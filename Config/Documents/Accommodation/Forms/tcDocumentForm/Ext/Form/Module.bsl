
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Initialization
	WasNew = False;
	WasAlreadyPrint = False;
	
	NumberOfGuestFields = 5;
	NumberOfKidAgeFields = 12;
	NumberOfAdults = 1;
	NumberOfKids = 0;
	AdultsMinAge = 18;
	If ValueIsFilled(Object.Ref) Then
		vChildrenAgesStruct = Undefined;
		vHotel = Object.Hotel;
		If ValueIsFilled(vHotel) Then
			vAgesStruct = vHotel;
		EndIf;
		If ValueIsFilled(Object.Contract) Then
			vContract = Object.Contract;
			If vContract.TeenagersMaxAge <> 0 Or vContract.ChildrenMaxAge <> 0 Or vContract.InfantsMaxAge <> 0 Then
				vChildrenAgesStruct = Object.Contract;
			EndIf;
		EndIf;
		If ValueIsFilled(vHotel) And (vHotel.TeenagersMaxAge <> 0 Or vHotel.ChildrenMaxAge <> 0 Or vHotel.InfantsMaxAge <> 0) Then
			vOffers = cmGetConfirmedSpecialOffersForReservation(Object.Ref, Object.Hotel, Object.RoomRate, Object.RoomRateType, Object.Guest, Object.ClientType, Object.Customer, Object.CustomerType, Object.GuestGroup, Object.SourceOfBusiness, Object.MarketingCode, Object.TripPurpose, Object.CheckInDate, Object.Duration, Object.CheckOutDate, ?(ValueIsFilled(Object.GuestGroup), Object.GuestGroup.CreateDate, Object.Date), Object.RoomType);
			For Each vOffersRow In vOffers Do
				vOffer = vOffersRow.SpecialOffer;
				If vOffer.TeenagersMaxAge <> 0 Or vOffer.ChildrenMaxAge <> 0 Or vOffer.InfantsMaxAge <> 0 Then
					vChildrenAgesStruct = vOffer;
					Break;
				EndIf;
			EndDo;
		EndIf;
		If vChildrenAgesStruct <> Undefined Then
			If vChildrenAgesStruct.TeenagersMaxAge <> 0 Then
				AdultsMinAge = vChildrenAgesStruct.TeenagersMaxAge + 1;
			ElsIf vChildrenAgesStruct.ChildrenMaxAge <> 0 Then
				AdultsMinAge = vChildrenAgesStruct.ChildrenMaxAge + 1;
			ElsIf vChildrenAgesStruct.InfantsMaxAge <> 0 Then
				AdultsMinAge = vChildrenAgesStruct.InfantsMaxAge + 1;
			EndIf;
		EndIf;
		If Object.GuestAge > 0 And Object.GuestAge < AdultsMinAge Then
			NumberOfAdults = 0;
			NumberOfKids = 1;
			Items.KidAge1.Visible = True;
			KidAge1 = Object.GuestAge;
		EndIf;
	EndIf;
	LastNumberOfAdults = NumberOfAdults;
	LastKidsNumber = NumberOfKids;

	FunctionsAndPrintFormsWereLoaded = False;
	
	// Save current user
	CurrentUser = SessionParameters.CurrentUser;
	
	// Agent is not permitted to open accommodations
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
			pCancel = True;
			Return;
		EndIf;
	Else
		pCancel = True;
		Return;
	EndIf;
	
	// Custom fields
	AddCustomFields();
	
	// Apply custom form settings
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Restore object
	If Parameters.Property("RestoreObject") Then
		If TypeOf(Parameters.RestoreObject) = Type("Structure") Then
			vRChg = InformationRegisters.AccommodationChangeHistory;
			vRChgRec = vRChg.Get(Parameters.RestoreObject.Period, New Structure("Accommodation", Parameters.RestoreObject.Document));
			vObj = Parameters.RestoreObject.Document.GetObject();
			vObj.pmRestoreAttributesFromHistory(vRChgRec);
			ValueToFormData(vObj, Object); 
			Parameters.ModifiedFromHistory = True;
		EndIf;	
	EndIf;	
	// Process parameters
	If Parameters.Property("GuestGroup") Then
		If ValueIsFilled(Parameters.GuestGroup) Then
			Object.GuestGroup = Parameters.GuestGroup; 
			If Object.Hotel <> Object.GuestGroup.Owner Then
				Object.Hotel = Object.GuestGroup.Owner;
			EndIf;
		EndIf;
	EndIf;
	If Parameters.Property("RoomType") Then
		If ValueIsFilled(Parameters.RoomType) Then
			Object.RoomType = Parameters.RoomType; 
			If ValueIsFilled(Object.RoomType.BaseRoomType) Then
				Object.RoomTypeUpgrade = Object.RoomType;
				Object.RoomType = Object.RoomType.BaseRoomType;
				RoomPrice = 0;
				IsManualRoomPrice = 2;
				Items.RoomPrice.Visible = False;
				Items.RoomTypeUpgrade.Visible = True;
			EndIf;
		EndIf;
	EndIf;
	If Parameters.Property("Room") Then
		If ValueIsFilled(Parameters.Room) Then
			Object.Room = Parameters.Room; 
		EndIf;
	EndIf;
	If Parameters.Property("CheckInDate") Then
		Object.CheckInDate = Parameters.CheckInDate;
	EndIf;
	If Parameters.Property("CheckOutDate") Then
		Object.CheckOutDate = Parameters.CheckOutDate;
	EndIf;
	If Parameters.Property("RoomQuota") Then
		If ValueIsFilled(Parameters.RoomQuota) Then
			Object.RoomQuota = Parameters.RoomQuota;
		EndIf;
	EndIf;
	If Parameters.Property("RoomRate") Then
		If ValueIsFilled(Parameters.RoomRate) Then
			Object.RoomRate = Parameters.RoomRate; 
			Object.RoomRateType = Object.RoomRate.RoomRateType;
			SetDurationCaption();
		EndIf;
	EndIf;
	If Parameters.Property("ClientType") Then
		If ValueIsFilled(Parameters.ClientType) Then
			Object.ClientType = Parameters.ClientType; 
		EndIf;
	EndIf;
	If Parameters.Property("BoardPlace") Then
		If ValueIsFilled(Parameters.BoardPlace) Then
			Object.BoardPlace = Parameters.BoardPlace; 
		EndIf;
	EndIf;
	If Parameters.Property("BedsSetup") Then
		If ValueIsFilled(Parameters.BedsSetup) Then
			Object.BedsSetup = Parameters.BedsSetup; 
		EndIf;
	EndIf;
	If Parameters.Property("Template") Then
		If ValueIsFilled(Parameters.Template) Then
			vOverrides = New ValueTable();
			If ValueIsFilled(Object.RoomRate) And ValueIsFilled(Object.Hotel) And ValueIsFilled(Object.RoomType) Then
				vOverrides = cmGetRoomRateOverrides(Object.RoomRate, Object.Hotel, Parameters.Template, ?(ValueIsFilled(Object.RoomTypeUpgrade), Object.RoomTypeUpgrade, Object.RoomType));
			EndIf;
			
			For Each vAccType In Parameters.Template.AccommodationTypes Do
				vAccTypeIndex = Parameters.Template.AccommodationTypes.IndexOf(vAccType);
				vAccommodationType = vAccType.AccommodationType;

				vAge = Undefined;
				If ValueIsFilled(vAccommodationType) And vAccommodationType.AllowedClientAgeTo <> 0 Then
					vAge = BegOfDay(CurrentSessionDate()) - (vAccommodationType.AllowedClientAgeTo - 1) * tcCommonFunctionOnClientServer.cmOneDay(365);
				EndIf;
				
				If vOverrides.Count() > 0 Then
					vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vAccommodationType, vAccTypeIndex + 1));
					If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
						vAccommodationType = vOverrideRows.Get(0).ToAccommodationType;
					EndIf;
				EndIf;
				
				vStructure = New Structure("AccommodationType, Amount, GuestName, GuestRef, DateOfBirth, Phone, Email, HotelProduct, LegalRepresentative, RelationType", vAccommodationType, Undefined, Undefined, Undefined, vAge, Undefined, Undefined, Undefined); 
				
				DocsList.Add(vStructure, vAccommodationType.SortCode);
			EndDo;
		EndIf;
	EndIf;
	If Parameters.Property("GuestsToCheckInList") And TypeOf(Parameters.GuestsToCheckInList) = Type("ValueList") Then
		GuestsToCheckInList.LoadValues(Parameters.GuestsToCheckInList.UnloadValues());
	EndIf;
	DoNotCheckDatesAtCheckIn = False;
	If Parameters.Property("DoNotCheckDatesAtCheckIn") And TypeOf(Parameters.DoNotCheckDatesAtCheckIn) = Type("Boolean") Then
		DoNotCheckDatesAtCheckIn = Parameters.DoNotCheckDatesAtCheckIn;
	EndIf;
	// Phone2
	If IsBlankString(Object.Fax) Then
		Items.AddPhone2.Visible = True;
		Items.Fax.Visible = false;
	Else
		Items.AddPhone2.Visible = False;
		Items.Fax.Visible = True;
	EndIf;
	If ValueIsFilled(Object.Guest) And Not IsBlankString(Object.Guest.EMailAdditional) Then
		EMail2 = Object.Guest.EMailAdditional;
		Items.EMail2.Visible = True;
		Items.AddEmail2.Visible = False;
	Else
		Items.EMail2.Visible = False;
		Items.AddEmail2.Visible = True;	
	EndIf;
	
	vKeyParameter = Parameters.Key;
	If ValueIsFilled(vKeyParameter) Then
		If TypeOf(vKeyParameter) = Type("DocumentRef.Accommodation") Then
			ValueToFormAttribute(vKeyParameter.GetObject(), "Object");
		EndIf;
	EndIf;
	
	OneGuestModeWasNotSet = False;
	If Not Parameters.Property("OneGuestMode", OneGuestMode) Then
		OneGuestMode = False;
		OneGuestModeWasNotSet = True;
	EndIf;
	If Parameters.Property("IsForFolioSplit") Then
		Object.IsForFolioSplit = Parameters.IsForFolioSplit;
	EndIf;
	
	If OneGuestMode Then
		Items.AccommodationType.Enabled = True;
		Items.AccommodationType.TextEdit = True;
	EndIf;
	
	If Parameters.Property("ParentAccommodation") And Not OneGuestMode Then
		vParentDoc = Parameters.ParentAccommodation;
		If ValueIsFilled(vParentDoc) And TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
			vNewObj = Documents.Accommodation.CreateDocument();
			vNewObj.Fill(vParentDoc);
			vNewObj.Room = vParentDoc.Room;
			ValueToFormAttribute(vNewObj, "Object");
		EndIf;
	EndIf;
	
	// Do not change number of guests mode
	vDoNotChangeNumberOfGuests = False;
	If Parameters.Property("DoNotChangeNumberOfGuestsMode") Then
		vDoNotChangeNumberOfGuests = Parameters.DoNotChangeNumberOfGuestsMode;
	EndIf;
	If vDoNotChangeNumberOfGuests Then
		Items.AdultsGroup.Visible = False;
		Items.TabulationAdultsAndKids.Visible = False;
		Items.KidsCalculateGroup.Visible = False;
	EndIf;
	
	// Fill Accommodation Statuses
	FillAccommodationStatusListChoice();
	
	// Fill parameters
	Items.ClientType.ChoiceList.LoadValues(GetArrayOfAllClientTypes());
	Items.RoomRatesClientType.ChoiceList.LoadValues(Items.ClientType.ChoiceList.UnloadValues());
	Items.SourceOfBusiness.ChoiceList.LoadValues(GetArrayOfAllSourceOfBusiness());
	Items.RoomRatesSourceOfBusiness.ChoiceList.LoadValues(Items.SourceOfBusiness.ChoiceList.UnloadValues());
	Items.TripPurpose.ChoiceList.LoadValues(GetArrayOfAllTripPurposes());
	
	// Fill room properties
	RoomProperties = GetRoomPropertiesValueList();
	RoomPropertiesFromGuest = GetRoomPropertiesFromGuestValueList();
	
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToAddManualDiscounts") Then
		Items.DiscountCard.Enabled = True;
		Items.DiscountType.Enabled = True;
		Items.Discount.Enabled = False;
		Items.DiscountServiceGroup.Enabled = False;
	EndIf;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToInputDiscountCardNumberManually") Then
		Items.DiscountCard.TextEdit = False;
		Items.DiscountCard.ChoiceButton = False;
		Items.DiscountCard.OpenButton = False;
	Else
		Items.DiscountCard.TextEdit = True;
		Items.DiscountCard.ChoiceButton = True;
		Items.DiscountCard.OpenButton = True;
	EndIf;
	
	// Price calculation date
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditRoomRateServices") Then
		Items.PriceCalculationDate.ReadOnly = True;
	EndIf;
	
	// Register foreigners action availability
	vRegForeignerObjectFormAction = Catalogs.ObjectFormActions.AccommodationOpenForeignerRegistryRecord;
	If vRegForeignerObjectFormAction.DeletionMark Or Not vRegForeignerObjectFormAction.IsActive Then
		Items.FormOpenForeignerRegistryRecord.Visible = False;
	EndIf;
	
	// Scan documents action availability
	vScansObjectFormAction = Catalogs.ObjectFormActions.AccommodationScanClientData;
	If vScansObjectFormAction.DeletionMark Or Not vScansObjectFormAction.IsActive Then
		Items.FormScanDocuments.Visible = False;
	EndIf;
	
	// Services availability
	If Not cmCheckUserPermissions("HavePermissionToEditRoomRateServices") Then
		Items.ServicesGroup.ReadOnly = True;
		Items.ServicesClearServicesManualChanges.Enabled = False;
	EndIf;
	Items.ServicesGroup.Visible = True;
	
	// Show properties
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToSkipInputOfAccommodationMarketingCode") Or 
		   Not cmCheckUserPermissions("HavePermissionToSkipInputOfAccommodationSourceOfBusiness") Or
		   Not cmCheckUserPermissions("HavePermissionToSkipInputOfClientType") Or
		   Not cmCheckUserPermissions("HavePermissionToSkipInputOfGuestTripPurpose") Then
			Items.GroupProperties.Show();
		EndIf;
	EndIf;
	
	// Charging rules
	If Not cmCheckUserPermissions("HavePermissionToEditChargingRules") Then
		Items.GroupChargingRules.ReadOnly = True;
		Items.ChargingRulesLoadDefaultChargingRules.Enabled = False;
	EndIf;
	
	// Change availability
	Items.RoomRatesDoNotChangeAvailability.Visible = cmCheckUserPermissions("HavePermissionToUseDoNotChangeAvailabilityFlag");
	
	// Document parameters
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Check if this document is still being posted in the background
	DocumentBackgroundJobsCount = CheckForExistingBackgroundJobs().Count();
	
	// List of planned payment methods
	Items.PlannedPaymentMethod.ChoiceList.LoadValues(FillArrayOfPaymentMethods());

	// Fill functions and print forms list
	If ValueIsFilled(Object.Ref) Then
		FillFunctionsButton();
		FillPrintingButton();
		FunctionsAndPrintFormsWereLoaded = True;
	Else
		WasNew = True;
	EndIf;
	
	// Copy reservation function with new group creation
	vCopiedAcc = Undefined;
	If Parameters.Property("CopiedDocument") Then
		vCopiedAcc = Parameters.CopiedDocument;
		If ValueIsFilled(vCopiedAcc) Then
			vNewObj = vCopiedAcc.Copy();
			vNewObj.pmFillAuthorAndDate();
			vNewObj.pmCreateGuestGroup();
			vNewObj.RoomRates.Clear();
			vNewObj.Services.Clear();
			vNewObj.OccupationPercents.Clear();
			vNewObj.Guest = Undefined;
			vNewObj.GuestFullName = Undefined;
			vNewObj.Room = Undefined;
			vNewObj.CheckInDate = cm1SecondShift(CurrentSessionDate());
			vNewObj.CheckOutDate = vNewObj.pmCalculateCheckOutDate();
			vNewObj.NumberOfPersons = 1;
			vNewObj.NumberOfAdults = 1;
			vNewObj.NumberOfTeenagers = 0;
			vNewObj.NumberOfChildren = 0;
			vNewObj.NumberOfInfants = 0;
			vNewObj.AccommodationTemplate = Catalogs.AccommodationTemplates.EmptyRef();
			vNewObj.Phone = "";
			vNewObj.EMail = "";
			vNewObj.Car = "";
			ValueToFormAttribute(vNewObj, "Object");
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.Guest) Then
		SelGuest1 = TrimAll(Object.Guest.FullName);
		LastGuestFullName = SelGuest1;
	EndIf;
	
	// Check customer
	If ValueIsFilled(Object.Customer) Then
		Items.Contract.ReadOnly = False;
	Else
		Items.Contract.ReadOnly = True;
	EndIf;
	
	Items.FormOpenBlockForm.Enabled = Not WasNew;
	Items.FormCheckOut.Enabled = Not WasNew;
	
	// Fill document tasks button
	If ValueIsFilled(Object.Ref) Then
		vCount = GetNumberOfMessagesForObject(Object.Ref);
		If vCount = 0 Then
			Items.FormMessage.Title = NStr("en='Tasks';ru='Задачи';de='Aufgaben'");
		Else
			Items.FormMessage.Title = NStr("ru = 'Задачи - " + vCount + "'; en = 'Tasks - " + vCount + "'; de = 'Aufgaben - " + vCount + "'");
		EndIf;
	Else
		Items.FormMessage.Title = NStr("en='Tasks';ru='Задачи';de='Aufgaben'");
	EndIf;
	
	// Split services to 2 tables: rate charges and fixed charges
	vSrvFilter = New Structure("IsManual", False);
	Items.Services.RowFilter = New FixedStructure(vSrvFilter);	
	vFixFilter = New Structure("IsManual", True);
	Items.FixedCharges.RowFilter = New FixedStructure(vFixFilter);
	
	// Hotel products
	UseHotelProducts = GetVauchersFunctionalOption();
	Items.HotelProduct.Visible = UseHotelProducts;
	Items.HotelProduct2.Visible = UseHotelProducts;
	Items.HotelProduct3.Visible = UseHotelProducts;
	Items.HotelProduct4.Visible = UseHotelProducts;
	Items.HotelProduct5.Visible = UseHotelProducts;
	
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToForbiddenSetHotelProducts") Then
		Items.HotelProduct.ReadOnly = True;
		Items.HotelProduct2.ReadOnly = True;
		Items.HotelProduct3.ReadOnly = True;
		Items.HotelProduct4.ReadOnly = True;
		Items.HotelProduct5.ReadOnly = True;
		Items.HotelProduct.OpenButton = False; 
		Items.HotelProduct2.OpenButton = False;
		Items.HotelProduct3.OpenButton = False;
		Items.HotelProduct4.OpenButton = False;
		Items.HotelProduct5.OpenButton = False;
	EndIf;	
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToForbiddenClearHotelProducts") Then
		Items.HotelProduct.ClearButton = False;
		Items.HotelProduct2.ClearButton = False;
		Items.HotelProduct3.ClearButton = False;
		Items.HotelProduct4.ClearButton = False;
		Items.HotelProduct5.ClearButton = False;	
	EndIf;	
	
	// Beds setup
	UseBedsSetups = GetBedsSetupFunctionalOption();
	Items.BedsSetup.Visible = UseBedsSetups;
	
	// Main form processing
	OnOpenForm(Object.Posted);
	
	// Board place
	vBoardPlaces = cmGetBoardPlaces(Object.Hotel);
	If vBoardPlaces.Count() = 0 Then
		Items.BoardPlace.Visible = False;
		Items.RoomRatesBoardPlace.Visible = False;
		Items.ServicesBoardPlace.Visible = False;
		Items.FixedChargesBoardPlace.Visible = False;
	EndIf;
	
	// Check permissions
	OnOpenCheckPermissionsResult = BeforeOpenCheckPermissions();
	
	// Terms choice list
	FillServicePackageChoiceList();
	
	// Check if resort fee is used
	If Not ValueIsFilled(Object.Hotel.Region) And Not Object.Hotel.TouristTaxIsUsed Then
		Items.FormAddResortFeeExemption.Visible = False;
		Items.FormClearResortFeeExemption.Visible = False;
	EndIf;
	
	// Show room rate by default
	If Items.ServicePackage.Visible Then
		Items.GroupRoomRate.Show();
	EndIf;
	
	// Show or hide export guest data procedure
	vExportDPRef = GetDataProcessorForExportGuestDataToUFMS();
	If Not ValueIsFilled(vExportDPRef) Then
		Items.FormExportGuestDataToUFMSRu.Visible = False;
	EndIf;
	
	ShowButtonGetPaid = ?(Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(Object.Hotel) <> Undefined, True, False);
	If ValueIsFilled(Object.Ref) Then
		Items.GetPaid.Visible = ShowButtonGetPaid;
	Else
		Items.GetPaid.Visible = False;
	EndIf;
	
	// Fill guests names
	LastGuestFullName = SelGuest1;
	For i = 1 To GuestsInGroup.Count() Do
		ThisObject["LastGuestFullName" + Format(i + 1, "NFD=0; NG=")] = ThisObject["SelGuest" + Format(i + 1, "NFD=0; NG=")];
	EndDo;
	
	// Price change reaon
	PriceChangeReason = Object.PriceChangeReason;
	If IsBlankString(PriceChangeReason) Then
		PriceChangeReason = NStr("en='<price change reason>'; ru='<причина изменения цены>'; de='<Preisänderungsgründe>'");
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	pCancel = False;
	If Parameters.ModifiedFromHistory Then
		ThisObject.Modified = True;
		ThisObject.Title = NStr("en = 'Restored'; de = 'Restauriert'; ru = 'Восстановлен'") +", "+ ThisObject.Title;
	EndIf;	
	
	vResRef = Object.Reservation;
	vGuestsToCheckInList = GuestsToCheckInList.Copy();
	
	// Check if this is main room document
	If OneGuestModeWasNotSet Then
		If ValueIsFilled(Object.Ref) And Not ValueIsFilled(Object.AccommodationTemplate) Then
			If Object.Posted And ValueIsFilled(Object.AccommodationStatus) And tcOnServer.cmGetAttributeByRef(Object.AccommodationStatus, "IsActive") Then
				vMainRoomDoc = GetMainRoomDocument(Object.Number, Object.Room, Object.GuestGroup);
				If ValueIsFilled(vMainRoomDoc) And vMainRoomDoc <> Object.Ref Then
					If tcOnServer.cmGetAttributeByRef(vMainRoomDoc, "CheckInDate") < Object.CheckOutDate And tcOnServer.cmGetAttributeByRef(vMainRoomDoc, "CheckOutDate") > Object.CheckInDate Then
						OpenForm("Document.Accommodation.ObjectForm", New Structure("Key, OneGuestMode", vMainRoomDoc, False), ThisObject.FormOwner, vMainRoomDoc);
						pCancel = True;
						FreeLockedDocs(vResRef, vGuestsToCheckInList, GuestsInGroup.Count(), ThisObject.UUID);
						Return;
					EndIf;
				EndIf;
			Else
				OpenForm("Document.Accommodation.ObjectForm", New Structure("Key, OneGuestMode", Object.Ref, True), ThisObject.FormOwner, tcOnServer.GetStringUUIDByRef(Object.Ref));
				pCancel = True;
				FreeLockedDocs(vResRef, vGuestsToCheckInList, GuestsInGroup.Count(), ThisObject.UUID);
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	// Check if this is check-in and there are guests with different check-in dates
	If Not OneGuestMode Or OneGuestModeWasNotSet Then
		If Not DoNotCheckDatesAtCheckIn And GuestsToCheckInList.Count() > 1 And ValueIsFilled(Object.Reservation) Then
			vDifferentCheckInDates = False;
			vCurCheckInDay = BegOfDay(tcOnServer.cmGetAttributeByRef(Object.Reservation, "CheckInDate"));
			For Each vGuestItem In GuestsToCheckInList Do
				vGuestItemValue = vGuestItem.Value;
				If vCurCheckInDay <> BegOfDay(tcOnServer.cmGetAttributeByRef(vGuestItemValue, "CheckInDate")) Then
					vDifferentCheckInDates = True;
					Break;
				EndIf;
			EndDo;
			If vDifferentCheckInDates Then
				OpenForm("CommonForm.tcSelectGuestsToCheckIn", New Structure("DocRef, GuestsToCheckInList", Object.Reservation, GuestsToCheckInList));
				pCancel = True;
				FreeLockedDocs(vResRef, vGuestsToCheckInList, GuestsInGroup.Count(), ThisObject.UUID);
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	If DocumentBackgroundJobsCount > 0 Then
		ThisObject.ReadOnly = True;
		ThisObject.Enabled = False;
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'The document is being conducted. Try again later.'; ru = 'Документ проводится, попробуйте открыть его позже.'; de = '-'")); // #Translate
	EndIf;
	
	If Not IsBlankString(OnOpenCheckPermissionsResult) Then
		tcCommonFunctionOnClientServer.UserMessage(OnOpenCheckPermissionsResult);
		pCancel = True;
		FreeLockedDocs(vResRef, vGuestsToCheckInList, GuestsInGroup.Count(), ThisObject.UUID);
		Return;
	EndIf;
	
	ThisObject.CurrentItem = Items.Room;
	
	#If ThickClientOrdinaryApplication Then
		Items.FormPostAndClose.Visible = False;
		Items.FormPost.Visible = False;
		Items.SimpleModeActions.Visible = True;
		// Write to last visited objects
		cmWriteToLastVisitedObjects(amPersistentObjects, ThisObject.Object.Ref);
	#Else
		Items.FormPostAndClose.Visible = True;
		Items.FormPostAndClose.DefaultButton = True;
		Items.FormPost.Visible = True;
		Items.SimpleModeActions.Visible = False;
		Items.FormOpenBlockForm.Visible = False;
		Items.FormOpenChangeHistory.Visible = False;
	#EndIf
	#If ThickClientOrdinaryApplication Then
		Items.HotelProduct.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;
		Items.HotelProduct.CreateButton = False;
		Items.HotelProduct2.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;
		Items.HotelProduct2.CreateButton = False;
		Items.HotelProduct3.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;
		Items.HotelProduct3.CreateButton = False;
		Items.HotelProduct4.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;
		Items.HotelProduct4.CreateButton = False;
		Items.HotelProduct5.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;
		Items.HotelProduct5.CreateButton = False;
	#EndIf
	#If ThickClientOrdinaryApplication Then
		Items.GroupClientType.BackColor = New Color;
	#EndIf
	
	If Not IsNew Then
		vTasksStructure = TasksTab; 
		For Each vTasks In vTasksStructure Do
			vTaskStruct = vTasks.Value;
			If vTaskStruct.PopUp Then
				vShow = True;
				If ValueIsFilled(vTaskStruct.ReservationTaskArea) Then
					If vTaskStruct.ReservationTaskArea = PredefinedValue("Enum.ReservationTaskAreas.CheckIn") Then
						If BegOfDay(CurrentDate()) > BegOfDay(Object.CheckInDate) Then
							vShow = False;
						EndIf;
					ElsIf vTaskStruct.ReservationTaskArea = PredefinedValue("Enum.ReservationTaskAreas.CheckOut") Then
						If BegOfDay(CurrentDate()) < BegOfDay(Object.CheckOutDate) Then
							vShow = False;
						EndIf;
					EndIf;
				EndIf; 
				If vShow And ValueIsFilled(vTaskStruct.ValidToDate) And BegOfDay(vTaskStruct.ValidToDate) < BegOfDay(CurrentDate()) Then
					vShow = False;  
				ElsIf vShow And ValueIsFilled(vTaskStruct.ValidFromDate) And BegOfDay(vTaskStruct.ValidFromDate) > BegOfDay(CurrentDate()) Then	 
					vShow = False;
				EndIf;	
				If vShow Then
					ShowMessageBox(, vTasks.Value.Remarks, , NStr("en='Task';de='Aufgabe';ru='Задача'"));
				EndIf;
			EndIf;
		EndDo;     
	EndIf;
	
	// Set form functional option parameters
	SetFormFunctionalOptionParameters(New Structure("Hotel", Object.Hotel));
	
	// Show footer
	AttachIdleHandler("ShowFooter", 0.1, True);
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowFooter()
	// Fill table with valid room type/accommodation type combinations
	If ValueIsFilled(Object.RoomType) Then
		FillTypesTableAtServer();
	EndIf;
	// Show footer
	Items.GroupFooter.Visible = True;
	// Check planned room move
	If Not IsNew And Object.Posted Then
		AttachIdleHandler("CheckPlannedRoomMove", 0.1, True);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckPlannedRoomMove()
	vAccommodationStatusStruct = tcOnServer.cmGetAtributeAsArray(Object.AccommodationStatus);
	If vAccommodationStatusStruct.IsActive And vAccommodationStatusStruct.IsInHouse Then
		vCurDate = tcOnServer.GetCurrentSessionDate();
		vCurRoom = Object.Room;
		vCurAccommodationType = Object.AccommodationType;
		vCurAccommodationTemplate = Object.AccommodationTemplate;
		For Each vRRRow In Object.RoomRates Do
			vChangeDate = BegOfDay(vRRRow.AccountingDate) + (vRRRow.ChangeTime - BegOfDay(vRRRow.ChangeTime));
			If vChangeDate <= vCurDate Then
				If ValueIsFilled(vRRRow.Room) Then
					vCurRoom = vRRRow.Room;
				EndIf;
				If ValueIsFilled(vRRRow.AccommodationType) Then
					vCurAccommodationType = vRRRow.AccommodationType;
				EndIf;
				If ValueIsFilled(vRRRow.AccommodationTemplate) Then
					vCurAccommodationTemplate = vRRRow.AccommodationTemplate;
				EndIf;
			Else
				Break;
			EndIf;
		EndDo;
		If ValueIsFilled(vCurRoom) And vCurRoom <> Object.Room Then
			vParams = New Structure("Room, AccommodationType, AccommodationTemplate", vCurRoom, vCurAccommodationType, vCurAccommodationTemplate);
			ShowQueryBox(New NotifyDescription("PlannedRoomMoveProcessing", ThisObject, vParams), 
			             StrTemplate(NStr("en='Finish the planned room move to the room %1?'; 
						                  |ru='Выполнить запланированное переселение в номер %1?'; 
							              |de='Den geplanten Zimmerumzug in das Zimmer %1 abschließen?'"), String(vCurRoom)), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		EndIf;
	EndIf;
EndProcedure // CheckPlannedRoomMove

// -----------------------------------------------------------------------------
&AtClient
Procedure PlannedRoomMoveProcessing(pUserAnswer, pExtraParams) Export
	If pUserAnswer = DialogReturnCode.Yes Then
		Object.Room = pExtraParams.Room;
		If ValueIsFilled(pExtraParams.AccommodationType) Then
			Object.AccommodationType = pExtraParams.AccommodationType;
		EndIf;
		If ValueIsFilled(pExtraParams.AccommodationTemplate) Then
			Object.AccommodationTemplate = pExtraParams.AccommodationTemplate;
		EndIf;
		vRoomPopUpTasksArray = RoomOnChangeAtServer();
		RefreshDocumentRepresentation();
		// Show room pop up tasks
		If vRoomPopUpTasksArray.Count() > 0 Then
			For Each vRoomPopUpTask In vRoomPopUpTasksArray Do
				ShowMessageBox(, vRoomPopUpTask, , NStr("en='Information';de='Information';ru='Информация'"));
			EndDo;
		EndIf;
		ThisObject.Modified = True;
	EndIf;
EndProcedure // PlannedRoomMoveProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If pExit Then
	   Return;
	EndIf; 
	If IsInBeforeCloseEvent Then
		Return;
	EndIf;
	IsInBeforeCloseEvent = True;
	If ThisObject.ReadOnly Then
		ThisObject.Modified = False;
	EndIf;
	vModified = ThisObject.Modified;
	If vModified Then
		pCancel = True;
		ShowQueryBox(New NotifyDescription("BeforeClose_AfterAnswering", ThisObject, pCancel), NStr("en='Data was changed! Save the changes?';ru='Данные были изменены! Сохранить изменения?';de='Die Daten wurden geändert! Änderungen speichern?'"), QuestionDialogMode.YesNoCancel);
	Else
		BeforeClose_AfterAnswering(Undefined, pCancel);	
		IsInBeforeCloseEvent = False;
	EndIf;		
EndProcedure // BeforeClose

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(pExit)
	If Not pExit Then
		OnCloseAtServer();
	EndIf;
EndProcedure // OnClose

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("CatalogRef.ServicePackages") Then
		InsertServicePackageAtServer(pSelectedValue);
	EndIf;
EndProcedure // ChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)        
	vPrevAccommodationTemplate = Object.AccommodationTemplate;
	If pEventName = "Client.Change" Then
		If TypeOf(pSource) = Type("ClientApplicationForm") And pSource = ThisObject Then
			Object.Guest = pParameter;
			GuestOnChangeAtServer();
		ElsIf TypeOf(pSource) = Type("FormTable") And tcOnClient.GetParentForm(pSource) = ThisObject Then
			vFieldName = ThisObject.CurrentItem.Name;
			If Left(vFieldName, 8) = "SelGuest" Then
				If vFieldName = "SelGuest1" Then
					Object.Guest = pParameter;
					ThisObject[vFieldName] = GetClientFullName(pParameter);
					GuestOnChangeAtServer();
				Else
					ThisObject[Right(vFieldName, StrLen(vFieldName)-3)] = pParameter;
					ThisObject[vFieldName] = GetClientFullName(pParameter);
					AddGuestOnChange(ThisObject.CurrentItem);
				EndIf;
			EndIf;
		ElsIf TypeOf(pSource) = Type("FormField") And tcOnClient.GetParentForm(pSource) = ThisObject Then
			vFieldName = pSource.Name;
			If Left(vFieldName, 8) = "SelGuest" Then
				If vFieldName = "SelGuest1" Then
					Object.Guest = pParameter;
					ThisObject[vFieldName] = GetClientFullName(pParameter);
					GuestOnChangeAtServer();
				Else
					ThisObject[Right(vFieldName, StrLen(vFieldName)-3)] = pParameter;
					ThisObject[vFieldName] = GetClientFullName(pParameter);
					AddGuestOnChange(pSource);
				EndIf;
			EndIf;
		EndIf;
	ElsIf pEventName = "ForeignerRegistryRecord.Write" Then
		If TypeOf(pSource) = Type("FormField") And tcOnClient.GetParentForm(pSource) = ThisObject Then
			vFieldName = pSource.Name;
			If Left(vFieldName, 8) = "SelGuest" Then
				If Not IsOnCloseForm Then
					ThisObject.Read();
					If SavedButNotPostedWhileOpen Then
						ThisObject.Modified = True;
					EndIf;
				EndIf;
				If Not (NumberOfAdults = 0 And NumberOfKids > 0) Then
					NumberOfAdults = 1;
					NumberOfKids = 0;
				Else
					NumberOfAdults = 0;
					NumberOfKids = 1;
				EndIf;
				LastNumberOfAdults = NumberOfAdults;
				LastKidsNumber = NumberOfKids;
				vWasPosted = WasPosted;
				vIsNew = IsNew;
				DocsList.Clear();
				OnOpenForm(False);
				WasPosted = vWasPosted;
				IsNew = vIsNew;
			EndIf;
		EndIf;
	ElsIf pEventName = "HotelProduct.Write" Or pEventName = "HotelProduct.CostChange" Then
		If pSource = ThisObject.CurrentItem Then
			If pSource = Items.HotelProduct Then
				Object.HotelProduct = pParameter;
				HotelProductOnChangeAtServer();
				ThisObject.Modified = True;
			Else
				vInd = GetItemIndex(ThisObject.CurrentItem.Name);
				If Not IsBlankString(vInd) Then
					ThisObject[pSource.Name] = pParameter;
					ExtraGuestHotelProductOnChangeAtServer(vInd);
					ThisObject.Modified = True;
				EndIf;
			EndIf;
		EndIf;
	ElsIf pEventName = "HotelProduct.Deleted" Then
		If pSource = ThisObject.CurrentItem Then
			If pSource = Items.HotelProduct Then
				Object.HotelProduct = Undefined;
				HotelProductOnChangeAtServer();
				ThisObject.Modified = True;
			Else
				vInd = GetItemIndex(ThisObject.CurrentItem.Name);
				If Not IsBlankString(vInd) Then
					ThisObject[pSource.Name] = Undefined;
					ExtraGuestHotelProductOnChangeAtServer(vInd);
					ThisObject.Modified = True;
				EndIf;
			EndIf;
		EndIf;
	ElsIf pEventName = "Document.Reservation.Write" And ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(pParameter) And 
		  (TypeOf(pParameter) = Type("DocumentRef.Accommodation") Or TypeOf(pParameter) = Type("DocumentRef.Reservation")) And 
		   tcOnServer.cmGetAttributeByRef(pParameter, "GuestGroup") = Object.GuestGroup Then
			If Not IsOnCloseForm Then
				ThisObject.Read();
				If SavedButNotPostedWhileOpen Then
					ThisObject.Modified = True;
				EndIf;
			EndIf;
			If Not (NumberOfAdults = 0 And NumberOfKids > 0) Then
				NumberOfAdults = 1;
				NumberOfKids = 0;
			Else
				NumberOfAdults = 0;
				NumberOfKids = 1;
			EndIf;
			LastNumberOfAdults = NumberOfAdults;
			LastKidsNumber = NumberOfKids;
			vWasPosted = WasPosted;
			vIsNew = IsNew;
			DocsList.Clear();
			OnOpenForm(False);
			WasPosted = vWasPosted;
			IsNew = vIsNew;
		EndIf;
	ElsIf pEventName = "Subsystem.Accounts.Changed" And ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(pParameter) And pParameter = Object.GuestGroup Then
			If Not IsOnCloseForm Then
				ThisObject.Read();
				If SavedButNotPostedWhileOpen Then
					ThisObject.Modified = True;
				EndIf;
			EndIf;
			If Not (NumberOfAdults = 0 And NumberOfKids > 0) Then
				NumberOfAdults = 1;
				NumberOfKids = 0;
			Else
				NumberOfAdults = 0;
				NumberOfKids = 1;
			EndIf;
			LastNumberOfAdults = NumberOfAdults;
			LastKidsNumber = NumberOfKids;
			vWasPosted = WasPosted;
			vIsNew = IsNew;
			DocsList.Clear();
			OnOpenForm(False);
			WasPosted = vWasPosted;
			IsNew = vIsNew;
		EndIf;
	ElsIf (pEventName = "Document.Accommodation.Write" Or pEventName = "Document.Accommodation.WriteNew") And ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(pParameter) And (pParameter = Object.Ref And pSource <> ThisObject Or GuestsInGroup.FindRows(New Structure("Ref", pParameter)).Count() > 0) Then
			If Not IsOnCloseForm Then
				ThisObject.Read();
				If SavedButNotPostedWhileOpen Then
					ThisObject.Modified = True;
				EndIf;
			EndIf;
			If Not (NumberOfAdults = 0 And NumberOfKids > 0) Then
				NumberOfAdults = 1;
				NumberOfKids = 0;
			Else
				NumberOfAdults = 0;
				NumberOfKids = 1;
			EndIf;
			LastNumberOfAdults = NumberOfAdults;
			LastKidsNumber = NumberOfKids;
			vWasPosted = WasPosted;
			vIsNew = IsNew;
			DocsList.Clear();
			OnOpenForm(False);
			WasPosted = vWasPosted;
			IsNew = vIsNew;
		EndIf;
	ElsIf pEventName = "CreditCard.Write" Then
		If pSource = ThisObject Then
			CreditCardAfterUserInput(pParameter);
		EndIf;
	ElsIf pEventName = "Document.Order.Write" Then
		FillOrders();
	ElsIf pEventName = "SessionParameters.CurrentUser.Change" Then
		EmployeePINCodeChecked = True;
		If pParameter.ModeAfterCheck = "WriteAndClose" Then
			PostAndClose(Commands["PostAndClose"]);
		ElsIf pParameter.ModeAfterCheck = "BeforeClose_AfterAnswering" Then
			BeforeClose_AfterAnswering(DialogReturnCode.Yes, False);
		ElsIf pParameter.ModeAfterCheck = "OpenFolios" Then
			OpenFolios(Commands.OpenFolios);
		ElsIf pParameter.ModeAfterCheck = "CheckOut" Then
			CheckOut(Undefined);
		ElsIf pParameter.ModeAfterCheck = "CreateGroupProformaInvoice" Then
			CreateGroupProformaInvoice(Undefined);
		ElsIf pParameter.ModeAfterCheck = "OpenForeignerRegistryRecord" Then
			OpenForeignerRegistryRecord(Undefined);
		ElsIf pParameter.ModeAfterCheck = "Pay" Then
			Pay(Undefined);
		ElsIf pParameter.ModeAfterCheck = "MakeKey" Then
			MakeKey(Undefined);
		ElsIf pParameter.ModeAfterCheck = "ScanDocuments" Then
			ScanDocuments(Undefined);
		ElsIf pParameter.ModeAfterCheck = "GuestRegistrationActionClick" Then
			GuestRegistrationActionClick(ThisObject.CurrentItem);
		Else
			Post(Commands["Post"]);
		EndIf;
	ElsIf pEventName = "MessageWrite" Then
		FillTasksPresentation();
	ElsIf pEventName = "Reservation.RoomTypeUpgradeWasChanged" And pParameter = Object.Ref Then
		ManualPriceAppearance(, True);
	ElsIf pEventName = "Catalog.GuestGroups.Changed" And pParameter = Object.GuestGroup Then
		If Not IsOnCloseForm Then
			ThisObject.RepresentDataChange(Object.GuestGroup, DataChangeType.Update);
			ThisObject.Read();
			If SavedButNotPostedWhileOpen Then
				ThisObject.Modified = True;
			EndIf;
		EndIf;
	ElsIf pEventName = "System.Hotel.Changed" And pParameter <> Object.Hotel Then
		If ThisObject.Modified Then
			PostAndClose(Commands.PostAndClose);
		Else
			ThisObject.Close();
		EndIf;
	ElsIf pEventName = "Document.Accommodation.Splitted" And pSource = ThisObject Then
		ThisObject.Modified = False;
		ThisObject.Close();
	ElsIf pEventName = "ServicePackages.Changed" And pParameter <> Undefined And pSource = ThisObject Then
		SaveServicePackagesListAtServer(pParameter);
		FillAmenitiesFromServicePackages(pParameter);
		RoomRateOnChangeAtServer(, True);
		RefreshDataRepresentation();
	ElsIf pEventName = "RateServicesServicesCopyRows" Then
		If Not ThisObject.ReadOnly Then
			vCopyValueButton = Items.ServicesCopy;
			vPasteValueButton = Items.ServicesPaste;
			If amClipboard.Property("RateServicesServices") Then
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
			EndIf;
		EndIf;
	ElsIf pEventName = "RateServicesServicesCancelCopyRows" Then
		vCopyValueButton = Items.ServicesCopy;
		vPasteValueButton = Items.ServicesPaste;
		ColumnCopied = Undefined;
		ValueCopied = Undefined;
	ElsIf pEventName = "FixedChargesServicesCopyRows" Then
		If Not ThisObject.ReadOnly Then
			vCopyValueButton = Items.FixedChargesCopy;
			vPasteValueButton = Items.FixedChargesPaste;
			If amClipboard.Property("FixedChargesServices") Then
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
			EndIf;
		EndIf;
	ElsIf pEventName = "FixedChargesServicesCancelCopyRows" Then
		vCopyValueButton = Items.FixedChargesCopy;
		vPasteValueButton = Items.FixedChargesPaste;
		ColumnCopiedFixedCharges = Undefined;
		ValueCopiedFixedCharges = Undefined;
	ElsIf pEventName = "Clients.Merged" Then
		If Not IsOnCloseForm Then
			ThisObject.Read();
			If SavedButNotPostedWhileOpen Then
				ThisObject.Modified = True;
			EndIf;
		EndIf;   
	ElsIf pEventName = "ClientDataScans.Write" And pSource = ThisObject Then
		If Not OneGuestMode And ValueIsFilled(Object.AccommodationStatus) And 
		   tcOnServer.cmGetAttributeByRef(Object.AccommodationStatus, "IsInHouse") And 
		   tcOnServer.cmGetAttributeByRef(Object.AccommodationStatus, "IsActive") Then
			If GetNumberOfNotCheckedInGuests() = 0 Then
				CheckGuestFieldCount();
			EndIf;
		EndIf;
		GuestOnChangeAtServer();     
		Write();
	EndIf;    
	If vPrevAccommodationTemplate <> Object.AccommodationTemplate Then   
		WaitMessageBox = NStr("en = 'The list of guests has changed, the cost will be recalculated'; 
							  |de = 'Die Gästeliste hat sich geändert, die Kosten werden neu berechnet'; 
							  |ru = 'Изменился состав гостей, стоимость будет пересчитана'");
		If IsInputAvailable() Then
			ShowMessageBox(, WaitMessageBox);   
			WaitMessageBox = "";
		Else
		    AttachIdleHandler("Attachable_ShowMessages", 1, True);
		EndIf;
	EndIf;	
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If pWriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// APDEX
		vApdexRemarks = GetRemarksForAPDEX();
		vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.Posting";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If Not FunctionsAndPrintFormsWereLoaded Then
		FillFunctionsButton();
		FillPrintingButton();
		Items.GetPaid.Visible = ShowButtonGetPaid;
		FunctionsAndPrintFormsWereLoaded = True;
	EndIf;     
EndProcedure // AfterWriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)    
	// Notify changes in the accounts subsystem
	Notify("Subsystem.Accounts.Changed");
EndProcedure // AfterWrite

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	vObj = FormAttributeToValue("Object");
	pCancel = tcOnServer.cmFillCheckProcessingForm(pCheckedAttributes, CheckedAttributesManual, vObj);
EndProcedure

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
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		// Try to find client identification card
		vCard = GetClientIdentificationCardById(vEventData.DeviceData);
		// Set client from the card data
		If ValueIsFilled(vCard) Then
			vClient = GetClient(vCard);
			If ValueIsFilled(vClient) Then
				If Parameters.Key.IsEmpty() Or Not ValueIsFilled(Object.Guest) Then
					Object.Guest = vClient;
					GuestOnChange(Items.SelGuest1);
				Else
					ShowMessageBox(, NStr("en='This card does not belong to the guest! You may clear guest field and try to slip card again.';ru='Чужая карта! Можете очистить поле гостя и заново прокатать карту.';de='Fremde Karte! Sie können das Gastfeld löschen und die Karte neu durchziehen.'"));
				EndIf;
				// Activate form
				Activate();
			EndIf;
		EndIf;
		// Try to search discount card
		vDiscountCard = GetDiscountCardById(vEventData.DeviceData);
		If ValueIsFilled(vDiscountCard) Then
			vDiscountCardClient = GetClient(vDiscountCard);
			If ValueIsFilled(vDiscountCardClient) Then
				If vDiscountCardClient = Object.Guest Or Not ValueIsFilled(Object.Guest) Or Parameters.Key.IsEmpty() Then
					Object.DiscountCard = vDiscountCard;
					DiscountCardOnChange(Items.DiscountCard);
				Else
					If Not CheckUserPermissions("HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt") Then
						ShowMessageBox(, NStr("en='This card does not belong to the guest! You may clear guest field and try to slip card again.';ru='Чужая карта! Можете очистить поле гостя и заново прокатать карту.';de='Fremde Karte! Sie können das Gastfeld löschen und die Karte neu durchziehen.'"));
					Else
						Object.DiscountCard = vDiscountCard;
						DiscountCardOnChange(Items.DiscountCard);
					EndIf;
				EndIf;
			ElsIf Parameters.Key.IsEmpty() Then
				Object.DiscountCard = vDiscountCard;
				DiscountCardOnChange(Items.DiscountCard);
			EndIf;
			// Activate form
			Activate();
		EndIf;
		// Check if something was found
		If Not ValueIsFilled(vCard) And Not ValueIsFilled(vDiscountCard) Then
			ShowMessageBox(, NStr("en='Reservation: Card was not found!';ru='Бронь: Карта не найдена!';de='Reservierung: Die Karte wurde nicht gefunden!'"), 3);
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupIDOnChange(pItem)
	// Check if there is another active guest group with this description
	vOtherGroupStruct = FindGuestGroupByID(Object.Hotel, Object.GuestGroup, TrimAll(GuestGroupID));
	If vOtherGroupStruct <> Undefined Then     
		vMsg = NStr("en='Another group with code '; ru='В базе данных уже есть группа с кодом '; de='Die Datenbank hat bereits eine Gruppe mit einem Code '") + vOtherGroupStruct.Code + NStr("en=' exists with given Ref.#: '; ru=' и совпадающим Ref.#: '; de=' und einer passenden Ref.#: '") + TrimAll(GuestGroupID);
		tcCommonFunctionOnClientServer.UserMessage(vMsg, vOtherGroupStruct.GuestGroup, "GuestGroupID");
	EndIf;
	// Save group description
	GroupIDOnChangeAtServer();
	Modified = True;
EndProcedure // GuestGroupIDOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem)
	If ValueIsFilled(pItem.EditText) Then
		Items.GuestGroupDescription.Enabled = True;
		Items.GuestGroupID.Enabled = True;
		Items.GuestGroupCreateDate.Enabled = True;
	Else
		Items.GuestGroupDescription.Enabled = False;
		Items.GuestGroupID.Enabled = False;
		Items.GuestGroupCreateDate.Enabled = False;
	EndIf;
	GuestGroupOnChangeAtServer();
EndProcedure // GuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	If pWait = 0 Then
		pStandardProcessing = True;
		pChoiceData = Undefined;
	ElsIf IsBlankString(pText) Then
		pStandardProcessing = True;
		pChoiceData = Undefined;
		Object.Customer = Undefined;
		ThisObject.Modified = True;
	Else
		pStandardProcessing = False;
		vText = TrimAll(pText);
		If StrLen(vText) > 2 Then
			vChoiceDataAddress = GetCustomersChoiceDataList(vText);
			pChoiceData = GetFromTempStorage(vChoiceDataAddress);
		EndIf;
		ThisObject.Modified = True;
	EndIf;
EndProcedure // CustomerAutoComplete

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	// Get guest last name, first name and second name
	vSelLastName = "";
	vSelFirstName = "";
	vSelSecondName = "";
	If ValueIsFilled(Object.Guest) Then
		vSelLastName = tcOnServer.cmGetAttributeByRef(Object.Guest, "LastName");
		vSelFirstName = tcOnServer.cmGetAttributeByRef(Object.Guest, "FirstName");
		vSelSecondName = tcOnServer.cmGetAttributeByRef(Object.Guest, "SecondName");
	Else
		vSelGuest = pItem.EditText;
		vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
		vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
		vSelLastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
		If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
			vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
			vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
			vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
			vSelFirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
			If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vSelSecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
			EndIf;
		EndIf; 
	EndIf;
	// Get clients search form
	#If ThickClientOrdinaryApplication Then
	   	vFrm = GetForm("Catalog.Clients.ChoiceForm", New Structure("ChoiceMode", True), pItem);
		vFrm.MultipleChoice = False;
		vFrm.SelLastName = vSelLastName;
		vFrm.SelFirstName = vSelFirstName;
		vFrm.SelSecondName = vSelSecondName;
		vFrm.Open();
	#Else
	   	vFrm = OpenForm("Catalog.Clients.ChoiceForm", New Structure("ChoiceMode, MultipleChoice, SelLastName, SelFirstName, SelSecondName", True, False, vSelLastName, vSelFirstName, vSelSecondName), pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	#EndIf
EndProcedure // GuestStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	// Get client form
	If ValueIsFilled(Object.Guest) Then
		OpenForm("Catalog.Clients.ObjectForm", New Structure("Key", Object.Guest), pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	Else
		vLastName = "";
		vFirstName = "";
		vSecondName = "";
		vSelGuest = pItem.EditText;
		vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
		vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
		vLastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
		If vLastNameLastCharNumber <> StrLen(vSelGuest) Then
			vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
			vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
			vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
			vFirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
			If vFirstNameLastCharNumber <> StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vSecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
			EndIf;
		EndIf;
		#If ThickClientOrdinaryApplication Then
			vFrm = GetForm("Catalog.Clients.ObjectForm", , pItem, ThisObject.UUID);
			vFrm.LastName = vLastName;
			vFrm.FirstName = vFirstName;
			vFrm.SecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
			vFrm.Open();
		#Else
			vParams = New Structure("SelLastName, SelFirstName, SelSecondName", vLastName, vFirstName, vSecondName);
			vFrm = OpenForm("Catalog.Clients.ObjectForm", vParams, pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
		#EndIf
	EndIf;
EndProcedure // GuestOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckGuestRemarksOnClient(pItem)
	If TrimAll(pItem.Name) = "SelGuest1" Then
		vValue = Object["Guest"];
	Else
		vValue = ThisObject[StrReplace(TrimAll(pItem.Name), "Sel", "")];
	EndIf;
	CheckGuestRemarksAtServer(vValue);
EndProcedure // CheckGuestRemarksOnClient

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(pSelectedValue) Then
		If TypeOf(pSelectedValue) = Type("CatalogRef.Clients") Then
			Object.Guest = pSelectedValue;
			SelGuest1 = tcOnServer.cmGetAttributeByRef(pSelectedValue, "FullName");
			LastGuestFullName = SelGuest1;
			pItem.TextEdit = False;
			vPhone = SMS.GetValidPhoneNumber(tcOnServer.cmGetAttributeByRef(pSelectedValue, "Phone"));
			If Not IsBlankString(vPhone) And IsBlankString(Object.Phone) Then
				Object.Phone = vPhone;
			EndIf;
			vEMail = tcOnServer.cmGetAttributeByRef(pSelectedValue, "EMail");
			If Not IsBlankString(vEMail) And IsBlankString(Object.EMail) Then
				Object.EMail = vEMail;
			EndIf;
		ElsIf TypeOf(pSelectedValue) = Type("String") Then
			SelGuest1 = pSelectedValue;
			Object.Guest = tcOnServer.cmGetCatalogItemRefByCode("Clients", "", True);
			pItem.TextEdit = True;
		EndIf;
		GuestOnChangeAtServer();
	Else
		Object.Guest = tcOnServer.cmGetCatalogItemRefByCode("Clients",, True);
		pItem.TextEdit = True;
	EndIf;
	CheckGuestRemarksOnClient(pItem);
	ThisObject.Modified = True;
EndProcedure // GuestChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	If pWait = 0 Then
		pStandardProcessing = True;
		pChoiceData = Undefined;
	ElsIf IsBlankString(pText) Then
		pStandardProcessing = True;
		pChoiceData = Undefined;
		Object.Guest = Undefined;
		ThisObject[pItem.Name] = "";
		LastGuestFullName = "";
		ThisObject.Modified = True;
	Else
		pStandardProcessing = False;
		If ValueIsFilled(Object.Guest) Then
			pItem.TextEdit = False;
			SelGuest1 = TrimR(LastGuestFullName);
			vMessage = New UserMessage;
			vMessage.Field = "SelGuest1";
			vMessage.Text = NStr("en='The data can be changed in the guest card only! (To open the guest card, click the magnifying glass; To write a new guest, click the delete icon and type guest name in the field)';ru='Данные могут быть изменены только в карточке гостя! (Для того, чтобы открыть карточку гостя, нажмите кнопку с изображением лупы; Для того, чтобы создать нового гостя, нажмите кнопку с крестиком и введите ФИО гостя в поле)';de='Die Daten können nur in der Karte des Gastes geändert werden! (Um die Karte des Gastes zu öffnen, drücken Sie die Taste mit der Lupe; um einen neuen Gast zu erstellen, drücken Sie die Taste mit dem Kreuz und geben Sie den Namen und den Vornamen des Gastes ins Feld ein)'");
			vMessage.Message();
		Else
			#IF Not WebClient And Not MobileClient THEN
				If StrLen(pText) > 2 Then
					vChoiceDataUID = tcOnServer.cmGetGuestsChoiceDataList(pText);
					pChoiceData = GetFromTempStorage(vChoiceDataUID);
					If pChoiceData.Count() = 0 Then
						pChoiceData.Add(pText, NStr("en='--Guest not found--';ru='--Гость не найден--';de='--Gast nicht gefunden--'"));
					EndIf;
				Else
					pStandardProcessing = True;
					pChoiceData = Undefined;
				EndIf;
			#ELSE
				pStandardProcessing = True;
				pChoiceData = Undefined;
			#ENDIF
		EndIf;
		ThisObject.Modified = True;
	EndIf;
EndProcedure // GuestAutoComplete

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestTextEditEnd(pItem, pText, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(Object.Guest) Then
		If IsBlankString(pText) Then
			pItem.TextEdit = True;
			Object.Guest = Undefined;
			LastGuestFullName = "";
		ElsIf Lower(TrimAll(tcOnServer.cmGetAttributeByRef(Object.Guest, "FullName"))) <> Lower(TrimAll(pText)) And 
		      pItem.TextEdit Then
			pItem.TextEdit = False;
			SelGuest1 = LastGuestFullName;
			vMessage = New UserMessage;
			vMessage.Field = "SelGuest1";
			vMessage.Text = NStr("en='The data can be changed in the guest card only! (To open the guest card, click the magnifying glass; To write a new guest, click the delete icon and type guest name in the field)';ru='Данные могут быть изменены только в карточке гостя! (Для того, чтобы открыть карточку гостя, нажмите кнопку с изображением лупы; Для того, чтобы создать нового гостя, нажмите кнопку с крестиком и введите ФИО гостя в поле)';de='Die Daten können nur in der Karte des Gastes geändert werden! (Um die Karte des Gastes zu öffnen, drücken Sie die Taste mit der Lupe; um einen neuen Gast zu erstellen, drücken Sie die Taste mit dem Kreuz und geben Sie den Namen und den Vornamen des Gastes ins Feld ein)'");
			vMessage.Message();
		EndIf;
	Else
		pItem.TextEdit = True;
		If IsBlankString(pText) Then
			pStandardProcessing = False;
			pChoiceData = Undefined;
			Object.Guest = Undefined;
			ThisObject[pItem.Name] = "";
			LastGuestFullName = "";
		ElsIf StrLen(pText) > 2 Then
			#IF WebClient Or MobileClient THEN
				vChoiceDataUID = tcOnServer.cmGetGuestsChoiceDataList(pText);
				pChoiceData = GetFromTempStorage(vChoiceDataUID);
				If pChoiceData.Count() = 0 Then
					pChoiceData.Add(pText, NStr("en='--Guest not found--';ru='--Гость не найден--';de='--Gast nicht gefunden--'"));
				Else
					pChoiceData.Insert(0, TrimR(pText));
				EndIf;
			#ELSE
				pChoiceData = New ValueList();
				pChoiceData.Add(TrimR(pText));
			#ENDIF
		Else
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;
	EndIf;
	ThisObject.Modified = True;
EndProcedure // GuestTextEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestClearing(pItem, pStandardProcessing)
	Object.Guest = Undefined;
	Object.Phone = "";
	Object.EMail = "";
	Object.Fax = "";
	SelGuest1 = "";
	Items.SelGuest1.TextEdit = True;
	CheckGuestRemarksOnClient(pItem);
	Modified = True;
	// Read foreigner registry documents
	ReadForeignerRegistryDocuments();
EndProcedure // GuestClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure PhoneOnChange(pItem)
	If ValueIsFilled(Object.Phone) Then
		vList = PhoneOnChangeAtServer(Object.Phone);
		If vList.Count() > 0 And Not ValueIsFilled(Object.Guest) Then
			If vList.Count() = 1 Then
				vStructure = vList.Get(0).Value;
				Object.Guest = vStructure.Client;
				SelGuest1 = vStructure.ClientFullName; 
				GuestOnChangeAtServer();
				CheckGuestRemarksOnClient(Items.SelGuest1);
				ThisObject.Modified = True;
			Else
				ThisObject.ShowChooseFromList(New NotifyDescription("AfterClientChoiceByPhoneOrEMail", ThisObject), vList, pItem);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PhoneOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FaxOnChange(pItem)
	If ValueIsFilled(Object.Fax) Then
		vList = PhoneOnChangeAtServer(Object.Fax);
		If vList.Count() > 0 And Not ValueIsFilled(Object.Guest) Then
			If vList.Count() = 1 Then
				vStructure = vList.Get(0).Value;
				Object.Guest = vStructure.Client;
				SelGuest1 = vStructure.ClientFullName; 
				GuestOnChangeAtServer();
				CheckGuestRemarksOnClient(Items.SelGuest1);
				ThisObject.Modified = True;
			Else
				ThisObject.ShowChooseFromList(New NotifyDescription("AfterClientChoiceByPhoneOrEMail", ThisObject), vList, pItem);
			EndIf;
		EndIf;
	Else
		Items.AddPhone2.Visible = True;
		Items.Fax.Visible = false;
	EndIf;
	ThisObject.Modified = True;
EndProcedure // FaxOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure EMailOnChange(pItem)
	If Not ValueIsFilled(Object.Phone) Then
		If ValueIsFilled(Object.EMail) And Not ValueIsFilled(Object.Guest) Then
			vList = EMailOnChangeAtServer(Object.EMail);
			If vList.Count() = 1 Then
				vStructure = vList.Get(0).Value;
				Object.Guest = vStructure.Client;
				SelGuest1 = vStructure.ClientFullName; 
				GuestOnChangeAtServer();
				CheckGuestRemarksOnClient(Items.SelGuest1);
				ThisObject.Modified = True;
			Else
				ThisObject.ShowChooseFromList(New NotifyDescription("AfterClientChoiceByPhoneOrEMail", ThisObject), vList, pItem);
			EndIf;
		EndIf;
	EndIf;
	ThisObject.Modified = True;
EndProcedure // EMailOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PlannedPaymentMethodOnChange(pItem)
	PlannedPaymentMethodOnChangeAtServer();
	ThisObject.Modified = True;
EndProcedure // PlannedPaymentMethodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomQuotaStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCustomer = tcOnServer.cmGetCurrentUserAttribute("Customer");
	vContract = PredefinedValue("Catalog.Contracts.EmptyRef");
	If Not ValueIsFilled(vCustomer) Then
		vCustomer = Object.Customer;
		vContract = Object.Contract;
	EndIf;
	vFilter = New Structure("Customer, Contract, Hotel", vCustomer, vContract, Object.Hotel);
	OpenForm("Catalog.RoomQuotas.ChoiceForm", New Structure("Filter, ChoiceMode", vFilter, True), pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // RoomQuotaStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vFilter = New Structure("Hotel", tcOnServer.cmGetCurrentHotelAttribute());
	OpenForm("Catalog.Customers.ChoiceForm", New Structure("Filter, ChoiceMode", vFilter, True), pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // CustomerStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vKidsAgeArray = New Array;
	For i = 1 To NumberOfKids Do
		vKidsAgeArray.Add(ThisObject["KidAge"+i]);
	EndDo;
	// APDEX
	vKeyOperation = "Catalog.RoomTypes.Form.tcChoiceForm.OpenForm";    
	vApdexRemarks = GetRemarksForAPDEX();
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);
	
	vParams = New Structure("Hotel, RoomType, CheckInDate, CheckOutDate, Duration, RoomRate, ClientType, RoomQuota, NumberOfAdults, NumberOfKids, AgeArray", 
	Object.Hotel, Object.RoomType, Object.CheckInDate, Object.CheckOutDate, Object.Duration, Object.RoomRate, Object.ClientType, Object.RoomQuota, NumberOfAdults, NumberOfKids, vKidsAgeArray);
	vFrm = OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", vParams, pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // RoomTypeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomFieldOnChange(pItem)
	ThisObject.Modified = True;
EndProcedure // CustomFieldOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	vRoomPopUpTasksArray = New Array;
	vRoomType = pSelectedValue;
	If TypeOf(pSelectedValue) = Type("Structure") Then
		If ValueIsFilled(pSelectedValue.CheckInDate) And 
		   ValueIsFilled(pSelectedValue.CheckOutDate) And 
		   pSelectedValue.CheckOutDate > pSelectedValue.CheckInDate Then
			Object.CheckInDate = pSelectedValue.CheckInDate;
			Object.CheckOutDate = pSelectedValue.CheckOutDate;
			Object.Duration = pSelectedValue.Duration;
		EndIf;
		vRoomType = pSelectedValue.RoomType;
		If Object.RoomType <> vRoomType And ValueIsFilled(pSelectedValue.RoomRate) Then
			ClearOccupationPercents(CurrentDate(), pSelectedValue.RoomRate, Object.RoomType, vRoomType);
		EndIf;
		Object.RoomType = vRoomType;
		Object.RoomRate = pSelectedValue.RoomRate;
		If ValueIsFilled(Object.RoomRate) Then
			Object.RoomRateType = tcOnServer.cmGetAttributeByRef(Object.RoomRate, "RoomRateType");
			Object.DoNotPrintRate = tcOnServer.cmGetAttributeByRef(Object.RoomRate, "DoNotPrintRate");
			SetDurationCaption();
		EndIf;				
		vClientTypeHasChanged = False;
		If Object.ClientType <> pSelectedValue.ClientType Then
			vClientTypeHasChanged = True;
			Object.ClientType = pSelectedValue.ClientType;
		EndIf;
		If vClientTypeHasChanged Then 
			ClientTypeConfirmationTextChange();
		EndIf;
		Object.RoomQuota = pSelectedValue.RoomQuota;
		vRoomPopUpTasksArray = MainParametersChangeAtServer(vClientTypeHasChanged);
		// Show room pop up tasks
		If ValueIsFilled(Object.Room) And vRoomPopUpTasksArray.Count() > 0 Then
			For Each vRoomPopUpTask In vRoomPopUpTasksArray Do
				ShowMessageBox(, vRoomPopUpTask, , NStr("en='Information';de='Information';ru='Информация'"));
			EndDo;
		EndIf;
	ElsIf TypeOf(vRoomType) = Type("CatalogRef.RoomTypes") Then
		If Object.RoomType <> vRoomType And ValueIsFilled(Object.RoomRate) Then
			ClearOccupationPercents(CurrentDate(), Object.RoomRate, Object.RoomType, vRoomType);
		EndIf;
		Object.RoomType = vRoomType;
		RoomTypeOnChangeAtServer(True, False);
	ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.Rooms") Then
		tcOnClient.AskRoomChangeQuestion(pSelectedValue, Object);
		// Show room pop up tasks
		vRoomPopUpTasksArray = RoomChoiceProcessingAtServer(pSelectedValue);
		If vRoomPopUpTasksArray.Count() > 0 Then
			For Each vRoomPopUpTask In vRoomPopUpTasksArray Do
				ShowMessageBox(, vRoomPopUpTask, , NStr("en='Information';de='Information';ru='Информация'"));
			EndDo;
		EndIf;
	EndIf;
	vTypes = GetTypesArrayByRoomType(vRoomType);
	Items.AccommodationType.ChoiceList.LoadValues(vTypes);
	For Each vGRow In GuestsInGroup Do
		Items["AccommodationType" + Format(GuestsInGroup.IndexOf(vGRow) + 2, "NFD=0; NG=")].ChoiceList.LoadValues(vTypes);
	EndDo;
	RefreshDocumentRepresentation();
	ThisObject.Modified = True;
EndProcedure // RoomTypeChoiceProcessing

// ----------------------------------------------------------------------------
&AtServer
Function MainParametersChangeAtServer(pClientTypeHasChanged)
	RoomTypeOnChangeAtServer(False, pClientTypeHasChanged);
	RoomQuotaOnChangeAtServer(False, , True);
	If ValueIsFilled(Object.RoomType) And 
		ValueIsFilled(Object.AccommodationType) And 
		ValueIsFilled(Object.CheckInDate) And 
		ValueIsFilled(Object.CheckOutDate) And 
		Object.CheckOutDate > Object.CheckInDate And 
		Not ValueIsFilled(Object.Room) Then
		GetDefaultRoomAtServer();
	EndIf;
	vRoomPopUpTasksArray = RoomOnChangeAtServer(False, , pClientTypeHasChanged);
	RoomRateOnChangeAtServer(, True);
	Return vRoomPopUpTasksArray;
EndFunction // MainParametersChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PayerOnChange(pItem)
	vIsNeedToOpenForm = PayerOnChangeAtServer();
	If vIsNeedToOpenForm Then
		vFrm = GetForm("Catalog.Customers.ChoiceForm", New Structure("CurrentRow, ChoiceMode", Object.Customer, True), Items.Customer);
		#If ThinClient Or WebClient Or MobileClient Then
			vFrm.CloseOnOwnerClose = True;
			vFrm.CloseOnChoice = True;
			vFrm.Open();
		#Else
			vFrm.MultipleChoice = False;
			vFrm.CloseOnOwnerClose = True;
			vFrm.CloseOnChoice = True;
			vFrm.Open();
		#EndIf
	EndIf;
	ThisObject.Modified = True;
EndProcedure // PayerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerOnChange(pItem)
	CustomerOnChangeAtServer();
	RefreshDocumentRepresentation();
	If ValueIsFilled(Object.Customer) Then
		Items.Contract.ReadOnly = False;
	Else
		Items.Contract.ReadOnly = True;
	EndIf;
	ThisObject.Modified = True;
EndProcedure // CustomerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ContractOnChange(pItem)
	vMessage = "";
	ContractOnChangeAtServer(, vMessage);
	RefreshDocumentRepresentation();
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndIf;
	ThisObject.Modified = True;
EndProcedure // ContractOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypeOnChange(pItem, pRecalculateServices = True)
	AccommodationTypeOnChangeAtServer(pRecalculateServices, , True);
	ThisObject.Modified = True;
EndProcedure // AccommodationTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	pChoiceData = AccommodationTypeStartChoiceAtClient(False);
EndProcedure // AccommodationTypeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestAccommodationTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	pChoiceData = AccommodationTypeStartChoiceAtClient(True);
EndProcedure // ExtraGuestAccommodationTypeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeOnChange(pItem, pRecalculateServices = True, pRecalculateDiscounts = False)
	If ValueIsFilled(Object.RoomRate) Then
		ClearOccupationPercents(CurrentDate());
	EndIf;
	RoomTypeOnChangeAtServer(pRecalculateServices, pRecalculateDiscounts);
	RefreshDocumentRepresentation();
	ThisObject.Modified = True;
EndProcedure // RoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateOnChange(pItem)
	CheckOutDateOnChangeAtServer();
EndProcedure // CheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(pItem)
	CheckInDateOnChangeAtServer();
EndProcedure // CheckInDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem)
	DurationOnChangeAtServer();
EndProcedure // DurationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomQuotaOnChange(pItem)
	RoomQuotaOnChangeAtServer(True);
	RefreshDocumentRepresentation();
	ThisObject.Modified = True;
EndProcedure // RoomQuotaOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentOnChange(pItem)
	AgentOnChangeAtServer();
	BuildCommissionGroupCollapsedTitle();
	ThisObject.Modified = True;
EndProcedure // AgentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestOnChange(pItem)
	GuestOnChangeAtServer();	
	CheckGuestRemarksOnClient(pItem);
	ThisObject.Modified = True;
EndProcedure // GuestOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionServiceGroupOnChange(pItem)
	AgentCommissionServiceGroupOnChangeAtServer();
	BuildCommissionGroupCollapsedTitle();
	ThisObject.Modified = True;
EndProcedure // AgentCommissionServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationStatusOnChange(pItem)
	vResult = AccommodationStatusOnChangeAtServer();
	If ValueIsFilled(vResult) Then
		tcCommonFunctionOnClientServer.UserMessage(vResult);
	EndIf;
EndProcedure // AccommodationStatusOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionTypeOnChange(pItem)
	AgentCommissionTypeOnChangeAtServer();
	BuildCommissionGroupCollapsedTitle();
	ThisObject.Modified = True;
EndProcedure // AgentCommissionTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	RoomRateOnChangeAtServer(, True);
	RefreshDocumentRepresentation();
	ThisObject.Modified = True;
EndProcedure // RoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vRoomPropertiesList = FillRoomPropertiesList();
	vRoomPropertiesList.ShowCheckItems(New NotifyDescription("RoomPropertiesPresentationStartChoice_AfterInput", ThisObject, New Structure()), NStr("en='Check room properties...'; ru='Отметьте свойства номеров...'; de='Markieren Zimmereigenschaften...'"));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RemarksOnChange(pItem)
	BuildThisObjectRemarksDataDecoration();
	ThisObject.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HousekeepingRemarksOnChange(pItem)
	BuildThisObjectRemarksDataDecoration();
	ThisObject.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInTimeOnChange(pItem)
	CheckInTimeOnChangeAtServer();
	ThisObject.Modified = True;
EndProcedure // CheckInTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutTimeOnChange(pItem)
	CheckOutTimeOnChangeAtServer();
	ThisObject.Modified = True;
EndProcedure // CheckOutTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInTimeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = GetDayTimes(pItem.Name);
	ShowChooseFromList(New NotifyDescription("CheckInTimeAfterChoice", ThisObject, New Structure()), vList, pItem);
EndProcedure // CheckInTimeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutTimeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = GetDayTimes(pItem.Name);
	ShowChooseFromList(New NotifyDescription("CheckOutTimeAfterChoice", ThisObject, New Structure()), vList, pItem);
EndProcedure // CheckOutTimeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupDescriptionOnChange(pItem)
	// Check if there is another active guest group with this description
	vOtherGroupStruct = FindGuestGroupByDescription(Object.Hotel, Object.GuestGroup, TrimAll(GuestGroupDescription));
	If vOtherGroupStruct <> Undefined Then
		vUM = New UserMessage();
		vUM.Field = "GuestGroupDescription";
		vUM.DataKey = vOtherGroupStruct.GuestGroup;
		vUM.Text = NStr("en='Another group with code '; ru='В базе данных уже есть группа с кодом '; de='Die Datenbank hat bereits eine Gruppe mit einem Code '") + vOtherGroupStruct.Code + NStr("en=' exists with given description!'; ru=' и совпадающим описанием!'; de=' und einer passenden Beschreibung!'");
		vUM.Message();
	EndIf;
	// Save group description
	GroupDescriptionOnChangeAtServer();
	ThisObject.Modified = True;
EndProcedure // GuestGroupDescriptionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupCreateDateOnChange(pItem)
	GuestGroupCreateDateOnChangeAtServer();
	If ValueIsFilled(Object.Contract) Then
		vMessage = "";
		ContractOnChangeAtServer(, vMessage, True);
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf;
	EndIf;
	ThisObject.Modified = True;
EndProcedure // GuestGroupCreateDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	tcOnClient.AskRoomChangeQuestion(pSelectedValue, Object);
	vRoomPopUpTasksArray = RoomChoiceProcessingAtServer(pSelectedValue);
	RefreshDocumentRepresentation();
	// Show room pop up tasks
	If vRoomPopUpTasksArray.Count() > 0 Then
		For Each vRoomPopUpTask In vRoomPopUpTasksArray Do
			ShowMessageBox(, vRoomPopUpTask, , NStr("en='Information';de='Information';ru='Информация'"));
		EndDo;
	EndIf;
	ThisObject.Modified = True;
EndProcedure // RoomChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(Object.Hotel) Then
		vHotel = Object.Hotel;
	Else
		vHotel = tcOnServer.cmGetCurrentHotelAttribute();
	EndIf;
	vRoomType = Undefined;
	If ValueIsFilled(Object.RoomType) Then
		vRoomType = Object.RoomType;
	EndIf;
	vRoomQuota = Undefined;
	If ValueIsFilled(Object.RoomQuota) Then
		vRoomQuota = Object.RoomQuota;
	EndIf;
	vRoomQuantity = 1;
	vNumberOfBeds = 0;
	If Object.NumberOfBeds <> 0 Then
		vNumberOfBeds = Int(Object.NumberOfBeds/vRoomQuantity);
	EndIf;
	vNumberOfRooms = 0;
	If Object.NumberOfRooms <> 0 Then
		vNumberOfRooms = Int(Object.NumberOfRooms/vRoomQuantity);
	EndIf;
	vCheckInDate = Max(CurrentDate(), Object.CheckInDate);
	vCheckOutDate = Object.CheckOutDate;
	If vCheckOutDate <= vCheckInDate Then
		vCheckInDate = Object.CheckInDate;
	EndIf;
	vBedsSetup = Object.BedsSetup;

	#If ThickClientOrdinaryApplication Then
		vFrm = GetForm("Catalog.Rooms.Form.ChoiceForm", , pItem);
		vFrm.SelDateFrom = vCheckInDate;
		vFrm.SelDateTo = vCheckOutDate;
		If vRoomQuota <> Undefined Then
			vFrm.SelRoomQuota = vRoomQuota;
		Else
			vFrm.SelRoomQuota = Undefined;
		EndIf;
		If vRoomType <> Undefined Then
			vFrm.SelRoomType = vRoomType;
		Else
			vFrm.SelRoomType = Undefined;
		EndIf;
		vFrm.SelNumberOfBeds = vNumberOfBeds;
		vFrm.SelNumberOfRooms = vNumberOfRooms;
		vFrm.SelRoomProperties = GetRoomPropertiesValueList();
		vFrm.Hotel = vHotel;
		vFrm.ChoiceMode = True;
		vFrm.Open();
	#Else
		vRoomProperties = RoomProperties;
		vRoomPropertiesFromGuest = RoomPropertiesFromGuest;
		vRoomPropertiesAll = New ValueList();
		For Each vRow In vRoomProperties do
			vRoomPropertiesAll.Add(vRow.Value);
		EndDo; 		
		For Each vRow In vRoomPropertiesFromGuest do
			If vRoomPropertiesAll.FindByValue(vRow.Value) =Undefined Then
				vRoomPropertiesAll.Add(vRow.Value);
			EndIf;
		EndDo; 
		OpenForm("Catalog.Rooms.Form.tcChoiceForm", New Structure("Hotel, DateFrom, DateTo, RoomType, RoomQuota, Company, NumberOfRooms, NumberOfBeds, SelRoomProperties, BedsSetup", vHotel, vCheckInDate, vCheckOutDate, vRoomType, vRoomQuota, Undefined, vNumberOfRooms, vNumberOfBeds, vRoomPropertiesAll, vBedsSetup), pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	#EndIf
EndProcedure // RoomStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesRoomStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.RoomRates.CurrentData;
	If vCurData = Undefined Then
		Return;
	EndIf;
	If ValueIsFilled(Object.Hotel) Then
		vHotel = Object.Hotel;
	Else
		vHotel = tcOnServer.cmGetCurrentHotelAttribute();
	EndIf;
	vRoomType = Undefined;
	If ValueIsFilled(vCurData.RoomType) Then
		vRoomType = vCurData.RoomType;
	EndIf;
	vAccommodationType = Object.AccommodationType;
	If ValueIsFilled(vCurData.AccommodationType) Then
		vAccommodationType = vCurData.AccommodationType;
	EndIf;
	vRoomQuota = Undefined;
	If ValueIsFilled(Object.RoomQuota) Then
		vRoomQuota = Object.RoomQuota;
	EndIf;
	vNumberOfRooms = 0;
	If Object.NumberOfRooms <> 0 Then
		vNumberOfRooms = Object.NumberOfRooms;
	EndIf;
	vNumberOfBeds = 0;
	If Object.NumberOfBeds <> 0 Then
		vNumberOfBeds = Object.NumberOfBeds;
		If ValueIsFilled(vRoomType) And vRoomType <> Object.RoomType Then
			vNumberOfBeds = tcOnServer.GetNumberOfBedsForReservation(vRoomType, vAccommodationType);
		EndIf;
	EndIf;
	vCheckInDate = Max(CurrentDate(), (vCurData.AccountingDate + (vCurData.ChangeTime - BegOfDay(vCurData.ChangeTime))));
	vCheckOutDate = Object.CheckOutDate;
	If vCheckOutDate <= vCheckInDate Then
		vCheckInDate = Object.CheckInDate;
	EndIf;
	vBedsSetup = Object.BedsSetup;
	
	#IF ThickClientOrdinaryApplication THEN
		vFrm = GetForm("Catalog.Rooms.Form.ChoiceForm", , pItem);
		vFrm.SelDateFrom = vCheckInDate;
		vFrm.SelDateTo = vCheckOutDate;
		vFrm.SelRoomQuota = vRoomQuota;
		vFrm.SelRoomType = vRoomType;
		vFrm.SelNumberOfBeds = vNumberOfBeds;
		vFrm.SelNumberOfRooms = vNumberOfRooms;
		vFrm.SelRoomProperties = GetRoomPropertiesValueList();
		vFrm.Hotel = vHotel;
		vFrm.ChoiceMode = True;
		vFrm.Open();
	#Else
		OpenForm("Catalog.Rooms.Form.tcChoiceForm", New Structure("Hotel, DateFrom, DateTo, RoomType, RoomQuota, Company, NumberOfRooms, NumberOfBeds, BedsSetup", vHotel, vCheckInDate, vCheckOutDate, vRoomType, vRoomQuota, Undefined, vNumberOfRooms, vNumberOfBeds, vBedsSetup), pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	#EndIf
EndProcedure // RoomRatesRoomStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(pItem)
	tcOnClient.AskRoomChangeQuestion(Object.Room, Object);
	vRoomPopUpTasksArray = RoomOnChangeAtServer();
	RefreshDocumentRepresentation();
	// Show room pop up tasks
	If vRoomPopUpTasksArray.Count() > 0 Then
		For Each vRoomPopUpTask In vRoomPopUpTasksArray Do
			ShowMessageBox(, vRoomPopUpTask, , NStr("en='Information';de='Information';ru='Информация'"));
		EndDo;
	EndIf;
	ThisObject.Modified = True;
EndProcedure // RoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FixReservationConditionsOnChange(pItem)
	FixReservationConditionsOnChangeAtServer();
EndProcedure // FixReservationConditionsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionOnChange(pItem)
	AgentCommissionOnChangeAtServer();
	BuildCommissionGroupCollapsedTitle();
	ThisObject.Modified = True;
EndProcedure // AgentCommissionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(pItem)
	// Check rights to automatically open folios list after document write
	If pItem = Undefined Then
		If tcOnServer.cmCheckUserPermissionsAtServer("DoNotOpenFoliosListAfterAccommodationChange") Then
			Return;
		EndIf;
	EndIf;
	
	// APDEX
	vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";   
	vApdexRemarks = GetRemarksForAPDEX();
	vUUID = New UUID;
	APDEXPerformanceSystemOnClientServer.StartManualTimeIntervalMeasurement(vKeyOperation, vUUID, vApdexRemarks);

	If (WasPosted = False Or ThisObject.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "OpenFolios"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vAddRoomsToAllotment = False;
		vAllotmentBalances = Undefined;
		vResult = WriteAtServer(, vWarning, , , vAddRoomsToAllotment, vAllotmentBalances);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;
		vBreakProcessing = False;
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.UserMessage(vResult);
			EndIf;
			vBreakProcessing = True;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;         
	 	If vAddRoomsToAllotment Then
			ShowQueryBox(New NotifyDescription("AddRoomsToAllotment", ThisObject, New Structure("AllotmentBalances", vAllotmentBalances)), 
						 NStr("en='Add missing rooms to the allotment?'; ru='Добавить недостающие номера в квоту?'; de='Fehlende Zimmer zum Allotment hinzufügen?'"), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
		If vBreakProcessing Then
			Return;
		EndIf;
	EndIf;
	#If Not ThickClientOrdinaryApplication Then
		vParametersStructure = New Structure("IsNew, WasPosted, IsFormModified, DocRef", IsNew, WasPosted, ThisObject.Modified, Object.Ref);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), , Object.Ref);
		// APDEX
		APDEXPerformanceSystemOnClient.FinishManualTimeIntervalMeasurementNotGlobal(vUUID);
	#Else
		vLastAcc = Object;
		
		// Try to find guest master folio in the document charging rules.
		vGuestMasterFolio = Undefined;
		For Each vCRRow In vLastAcc.ChargingRules Do
			If ValueIsFilled(vCRRow.ChargingFolio) And vCRRow.ChargingFolio.IsMaster Then
				If ValueIsFilled(vLastAcc.Guest) And ValueIsFilled(vCRRow.Owner) And vLastAcc.Guest = vCRRow.Owner Then
					vGuestMasterFolio = vCRRow.ChargingFolio;
					Break;
				EndIf;
			EndIf;
		EndDo;
		
		// Open list of folios
		vFrm = Documents.Folio.GetListForm();
		// Reset all other filters
		vFrm.ResetLeftFilterFolios();
		vFrm.ResetRightFilterFolios();
		
		If ValueIsFilled(vGuestMasterFolio) Then
			// Set filter by guest and show acive folios only
			vFrm.SelClientStrLeft = TrimR(vLastAcc.Guest.Description);
			vFrm.SelClientLeft = vLastAcc.Guest;
			vFrm.SelFolioIsClosedLeft = False;
			vFrm.SelFolioIsClosedRight = False;
			vFrm.SelFilterByIsClosedLeft = True;
			vFrm.SelFilterByIsClosedRight = False;
			vFrm.SelFilterByParentDocLeft = False;
			vFrm.SelFilterByParentDocRight = False;
		Else
			// Set filter by room and guest group
			vFrm.SelGuestGroupLeft = vLastAcc.GuestGroup;
			If ValueIsFilled(vLastAcc.GuestGroup) Then
				vFrm.SelGuestGroupDescriptionLeft = TrimAll(vLastAcc.GuestGroup.Description);
			Else
				vFrm.SelGuestGroupDescriptionLeft = "";
			EndIf;
			vFrm.SelRoomLeft = vLastAcc.Room;
			vFrm.SelRoomRight = vLastAcc.Room;
			vFrm.SelFolioIsClosedLeft = False;
			vFrm.SelFolioIsClosedRight = False;
			vFrm.SelFilterByIsClosedLeft = False;
			vFrm.SelFilterByIsClosedRight = False;
			vFrm.SelFilterByParentDocLeft = True;
			vFrm.SelFilterByParentDocRight = False;
		EndIf;
		vFrm.SelParentDoc = vLastAcc.Ref;
		vFrm.SelHotel = vLastAcc.Hotel;
		// Open folios list form	
		If Not vFrm.IsOpen() Then
			vFrm.WindowAppearanceMode = WindowAppearanceModeVariant.Maximized;
		EndIf;
		vFrm.Open();
		
		// Check if there are any folios with debts for the current guest
		If ValueIsFilled(vLastAcc.Guest) Then
			If Not ValueIsFilled(vGuestMasterFolio) Then
				vDebtFolios = cmGetClientFoliosWithDebts(vLastAcc.Guest, vLastAcc.GuestGroup);
				If vDebtFolios.Count() > 0 Then
					tcCommonFunctionOnClientServer.UserMessage(NStr("ru='У гостя " + TrimAll(vLastAcc.Guest) + " есть долги/переплаты прошлых периодов! В лицевых счетах будет открыта правая панель содержащая список фолио с долгами.'; 
					                  |de='There are folios with previous period debts/deposits for the " + TrimAll(vLastAcc.Guest) + " client! The list of such folios will be opened in the right panel.'; 
					                  |en='There are folios with previous period debts/deposits for the " + TrimAll(vLastAcc.Guest) + " client! The list of such folios will be opened in the right panel.'"));
					// Open right panel with list of such folios
					If vFrm.IsOpen() Then
						// Set up right folio list filter
						vFrm.SelFoliosListRight = vDebtFolios;
						vFrm.SelHotel = Catalogs.Hotels.EmptyRef();
						vFrm.SelClientRight = Catalogs.Clients.EmptyRef();
						vFrm.SelCustomerRight = Catalogs.Customers.EmptyRef();
						vFrm.SelContractRight = Catalogs.Contracts.EmptyRef();
						vFrm.SelGuestGroupRight = Catalogs.GuestGroups.EmptyRef();
						vFrm.SelRoomRight = Catalogs.Rooms.EmptyRef();
						vFrm.SelFolioNumberRight = "";
						vFrm.SelFolioIsClosedRight = False;
						vFrm.SelFilterByIsClosedRight = False;
						vFrm.SelFilterByParentDocRight = False;
						// Do show
						vFrm.fmShowRightFoliosListPanel();
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	#EndIf
EndProcedure // OpenFolios

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfKidsOnChange(pItem)
	NumberOfKidsOnChangeAtServer();
	ThisObject.Modified = True;
EndProcedure // NumberOfKidsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfAdultsOnChange(pItem)
	If NumberOfAdults < 0 Then
		NumberOfAdults = 1;
	EndIf;
	If (NumberOfAdults = 1 And NumberOfKids = 0 Or NumberOfAdults = 0) Or Object.IsForFolioSplit Or OneGuestMode Then
		Items.AccommodationType.Enabled = True;
		Items.AccommodationType.TextEdit = True;
	Else
		Items.AccommodationType.Enabled = False;
		Items.AccommodationType.TextEdit = False;
	EndIf;
	CheckGuestFieldCount();
	LastNumberOfAdults = NumberOfAdults;
	ThisObject.Modified = True;
EndProcedure // NumberOfAdultsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure KidAgeOnChange(pItem)
	If (NumberOfKids > 0 And NumberOfAdults > 0 Or NumberOfAdults > 1) And Not Object.IsForFolioSplit And Not OneGuestMode Then
		Items.AccommodationType.Enabled = False;
		Items.AccommodationType.TextEdit = False;
	Else
		Items.AccommodationType.Enabled = True;
		Items.AccommodationType.TextEdit = True;
	EndIf;
	CheckGuestFieldCount();
	ThisObject.Modified = True;
EndProcedure // KidAgeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestOnChange(pItem)
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	If vItemIndex > 1 Then
		vGuest = ThisObject["Guest" + vItemIndex];
		If ValueIsFilled(vGuest) Then
			vClientAge = GetClientAgeAtServer(vGuest, Object.CheckInDate);
			If vClientAge > 0 Then
				vKidIndex = vItemIndex - NumberOfAdults;
				If vKidIndex > 0 Then
					If ThisObject["KidAge"+vKidIndex] <> vClientAge Then
						ThisObject["KidAge"+vKidIndex] = vClientAge;
						KidAgeOnChange(Items["KidAge"+vKidIndex]);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		vGiGRowIndex = vItemIndex-2;
		Try
			vGiGRow = GuestsInGroup.Get(vGiGRowIndex);
			vGiGRow.Guest = ThisObject[pItem.Name];
			If ValueIsFilled(ThisObject["AccommodationType" + vItemIndex]) Then
				vGiGRow.IsAnnulation = False;
				vGiGRow.IsGuest = True;
				vGiGRow.GuestRef = vGuest;
				TotalSum = CalculateTotalServices(, , False, False);
			EndIf;
			If ValueIsFilled(vGuest) Then
				Items["SelGuest"+vItemIndex].TextEdit = False;
			Else
				Items["SelGuest"+vItemIndex].TextEdit = True;
			EndIf;
			vGiGRow.LegalRepresentative = ThisObject["LegalRepresentative"+vItemIndex];
			vGiGRow.RelationType = ThisObject["RelationType"+vItemIndex];
		Except
		EndTry;
	EndIf;
	CheckGuestRemarksOnClient(pItem);
	// Read foreigner registry documents
	ReadForeignerRegistryDocuments();
EndProcedure // AddGuestOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	vGuest = ThisObject["Guest"+vItemIndex];
	vSelLastName = "";
	vSelFirstName = "";
	vSelSecondName = "";
	If ValueIsFilled(vGuest) Then
		vSelLastName = tcOnServer.cmGetAttributeByRef(vGuest, "LastName");
		vSelFirstName = tcOnServer.cmGetAttributeByRef(vGuest, "FirstName");
		vSelSecondName = tcOnServer.cmGetAttributeByRef(vGuest, "SecondName");
	Else
		// Get guest last name, first name and second name
		vSelGuest = pItem.EditText;
		vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
		vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
		vSelLastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
		If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
			vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
			vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
			vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
			vSelFirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
			If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vSelSecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
			EndIf;
		EndIf; 
	EndIf;
	// Get clients search form
	#If ThickClientOrdinaryApplication Then
		vFrm = GetForm("Catalog.Clients.ChoiceForm", New Structure("ChoiceMode", True), pItem);
		vFrm.MultipleChoice = False;
		vFrm.SelLastName = vSelLastName;
		vFrm.SelFirstName = vSelFirstName;
		vFrm.SelSecondName = vSelSecondName;
		vFrm.Open();
	#Else
		vParams = New Structure("ChoiceMode, MultipleChoice, SelLastName, SelFirstName, SelSecondName", True, False, vSelLastName, vSelFirstName, vSelSecondName);
		OpenForm("Catalog.Clients.ChoiceForm", vParams, pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	#EndIf
EndProcedure // AddGuestStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	vGuest = ThisObject["Guest"+vItemIndex];
	// Get client form
	If ValueIsFilled(vGuest) Then
		OpenForm("Catalog.Clients.ObjectForm", New Structure("Key", vGuest), pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	Else
		vSelGuest = pItem.EditText;
		vSelLastName = "";
		vSelFirstName = "";
		vSelSecondName = "";
		vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
		vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
		vSelLastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
		If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
			vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
			vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
			vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
			vSelFirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
			If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vSelSecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
			EndIf;
		EndIf;
		#If ThickClientOrdinaryApplication Then
			vFrm = GetForm("Catalog.Clients.ObjectForm", New Structure("TemplateGuest", Object.Guest), pItem, New UUID());
			vFrm.LastName = vSelLastName;
			vFrm.FirstName = vSelFirstName;
			vFrm.SecondName = vSelSecondName;
			vFrm.Open();
		#Else
			OpenForm("Catalog.Clients.ObjectForm", New Structure("TemplateGuest, SelLastName, SelFirstName, SelSecondName", Object.Guest, vSelLastName, vSelFirstName, vSelSecondName), pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
		#EndIf
	EndIf;
EndProcedure // AddGuestOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestClearing(pItem, pStandardProcessing)
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	ThisObject["Guest"+vItemIndex] = "";
	ThisObject["LegalRepresentative"+vItemIndex] = Undefined;
	ThisObject["RelationType"+vItemIndex] = Undefined;
	Items["SelGuest"+vItemIndex].TextEdit = True;
	ThisObject[pItem.Name] = "";
	CheckGuestRemarksOnClient(pItem);
	ThisObject.Modified = True;
	// Read foreigner registry documents
	ReadForeignerRegistryDocuments();
EndProcedure // AddGuestClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	If ValueIsFilled(pSelectedValue) Then
		If TypeOf(pSelectedValue) = Type("CatalogRef.Clients") Then
			ThisObject["Guest"+vItemIndex] = pSelectedValue;
			ThisObject[pItem.Name] = tcOnServer.cmGetAttributeByRef(pSelectedValue, "FullName");
			ThisObject["LastGuestFullName"+vItemIndex] = ThisObject[pItem.Name];
			pItem.TextEdit = False;
		ElsIf TypeOf(pSelectedValue) = Type("String") Then
			ThisObject[pItem.Name] = pSelectedValue;
			ThisObject["Guest"+vItemIndex] = tcOnServer.cmGetCatalogItemRefByCode("Clients", "", True);
			pItem.TextEdit = True;
		EndIf;
		AddGuestOnChange(pItem);
	Else
		ThisObject["Guest"+vItemIndex] = tcOnServer.cmGetCatalogItemRefByCode("Clients",, True);
		pItem.TextEdit = True;
	EndIf;
	CheckGuestRemarksOnClient(pItem);
	ThisObject.Modified = True;
EndProcedure // AddGuestChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	If pWait = 0 Then
		pStandardProcessing = True;
		pChoiceData = Undefined;
	ElsIf IsBlankString(pText) Then
		pStandardProcessing = True;
		pChoiceData = Undefined;
		vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
		ThisObject["Guest"+vItemIndex] = Undefined;
		ThisObject[pItem.Name] = "";
		ThisObject["LastGuestFullName"+vItemIndex] = "";
		ThisObject.Modified = True;
	Else
		pStandardProcessing = False;
		vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
		vGuest = ThisObject["Guest"+vItemIndex];
		If ValueIsFilled(vGuest) Then
			pItem.TextEdit = False;
			ThisObject[pItem.Name] = TrimR(ThisObject["LastGuestFullName"+vItemIndex]);
			vMessage = New UserMessage;
			vMessage.Field = pItem.Name;
			vMessage.Text = NStr("en='The data can be changed in the guest card only! (To open the guest card, click the magnifying glass; To write a new guest, click the delete icon and type guest name in the field)';ru='Данные могут быть изменены только в карточке гостя! (Для того, чтобы открыть карточку гостя, нажмите кнопку с изображением лупы; Для того, чтобы создать нового гостя, нажмите кнопку с крестиком и введите ФИО гостя в поле)';de='Die Daten können nur in der Karte des Gastes geändert werden! (Um die Karte des Gastes zu öffnen, drücken Sie die Taste mit der Lupe; um einen neuen Gast zu erstellen, drücken Sie die Taste mit dem Kreuz und geben Sie den Namen und den Vornamen des Gastes ins Feld ein)'");
			vMessage.Message();
		Else
			If StrLen(pText) > 2 Then
				#IF Not WebClient And Not MobileClient THEN
					vChoiceDataUID = tcOnServer.cmGetGuestsChoiceDataList(pText);
					pChoiceData = GetFromTempStorage(vChoiceDataUID);
					If pChoiceData.Count() = 0 Then
						pChoiceData.Add(pText, NStr("en='--Guest not found--';ru='--Гость не найден--';de='--Gast nicht gefunden--'"));
					EndIf;
				#ELSE
					pStandardProcessing = True;
					pChoiceData = Undefined;
				#ENDIF
			Else
				pStandardProcessing = True;
				pChoiceData = Undefined;
			EndIf;
		EndIf;
		ThisObject.Modified = True;
	EndIf;
EndProcedure // AddGuestAutoComplete

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestTextEditEnd(pItem, pText, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	vGuest = ThisObject["Guest"+vItemIndex];
	If ValueIsFilled(vGuest) Then
		If IsBlankString(pText) Then
			pItem.TextEdit = True;
			ThisObject["Guest"+vItemIndex] = Undefined;
			ThisObject["LastGuestFullName"+vItemIndex] = "";
		ElsIf Lower(TrimAll(tcOnServer.cmGetAttributeByRef(vGuest, "FullName"))) <> Lower(TrimAll(pText)) And
		      pItem.TextEdit Then
			pItem.TextEdit = False;
			ThisObject[pItem.Name] = ThisObject["LastGuestFullName"+vItemIndex];
			vMessage = New UserMessage;
			vMessage.Field = pItem.Name;
			vMessage.Text = NStr("en='The data can be changed in the guest card only! (To open the guest card, click the magnifying glass; To write a new guest, click the delete icon and type guest name in the field)';ru='Данные могут быть изменены только в карточке гостя! (Для того, чтобы открыть карточку гостя, нажмите кнопку с изображением лупы; Для того, чтобы создать нового гостя, нажмите кнопку с крестиком и введите ФИО гостя в поле)';de='Die Daten können nur in der Karte des Gastes geändert werden! (Um die Karte des Gastes zu öffnen, drücken Sie die Taste mit der Lupe; um einen neuen Gast zu erstellen, drücken Sie die Taste mit dem Kreuz und geben Sie den Namen und den Vornamen des Gastes ins Feld ein)'");
			vMessage.Message();
		EndIf;
	Else
		pItem.TextEdit = True;
		If IsBlankString(pText) Then
			pStandardProcessing = False;
			pChoiceData = Undefined;
			pItem.TextEdit = True;
			ThisObject["Guest"+vItemIndex] = Undefined;
			ThisObject["LastGuestFullName"+vItemIndex] = "";
		ElsIf StrLen(pText) > 2 Then
			#IF WebClient Or MobileClient THEN
				vChoiceDataUID = tcOnServer.cmGetGuestsChoiceDataList(pText);
				pChoiceData = GetFromTempStorage(vChoiceDataUID);
				If pChoiceData.Count() = 0 Then
					pChoiceData.Add(pText, NStr("en='--Guest not found--';ru='--Гость не найден--';de='--Gast nicht gefunden--'"));
				Else
					pChoiceData.Insert(0, TrimR(pText));
				EndIf;
			#ELSE
				pChoiceData = New ValueList();
				pChoiceData.Add(TrimR(pText));
			#ENDIF
		Else
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;
	EndIf;
	ThisObject.Modified = True;
EndProcedure // AddGuestTextEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.GuestGroups.ChoiceForm", , pItem, ThisObject.UUID, , , New NotifyDescription("GuestGroupStartChoiceEnd", ThisObject, New Structure("pItem", pItem)), FormWindowOpeningMode.LockWholeInterface);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackagesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vSelectedPackages = New ValueList();
	If ValueIsFilled(Object.ServicePackage) And Not tcOnServer.cmGetAttributeByRef(Object.ServicePackage, "IsMealBoardTerm") Then
		vSPStruct = New Structure("ServicePackage, Quantity, DateFrom, DateTo", Object.ServicePackage, 1, '00010101', '00010101');
		vSelectedPackages.Add(vSPStruct);
	EndIf;
	For Each vSPRow In Object.ServicePackages Do
		If ValueIsFilled(vSPRow.ServicePackage) Then
			vSPStruct = New Structure("ServicePackage, Quantity, DateFrom, DateTo", vSPRow.ServicePackage, ?(vSPRow.Quantity = 0, 1, vSPRow.Quantity), vSPRow.DateFrom, vSPRow.DateTo);
			vSelectedPackages.Add(vSPStruct);
		EndIf;
	EndDo;
	OpenForm("Catalog.ServicePackages.Form.tcChoiceFormWithPeriod", New Structure("Hotel, SelectedPackages, CheckInDate, CheckOutDate, MealBoardsAreUsed", Object.Hotel, vSelectedPackages, Object.CheckInDate, Object.CheckOutDate, Items.ServicePackage.Visible), ThisObject, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // ServicePackagesStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackagesClearing(pItem, pStandardProcessing)
	ServicePackagesClearingAtServer(pStandardProcessing);
	vServicePackagesList = GetServicePackagesListAtServer(Items.ServicePackage.Visible);
	FillAmenitiesFromServicePackages(vServicePackagesList);
	RoomRateOnChangeAtServer(, True);
	RefreshDataRepresentation();
EndProcedure // ServicePackagesClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceChangeReasonClick(pItem, pStandardProcessing)
	// Ask for price change reason
	pStandardProcessing = False;
	vParametersStructure = New Structure("Hotel, PriceChangeReason", Object.Hotel, Object.PriceChangeReason);
	vNotifyDescr = New NotifyDescription("AfterPriceChangeReasonSelection", ThisObject);
	vResultStructure = OpenForm("CommonForm.tcPriceChangeReasonSelection", New Structure("SettingStructure", vParametersStructure), ThisObject, , , , vNotifyDescr, FormWindowOpeningMode.LockWholeInterface);
EndProcedure // PriceChangeReasonClick

// -----------------------------------------------------------------------------
&AtClient
Procedure IsManualRoomPriceOnChange(pItem)
	If IsManualRoomPrice = 0 Then
		Items.RoomPrice.Visible = False;
		Items.RoomTypeUpgrade.Visible = False;
	ElsIf IsManualRoomPrice = 1 Or IsManualRoomPrice = 3 Then
		Items.RoomPrice.Visible = True;
		Items.RoomTypeUpgrade.Visible = False;
		If Not HaveRightsForManualPriceChange() Then
			Return;
		EndIf;
	ElsIf IsManualRoomPrice = 2 Then
		Items.RoomPrice.Visible = False;
		Items.RoomTypeUpgrade.Visible = True;
		If Object.IsByReservation And ValueIsFilled(Object.Reservation) Then
			Object.RoomTypeUpgrade = tcOnServer.cmGetAttributeByRef(Object.Reservation, "RoomType");
		EndIf;
	EndIf;
	RoomPriceOnChangeAtServer();
	FillPriceChangeReason();
	ThisObject.Modified = True;
EndProcedure
 
// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPriceOnChange(pItem)
	RoomPriceOnChangeAtServer();
	FillPriceChangeReason();
	ThisObject.Modified = True;
EndProcedure
 
// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountOnChange(pItem)
	DiscountOnChangeAtServer();
	FillPriceChangeReason();
EndProcedure // DiscountOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountServiceGroupOnChange(pItem)
	DiscountOnChangeAtServer();
EndProcedure // DiscountServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(pItem)
	DiscountTypeOnChangeAtServer();
	FillPriceChangeReason();
EndProcedure // DiscountTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeUpgradeOnChange(pItem)
	RoomTypeUpgradeOnChangeAtServer();
	FillPriceChangeReason();
EndProcedure // RoomTypeUpgradeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeUpgradeChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If TypeOf(pSelectedValue) = Type("Structure") Then
		pStandardProcessing = False;
		Object.RoomTypeUpgrade = pSelectedValue.RoomType;
		RoomTypeUpgradeOnChange(pItem);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenForeignerRegistryRecord(pItem)
	If (WasPosted = False Or ThisObject.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "OpenForeignerRegistryRecord"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vAddRoomsToAllotment = False;
		vAllotmentBalances = Undefined;
		vResult = WriteAtServer(, vWarning, , , vAddRoomsToAllotment, vAllotmentBalances);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;
		vBreakProcessing = False;
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.UserMessage(vResult);
			EndIf;
			vBreakProcessing = True;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;         
	 	If vAddRoomsToAllotment Then
			ShowQueryBox(New NotifyDescription("AddRoomsToAllotment", ThisObject, New Structure("AllotmentBalances", vAllotmentBalances)), 
						 NStr("en='Add missing rooms to the allotment?'; ru='Добавить недостающие номера в квоту?'; de='Fehlende Zimmer zum Allotment hinzufügen?'"), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
		If vBreakProcessing Then
			Return;
		EndIf;
	EndIf;
	OpenForeignerRegistryRecordForm(Object.Ref);
	For Each vRow In GuestsInGroup Do
		If ValueIsFilled(vRow.AccommodationType) Then
			OpenForeignerRegistryRecordForm(vRow.Ref);
		EndIf;
	EndDo;
	If Not ThisObject.Modified Then
		If ThisObject.IsOpen() Then
			ThisObject.Close();
		EndIf;
	EndIf;
EndProcedure // OpenForeignerRegistryRecord

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintInvoiceAfterInvoiceSelection(pItem, pExtraParams) Export
	If pItem <> Undefined Then
		vInvoice = pItem.Value;
		PrintInvoice(vInvoice);
	EndIf;
EndProcedure // PrintInvoiceAfterInvoiceSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardPresentationClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ThisObject.Modified Then
		vMessage = CreateGuestItems();
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
			Return;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.CreditCard) Then
		OpenForm("Catalog.CreditCards.ObjectForm", New Structure("Key", Object.CreditCard), ThisObject, Object.CreditCard, , , , FormWindowOpeningMode.LockOwnerWindow);
	Else
	 	OpenForm("Catalog.CreditCards.ObjectForm", New Structure("FillingValues", New Structure("CardOwner", Object.Guest)), ThisObject);
	EndIf;
EndProcedure // CreditCardPresentationClick

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerOpening(pItem, pStandardProcessing)
	If Not ValueIsFilled(Object.Customer) Then
		If ThisObject.Modified Then
			vMessage = CreateGuestItems();
			If Not IsBlankString(vMessage) Then
				ShowMessageBox(, vMessage);
				Return;
			EndIf;
		EndIf;
		If ValueIsFilled(Object.Guest) Then
			Object.Customer = CreateCustomerFromGuest(Object.Guest);
			CustomerOnChangeAtServer();
			ThisObject.Modified = True;
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Please fill guest first!';ru='Сначала введите данные гостя!';de='Erst die Daten des Gastes eintragen!'"));
		EndIf;
	EndIf;
EndProcedure // CustomerOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestChangesDescriptionClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenExtraGuestOrdinaryApplicationForm(ThisObject.Commands.OpenExtraGuestOrdinaryApplicationForm);
EndProcedure // GuestChangesDescriptionClick

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)	
	ClientTypeConfirmationTextChange();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MarketingCodeOnChange(pItem)
	MarketingCodeOnChangeAtServer();
	BuildThisObjectClientDataDecoration();
	ThisObject.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SourceOfBusinessOnChange(pItem)
	SourceOfBusinessOnChangeAtServer();
	BuildThisObjectClientDataDecoration();
	ThisObject.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TripPurposeOnChange(pItem)
	BuildThisObjectClientDataDecoration();
	ThisObject.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BedsSetupOnChange(pItem)
	BuildThisObjectClientDataDecoration();
	ThisObject.Modified = True;
EndProcedure // BedsSetupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BoardPlaceOnChange(pItem)
	BoardPlaceOnChangeAtServer();
	ThisObject.Modified = True;
EndProcedure // BoardPlaceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationOnChange(pItem)
	BuildThisObjectClientDataDecoration();
	ThisObject.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationClearing(pItem, pStandardProcessing)
	ThisObject.RoomProperties.Clear();
	ThisObject.RoomPropertiesPresentation = GetRoomPropertiesPresentation();
	BuildThisObjectClientDataDecoration();
	// Save room properties to the document object
	FillDocumentRoomProperties();
	ThisObject.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CarOnChange(pItem)
	BuildThisObjectClientDataDecoration();
	ThisObject.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestAccommodationTypeOnChange(pItem)
	vInd = GetItemIndex(pItem.Name);
	If Not IsBlankString(vInd) Then
		ExtraGuestAccommodationTypeOnChangeAtServer(vInd);
	EndIf;
	ThisObject.Modified = True;
EndProcedure // ExtraGuestAccommodationTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vChoiceFrm = OpenForm("Catalog.RoomRates.Form.tcChoiceForm", New Structure("ChoiceMode, Hotel, Company, Customer, Contract, PeriodFrom, PeriodTo, RoomRates, CurrentRow", True, Object.Hotel, PredefinedValue("Catalog.Companies.EmptyRef"), Object.Customer, Object.Contract, Object.CheckInDate, Object.CheckOutDate, New ValueList, Object.RoomRate), pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // RoomRateStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardStartChoice(pItem, pChoiceData, pStandardProcessing)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToInputDiscountCardNumberManually") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsForFolioSplitOnChange(pItem)
	ThisObject.Modified = True;
	CheckGuestFieldCount();
	AccommodationTypeOnChangeAtServer(False);
	If Object.IsForFolioSplit And ValueIsFilled(Object.HotelProduct) Then
		ResetOtherRoomGuestsVouchersIfNeeded();
	EndIf;
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // IsForFolioSplitOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardOnChange(pItem)
	If ValueIsFilled(Object.DiscountCard) Then
		If GetDiscountCardIsBlocked(Object.DiscountCard) Then
			vMessage = NStr("en='Discount card is blocked!';ru='Дисконтная карта заблокирована!';de='Die Diskontkarte ist blockiert!'");
			ShowMessageBox(, vMessage);
			DiscountCardsEmptyRef();
		ElsIf GetDiscountCheckInDate(Object.DiscountCard) Then
			vMessage = NStr("en='Discount card is not valid on guest check in date!';ru='Дисконтная карта не действует на дату заезда гостя!';de='Die Diskontkarte gilt nicht am Anreisetag des Gastes!'");
			ShowMessageBox(, vMessage);
			DiscountCardsEmptyRef();
		Else
			vClient = GetDiscountCardClient(Object.DiscountCard);
			If ValueIsFilled(vClient) Then
				If Not ValueIsFilled(Object.Guest) Then
					Object.Guest = vClient;
					GuestOnChangeAtServer();
				Else
					If Object.Guest <> vClient Then
						If Not CheckUserPermissions("HavePermissionToUseClientDiscountCardWithAnyOtherClientHavingIt") Then
							vMessage = NStr("en='This discount card was issued for another client! You do not have rights to use this discount card.';
							                |ru='Дисконтная карта выдана другому клиенту. Нет прав на использование этой дисконтной карты.';
							                |de='Die Rabatt-Karte von einem anderen Kunde ausgegeben. Sie sind nicht berechtigt, diese Rabatt-Karte zu verwenden.'");
							ShowMessageBox(, vMessage);
							DiscountCardsEmptyRef();
						Else
							vMessage = NStr("ru='Дисконтная карта выдана на другого клиента: '; 
							                |de='Discount card was issued to the different client: ';
							                |en='Discount card was issued to the different client: ") + TrimAll(vClient) + "!";
							tcCommonFunctionOnClientServer.UserMessage(vMessage);
						EndIf;
					Else
						DiscountCardOnChangeAtServer();
					EndIf;
				EndIf;
			Else
				DiscountCardOnChangeAtServer();
			EndIf;
			// Clear manual discounts from the accommodation plan table
			ClearRoomRatesCommission();
		EndIf;
	Else
		DiscountCardOnChangeAtServer();
		// Clear manual discounts from the accommodation plan table
		ClearRoomRatesCommission();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeClassOnChange(pItem)
	If ValueIsFilled(Object.RoomRate) Then
		ClearOccupationPercents(CurrentDate(), , , , True);
	EndIf;
	If ValueIsFilled(RoomTypeClass) Then
		If ValueIsFilled(WindowView) Then
			Object.RoomType = GetRoomTypeByViewAtServer(Object.Hotel, RoomTypeClass, WindowView);
		Else
			Object.RoomType = Undefined;
		EndIf;
	Else
		Object.RoomType = Undefined;
	EndIf;
	RoomTypeOnChange(Items.RoomType);
	ThisObject.Modified = True;
EndProcedure // RoomTypeClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeClassStartChoice(pItem, pChoiceData, pStandardProcessing)
	// APDEX
	vKeyOperation = "Catalog.RoomTypes.Form.tcChoiceForm.OpenForm";   
	vApdexRemarks = GetRemarksForAPDEX();
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);

	pStandardProcessing = False;
	vKidsAgeArray = New Array;
	For i = 1 To NumberOfKids Do
		vKidsAgeArray.Add(ThisObject["KidAge"+i]);
	EndDo;
	vParams = New Structure("Hotel, RoomType, WindowView, CheckInDate, CheckOutDate, Duration, RoomRate, ClientType, RoomQuota, NumberOfAdults, NumberOfKids, AgeArray", 
	                         Object.Hotel, Object.RoomType, WindowView, Object.CheckInDate, Object.CheckOutDate, Object.Duration, Object.RoomRate, Object.ClientType, Object.RoomQuota, NumberOfAdults, NumberOfKids, vKidsAgeArray);
	vFrm = OpenForm("Catalog.RoomTypes.Form.tcChoiceForm", vParams, pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // RoomTypeClassStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeClassChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	vOldRoomType = Object.RoomType;
	If TypeOf(pSelectedValue) = Type("Structure") Then
		vClientTypeHasChanged = False;
		If Object.ClientType <> pSelectedValue.ClientType Then
			vClientTypeHasChanged = True;
			Object.ClientType = pSelectedValue.ClientType;
		EndIf;
		If vClientTypeHasChanged Then 
			ClientTypeConfirmationTextChange();
		EndIf;
		vRoomType = pSelectedValue.RoomType;
		If ValueIsFilled(vRoomType) And Not tcOnServer.cmGetAttributeByRef(vRoomType, "IsFolder") Then
			Object.RoomType = vRoomType;
			WindowView = tcOnServer.cmGetAttributeByRef(vRoomType, "WindowView");
			RoomTypeClass = tcOnServer.cmGetAttributeByRef(vRoomType, "RoomClass");
		Else
			RoomTypeClass = Undefined;
			Object.RoomType = Undefined;
		EndIf;
		ClearOccupationPercents(CurrentDate(), pSelectedValue.RoomRate, , , True);
		RoomTypeOnChangeAtServer(False, vClientTypeHasChanged);
		Object.RoomQuota = pSelectedValue.RoomQuota;
		If ValueIsFilled(Object.RoomQuota) Then
			RoomQuotaOnChangeAtServer(False, , True);
		EndIf;
		Object.RoomRate = pSelectedValue.RoomRate;
		If ValueIsFilled(pSelectedValue.CheckInDate) And ValueIsFilled(pSelectedValue.CheckOutDate) And pSelectedValue.CheckOutDate > pSelectedValue.CheckInDate Then
			Object.CheckInDate = pSelectedValue.CheckInDate;
			Object.CheckOutDate = pSelectedValue.CheckOutDate;
			Object.Duration = pSelectedValue.Duration;
		EndIf;
		RoomRateOnChangeAtServer(, True);
	ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.RoomTypeClasses") Then
		RoomTypeClass = pSelectedValue;
		If ValueIsFilled(RoomTypeClass) Then
			If ValueIsFilled(WindowView) Then
				Object.RoomType = GetRoomTypeByViewAtServer(Object.Hotel, RoomTypeClass, WindowView);
			Else
				Object.RoomType = Undefined;
			EndIf;
		Else
			Object.RoomType = Undefined;
		EndIf;
		ClearOccupationPercents(CurrentDate(), Object.RoomRate, , , True);
		RoomTypeOnChangeAtServer(True, False);
	ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.Rooms") Then
		tcOnClient.AskRoomChangeQuestion(pSelectedValue, Object);
		// Show room pop up tasks
		vRoomPopUpTasksArray = RoomChoiceProcessingAtServer(pSelectedValue);
		If vRoomPopUpTasksArray.Count() > 0 Then
			For Each vRoomPopUpTask In vRoomPopUpTasksArray Do
				ShowMessageBox(, vRoomPopUpTask, , NStr("en='Information';de='Information';ru='Информация'"));
			EndDo;
		EndIf;
	EndIf;
	vTypes = GetTypesArrayByRoomType(Object.RoomType);
	Items.AccommodationType.ChoiceList.LoadValues(vTypes);
	For Each vGRow In GuestsInGroup Do
		Items["AccommodationType" + Format(GuestsInGroup.IndexOf(vGRow) + 2, "NFD=0; NG=")].ChoiceList.LoadValues(vTypes);
	EndDo;
	RefreshDocumentRepresentation();
	ThisObject.Modified = True;
EndProcedure // RoomTypeClassChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure WindowViewOnChange(pItem)
	If ValueIsFilled(RoomTypeClass) Then
		vRoomType = GetRoomTypeByViewAtServer(Object.Hotel, RoomTypeClass, WindowView);
	Else
		vRoomType = PredefinedValue("Catalog.RoomTypes.EmptyRef");
	EndIf;
	If vRoomType <> Object.RoomType Then
		Object.Room = PredefinedValue("Catalog.Rooms.EmptyRef");
		Object.RoomType = vRoomType;
		If ValueIsFilled(Object.RoomRate) Then
			vRoomRatePriceTagType = tcOnServer.cmGetAttributeByRef(Object.RoomRate, "PriceTagType");
			If vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomType") Or 
			   vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType") Then
				ClearOccupationPercents();
			EndIf;
		EndIf;
		RoomTypeOnChangeAtServer(True, False);
		vTypes = GetTypesArrayByRoomType(Object.RoomType);
		Items.AccommodationType.ChoiceList.LoadValues(vTypes);
		For Each vGRow In GuestsInGroup Do
			Items["AccommodationType" + Format(GuestsInGroup.IndexOf(vGRow) + 2, "NFD=0; NG=")].ChoiceList.LoadValues(vTypes);
		EndDo;
		RefreshDocumentRepresentation();
	EndIf;
	ThisObject.Modified = True;
EndProcedure // WindowViewOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackageOnChange(pItem)
	If ValueIsFilled(Object.ServicePackage) And Object.Prices.Count() > 0 Then
		ServicePackageOnChangeAtServer();
	EndIf;
	RoomRateOnChangeAtServer(, True);
	RefreshDataRepresentation();
EndProcedure // ServicePackageOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ContractStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	#If ThickClientOrdinaryApplication Then
		vFrm = Catalogs.Contracts.GetChoiceForm(, pItem);
		// Set customer as current owner
		vFrm.SelHotel = Object.Hotel;
		vFrm.SelCustomer = Object.Customer;
		vFrm.SelShowValidContractsOnly = True;
		vFrm.SelPeriodFrom = BegOfDay(Object.CheckInDate);
		vFrm.SelCreateDate = ?(ValueIsFilled(Object.GuestGroup), BegOfDay(tcOnServer.cmGetAttributeByRef(Object.GuestGroup, "CreateDate")), BegOfDay(Object.Date));
		// Open form
		vFrm.Open();
	#Else
		vCreateDate = ?(ValueIsFilled(Object.GuestGroup), BegOfDay(tcOnServer.cmGetAttributeByRef(Object.GuestGroup, "CreateDate")), BegOfDay(Object.Date));
		vParams = New Structure("Filter, Hotel, ShowValidContractsOnly, PeriodFrom, PeriodTo, CreateDate", New Structure("Owner", Object.Customer), Object.Hotel, True, BegOfDay(Object.CheckInDate), '00010101', vCreateDate);
		OpenForm("Catalog.Contracts.ChoiceForm", vParams, pItem, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	#EndIf
EndProcedure // ContractStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure OrdersClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If IsBlankString(TOrders) Then
		vParam = New Structure();
		vParam.Insert("basis", Object.Ref);
		OpenForm("Document.Order.ObjectForm", vParam, ThisObject, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);	
	Else	
		vParam = New Structure;
		vParam.Insert("ParentDoc", Object.Ref);
		OpenForm("Document.Order.ListForm", vParam, ThisObject, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	pStandardProcessing = False;
	Object.HotelProduct = Undefined;
	vParams = New Structure;
	VaucherText = pItem.EditText;
	vVaucherType = Undefined;
	vVaucher = Object.HotelProduct;
	If ValueIsFilled(vVaucher) And tcOnServer.cmGetAttributeByRef(vVaucher, "IsFolder") Then
		vVaucherType = vVaucher;
	EndIf;
	If GetAllHotelProductFolders() And Not ValueIsFilled(vVaucherType) Then
		vParams.Insert("ChoiceMode", True);
		vFrm = OpenForm("Catalog.HotelProducts.Form.tcGroupChoiceForm", vParams, pItem); 
	Else
		vObject = Object;
		vMessage = CreateGuestItems(vObject); 
		
		If Not IsBlankString(vMessage) Then
			ShowMessageBox(, vMessage);
			Return;
		EndIf;
		
		Object.HotelProduct = CreateNewVaucher(vObject, vVaucherType, VaucherText);

		// Reset vaucher text
		VaucherText = "";
	Endif;
EndProcedure // HotelProductTextEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestHotelProductTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	pStandardProcessing = False;
	vInd = GetItemIndex(pItem.Name);
	If Not IsBlankString(vInd) Then
		ThisObject[pItem.Name] = Undefined;
		vParams = New Structure; 
		VaucherText = pItem.EditText;
		vVaucherType = Undefined;
		vGiGIndex = Number(vInd) - 2;
		If vGiGIndex < GuestsInGroup.Count() Then
			vVaucher = GuestsInGroup.Get(vGiGIndex).HotelProduct;
			If ValueIsFilled(vVaucher) And tcOnServer.cmGetAttributeByRef(vVaucher, "IsFolder") Then
				vVaucherType = vVaucher;
			EndIf;
		EndIf;
		If GetAllHotelProductFolders() And Not ValueIsFilled(vVaucherType) Then
			vParams.Insert("ChoiceMode", True);
			vFrm = OpenForm("Catalog.HotelProducts.Form.tcGroupChoiceForm", vParams, pItem); 
		Else 
			vObject = Object;
			vMessage = CreateGuestItems(vObject);
			If Not IsBlankString(vMessage) Then
				ShowMessageBox(, vMessage);
				Return;
			EndIf;
			vDocRef = GetGuestDocumentRefByItemID(pItem.Name);
			vGuestsInGroup = GuestsInGroup[vInd-2];
			vClient = vGuestsInGroup.GuestRef;
			
			If Not vGuestsInGroup.Ref.isEmpty() And GetDocGuest(vDocRef) = vClient Then
				ThisObject[pItem.Name] = CreateNewVaucher(vDocRef, vVaucherType, VaucherText);
			Else
				vStruct = New Structure("Hotel, Client, Description, Code", vObject.Hotel, vClient, VaucherText, VaucherText);
				ThisObject[pItem.Name] = CreateNewVaucher(vStruct, vVaucherType, VaucherText);
			EndIf;
			
			If vGiGIndex < GuestsInGroup.Count() Then
				GuestsInGroup.Get(vGiGIndex).HotelProduct = ThisObject[pItem.Name];
			EndIf;

			// Reset vaucher text
			VaucherText = "";
		EndIf;
	EndIf;
EndProcedure // ExtraGuestHotelProductTextEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductOnChange(pItem)  
	HotelProductOnChangeAtServer();
EndProcedure // HotelProductOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;   
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToForbiddenSetHotelProducts") Then
		vErrMsg = NStr("en = 'No permission to add hotel product'; de = 'Keine Berechtigung zum Hinzufügen eines Hotelprodukts'; ru = 'Нет прав на ввод путевок'");    
		tcCommonFunctionOnClientServer.UserMessage(vErrMsg, , pItem.Name);
	Else	
		#If ThickClientOrdinaryApplication Then
			vFrm = Catalogs.HotelProducts.GetChoiceForm(, pItem);
			vFrm.ChoiceInitialValue = Object.HotelProduct;
			// Apply filters
			vFrm.SelRoomQuota = Catalogs.RoomQuotas.EmptyRef();
			vFrm.SelRoomType = Catalogs.RoomTypes.EmptyRef();
			vFrm.SelHotel = Object.Hotel;
			vFrm.SelCheckInDate = Undefined;
			// Open form
			vFrm.Open();
		#Else
			OpenForm("Catalog.HotelProducts.Form.tcChoiceForm", New Structure("ChoiceMode, ChoiceFoldersAndItems", True, FoldersAndItemsUse.FoldersAndItems), pItem);
		#EndIf  
	EndIf;
EndProcedure // HotelProductStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestHotelProductOnChange(pItem)
	vInd = GetItemIndex(pItem.Name);
	If Not IsBlankString(vInd) Then
		ExtraGuestHotelProductOnChangeAtServer(vInd);
	EndIf;
	ThisObject.Modified = True;
EndProcedure // ExtraGuestHotelProductOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestHotelProductStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False; 
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToForbiddenSetHotelProducts") Then
		vErrMsg = NStr("en = 'No permission to add hotel product'; de = 'Keine Berechtigung zum Hinzufügen eines Hotelprodukts'; ru = 'Нет прав на ввод путевок'");    
		tcCommonFunctionOnClientServer.UserMessage(vErrMsg, , pItem.Name);
	Else
		vInd = GetItemIndex(pItem.Name);
		If Not IsBlankString(vInd) Then
			#If ThickClientOrdinaryApplication Then
				vFrm = Catalogs.HotelProducts.GetChoiceForm(, pItem);
				vFrm.ChoiceInitialValue = ThisObject["HotelProduct" + vInd];
				// Apply filters
				vFrm.SelRoomQuota = Catalogs.RoomQuotas.EmptyRef();
				vFrm.SelRoomType = Catalogs.RoomTypes.EmptyRef();
				vFrm.SelHotel = Object.Hotel;
				vFrm.SelCheckInDate = Undefined;
				// Open form
				vFrm.Open();
			#Else 
				OpenForm("Catalog.HotelProducts.Form.tcChoiceForm", New Structure("ChoiceMode, ChoiceFoldersAndItems", True, FoldersAndItemsUse.FoldersAndItems), pItem);
			#EndIf
		EndIf; 
	EndIf;
EndProcedure // ExtraGuestHotelProductStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChooseItemToCoupons(pItem, pExtraParams) Export	
	If pItem = Undefined Then
		Return;
	EndIf;
	
	vService = pItem.Value;
	
	If Not ValueIsFilled(vService) Then
		Return;
	EndIf;
	vCouponsList = GetListPrintCoupons(pExtraParams.Base, vService);
	If vCouponsList = Undefined Then
		Return;	
	EndIf;
	vCurrentWorkstation = tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation");
	// Print coupons list
	If vCouponsList.Count() > 0 Then
		// Get language
		vLanguage = tcOnServer.cmGetAttributeByRef(Object.Hotel,"Language");
		If ValueIsFilled(Object.Guest) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(Object.Guest,"Language")) Then
			vLanguage = tcOnServer.cmGetAttributeByRef(Object.Guest,"Language");
		EndIf;
		vRibbonPrinterConnection = tcOnServer.cmGetAttributeByRef(vCurrentWorkstation,"RibbonPrinterConnectionParameters");
		vDriverType = tcOnServer.cmGetAttributeByRef(vRibbonPrinterConnection, "DriverType");
		If vDriverType = PredefinedValue("Enum.RibbonPrinterDrivers.SystemPrinter") Then
			OpenForm("DataProcessor.PrintCouponSystemPrinter.Form.tcCouponPrintForm", New Structure("SelLanguage, SelObjList, RibbonPrinterConnectionParameters", vLanguage, vCouponsList, vRibbonPrinterConnection), ThisObject, ThisObject.UUID);
		ElsIf vDriverType = PredefinedValue("Enum.RibbonPrinterDrivers.Intermec") Then
			OpenForm("DataProcessor.IntermecRibbonPrinterDriver.Form.tcCouponPrintForm", New Structure("SelLanguage, SelObjList, RibbonPrinterConnectionParameters", vLanguage, vCouponsList, vRibbonPrinterConnection), ThisObject, ThisObject.UUID);	
		ElsIf vDriverType = PredefinedValue("Enum.RibbonPrinterDrivers.Atol") Then
			ShowMessageBox(,NStr("ru='Данный принтер временно не поддерживается в тонком клиенте';en='This printer is temporarily not supported in the thin client';de='Dieser Drucker wird im Thin Client vorübergehend nicht unterstützt'"));	
		EndIf;
	Else
		ShowMessageBox(,NStr("en='Nothing to print!';ru='Нет услуг для печати!';de='Es gibt keine Dienste für den Druck!'"));
	EndIf;
EndProcedure // AfterChooseItemToCoupons

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesRoomOnChange(pItem)
	vRowData = Items.RoomRates.RowData(Items.RoomRates.CurrentRow);
	If vRowData <> Undefined Then
		If ValueIsFilled(vRowData.Room) Then
			vRowData.RoomType = GetRoomRoomTypeAtServer(vRowData.AccountingDate + (vRowData.ChangeTime - BegOfDay(vRowData.ChangeTime)) + 1, vRowData.Room);
		Else
			vRowData.RoomType = Undefined;
		EndIf;
	EndIf;
EndProcedure // RoomRatesRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesOnStartEdit(pItem, pNewRow, pClone)
	vRowData = Items.RoomRates.RowData(Items.RoomRates.CurrentRow);
	If vRowData <> Undefined Then
		If Not ValueIsFilled(vRowData.AccountingDate) Then
			If BegOfDay(Object.CheckInDate) < BegOfDay(Object.CheckOutDate) Then
				If BegOfDay(CurrentDate()) > BegOfDay(Object.CheckInDate) And BegOfDay(CurrentDate()) < BegOfDay(Object.CheckOutDate) Then
					vRowData.AccountingDate = BegOfDay(CurrentDate());
				Else
					vRowData.AccountingDate = BegOfDay(Object.CheckInDate) + 24*3600;
				EndIf;
			EndIf;
			vRowData.RoomType = Object.RoomType;
			vRowData.Room = Object.Room;
		EndIf;
	EndIf;
EndProcedure // RoomRatesOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesOnEditEnd(pItem, pNewRow, pCancelEdit)
	vRowData = Items.RoomRates.RowData(Items.RoomRates.CurrentRow);
	If vRowData <> Undefined Then
		If Not ValueIsFilled(vRowData.Room) And ValueIsFilled(vRowData.RoomType) Then
			vRowData.RoomType = Undefined;
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Room is not selected!'; ru='Не выбран номер!'; de='Keine Zimmer ausgewählt!'"));
		EndIf; 
		vRowData.BoardPlace = tcOnServer.cmGetAttributeByRef(vRowData.Room, "BoardPlace");
	EndIf;
	Object.RoomRates.Sort("AccountingDate, ChangeTime");
	AttachIdleHandler("RecalculateTotalsOnClient", 0.1, True);
EndProcedure // RoomRatesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesAfterDeleteRow(pItem)
	AttachIdleHandler("RecalculateTotalsOnClient", 0.1, True);
EndProcedure // RoomRatesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceCalculationDateOnChange(pItem)
	PriceCalculationDateOnChangeAtServer();
EndProcedure // PriceCalculationDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesBeforeDeleteRow(pItem, pCancel)
	If Object.ChargingRules.Count() = 1 Then
		pCancel = True;
		ShowMessageBox(, NStr("en='It is forbidden to delete the last rule!'; ru='Удалять последнее правило запрещено!'; de='Es ist verboten die letzte Regel zu löschen!'"));
	EndIf;
EndProcedure // ChargingRulesBeforeDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesAfterDeleteRow(pItem)
	// Check last charging rule
	If Object.ChargingRules.Count() = 1 Then
		vCRRow = Object.ChargingRules.Get(0);
		If vCRRow.ChargingRule <> PredefinedValue("Enum.ChargingRuleTypes.Any") Then
			vCRRow.ChargingRule = PredefinedValue("Enum.ChargingRuleTypes.Any");
			vCRRow.ChargingRuleValue = Undefined;
		EndIf;
	EndIf;
	// Recalculate services	
	RecalculateServicesAtServer();
EndProcedure // ChargingRulesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterResortFeeExemptionChoice(pItem, pExtraParams) Export
	If pItem <> Undefined Then
		vReason = pItem.Value;
		// Get service
		vResortFeeCurrency = Object.ReportingCurrency;
		vResortFeeService = GetResortFeeService(vResortFeeCurrency);
		If vResortFeeService <> Undefined Then
			// Add 0 price
			AddZeroResortFeePriceAtServer(vResortFeeService, vResortFeeCurrency, vReason);
			// Ask user should we exempt other room guests from paying the resort fee
			If Not OneGuestMode Then
				ShowQueryBox(New NotifyDescription("ResortFeeExemptAfterQuery", ThisObject), NStr("en='Add exempt from paying the resort fee to room other guests?'; ru='Освободить других гостей номера от уплаты курортного сбора?'; de='Lassen Zimmer andere Gäste die Kurtax nicht bezahlen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
			EndIf;
		EndIf;
		// Form is modified
		ThisObject.Modified = True;
	EndIf;
EndProcedure // AfterResortFeeExemptionChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterTouristTaxExemptionChoice(pItem, pExtraParams) Export
	If pItem <> Undefined Then
		Object.TouristicTaxExemptionReason = pItem.Value;
		If Not ValueIsFilled(Object.TouristicTaxExemptionReasonFillDate) Then
			Object.TouristicTaxExemptionReasonFillDate = tcOnServer.GetCurrentSessionDate();
		EndIf;
		BuildRoomRateGroupCollapsedTitle();
		// Ask user should we exempt other room guests from paying the resort fee
		If Not OneGuestMode Then
			ShowQueryBox(New NotifyDescription("ResortFeeExemptAfterQuery", ThisObject), NStr("en='Add exempt from tourist tax to room other guests?'; ru='Освободить других гостей номера от уплаты туристического налога?'; de='Lassen Zimmer andere Gäste die Kurtax nicht bezahlen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
		// Form is modified
		ThisObject.Modified = True;
	EndIf;
EndProcedure // AfterTouristTaxExemptionChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vCurRow = Items.ChargingRules.CurrentData;
	If vCurRow <> Undefined Then
		pStandardProcessing = False;
		vParams = New Structure("SelObjectRef, SelLineNumber, SelOwner, SelChargingRule, SelChargingRuleValue, SelChargingFolio, SelValidFromDate, SelValidToDate, SelIsMaster, SelIsPersonal, SelIsTransfer, SelHotel, SelCompany, SelGuestGroup, SelRoom, SelClient, SelCheckInDate, SelCheckOutDate", 
								 Object.Ref, vCurRow.LineNumber, vCurRow.Owner, vCurRow.ChargingRule, vCurRow.ChargingRuleValue, vCurRow.ChargingFolio, vCurRow.ValidFromDate, vCurRow.ValidToDate, vCurRow.IsMaster, vCurRow.IsPersonal, vCurRow.IsTransfer, Object.Hotel, Object.Company, Object.GuestGroup, Object.Room, Object.Guest, Object.CheckInDate, Object.CheckOutDate);
		OpenForm("CommonForm.tcEditChargingRule", New Structure("Parameters, EditMode", vParams, Not (vCurRow.IsTransfer Or vCurRow.IsMaster)), ThisObject, UUID, , , New NotifyDescription("AfterChangeChargingRules", ThisObject, vCurRow), FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure // ChargingRulesSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesBeforeRowChange(pItem, pCancel)
	pCancel = True;
EndProcedure // ChargingRulesBeforeRowChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	pCancel = true;
EndProcedure // ChargingRulesBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesFolioOnChange(pItem)
	ServicesFolioOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesFolioOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesServiceOnChange(pItem)
	vCurRow = pItem.Parent.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = Object.Services.FindByID(vCurRow);
		If vCurData <> Undefined Then
			// Check if it is possible to use this service
			If ValueIsFilled(vCurData.Service) Then
				vServiceType = tcOnServer.cmGetAttributeByRef(vCurData.Service, "ServiceType");
				vIsChargedExternally = tcOnServer.cmGetAttributeByRef(vServiceType, "ActualAmountIsChargedExternally");
				If vIsChargedExternally Then
					vCurData.Service = Undefined;
					ShowMessageBox(, NStr("en='Selected service should be charged from external system like POS! You can not use it in fixed charges because it will be automatically deleted at check-out.';
					                      |ru='В соответствии с настройками этой услуги она должна быть начислена из внешней системы (POS: ресторан, SPA)! Не можете использовать эту услугу в ручных начислениях потому, что она будет автоматически удалена при выезде гостя.'; 
										  |de='Nach den ausgewählten service-Einstellungen sollte es von externen system wie POS gebucht werden! Sie können es nicht in festen Gebühren verwenden, da es beim check-out automatisch gelöscht wird.'"));
					Return;
				EndIf;
			EndIf;
			// Process service choice
			ServicesServiceOnChangeAtServer(vCurRow);
		EndIf;
	EndIf;
EndProcedure // ServicesServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesPriceOnChange(pItem)
	ServicesPriceOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesPriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesQuantityOnChange(pItem)
	ServicesQuantityOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesQuantityOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesSumOnChange(pItem)
	ServicesSumOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesDiscountOnChange(pItem)
	ServicesDiscountOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesDiscountOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesDiscountSumOnChange(pItem)
	ServicesDiscountSumOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesDiscountSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesAgentCommissionOnChange(pItem)
	ServicesAgentCommissionOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesAgentCommissionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesCommissionSumOnChange(pItem)
	ServicesCommissionSumOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesCommissionSumOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure ServicesVATRateOnChange(pItem)
	ServicesVATRateOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesVATRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesServiceResourceOnChange(pItem)
	ServicesServiceResourceOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesServiceResourceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesTimeFromOnChange(pItem)
	ServicesTimeFromOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesTimeFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesTimeToOnChange(pItem)
	ServicesTimeToOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesTimeToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationTotalSumClick(pItem)
	DecorationTotalSumClickAtServer();
EndProcedure // DecorationTotalSumClick

// -----------------------------------------------------------------------------
&AtClient
Procedure GetPaidClick(pItem)
	If Not Modified Then
		vParams = New Structure("SelDocument", Object.Ref); 
		OpenForm("CommonForm.tcGetPaidForm", vParams, ThisObject, UUID);
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'All changes must be saved!'; de = 'Alle Änderungen müssen gespeichert werden!'; ru = 'Все изменения должны быть сохранены!'"));
	EndIf;
EndProcedure // GetPaidClick

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTemplateOnChange(pItem)
	AccommodationTemplateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardCreating(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.DiscountCards.ObjectForm", New Structure("FillingValues", New Structure("Client, Identifier", Object.Guest, pItem.EditText)), pItem, , , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // DiscountCardCreating

// -----------------------------------------------------------------------------
&AtClient
Procedure ContactPersonOnChange(pItem)
	ContactPersonOnChangeAtServer();
EndProcedure // ContactPersonOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	CompanyOnChangeAtServer();
	RefreshDocumentRepresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateEditTextChange(pItem, pText, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // RoomRateEditTextChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	If Not IsBlankString(pText) Then
		pStandardProcessing = False;
		pChoiceData = GetListOfRoomRatesAtServer(pText, Object.CheckInDate, Object.CheckOutDate, GuestGroupCreateDate, Object.RoomType, Object.Hotel);
	EndIf;
EndProcedure // RoomRateTextEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductOpening(pItem, pStandardProcessing)
	If ValueIsFilled(Object.HotelProduct) And tcOnServer.cmGetAttributeByRef(Object.HotelProduct, "IsFolder") Then
		pStandardProcessing = False;
		vFillingValues = New Structure("Parent, Code, Description, Hotel, RoomQuota, RoomType, Client, CheckInDate, Duration, CheckOutDate, PaymentMethod", 
		                               Object.HotelProduct, TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, Object.Guest, Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
		OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, Object.Guest);
	ElsIf Not ValueIsFilled(Object.HotelProduct) Then
		pStandardProcessing = False;
		vFillingValues = New Structure("Parent, Code, Description, Hotel, RoomQuota, RoomType, Client, CheckInDate, Duration, CheckOutDate, PaymentMethod", 
		                               Undefined, TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, Object.Guest, Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
		OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, Object.Guest);
	EndIf;
EndProcedure // HotelProductOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductCreating(pItem, pStandardProcessing)  
	If ValueIsFilled(Object.HotelProduct) And tcOnServer.cmGetAttributeByRef(Object.HotelProduct, "IsFolder") Then
		pStandardProcessing = False;
		vFillingValues = New Structure("Parent, Code, Description, Hotel, RoomQuota, RoomType, Client, CheckInDate, Duration, CheckOutDate, PaymentMethod", 
		Object.HotelProduct, TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, Object.Guest, Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
		OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, Object.Guest);
	Else
		pStandardProcessing = False;
		vFillingValues = New Structure("Parent, Code, Description, Hotel, RoomQuota, RoomType, Client, CheckInDate, Duration, CheckOutDate, PaymentMethod", 
		Undefined, TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, Object.Guest, Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
		OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, Object.Guest);
	EndIf;   
EndProcedure // HotelProductCreating

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestHotelProductOpening(pItem, pStandardProcessing)
	vInd = GetItemIndex(pItem.Name); 
	If Not IsBlankString(vInd) Then
		If ValueIsFilled(ThisObject["HotelProduct"+vInd]) And tcOnServer.cmGetAttributeByRef(ThisObject["HotelProduct"+vInd], "IsFolder") Then
			pStandardProcessing = False;
			vFillingValues = New Structure("Parent, Code, Description, Hotel, RoomQuota, RoomType, Client, CheckInDate, Duration, CheckOutDate, PaymentMethod", 
			ThisObject["HotelProduct"+vInd], TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, ThisObject["Guest"+vInd], Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
			OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, ThisObject["Guest"+vInd]);
		ElsIf Not ValueIsFilled(ThisObject["HotelProduct"+vInd]) Then
			pStandardProcessing = False;
			vParent = Undefined;
			If ValueIsFilled(Object.HotelProduct) Then
				If tcOnServer.cmGetAttributeByRef(Object.HotelProduct, "IsFolder") Then
					vParent = Object.HotelProduct;
				Else
					vParent = tcOnServer.cmGetAttributeByRef(Object.HotelProduct, "Parent");
				EndIf;
			EndIf;
			vFillingValues = New Structure("Parent, Code, Description, Hotel, RoomQuota, RoomType, Client, CheckInDate, Duration, CheckOutDate, PaymentMethod", 
			vParent, TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, ThisObject["Guest"+vInd], Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
			OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, ThisObject["Guest"+vInd]);
		EndIf;
	EndIf;    
EndProcedure // ExtraGuestHotelProductOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestHotelProductCreating(pItem, pStandardProcessing)
	vInd = GetItemIndex(pItem.Name);
	If Not IsBlankString(vInd) Then
		If ValueIsFilled(ThisObject["HotelProduct"+vInd]) And tcOnServer.cmGetAttributeByRef(ThisObject["HotelProduct"+vInd], "IsFolder") Then
			pStandardProcessing = False;
			vFillingValues = New Structure("Parent, Code, Description, Hotel, RoomQuota, RoomType, Client, CheckInDate, Duration, CheckOutDate, PaymentMethod", 
			                               ThisObject["HotelProduct"+vInd], TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, ThisObject["Guest"+vInd], Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
			OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, ThisObject["Guest"+vInd]);
		Else
			pStandardProcessing = False;
			vParent = Undefined;
			If ValueIsFilled(Object.HotelProduct) Then
				If tcOnServer.cmGetAttributeByRef(Object.HotelProduct, "IsFolder") Then
					vParent = Object.HotelProduct;
				Else
					vParent = tcOnServer.cmGetAttributeByRef(Object.HotelProduct, "Parent");
				EndIf;
			EndIf;
			vFillingValues = New Structure("Parent, Code, Description, Hotel, RoomQuota, RoomType, Client, CheckInDate, Duration, CheckOutDate, PaymentMethod", 
			                               vParent, TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, ThisObject["Guest"+vInd], Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
			OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, ThisObject["Guest"+vInd]);
		EndIf;
	EndIf;
EndProcedure // ExtraGuestHotelProductCreating

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestRegistrationActionClick(pItem)
	// Save document first
	If (WasPosted = False Or ThisObject.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "GuestRegistrationActionClick"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vAddRoomsToAllotment = False;
		vAllotmentBalances = Undefined;
		vResult = WriteAtServer(, vWarning, , , vAddRoomsToAllotment, vAllotmentBalances);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;
		vBreakProcessing = False;
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.UserMessage(vResult);
			EndIf;
			vBreakProcessing = True;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;         
	 	If vAddRoomsToAllotment Then
			ShowQueryBox(New NotifyDescription("AddRoomsToAllotment", ThisObject, New Structure("AllotmentBalances", vAllotmentBalances)), 
						 NStr("en='Add missing rooms to the allotment?'; ru='Добавить недостающие номера в квоту?'; de='Fehlende Zimmer zum Allotment hinzufügen?'"), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
		If vBreakProcessing Then
			Return;
		EndIf;
	EndIf;
	// Get guest index
	vIndexStr = "";
	vItemName = Mid(pItem.Name, 6);
	i = 1;
	While True Do
		If i > StrLen(vItemName) Then
			Break;
		EndIf;
		vChar = Mid(vItemName, i, 1);
		If StrFind("0123456789", vChar) > 0 Then
			vIndexStr = vIndexStr + vChar;
		Else
			Break;
		EndIf;
		i = i + 1;
	EndDo;
	If Not IsBlankString(vIndexStr) Then
		vIndex = Number(vIndexStr);
		vGuestRegDocument = ThisObject["Guest"+String(vIndex)+"Registration"];
		If Not ValueIsFilled(vGuestRegDocument) Then
			vGuestAccommodation = Object.Ref;
			If vIndex > 1 Then
				vGuestAccommodation = GuestsInGroup.Get(vIndex - 2).Ref;
				If Not ValueIsFilled(vGuestAccommodation) Then
					Return;
				EndIf;
			EndIf;
			OpenForm("Document.ForeignerRegistryRecord.ObjectForm", New Structure("Basis", vGuestAccommodation), Items["SelGuest"+vIndexStr], vGuestAccommodation);
		Else
			OpenForm("Document.ForeignerRegistryRecord.ObjectForm", New Structure("Key", vGuestRegDocument), Items["SelGuest"+vIndexStr], vGuestRegDocument);
		EndIf;
	EndIf;
EndProcedure // GuestRegistrationActionClick

// -----------------------------------------------------------------------------
&AtClient
Procedure DecorationTasksClick(pItem)
	Task(Commands.Task);
EndProcedure // DecorationTasksClick

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesOnChange(pItem)
	ManualServicesPriceAppearance();
EndProcedure // ServicesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomInterfacesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If Not pClone Then
		pCancel = True;
		ActionInsert(pItem);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesRoomTypeOnChange(pItem)
	vRowData = Items.RoomRates.RowData(Items.RoomRates.CurrentRow);
	If vRowData <> Undefined Then
		If ValueIsFilled(vRowData.RoomType) Then
			ClearOccupationPercents(vRowData.AccountingDate, vRowData.RoomRate, Object.RoomType, vRowData.RoomType);
			If ValueIsFilled(vRowData.Room) Then
				vRowData.Room = tcOnServer.CheckRoomForRoomType(vRowData.RoomType, vRowData.Room, vRowData.AccountingDate);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // RoomRatesRoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesRoomRateOnChange(pItem)
	vRowData = Items.RoomRates.RowData(Items.RoomRates.CurrentRow);
	If vRowData <> Undefined Then
		If ValueIsFilled(vRowData.RoomRate) Then
			vRowData.PriceCalculationDate = '00010101';
		EndIf;
	EndIf;
EndProcedure // RoomRatesRoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedChargesOnStartEdit(pItem, pNewRow, pClone)
	vCurData = Object.Services.FindByID(pItem.CurrentRow);
	If vCurData <> Undefined Then
		If pNewRow Then
			vCurData.IsManual = True;
			If Not pClone Then
				vCurData.AccountingDate = BegOfDay(CurrentDate());
				vCurData.Folio = Object.ChargingRules.Get(Object.ChargingRules.Count() - 1).ChargingFolio;
				If ValueIsFilled(vCurData.Folio) Then
					vCurData.FolioCurrency = tcOnServer.cmGetAttributeByRef(vCurData.Folio, "FolioCurrency");
					vCurData.FolioCurrencyExchangeRate = GetCurrencyExchangeRateAtServer(Object.Hotel, vCurData.FolioCurrency, ?(ValueIsFilled(vCurData.AccountingDate), vCurData.AccountingDate, Object.ExchangeRateDate));
				EndIf;
				vCurData.Company = Object.Company;
				If vCurData.Quantity = 0 Then
					vCurData.Quantity = 1;
				EndIf;
			Else
				vCurData.IsManualAuthor = Undefined;
				vCurData.IsManualDate = '00010101';
			EndIf;
		EndIf;
		// Check if user can edit service price
		Items.FixedChargesPrice.ReadOnly = False;
		If ValueIsFilled(vCurData.Service) Then
			If Not tcOnServer.cmGetAttributeByRef(vCurData.Service, "AllowChangePrice") Then
				If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditServicePrices") Then
					Items.FixedChargesPrice.ReadOnly = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FixedChargesOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedChargesOnEditEnd(pItem, pNewRow, pCancelEdit) 
	ManualServicesPriceAppearance();
EndProcedure // FixedChargesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedChargesAfterDeleteRow(pItem)
	ManualServicesPriceAppearance();
EndProcedure // FixedChargesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedChargesAccountingDateOnChange(pItem)
	If ValueIsFilled(Object.CheckInDate) And ValueIsFilled(Object.CheckOutDate) Then
		vCurData = Object.Services.FindByID(pItem.Parent.CurrentRow);
		If vCurData <> Undefined Then
			vCurData.RoomType = Object.RoomType;
			vCurData.Room = Object.Room;
			vCurData.AccommodationType = Object.AccommodationType;
			vCurData.ClientType = Object.ClientType;
			vCurData.SourceOfBusiness = Object.SourceOfBusiness;
			vCurData.MarketingCode = Object.MarketingCode;
			If BegOfDay(vCurData.AccountingDate) < (BegOfDay(Object.CheckInDate) - 24*3600) Or BegOfDay(vCurData.AccountingDate) > (BegOfDay(Object.CheckOutDate) + 24*3600) Then
				vCurData.AccountingDate = BegOfDay(Object.CheckInDate);
				ShowMessageBox(, NStr("en='Charge date should be inside reservation period!'; ru='Дата начисления должна быть внутри периода проживания!'; de='Datum sollte innerhalb der Reservierungsperiode sein!'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FixedChargesAccountingDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOpening(pItem, pStandardProcessing)
	If Not ValueIsFilled(Object.GuestGroup) Then
		pStandardProcessing = False;
		GuestGroupOpeningAtServer();
	EndIf;
EndProcedure // GuestGroupOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure ContactPersonStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCPList = ContactPersonStartChoiceAtServer(Object.Customer);
	If vCPList.Count() > 0 Then
		If vCPList.Count() = 1 Then
			Object.ContactPerson = vCPList.Get(0).Value;
		Else
			ThisObject.ShowChooseFromList(New NotifyDescription("ContactPersonAfterChoice", ThisObject), vCPList, pItem);
		EndIf;
	EndIf;
EndProcedure // ContactPersonStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RemarksStartChoice(pItem, pChoiceData, pStandardProcessing)
	vAmenitiesList = GetAmenitiesList(pItem.EditText, 1);
	vAmenitiesList.ShowCheckItems(New NotifyDescription("AmenitiesAfterChoice", ThisObject, "Remarks"), NStr("en='Choose amenities'; ru='Отметьте доп. удобства'; de='Wählen Sie Amenities'"));
EndProcedure // RemarksStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure HousekeepingRemarksStartChoice(pItem, pChoiceData, pStandardProcessing)
	vAmenitiesList = GetAmenitiesList(pItem.EditText, 2);
	vAmenitiesList.ShowCheckItems(New NotifyDescription("AmenitiesAfterChoice", ThisObject, "HousekeepingRemarks"), NStr("en='Choose amenities'; ru='Отметьте доп. удобства'; de='Wählen Sie Amenities'"));
EndProcedure // HousekeepingRemarksStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure NoPostOnChange(pItem)
	vQuery = NStr("en='Do change the <No external postings> flag for all group guests?'; ru='Изменить флаг <Запрет внешних начислений> для всех гостей группы?'; de='Ändern Sie das <Externe gebührenverbot> Flag für alle Gäste in der Gruppe?'");
	ShowQueryBox(New NotifyDescription("NoPostAfterAnswer", ThisObject), vQuery, QuestionDialogMode.YesNo, , DialogReturnCode.No);
EndProcedure // NoPostOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsClosedForEditOnChange(pItem)
	IsClosedForEditOnChangeAtServer();
EndProcedure // IsClosedForEditOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectionServiceInAccommodationPlan(pItem, pSelectionRow, pField, pStandardProcessing)
	vCurdata = ThisObject["AccommodationPlan"][pSelectionRow];
	If vCurdata <> Undefined Then
		Try
			If vCurData.IsService Then 
				pField.ChoiceButton = False;
				pField.SpinButton = True;
				pField.MinValue = 0;
				pField.TextEdit = True;
				If vCurdata[pField.Name] = Undefined Then
					vCurdata[pField.Name] = 0;	
				EndIf;
			ElsIf vCurData.ResourceName = "RoomRate" Then
				pField.ChoiceButton = True;
				pField.SpinButton = False;
				pField.TextEdit = False;
			ElsIf vCurData.ResourceName = "CalendarDayType" Then
				pField.ChoiceButton = True;
				pField.SpinButton = False;
				pField.TextEdit = False;	
			ElsIf vCurData.ResourceName = "PriceTag" Then
				pField.ChoiceButton = True;
				pField.SpinButton = False;
				pField.TextEdit = False;	
			ElsIf vCurData.ResourceName = "ClientType" Then
				pField.ChoiceButton = True;
				pField.SpinButton = False;
				pField.TextEdit = False;	
			ElsIf vCurData.ResourceName = "SourceOfBusiness" Then
				pField.ChoiceButton = True;
				pField.SpinButton = False;
				pField.TextEdit = False;	
			ElsIf vCurData.ResourceName = "MarketingCode" Then
				pField.ChoiceButton = True;
				pField.SpinButton = False;
				pField.TextEdit = False;	
			ElsIf vCurData.ResourceName = "BoardPlace" Then
				pField.ChoiceButton = True;
				pField.SpinButton = False;
				pField.TextEdit = False;
				vCPsArray = New Array();
				vCP = New ChoiceParameter("Filter.IsBoardPlace", True);
				vCPsArray.Add(vCP);
				vCPs = New FixedArray(vCPsArray);
				pField.ChoiceParameters = vCPs;
			ElsIf vCurData.ResourceName = "Terms" Then
				pField.ChoiceButton = True;
				pField.SpinButton = False;
				pField.TextEdit = False;	
				vCPsArray = New Array();
				vCP = New ChoiceParameter("Filter.IsMealBoardTerm", True);
				vCPsArray.Add(vCP);
				vCPs = New FixedArray(vCPsArray);
				pField.ChoiceParameters = vCPs;
			ElsIf vCurData.ResourceName = "OccupancyPercent" Then
				pField.ChoiceButton = False;
				pField.SpinButton = False;
				pField.TextEdit = False;	
			ElsIf vCurData.ResourceName = "RoomPrice" Then
				pField.ChoiceButton = False;
				pField.SpinButton = False;
				pField.MinValue = 0;
				pField.TextEdit = True;
				If vCurdata[pField.Name] = Undefined Then
					vCurdata[pField.Name] = 0;
				Else
					vCurdata[pField.Name] = ConvertToNumber(vCurdata[pField.Name]);
				EndIf;
			Else
				pStandardProcessing = False;
			EndIf;	
		Except
		EndTry;
	Else
		pStandardProcessing = False;	
	EndIf;
EndProcedure // SelectionServiceInAccommodationPlan

// -----------------------------------------------------------------------------
&AtClient
Procedure StartChoiceInAccommodationPlan(pItem, pChoiceData, pStandardProcessing) 
	pStandardProcessing = False;
	vCurrData = Items["AccommodationPlan"].CurrentData;
	If vCurrData <> Undefined Then
		vCurDate = '00010101';
		Try
			If StrFind(pItem.Name, "Column_") <> 0 Then
				vDate = Date(StrReplace(pItem.Name, "Column_", ""));
			EndIf;
		Except
			vDate = '00010101';
		EndTry;
		If vCurrData.ResourceName = "RoomRate" Then  
			vCurRoomRate = vCurrData[pItem.Name];
			If ValueIsFilled(vDate) And ValueIsFilled(vCurRoomRate) Then
				OpenForm("Catalog.RoomRates.Form.tcChoiceForm", New Structure("ChoiceMode, Hotel, Company, Customer, Contract, PeriodFrom, PeriodTo, RoomRates, CurrentRow", True, Object.Hotel, PredefinedValue("Catalog.Companies.EmptyRef"), Object.Customer, Object.Contract, vDate + (Object.CheckInDate - BegOfDay(Object.CheckInDate)), Object.CheckOutDate, New ValueList, vCurRoomRate), pItem);
			EndIf;
		ElsIf vCurrData.ResourceName = "CalendarDayType" Then	
			OpenForm("Catalog.CalendarDayTypes.Form.tcChoiceForm", New Structure("ChoiceMode", True), pItem);
		ElsIf vCurrData.ResourceName = "PriceTag" Then	
			OpenForm("Catalog.PriceTags.Form.tcChoiceForm", New Structure("ChoiceMode", True), pItem);
		ElsIf vCurrData.ResourceName = "ClientType" Then	
			OpenForm("Catalog.ClientTypes.ChoiceForm", New Structure("ChoiceMode", True), pItem);
		ElsIf vCurrData.ResourceName = "SourceOfBusiness" Then	
			OpenForm("Catalog.SourcesOfBusiness.ChoiceForm", New Structure("ChoiceMode", True), pItem);
		ElsIf vCurrData.ResourceName = "MarketingCode" Then	
			OpenForm("Catalog.MarketingCodes.ChoiceForm", New Structure("ChoiceMode", True), pItem);
		ElsIf vCurrData.ResourceName = "Terms" Then	
			OpenForm("Catalog.ServicePackages.ChoiceForm", New Structure("ChoiceMode, Filter", True, New Structure("IsMealBoardTerm", True)), pItem);
		ElsIf vCurrData.ResourceName = "BoardPlace" Then	
			OpenForm("Catalog.Resources.ChoiceForm", New Structure("ChoiceMode, Filter", True, New Structure("IsBoardPlace", True)), pItem);
		EndIf;
	EndIf;
EndProcedure // StartChoiceInAccommodationPlan

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationPlanChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	vOldAttributeValue = PredefinedValue("Catalog.RoomRates.EmptyRef");
	vAccountingDate = Date(StrReplace(pItem.Name, "Column_", ""));
	If ValueIsFilled(vAccountingDate) Then
		vCurrData = Items["AccommodationPlan"].CurrentData;
		If vCurrData <> Undefined Then
			vOldAttributeValue = vCurrData[pItem.Name];
			AccommodationPlanAttributeUpdate(vAccountingDate, pSelectedValue, vOldAttributeValue, vCurrData.ResourceName);
		Else
			pStandardProcessing = False;	
		EndIf; 	
	Else
		ShowMessageBox(, NStr("en='Accounting date is not choosen!';ru='Не выбрана строка учетной даты!';de='Keine Zeile des Erfassungsdatums ist gewählt!'"));
		pStandardProcessing = False;
	EndIf;
EndProcedure // AccommodationPlanChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient 
Procedure BeforeRowChangeInAccommodationPlan(pItem, pCancel)
	vCurdata = Items["AccommodationPlan"].CurrentData;
	If vCurdata <> Undefined Then
		If vCurdata.ResourceName = "OccupancyPercent" Then
			pCancel = true;
		EndIf;
	EndIf;
EndProcedure // BeforeRowChangeInAccommodationPlan

// -----------------------------------------------------------------------------
&AtClient
Procedure OnStartEditInAccommodationPlan(pItem, pNewRow, pClone) 
	ChangedFieldsOfAccommodationPlan.Clear();
	vCurdata = pItem.CurrentData;
	If vCurdata <> Undefined Then
		ChangedFieldsOfAccommodationPlan.Add(New Structure("Field, ValueField, Continue, AccountingDate, RoomPrice, Service, ServiceQuantity, AccommodationType, PrevRowField", pItem.CurrentItem.Name, vCurdata[pItem.CurrentItem.Name], False, , , , pItem.CurrentItem.Name)); 
	EndIf;
EndProcedure // OnStartEditInAccommodationPlan

// -----------------------------------------------------------------------------
&AtClient
Procedure OnActivateFieldInAccommodationPlan(pItem)
	If ChangedFieldsOfAccommodationPlan.Count() > 0 Then
		Try
			vPrevRow = ChangedFieldsOfAccommodationPlan.Get(ChangedFieldsOfAccommodationPlan.Count()-1).Value;
			If vPrevRow.ValueField <> pItem.CurrentData[vPrevRow.Field] Then
				FillConditionalAppearanceByAccommodationPlan();
			EndIf;
			vIsNewCell = True;
			For Each vRow In ChangedFieldsOfAccommodationPlan Do
				If vRow.Value.Field = pItem.CurrentItem.Name Then
					vIsNewCell = False;	
					Break;
				EndIf;	
			EndDo;
			If vIsNewCell Then
				vCurdata = pItem.CurrentData;
				If vCurdata <> Undefined Then
					ChangedFieldsOfAccommodationPlan.Add(New Structure("Field, ValueField, Continue, AccountingDate, RoomPrice, Service, ServiceQuantity, AccommodationType, PrevRowField",pItem.CurrentItem.Name, vCurdata[pItem.CurrentItem.Name], False, ,,,pItem.CurrentItem.Name)); 
				EndIf;
			EndIf;
		Except
		EndTry;
	EndIf;
EndProcedure // OnActivateFieldInAccommodationPlan

// -----------------------------------------------------------------------------
&AtClient
Procedure OnEditEndInAccommodationPlan(pItem, pNewRow, pCancel) 
	vCurdata = pItem.CurrentData;
	vUpdateServiceQuantity = False;
	vUpdateRoomPrice = False;
	If vCurdata <> Undefined Then
		For Each vField In ChangedFieldsOfAccommodationPlan Do
			vSelRow = vField.Value;
			vFieldName = vSelRow.Field;
			vValue = vCurdata[vFieldName];
			If vValue = vSelRow.ValueField Then
				vSelRow.Continue = True;
				Continue;
			EndIf;	
			If vCurdata.IsService Then 
				If ValueIsFilled(vFieldName) Then
					vService = vCurdata["AccommodationPlanService"];
					If ValueIsFilled(vService) Then
						If vValue >= 0 Then
							vAccountingDate = Date(StrReplace(vFieldName, "Column_", ""));
							If ValueIsFilled(vAccountingDate) Then
								vSelRow.AccountingDate = vAccountingDate;
								vSelRow.Service = vService;
								vSelRow.ServiceQuantity = vValue;
								vSelRow.AccommodationType = vCurdata["AccommodationPlanAccommodationType"];
								vUpdateServiceQuantity = True;
							Else
								pCancel = True;
							EndIf;
						Else
							pCancel = True;
						EndIf;
					Else
						pCancel = True;
					EndIf;
				Else
					pCancel = True;	
				EndIf;
			ElsIf vCurdata.ResourceName = "RoomPrice" Then
				If ValueIsFilled(vFieldName) Then
					vRoomPriceStr = vCurdata[vFieldName];
					If tcOnServer.IsNumber(vRoomPriceStr) Then
						vRoomPrice = Number(vRoomPriceStr);
						If vRoomPrice >= 0 Then
							vAccountingDate = Date(StrReplace(vFieldName, "Column_", ""));
							If ValueIsFilled(vAccountingDate) Then
								vSelRow.AccountingDate = vAccountingDate;
								vSelRow.RoomPrice = vRoomPrice;
								vUpdateRoomPrice = True;
							Else
								pCancel = True;
							EndIf;
						Else
							pCancel = True;
						EndIf;
					Else
						pCancel = True;	
					EndIf;
				Else
					pCancel = True;	
				EndIf;
			EndIf;
		EndDo;
		If vUpdateRoomPrice Then
			AttachIdleHandler("UpdateRoomPrice", 0.1, True);
		EndIf;
		If vUpdateServiceQuantity Then
			AttachIdleHandler("UpdateServiceQuantity", 0.1, True);
		EndIf;
	Else
		pCancel = True;
	EndIf;
EndProcedure // OnEditEndInAccommodationPlan

// -----------------------------------------------------------------------------
&AtClient
Procedure TurnOffAutomaticDiscountsOnChange(pItem)
	DiscountOnChangeAtServer();
EndProcedure // TurnOffAutomaticDiscountsOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountSumOnChange(pItem)
	DiscountOnChangeAtServer();
EndProcedure // DiscountSumOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure LegalRepresentativeOnChange(pItem)
	If Left(pItem.Name, 19) = "LegalRepresentative" Then
		vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-19));
	Else
		vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-12));
	EndIf;
	If vItemIndex > 1 Then
		vGiGRowIndex = vItemIndex-2;
		Try
			vGiGRow = GuestsInGroup.Get(vGiGRowIndex);
			vGiGRow.LegalRepresentative = ThisObject["LegalRepresentative"+vItemIndex];
			vGiGRow.RelationType = ThisObject["RelationType"+vItemIndex];
		Except
		EndTry;
	EndIf;
	// Read foreigner registry documents
	ReadForeignerRegistryDocuments();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedChargesBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	// Ask to check dates to copy rows to
	If pClone Then
		pCancel = True;
		// Get row to be copied
		vCopiedData = Items.FixedCharges.CurrentData;
		// Build array of dates starting after selected
		vDatesList = New ValueList();
		vCurDate = vCopiedData.AccountingDate + 24*3600;
		While vCurDate <= Object.CheckOutDate Do
			vDatesList.Add(vCurDate, Format(vCurDate, "DF='dd.MM.yyyy ddd'"), True);
			vCurDate = vCurDate + 24*3600;
		EndDo;
		// Ask to check dates to copy service to
		vDatesList.ShowCheckItems(New NotifyDescription("AfterDatesCheck", ThisObject, vCopiedData), NStr("en='Check dates'; ru='Отметьте даты'; de='Markieren Sie die Daten'"));
	EndIf;
EndProcedure // FixedChargesBeforeAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestPayOnlyOnChange(pItem)
    If Object.ref.IsEmpty() Or ThisObject.Modified Then
        DecorationTotalSumClickAtServer();
	Else
		FillGridAtServer();
    EndIf; 
EndProcedure // GuestPayOnlyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IgnoreGroupChargingRulesOnChange(pItem)
	// Recalculate services	
	RecalculateServicesAtServer();
EndProcedure // IgnoreGroupChargingRulesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SharePercentOnChange(pItem)
	SharePercentOnChangeAtServer();
	ThisObject.Modified = True;
EndProcedure // SharePercentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestSharePercentOnChange(pItem)
	vInd = GetItemIndex(pItem.Name);
	If Not IsBlankString(vInd) Then
		ExtraGuestSharePercentOnChangeAtServer(vInd);
	EndIf;
	ThisObject.Modified = True;
EndProcedure // ExtraGuestSharePercentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceCalculationDateStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = New ValueList;
	vList.Add("CurrentValue", NStr("en = 'Reset...'; de = 'Zurücksetzen...'; ru = 'Сбросить...'"));
	If ValueIsFilled(Object.ParentDoc) Then
		vList.Add("ByParentDoc", NStr("en = 'Fill in the reservation...'; de = 'Füllen Sie die Reservierung aus...'; ru = 'Заполнить по брони...'"));
	EndIf;
	ShowChooseFromList(New NotifyDescription("PriceCalculationDateFinishChoice", ThisObject), vList, pItem);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure EMail2OnChange(pItem)
	If IsBlankString(EMail2) Then
		Items.AddEmail2.Visible = True;
		Items.EMail2.Visible = false;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesCalendarDayTypeOnChange(pItem)
	vCurData = Items.Services.CurrentData;
	If vCurData <> Undefined Then
		If Not vCurData.IsManual And Not vCurData.CalendarDayTypeIsChanged Then
			vCurData.CalendarDayTypeIsChanged = True;
		EndIf;
	EndIf;
EndProcedure // ServicesCalendarDayTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesPriceTagOnChange(pItem)
	vCurData = Items.Services.CurrentData;
	If vCurData <> Undefined Then
		If Not vCurData.IsManual And Not vCurData.CalendarDayTypeIsChanged Then
			vCurData.CalendarDayTypeIsChanged = True;
		EndIf;
	EndIf;
EndProcedure // ServicesPriceTagOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomRateChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	FillAmenitiesFromRackRate(pSelectedValue);
	If ValueIsFilled(TServicePackagesPresentation) Then
		vServicePackagesList = GetServicePackagesListAtServer(Items.ServicePackage.Visible);
		FillAmenitiesFromServicePackages(vServicePackagesList);
	EndIf;
EndProcedure // RoomRateChoiceProcessing

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomRateClearing(pItem, pStandardProcessing)
	FillAmenitiesFromRackRate(Object.RoomRate, True);
	vServicePackagesList = GetServicePackagesListAtServer(Items.ServicePackage.Visible);
	FillAmenitiesFromServicePackages(vServicePackagesList);
EndProcedure // RoomRateClearing

// ----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeBeforeUpgradeOnChange(pItem)
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // RoomTypeBeforeUpgradeOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure ServicePackageBeforeUpgradeOnChange(pItem)
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // ServicePackageBeforeUpgradeOnChange

// ----------------------------------------------------------------------------
&AtClient
Procedure FixedChargesBeforeEditEnd(pItem, pNewRow, pCancelEdit, pCancel)
	vCurRow = Items.FixedCharges.CurrentData;
	If vCurRow <> Undefined And Not ValueIsFilled(vCurRow.Service) Then   
		vMsg = NStr("en = 'It is necessary to fill out the service for accrual'; 
					|de = 'Für die Abgrenzung ist es notwendig, den Service auszufüllen'; 
					|ru = 'Необходимо заполнить услугу для начисления'");   
		vIDRowPath = StrTemplate("Services[%1].Service", Object.Services.IndexOf(vCurRow));
		tcCommonFunctionOnClientServer.UserMessage(vMsg, ThisObject, vIDRowPath, , True); 
		pCancel = True;
		Return;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountConfirmationTextClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	ShowInputString(New NotifyDescription("DiscountConfirmationTextEditEnd", ThisObject), Object.DiscountConfirmationText, NStr("en='Edit text'; ru='Редактировать текст'; de='Text bearbeiten'"), 0, False);
EndProcedure // DiscountConfirmationTextClick

// -----------------------------------------------------------------------------
&AtClient
Procedure CarOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.GuestVehicles.ObjectForm", New Structure("Key", GetCarByDescriptionAtServer(TrimAll(Object.Car))), pItem, Object.Ref, , , New NotifyDescription("CarOpeningOnFinish", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // CarOpening

// --------------------------------------------------------------------------------
&AtClient
Procedure BedsSetupStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	Items.BedsSetup.ChoiceList.Clear();
	vBedsSetupList = GetBedsSetupList(Object.BedsSetup, Object.RoomType);
	For Each vBedsSetupListItem In vBedsSetupList Do
		Items.BedsSetup.ChoiceList.Add(vBedsSetupListItem.Value);
	EndDo;
EndProcedure // BedsSetupStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateGroupProformaInvoice(pCommand)
	If (WasPosted = False Or ThisObject.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "CreateGroupProformaInvoice"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		#If Not WebClient And Not MobileClient Then
			Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 10, NStr("en='Opening...';ru='Открытие формы...';de='Öffnen des Formulars...'"), PictureLib.LongOperation); 
		#EndIf
		vWarning = "";
		vAddRoomsToAllotment = False;
		vAllotmentBalances = Undefined;
		vResult = WriteAtServer(, vWarning, , , vAddRoomsToAllotment, vAllotmentBalances);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;		
		vBreakProcessing = False;
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.UserMessage(NStr(vResult));
			EndIf;
			vBreakProcessing = True;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;
	 	If vAddRoomsToAllotment Then
			ShowQueryBox(New NotifyDescription("AddRoomsToAllotment", ThisObject, New Structure("AllotmentBalances", vAllotmentBalances)), 
						 NStr("en='Add missing rooms to the allotment?'; ru='Добавить недостающие номера в квоту?'; de='Fehlende Zimmer zum Allotment hinzufügen?'"), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
		If vBreakProcessing Then
			Return;
		EndIf;
		#If Not WebClient And Not MobileClient Then
			Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 90, NStr("en='Opening...';ru='Открытие формы...';de='Öffnen des Formulars...'"), PictureLib.LongOperation); 
		#EndIf
	EndIf;
	#If ThinClient or WebClient Or MobileClient Then
		OpenForm("Document.ProformaInvoice.ObjectForm", New Structure("Basis", Object.GuestGroup));
	#Else
		vObj = NewGroupProformaInvoice(Undefined,False);
		vForm = GetForm("Document.ProformaInvoice.Form.DocumentForm", New Structure("Key",vObj));
		vForm.Open();
	#EndIf
EndProcedure // CreateGroupProformaInvoice

// -----------------------------------------------------------------------------
&AtClient
Procedure Post(pCommand)
	If ThisObject.ReadOnly Then
		Return;
	EndIf;
	// Clear messages left from previous run
	ClearMessages();
	// Check attributes
	If Not CheckAttributes() Then
		Return;
	EndIf;
	// Check user PIN if necessary
	If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
		OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "Write"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf;
	EmployeePINCodeChecked = False;      
	// APDEX
	vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.Posting";
	vApdexRemarks = GetRemarksForAPDEX();
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);
	// Do write procedure
	#If Not WebClient And Not MobileClient Then
		Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 10, NStr("en='Posting...';ru='Проводка документа...';de='Ausführen des Dokuments...'"), PictureLib.LongOperation); 
	#EndIf
	vWarning = "";
	vAddRoomsToAllotment = False;
	vAllotmentBalances = Undefined;
	vResult = WriteAtServer(, vWarning, True, , vAddRoomsToAllotment, vAllotmentBalances);
	If Not IsBlankString(vWarning) Then
		tcCommonFunctionOnClientServer.UserMessage(vWarning);
	EndIf;
	If ValueIsFilled(vResult) And vResult <> "Error" Then
		#If ThickClientOrdinaryApplication Then
			ShowMessageBox(, NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
		#Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
		#EndIf
	ElsIf Not ValueIsFilled(vResult) Then
		#If Not WebClient And Not MobileClient Then
			Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 90, NStr("en='Posting...';ru='Проводка документа...';de='Ausführen des Dokuments...'"), PictureLib.LongOperation); 
		#EndIf
		vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
		AfterWriteAtServer(Undefined, vWriteParameters);
		// Notify changes
		Notify("Subsystem.Accounts.Changed", Object.Ref, ThisObject);
		Notify("Document.Accommodation.Write", Object.Ref, Undefined);
		If GuestsToCheckInList.Count() > 0 Then
			Notify("CheckIn", Object.Ref, ThisObject);
		EndIf;
		Items.FormOpenBlockForm.Enabled = True;
		Items.FormCheckOut.Enabled = True;
		If ThisObject.IsNew Then
			ThisObject.IsNew = False;
		EndIf;
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Documents posting error!';ru='Ошибка проводки документа!';de='Fehler bei der Durchführung des Dokuments!'"));
	EndIf;
 	If vAddRoomsToAllotment Then
		ShowQueryBox(New NotifyDescription("AddRoomsToAllotment", ThisObject, New Structure("AllotmentBalances", vAllotmentBalances)), 
					 NStr("en='Add missing rooms to the allotment?'; ru='Добавить недостающие номера в квоту?'; de='Fehlende Zimmer zum Allotment hinzufügen?'"), 
					 QuestionDialogMode.YesNo, , DialogReturnCode.No);
	EndIf;
EndProcedure // Post

// -----------------------------------------------------------------------------
&AtClient
Procedure PostAndClose(pCommand)
	If ThisObject.ReadOnly Then
		Return;
	EndIf;
	// APDEX
	vKeyOperation = "Document.Accommodation.Form.tcDocumentForm.Posting";    
	vApdexRemarks = GetRemarksForAPDEX();
	APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, , vApdexRemarks);
	// Clear messages left from previous run
	ClearMessages();
	// Check attributes
	If Not CheckAttributes() Then
		Return;
	EndIf;
	// Check user PIN if necessary
	If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
		OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "WriteAndClose"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf;
	FunctionsAndPrintFormsWereLoaded = True;
	EmployeePINCodeChecked = False;
	// Do write procedure
	#If Not WebClient And Not MobileClient Then
		Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 10, NStr("en='Posting...';ru='Проводка документа...';de='Ausführen des Dokuments...'"), PictureLib.LongOperation); 
	#EndIf
	vWasModified = ThisObject.Modified Or WasNew;
	vWarning = "";
	vAddRoomsToAllotment = False;
	vAllotmentBalances = Undefined;
	vResult = WriteAtServer(, vWarning, , , vAddRoomsToAllotment, vAllotmentBalances);
	If Not IsBlankString(vWarning) Then
		If ValueIsFilled(vResult) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		Else
			ShowMessageBox(, vWarning);
		EndIf;
	EndIf;		
	If ValueIsFilled(vResult) And vResult <> "Error" Then
		#If ThickClientOrdinaryApplication Then
			ShowMessageBox(, NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
		#Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
		#EndIf
	ElsIf Not ValueIsFilled(vResult) Then
		#If Not WebClient And Not MobileClient Then
			Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 90, NStr("en='Posting...';ru='Проводка документа...';de='Ausführen des Dokuments...'"), PictureLib.LongOperation); 
		#EndIf
		IsOnCloseForm = True;
		// Notify changes in the accounts subsystem
		Notify("Subsystem.Accounts.Changed", Object.Ref, ThisObject);
		Notify("Document.Accommodation.Write", Object.Ref, ThisObject);
		// Open folios list
		If vWasModified Then  
			WasChanged = True;
			OpenFolios(Undefined);
		EndIf;
		If GuestsToCheckInList.Count() > 0 Then
			Notify("CheckIn", Object.Ref, ThisObject);
		EndIf;
		If Not vAddRoomsToAllotment Then
			Close();
		EndIf;
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Documents posting error!';ru='Ошибка проводки документа!';de='Fehler bei der Durchführung des Dokuments!'"));
	EndIf;
 	If vAddRoomsToAllotment Then
		ShowQueryBox(New NotifyDescription("AddRoomsToAllotment", ThisObject, New Structure("AllotmentBalances", vAllotmentBalances)), 
					 NStr("en='Add missing rooms to the allotment?'; ru='Добавить недостающие номера в квоту?'; de='Fehlende Zimmer zum Allotment hinzufügen?'"), 
					 QuestionDialogMode.YesNo, , DialogReturnCode.No);
	EndIf;
	#If ThickClientOrdinaryApplication Then
		// Write to last visited objects
		cmWriteToLastVisitedObjects(amPersistentObjects, Object.Ref);
	#EndIf
EndProcedure // PostAndClose

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInHouseGuests(pCommand)
#If ThickClientOrdinaryApplication Then
	// Open form
	vFrm = Documents.Accommodation.GetListForm();
	// Set filter to this guest group
	vFrm.SelHotel = Object.Hotel;
	vFrm.SelGuestGroup = Object.GuestGroup;
	vFrm.SelRoom = Catalogs.Rooms.EmptyRef();
	vFrm.SelRoomType = Catalogs.RoomTypes.EmptyRef();
	vFrm.SelCustomer = Catalogs.Customers.EmptyRef();
	vFrm.SelContract = Catalogs.Contracts.EmptyRef();
	vFrm.SelRemarks = "";
	vFrm.SelHotelProduct = Catalogs.HotelProducts.EmptyRef();
	vFrm.SelGuest = Catalogs.Clients.EmptyRef();
	vFrm.SelGuestStr = "";
	vFrm.SelIntersection = False;
	vFrm.SelCheckInDate = Undefined;
	vFrm.SelCheckOutDate = Undefined;
	// Open form
	If Not vFrm.IsOpen() Then
		vFrm.WindowAppearanceMode = WindowAppearanceModeVariant.Maximized;
	EndIf;
	vFrm.Open();
	// Open archive page
	vFrm.Controls.PanelList.CurrentPage = vFrm.Controls.PanelList.Pages.ArchivePage;
	// Close current form
	If Not ThisObject.Modified Then
		ThisObject.Close();
	EndIf;
#Else
	#IF NOT MobileClient THEN
		vFrm = GetForm("Document.Accommodation.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisObject);
		vFrm.SelGuestGroup = Object.GuestGroup;
		vFrm.Open();
	#ELSE
		OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisObject);	
	#ENDIF
#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInvoicesList(pCommand)
#If ThickClientOrdinaryApplication Then
	// Open form
	vFrm = Documents.Settlement.GetListForm();
	// Set filter to this guest group
	vFrm.SelHotel = Object.Hotel;
	vFrm.SelCustomer = Catalogs.Customers.EmptyRef();
	vFrm.SelGuestGroup = Object.GuestGroup;
	// Open form
	If Not vFrm.IsOpen() Then
		vFrm.WindowAppearanceMode = WindowAppearanceModeVariant.Maximized;
	EndIf;
	vFrm.Open();
	// Close current form
	If Not ThisObject.Modified Then
		ThisObject.Close();
	EndIf;
#Else
	vFrm = GetForm("Document.Settlement.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisObject);
	vFrm.SelGuestGroup = Object.GuestGroup;
	vFrm.Open();
#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenProformaInvoicesList(pCommand)
#If ThickClientOrdinaryApplication Then
	// Open form
	vFrm = Documents.ProformaInvoice.GetListForm();
	// Set filter to this guest group
	vFrm.SelHotel = Object.Hotel;
	vFrm.SelCustomer = Catalogs.Customers.EmptyRef();
	vFrm.SelGuestGroup = Object.GuestGroup;
	// Open form
	If Not vFrm.IsOpen() Then
		vFrm.WindowAppearanceMode = WindowAppearanceModeVariant.Maximized;
	EndIf;
	vFrm.Open();
	// Close current form
	If Not ThisObject.Modified Then
		ThisObject.Close();
	EndIf;
#Else
	vFrm = GetForm("Document.ProformaInvoice.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisObject);
	vFrm.SelGuestGroup = Object.GuestGroup;
	vFrm.Open();
#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenReservations(pCommand)
#If ThickClientOrdinaryApplication Then
	// Open form
	vFrm = Documents.Reservation.GetListForm();
	// Open form
	If Not vFrm.IsOpen() Then
		vFrm.WindowAppearanceMode = WindowAppearanceModeVariant.Maximized;
	EndIf;
	vFrm.Open();
	// Set filter to this guest group
	vFrm.SelHotel = Object.Hotel;
	vFrm.SelGuestGroup = Object.GuestGroup;
	vFrm.SelRoom = Catalogs.Rooms.EmptyRef();
	vFrm.SelRoomType = Catalogs.RoomTypes.EmptyRef();
	vFrm.SelCustomer = Catalogs.Customers.EmptyRef();
	vFrm.SelContract = Catalogs.Contracts.EmptyRef();
	vFrm.SelRemarks = "";
	vFrm.SelHotelProduct = Catalogs.HotelProducts.EmptyRef();
	vFrm.SelGuest = Catalogs.Clients.EmptyRef();
	vFrm.SelGuestStr = "";
	vFrm.SelCheckInDate = Undefined;
	vFrm.SelPeriodFromDate = Undefined;
	vFrm.SelPeriodToDate = Undefined;
	// Open filter page
	vFrm.Controls.PanelSearch.CurrentPage = vFrm.Controls.PanelSearch.Pages.SearchPage;
	// Close current form
	If Not ThisObject.Modified Then
		ThisObject.Close();
	EndIf;
#Else
	#IF NOT MobileClient THEN
		vFrm = GetForm("Document.Reservation.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisObject);
		vFrm.SelGuestGroup = Object.GuestGroup;
		vFrm.Open();
	#ELSE
		OpenForm("Document.Reservation.Form.mcReservationListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisObject);	
	#ENDIF
#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenChangeHistory(pCommand)
	If ThisObject.IsNew Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("ru='Документ должен быть записан!';
		                  |de='Das Dokument muss aufgezeichnet sein!'; 
		                  |en='Please write document first!'"));
		Return;
	EndIf;
	#If ThickClientOrdinaryApplication Then
		vFrm = InformationRegisters.AccommodationChangeHistory.GetListForm(, ThisObject, Object.Ref);
		vFrm.FilterByDimensionParameter = New Structure("Accommodation", Object.Ref);
		vFrm.ReadOnly = ThisObject.ReadOnly;
		If Not vFrm.IsOpen() Then
			vFrm.WindowAppearanceMode = WindowAppearanceModeVariant.Maximized;
		EndIf;
		vFrm.Open();
	#Else
		vFrm = OpenForm("InformationRegister.AccommodationChangeHistory.ListForm", New Structure("Accommodation", Object.Ref), ThisObject, Object.Ref);
		vFrm.ReadOnly = ThisObject.ReadOnly;
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenOrdinaryApplicationForm(pCommand)
	If ThisObject.IsNew Then
		ShowMessageBox(Undefined, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	ElsIf ThisObject.Modified Then
		vWarning = "";
		vResult = WriteAtServer(, vWarning, True, DocumentWriteMode.Write);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				ShowMessageBox(, vResult);
			EndIf;
			Return;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;         
		SavedButNotPostedWhileOpen = True;
	EndIf;
	ThisObject.UnlockFormDataForEdit();
	#If ThickClientOrdinaryApplication Then
		vFrm = GetForm("Document.Accommodation.ObjectForm", New Structure("Key", Object.Ref), ThisObject);
		vFrm.CloseOnOwnerClose = False;
		vFrm.SelOpenOrdinaryForm = True;
		vFrm.Open();
	#Else
		OpenForm("Document.Accommodation.ObjectForm", New Structure("Key, OneGuestMode, IsForFolioSplit", Object.Ref, True, Object.IsForFolioSplit), ThisObject, tcOnServer.GetStringUUIDByRef(Object.Ref));
	#EndIf
EndProcedure // OpenOrdinaryApplicationForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenBlockForm(pCommand)
	If ThisObject.IsNew Or ThisObject.Modified Then
		ShowMessageBox(Undefined, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	Else
		ThisObject.UnlockFormDataForEdit();
	EndIf;
	#If ThickClientOrdinaryApplication Then
		vFrm = GetForm("Document.Accommodation.ObjectForm", New Structure("Key", Object.Ref), ThisObject);
		vFrm.CloseOnOwnerClose = False;
		vFrm.SelOpenOrdinaryForm = True;
		vFrm.SelOpenGroupTableBox = True;
		vFrm.Open();
	#EndIf
EndProcedure // OpenBlockForm

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOut(pCommand)
	If (WasPosted = False Or ThisObject.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "CheckOut"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vResult = WriteAtServer(, vWarning);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;		
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				ShowMessageBox(, vResult);
			EndIf;
			Return;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;         
	EndIf;
	// Check document form mode
	If OneGuestMode Then
		OpenForm("CommonForm.tcChangeRoomWizard", New Structure("DocRef, OperationType", Object.Ref, 2), ThisObject);
		Return;
	EndIf;
	// Build list of documents to be checked out
	AccList = New ValueList;
	If Not OneGuestMode Then
		i = GuestsInGroup.Count() - 1;
		While i >= 0 Do
			vRow = GuestsInGroup.Get(i);
			If ValueIsFilled(vRow.Ref) Then
				AccList.Add(vRow.Ref);
			EndIf;
			i = i - 1;
		EndDo;
	EndIf;
	AccList.Add(Object.Ref);
	// *** CURRENT DOCUMENT ***
	// Check if document is posted
	If IsNew Then
		ShowMessageBox(, NStr("ru='Процедура выселения не возможна для не проведенного размещения!';
		                      |de='Das Ausweisungsverfahren ist für nicht durchgeführte Unterbringungen nicht möglich!'; 
		                      |en='Check out procedure is not possible for the accommodation that is not posted!'"));
		Return;
	EndIf;
	// Check document form state. If document is open for read only then do 
	// message and cancel action
	If ThisObject.ReadOnly Then
		ShowMessageBox(, NStr("en='Action choosen is not permitted from the document opened for read only!';
		                      |ru='Действие не разрешено из документа открытого на просмотр!';
		                      |de='Die Aktion ist aus dem zur Ansicht geöffneten Dokument nicht erlaubt!'"));
		Return;
	EndIf;
	// Give warning if current date is less then expected check-out date
	If BegOfDay(Object.CheckOutDate) > BegOfDay(CurrentDate()) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Expected check-out date " + Format(Object.CheckOutDate, "DF=dd.MM.yyyy") + " is in the future!'; 
		             |de='Expected check-out date " + Format(Object.CheckOutDate, "DF=dd.MM.yyyy") + " is in the future!'; 
		             |ru='Дата планируемого выезда " + Format(Object.CheckOutDate, "DF=dd.MM.yyyy") + " в будущем!'"));
	EndIf;
	// Get check-out date
	CheckOutDateTime = '00010101';
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
		GetCheckOutDate(Object.CheckInDate, Object.CheckOutDate);
	Else
		CheckOutDateTime = Object.CheckOutDate;
	EndIf;
	AttachIdleHandler("CheckIfCheckOutDateTimeIsFilled", 1, False);
EndProcedure // CheckOut

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGroupSettlement(pCommand)
	If ThisObject.Modified Then
		ShowMessageBox(, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	vMessage = "";
	vInvoice = Undefined;
	// Try to  search for unposted invoice
	vUnpostedInvoices = GetUnpostedGroupInvoices(Object.GuestGroup);
	If vUnpostedInvoices.Count() > 0 Then
		vInvoice = vUnpostedInvoices.Get(0).Value;
	EndIf;
	// Fill new or refill existing unposted invoice
	vResult = GuestGroupFillSettlement(Object.GuestGroup, vMessage, vInvoice);
	If vResult = -1 Then
		ShowMessageBox(, vMessage);
	Else
		If vResult = 0 Then
			vInvList = GetListOfGroupInvoices(Object.GuestGroup);
			If vInvList.Count() = 0 Then
				ShowMessageBox(, vMessage);
			ElsIf vInvList.Count() = 1 Then
				vInvoice = vInvList.Get(0).Value;
			Else
				ShowChooseFromMenu(New NotifyDescription("PrintInvoiceAfterInvoiceSelection", ThisObject), vInvList, Items.GuestGroupDescription);
			EndIf;
		EndIf;
		If ValueIsFilled(vInvoice) Then
			PrintInvoice(vInvoice);
		EndIf;
	EndIf;
EndProcedure // PrintGroupSettlement

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateGroupSettlement(pCommand)
	If ThisObject.Modified Then
		ShowMessageBox(, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	#If ThickClientOrdinaryApplication Then
		// Do for each accommodation in guest group
		vDocObj = Documents.Settlement.CreateDocument();
		vDocObj.Fill(Object.Ref);
		// Clear parent document
		vDocObj.ParentDoc = Documents.Accommodation.EmptyRef();
		// Fill by guest group
		vDocObj.Fill(Object.GuestGroup);
		// Open form
		vFrm = vDocObj.GetForm();
		vFrm.Open();
		If Not ThisObject.Modified Then
			If ThisObject.IsOpen() Then
				ThisObject.Close();
			EndIf;
		EndIf;
	#Else
		// Get list of all group invoices
		vInvoicesList = GetGroupInvoices(Object.GuestGroup);
		// Open new invoice form
		vFrm = OpenForm("Document.Settlement.ObjectForm", New Structure("Basis, ParentDoc, HasOfficialLetter", Object.GuestGroup, Object.Ref, Object.HasOfficialLetter), ThisObject, Object.GuestGroup);
		If vFrm.Object.Services.Count() = 0 Then
			If vInvoicesList.Count() > 0 Then
				// Invoice was already created
				vFrm.Close();
				// Show existing invoices
				If vInvoicesList.Count() = 1 Then
					vInvItem = vInvoicesList.Get(0);
					OpenForm("Document.Settlement.ObjectForm", New Structure("Key", vInvItem.Value), ThisObject, vInvItem.Value);
					vMessage = NStr("en='No data for the new invoice was found! Existing invoice was opened'; 
					                |ru='Нет данных для нового акта! Открылся существующий акт'; 
					                |de='Für die neue Rechnung wurden keine Daten gefunden! Bestehende Rechnung geöffnet'");
					ShowMessageBox(, vMessage);
				Else
					vMessage = NStr("en='No data for the new invoice was found! Please choose invoice from the list of existing invoices'; 
					                |ru='Нет данных для нового акта! Выберите один из существующих актов'; 
					                |de='Für die neue Rechnung wurden keine Daten gefunden! Wählen Sie eine der vorhandenen Rechnungen'");
					vInvoicesList.ShowChooseItem(New NotifyDescription("GroupInvoiceSelection", ThisObject), vMessage);
				EndIf;
			EndIf;
		EndIf;
	#EndIf
EndProcedure // CreateGroupSettlement

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExtraGuestOrdinaryApplicationForm(pCommand)
	If ThisObject.IsNew Then
		ShowMessageBox(, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	ElsIf ThisObject.Modified Then
		vWarning = "";
		vResult = WriteAtServer(, vWarning, True, DocumentWriteMode.Write);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				ShowMessageBox(, vResult);
			EndIf;
			Return;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;         
		SavedButNotPostedWhileOpen = True;
	EndIf;
	vDocRef = GetGuestDocumentRefByItemID(ThisObject.CurrentItem.Name);
	If Not ValueIsFilled(vDocRef) Then
		ShowMessageBox(, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	#If ThickClientOrdinaryApplication Then
		vFrm = GetForm("Document.Accommodation.ObjectForm", New Structure("Key", vDocRef), ThisObject);
		vFrm.CloseOnOwnerClose = False;
		vFrm.SelOpenOrdinaryForm = True;
		vFrm.Open();
	#Else
		OpenForm("Document.Accommodation.ObjectForm", New Structure("Key, OneGuestMode, IsForFolioSplit", vDocRef, True, tcOnServer.cmGetAttributeByRef(vDocRef, "IsForFolioSplit")), ThisObject, tcOnServer.GetStringUUIDByRef(vDocRef));
	#EndIf
EndProcedure // OpenExtraGuestOrdinaryApplicationForm

// -----------------------------------------------------------------------------
&AtClient
Procedure SetMainGuest(pCommand)
	vGuestRef = Undefined;
	vInd = StrReplace(CurrentItem.Name, "ButtonSetMainGuest", "");
	If tcOnServer.IsNumber(vInd) Then
		vInd = Number(vInd) - 2;
		If vInd >= 0 Then
			vGuestsInGroupCount = GuestsInGroup.Count(); 
			If vInd < vGuestsInGroupCount Then
				vGuestRef = GuestsInGroup.Get(vInd).GuestRef;
			EndIf;
		EndIf;
	EndIf;
	If vGuestRef = Undefined Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Guest not found.'; de = 'Gast nicht gefunden.'; ru = 'Гость не найден'"));
		Return;	
	EndIf;
	If Not ValueIsFilled(ThisObject["AccommodationType" + TrimAll(vInd + 2)]) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = '<Accommodation type> attribute should be filled!'; de = '<Accommodation type> attribute should be filled!'; ru = 'Реквизит <Вид размещения> должен быть заполнен!'"));
		Return	
	EndIf;
	Object.EMail = "";
	Object.Phone = "";
	vMainGuestRef = Object.Guest;
	vMainGuestFullName = SelGuest1;
	vOtherGuestFullName = ThisObject["SelGuest"+ TrimAll(vInd + 2)];
	If ValueIsFilled(vGuestRef) Then
		Object.Guest = vGuestRef;
		SelGuest1 = tcOnServer.cmGetAttributeByRef(vGuestRef, "FullName");
		Items.SelGuest1.TextEdit = False;
		LastGuestFullName = SelGuest1;
		vPhone = SMS.GetValidPhoneNumber(tcOnServer.cmGetAttributeByRef(vGuestRef, "Phone"));
		If ValueIsFilled(vPhone) Then
			Object.Phone = vPhone;
		EndIf;
		vEMail = tcOnServer.cmGetAttributeByRef(vGuestRef, "EMail");
		If ValueIsFilled(vEMail) Then
			Object.EMail = vEMail;
		EndIf;
		GuestOnChangeAtServer();
	Else
		Object.Guest = tcOnServer.cmGetCatalogItemRefByCode("Clients",, True);
		SelGuest1 = vOtherGuestFullName;
		Items.SelGuest1.TextEdit = True;
	EndIf;
	If ValueIsFilled(vMainGuestRef) Then
		ThisObject["Guest" + TrimAll(vInd + 2)] = vMainGuestRef;
		ThisObject["SelGuest" + TrimAll(vInd + 2)] = tcOnServer.cmGetAttributeByRef(vMainGuestRef, "FullName");
		ThisObject["LastGuestFullName" + TrimAll(vInd + 2)] = Items["SelGuest" + TrimAll(vInd + 2)];
		Items["SelGuest" + TrimAll(vInd + 2)].TextEdit = False;
	Else
		ThisObject["Guest" + TrimAll(vInd + 2)] = tcOnServer.cmGetCatalogItemRefByCode("Clients",, True);
		ThisObject["SelGuest" + TrimAll(vInd + 2)] = vMainGuestFullName;
		Items["SelGuest" + TrimAll(vInd + 2)].TextEdit = True;
	EndIf;     
	AddGuestOnChange(Items["SelGuest" + TrimAll(vInd + 2)]);
	CheckGuestRemarksOnClient(Items.SelGuest1);
	CheckGuestRemarksOnClient(Items["SelGuest" + TrimAll(vInd + 2)]);
	ThisObject.Modified = True;
EndProcedure // SetMainGuest

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearExtraGuestChanges(pCommand)
	If ThisObject.IsNew Then
		ShowMessageBox(, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	vDocRef = GetGuestDocumentRefByItemID(ThisObject.CurrentItem.Name);
	If Not ValueIsFilled(vDocRef) Then
		ShowMessageBox(, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	For Each vGiGRow In GuestsInGroup Do
		If vGiGRow.Ref = vDocRef Then
			// Reset changes except check-in date
			vGiGRow.ChangesDescription = "";
			vGiGRow.RoomRateIsDifferent = False;
			vGiGRow.DiscountsAreDifferent = False;
			vGiGRow.ManualPricesAreDifferent = False;
			vGiGRow.ServicePackagesAreDifferent = False;
			vGiGRow.RoomRatesAreDifferent = False;
			vGiGRow.CheckOutDateIsDifferent = False;
			vGiGRow.ClientTypeIsDifferent = False;
			vGiGRow.BoardPlaceIsDifferent = False;
			vGiGRow.IsForFolioSplitIsDifferent = False;
			// Get index and hide changes group
			vInd = GuestsInGroup.IndexOf(vGiGRow) + 2;
			ThisObject["GuestChangesDescription" + String(vInd)] = vGiGRow.ChangesDescription;
			vCDItem = Items["Guest" + String(vInd) + "ChangesGroup"];
			vCDItem.Visible = False;
			Break;
		EndIf;
	EndDo;
EndProcedure // ClearExtraGuestChanges

// -----------------------------------------------------------------------------
&AtClient
Procedure Pay(pCommand)
	If (WasPosted = False Or ThisObject.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "Pay"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vResult = WriteAtServer(, vWarning);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;		
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.UserMessage(vResult);
			EndIf;
			Return;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;         
	EndIf;
	// Get payment folio
	vFolio = GetPaymentFolio(Object.Ref);
	If ValueIsFilled(vFolio) Then
		// Open payment form
		#If ThickClientOrdinaryApplication Then
			vPayment = Documents.Payment.CreateDocument();
			vPayment.Fill(vFolio);
			vPayment.GetForm().Open();
		#Else
			OpenForm("Document.Payment.ObjectForm", New Structure("Basis", vFolio), ThisObject);
		#EndIf
	EndIf;
EndProcedure // Pay

// -----------------------------------------------------------------------------
&AtClient
Procedure MakeKey(pCommand)
	If (WasPosted = False Or ThisObject.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "MakeKey"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vResult = WriteAtServer(, vWarning);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;		
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.UserMessage(vResult);
			EndIf;
			Return;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;         
	EndIf;
	
	vParametersKeyCard = FillParametersKeyCard(Object.Ref);
	vParams = New Structure();
	vParams.Insert("ParametersKeyCard", vParametersKeyCard);
	vParams.Insert("ParametersOneGuestMode", OneGuestMode);
	vCurWorkstation = tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation");
	OpenForm("CommonForm.tcIssueKeyCard", vParams, ThisObject, vCurWorkstation, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // MakeKey

// -----------------------------------------------------------------------------
&AtClient
Procedure IssueIdentityCard(pCommand)
	If (WasPosted = False Or ThisObject.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Save document first
		vWarning = "";
		vResult = WriteAtServer(, vWarning);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;		
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.UserMessage(vResult);
			EndIf;
			Return;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;         
	EndIf;
	// Get current accommodation
	vCurDoc = Object.Ref;
	vParameters = FillParametersCard(vCurDoc);
	If ValueIsFilled(vParameters.IdentityCardSystemParameters) Then
		vArrIdentityCardSystemParameters = tcOnServer.cmGetAtributeAsArray(vParameters.IdentityCardSystemParameters);
		If ValueIsFilled(vArrIdentityCardSystemParameters.ExternalInteraction) And 
			tcOnServer.cmGetAttributeByRef(vArrIdentityCardSystemParameters.ExternalInteraction, "IntegrationType") = PredefinedValue("Enum.Integrations.ISD") Then
			OpenForm("CommonForm.tcRoomIdentityCardsRegistrationISD", vParameters, ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);	
		ElsIf vArrIdentityCardSystemParameters.IssueCardsForAllGuestsInTheRoom And ValueIsFilled(vParameters.Room) Then
			OpenForm("CommonForm.tcRoomIdentityCardsRegistration", vParameters, ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);	
		Else
			OpenForm("CommonForm.tcClientIdentityCardsRegistration", vParameters, ThisObject, , , , , FormWindowOpeningMode.LockWholeInterface);
		EndIf;
	Else
		ShowMessageBox(, NStr("en='Client identity cards system is not configurated properly for the current workstation!';ru='Система карт идентификации клиентов на данном рабочем месте не настроена!';de='Das System für Kundenausweise ist auf diesem Arbeitsplatz nicht eingestellt!'"));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Task(pCommand)
	stParam = New Structure("SetParamObject", Object.Ref);
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam, ThisObject, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure // Task

// -----------------------------------------------------------------------------
&AtClient
Procedure SendWelcomeSMS(pCommand)
	vMessage = SendWelcomeSMSAtServer();
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndIf;
EndProcedure // SendWelcomeSMS

// -----------------------------------------------------------------------------
&AtClient
Procedure FillAccommodation(pCommand)
	// Save document first
	If ThisObject.Modified Then
		Post(pCommand);
		ThisObject.Modified = False;
		ThisObject.UnlockFormDataForEdit();
	EndIf;
	// Create form for the new accommodation
	OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("ParentAccommodation", Object.Ref), , New UUID);
	// Close this document
	ThisObject.Close();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ScanDocuments(pCommand)
	If (WasPosted = False Or ThisObject.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "ScanDocuments"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vAddRoomsToAllotment = False;
		vAllotmentBalances = Undefined;
		vResult = WriteAtServer(, vWarning, , , vAddRoomsToAllotment, vAllotmentBalances);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;
		vBreakProcessing = False;
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.UserMessage(vResult);
			EndIf;
			vBreakProcessing = True;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;         
	 	If vAddRoomsToAllotment Then
			ShowQueryBox(New NotifyDescription("AddRoomsToAllotment", ThisObject, New Structure("AllotmentBalances", vAllotmentBalances)), 
						 NStr("en='Add missing rooms to the allotment?'; ru='Добавить недостающие номера в квоту?'; de='Fehlende Zimmer zum Allotment hinzufügen?'"), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
		If vBreakProcessing Then
			Return;
		EndIf;
	EndIf;
	#If ThickClientOrdinaryApplication Then
		vAccList = New ValueList();
		vAccList.Add(Object.Ref);
		For Each vGuestsInGroupRow In GuestsInGroup Do
			If ValueIsFilled(vGuestsInGroupRow.Ref) Then
				vAccList.Add(vGuestsInGroupRow.Ref);
			EndIf;
		EndDo;
		For Each vAccListItem In vAccList Do
			vAccRef = vAccListItem.Value;
			vDoc = GetClientDataScanDocument(vAccRef);
			If ValueIsFilled(vDoc) Then
				vFrm = vDoc.GetForm(, ThisObject, vDoc);
				vFrm.CloseOnOwnerClose = False;
				If vFrm.Guest <> vAccRef.Guest Then
					vFrm.Guest = vAccRef.Guest;
				EndIf;
				If vFrm.ParentDoc <> vAccRef.Ref Then
					vFrm.ParentDoc = vAccRef.Ref;
				EndIf;
				If vFrm.GuestGroup <> vAccRef.GuestGroup Then
					vFrm.GuestGroup = vAccRef.GuestGroup;
				EndIf;
				If vFrm.Room <> vAccRef.Room Then
					vFrm.Room = vAccRef.Room;
				EndIf;
				vFrm.Open();
			Else
				vFrm = Documents.ClientDataScans.GetNewDocumentForm(, ThisObject, vAccRef);
				vFrm.ThisObject.Fill(vAccRef);
				vFrm.CloseOnOwnerClose = False;
				vFrm.Open();
			EndIf;
		EndDo;
	#Else
		vScanRef = GetClientDataScanDocument(Object.Ref);
		If ValueIsFilled(vScanRef) Then
			vFrm = GetForm("Document.ClientDataScans.ObjectForm", New Structure("Key, Guest, ParentDoc, GuestGroup, Room", vScanRef, Object.Guest, Object.Ref, Object.GuestGroup, Object.Room), ThisObject, "ClientDataScans");
			If vFrm <> Undefined And vFrm.IsOpen() Then
				ShowMessageBox(, NStr("en='You have an other scan form open already! Close the previous one first.'; ru='Уже открыта форма сканов! Сначала закройте предыдущую.'; de='Sie haben bereits die Form der Scans geöffnet! Schließen Sie zuerst die vorherige.'"));
				Return;
			EndIf;
			vFrm.Open();
		Else
			vFrm = GetForm("Document.ClientDataScans.ObjectForm", New Structure("basis", Object.Ref), ThisObject, "ClientDataScans");
			If vFrm <> Undefined And vFrm.IsOpen() Then
				ShowMessageBox(, NStr("en='You have an other scan form open already! Close the previous one first.'; ru='Уже открыта форма сканов! Сначала закройте предыдущую.'; de='Sie haben bereits die Form der Scans geöffnet! Schließen Sie zuerst die vorherige.'"));
				Return;
			EndIf;
			vFrm.Open();
		EndIf;
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NewOrder(pCommand)
	If ValueIsFilled(Object.Ref) Then
		vParam = New Structure();
		vParam.Insert("basis", Object.Ref);
		OpenForm("Document.Order.ObjectForm", vParam, ThisObject, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // NewOrder

// -----------------------------------------------------------------------------
&AtClient
Procedure FuncButtonClick(pCommand)
	If ThisObject.IsNew Or ThisObject.Modified Then
		ShowMessageBox(Undefined, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	
	vActionsNumber = StrReplace(pCommand.Name,"Func","");
	vAction = GetActionForNumber(vActionsNumber);
	
	If ValueIsFilled(vAction.ExternalProcessing) Then
		#If ThickClientOrdinaryApplication Then
			If Not cmLoadExternalDataProcessor(vAction.ExternalProcessing, FormAttributeToValue("Object", Type("DocumentObject.Accommodation")), , Undefined) Then
				ShowMessageBox(, NStr("en='Failed to load external action!';ru='Не удалось загрузить внешнюю операцию!';de='Die externe Operation konnte nicht geladen werden!'"));
			EndIf;
		#EndIf
	Else
		If vAction.PredefinedDataName = "AccommodationGuestGroupFillSettlement" Then
			CreateGroupSettlement(Undefined);
		ElsIf vAction.PredefinedDataName = "AccommodationSendWelcomeSMS" Then
			SendWelcomeSMS(Commands.SendWelcomeSMS);
		ElsIf vAction.PredefinedDataName = "AccommodationFillClientFeedback" Then
			AccommodationFillClientFeedback(Undefined);
		ElsIf vAction.PredefinedDataName = "AccommodationFillAccommodation" Then
			FillAccommodation(Commands.FillAccommodation);
		ElsIf vAction.PredefinedDataName = "AccommodationGuestGroupFillInvoice" Then
			CreateGroupProformaInvoice(Commands.CreateGroupProformaInvoice);
		ElsIf vAction.PredefinedDataName = "AccommodationPrintCoupons" Then
			AccommodationPrintCoupons(vAction, Object.Ref);
		ElsIf vAction.PredefinedDataName = "AccommodationPrintRoomCoupons" Then
			AccommodationPrintCoupons(vAction, Object.Room);
		ElsIf vAction.PredefinedDataName = "AccommodationPrintGuestGroupCoupons" Then
			AccommodationPrintCoupons(vAction, Object.GuestGroup);
		ElsIf vAction.PredefinedDataName = "AccommodationFillInvoice" Then  
			AccommodationFillInvoice();
		ElsIf vAction.PredefinedDataName = "AccommodationChangeRoom" Then  
			AccommodationChangeRoom();
		ElsIf vAction.PredefinedDataName = "AccommodationFillOrder" Then
			vParam = New Structure;
			vParam.Insert("basis",Object.Ref);
			OpenForm("Document.Order.Form.DocumentForm", vParam, ThisObject, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
		// Run data processor
		ElsIf ValueIsFilled(vAction.DataProcessor) Then
			vReturnParameter = New Structure("Action, Data");
			If Not RunDataProcessor(vAction.DataProcessor, Object.Ref, True, vReturnParameter) Then
				ShowMessageBox(, NStr("en='Failed to run data processor!';ru='Не удалось выполнить обработку!';de='Die Bearbeitung ist fehlgeschlagen!'"));
			Else
				If vReturnParameter <> Undefined And TypeOf(vReturnParameter) = Type("Structure") Then
					If vReturnParameter.Property("Action") And vReturnParameter.Action <> Undefined Then
						If vReturnParameter.Action = "ShowFile" Then
							vFileData = vReturnParameter.Data;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		Else
			ShowMessageBox(, NStr("en='No data processor found for action!';ru='У действия не указан обработчик!';de='Bei der Aktion ist kein Bearbeiter angegeben!'"));
		EndIf;
	EndIf;   
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AddResortFeeExemption(pCommand)
	If ValueIsFilled(Object.Hotel) And tcOnServer.cmGetAttributeByRef(Object.Hotel, "TouristTaxIsUsed") And Object.CheckInDate > Date(2025, 1, 1) Then
		vList = tcOnClient.cmGetTouristTaxExemptionReasonsList();
		vList.ShowChooseItem(New NotifyDescription("AfterTouristTaxExemptionChoice", ThisObject), NStr("en='Choose reason'; ru='Выберите причину'; de='Wählen Sie den Grund'"));
	Else
		vList = tcOnClient.cmGetResortFeeExemptionReasonsList();
		vList.ShowChooseItem(New NotifyDescription("AfterResortFeeExemptionChoice", ThisObject), NStr("en='Choose reason'; ru='Выберите причину'; de='Wählen Sie den Grund'"));
	EndIf;
EndProcedure // AddResortFeeExemption

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButtonClick(pCommand)
	If ThisObject.IsNew Or ThisObject.Modified Then
		ShowMessageBox(Undefined, NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	
	vPrintNumber = StrReplace(pCommand.Name,"Print","");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"));
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"));
		EndTry;
	ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintHotelProduct" Or
	      vPrintForm.PredefinedDataName = "AccommodationPrintGuestGroupHotelProducts" Then
		PrintHotelProduct(vPrintForm.Language, vPrintForm.Ref);
	ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestForm2Forms5" Or 
	      vPrintForm.PredefinedDataName = "AccommodationPrintGuestFormFreeForm" Or
	      vPrintForm.PredefinedDataName = "AccommodationPrintGuestCardFreeForm" Or
	      vPrintForm.PredefinedDataName = "AccommodationPrintGuestCardForm4G" Or
	      vPrintForm.PredefinedDataName = "AccommodationPrintGuestRegistrationForm" Then
		WasAlreadyPrint = True;
		PrintGuestForm(vPrintForm.PredefinedDataName);
	ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestsForms2Forms5" Or 
	      vPrintForm.PredefinedDataName = "AccommodationPrintGuestsFormsFreeForm" Or
	      vPrintForm.PredefinedDataName = "AccommodationPrintGuestsCardsFreeForm" Or
	      vPrintForm.PredefinedDataName = "AccommodationPrintGuestsCardsForm4G" Or
	      vPrintForm.PredefinedDataName = "AccommodationPrintGuestRegistrationForms" Then
		WasAlreadyPrint = True;
		PrintGuestsForms(vPrintForm.PredefinedDataName);
	ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestPersonalDataProcessingConsent" Then
		WasAlreadyPrint = True;
		PrintGuestPersonalDataProcessingConsent();
	ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintGuestRefusalToPayResortFee" Then
		WasAlreadyPrint = True;
		PrintGuestRefusalToPayResortFee();
	ElsIf vPrintForm.PredefinedDataName = "AccommodationPrintDepartureNotificationForm" Then
		WasAlreadyPrint = True;
		PrintGuestDepartureNotificationForm(vPrintForm.PredefinedDataName);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeRoomWizard(pCommand)
	If Object.Ref.IsEmpty() Or ThisObject.Modified Then
		ShowMessageBox(, NStr("ru='Документ должен быть записан!';
		                      |de='Das Dokument muss aufgezeichnet sein!'; 
		                      |en='Please write document first!'"));
		Return;
	EndIf;
	OpenForm("CommonForm.tcChangeRoomWizard", New Structure("DocRef, GuestTable", Object.Ref, GuestsInGroup), ThisObject);
EndProcedure // ChangeRoomWizard

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesEditRow(pCommand)
	vCurRow = Items.ChargingRules.CurrentData;
	If vCurRow <> Undefined Then
		pStandardProcessing = False;
		vParams = New Structure("SelObjectRef, SelLineNumber, SelOwner, SelChargingRule, SelChargingRuleValue, SelChargingFolio, SelValidFromDate, SelValidToDate, SelIsMaster, SelIsPersonal, SelIsTransfer, SelHotel, SelCompany, SelGuestGroup, SelRoom, SelClient, SelCheckInDate, SelCheckOutDate", 
								 Object.Ref, vCurRow.LineNumber, vCurRow.Owner, vCurRow.ChargingRule, vCurRow.ChargingRuleValue, vCurRow.ChargingFolio, vCurRow.ValidFromDate, vCurRow.ValidToDate, vCurRow.IsMaster, vCurRow.IsPersonal, vCurRow.IsTransfer, Object.Hotel, Object.Company, Object.GuestGroup, Object.Room, Object.Guest, Object.CheckInDate, Object.CheckOutDate);
		OpenForm("CommonForm.tcEditChargingRule", New Structure("Parameters, EditMode", vParams, Not (vCurRow.IsTransfer Or vCurRow.IsMaster)), ThisObject, UUID, , , New NotifyDescription("AfterChangeChargingRules", ThisObject, vCurRow), FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure // ChargingRulesEditRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesAddRow(pCommand)
	vCurRow = Object.ChargingRules.FindByID(ChargingRulesAddRowAtServer());
	If vCurRow <> Undefined Then
		vParams = New Structure("SelObjectRef, SelLineNumber, SelOwner, SelChargingRule, SelChargingRuleValue, SelChargingFolio, SelValidFromDate, SelValidToDate, SelIsMaster, SelIsPersonal, SelIsTransfer, SelHotel, SelCompany, SelGuestGroup, SelRoom, SelClient, SelCheckInDate, SelCheckOutDate", 
								 Object.Ref, vCurRow.LineNumber, vCurRow.Owner, vCurRow.ChargingRule, vCurRow.ChargingRuleValue, vCurRow.ChargingFolio, vCurRow.ValidFromDate, vCurRow.ValidToDate, vCurRow.IsMaster, vCurRow.IsPersonal, vCurRow.IsTransfer, Object.Hotel, Object.Company, Object.GuestGroup, Object.Room, Object.Guest, Object.CheckInDate, Object.CheckOutDate);
		OpenForm("CommonForm.tcEditChargingRule", New Structure("Parameters, EditMode", vParams, False), ThisObject, UUID, , , New NotifyDescription("AfterChangeChargingRules", ThisObject, vCurRow), FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure // ChargingRulesAddRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesCopyRow(pCommand)
	vCurRow = Items.ChargingRules.CurrentData;
	If vCurRow <> Undefined Then
		vNewRowID = ChargingRulesCopyRowAtServer(vCurRow.GetID());
		If vNewRowID <> Undefined Then 
			vNewCurRow = Object.ChargingRules.FindByID(vNewRowID);
			If vNewCurRow <> Undefined Then
				vParams = New Structure("SelObjectRef, SelLineNumber, SelOwner, SelChargingRule, SelChargingRuleValue, SelChargingFolio, SelValidFromDate, SelValidToDate, SelIsMaster, SelIsPersonal, SelIsTransfer, SelHotel, SelCompany, SelGuestGroup, SelRoom, SelClient, SelCheckInDate, SelCheckOutDate", 
										 Object.Ref, vNewCurRow.LineNumber, vNewCurRow.Owner, vNewCurRow.ChargingRule, vNewCurRow.ChargingRuleValue, vNewCurRow.ChargingFolio, vNewCurRow.ValidFromDate, vNewCurRow.ValidToDate, vNewCurRow.IsMaster, vNewCurRow.IsPersonal, vNewCurRow.IsTransfer, Object.Hotel, Object.Company, Object.GuestGroup, Object.Room, Object.Guest, Object.CheckInDate, Object.CheckOutDate);
				OpenForm("CommonForm.tcEditChargingRule", New Structure("Parameters, SelClone, EditMode", vParams, True, False), ThisObject, UUID, , , New NotifyDescription("AfterChangeChargingRules", ThisObject, vNewCurRow), FormWindowOpeningMode.Independent);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ChargingRulesCopyRow

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadDefaultChargingRules(pCommand)
	LoadDefaultChargingRulesAtServer();
EndProcedure // LoadDefaultChargingRules

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateServices(pCommand)
	// Recalculate transactions plan
	RecalculateServicesAtServer();
	// Refresh grid
	FillGridAtServer();
	// Form appearance
	ThisObject.Modified = True;
EndProcedure // RecalculateServices

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearServicesManualChanges(pCommand)
	ClearServicesManualChangesAtServer();
	RecalculateServicesAtServer();
	ManualServicesPriceAppearance();
	ThisObject.Modified = True;
EndProcedure // ClearServicesManualChanges

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionCancel(pCommand)
	vCurRow = Items.RoomInterfaces.CurrentRow;
	If vCurRow <> Undefined Then
		If tcOnServer.cmGetAttributeByRef(vCurRow,"DeletionMark") Then
			ShowMessageBox(,NStr("en='Room interface is marked for deletion and could not be used!';ru='Доп. услуга помечена на удаление и не может быть отключена!';de='Zusätzliche Dienstleistung wurde zum Löschen markiert und kann nicht abgeschaltet werden!'"));
		ElsIf tcOnServer.cmGetAttributeByRef(vCurRow,"IsCanceled") Then
			ShowMessageBox(,NStr("en='Room interface is already cancelled!';ru='Доп. услуга уже отключена!';de='Zusätzliche Dienstleistung wurde bereits abgeschaltet!'"));
		ElsIf ValueIsFilled(tcOnServer.cmGetAttributeByRef(vCurRow,"RoomInterfaceType")) And tcOnServer.cmGetAttributeByRef(vCurRow,"RoomInterfaceType.ManualCancelIsForbidden") Then
			vMessage = NStr("en='Manual interface cancellation is forbidden!';ru='Ручное отключение услуги запрещено!';de='Das manuelle Abschalten des Dienstes ist verboten!'");
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(vCurRow,"RoomInterfaceType.RefusalReason")) Then
				vMessage = vMessage + Chars.LF + Chars.LF + tcOnServer.cmNStrAtServer(TrimAll(vCurRow.RoomInterfaceType.RefusalReason));
			EndIf;
			ShowMessageBox(,vMessage);
		Else
			ActionCancelAtServer(vCurRow);
		EndIf;
	EndIf;
EndProcedure // ActionCancel

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionInsert(pCommand)
	OpenForm("Document.RoomInterfaceStatus.ObjectForm", New Structure("Basis", ?(ValueIsFilled(Object.Ref), Object.Ref, Object.Room)), ThisObject, Object.Ref);
EndProcedure // ActionInsert

// -----------------------------------------------------------------------------
&AtClient
Procedure NewTask(Command)
	If ValueIsFilled(Object.Ref) Then
		stParam = New Structure("SetParamObject, Type", Object.Ref, PredefinedValue("Enum.MessageTypes.Task"));
		OpenForm("Document.Message.Form.tcDocumentForm", stParam, ThisObject, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenResourceReservations(pCommand)
	vFrm = GetForm("Document.ResourceReservation.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisObject);
	vFrm.Open();
EndProcedure // OpenResourceReservations

// -----------------------------------------------------------------------------
&AtClient
Procedure AddPhone2(pCommand)
	Items.Fax.Visible = True;
	Items.AddPhone2.Visible = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure InsertServicePackage(pCommand)
	If Not ValueIsFilled(Object.CheckInDate) Or Not ValueIsFilled(Object.CheckOutDate) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Reservation period should be specified!';ru='Период планируемого проживания должен быть указан!';de='Der Zeitraum der geplanten Unterbringung muss angegeben sein!'"));
		Return;
	EndIf;
	// Open package choice form
	OpenForm("Catalog.ServicePackages.ChoiceForm", New Structure("SelPeriodFrom, SelPeriodTo", Object.CheckInDate, Object.CheckOutDate), ThisObject, Object.Ref);
EndProcedure // InsertServicePackage

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearResortFeeExemption(pCommand)
	ClearResortFeeExemptionAtServer();
	// Ask user should we clear exempt from paying the resort fee from other room guests 
	If Not OneGuestMode Then
		ShowQueryBox(New NotifyDescription("ResortFeeExemptAfterQuery", ThisObject), NStr("en='Clear exempt from paying the tourist tax / resort fee from room other guests?'; ru='Отменить освобождение от уплаты туристического налога / курортного сбора у других гостей номера?'; de='Stornieren die Befreiung von der Zahlung einer Kurtax von Zimmer anderen Gäste?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
	EndIf;
	// Form is modified
	ThisObject.Modified = True;
EndProcedure // ClearResortFeeExemption

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearCreditCard(pCommand)
	Object.CreditCard = Undefined;
	CreditCardPresentation = NStr("en='<Credit card>'; ru='<Кредитная карта>'; de='<Kreditkarte>'");
	Items.ClearCreditCard.Visible = False;
	ThisObject.Modified = True;
EndProcedure // ClearCreditCard

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowDirectPostings(pCommand)
	If Object.Ref.IsEmpty() Or ThisObject.Modified Then
		ShowMessageBox(, NStr("ru='Документ должен быть записан!';
		                      |de='Das Dokument muss aufgezeichnet sein!'; 
		                      |en='Please write document first!'"));
		Return;
	EndIf;
	vRoom = Object.Room;
	vClient = Object.Guest;
	#IF NOT MobileClient THEN
		OpenForm("CommonForm.tcDirectPostingsForm", New Structure("Room, Client", vRoom, vClient), , vRoom);
	#ELSE
		OpenForm("CommonForm.mcDirectPostingsForm", New Structure("Room, Client", vRoom, vClient), , vRoom);	
	#ENDIF
EndProcedure // ShowDirectPostings

// -----------------------------------------------------------------------------
&AtClient
Procedure FillGrid(pCommand)
    If Object.ref.IsEmpty() Or ThisObject.Modified Then
        DecorationTotalSumClickAtServer();
	Else
		FillGridAtServer();
    EndIf; 
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutReversal(pCommand)
	CheckOutReversalAtServer();
	Post(Commands.Post);
	If Not (NumberOfAdults = 0 And NumberOfKids > 0) Then
		NumberOfAdults = 1;
		NumberOfKids = 0;
	Else
		NumberOfAdults = 0;
		NumberOfKids = 1;
	EndIf;
	LastNumberOfAdults = NumberOfAdults;
	LastKidsNumber = NumberOfKids;
	DocsList.Clear();
	OnOpenForm(False);
	If ThisObject.ReadOnly Then
		ThisObject.ReadOnly = False;
	EndIf;
	Items.FormPostAndClose.Enabled = True;
	Items.FormPost.Enabled = True;
EndProcedure // CheckOutReversal

// -----------------------------------------------------------------------------
&AtClient
Procedure ExportGuestDataToUFMSRu(pCommand)
	If Object.Ref.IsEmpty() Or ThisObject.Modified Then
		ShowMessageBox(, NStr("ru='Документ должен быть записан!';
		                      |de='Das Dokument muss aufgezeichnet sein!'; 
		                      |en='Please write document first!'"));
		Return;
	EndIf;
	vDPRef = GetDataProcessorForExportGuestDataToUFMS();
	If Not ValueIsFilled(vDPRef) Then
		ShowMessageBox(, NStr("en='Data processor for export is not configured!'; ru='Не настроена обработка экспорта!'; de='Exportverarbeitung nicht konfiguriert!'"));
	Else
		OpenForm("DataProcessor.ExportGuestsToUFMSTerritoryApp.Form.tcDPForm", New Structure("DataProcessor, Accommodation, GenerateOnOpen", vDPRef, Object.Ref, True), , Object.Ref);
	EndIf;
EndProcedure // ExportGuestDataToUFMSRu

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowClosedTasks(pCommand)
	stParam = New Structure("SetParamObject, ShowClosedMessages", Object.Ref, True);
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam, ThisObject, ThisObject.UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure // ShowClosedTasks

// -----------------------------------------------------------------------------
&AtClient
Procedure MoveToNewGroup(pCommand)
	If IsNew Then
		ShowMessageBox(, NStr("en='Save document first!'; ru='Сначала сохраните документ!'; de='Speichern Sie das Dokument zuerst!'"));
		Return;
	EndIf;
	// Ask user to check guests to move to other reservation
	vOneRoomGuests = GetOneRoomGuests(Object.Ref);
	vExtraParams = New Structure("MoveToNewGroup, OneRoomGuests", True, vOneRoomGuests);
	// Check if there are some guests
	If vOneRoomGuests.Count() > 0 Then
		// Build value list with documents
		vGuestsList = New ValueList();
		For Each vOneRoomGuestsItem In vOneRoomGuests Do
			vDocRef = vOneRoomGuestsItem.Value;
			vGuestsList.Add(vOneRoomGuestsItem.Value, tcOnServer.cmGetAttributeByRef(vDocRef, "GuestFullName") + " (" + TrimAll(tcOnServer.cmGetAttributeByRef(vDocRef, "AccommodationType")) + ")", ?(OneGuestMode And vDocRef = Object.Ref, True, False));
		EndDo;
		vGuestsList.ShowCheckItems(New NotifyDescription("AfterGuestsToMoveToNewReservationSelection", ThisObject, vExtraParams), NStr("en='Checkmark guests...'; ru='Отметьте гостей...'; de='Gäste markieren...'"));
	Else
		Return;
	EndIf;
EndProcedure // MoveToNewGroup

// -----------------------------------------------------------------------------
&AtClient
Procedure MoveToNewReservation(pCommand)
	If IsNew Then
		ShowMessageBox(, NStr("en='Save document first!'; ru='Сначала сохраните документ!'; de='Speichern Sie das Dokument zuerst!'"));
		Return;
	EndIf;
	// Ask user to check guests to move to other reservation
	vOneRoomGuests = GetOneRoomGuests(Object.Ref);
	vExtraParams = New Structure("MoveToNewGroup, OneRoomGuests", False, vOneRoomGuests);
	// Check if there are some guests
	If vOneRoomGuests.Count() > 0 Then
		// Build value list with documents
		vGuestsList = New ValueList();
		For Each vOneRoomGuestsItem In vOneRoomGuests Do
			vDocRef = vOneRoomGuestsItem.Value;
			vGuestsList.Add(vOneRoomGuestsItem.Value, tcOnServer.cmGetAttributeByRef(vDocRef, "GuestFullName") + " (" + TrimAll(tcOnServer.cmGetAttributeByRef(vDocRef, "AccommodationType")) + ")", ?(OneGuestMode And vDocRef = Object.Ref, True, False));
		EndDo;
		vGuestsList.ShowCheckItems(New NotifyDescription("AfterGuestsToMoveToNewReservationSelection", ThisObject, vExtraParams), NStr("en='Checkmark guests...'; ru='Отметьте гостей...'; de='Gäste markieren...'"));
	Else
		Return;
	EndIf;
EndProcedure // MoveToNewReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure EditGroupChargingRules(pCommand)
	If ValueIsFilled(Object.GuestGroup) Then
		OpenForm("Catalog.GuestGroups.ObjectForm", New Structure("Key, ShowChargingRules", Object.GuestGroup, True), ThisObject, Object.GuestGroup);
	EndIf;
EndProcedure // EditGroupChargingRules

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyTransferRulesToOtherRoomGuests(pCommand)
	If IsNew Then
		ShowMessageBox(, NStr("en='Save document first!'; ru='Сначала сохраните документ!'; de='Speichern Sie das Dokument zuerst!'"));
		Return;
	EndIf;
	// Get transfer rules
	vTranferRules = Object.ChargingRules.FindRows(New Structure("IsTransfer", True));
	If vTranferRules.Count() > 0 Then
		// Convert array of form data collection items to array of structures
		vTranferRulesArray = New Array();
		For Each vTranferRulesRow In vTranferRules Do
			vTranferRulesStruct = New Structure("ChargingRule, ChargingRuleValue, ChargingFolio, ValidFromDate, ValidToDate, Owner, IsMaster, IsPersonal, IsTransfer");
			FillPropertyValues(vTranferRulesStruct, vTranferRulesRow);
			vTranferRulesArray.Add(vTranferRulesStruct);
		EndDo;
		// Get one room guests
		vOneRoomGuests = GetOneRoomGuests(Object.Ref);
		// Remove current document
		i = 0;
		While i < vOneRoomGuests.Count() Do
			vOneRoomGuestsItem = vOneRoomGuests.Get(i);
			If vOneRoomGuestsItem.Value = Object.Ref Then
				vOneRoomGuests.Delete(i);
				Break;
			Else
				i = i + 1;
			EndIf;
		EndDo;
		// Check if there are some guests
		If vOneRoomGuests.Count() > 0 Then
			// Build value list with documents
			vGuestsList = New ValueList();
			For Each vOneRoomGuestsItem In vOneRoomGuests Do
				vDocRef = vOneRoomGuestsItem.Value;
				vGuestsList.Add(vOneRoomGuestsItem.Value, tcOnServer.cmGetAttributeByRef(vDocRef, "GuestFullName") + " (" + TrimAll(tcOnServer.cmGetAttributeByRef(vDocRef, "AccommodationType")) + ")", False);
			EndDo;
			vGuestsList.ShowCheckItems(New NotifyDescription("AfterGuestsToCopyTransferRulesSelection", ThisObject, vTranferRulesArray), NStr("en='Checkmark guests...'; ru='Отметьте гостей...'; de='Gäste markieren...'"));
		Else
			ShowMessageBox(, NStr("en='There are no sharers in the room!'; ru='В номере нет других гостей этой брони!'; de='Es gibt keine Mitspieler im Zimmer!'"));
			Return;
		EndIf;
	Else
		ShowMessageBox(, NStr("en='There are no redirects in the rules!'; ru='В правилах нет перенаправлений!'; de='Es gibt keine Weiterleitungen in den Regeln!'"));
		Return;
	EndIf;
EndProcedure // CopyTransferRulesToOtherRoomGuests

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyPackagesToOtherRoomGuests(pCommand)
	If IsNew Then
		ShowMessageBox(, NStr("en='Save document first!'; ru='Сначала сохраните документ!'; de='Speichern Sie das Dokument zuerst!'"));
	Else
		// Save this document first
		If ThisObject.Modified Then
			Post(Commands["Post"]);
		EndIf;
		// Ask if we need to replace service packages to the packages selected or add to existing list
		ShowQueryBox(New NotifyDescription("AfterReplaceServicePackagesSelection", ThisObject, Undefined), 
		             NStr("en='Do you want to clear existing packages from the guests that will be selected?'; ru='Хотите удалить существующие пакеты у гостей, которые будут выбраны?'; de='Möchten Sie vorhandene Pakete von den ausgewählten Gästen löschen?'"), 
					 QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
	EndIf;
EndProcedure // CopyPackagesToOtherRoomGuests

// -----------------------------------------------------------------------------
&AtClient
Procedure FillReservation(pCommand)
	If Object.Ref.IsEmpty() Or ThisObject.Modified Then
		ShowMessageBox(, NStr("ru='Документ должен быть записан!';
		                      |de='Das Dokument muss aufgezeichnet sein!'; 
		                      |en='Please write document first!'"));
		Return;
	EndIf;
	// Open new reservation form. Reservation will be based on this accommodation
	If Not OneGuestMode Then
		vDocsList = New ValueList();
		vDocsList.Add(New Structure("AccommodationTemplate, AccommodationType, Amount, GuestName, GuestRef, DateOfBirth, GuestAge, Phone, Email, HotelProduct, LegalRepresentative, RelationType, ParentDoc", 
		                             Object.AccommodationTemplate, Object.AccommodationType, Undefined, Object.GuestFullName, Object.Guest, Undefined, Object.GuestAge, Object.Phone, Object.EMail, Object.HotelProduct, Object.LegalRepresentative, Object.RelationType, Object.Ref), Object.SortCode);
		For Each vGuestsInGroupRow In GuestsInGroup Do
			If ValueIsFilled(vGuestsInGroupRow.Ref) Then
				vRef = vGuestsInGroupRow.Ref;
				vRefAttrs = tcOnServer.cmGetAtributeAsArray(vRef);
				vDocsList.Add(New Structure("AccommodationTemplate, AccommodationType, Amount, GuestName, GuestRef, DateOfBirth, GuestAge, Phone, Email, HotelProduct, LegalRepresentative, RelationType, ParentDoc", 
				                             vRefAttrs.AccommodationTemplate, vRefAttrs.AccommodationType, Undefined, vRefAttrs.GuestFullName, vRefAttrs.Guest, Undefined, vRefAttrs.GuestAge, vRefAttrs.Phone, vRefAttrs.EMail, vRefAttrs.HotelProduct, vRefAttrs.LegalRepresentative, vRefAttrs.RelationType, vRef), vRefAttrs.SortCode);
			EndIf;
		EndDo;
		vParams = New Structure("Basis, DocsList", Object.Ref, vDocsList);
	Else
		vParams = New Structure("Basis", Object.Ref);
	EndIf;
	OpenForm("Document.Reservation.ObjectForm", vParams, ThisObject, Object.Ref);
EndProcedure // FillReservation

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesCopy(pCommand)
	vCopyValueButton = Items.ServicesCopy;
	vPasteValueButton = Items.ServicesPaste;
	amClipboard.Delete("RateServicesServices");
	If vCopyValueButton.Check Then 
		ColumnCopied = Undefined;
		ValueCopied = Undefined;
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("RateServicesServicesCancelCopyRows", Undefined, ThisObject);
	Else
		vCurRow = Items.Services.CurrentRow;
		If vCurRow <> Undefined Then
			vSelectedRows = Items.Services.SelectedRows;
			If vSelectedRows.Count() > 1 Then
				vUM = New UserMessage();
				vUM.Text = NStr("en='You can copy only one area from the one row!';ru='Можете копировать только одно поле из одной строки';de='Sie können nur einen Bereich aus einer Zeile kopieren!'");
				vUM.Field = "Object.Services[" + vCurRow+ "].LineNumber";
				vUM.Message();				
			Else
				ColumnCopied = StrReplace(Items.Services.CurrentItem.Name, "Services", "");
				ColumnCopiedService = Items.Services.CurrentData.Service;
				If ColumnCopied = "Service" Then
					vUM = New UserMessage();
					vUM.Text = NStr("en='You can`t copy values from the ""Service"" column!';ru='Не можете копировать значения из колонки ""Услуга""!';de='Sie können keine Werte aus der Spalte ""Dienstleistung"" kopieren!'");
					vUM.Field = "Object.Services[" + vCurRow +"].Service";
					vUM.Message();
					Return;
				EndIf;
				ValueCopied = Items.Services.CurrentData[ColumnCopied];
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste ';ru='Вставить ';de='Einsetzen '") + TrimAll(ValueCopied);
			EndIf;
		Else
			ShowMessageBox(, NStr("en='Row is not selected!';ru='Не выбрана строка!';de='Keine Zeile ist gewählt!'"));
			ColumnCopied = Undefined;
			ValueCopied = Undefined;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		EndIf;
	EndIf;
EndProcedure // ServicesCopy

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesPaste(pCommand)
	vCopyValueButton = Items.ServicesCopy;
	vPasteValueButton = Items.ServicesPaste;
	
	vSelectedRows = Undefined;
	
	If amClipboard.Property("RateServicesServices") Then
		UploadTable(amClipboard.RateServicesServices);
		amClipboard.Delete("RateServicesServices");
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("RateServicesServicesCancelCopyRows", Undefined, ThisObject);
	Else
		vSelectedRows = Items.Services.SelectedRows;
		If vSelectedRows.Count() > 0 Then
			vDeniedRowsCounter = 0;
			vLastDeniedRow = 0;
			For Each vSelectedRowID In vSelectedRows Do
				vServicesRow = Object.Services.FindByID(vSelectedRowID);
				If vServicesRow[ColumnCopied] <> ValueCopied Then
					If ColumnCopied = "CalendarDayType" OR ColumnCopied = "PriceTag" Then
						vServicesRow[ColumnCopied] = ValueCopied;
						vServicesRowsPerDayArray = Object.Services.FindRows(New Structure("AccountingDate, IsManual", vServicesRow["AccountingDate"], False));
						For Each vServicesRowPerDay In vServicesRowsPerDayArray Do
							vServicesRowPerDay[ColumnCopied] = ValueCopied;
						EndDo;
					ElsIf StrFind("Price, Quantity, Sum", ColumnCopied) > 0 Then 
						If vServicesRow.Service = ColumnCopiedService Then
							vServicesRow[ColumnCopied] = ValueCopied;							
							vServicesRowsPerDayArray = Object.Services.FindRows(New Structure("AccountingDate, Service, IsManual", vServicesRow["AccountingDate"], vServicesRow["Service"], False));
							For Each vServicesRowPerDay In vServicesRowsPerDayArray Do
								vServicesRowPerDay[ColumnCopied] = ValueCopied;
								PastedColumnOnChange(ColumnCopied, vServicesRowPerDay.GetID());
							EndDo;
							PastedColumnOnChange(ColumnCopied, vSelectedRowID);
						Else
							vDeniedRowsCounter = vDeniedRowsCounter + 1;
							vLastDeniedRow = vSelectedRowID;
						EndIf;
					ElsIf StrFind("Discount, DiscountSum, AgentCommission, CommissionSum, TimeFrom", ColumnCopied) > 0 Then 
						vServicesRow[ColumnCopied] = ValueCopied;
						PastedColumnOnChange(ColumnCopied, vSelectedRowID);
					Else  
						vServicesRow[ColumnCopied] = ValueCopied;
						If Not vServicesRow.IsManual Then
							vServicesRow.IsManualPrice = True;	
						EndIf;
					EndIf;
				EndIf; 
			EndDo; 
			If (vDeniedRowsCounter > 0 OR vDeniedRowsCounter = vSelectedRows.Count()) Then
				vUM = New UserMessage();
				vUM.Text = StrTemplate(NStr("en='The value %1 will be inserted only in the lines with the service %2. Lines with other services will not be changed';ru='Значение %1 будет вставлено только в строки с услугой %2. Строки с другими услугами изменены не будут';de='Der Wert %1 wird nur in die Zeilen mit dem Dienst %2 eingefügt. Zeilen mit anderen Diensten werden nicht geändert'"), ValueCopied, ColumnCopiedService); 
				vUM.Field = "Object.Services[" + vLastDeniedRow + "].Service";
				vUM.Message();
			EndIf;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
			// Calculate totals
			TotalSum = CalculateTotalServices();
		Else
			ShowMessageBox(, NStr("en='There is no selected rows!';ru='Нет выделенных строк!';de='Es gibt keine markierten Zeilen!'"));
		EndIf;
	EndIf;
EndProcedure // ServicesPaste

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedChargesCopy(pCommand)
	vCopyValueButton = Items.FixedChargesCopy;
	vPasteValueButton = Items.FixedChargesPaste;
	amClipboard.Delete("FixedChargesServices");
	If vCopyValueButton.Check Then  
		ColumnCopiedFixedCharges = Undefined;
		ValueCopiedFixedCharges = Undefined;    
		vCopyValueButton.Check = False; 
		vPasteValueButton.Enabled = False; 
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("FixedChargesServicesCancelCopyRows", Undefined, ThisObject);
	Else
		vCurRow = Items.FixedCharges.CurrentRow;
		If vCurRow <> Undefined Then  
			vSelectedRows = Items.FixedCharges.SelectedRows;   
			If vSelectedRows.Count() > 1 Then	
				ColumnCopiedFixedCharges = "SelectedRows";  
				ValueCopiedFixedCharges = GetRows(vSelectedRows);
				amClipboard.Insert("FixedChargesServices", ValueCopiedFixedCharges);
				vCopyValueButton.Check = True;   
				vPasteValueButton.Enabled = True; 
				vPasteValueButton.Title = NStr("en='Paste selected rows';ru='Вставить выб. строки';de='Gewählte Zeilen einsetzen'");
				Notify("FixedChargesServicesCopyRows", ValueCopiedFixedCharges, ThisObject);				
			Else
				ColumnCopiedFixedCharges = StrReplace(Items.FixedCharges.CurrentItem.Name, "FixedCharges", ""); 
				ValueCopiedFixedCharges = Items.FixedCharges.CurrentData[ColumnCopiedFixedCharges]; 
				vCopyValueButton.Check = True;
				vPasteValueButton.Enabled = True;
				vPasteValueButton.Title = NStr("en='Paste ';ru='Вставить ';de='Einsetzen '") + TrimAll(ValueCopiedFixedCharges);
			EndIf;
		Else
			ShowMessageBox(, NStr("en='Row is not selected!';ru='Не выбрана строка!';de='Keine Zeile ist gewählt!'"));
			ColumnCopiedFixedCharges = Undefined;
			ValueCopiedFixedCharges = Undefined;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		EndIf;
	EndIf;
EndProcedure // FixedChargesCopy

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedChargesPaste(pCommand)
	vCopyValueButton = Items.FixedChargesCopy;
	vPasteValueButton = Items.FixedChargesPaste;
	
	vSelectedRows = Undefined;
	
	If amClipboard.Property("FixedChargesServices") Then
		UploadTable(amClipboard.FixedChargesServices);
		amClipboard.Delete("FixedChargesServices");
		vCopyValueButton.Check = False;
		vPasteValueButton.Enabled = False;
		vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
		Notify("FixedChargesServicesCancelCopyRows", Undefined, ThisObject);
	Else
		vSelectedRows = Items.FixedCharges.SelectedRows;
		If vSelectedRows.Count() > 0 Then
			For Each vSelectedRowID In vSelectedRows Do
				Object.Services.FindByID(vSelectedRowID)[ColumnCopiedFixedCharges] = ValueCopiedFixedCharges;
				If StrFind("Price, Quantity, Sum, Discount, DiscountSum, AgentCommission, CommissionSum", ColumnCopiedFixedCharges) > 0 Then
					PastedColumnOnChange(ColumnCopiedFixedCharges, vSelectedRowID);
				EndIf;
			EndDo;
			vCopyValueButton.Check = False;
			vPasteValueButton.Enabled = False;
			vPasteValueButton.Title = NStr("en='Paste';ru='Вставить';de='Einsetzen'");
			TotalSum = CalculateTotalServices();
		Else
			ShowMessageBox(, NStr("en='There is no selected rows!';ru='Нет выделенных строк!';de='Es gibt keine markierten Zeilen!'"));
		EndIf;
	EndIf;
EndProcedure // FixedChargesPaste

// -----------------------------------------------------------------------------
&AtClient
Procedure AddEmail2(pCommand)
	Items.EMail2.Visible = True;
	Items.AddEmail2.Visible = False;
EndProcedure

// ----------------------------------------------------------------------------
&AtClient
Procedure FixTransactionPlanPrices(pCommand)
	vServicesList = GetTransactionPlanServicesList();  
	vQ = NStr("en = 'Select services to fix prices'; 
			  |de = 'Markieren Sie die Dienste, bei denen die Preise festgelegt werden sollen'; 
			  |ru = 'Отметьте услуги, у которых нужно зафиксировать цены'");
	vServicesList.ShowCheckItems(New NotifyDescription("TransactionPlanServicesChoiceCompleted", ThisObject), vQ);
EndProcedure // FixTransactionPlanPrices

// ----------------------------------------------------------------------------
&AtClient
Procedure CreateGroupInvoice(pCommand)
	If (WasPosted = False Or Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "CreateGroupInvoice"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		#If Not WebClient And Not MobileClient Then
			Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 10, NStr("en='Opening...';ru='Открытие формы...';de='Öffnen des Formulars...'"), PictureLib.LongOperation); 
		#EndIf
		vWarning = "";
		vAddRoomsToAllotment = False;
		vAllotmentBalances = Undefined;
		vResult = WriteAtServer(, vWarning, , , vAddRoomsToAllotment, vAllotmentBalances);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.UserMessage(vWarning);
		EndIf;
		vBreakProcessing = False;
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				ShowMessageBox(Undefined,NStr(vResult));
			EndIf;
			vBreakProcessing = True;
		Else
			If Not FunctionsAndPrintFormsWereLoaded Then
				vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
				AfterWriteAtServer(Undefined, vWriteParameters);
			EndIf;
			If IsNew Then
				IsNew = False;
			EndIf;
		EndIf;
	 	If vAddRoomsToAllotment Then
			ShowQueryBox(New NotifyDescription("AddRoomsToAllotment", ThisObject, New Structure("AllotmentBalances", vAllotmentBalances)), 
						 NStr("en='Add missing rooms to the allotment?'; ru='Добавить недостающие номера в квоту?'; de='Fehlende Zimmer zum Allotment hinzufügen?'"), 
						 QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
		If vBreakProcessing Then
			Return;
		EndIf;
		#If Not WebClient And Not MobileClient Then
			Status(NStr("en='Wait...';ru='Подождите...';de='Bitte warten...'"), 90, NStr("en='Opening...';ru='Открытие формы...';de='Öffnen des Formulars...'"), PictureLib.LongOperation); 
		#EndIf
	EndIf;
	
	OpenForm("CommonForm.tcNewInvoiceForm", New Structure("ParentDoc", Object.Ref));

EndProcedure // CreateGroupInvoice

#EndRegion

#Region Private

// -------------------------------------------------------------------------
&AtClient
Procedure Attachable_ShowMessages() Export
	If IsInputAvailable() And Not IsBlankString(WaitMessageBox) Then	
		ShowMessageBox(, WaitMessageBox);	
		WaitMessageBox = "";
	Else      
		If Not IsBlankString(WaitMessageBox) Then
			AttachIdleHandler("Attachable_ShowMessages", 1, True);	
		EndIf;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function RollBackMainDocumentToTheLastPostedState(pRefs)
	vCancel = False;
	Try
		BeginTransaction(DataLockControlMode.Managed);
		For Each vRef In pRefs Do
			vObj = vRef.GetObject();
			vLastState = vObj.pmGetLastDocumentState();
			vRChgRec = InformationRegisters.AccommodationChangeHistory.Get(vLastState.Period, New Structure("Accommodation", vRef));
			vObj.pmRestoreAttributesFromHistory(vRChgRec);
			vObj.Write(DocumentWriteMode.Posting);
		EndDo;
		CommitTransaction();
	Except
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		vCancel = True;
	EndTry;
	Return vCancel;
EndFunction // RollBackMainDocumentToTheLastPostedState

// ----------------------------------------------------------------------------
&AtClient
Procedure TransactionPlanServicesChoiceCompleted(pServicesList, pExtraParams) Export
	If pServicesList <> Undefined Then
		For Each vSrvRow In Object.Services Do
			If Not vSrvRow.IsManual And Not vSrvRow.IsManualPrice Then
				vServiceItem = pServicesList.FindByValue(vSrvRow.Service);
				If vServiceItem <> Undefined And vServiceItem.Check Then
					vSrvRow.IsManualPrice = True;
					If Not Modified Then
						Modified = True;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // TransactionPlanServicesChoiceCompleted

// ----------------------------------------------------------------------------
&AtServer
Function GetTransactionPlanServicesList()
	vServicesList = New ValueList();
	vServices = Object.Services.Unload(Object.Services.FindRows(New Structure("IsManual", False)));
	vServices.GroupBy("Service", );
	For Each vServicesRow In vServices Do
		If ValueIsFilled(vServicesRow.Service) And Not vServicesRow.Service.IsResortFee Then
			vServicesList.Add(vServicesRow.Service, , True);
		EndIf;
	EndDo;
	Return vServicesList;
EndFunction // GetTransactionPlanServicesList

// -----------------------------------------------------------------------------
&AtServer
Procedure DoFormReadOnly()
	ThisObject.ReadOnly = True;
	Items.ServicePackages.ReadOnly = True;
	Items.IsManualRoomPrice.ReadOnly = True;
	Items.RoomPropertiesPresentation.ReadOnly = True;
	Items.NumberOfAdults.ReadOnly = True;
	Items.NumberOfKids.ReadOnly = True;
	Items.KidAge1.ReadOnly = True;
	Items.KidAge2.ReadOnly = True;
	Items.KidAge3.ReadOnly = True;
	Items.KidAge4.ReadOnly = True;
	Items.Guest1Group.ReadOnly = True;
	Items.Guest2Group.ReadOnly = True;
	Items.Guest3Group.ReadOnly = True;
	Items.Guest4Group.ReadOnly = True;
	Items.Guest5Group.ReadOnly = True;
	Items.IsForFolioSplit.ReadOnly = True;
	Items.CreditCardPresentation.ReadOnly = True;
	Items.CreditCardPresentation.Hyperlink = False;
	Items.GroupRoomType.ReadOnly = True;
	Items.GroupCustomFields.ReadOnly = True;
	Items.FormPostAndClose.Enabled = False;
	Items.FormPost.Enabled = False;
EndProcedure // DoFormReadOnly

// -----------------------------------------------------------------------------
&AtServer
Function GetOneRoomGuests(pRef)
	If TypeOf(pRef) = Type("DocumentRef.Accommodation") Then
		// Fill one room guests
		vQry = New Query;
		vQry.Text = "SELECT
		|	Accommodation.Ref AS Ref,
		|	Accommodation.CheckInDate AS CheckInDate,
		|	Accommodation.CheckOutDate AS CheckOutDate,
		|	Accommodation.Guest AS GuestRef,
		|	Accommodation.Guest.FullName AS Guest,
		|	Accommodation.AccommodationType AS AccommodationType,
		|	Accommodation.SharePercent AS SharePercent,
		|	FALSE AS IsStatusChanged,
		|	FALSE AS IsAnnulation,
		|	TRUE AS IsGuest,
		|	FALSE AS IsNoResortFee,
		|	&qEmptyReservationStatusRef AS ReservationStatus
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	Accommodation.GuestGroup = &qGroup
		|	AND Accommodation.Number = &qNumber
		|	AND Accommodation.Posted
		|	AND NOT Accommodation.DeletionMark
		|	AND ((Accommodation.AccommodationStatus.IsActive
		|			AND Accommodation.AccommodationStatus.IsInHouse)
		|		OR	(Accommodation.AccommodationStatus = &qAccommodationStatus))
		|ORDER BY
		|	Accommodation.AccommodationType.SortCode";
		vQry.SetParameter("qGroup", pRef.GuestGroup);
		vQry.SetParameter("qAccommodationStatus", pRef.AccommodationStatus);
		vQry.SetParameter("qNumber", pRef.Number);
		vQry.SetParameter("qEmptyReservationStatusRef", Catalogs.ReservationStatuses.EmptyRef());
		vQryResult = vQry.Execute().Unload();
		vSelAccList = New ValueList;
		For Each vRow In vQryResult Do
			vSelAccList.Add(vRow.Ref, cmBuildAccommodationSortingPresentation(vRow.Ref));
		EndDo;
		Return vSelAccList;
	Else
		// Fill one room guests
		vQry = New Query;
		vQry.Text = "SELECT
		            |	Reservation.Ref AS Ref,
		            |	Reservation.CheckInDate AS CheckInDate,
		            |	Reservation.CheckOutDate AS CheckOutDate,
		            |	Reservation.Guest AS GuestRef,
		            |	Reservation.Guest.FullName AS Guest,
		            |	Reservation.AccommodationType AS AccommodationType,
					|	Reservation.SharePercent AS SharePercent,
		            |	FALSE AS IsStatusChanged,
		            |	FALSE AS IsAnnulation,
		            |	TRUE AS IsGuest,
		            |	FALSE AS IsNoResortFee,
		            |	&qEmptyReservationStatusRef AS ReservationStatus
		            |FROM
		            |	Document.Reservation AS Reservation
		            |WHERE
		            |	Reservation.GuestGroup = &qGroup
		            |	AND Reservation.Number = &qNumber
					|	AND Reservation.Posted
		            |	AND NOT Reservation.DeletionMark
		            |	AND (Reservation.ReservationStatus.IsActive
		            |			OR Reservation.ReservationStatus.IsPreliminary
		            |			OR Reservation.ReservationStatus.IsInWaitingList
		            |			OR Reservation.ReservationStatus = &qReservStatus)
		            |
		            |ORDER BY
		            |	Reservation.AccommodationType.SortCode";
		vQry.SetParameter("qGroup", pRef.GuestGroup);
		vQry.SetParameter("qReservStatus", pRef.ReservationStatus);
		vQry.SetParameter("qNumber", pRef.Number);
		vQry.SetParameter("qEmptyReservationStatusRef", Catalogs.ReservationStatuses.EmptyRef());
		vQryResult = vQry.Execute().Unload();
		vSelResList = New ValueList;
		For Each vRow In vQryResult Do
			vSelResList.Add(vRow.Ref, cmBuildAccommodationSortingPresentation(vRow.Ref));
		EndDo;
		Return vSelResList;
	EndIf;
EndFunction // GetOneRoomGuests

// -----------------------------------------------------------------------------
&AtServer
Procedure ManualPriceAppearance(pObj = Undefined, pRecalculateServices = False)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Manual prices
	IsManualRoomPrice = 0;
	RoomPrice = 0;
	Items.RoomPrice.Visible = False;
	Items.RoomTypeUpgrade.Visible = False;
	If vObj.Prices.Count() > 0 Then
		IsManualRoomPrice = 1;
		If OneGuestMode Then
			IsManualRoomPrice = 3;
		EndIf;
		If GuestsInGroup.Count() > 0 Then
			vNextGuest = GuestsInGroup.Get(0).Ref;
			If Not ValueIsFilled(vNextGuest) Then
				If GuestsToCheckInList.Count() > 1 Then
					vNextGuest = GuestsToCheckInList.Get(1).Value;
				EndIf;
			EndIf;				
			If ValueIsFilled(vNextGuest) Then
				If vNextGuest.Prices.Count() > 0 Then
					For Each vMPriceRow In vNextGuest.Prices Do
						vMPriceRowService = vMPriceRow.Service;
						If ValueIsFilled(vMPriceRowService) And vMPriceRowService.IsRoomRevenue And vMPriceRowService.IsInPrice And Not vMPriceRowService.RoomRevenueAmountsOnly Then
							If vMPriceRow.Price > 0 Then
								IsManualRoomPrice = 3;
								Break;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
		RoomPrice = vObj.Prices[0].Price;
		Items.RoomPrice.Visible = True;
		Items.RoomTypeUpgrade.Visible = False;
	ElsIf ValueIsFilled(vObj.RoomTypeUpgrade) Then
		IsManualRoomPrice = 2;
		Items.RoomPrice.Visible = False;
		Items.RoomTypeUpgrade.Visible = True;
	EndIf;
	// Manual services prices
	ManualServicesPriceAppearance(vObj);
	// Recalculate services
	If pRecalculateServices Then
		// Calculate totals
		TotalSum = CalculateTotalServices(vObj, , False, False);
	EndIf;
	// Save object back to form
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
EndProcedure // ManualPriceAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure ManualServicesPriceAppearance(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	
	vMainServicesTitle = NStr("en='Guest transactions plan'; ru='План транзакций гостя'; de='Gasttransaktionsplan'");
	vManualPricesCount = "";
	vManualPrices = vObj.Services.FindRows(New Structure("IsManualPrice", True));
	If vManualPrices.Count() > 0 Then
		vManualPricesCount = " (" + vManualPrices.Count() + ")";
	EndIf;
	Items.ServicesGroup.Title = vMainServicesTitle + vManualPricesCount;
	
	vFixedChargesTitle = NStr("en='Fixed charges'; ru='Ручные начисления'; de='Manuelle Gebühren'");
	vFixedChargesCount = "";
	vFixedCharges = vObj.Services.FindRows(New Structure("IsManual", True));
	If vFixedCharges.Count() > 0 Then
		vFixedChargesCount = " (" + vFixedCharges.Count() + ")";
	EndIf;
	Items.FixedChargesGroup.Title = vFixedChargesTitle + vFixedChargesCount;
	
	If pObj = Undefined Then
		TotalSum = CalculateTotalServices(, , False, False);
	EndIf;
EndProcedure // ManualServicesPriceAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenForm(pIsOnOpenMode = True)
	If IsOnCloseForm Then
		Return;
	EndIf;
	
	IsOnOpenForm = True;
	
	If ThisObject.ReadOnly Then
		DoFormReadOnly();
	EndIf;
	
	// Get object value
	vObj = FormAttributeToValue("Object");
	
	// Check guest value
	If ValueIsFilled(vObj.Guest) Then
		SelGuest1 = vObj.Guest.FullName;
		Items.SelGuest1.TextEdit = False;
	EndIf;
	
	// Get one room accommodations
	If OneGuestMode Then
		vAddOtherOneRoomGuests = False;
		Items.AdultsGroup.Visible = False;
		Items.TabulationAdultsAndKids.Visible = False;
		Items.KidsCalculateGroup.Visible = False;
	Else
		vAddOtherOneRoomGuests = True;
	EndIf;
	vAccommodationsArray = New Array;
	If Not vObj.IsNew() And vAddOtherOneRoomGuests Then
		WasPosted = True;
		IsNew = False;
		// Fill one room guests
		vQry = New Query;
		vQry.Text = "SELECT
		            |	Accommodation.Ref AS Ref,
		            |	Accommodation.Guest AS GuestRef,
		            |	Accommodation.Guest.FullName AS Guest,
		            |	Accommodation.AccommodationType AS AccommodationType,
		            |	Accommodation.SharePercent AS SharePercent,
		            |	Accommodation.HotelProduct AS HotelProduct,
		            |	FALSE AS IsStatusChanged,
		            |	FALSE AS IsAnnulation,
		            |	TRUE AS IsGuest,
		            |	FALSE AS IsNoResortFee,
		            |	&qEmptyAccommodationStatusRef AS AccommodationStatus,
		            |	Accommodation.Guest.FullName AS LastGuestFullName,
		            |	Accommodation.GuestCitizenship AS GuestCitizenship,
		            |	CASE
		            |		WHEN ISNULL(Accommodation.Guest.Age, 0) <> 0
		            |			THEN Accommodation.Guest.Age
		            |		ELSE Accommodation.GuestAge
		            |	END AS GuestAge,
		            |	FALSE AS RoomRateIsDifferent,
		            |	FALSE AS DiscountsAreDifferent,
		            |	FALSE AS ManualPricesAreDifferent,
		            |	FALSE AS ServicePackagesAreDifferent,
		            |	FALSE AS RoomRatesAreDifferent,
		            |	FALSE AS CheckInDateIsDifferent,
		            |	FALSE AS CheckOutDateIsDifferent,
		            |	FALSE AS ClientTypeIsDifferent,
		            |	FALSE AS BoardPlaceIsDifferent,
		            |	FALSE AS IsForFolioSplitIsDifferent,
		            |	&qEmptyString AS ChangesDescription,
		            |	Accommodation.LegalRepresentative AS LegalRepresentative,
		            |	Accommodation.RelationType AS RelationType,
					|	FALSE AS PriceCalculationDateShouldBeUpdated,
					|	Accommodation.IsForFolioSplit AS pIsForFolioSplit
		            |FROM
		            |	Document.Accommodation AS Accommodation
		            |WHERE
		            |	Accommodation.GuestGroup = &qGroup
		            |	AND Accommodation.Number = &qNumber
		            |	AND Accommodation.Ref <> &qAccRef
		            |	AND Accommodation.Posted
		            |	AND (Accommodation.AccommodationStatus.IsActive
		            |			OR Accommodation.AccommodationStatus = &qAccStatus)
		            |	AND Accommodation.CheckOutDate > &qAccCheckIn
		            |	AND Accommodation.CheckInDate < &qAccCheckOut
		            |
		            |ORDER BY
		            |	Accommodation.AccommodationType.SortCode";
		vQry.SetParameter("qGroup", vObj.GuestGroup);
		vQry.SetParameter("qAccRef", vObj.Ref);
		vQry.SetParameter("qAccCheckIn", vObj.CheckInDate);
		vQry.SetParameter("qAccCheckOut", vObj.CheckOutDate);
		vQry.SetParameter("qAccStatus", vObj.AccommodationStatus);
		vQry.SetParameter("qNumber", vObj.Number);
		vQry.SetParameter("qEmptyAccommodationStatusRef", Catalogs.AccommodationStatuses.EmptyRef());
		vQry.SetParameter("qEmptyString", "");
		vQryResult = vQry.Execute().Unload();
		
		vAccommodationsArray = vQryResult.UnloadColumn("Ref");
		vAccommodationsArray.Insert(0, vObj.Ref);
		
		ValueToFormAttribute(vQryResult, "GuestsInGroup");
		
		// Check template number of guests
		If GuestsInGroup.Count() = 0 And ValueIsFilled(vObj.AccommodationTemplate) And pIsOnOpenMode Then
			vObjAccommodationTemplate = vObj.AccommodationTemplate;
			If NumberOfAdults <> vObjAccommodationTemplate.NumberOfAdults Then
				NumberOfAdults = vObjAccommodationTemplate.NumberOfAdults;
			EndIf;
			If NumberOfKids <> (vObjAccommodationTemplate.NumberOfTeenagers + vObjAccommodationTemplate.NumberOfChildren + vObjAccommodationTemplate.NumberOfInfants) Then
				NumberOfKids = (vObjAccommodationTemplate.NumberOfTeenagers + vObjAccommodationTemplate.NumberOfChildren + vObjAccommodationTemplate.NumberOfInfants);
			EndIf;
			If NumberOfKids > 0 Then
				vKidAge = 0;
				If vObj.GuestAge <> 0 Then
					vKidAge = vObj.GuestAge;
				ElsIf ValueIsFilled(vObj.Guest) Then
					vGuest = vObj.Guest;
					If ValueIsFilled(vGuest.DateOfBirth) Then
						vKidAge = GetClientAge(vGuest, vObj.CheckInDate);
					EndIf;
				EndIf;
				If vKidAge = 0 Then
					vAccType = vObj.AccommodationType;
					If vAccType.AllowedClientAgeTo <> 0 Then
						vKidAge = vAccType.AllowedClientAgeTo - 1;
					EndIf;
				EndIf;
				Try
					ThisObject["KidAge1"] = vKidAge;
				Except
				EndTry;
			EndIf;
		EndIf;
		
		vGuestsList = New ValueTable();
		vGuestsList.Columns.Add("Guest", cmGetCatalogTypeDescription("Clients"));
		vGuestsList.Columns.Add("GuestAge", cmGetNumberTypeDescription(3, 0, True));
		For Each vGiGRow In GuestsInGroup Do
			// Check if guests have differences from main room guest
			vGuestDocRef = vGiGRow.Ref;
			If vGuestDocRef = vObj.Ref Then
				Continue;
			EndIf;
			If vGuestDocRef.CheckInDate <> vObj.CheckInDate Then
				vGiGRow.CheckInDateIsDifferent = True;
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Check-in: '; ru='Заезд: '; de='Anreise: '") + Format(vGuestDocRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'");
			EndIf;
			If vGuestDocRef.CheckOutDate <> vObj.CheckOutDate Then
				vGiGRow.CheckOutDateIsDifferent = True;
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Check-out: '; ru='Выезд: '; de='Abreise: '") + Format(vGuestDocRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
			EndIf;
			If vGuestDocRef.IsForFolioSplit <> vObj.IsForFolioSplit Then
				vGiGRow.IsForFolioSplitIsDifferent = True;
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + ?(vGuestDocRef.IsForFolioSplit, NStr("en='Do folio split'; ru='Раздельные счета'; de='Do Folio Split'"), "");
			EndIf;
			If vGuestDocRef.RoomRate <> vObj.RoomRate Then
				vGiGRow.RoomRateIsDifferent = True;
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Room rate: '; ru='Тариф: '; de='Tariff: '") + TrimAll(vGuestDocRef.RoomRate);
			EndIf;
			If vGuestDocRef.ClientType <> vObj.ClientType Then
				vGiGRow.ClientTypeIsDifferent = True;
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Client type: '; ru='Тип клиента: '; de='Kundentyp: '") + TrimAll(vGuestDocRef.ClientType);
			EndIf;
			vSPAreDifferent = False;
			vMainSPIsDifferent = False;
			If vGuestDocRef.ServicePackage <> vObj.ServicePackage Then
				vSPAreDifferent = True;
				vMainSPIsDifferent = True;
			ElsIf vGuestDocRef.ServicePackages.Count() <> vObj.ServicePackages.Count() Then
				vSPAreDifferent = True;
			ElsIf vGuestDocRef.ServicePackages.Count() > 0 Then
				For Each vSPRow In vGuestDocRef.ServicePackages Do
					vObjSPRow = vObj.ServicePackages.Get(vGuestDocRef.ServicePackages.IndexOf(vSPRow));
					If vSPRow.ServicePackage <> vObjSPRow.ServicePackage Then
						vSPAreDifferent = True;
						Break;
					ElsIf vSPRow.Quantity <> vObjSPRow.Quantity Or vSPRow.DateFrom <> vObjSPRow.DateFrom Or vSPRow.DateTo <> vObjSPRow.DateTo Then
						vSPAreDifferent = True;
						Break;
					EndIf;
				EndDo;
			EndIf;
			If vSPAreDifferent Then
				vGiGRow.ServicePackagesAreDifferent = True;
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Packages: '; ru='Пакеты: '; de='Pakete: '") + ?(vMainSPIsDifferent, TrimAll(vGuestDocRef.ServicePackage), "");
				For Each vSPRow In vGuestDocRef.ServicePackages Do
					vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + TrimAll(vSPRow.ServicePackage);
				EndDo;
			EndIf;
			If vGuestDocRef.DiscountType <> vObj.DiscountType Or vGuestDocRef.Discount <> vObj.Discount Or vGuestDocRef.DiscountCard <> vObj.DiscountCard Then
				vGiGRow.DiscountsAreDifferent = True;
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Discount type: '; ru='Тип скидки: '; de='Rabatttyp: '") + TrimAll(vGuestDocRef.DiscountType);
			EndIf;
			If vGuestDocRef.Discount <> vObj.Discount Then
				vGiGRow.DiscountsAreDifferent = True;
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Discount %: '; ru='Скидка %: '; de='Rabatt %: '") + Format(vGuestDocRef.Discount, "ND=5; NFD=2");
			EndIf;
			If vGuestDocRef.DiscountCard <> vObj.DiscountCard Then
				vGiGRow.DiscountsAreDifferent = True;
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Discount card: '; ru='Дисконтная карта: '; de='Rabattkarte: '") + TrimAll(vGuestDocRef.DiscountCard);
			EndIf;
			If vGuestDocRef.Prices.Count() <> 0 And (vGuestDocRef.Prices.Count() <> vObj.Prices.Count() Or vObj.Prices.Count() > 0 And vGuestDocRef.Prices.Get(0).Price <> vObj.Prices.Get(0).Price) Then
				vGiGRow.ManualPricesAreDifferent = True;
				For Each vPRow In vGuestDocRef.Prices Do
					If vPRow.Price = 0 And IsManualRoomPrice = 1 Then
						Continue;
					EndIf;
					vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Manual price for: '; ru='Ручная цена за: '; de='Manuelle Preis für: '") + TrimAll(vPRow.Service) + " = " + cmFormatSum(vPRow.Price, vPRow.Currency, "NZ=");
				EndDo;
			EndIf;
			If vGuestDocRef.RoomRates.Count() > 0 And vGuestDocRef.RoomRates.Count() <> vObj.RoomRates.Count() Then
				vGiGRow.RoomRatesAreDifferent = True;
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Changes plan diffs'; ru='План изм. отличается'; de='Änderungsplan ist anders'");
			ElsIf vGuestDocRef.RoomRates.Count() = vObj.RoomRates.Count() Then
				For Each vRRRow In vGuestDocRef.RoomRates Do
					vObjRRRow = vObj.RoomRates.Get(vGuestDocRef.RoomRates.IndexOf(vRRRow));
					If ValueIsFilled(vRRRow.RoomRate) And vRRRow.RoomRate <> vObjRRRow.RoomRate And vRRRow.RoomRate <> vGuestDocRef.RoomRate Or 
					   ValueIsFilled(vRRRow.AccommodationType) And vRRRow.AccommodationType <> vObjRRRow.AccommodationType And vRRRow.AccommodationType <> vGuestDocRef.AccommodationType Then
						vGiGRow.RoomRatesAreDifferent = True;
						vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + 
						                             ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + 
													 Format(vRRRow.AccountingDate, "DF=dd.MM.yyyy") + " " + 
													 TrimAll(TrimAll(vRRRow.RoomRate) + " " + 
													 TrimAll(vRRRow.AccommodationType) + " " + 
													 TrimAll(vRRRow.Room) + " " + TrimAll(vRRRow.RoomType));
						Break;
					EndIf;
				EndDo;
			EndIf;
			If vGuestDocRef.BoardPlace <> vObj.BoardPlace Then
				vGiGRow.BoardPlaceIsDifferent = True;
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Board place: '; ru='Место питания: '; de='Essen ort: '") + TrimAll(vGuestDocRef.BoardPlace);
			EndIf;
			If TypeOf(vGuestDocRef) = Type("DocumentRef.Accommodation") And 
			   ValueIsFilled(vGuestDocRef.AccommodationStatus) And ValueIsFilled(vObj.AccommodationStatus) And 
			   vGuestDocRef.AccommodationStatus.IsInHouse <> vObj.AccommodationStatus.IsInHouse Then
				If vGuestDocRef.AccommodationStatus.IsInHouse Then
					vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Is in-house'; ru='Проживает'; de='Ist im Haus'");
				Else
					vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Is checked-out'; ru='Выселен'; de='Ist ausgecheckt'");
				EndIf;
			EndIf;
			
			// Fill guests ages
			AdultsMinAge = 18;
			vAgesStruct = Undefined;
			vHotel = vObj.Hotel;
			If ValueIsFilled(vHotel) Then
				vAgesStruct = vHotel;
			EndIf;
			If ValueIsFilled(vObj.Contract) Then
				vAllotmentContract = vObj.Contract;
				If vAllotmentContract.TeenagersMaxAge <> 0 Or vAllotmentContract.ChildrenMaxAge <> 0 Or vAllotmentContract.InfantsMaxAge <> 0 Then
					vAgesStruct = vAllotmentContract;
				EndIf;
			EndIf;
			// Get active special offers
			If vHotel.TeenagersMaxAge <> 0 Or vHotel.ChildrenMaxAge <> 0 Or vHotel.InfantsMaxAge <> 0 Then
				vOffers = cmGetConfirmedSpecialOffersForReservation(vObj.Ref, vObj.Hotel, vObj.RoomRate, vObj.RoomRateType, vObj.Guest, vObj.ClientType, vObj.Customer, vObj.CustomerType, vObj.GuestGroup, vObj.SourceOfBusiness, vObj.MarketingCode, vObj.TripPurpose, vObj.CheckInDate, vObj.Duration, vObj.CheckOutDate, ?(ValueIsFilled(vObj.GuestGroup), vObj.GuestGroup.CreateDate, vObj.Date), vObj.RoomType);
				For Each vOffersRow In vOffers Do
					vOffer = vOffersRow.SpecialOffer;
					If vOffer.TeenagersMaxAge <> 0 Or vOffer.ChildrenMaxAge <> 0 Or vOffer.InfantsMaxAge <> 0 Then
						vAgesStruct = vOffer;
						Break;
					EndIf;
				EndDo;
			EndIf;
			If vAgesStruct.TeenagersMaxAge <> 0 Then
				AdultsMinAge = vAgesStruct.TeenagersMaxAge + 1;
			ElsIf vAgesStruct.ChildrenMaxAge <> 0 Then
				AdultsMinAge = vAgesStruct.ChildrenMaxAge + 1;
			ElsIf vAgesStruct.InfantsMaxAge <> 0 Then
				AdultsMinAge = vAgesStruct.InfantsMaxAge + 1;
			EndIf;

			vAccType = vGiGRow.AccommodationType;
			If (vGiGRow.GuestAge = 0 Or vGiGRow.GuestAge >= AdultsMinAge) And 
			   (vAccType.AllowedClientAgeTo = 0 Or vAccType.AllowedClientAgeTo >= AdultsMinAge) Then
				NumberOfAdults = NumberOfAdults + 1;
			Else
				NumberOfKids = NumberOfKids + 1;
				vGuest = vGiGRow.GuestRef;
				vGuestsListRow = vGuestsList.Add();
				vGuestsListRow.Guest = vGuest;
				vKidAge = 0;
				If ValueIsFilled(vGuest) And ValueIsFilled(vGuest.DateOfBirth) Then
					vKidAge = GetClientAge(vGuest, vObj.CheckInDate);
				Else
					vKidAge = vGiGRow.GuestAge;
				EndIf;
				If vKidAge = 0 And vAccType.AllowedClientAgeTo <> 0 Then
					vKidAge = vAccType.AllowedClientAgeTo - 1;
				EndIf;
				vGiGRow.GuestAge = vKidAge;
				vGuestsListRow.GuestAge = vKidAge;
				Try
					ThisObject["KidAge"+String(NumberOfKids)] = vKidAge;
				Except
				EndTry;
			EndIf;
		EndDo;
		If NumberOfKids > 0 Then
			NumberOfKidsOnChangeAtServer(True, vGuestsList, vObj);
		EndIf;
		// Synchronize current accommodation room rates and document attributes
		vRoomRateWasChanged = False;
		vAccommodationTypeWasChanged = False;
		vRoomAttributesWereChanged = False;
		vOldRoomRate = vObj.RoomRate;
		vOldAccommodationType = vObj.AccommodationType;
		vOldRoom = vObj.Room;
		vOldRoomType = vObj.RoomType;
		vRoomRates = vObj.RoomRates.Unload();
		vRoomRates.Sort("AccountingDate Desc");
		For Each vRRRow In vRoomRates Do
			vLastRoomRate = vRRRow.RoomRate;
			vLastAccommodationType = vRRRow.AccommodationType;
			vLastRoom = vRRRow.Room;
			vLastRoomType = vRRRow.RoomType;
			If vRRRow.AccountingDate <= BegOfDay(CurrentSessionDate()) Then
				If ValueIsFilled(vLastRoomRate) And vLastRoomRate <> vObj.RoomRate Then
					vObj.RoomRate = vLastRoomRate;
					vObj.RoomRateType = vLastRoomRate.RoomRateType;
					SetDurationCaption(vObj);
					vRoomRateWasChanged = True;
					ThisObject.Modified = True;
				EndIf;
				If ValueIsFilled(vLastAccommodationType) And vLastAccommodationType <> vObj.AccommodationType Then
					vObj.AccommodationType = vLastAccommodationType;
					vAccommodationTypeWasChanged = True;
					ThisObject.Modified = True;
				EndIf;
				Break;
			EndIf;
		EndDo;
		If vRoomRateWasChanged Or vAccommodationTypeWasChanged Or vRoomAttributesWereChanged Then
			// Check if there is row for the check-in date in room rates
			If vObj.RoomRates.Find(BegOfDay(vObj.CheckInDate), "AccountingDate") = Undefined Then
				vCIRRRow = vObj.RoomRates.Add();
				vCIRRRow.AccountingDate = BegOfDay(vObj.CheckInDate);
				If vRoomRateWasChanged Then
					vCIRRRow.RoomRate = vOldRoomRate;
				EndIf;
				If vAccommodationTypeWasChanged Then
					vCIRRRow.AccommodationType = vOldAccommodationType;
				EndIf;
				If vRoomAttributesWereChanged Then
					vCIRRRow.Room = vOldRoom;
					vCIRRRow.RoomType = vOldRoomType;
				EndIf;
				vObj.RoomRates.Sort("AccountingDate, ChangeTime");
			EndIf;
		EndIf;
	Else
		If vObj.IsNew() Then
			ThisObject.Modified = True;
		EndIf;
		vRef = vObj.pmGetThisDocumentRef();
		vAccommodationsArray.Add(vRef);
		
		// Check number of persons
		If vObj.NumberOfPersons > 1 Then
			vObj.NumberOfPersons = 1;
		EndIf;
		// If check-in is in progress
		If GuestsToCheckInList.Count() = 0 And Not OneGuestMode Then
			If ValueIsFilled(vObj.ParentDoc) And vAddOtherOneRoomGuests Then
				vSelResList = GetOneRoomGuests(vObj.ParentDoc);
				If vSelResList.Count() > 0 Then
					GuestsToCheckInList = vSelResList.Copy();
				EndIf;
			EndIf;
		EndIf;
		If GuestsToCheckInList.Count() > 0 Then
			i = 0;
			For Each vGuestItem In GuestsToCheckInList Do
				vGuestItemValue = vGuestItem.Value;
				// Lock reservation
				LockDataForEdit(vGuestItemValue, , ThisObject.UUID);
				// Process reservations
				If i = 0 Then
					If vObj.ParentDoc <> vGuestItemValue Then
						vObj.Fill(vGuestItemValue);
						If vObj.NumberOfAdults = 0 Then
							NumberOfAdults = 0;
							NumberOfKids = 1;
							Items.KidAge1.Visible = True;
							KidAge1 = vObj.GuestAge;
							LastNumberOfAdults = NumberOfAdults;
							LastKidsNumber = NumberOfKids;
						EndIf;
					EndIf;
					SelGuest1 = vGuestItemValue.Guest.FullName;
					If ValueIsFilled(vGuestItemValue.Guest) Then
						Items.SelGuest1.TextEdit = False;
					EndIf;
					// Fill room properties
					ThisObject.RoomProperties = GetRoomPropertiesValueList(vObj);
					ThisObject.RoomPropertiesFromGuest = GetRoomPropertiesFromGuestValueList(vObj);
				Else
					vNewRow = GuestsInGroup.Add();
					vNewRow.Guest = vGuestItemValue.Guest.FullName;
					vNewRow.AccommodationType = vGuestItemValue.AccommodationType;
					If TypeOf(vGuestItemValue) <> Type("Structure") Or TypeOf(vGuestItemValue) = Type("Structure") And vGuestItemValue.Property("SharePercent") Then
						vNewRow.SharePercent = vGuestItemValue.SharePercent;
					EndIf;
					vNewRow.GuestRef = vGuestItemValue.Guest;
					vNewRow.IsGuest = True;
					vNewRow.HotelProduct = vGuestItemValue.HotelProduct;
					vNewRow.LegalRepresentative = vGuestItemValue.LegalRepresentative;
					vNewRow.RelationType = vGuestItemValue.RelationType;
					vNewRow.GuestAge = vGuestItemValue.GuestAge;
				EndIf;
				i = i + 1;
			EndDo;
			// check GiG
			vGuestsList = New ValueTable();
			vGuestsList.Columns.Add("Guest", cmGetCatalogTypeDescription("Clients"));
			vGuestsList.Columns.Add("GuestAge", cmGetNumberTypeDescription(3, 0, True));
			For Each vGiGRow In GuestsInGroup Do
				vGuestDocRef = vGiGRow.Ref;
				If Not ValueIsFilled(vGuestDocRef) Then
					vGuestDocRef = GuestsToCheckInList.Get(GuestsInGroup.IndexOf(vGiGRow) + 1).Value;
				EndIf;
				vAccType = vGiGRow.AccommodationType;
				If (ValueIsFilled(vGuestDocRef) And vGuestDocRef.GuestAge = 0 Or Not ValueIsFilled(vGuestDocRef)) And 
				   (vAccType.AllowedClientAgeTo = 0 Or vAccType.AllowedClientAgeTo >= AdultsMinAge) Then
					NumberOfAdults = NumberOfAdults + 1;
				Else
					NumberOfKids = NumberOfKids + 1;
					vGuest = vGiGRow.GuestRef;
					vGuestsListRow = vGuestsList.Add();
					vGuestsListRow.Guest = vGuest;
					vKidAge = 0;
					If ValueIsFilled(vGuest) And ValueIsFilled(vGuest.DateOfBirth) Then
						vKidAge = GetClientAge(vGuest, vObj.CheckInDate);
						If vKidAge = 0 And vAccType.AllowedClientAgeTo <> 0 Then
							vKidAge = vAccType.AllowedClientAgeTo - 1;
						EndIf;
						Try
							ThisObject["KidAge"+String(NumberOfKids)] = vKidAge;
						Except
						EndTry;
					Else
						vKidAge = vGiGRow.GuestAge;
					EndIf;
					vGuestsListRow.GuestAge = vKidAge;
				EndIf;
				If ValueIsFilled(vGuestDocRef) Then
					If vGuestDocRef.CheckOutDate <> vObj.CheckOutDate Then
						vGiGRow.CheckOutDateIsDifferent = True;
						vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Check-out: '; ru='Выезд: '; de='Abreise: '") + Format(vGuestDocRef.CheckOutDate, "DF='dd.MM.yyyy HH:mm'");
					EndIf;
					If vGuestDocRef.IsForFolioSplit <> vObj.IsForFolioSplit Then
						vGiGRow.IsForFolioSplitIsDifferent = True;
						vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + ?(vGuestDocRef.IsForFolioSplit, NStr("en='Do folio split'; ru='Раздельные счета'; de='Do Folio Split'"), "");
					EndIf;
					If vGuestDocRef.RoomRate <> vObj.RoomRate Then
						vGiGRow.RoomRateIsDifferent = True;
						vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Room rate: '; ru='Тариф: '; de='Tariff: '") + TrimAll(vGuestDocRef.RoomRate);
					EndIf;
					If vGuestDocRef.ClientType <> vObj.ClientType Then
						vGiGRow.ClientTypeIsDifferent = True;
						vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Client type: '; ru='Тип клиента: '; de='Kundentyp: '") + TrimAll(vGuestDocRef.ClientType);
					EndIf;
					vSPAreDifferent = False;
					vMainSPIsDifferent = False;
					If vGuestDocRef.ServicePackage <> vObj.ServicePackage Then
						vSPAreDifferent = True;
						vMainSPIsDifferent = True;
					ElsIf vGuestDocRef.ServicePackages.Count() <> vObj.ServicePackages.Count() Then
						vSPAreDifferent = True;
					ElsIf vGuestDocRef.ServicePackages.Count() > 0 Then
						For Each vSPRow In vGuestDocRef.ServicePackages Do
							vObjSPRow = vObj.ServicePackages.Get(vGuestDocRef.ServicePackages.IndexOf(vSPRow));
							If vSPRow.ServicePackage <> vObjSPRow.ServicePackage Then
								vSPAreDifferent = True;
								Break;
							ElsIf vSPRow.Quantity <> vObjSPRow.Quantity Or vSPRow.DateFrom <> vObjSPRow.DateFrom Or vSPRow.DateTo <> vObjSPRow.DateTo Then
								vSPAreDifferent = True;
								Break;
							EndIf;
						EndDo;
					EndIf;
					If vSPAreDifferent Then
						vGiGRow.ServicePackagesAreDifferent = True;
						vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Packages: '; ru='Пакеты: '; de='Pakete: '") + ?(vMainSPIsDifferent, TrimAll(vGuestDocRef.ServicePackage), "");
						For Each vSPRow In vGuestDocRef.ServicePackages Do
							vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + TrimAll(vSPRow.ServicePackage);
						EndDo;
					EndIf;
					If vGuestDocRef.DiscountType <> vObj.DiscountType Or vGuestDocRef.Discount <> vObj.Discount Or vGuestDocRef.DiscountCard <> vObj.DiscountCard Then
						vGiGRow.DiscountsAreDifferent = True;
						vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Discount type: '; ru='Тип скидки: '; de='Rabatttyp: '") + TrimAll(vGuestDocRef.DiscountType);
					EndIf;
					If vGuestDocRef.Discount <> vObj.Discount Then
						vGiGRow.DiscountsAreDifferent = True;
						vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Discount %: '; ru='Скидка %: '; de='Rabatt %: '") + Format(vGuestDocRef.Discount, "ND=5; NFD=2");
					EndIf;
					If vGuestDocRef.DiscountCard <> vObj.DiscountCard Then
						vGiGRow.DiscountsAreDifferent = True;
						vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Discount card: '; ru='Дисконтная карта: '; de='Rabattkarte: '") + TrimAll(vGuestDocRef.DiscountCard);
					EndIf;
					If vGuestDocRef.Prices.Count() <> 0 And (vGuestDocRef.Prices.Count() <> vObj.Prices.Count() Or vObj.Prices.Count() > 0 And vGuestDocRef.Prices.Get(0).Price <> vObj.Prices.Get(0).Price) Then
						vGiGRow.ManualPricesAreDifferent = True;
						For Each vPRow In vGuestDocRef.Prices Do
							If vPRow.Price = 0 And IsManualRoomPrice = 1 Then
								Continue;
							EndIf;
							vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Manual price for: '; ru='Ручная цена за: '; de='Manuelle Preis für: '") + TrimAll(vPRow.Service) + " = " + cmFormatSum(vPRow.Price, vPRow.Currency, "NZ=");
						EndDo;
					EndIf;
					If vGuestDocRef.BoardPlace <> vObj.BoardPlace Then
						vGiGRow.BoardPlaceIsDifferent = True;
						vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Board place: '; ru='Место питания: '; de='Essen ort: '") + TrimAll(vGuestDocRef.BoardPlace);
					EndIf;
					If TypeOf(vGuestDocRef) = Type("DocumentRef.Accommodation") And 
					   ValueIsFilled(vGuestDocRef.AccommodationStatus) And ValueIsFilled(vObj.AccommodationStatus) And 
					   vGuestDocRef.AccommodationStatus.IsInHouse <> vObj.AccommodationStatus.IsInHouse Then
						If vGuestDocRef.AccommodationStatus.IsInHouse Then
							vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Is in-house'; ru='Проживает'; de='Ist im Haus'");
						Else
							vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Is checked-out'; ru='Выселен'; de='Ist ausgecheckt'");
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			If NumberOfKids > 0 Then
				NumberOfKidsOnChangeAtServer(True, vGuestsList, vObj);
			EndIf;
		EndIf;
	EndIf;
	If Parameters.Property("CheckInDate") And ValueIsFilled(Parameters.CheckInDate) Or 
	   Parameters.Property("CheckOutDate") And ValueIsFilled(Parameters.CheckOutDate) Then
		vObj.Duration = vObj.pmCalculateDuration();
	EndIf;
	
	// Add guests from "Available rooms" report selection. This code is applied for the new document form only
	If DocsList.Count() > 0 And Not OneGuestMode Then
		NumberOfKids = 0;
		DocsList.SortByPresentation();
		NumberOfAdults = DocsList.Count();
		For vDocInd = 0 to DocsList.Count()-1 Do
			vDocIndRef = DocsList.Get(vDocInd).Value;
			If vDocInd = 0 Then
				vObj.Phone = vDocIndRef.Phone;
				vObj.Email = vDocIndRef.Email;
				vObj.Guest = vDocIndRef.GuestRef; 
				SelGuest1 = vDocIndRef.GuestName;
				If ValueIsFilled(vObj.Guest) Then
					Items.SelGuest1.TextEdit = False;
				EndIf;
			Else
				vNewGuest = GuestsInGroup.Add();
				vNewGuest.AccommodationType = vDocIndRef.AccommodationType;
				If TypeOf(vDocIndRef) <> Type("Structure") Or TypeOf(vDocIndRef) = Type("Structure") And vDocIndRef.Property("SharePercent") Then
					vNewGuest.SharePercent = vDocIndRef.SharePercent;
				EndIf;
				vNewGuest.Guest = vDocIndRef.GuestName;
				vNewGuest.GuestRef= vDocIndRef.GuestRef;
				vNewGuest.IsAnnulation = False;
				vNewGuest.IsGuest = True;
				vNewGuest.HotelProduct = vDocIndRef.HotelProduct;
				vNewGuest.LegalRepresentative = vDocIndRef.LegalRepresentative;
				vNewGuest.RelationType = vDocIndRef.RelationType;
				If ValueIsFilled(vDocIndRef.DateOfBirth) Then
					vAge = GetClientAge( , vObj.CheckInDate, vDocIndRef.DateOfBirth);
					If vAge <> 0 And vAge < AdultsMinAge Then
						NumberOfKids = NumberOfKids + 1;
						Try
							Items["KidAge"+String(NumberOfKids)].Visible = True;
							ThisObject["KidAge"+String(NumberOfKids)] = vAge;
						Except
						EndTry;
					EndIf;					
				EndIf;
			EndIf;
		EndDo;
		NumberOfAdults = NumberOfAdults - NumberOfKids;
	EndIf;
		
	// Main room guest accommodation type is editable if he is the only guest in the room
	If (NumberOfAdults = 1 And NumberOfKids = 0) Or vObj.IsForFolioSplit Or OneGuestMode Then
		Items.AccommodationType.TextEdit = True;
		Items.AccommodationType.Enabled = True;
	Else
		Items.AccommodationType.TextEdit = False;
		Items.AccommodationType.Enabled = False;
	EndIf;
	
	// Manual prices
	If Not vObj.IsNew() Then
		ManualPriceAppearance(vObj);
	EndIf;
	
	// Hide guest fields not needed any more
	If Not pIsOnOpenMode And Not OneGuestMode Then
		Try
			vIndex = 1;
			While vIndex <= GuestsInGroup.Count() Do
				vGiGRow = GuestsInGroup.Get(vIndex - 1);
				Items["Guest"+String(vIndex + 1)+"Group"].Visible = True;
				Items["Guest"+String(vIndex + 1)+"Group"].Enabled = True;
				ThisForm["AccommodationType"+String(vIndex + 1)] = vGiGRow.AccommodationType;
				ThisForm["SelGuest"+String(vIndex + 1)] = TrimAll(vGiGRow.Guest);
				ThisForm["Guest"+String(vIndex + 1)] = vGiGRow.GuestRef;
				vIndex = vIndex + 1;
			EndDo;
			vIndex = GuestsInGroup.Count() + 1;
			While True Do
				If Items["Guest"+String(vIndex + 1)+"Group"].Visible Then
					Items["Guest"+String(vIndex + 1)+"Group"].Visible = False;
					Items["Guest"+String(vIndex + 1)+"Group"].Enabled = False;
					ThisForm["AccommodationType"+String(vIndex + 1)] = Undefined;
					ThisForm["SelGuest"+String(vIndex + 1)] = "";
					ThisForm["Guest"+String(vIndex + 1)] = Undefined;
				Else
					Break;
				EndIf;
				vIndex = vIndex + 1;
			EndDo;
		Except
		EndTry;
	EndIf;
	
	// Apply form appearance according to the room guests and guest ages
	CheckGuestFieldCount(vObj, True, True);
	
	// Hide or show guest changes
	For Each vGiGRow In GuestsInGroup Do
		vInd = GuestsInGroup.IndexOf(vGiGRow) + 2;
		ThisObject["GuestChangesDescription" + String(vInd)] = vGiGRow.ChangesDescription;
		vCDItem = Items["Guest" + String(vInd) + "ChangesGroup"];
		If Not IsBlankString(vGiGRow.ChangesDescription) Then
			vCDItem.Visible = True;
		Else
			vCDItem.Visible = False;
		EndIf;
		ThisObject["LegalRepresentative" + String(vInd)] 	= vGiGRow.LegalRepresentative;
		ThisObject["RelationType" + String(vInd)] 		= vGiGRow.RelationType;
	EndDo;
	
	// Get current user customer and allotment
	vAuthorCustomer = SessionParameters.CurrentUser.Customer;
	vAuthorRoomQuota = SessionParameters.CurrentUser.RoomQuota;
	
	// Set default attributes if is new
	If vObj.IsNew() Then
		WasPosted = False;
		IsNew = True;
		// Use current time
		vObj.SetTime(AutoTimeMode.CurrentOrLast);
		// Fill attributes with default values
		If Not ValueIsFilled(vObj.Author) Then
			vObj.pmFillAttributesWithDefaultValues();
		Else
			vObj.pmFillAuthorAndDate();
		EndIf;
		If Parameters.Property("Event") And ValueIsFilled(Parameters.Event) Then
			vObjvGGObj = vObj.GuestGroup.GetObject();
			vObjvGGObj.Event = Parameters.Event;
			vObjvGGObj.Write();
		EndIf;
		If ValueIsFilled(vObj.AccommodationTemplate) And vObj.AccommodationTemplate.IsForFolioSplit Then
			vObj.IsForFolioSplit = True;
		ElsIf ValueIsFilled(vObj.AccommodationType) And vObj.AccommodationType.Type = Enums.AccomodationTypes.Beds Then
			If ValueIsFilled(vObj.RoomType) And ValueIsFilled(vObj.RoomType.AccommodationType) And vObj.RoomType.AccommodationType.Type = Enums.AccomodationTypes.Beds Then
				vObj.IsForFolioSplit = True;
			ElsIf ValueIsFilled(vObj.Hotel) And ValueIsFilled(vObj.Hotel.AccommodationType) And vObj.Hotel.AccommodationType.Type = Enums.AccomodationTypes.Beds Then
				vObj.IsForFolioSplit = True;
			EndIf;
		ElsIf ValueIsFilled(vObj.Hotel) And ValueIsFilled(vObj.Hotel.AccommodationType) And vObj.Hotel.AccommodationType.Type = Enums.AccomodationTypes.Beds Then
			vObj.IsForFolioSplit = True;
		EndIf;
		// Calculate resources
		vObj.pmCalculateResources();
		// Set is by reservation flag
		vObj.pmSetIsByReservation();
		// Check and show room status if this is accommodation based on reservation
		If ValueIsFilled(vObj.Room) And ValueIsFilled(vObj.Room.RoomStatus) Then
			If ValueIsFilled(vObj.ParentDoc) And TypeOf(vObj.ParentDoc) = Type("DocumentRef.Reservation") Then
				// Check room status
				vCurRoomStatus = vObj.Room.RoomStatus;
				If vCurRoomStatus <> vObj.Hotel.VacantRoomStatus And
				   Not vCurRoomStatus.RoomIsVacantClear And 
				   vCurRoomStatus <> vObj.Hotel.OccupiedRoomStatus And
				   vCurRoomStatus <> vObj.Hotel.ReservedRoomStatus Then
					ChangeRoomMessageText = NStr("ru='Статус забронированного номера: " + TrimAll(vCurRoomStatus) + "!'; 
					                             |de='Room reserved status is " + TrimAll(vCurRoomStatus) + "!';
					                             |en='Room reserved status is " + TrimAll(vCurRoomStatus) + "!'");
					Items.ChangeRoomMessageTextGroup.Visible = True;
					Items.ChangeRoomMessageText.TextColor = WebColors.Red;
				EndIf;
			EndIf;
		EndIf;
	Else
		ChangeRoomMessageText = "";
		vChangeRoomMessageTextColor = WebColors.Blue;
		vPrevRoom = Undefined;
		vDoNotChangeAvailabilityInfo = False;
		vRoomRates = vObj.pmGetAccommodationPeriods();
		For Each vRRRow In vRoomRates Do
			If ValueIsFilled(vRRRow.Room) And vRRRow.Room <> vPrevRoom Then
				If vPrevRoom <> Undefined And ValueIsFilled(vRRRow.Room) And ValueIsFilled(vRRRow.RoomType) Then
					If IsBlankString(ChangeRoomMessageText) Then
						ChangeRoomMessageText = NStr("en='Room change '; ru='Переселение '; de='Umzug '") + TrimAll(vPrevRoom) + " " + TrimAll(vPrevRoom.RoomType.Code) + " -> " + TrimAll(vRRRow.Room) + " " + TrimAll(vRRRow.RoomType.Code);
					Else
						ChangeRoomMessageText = TrimAll(ChangeRoomMessageText) + " -> " + TrimAll(vRRRow.Room) + " " + TrimAll(vRRRow.RoomType.Code);
					EndIf;
				EndIf;
				vPrevRoom = vRRRow.Room;
			EndIf;
			If vRRRow.DoNotChangeAvailability And Not vDoNotChangeAvailabilityInfo Then
				vDoNotChangeAvailabilityInfo = True;
				vMessageText = Format(vRRRow.AccountingDate, "DF=dd.MM.yyyy") + " - " + NStr("en='Availability is not changed!'; ru='Доступность не изменяется!'; de='Verfügbarkeit wird nicht geändert!'");
				If IsBlankString(ChangeRoomMessageText) Then
					ChangeRoomMessageText = vMessageText;
				Else
					ChangeRoomMessageText = TrimAll(ChangeRoomMessageText) + ", " + vMessageText;
				EndIf;
			EndIf;
		EndDo;
		If IsBlankString(ChangeRoomMessageText) Then
			If ValueIsFilled(vObj.Reservation) Then
				vReservation = vObj.Reservation;
				If vReservation.RoomType <> vObj.RoomType And ValueIsFilled(vReservation.RoomType) And ValueIsFilled(vObj.RoomType) Then
					ChangeRoomMessageText = TrimAll(ChangeRoomMessageText) + ", " + NStr("en='Upsell '; ru='Ап-селл '; de='Upsell '") + TrimAll(vReservation.RoomType.Code) + " -> " + TrimAll(vObj.RoomType.Code);
					vChangeRoomMessageTextColor = WebColors.Blue;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vObj.RoomTypeUpgrade) And vObj.RoomType <> vObj.RoomTypeUpgrade Then
			ChangeRoomMessageText = TrimAll(ChangeRoomMessageText) + ?(IsBlankString(ChangeRoomMessageText), "", ", ") + NStr("en='Prices by '; ru='Цены по '; de='Preise nach '") + TrimAll(vObj.RoomTypeUpgrade.Code);
		EndIf;
		// Check next linked reservation
		vNextReservation = cmGetNextReservationInChain(vObj.Ref);
		If ValueIsFilled(vNextReservation) Then
			ChangeRoomMessageText = TrimAll(ChangeRoomMessageText) + ?(IsBlankString(ChangeRoomMessageText), "", ", ") + NStr("en='Next period '; ru='След. период '; de='Nächste Periode '") + TrimAll(TrimAll(vNextReservation.Room) + " " + TrimAll(vNextReservation.RoomType.Code)) + " " + Format(vNextReservation.CheckInDate, "DF=dd.MM.yy") + " - " + Format(vNextReservation.CheckOutDate, "DF=dd.MM.yy");
		EndIf;
		ChangeRoomMessageText = TrimAll(ChangeRoomMessageText);
		If Not IsBlankString(ChangeRoomMessageText) Then
			Items.ChangeRoomMessageTextGroup.Visible = True;
			Items.ChangeRoomMessageText.TextColor = vChangeRoomMessageTextColor;
		EndIf;
	EndIf;
	If ValueIsFilled(vAuthorCustomer) Then
		Items.Customer.ClearButton = False;
		Items.Customer.ChoiceButton = False;
		Items.Customer.ReadOnly = True;
		If Not IsNew Then
			Items.CheckInDate.ReadOnly = True;
		EndIf;
		Items.Room.ClearButton = False;
		Items.Room.ChoiceButton = False;
		Items.Room.ReadOnly = True;
	EndIf;
	If ValueIsFilled(vAuthorRoomQuota) Then
		Items.RoomQuota.ClearButton = False;
		Items.RoomQuota.ChoiceButton = False;
		Items.RoomQuota.OpenButton = False;
		Items.RoomQuota.ReadOnly = True;
	EndIf;

	// Read foreigner registry documents
	ReadForeignerRegistryDocuments(vObj);
	
	// Manual prices
	If vObj.IsNew() Then
		ManualPriceAppearance(vObj);
	EndIf;
	
	// Check edit prohibited date
	If ValueIsFilled(vObj.Hotel) Then
		If ValueIsFilled(vObj.Hotel.EditProhibitedDate) And 
		   BegOfDay(vObj.Hotel.EditProhibitedDate) >= BegOfDay(vObj.CheckOutDate) Then
			DoFormReadOnly();
		EndIf;
	EndIf;
	
	// Check user permissions
	CheckPermissions(vObj);
	
	// Fill times
	CheckInTime = cmExtractTime(vObj.CheckInDate);
	CheckOutTime = cmExtractTime(vObj.CheckOutDate);
	
	// Set discounts if is based on operation template
	If vObj.IsNew() And IsBasedOnOperationTemplate Then
		vObj.pmSetDiscounts();
	EndIf;
	
	// Fill list of rooms in reservation
	FillReservationRoomsList(vObj);
	
	// Load customer contact persons list
	LoadCustomerContactPersonsList(vObj);
	
	// Set room quota appearance
	SetRoomQuotaAppearance(vObj);
	
	// Save current guest group and room rate values
	SavGuestGroup = vObj.GuestGroup;
	SavRoomRate = vObj.RoomRate;
	SavRoomType = vObj.RoomType;
	SavAccommodationType = vObj.AccommodationType;
	
	// Check if all document charges are closed by settlements
	If vObj.Posted Then
		If ValueIsFilled(vObj.Hotel) And vObj.Hotel.DoNotEditSettledDocs And 
		  (vObj.Services.Total("Sum") <> 0 Or vObj.Services.Total("Quantity") <> 0) And 
		   ValueIsFilled(vObj.AccommodationStatus) And vObj.AccommodationStatus.IsActive And Not vObj.AccommodationStatus.IsInHouse And 
		   cmGetDocumentCharges(vObj.Ref, Undefined, Undefined, vObj.Hotel, Undefined, True).Count() > 0 Then
			vDocBalanceIsZero = False;
			vDocBalancesRow = cmGetDocumentCurrentAccountsReceivableBalance(vObj.Ref);
			If vDocBalancesRow <> Undefined Then
				If vDocBalancesRow.SumBalance = 0 And vDocBalancesRow.QuantityBalance = 0 Then
					vDocBalanceIsZero = True;
				EndIf;
			Else
				vDocBalanceIsZero = True;
			EndIf;
			If vDocBalanceIsZero Then
				DoFormReadOnly();
				If Not IsInRestoreFromHistoryMode Then
					tcCommonFunctionOnClientServer.UserMessage(NStr("ru='Все начисления размещения уже закрыты актами об оказании услуг! Редактирование такого размещения запрещено.';en='All accommodation charges are closed by invoices! Accommodation will be opened read only.';de='Alle Übernachtungskosten werden durch Rechnungen geschlossen! Die Unterkunft ist nur lesbar.'"));
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Check if we have to rebuild guest folios
	vObj.pmCheckRoomMainFolios();
	
	// Update planned payment method if necessary
	Payer = vObj.pmSetPlannedPaymentMethod(TPayer);
	If Payer = Enums.WhoPays.ChargingRules Then
		Items.GroupChargingRules.Show();
	Else
		Items.GroupChargingRules.Hide();
	EndIf;
	
	// Fill guest group description
	If ValueIsFilled(vObj.GuestGroup) Then
		vGuestGroup = vObj.GuestGroup;
		Items.GuestGroupDescription.Enabled = True;
		GuestGroupDescription = TrimAll(vGuestGroup.Description);
		Items.GuestGroupID.Enabled = True;
		GuestGroupID = TrimAll(vGuestGroup.ID);
		Items.GuestGroupCreateDate.Enabled = True;
		GuestGroupCreateDate = vGuestGroup.CreateDate;
	Else
		Items.GuestGroupDescription.Enabled = False;
		GuestGroupDescription = "";
		Items.GuestGroupID.Enabled = False;
		GuestGroupID = "";
		Items.GuestGroupCreateDate.Enabled = False;
		GuestGroupCreateDate = '00010101';
	EndIf;
	
	SetDurationCaption(vObj);
	
	// Room interface commands list
	SetRoomInterfacesFilter(vObj);
	
	// Set room status picture
	SetRoomStatusPictureAtServer(vObj);
	
	// Check if there are other room guests that were not checked-in yet
	vObjAccommodationStatus = vObj.AccommodationStatus;
	If ValueIsFilled(vObjAccommodationStatus) And vObjAccommodationStatus.IsInHouse And vObjAccommodationStatus.IsActive Then
		vMsgText = "";
		If vObj.IsNew() Then
			vOneRoomAccs = cmGetOneRoomAccommodations(Catalogs.Rooms.EmptyRef(), vObj.GuestGroup, vObj.CheckInDate, vObj.CheckOutDate, vObj.Number);
			For Each vOneRoomAccsRow In vOneRoomAccs Do
				vAccRef = vOneRoomAccsRow.Ref;
				vMsgText = StrTemplate(NStr("en='Guests from this reservation are already staying in room %1 from %2!'; ru='В номере %1 с %2 уже проживают гости из этой брони!'; de='Im Zimmer %1 von %2 wohnen bereits Gäste dieser Reservierung!'"), TrimAll(vAccRef.Room), Format(vAccRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'"));
				Break;
			EndDo;
			If Not IsBlankString(vMsgText) Then
				GuestRemarks = vMsgText + ?(IsBlankString(GuestRemarks), "", Chars.LF) + TrimAll(GuestRemarks);
				Items.GuestRemarks.Visible = True;
				Items.GuestRemarks.TextColor = WebColors.Blue;
				Items.GuestRemarks.BorderColor = WebColors.Blue;
			EndIf;
		Else
			vOneRoomRes = cmGetOneRoomReservations(vObj.Number, vObj.GuestGroup, vObj.CheckInDate, vObj.CheckOutDate);
			For Each vOneRoomResRow In vOneRoomRes Do
				vResRef = vOneRoomResRow.Ref;
				vMsgText = StrTemplate(NStr("en='There are not checked-in guests expected on %1!'; ru='По этой брони есть не заселенные гости с заездом %1!'; de='Am %1 werden keine eingecheckten Gäste erwartet!'"), Format(vResRef.CheckInDate, "DF='dd.MM.yyyy HH:mm'"));
				Break;
			EndDo;
			If Not IsBlankString(vMsgText) Then
				GuestRemarks = vMsgText + ?(IsBlankString(GuestRemarks), "", Chars.LF) + TrimAll(GuestRemarks);
				Items.GuestRemarks.Visible = True;
				Items.GuestRemarks.TextColor = WebColors.Blue;
				Items.GuestRemarks.BorderColor = WebColors.Blue;
			EndIf;
		EndIf;
	EndIf;
	
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	
	// Beds setup
	Items.BedsSetup.ChoiceList.Clear();
	vBedsSetupList = GetBedsSetupList(Object.BedsSetup, Object.RoomType);
	For Each vBedsSetupListItem In vBedsSetupList Do
		Items.BedsSetup.ChoiceList.Add(vBedsSetupListItem.Value);
	EndDo;
	
	// Custom fields
	FillCustomFields();
	
	IsOnOpenForm = False;
	
	// Calculate totals
	TotalSum = CalculateTotalServices(, pIsOnOpenMode, False, False);
	
	// Fill presentation
	ThisObject.RoomPropertiesPresentation = GetRoomPropertiesPresentation();

	// Fill service packages presentation
	FillServicePackagesPresentation();
	
	// Check charging mode
	If ValueIsFilled(Object.Hotel) And Object.Hotel.CloseOfPeriodDoChargeServices Then
		Items.DoChargingToDate.Visible = True;
	Else
		If ValueIsFilled(Object.RoomRate) And Object.RoomRate.CloseOfPeriodDoChargeServices Then
			Items.DoChargingToDate.Visible = True;
		Else
			Items.DoChargingToDate.Visible = False;
		EndIf;
	EndIf;
	
	// Credit card presentation
	If ValueIsFilled(Object.CreditCard) Then
		CreditCardPresentation = TrimAll(Object.CreditCard);
		Items.ClearCreditCard.Visible = True;
	Else
		CreditCardPresentation = NStr("en='<Credit card>'; ru='<Кредитная карта>'; de='<Kreditkarte>'");
		Items.ClearCreditCard.Visible = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditGuestGroup") Then
		Items.GuestGroup.ReadOnly = True;
		Items.GuestGroup.ChoiceButton = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToViewCreditCardsData") Then
		Items.CreditCardPresentation.Visible = False;
		Items.ClearCreditCard.Visible = False;
	EndIf;
	
	// Window views
	vViews = cmGetWindowViews(Object.Hotel);
	vRoomTypesWithViews = cmGetRoomTypesWithViews(Object.Hotel);
	If vViews.Count() > 0 And vRoomTypesWithViews.Count() > 0 Then
		Items.RoomType.Visible = False;
		Items.GroupRoomType.Visible = True;
		If ValueIsFilled(Object.RoomType) Then
			WindowView = Object.RoomType.WindowView;
			RoomTypeClass = Object.RoomType.RoomClass;
		Else
			WindowView = Undefined;
			RoomTypeClass = Undefined;
		EndIf;
	Else
		Items.RoomType.Visible = True;
		Items.GroupRoomType.Visible = False;
		WindowView = Undefined;
		RoomTypeClass = Undefined;
	EndIf;
	
	// Meal board terms
	vTerms = cmGetAllMealBoardTerms(Object.Hotel);
	If vTerms.Count() > 0 Then
		vTermsArray = GetMealBoardTermsList(Object.Hotel, Object.Contract).UnloadValues();
		Items.ServicePackage.Visible = True;
		Items.ServicePackage.ChoiceList.LoadValues(vTermsArray);
		Items.RoomRatesTerms.Visible = True;
		Items.ServicePackageBeforeUpgrade.Visible = False; // Not supported yet
		Items.ServicePackageBeforeUpgrade.ChoiceList.LoadValues(vTermsArray);
	Else
		Items.ServicePackage.Visible = False;
		Items.RoomRatesTerms.Visible = False;
		Items.ServicePackageBeforeUpgrade.Visible = False;
	EndIf;
	
	// Form actions availability
	If Not Object.AccommodationStatus.IsInHouse Then
		vAccountingDate = tcOnServer.GetForecastStartDate(Object.Hotel);
		If BegOfDay(vAccountingDate) = BegOfDay(Object.CheckOutDate) Then
			Items.FormCheckOutReversal.Visible = True;
			Items.FormCheckOutReversal.Enabled = True;
		Else
			If Not cmCheckUserPermissions("HavePermissionToEditCheckedOutAccommodations") Then
				Items.FormCheckOutReversal.Visible = True;
				Items.FormCheckOutReversal.Enabled = False;
			Else
				Items.FormCheckOutReversal.Visible = True;
				Items.FormCheckOutReversal.Enabled = True;
			EndIf;
		EndIf;
		Items.FormCheckOut.Visible = False;
		Items.FormCheckOut.Enabled = False;
		Items.ButtonPay.Enabled = False;
		Items.ButtonKey.Enabled = False;
	Else
		Items.FormCheckOutReversal.Visible = False;
		Items.FormCheckOutReversal.Enabled = False;
	EndIf;
	
	// Build form caption
	BuildThisObjectCaption();
	
	// Build remarks group hidden title
	BuildThisObjectRemarksDataDecoration();
	
	// Build client's decoration
	BuildThisObjectClientDataDecoration();
	
	// Commission group hidden title
	BuildCommissionGroupCollapsedTitle();
	
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle();
	
	// Build room rate group hidden title
	BuildRoomRateGroupCollapsedTitle();
	
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle();
	
	// Build discounts group hidden title
	BuildStatusGroupCollapsedTitle();
	
	// Build guest group group hidden title
	BuildGuestGroupGroupCollapsedTitle();
	
	// Fill orders
	FillOrders();
	
	// Fill document tasks presentation
	FillTasksPresentation();
	
	// Fill check-in/check-out day of week names
	If ValueIsFilled(Object.CheckInDate) Then
		CheckInDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(Object.CheckInDate)));
	Else
		CheckInDayOfWeek = "";
	EndIf;
	If ValueIsFilled(Object.CheckOutDate) Then
		CheckOutDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(Object.CheckOutDate)));
	Else
		CheckOutDayOfWeek = "";
	EndIf;
	
	// Show hide tourist tax panel
	If ValueIsFilled(Object.Hotel) And Object.Hotel.TouristTaxIsUsed Then
		Items.GroupTouristTax.Visible = True;
		If cmCheckUserPermissions("HavePermissionToEditRoomRateServices") Then
			Items.TouristicTaxExemptionReasonFillDate.ReadOnly = False;
		EndIf;
		If Object.Hotel.TouristTaxAccountingDateSettingType = Enums.TouristTaxAccountingDateSettingTypes.UseCheckInDate Or
		   Object.Hotel.TouristTaxAccountingDateSettingType = Enums.TouristTaxAccountingDateSettingTypes.UseCheckOutDate Then
			Items.TouristicTaxAccountingDate.ReadOnly = True;
		EndIf;
	Else
		Items.GroupTouristTax.Visible = False;
	EndIf;
EndProcedure // OnOpenForm

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetMealBoardTermsList(pHotel, pContract)
	vTermsList = New ValueList();
	vTerms = cmGetAllMealBoardTerms(pHotel);
	If ValueIsFilled(pContract) Then
		For Each vTermsRow In vTerms Do
			If vTermsRow.Ref = pContract.MealBoardTerm Then
				If vTermsList.FindByValue(vTermsRow.Ref) = Undefined Then
					vTermsList.Add(vTermsRow.Ref);
				EndIf;
			ElsIf pContract.MealBoardTerms.Count() > 0 Then
				If pContract.MealBoardTerms.Find(vTermsRow.Ref, "MealBoardTerm") <> Undefined Then
					If vTermsList.FindByValue(vTermsRow.Ref) = Undefined Then
						vTermsList.Add(vTermsRow.Ref);
					EndIf;
				EndIf;
			Else
				If vTermsList.FindByValue(vTermsRow.Ref) = Undefined Then
					vTermsList.Add(vTermsRow.Ref);
				EndIf;
			EndIf;
		EndDo;
	Else
		vTermsList.LoadValues(vTerms.UnloadColumn("Ref"));
	EndIf;
	Return vTermsList;
EndFunction // GetMealBoardTermsList

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildThisObjectClientDataDecoration(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	
	vRoomProperties = "";
	If vObj.RoomProperties.Count() > 0 Then
		For Each vRPRow In vObj.RoomProperties Do
			If ValueIsFilled(vRPRow.RoomProperty) Then
				If Not IsBlankString(vRoomProperties) Then
					vRoomProperties = vRoomProperties + ", " + TrimAll(vRPRow.RoomProperty.Description);
				Else
					vRoomProperties = TrimAll(vRPRow.RoomProperty.Description);
				EndIf;
			EndIf;
		EndDo;
	EndIf;

	If Items.BedsSetup.ChoiceList.FindByValue(vObj.BedsSetup) = Undefined Then
		Items.BedsSetup.ChoiceList.Add(vObj.BedsSetup);
	EndIf;
	
	Items.GroupProperties.CollapsedRepresentationTitle = NStr("en='Trip purpose: ';ru='Цель поездки: ';de='Ziel des Besuchs: '") + ?(ValueIsFilled(vObj.TripPurpose), TrimAll(vObj.TripPurpose), NStr("en='<empty>';ru='<пусто>';de='<leer>'")) + 
														 ?(ValueIsFilled(vObj.BedsSetup), " • " + NStr("en='Beds: ';ru='Кровати: ';de='Betten: '") + vObj.BedsSetup, "") + 
														 ?(Not IsBlankString(vRoomProperties), " • " + NStr("en='Room properties: ';ru='Свойства номера: ';de='Zimmer Eigenschaften: '") + vRoomProperties, "");
EndProcedure // BuildThisObjectClientDataDecoration

// -----------------------------------------------------------------------------
&AtServer
Procedure FillReservationRoomsList(pObj)
	vObj = pObj;
	If ValueIsFilled(vObj.ParentDoc) Then
		If TypeOf(vObj.ParentDoc) = Type("DocumentRef.Reservation") Then
			If vObj.ParentDoc.Rooms.Count() > 0 Then
				If ValueIsFilled(vObj.ParentDoc.ReservationStatus) Then
					If vObj.ParentDoc.ReservationStatus.IsActive Then
						vReservationRoomsList = New ValueList();
						If vObj.NumberOfRooms > 0 Then
							// We will show only vacant rooms from reservation
							vRoomsRows = vObj.ParentDoc.Rooms.FindRows(New Structure("IsUsed", False));
							If vRoomsRows.Count() > 0 Then
								For Each vRoomsRow In vRoomsRows Do
									vReservationRoomsList.Add(vRoomsRow.Room);
								EndDo;
							EndIf;
						ElsIf vObj.NumberOfAdditionalBeds > 0 Then
							// We will show all rooms from reservation
							For Each vRoomsRow In vObj.ParentDoc.Rooms Do
								vReservationRoomsList.Add(vRoomsRow.Room, cmGetRoomPresentation(vObj.Hotel, vRoomsRow.Room, CurrentSessionDate(), , , vObj.Number));
							EndDo;
						Else
							// We will show vacant and partially occupied rooms
							For Each vRoomsRow In vObj.ParentDoc.Rooms Do
								If vRoomsRow.IsUsed Then
									vOccupiedBeds = 0;
									vRoomPresentation = cmGetRoomPresentation(vObj.Hotel, vRoomsRow.Room, CurrentSessionDate(), vOccupiedBeds, , vObj.Number);
									If vOccupiedBeds < vRoomsRow.NumberOfBedsPerRoom Then
										vReservationRoomsList.Add(vRoomsRow.Room, vRoomPresentation);
									EndIf;
								Else
									vReservationRoomsList.Add(vRoomsRow.Room);
								EndIf;
							EndDo;
						EndIf;
						// Set choice list for room controls
						If vReservationRoomsList.Count() > 0 Then
							Items.Room.ChoiceListButton = True;
							Items.Room.ChoiceList.LoadValues(vReservationRoomsList.UnloadValues());
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FillReservationRoomsList

// -----------------------------------------------------------------------------
&AtServer
Procedure SetRoomQuotaAppearance(pObj)
	vObj = pObj;
	Items.RoomQuota.AutoChoiceIncomplete = False;
	Items.RoomQuota.Visible = False;
	Items.RoomQuota.Enabled = False;
	If cmGetAllRoomQuotas(, 1).Count() > 0 Then
		If ValueIsFilled(vObj.Customer) Then
			Items.RoomQuota.AutoChoiceIncomplete = True;
		EndIf;
		Items.RoomQuota.Visible = True;
		Items.RoomQuota.Enabled = True;
	EndIf;
EndProcedure // SetRoomQuotaAppearance

// -----------------------------------------------------------------------------
&AtServer
Function FillArrayOfPaymentMethods()
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	PaymentMethods.Ref AS Ref
	|FROM
	|	Catalog.PaymentMethods AS PaymentMethods
	|WHERE
	|	NOT PaymentMethods.DeletionMark
	|	AND NOT PaymentMethods.IsForReturnOnly
	|	AND (PaymentMethods.IsByCreditCard
	|			OR PaymentMethods.IsByCash
	|			OR PaymentMethods.IsByBankTransfer
	|			OR PaymentMethods.IsByGiftCertificate
	|			OR PaymentMethods.IsByBonuses
	|			OR PaymentMethods.IsViaInternetAcquiring
	|			OR PaymentMethods.Ref = VALUE(Catalog.PaymentMethods.Settlement))
	|
	|ORDER BY
	|	PaymentMethods.SortCode";
	vResult = vQry.Execute().Select();
	vArrayOfPaymentMethods = New Array;
	While vResult.Next() Do
		vArrayOfPaymentMethods.Add(vResult.Ref);
	EndDo;
	// Return
	Return vArrayOfPaymentMethods;
EndFunction // FillArrayOfPaymentMethods

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckPermissions(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	// Set user rights for some controls
	Items.IsClosedForEdit.Enabled = True;
	Items.Room.ReadOnly = False;
	Items.RoomType.ReadOnly = False;
	Items.Room.TextColor = New Color;
	If vObj.IsClosedForEdit Then
		If ValueIsFilled(vObj.Room) Then
			Items.Room.TextColor = WebColors.Red;
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditClosedForEditDocuments") Then
		Items.IsClosedForEdit.Enabled = False;
		If vObj.IsClosedForEdit Then
			If ValueIsFilled(vObj.Room) Then
				Items.Room.ReadOnly = True;
				Items.RoomType.ReadOnly = False;
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(vObj.AccommodationStatus) Then
		If Not vObj.AccommodationStatus.IsInHouse And vObj.Posted Then
			// Open document read only if user do not have appropriate rights
			If Not cmCheckUserPermissions("HavePermissionToEditCheckedOutAccommodations") Then
				DoFormReadOnly();
			EndIf;
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToChangeCustomerInDocuments") Then
		If Not vObj.IsNew() Then
			Items.Customer.ReadOnly = True;
			Items.Customer.ChoiceButton = False;
			Items.Customer.ClearButton = False;
			Items.Contract.ReadOnly = True;
			Items.Contract.ChoiceButton = False;
			Items.Contract.ClearButton = False;
			Items.Agent.ReadOnly = True;
			Items.Agent.ChoiceButton = False;
			Items.Agent.ClearButton = False;
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditGuestGroup") Then
		Items.GuestGroup.ReadOnly = True;
		Items.GuestGroup.ChoiceButton = False;
		Items.GuestGroup.ClearButton = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditAccommodationDocumentNumberAndDate") Then
		Items.Number.Enabled = False;
		Items.Date.Enabled = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToAddManualPrices") And Not cmCheckUserPermissions("HavePermissionToDoRoomTypeUpgrade") Then
		Items.IsManualRoomPrice.Enabled = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToAddManualPrices") Then
		Items.RoomPrice.Enabled = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToDoRoomTypeUpgrade") Then
		Items.RoomTypeUpgrade.Enabled = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToAddManualDiscounts") Then
		Items.DiscountType.Enabled = True;
		Items.DiscountType.Visible = True;
		Items.DiscountType.TitleLocation = FormItemTitleLocation.None;
		Items.Discount.Enabled = True;
		Items.Discount.Visible = True;
		Items.Discount.ReadOnly = True;
		Items.Discount.ChoiceButton = False;
		Items.DiscountServiceGroup.Enabled = False;
		Items.RoomRatesDiscount.ReadOnly = True;
	Else
		Items.DiscountType.Enabled = True;
		Items.DiscountType.Visible = True;
		Items.DiscountType.TitleLocation = FormItemTitleLocation.None;
		Items.Discount.Enabled = True;
		Items.Discount.Visible = True;
		Items.Discount.ReadOnly = False;
		Items.Discount.ChoiceButton = True;
		Items.DiscountServiceGroup.Enabled = True;
		Items.RoomRatesDiscount.ReadOnly = False;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditCheckInDateTimeInPast") Then
		vHrs = cmGetRoomExaminationFreeOfChargeTime();
		vHrs = ?(vHrs = 0, 24, vHrs);
		If (CurrentSessionDate() - vObj.CheckInDate) > (vHrs*3600) Then // more then one day after check in
			Items.CheckInDate.Enabled = False;
			Items.CheckInTime.Enabled = False;
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditAccommodationCheckInDate") Then
		If Not ValueIsFilled(vObj.ParentDoc) Or 
		   TypeOf(vObj.ParentDoc) = Type("DocumentRef.Reservation") Then
			Items.CheckInDate.Enabled = False;
			Items.CheckInTime.Enabled = False;
		EndIf;
	EndIf;
	// Check user rights to edit accommodations
	If Not cmCheckUserPermissions("HavePermissionToEditAccommodations") Then
		If Not vObj.IsNew() And 
		  (Not ValueIsFilled(vObj.Author.Department) And vObj.Author <> SessionParameters.CurrentUser Or 
		   ValueIsFilled(vObj.Author.Department) And vObj.Author <> SessionParameters.CurrentUser And 
		   ValueIsFilled(SessionParameters.CurrentUser) And Not ValueIsFilled(SessionParameters.CurrentUser.Department) Or 
		   ValueIsFilled(vObj.Author.Department) And vObj.Author <> SessionParameters.CurrentUser And 
		   ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Department) And 
		   vObj.Author.Department <> SessionParameters.CurrentUser.Department) Then
			DoFormReadOnly();
		EndIf;
	EndIf;
EndProcedure // CheckPermissions

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetMainRoomDocument(pNumber, pRoom, pGuestGroup)
	Return cmGetMainRoomAccommodation(pNumber, pGuestGroup, pRoom);
EndFunction // GetMainRoomDocument

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetNumberOfMessagesForObject(pDocRef)
	Return cmGetNumberOfMessagesForObject(pDocRef);
EndFunction // GetNumberOfMessagesForObject

// -----------------------------------------------------------------------------
&AtServer
Function BeforeOpenCheckPermissions()
	If IsNew Then
		// Check user rights to create new accommodations
		If Not cmCheckUserPermissions("HavePermissionToCreateNewAccommodations") Then
			Return NStr("en='You do not have rights to create new accommodations!';ru='Нет прав на создание новых размещений!';de='Sie haben keine Rechte, neue Unterbringungen vorzunehmen!'");
		EndIf;
	EndIf;
	// User rights to open item
	If Not IsInRole("RightsToChooseHotel") Then
		If ValueIsFilled(Object.Hotel) And SessionParameters.CurrentHotel <> Object.Hotel Then
			Return NStr("en='You do not have rights to view documents of choosen hotel!';ru='Нет прав на доступ к данным этого отеля!';de='Sie haben keine Rechte für einen Zugang zu den Daten dieses Hotels!'");
		EndIf;
	EndIf;	
	Return "";
EndFunction // BeforeOpenCheckPermissions

// -----------------------------------------------------------------------------
&AtServer
Procedure SetRoomInterfacesFilter(pObj)
	If pObj.IsNew() Or Not pObj.Posted Then
		Items.GroupRoomInterfaces.Visible = False;
	Else
		Items.GroupRoomInterfaces.Visible = True;
		// Reset filter
		RoomInterfaces.Filter.Items.Clear();
		// Filter by accommodation or by room
		vFlt = RoomInterfaces.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vFlt.LeftValue = new DataCompositionField("ParentDoc");
		vFlt.ComparisonType = DataCompositionComparisonType.Equal;
		vFlt.RightValue = pObj.Ref;
		vFlt.Use = True;
	EndIf;
EndProcedure // SetRoomInterfacesFilter

// -----------------------------------------------------------------------------
&AtServer
Function GetVauchersFunctionalOption()
	vUseVauchers = False;
	vHotel = Object.Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		vUseVauchers = GetFunctionalOption("Vauchers", New Structure("Hotel", vHotel));
	EndIf;
	Return vUseVauchers;
EndFunction // CheckVauchersFunctionalOption

// -----------------------------------------------------------------------------
&AtServer
Function GetBedsSetupFunctionalOption()
	vUseBedsSetups = False;
	vHotel = Object.Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		vUseBedsSetups = GetFunctionalOption("BedsSetups", New Structure("Hotel", vHotel));
	EndIf;
	Return vUseBedsSetups;
EndFunction // GetBedsSetupFunctionalOption

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure FillTypesTableAtServer(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	ValueToFormAttribute(vObj.pmFillTypesTable(), "TypesTable");
	If ValueIsFilled(vObj.RoomType) Then
		vTypes = GetTypesArrayByRoomType(vObj.RoomType);
		Items.AccommodationType.ChoiceList.LoadValues(vTypes);
		For Each vGRow In GuestsInGroup Do
			Items["AccommodationType" + Format(GuestsInGroup.IndexOf(vGRow) + 2, "NFD=0; NG=")].ChoiceList.LoadValues(vTypes);
		EndDo;
	EndIf;
EndProcedure // FillTypesTableAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillAccommodationStatusListChoice()
	Items.AccommodationStatus.ChoiceList.Clear();
	vCurAccommodationStatus = Object.AccommodationStatus;
	vAccommodationStatusesArray = New Array;
	If ValueIsFilled(tcOnServer.cmGetCurrentUserAttribute("Customer")) Then
		vAccommodationStatusesArray.Add(tcOnServer.cmGetCurrentHotelAttribute("CheckInAccommodationStatus"));
		vAccommodationStatusesArray.Add(GetAccommodationAnnulationStatus(Object.Ref));
	Else
		vAccommodationStatusesArray = GetAllAccommodationStatuses();
	EndIf;
	
	For Each vAccommodationStatus In vAccommodationStatusesArray Do
		If vCurAccommodationStatus.IsActive Then
			If vCurAccommodationStatus.IsInHouse Then
				If Not vAccommodationStatus.IsActive Then
					Items.AccommodationStatus.ChoiceList.Add(vAccommodationStatus, , , GetAccommodationStatusIcon(vAccommodationStatus));
				EndIf;
			Else
				Items.AccommodationStatus.ChoiceList.Add(vAccommodationStatus, , , GetAccommodationStatusIcon(vAccommodationStatus));
			EndIf;
		Else
			Items.AccommodationStatus.ChoiceList.Add(vAccommodationStatus, , , GetAccommodationStatusIcon(vAccommodationStatus));
		EndIf;
	EndDo;
	
	If ValueIsFilled(Object.AccommodationStatus) And Items.AccommodationStatus.ChoiceList.FindByValue(Object.AccommodationStatus) = Undefined Then
		Items.AccommodationStatus.ChoiceList.Add(Object.AccommodationStatus, , , GetAccommodationStatusIcon(Object.AccommodationStatus));
	EndIf;
EndProcedure // FillAccommodationStatusListChoice

// -----------------------------------------------------------------------------
&AtServer
Function GetAccommodationStatusIcon(pAccommodationStatus)
	vPicture = PictureLib.Empty;
	If ValueIsFilled(pAccommodationStatus) Then
		If pAccommodationStatus.IsActive Then
			If pAccommodationStatus.IsCheckIn And pAccommodationStatus.IsInHouse Then
				vPicture = PictureLib.CheckIn;
			ElsIf pAccommodationStatus.IsRoomChange And pAccommodationStatus.IsInHouse Then
				vPicture = PictureLib.ChangeRoom;
			Else
				vPicture = PictureLib.CheckOut;
			EndIf;
		Else
			vPicture = PictureLib.IsNotActive;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // GetAccommodationStatusIcon

// -----------------------------------------------------------------------------
&AtServer
Procedure AddCustomFields()
	// Get list of custom fields
	vCustFields = cmGetListOfReservationCustomFields();
	// Create custom fields form attributes
	vCustAttrArray = New Array();
	For Each vCustFieldsRow In vCustFields Do
		If Not vCustFieldsRow.IsFolder Then
			vCustAttrArray.Add(New FormAttribute(TrimAll(vCustFieldsRow.Code), vCustFieldsRow.ValueType));
		EndIf;
	EndDo;		
	ChangeAttributes(vCustAttrArray);
	// Create form items
	vParentGroup = Items.GroupCustomFields;
	For Each vCustFieldsRow In vCustFields Do
		If vCustFieldsRow.IsFolder Then
			vGroup = Items.Add(TrimAll(vCustFieldsRow.Code), Type("FormGroup"), Items.GroupCustomFields);
			vGroup.Title = cmNStr(TrimAll(vCustFieldsRow.Description), SessionParameters.CurrentLanguage);
			vGroup.Type = FormGroupType.UsualGroup;
			vGroup.Representation = UsualGroupRepresentation.None;
			vGroup.Behavior = UsualGroupBehavior.Collapsible;
			vGroup.ControlRepresentation = UsualGroupControlRepresentation.Picture;
			vGroup.Group = ChildFormItemsGroup.Vertical;
			vGroup.ChildItemsWidth = ChildFormItemsWidth.Auto;
			vGroup.ShowTitle = True;
			vParentGroup = vGroup;
		Else
			vField = Items.Add(TrimAll(vCustFieldsRow.Code), Type("FormField"), vParentGroup);
			vField.DataPath = TrimAll(vCustFieldsRow.Code);
			vField.Title = cmNStr(TrimAll(vCustFieldsRow.Description), SessionParameters.CurrentLanguage);
			vField.ToolTip = cmNStr(TrimAll(vCustFieldsRow.Remarks), SessionParameters.CurrentLanguage);			
			If vCustFieldsRow.ValueType = cmGetBooleanTypeDescription() Then
            	vField.Type = FormFieldType.CheckBoxField;
				vField.TitleLocation = FormItemTitleLocation.Right;
			Else  
				vField.Type = FormFieldType.InputField;
				vField.TitleLocation = FormItemTitleLocation.Left;
				vField.OpenButton = False;
				If vCustFieldsRow.ValueType = cmGetNumberTypeDescription(vCustFieldsRow.ValueType.NumberQualifiers.Digits, vCustFieldsRow.ValueType.NumberQualifiers.FractionDigits) Then
					vField.ChoiceButton = True;
					vField.ClearButton = False;
					If vCustFieldsRow.ValueType.NumberQualifiers.FractionDigits <> 2 Then
						vField.EditFormat = "NG=";
					EndIf;
				ElsIf vCustFieldsRow.ValueType = cmGetDateTypeDescription() Then
					vField.ChoiceButton = True;
					vField.ClearButton = False;
				ElsIf vCustFieldsRow.ValueType = cmGetCatalogTypeDescription("ICD10") Or 
					  vCustFieldsRow.ValueType = cmGetCatalogTypeDescription("Currencies") Or 
					  vCustFieldsRow.ValueType = cmGetCatalogTypeDescription("Customers") Or 
					  vCustFieldsRow.ValueType = cmGetCatalogTypeDescription("Contracts") Or 
					  vCustFieldsRow.ValueType = cmGetCatalogTypeDescription("Cities") Or 
					  vCustFieldsRow.ValueType = cmGetCatalogTypeDescription("Countries") Or 
					  vCustFieldsRow.ValueType = cmGetCatalogTypeDescription("Places") Or 
					  vCustFieldsRow.ValueType = cmGetCatalogTypeDescription("Regions") Or 
					  vCustFieldsRow.ValueType = cmGetCatalogTypeDescription("GuestVehicles") Then
					vField.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInDropList;
					vField.CreateButton = False;
					vField.ClearButton = True;
					vField.OpenButton = True;   
					If Not IsBlankString(vCustFieldsRow.Ref.ChoiceParametersLinks) Then
						vAtArr = StrSplit(vCustFieldsRow.Ref.ChoiceParametersLinks, ";", False); 
						vFilterArr = New Array;
						For Each vRow In vAtArr Do	
							vFl = StrReplace(vRow, "(", "");
							vFl = StrReplace(vFl, ")", "");   
							vFilterParams = StrSplit(vFl, ",", False);  
							If vFilterParams.Count()>1 Then
								vFilterArr.Add(New ChoiceParameterLink(TrimAll(vFilterParams[0]),TrimAll(vFilterParams[1])));      
							EndIf;
						EndDo;
						If vFilterArr.Count() > 0 Then
							vField.ChoiceParameterLinks = New FixedArray(vFilterArr); 
						EndIf;
					EndIf;
					If Not IsBlankString(vCustFieldsRow.Ref.ChoiceParameters) Then
						vAtArr = StrSplit(vCustFieldsRow.Ref.ChoiceParameters, ";", False); 
						vFilterArr = New Array;
						For Each vRow In vAtArr Do	
							vFl = StrReplace(vRow, "(", "");
							vFl = StrReplace(vFl, ")", "");   
							vFilterParams = StrSplit(vFl, ",", False);  
							If vFilterParams.Count()>1 Then
								vFilterArr.Add(New ChoiceParameter(TrimAll(vFilterParams[0]),TrimAll(vFilterParams[1])));      
							EndIf;
						EndDo;
						If vFilterArr.Count() > 0 Then
							vField.ChoiceParameters = New FixedArray(vFilterArr); 
						EndIf;
					EndIf;	
					If vCustFieldsRow.ValueType = cmGetCatalogTypeDescription("ICD10") Then
						vField.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
					EndIf;
				Else // Type is String
					vField.ChoiceButton = False;
					vField.ClearButton = True;
					If Not IsBlankString(vCustFieldsRow.ChoiceListValues) Then
						vValuesArray = StrSplit(TrimAll(vCustFieldsRow.ChoiceListValues), ";", False);
						If vValuesArray.Count() > 0 Then
							vField.ChoiceList.LoadValues(vValuesArray);
							vField.ListChoiceMode = True;
						EndIf;
					EndIf;
					If vCustFieldsRow.FillChoiceListFromHistory Then
						vValues = cmGetReservationCustomFieldHistoryValuesList(TrimAll(vCustFieldsRow.Code));
						For Each vValuesItem In vValues Do
							vField.ChoiceList.Add(vValuesItem.Value);
						EndDo;
						vField.ListChoiceMode = False;
						vField.DropListButton = True;
					EndIf;
				EndIf;
				vField.AutoMaxWidth = True;
			EndIf;
			If vCustFieldsRow.ShowCaptionAboveTheField Then
				vField.TitleLocation = FormItemTitleLocation.Top;
			EndIf;
			If vCustFieldsRow.IsMultiline And vCustFieldsRow.ValueType = cmGetStringTypeDescription() Then
				vField.MultiLine = True;
			EndIf;
			vField.SetAction("OnChange", "CustomFieldOnChange");
			CustomFieldsList.Add(vCustFieldsRow.Ref, TrimAll(vCustFieldsRow.Code));
		EndIf;
	EndDo;
EndProcedure // AddCustomFields

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCustomFields()
	// Read custom field values for the current document
	vRef = Object.Ref;
	If Not ValueIsFilled(vRef) Then
		vRef = Object.Reservation;
	EndIf;
	If ValueIsFilled(vRef) Then
		vCustFieldsValues = cmGetReservationCustomFieldsValues(vRef);
		For Each vCustFieldsValuesRow In vCustFieldsValues Do
			ThisObject[TrimAll(vCustFieldsValuesRow.CharacteristicCode)] = vCustFieldsValuesRow.CharacteristicValue;
		EndDo;
	EndIf;
EndProcedure // FillCustomFields

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveCustomFields(pRef)
	vRef = pRef;
	If TypeOf(vRef) = Type("DocumentRef.Accommodation") And 
	   ValueIsFilled(vRef.Reservation) Then
		vRef = pRef.Reservation;
	EndIf;
	For Each CustomFieldsListItem In CustomFieldsList Do
		vRcdMgr = InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
		vRcdMgr.Owner = vRef;
		vRcdMgr.Characteristic = CustomFieldsListItem.Value;
		vRcdMgr.CharacteristicValue = ThisObject[CustomFieldsListItem.Presentation];
		vRcdMgr.Write(True);
	EndDo;
EndProcedure // SaveCustomFields

// -----------------------------------------------------------------------------
&AtServer
Function NewGroupProformaInvoice(pFormData,pThinClient)
	If pThinClient Then
		vInvObj = FormDataToValue(pFormData, Type("DocumentObject.ProformaInvoice"));
		vInvObj.Fill(Object.Ref);
		vInvObj.ParentDoc = Undefined;
		vInvObj.Fill(Object.GuestGroup);
		ValueToFormData(vInvObj, pFormData);
	Else
		vObj = FormAttributeToValue("Object");
		vInvObj = Documents.ProformaInvoice.CreateDocument();
		vInvObj.Fill(vObj.Ref);
        vInvObj.ParentDoc = Undefined;
		vInvObj.Fill(vObj.GuestGroup);
		Return vInvObj;
	EndIf
EndFunction // NewGroupProformaInvoice

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearOccupationPercentAtServer(pDate = Undefined, pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	If pDate = Undefined Then
		vObj.pmClearOccupationPercents();
	Else
		i = 0;
		While i < vObj.OccupationPercents.Count() Do
			vOccupationPercentsRow = vObj.OccupationPercents.Get(i);
			If vOccupationPercentsRow.AccountingDate >= BegOfDay(pDate) Then
				vObj.OccupationPercents.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // ClearOccupationPercentAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearOccupationPercents(pDate = Undefined, pRoomRate = Undefined, pOldRoomType = Undefined, pNewRoomType = Undefined, pDoClear = False)
	vRoomRate = pRoomRate;
	If Not ValueIsFilled(pRoomRate) Then
		vRoomRate = Object.RoomRate;
	EndIf;
	If ValueIsFilled(vRoomRate) Then
		vRoomRatePriceTagType = tcOnServer.cmGetAttributeByRef(vRoomRate, "PriceTagType");
		vDoNotRefillOccupationPercentsAfterInHouseRoomChange = tcOnServer.cmGetAttributeByRef(Object.RoomRate, "DoNotRefillOccupationPercentsAfterInHouseRoomChange");
		If Not vDoNotRefillOccupationPercentsAfterInHouseRoomChange Then
			If vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomType") Or 
			   vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType") Then
				ClearOccupationPercentAtServer(pDate);
			ElsIf vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomClass") Then
				If pDoClear Then
					ClearOccupationPercentAtServer(pDate);
				Else
					vOldRoomType = pOldRoomType;
					If pOldRoomType = Undefined Then
						If ValueIsFilled(Object.Ref) Then
							vOldRoomType = tcOnServer.cmGetAttributeByRef(Object.Ref, "RoomType");
						ElsIf ValueIsFilled(Object.Reservation) Then
							vOldRoomType = tcOnServer.cmGetAttributeByRef(Object.Reservation, "RoomType");
						EndIf;
					EndIf;
					vNewRoomType = pNewRoomType;
					If pNewRoomType = Undefined And ValueIsFilled(Object.RoomType) Then
						vNewRoomType = Object.RoomType;;
					EndIf;
					If ValueIsFilled(vOldRoomType) And ValueIsFilled(vNewRoomType) Then
						vOldRoomTypeClass = tcOnServer.cmGetAttributeByRef(pOldRoomType, "RoomClass");
						vNewRoomTypeClass = tcOnServer.cmGetAttributeByRef(pNewRoomType, "RoomClass");
						If vOldRoomTypeClass <> vNewRoomTypeClass Then
							ClearOccupationPercentAtServer(pDate);
						EndIf;
					Else
						ClearOccupationPercentAtServer(pDate);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ClearOccupationPercents

// -----------------------------------------------------------------------------
&AtServer
Procedure GetDefaultRoomAtServer(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	vObj.Room = cmGetDefaultRoom(vObj.NumberOfBeds, vObj.Hotel, vObj.Company, vObj.RoomQuota, vObj.RoomType, vObj.CheckInDate, vObj.CheckOutDate, vObj.Guest);
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // GetDefaultRoomAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetTypesArrayByRoomType(pRoomType)
	vTypesTable = FormAttributeToValue("TypesTable");
	vTypesArray = vTypesTable.FindRows(New Structure("RoomType", pRoomType));
	vTypes = New Array;
	For Each vType In vTypesArray Do
		vTypes.Add(vType.AccommodationType);
	EndDo;
	Return vTypes;
EndFunction // GetTypesArrayByRoomType

// -----------------------------------------------------------------------------
&AtServer
Function PayerOnChangeAtServer()
	If Payer = Enums.WhoPays.Guest Then
		Items.GroupChargingRules.Hide();
		RemoveCustomerChargingRules();
		ChargingRulesAfterDeleteRowAtServer();
		BuildAccountingGroupCollapsedTitle();
		BuildRoomRateGroupCollapsedTitle();
		BuildDiscountsGroupCollapsedTitle();
		Return False;
	ElsIf Payer = Enums.WhoPays.Customer Then
		Items.GroupChargingRules.Hide();
		If Not ValueIsFilled(Object.Customer) Then
			BuildAccountingGroupCollapsedTitle();
			BuildRoomRateGroupCollapsedTitle();
			BuildDiscountsGroupCollapsedTitle();
		    Return True;
		Else
			AddBankTransferCR();
			BuildAccountingGroupCollapsedTitle();
			BuildRoomRateGroupCollapsedTitle();
			BuildDiscountsGroupCollapsedTitle();
			Return False;
		EndIf;
	ElsIf Payer = Enums.WhoPays.Agent Then
		Items.GroupChargingRules.Hide();
		If Not ValueIsFilled(Object.Agent) Then
			BuildAccountingGroupCollapsedTitle();
			BuildRoomRateGroupCollapsedTitle();
			BuildDiscountsGroupCollapsedTitle();
		    Return True;
		Else
			AddBankTransferCR(, True);
			BuildAccountingGroupCollapsedTitle();
			BuildRoomRateGroupCollapsedTitle();
			BuildDiscountsGroupCollapsedTitle();
			Return False;
		EndIf;
	ElsIf Payer = Enums.WhoPays.ChargingRules Then
		Items.GroupChargingRules.Show();
		If ValueIsFilled(Object.Customer) Then
			vBankTransferCRIsFound = False;
			For Each vCRRow In Object.ChargingRules Do
				If ValueIsFilled(vCRRow.Owner) And (TypeOf(vCRRow.Owner) = Type("CatalogRef.Customers") Or TypeOf(vCRRow.Owner) = Type("CatalogRef.Contracts")) Then
					vBankTransferCRIsFound = True;
					Break;
				EndIf;
			EndDo;
			If Not vBankTransferCRIsFound Then
				AddBankTransferCR(True);
			EndIf;
		EndIf;
		BuildAccountingGroupCollapsedTitle();
		BuildRoomRateGroupCollapsedTitle();
		BuildDiscountsGroupCollapsedTitle();
		Return False;
	EndIf;
EndFunction // PayerOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ChargingRulesAfterDeleteRowAtServer()
	// Check that charging rules are not empty
	If Object.ChargingRules.Count() = 0 Then
		// Initialize charging rules by default
		LoadDefaultChargingRulesAtServer();
	Else
		// Check if there is base rule
		vBaseRuleFound = False;
		For Each vCRRow In Object.ChargingRules Do
			If Not ValueIsFilled(vCRRow.Owner) And vCRRow.ChargingRule = Enums.ChargingRuleTypes.Any Then
				vBaseRuleFound = True;
			EndIf;
		EndDo;
		If Not vBaseRuleFound Then
			// Initialize charging rules by default
			LoadDefaultChargingRulesAtServer();
		Else
			// Get object value
			vObj = FormAttributeToValue("Object");
			// Automatic services list calculation	
			vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
			// Set planned payment method from the first charging rule
			Payer = vObj.pmSetPlannedPaymentMethod(TPayer);
			If Payer = Enums.WhoPays.ChargingRules Then
				Items.GroupChargingRules.Show();
			Else
				Items.GroupChargingRules.Hide();
			EndIf;
			// Set object value
			ValueToFormAttribute(vObj, "Object");	
			// Calculate totals
			TotalSum = CalculateTotalServices(, , False, False);
		EndIf;
	EndIf;
	ThisObject.Modified = True;
EndProcedure // ChargingRulesAfterDeleteRowAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadDefaultChargingRulesAtServer()
	If ValueIsFilled(Object.Hotel) Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		// Load default charging rules
		vObj.pmLoadDefaultChargingRules();
		// Automatic services list calculation	
		vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));	
		// Set planned payment method from the first charging rule
		Payer = vObj.pmSetPlannedPaymentMethod(TPayer);
		// Set object value
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		TotalSum = CalculateTotalServices(, , False, False);
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("ru='Не выбрана гостиница!';de='Kein Hotel ist gewählt!';en='Hotel is not filled!'"));
	EndIf;
	ThisObject.Modified = True;
EndProcedure // LoadDefaultChargingRulesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RemoveCustomerChargingRules(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(vObj.Hotel) And ValueIsFilled(vObj.GuestGroup) Then
		i = 0;
		While i < vObj.ChargingRules.Count() Do
			vCRRow = vObj.ChargingRules.Get(i);
			If ValueIsFilled(vCRRow.Owner) And 
			  (TypeOf(vCRRow.Owner) = Type("CatalogRef.Customers") Or TypeOf(vCRRow.Owner) = Type("CatalogRef.Contracts")) Then
				// Check if hotel base charging rules have row with rule equal to the current one
				vBaseRuleIsFound = False;
				If ValueIsFilled(vObj.Hotel) And vObj.Hotel.ChargingRules.Count() > 0 And 
				   ValueIsFilled(vCRRow.ChargingFolio) And Not vCRRow.ChargingFolio.IsMaster Then
					// Try to find hotel template rule of the same type
					vHotelCRRows = vObj.Hotel.ChargingRules.FindRows(New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate", vCRRow.ChargingRule, vCRRow.ChargingRuleValue, vCRRow.ValidFromDate, vCRRow.ValidToDate));
					If vHotelCRRows.Count() = 1 Then
						vBaseRuleIsFound = True;
						vHotelCRRow = vHotelCRRows.Get(0);
						// Update charging folio
						vFolioObj = vCRRow.ChargingFolio.GetObject();
						cmFillFolioFromTemplate(vFolioObj, vHotelCRRow.ChargingFolio, vObj.Hotel, vObj.Date);
						If Not ValueIsFilled(vFolioObj.ParentDoc) Or 
						   ValueIsFilled(vFolioObj.ParentDoc) And TypeOf(vFolioObj.ParentDoc) <> Type("DocumentRef.Accommodation") Then
							vFolioObj.ParentDoc = vObj.Ref;
						EndIf;
						If Not vFolioObj.DoNotUpdateCompany Then
							vFolioObj.Company = vObj.Company;
						EndIf;
						vFolioObj.Client = vObj.Guest;
						vFolioObj.GuestGroup = vObj.GuestGroup;
						vFolioObj.DateTimeFrom = vObj.CheckInDate;
						vFolioObj.DateTimeTo = vObj.CheckOutDate;
						vFolioObj.Customer = Catalogs.Customers.EmptyRef();
						vFolioObj.Contract = Catalogs.Contracts.EmptyRef();
						vFolioObj.Write(DocumentWriteMode.Write);
						// Update owner
						vIsTransfer = vCRRow.IsTransfer;
						vCRRow.Owner = GetChargingRuleOwnerByFolioAtServer(Object.Ref, vCRRow.ChargingFolio, vIsTransfer);
						vCRRow.IsTransfer = vIsTransfer;
					EndIf;
				EndIf;
				If Not vBaseRuleIsFound Then
					vObj.ChargingRules.Delete(i);
				Else
					i = i + 1;
				EndIf;
			Else
				i = i + 1;
			EndIf;
		EndDo;
		cmUpdateChargingRulesFoliosLineNumbers(vObj.ChargingRules);
	EndIf;
EndProcedure // RemoveCustomerChargingRules

// -----------------------------------------------------------------------------
&AtServer
Procedure AddBankTransferCR(pDoNotRefillPayer = False, pPayerIsAgent = False)
	If ValueIsFilled(Object.Hotel) Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		// Add bank transfer charging rule
		vObj.pmAddBankTransferChargingRule(pPayerIsAgent);
		// Automatic services list calculation	
		vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
		// Set planned payment method from the first charging rule
		If Not pDoNotRefillPayer Then
			Payer = vObj.pmSetPlannedPaymentMethod(TPayer);
			If Payer = Enums.WhoPays.ChargingRules Then
				Items.GroupChargingRules.Show();
			Else
				Items.GroupChargingRules.Hide();
			EndIf;
		EndIf;
		// Set object value
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		TotalSum = CalculateTotalServices(, , False, False);
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("ru='Не выбрана гостиница!';de='Kein Hotel ist gewählt!';en='Hotel is not filled!'"));
	EndIf;
EndProcedure // AddBankTransferCR

// -----------------------------------------------------------------------------
&AtServer
Function CalculateTotalServices(pObj = Undefined, pIsOnOpenMode = False, pSetNeedServicesRecalculation = True, pForceServicesRecalculation = False, pShowMessages = False)
	NeedServicesRecalculation = pSetNeedServicesRecalculation;
	// Check parameters
	vObj = pObj;
	vUseParameterObject = True;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// We have to group all amounts by currencies
	vResortFeeStr = "";
	vPricePresentation = "";
	vTotalStr = GetTotalSumPresentation(vObj, False, vPricePresentation, pIsOnOpenMode, pForceServicesRecalculation, pShowMessages, vResortFeeStr);
	PricePresentation = vPricePresentation;
	// Calculate discount description
	DiscountDescription = "";
	If ValueIsFilled(vObj.PayerAccommodation) Then
		DiscountDescription = DiscountDescription + NStr("en='Payer: ';ru='Плательщик: ';de='Zahler: '") + TrimAll(vObj.PayerAccommodation.Room) + ", " + TrimAll(vObj.PayerAccommodation.Guest) + "; ";
	Else
		If Not IsBlankString(TPayer) Then
			DiscountDescription = DiscountDescription + NStr("en='Payer: ';ru='Плательщик: ';de='Zahler: '") + TPayer + "; ";
		EndIf;
	EndIf;
	If vObj.IsByReservation Then
		vReservation = vObj.pmGetParentReservation();
		If ValueIsFilled(vReservation) Then
			DiscountDescription = DiscountDescription + NStr("en='By reservation N ';ru='По брони № ';de='Nach Reservierung Nr. '") + TrimAll(vReservation.Number) + " (" + Format(vReservation.Date, "DF=dd.MM.yyyy") + ")" + "; ";
		EndIf;
	EndIf;
	If vObj.Discount <> 0 Then
		If IsBlankString(vObj.DiscountConfirmationText) Then
			If ValueIsFilled(vObj.DiscountType) Then
				DiscountDescription = DiscountDescription + NStr("en='Discount ';ru='Скидка ';de='Preisnachlass '") + Format(vObj.Discount, "ND=10; NFD=2; NZ=; NG=") + "% - " + TrimAll(vObj.DiscountType) + "; ";
			Else
				DiscountDescription = DiscountDescription + NStr("en='Discount ';ru='Скидка ';de='Preisnachlass '") + Format(vObj.Discount, "ND=10; NFD=2; NZ=; NG=") + "% - " + NStr("en='Manual discount';ru='Ручная скидка';de='Manueller Preisnachlass'") + "; ";
			EndIf;
		Else
			DiscountDescription = DiscountDescription + NStr("en='Discount ';ru='Скидка ';de='Preisnachlass '") + Format(vObj.Discount, "ND=10; NFD=2; NZ=; NG=") + "% - " + TrimAll(vObj.DiscountConfirmationText) + "; ";
		EndIf;
	ElsIf vObj.DiscountSum <> 0 Then
		If IsBlankString(vObj.DiscountConfirmationText) Then
			DiscountDescription = DiscountDescription + NStr("en='Discount is ';ru='Скидка на ';de='Preisnachlass auf '") + Format(vObj.DiscountSum, "ND=17; NFD=2; NZ=") + " - " + TrimAll(vObj.DiscountType) + "; ";
		Else
			DiscountDescription = DiscountDescription + NStr("en='Discount is ';ru='Скидка на ';de='Preisnachlass auf '") + Format(vObj.DiscountSum, "ND=17; NFD=2; NZ=") + " - " + TrimAll(vObj.DiscountConfirmationText) + "; ";
		EndIf;
	EndIf;
	If Not IsBlankString(vObj.PricePresentation) Then
		DiscountDescription = DiscountDescription + vObj.PricePresentation;
	EndIf;
    // Calculate manual price presentation
	ManualPricePresentation = NStr("en='N/A';ru='N/A';de='N/D'");
	If vObj.Prices.Count() > 0 Then
		vFirstRow = vObj.Prices.Get(0);
		ManualPricePresentation = cmFormatSum(vFirstRow.Price, vFirstRow.Currency);
		If vObj.Prices.Count() > 1 Then
			ManualPricePresentation = ManualPricePresentation + " ...";
		EndIf;
	Else
		If vObj.RoomRates.Count() > 0 Then
			vFirstRow = vObj.RoomRates.Get(0);
			If ValueIsFilled(vFirstRow.RoomRate) Then
				ManualPricePresentation = TrimAll(vFirstRow.RoomRate.Code) + " " + Format(vFirstRow.AccountingDate, "DF=dd.MM.yy");
			ElsIf ValueIsFilled(vFirstRow.AccommodationType) Then
				ManualPricePresentation = TrimAll(vFirstRow.AccommodationType.Code) + " " + Format(vFirstRow.AccountingDate, "DF=dd.MM.yy");
			EndIf;
			If vObj.RoomRates.Count() > 1 Then
				ManualPricePresentation = ManualPricePresentation + " ...";
			EndIf;
		EndIf;
	EndIf;
	BuildDiscountsGroupCollapsedTitle(vObj);
	If vUseParameterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	Items.DecorationTotalSum.Title = vTotalStr;
	Items.DecorationResortFee.Title = vResortFeeStr;
	// Fill calculated columns in Object.Services and totals
	If pObj = Undefined Then
		CalculateServicesFooterTotals();
	EndIf;
	// Return
	Return vTotalStr;
EndFunction // CalculateTotalServices

// -----------------------------------------------------------------------------
&AtServer
Procedure CalculateServicesFooterTotals()
	FixedChargesTotalCommissionSum = 0;
	FixedChargesTotalDiscountSum = 0;
	FixedChargesTotalSum = 0;
	FixedChargesTotalSumWithDiscount = 0;
	FixedChargesTotalVATSum = 0;
	
	ServicesTotalCommissionSum = 0;
	ServicesTotalDiscountSum = 0;
	ServicesTotalSum = 0;
	ServicesTotalSumWithDiscount = 0;
	ServicesTotalVATSum = 0;
	
	For Each vSrvRow In Object.Services Do
		vSrvRow.SumWithDiscount = vSrvRow.Sum - vSrvRow.DiscountSum;
		
		If vSrvRow.IsManual Then
			FixedChargesTotalCommissionSum = FixedChargesTotalCommissionSum + vSrvRow.CommissionSum;
			FixedChargesTotalDiscountSum = FixedChargesTotalDiscountSum + vSrvRow.DiscountSum;
			FixedChargesTotalSum = FixedChargesTotalSum + vSrvRow.Sum;
			FixedChargesTotalSumWithDiscount = FixedChargesTotalSumWithDiscount + vSrvRow.Sum - vSrvRow.DiscountSum;
			FixedChargesTotalVATSum = FixedChargesTotalVATSum + vSrvRow.VATSum;
		Else			
			ServicesTotalCommissionSum = ServicesTotalCommissionSum + vSrvRow.CommissionSum;
			ServicesTotalDiscountSum = ServicesTotalDiscountSum + vSrvRow.DiscountSum;
			ServicesTotalSum = ServicesTotalSum + vSrvRow.Sum;
			ServicesTotalSumWithDiscount = ServicesTotalSumWithDiscount + vSrvRow.Sum - vSrvRow.DiscountSum;
			ServicesTotalVATSum = ServicesTotalVATSum + vSrvRow.VATSum;
		EndIf;
	EndDo;
EndProcedure // CalculateServicesFooterTotals

// -----------------------------------------------------------------------------
&AtServer
Procedure CopyPrices(pTargetPrices, pSourcePrices = Undefined, pRoomRatePrice = Undefined)
	// Clear all manual prices except resort fee
	i = 0;
	While i < pTargetPrices.Count() Do
		vTgtPricesRow = pTargetPrices.Get(i);
		vTgtPricesSrv = vTgtPricesRow.Service;
		If ValueIsFilled(vTgtPricesSrv) And 
		   ValueIsFilled(vTgtPricesSrv.QuantityCalculationRule) And 
		  (vTgtPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 Or 
		   vTgtPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO Or 
		   vTgtPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022) Then
			i = i + 1;
		Else
			pTargetPrices.Delete(i);
		EndIf;
	EndDo;
	// Add source prices
	If pSourcePrices <> Undefined Then
		i = 0;
		While i < pSourcePrices.Count() Do
			vSrcPricesRow = pSourcePrices.Get(i);
			vSrcPricesSrv = vSrcPricesRow.Service;
			If ValueIsFilled(vSrcPricesSrv) And 
			   ValueIsFilled(vSrcPricesSrv.QuantityCalculationRule) And 
			  (vSrcPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 Or 
			   vSrcPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO Or 
			   vSrcPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022) Then
				i = i + 1;
			Else
				vTgtPricesRow = pTargetPrices.Add();
				FillPropertyValues(vTgtPricesRow, vSrcPricesRow);
				If pRoomRatePrice <> Undefined Then
					vTgtPricesRow.Price = Number(pRoomRatePrice);
				EndIf;
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // CopyPrices

// -----------------------------------------------------------------------------
&AtServer
Procedure ProcessResortFee(pTargetPrices, pSourcePrices)
	vObjResortFeeServiceIsFound = False;
	For Each vObjPricesRow In pSourcePrices Do
		vObjPricesSrv = vObjPricesRow.Service;
		If ValueIsFilled(vObjPricesSrv) And 
		   ValueIsFilled(vObjPricesSrv.QuantityCalculationRule) And 
		  (vObjPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 Or 
		   vObjPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO Or 
		   vObjPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022) Then
			vObjResortFeeServiceIsFound = True;
			Break;
		EndIf;
	EndDo;
	vSrvObjResortFeeServiceIsFound = False;
	For Each vSrvObjPricesRow In pTargetPrices Do
		vSrvObjPricesSrv = vSrvObjPricesRow.Service;
		If ValueIsFilled(vSrvObjPricesSrv) And 
		   ValueIsFilled(vSrvObjPricesSrv.QuantityCalculationRule) And 
		  (vSrvObjPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 Or 
		   vSrvObjPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO Or 
		   vSrvObjPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022) Then
			vSrvObjResortFeeServiceIsFound = True;
			Break;
		EndIf;
	EndDo;
	If vObjResortFeeServiceIsFound Then
		If Not vSrvObjResortFeeServiceIsFound Then
			vPricesRow = pTargetPrices.Add();
			FillPropertyValues(vPricesRow, vObjPricesRow);
		EndIf;
	Else
		If vSrvObjResortFeeServiceIsFound Then
			pTargetPrices.Delete(vSrvObjPricesRow);
		EndIf;
	EndIf;
EndProcedure // ProcessResortFee

// -----------------------------------------------------------------------------
&AtServer
Function GetTotalSumPresentation(pObj = Undefined, pRowMode = False, rPricePresentation = "", pIsOnOpenMode = False, pForceServicesRecalculation = False, pShowMessages = False, rResortFeeStr = "")
	rPricePresentation = "";
	If NeedServicesRecalculation And Not pForceServicesRecalculation Then
		vTotalStr = NStr("en='<Recalculate>'; ru='<Пересчитать>'; de='<Neuberechnen>'");
		Return vTotalStr;
	EndIf;	
	NeedServicesRecalculation = False;
	
	vThereAreServices = False;
	vTotalStr = "";
	vTotalSum = 0;
	vObj = pObj;
	If (TypeOf(pObj)=Type("FormDataStructure")) Or (pObj = Undefined) Then
		vObj = Object;
	ElsIf TypeOf(pObj)=Type("DocumentRef.Accommodation") Then
		vObj = pObj.GetObject();
	ElsIf TypeOf(pObj)=Type("DocumentObject.Accommodation") Then
		vObj = pObj;
	EndIf;
	If pRowMode = Undefined Then
		pRowMode = False;
	EndIf;
	vHotel = vObj.Hotel;
	// Table with accommodation types of all guests in the group
	vAccTypesTable = New ValueTable;
	vAccTypesTable.Columns.Add("AccommodationType");
	vAccTypesTable.Columns.Add("Ref");
	vAccTypesTable.Columns.Add("RoomRateIsDifferent", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("DiscountsAreDifferent", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("ManualPricesAreDifferent", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("ServicePackagesAreDifferent", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("RoomRatesAreDifferent", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("CheckInDateIsDifferent", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("CheckOutDateIsDifferent", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("ClientTypeIsDifferent", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("BoardPlaceIsDifferent", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("IsForFolioSplitIsDifferent", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("GuestAge", cmGetNumberTypeDescription(3, 0, True));
	vAccTypesTable.Columns.Add("GuestCitizenship", cmGetCatalogTypeDescription("Countries"));
	vAccTypesTable.Columns.Add("IsNoResortFee", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("SharePercent", cmGetStringTypeDescription(6));
	vAccTypesTable.Columns.Add("PriceCalculationDateShouldBeUpdated", cmGetBooleanTypeDescription());
	vAccTypesTable.Columns.Add("pIsForFolioSplit", cmGetBooleanTypeDescription());
	vFirstRow = vAccTypesTable.Add();
	vFirstRow.AccommodationType = vObj.AccommodationType;
	vFirstRow.SharePercent = vObj.SharePercent;
	vFirstRow.Ref = vObj.Ref;
	vFirstRow.GuestAge = vObj.GuestAge;
	vFirstRow.GuestCitizenship = vObj.GuestCitizenship;
	For Each vGuestsInGroupRow In GuestsInGroup Do
		If ValueIsFilled(vGuestsInGroupRow.AccommodationType) And Not vGuestsInGroupRow.IsStatusChanged Then
			vRow = vAccTypesTable.Add();
			FillPropertyValues(vRow, vGuestsInGroupRow);
			// Fill guest age and citizehship
			vCurGuestAge = 0;
			vCurKidIndex = GuestsInGroup.IndexOf(vGuestsInGroupRow) - NumberOfAdults + 2;
			If vCurKidIndex > 0 Then
				vCurGuestAge = ThisObject["KidAge" + String(vCurKidIndex)];
			EndIf;
			vRow.GuestAge = vCurGuestAge;
			vRow.PriceCalculationDateShouldBeUpdated = vGuestsInGroupRow.PriceCalculationDateShouldBeUpdated;
		EndIf;
	EndDo;
	vMainSrvTable = New ValueTable;
	vMainSrvTable.Columns.Add("Service");
	vMainSrvTable.Columns.Add("AccountingDate");
	vMainSrvTable.Columns.Add("FolioCurrency");
	vMainSrvTable.Columns.Add("IsInPrice");
	vMainSrvTable.Columns.Add("Quantity");
	vMainSrvTable.Columns.Add("Sum");
	vMainSrvTable.Columns.Add("DiscountSum");
	vMainSrvTable.Columns.Add("CommissionSum");
	i = 0;
	For Each vAccType In vAccTypesTable Do
		If ValueIsFilled(vAccType.Ref) Then
			If vAccType.Ref = vObj.Ref Then
				If TypeOf(vObj) <> Type("FormDataStructure") Then
					vSrvObj = vObj;
				Else
					vSrvObj = FormAttributeToValue("Object");
				EndIf;
				vRecalculateServices = pForceServicesRecalculation;
				If Not pIsOnOpenMode Then
					vRecalculateServices = True;
					vSrvObj.AccommodationType = vAccType.AccommodationType;
					vSrvObj.SharePercent = vAccType.SharePercent;
					vSrvObj.GuestAge = vAccType.GuestAge;
				EndIf;
				If vRecalculateServices Then
					vWarnings = "";
					vTouristicTaxExemptionReason = vSrvObj.TouristicTaxExemptionReason;
					vSrvObj.pmCalculateServices(vWarnings, , , , , vSrvObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
					If TypeOf(vObj) = Type("FormDataStructure") Then
						If vTouristicTaxExemptionReason <> vSrvObj.TouristicTaxExemptionReason Then
							Modified = True;
						EndIf;
						If Modified Then
							ValueToFormAttribute(vSrvObj, "Object");
						EndIf;
					EndIf;
					If pShowMessages Then
						If Not IsBlankString(vWarnings) Then
							SetObjectAndFormAttributeConformity(vSrvObj, "Object");
							vUM = New UserMessage();
							vUM.SetData(vSrvObj);
							vUM.Field = "RoomRate";
							vUM.Text = cmNStr(vWarnings);
							vUM.Message();
						EndIf;
					EndIf;
				EndIf;
			Else
				vSrvObj = vAccType.Ref.GetObject();
				If Not pIsOnOpenMode Then
					If Not vAccType.IsForFolioSplitIsDifferent Then
						vSrvObj.IsForFolioSplit = vObj.IsForFolioSplit;
					Else
						vSrvObj.IsForFolioSplit = vAccType.pIsForFolioSplit;
					EndIf;
					vSrvObj.FixReservationConditions = vObj.FixReservationConditions;
					vSrvObj.RoomType = vObj.RoomType;
					vSrvObj.RoomTypeUpgrade = vObj.RoomTypeUpgrade;
					vSrvObj.AccommodationType = vAccType.AccommodationType;
					vSrvObj.SharePercent = vAccType.SharePercent;
					If Not vAccType.CheckInDateIsDifferent Then
						vSrvObj.CheckInDate = vObj.CheckInDate;
						vSrvObj.Duration = vObj.Duration;
					EndIf;
					If Not vAccType.CheckOutDateIsDifferent Then
						vSrvObj.CheckOutDate = vObj.CheckOutDate;
						vSrvObj.Duration = vObj.Duration;
					EndIf;
					If Not vAccType.RoomRateIsDifferent Then
						vSrvObj.RoomRate = vObj.RoomRate;
						If ValueIsFilled(vSrvObj.RoomRate) Then
							vSrvObj.RoomRateType = vSrvObj.RoomRate.RoomRateType;
						EndIf;
						SetDurationCaption(vSrvObj);
					EndIf;
					If Not vAccType.ClientTypeIsDifferent Then
						vSrvObj.ClientType = vObj.ClientType;
					EndIf;
					If Not vAccType.BoardPlaceIsDifferent Then
						vSrvObj.BoardPlace = vObj.BoardPlace;
					EndIf;
					If Not vAccType.DiscountsAreDifferent Then
						vSrvObj.DiscountCard = vObj.DiscountCard;
						vSrvObj.DiscountType = vObj.DiscountType;
						vSrvObj.DiscountConfirmationText = vObj.DiscountConfirmationText;
						vSrvObj.Discount = vObj.Discount;
						vSrvObj.DiscountSum = vObj.DiscountSum;
						vSrvObj.DiscountServiceGroup = vObj.DiscountServiceGroup;
						vSrvObj.TurnOffAutomaticDiscounts = vObj.TurnOffAutomaticDiscounts;
					EndIf;
					// Service packages
					If Not vAccType.ServicePackagesAreDifferent Then
						vSrvObj.ServicePackages.Clear();
						If ValueIsFilled(vObj.ServicePackage) Then
							If vObj.ServicePackage.IsMealBoardTerm Then
								vSrvObj.ServicePackage = vObj.ServicePackage;
							Else
								If vObj.ServicePackage.IsPerPerson Then
									vSrvObj.ServicePackage = vObj.ServicePackage;
								EndIf;
							EndIf;
						EndIf;
						For Each vSrvPkgRow In vObj.ServicePackages Do
							If ValueIsFilled(vSrvPkgRow.ServicePackage) And vSrvPkgRow.ServicePackage.IsPerPerson Then
								vSrvObjPkgRow = vSrvObj.ServicePackages.Add();
								vSrvObjPkgRow.ServicePackage = vSrvPkgRow.ServicePackage;
								vSrvObjPkgRow.Quantity = vSrvPkgRow.Quantity;
								vSrvObjPkgRow.DateFrom = vSrvPkgRow.DateFrom;
								vSrvObjPkgRow.DateTo = vSrvPkgRow.DateTo;
							EndIf;
						EndDo;
					EndIf;
					// Services
					If vSrvObj.IsForFolioSplit And Not vSrvObj.Ref.IsForFolioSplit Then
						If vSrvObj.AccommodationType = vSrvObj.AccommodationType Then
							vSrvObj.Services.Load(vObj.Services.Unload());
						Else
							vSrvObj.Services.Load(vObj.Services.Unload(New Structure("IsManual", False)));
							For Each vObjectServicesRow In vSrvObj.Services Do
								vObjectServicesRow.IsManualPrice = False;
								vObjectServicesRow.QuantityIsChanged = False;
							EndDo;
						EndIf;
					EndIf;
					// Prices
					If IsManualRoomPrice = 3 And Not vAccType.ManualPricesAreDifferent Then
						CopyPrices(vSrvObj.Prices, vObj.Prices);
					ElsIf IsManualRoomPrice = 1 Then
						If vObj.IsForFolioSplit And Not IsBlankString(vAccType.SharePercent) Then
							vAccType.ManualPricesAreDifferent = False;
							CopyPrices(vSrvObj.Prices, vObj.Prices);
						ElsIf Not vAccType.ManualPricesAreDifferent Then
							CopyPrices(vSrvObj.Prices, vObj.Prices, 0);
						EndIf;
					ElsIf Not vAccType.ManualPricesAreDifferent Then
						If ValueIsFilled(vAccType.AccommodationType) And (vAccType.AccommodationType.Type = Enums.AccomodationTypes.Beds OR vAccType.AccommodationType.Type = Enums.AccomodationTypes.Room) Then
							CopyPrices(vSrvObj.Prices, vObj.Prices);
						Else
							CopyPrices(vSrvObj.Prices);
						EndIf;
					EndIf;
					// Resort fee and tourist tax
					If vAccType.IsNoResortFee Then
						vSrvObj.TouristicTaxExemptionReason = vObj.TouristicTaxExemptionReason;
						vSrvObj.TouristicTaxExemptionReasonFillDate = vObj.TouristicTaxExemptionReasonFillDate;
						vSrvObj.TouristicTaxExemptionConfirmationData = "";
						ProcessResortFee(vSrvObj.Prices, vObj.Prices);
					EndIf;
					// Room rates
					If Not vAccType.RoomRatesAreDifferent Then
						vOldSrvObjRoomRates = vSrvObj.RoomRates.Unload();
						vSrvObj.RoomRates.Load(vObj.RoomRates.Unload());
						For Each vSrvObjRRRow In vSrvObj.RoomRates Do
							vSrvObjRRRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef();
							vSrvObjRRRow.AccommodationTemplate = Catalogs.AccommodationTemplates.EmptyRef();
						EndDo;
						For Each vOldSrvObjRRRow In vOldSrvObjRoomRates Do
							If ValueIsFilled(vOldSrvObjRRRow.AccommodationType) Or ValueIsFilled(vOldSrvObjRRRow.AccommodationTemplate) Then
								vSrvObjRRRow = vSrvObj.RoomRates.Find(vOldSrvObjRRRow.AccountingDate, "AccountingDate");
								If vSrvObjRRRow = Undefined Then
									vSrvObjRRRow = vSrvObj.RoomRates.Add();
									vSrvObjRRRow.AccountingDate = vOldSrvObjRRRow.AccountingDate;
									vSrvObjRRRow.ChangeTime = vOldSrvObjRRRow.ChangeTime;
								EndIf;
								vSrvObjRRRow.AccommodationType = vOldSrvObjRRRow.AccommodationType;
								vSrvObjRRRow.AccommodationTemplate = vOldSrvObjRRRow.AccommodationTemplate;
							EndIf;
						EndDo;
					EndIf;
					// Agent commission
					vSrvObj.AgentCommission = vObj.AgentCommission;
					vSrvObj.AgentCommissionType = vObj.AgentCommissionType;
					vSrvObj.AgentCommissionServiceGroup = vObj.AgentCommissionServiceGroup;
					vSrvObj.GuestAge = vAccType.GuestAge;
					If vAccType.PriceCalculationDateShouldBeUpdated Then
						vSrvObj.PriceCalculationDate = Object.PriceCalculationDate;
					EndIf;
					// Recalculate services
					vWarnings = "";
					vSrvObj.pmCalculateServices(vWarnings, , , , , vSrvObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
				EndIf;
			EndIf;
		Else
			If vAccTypesTable.IndexOf(vAccType) = 0 Then
				If TypeOf(vObj) <> Type("FormDataStructure") Then
					vSrvObj = vObj;
				Else
					vSrvObj = FormAttributeToValue("Object");
				EndIf;
			Else
				vSrvObjReservation = Undefined;
				If GuestsToCheckInList.Count() > 0 And i < GuestsToCheckInList.Count() Then
					vSrvObjReservation = GuestsToCheckInList[i].Value;
				EndIf;
				vSrvObj = Documents.Accommodation.CreateDocument();
				If ValueIsFilled(vSrvObjReservation) Then
					vSrvObj.Fill(vSrvObjReservation);
				Else
					FillPropertyValues(vSrvObj, vObj, , "AccommodationTemplate, ServicePackage");
					vSrvObj.ChargingRules.Load(vObj.ChargingRules.Unload());
					// Fill occupation percents
					vSrvObj.OccupationPercents.Load(vObj.OccupationPercents.Unload());
					// Fill service packages
					vSrvObj.ServicePackages.Clear();
					If ValueIsFilled(vObj.ServicePackage) Then
						If vObj.ServicePackage.IsMealBoardTerm Then
							vSrvObj.ServicePackage = vObj.ServicePackage;
						Else
							If vObj.ServicePackage.IsPerPerson Then
								vSrvObj.ServicePackage = vObj.ServicePackage;
							EndIf;
						EndIf;
					EndIf;
					For Each vSrvPkgRow In vObj.ServicePackages Do
						If ValueIsFilled(vSrvPkgRow.ServicePackage) And vSrvPkgRow.ServicePackage.IsPerPerson Then
							vSrvObjPkgRow = vSrvObj.ServicePackages.Add();
							vSrvObjPkgRow.ServicePackage = vSrvPkgRow.ServicePackage;
							vSrvObjPkgRow.Quantity = vSrvPkgRow.Quantity;
							vSrvObjPkgRow.DateFrom = vSrvPkgRow.DateFrom;
							vSrvObjPkgRow.DateTo = vSrvPkgRow.DateTo;
						EndIf;
					EndDo;
					// Fill services as basis
					If IsManualRoomPrice = 3 Then
						vSrvObj.Services.Load(vObj.Services.Unload());
					Else
						If vSrvObj.AccommodationType = vObj.AccommodationType Then
							vSrvObj.Services.Load(vObj.Services.Unload());
						Else
							vSrvObj.Services.Load(vObj.Services.Unload(New Structure("IsManual", False)));
							For Each vObjectServicesRow In vSrvObj.Services Do
								vObjectServicesRow.IsManualPrice = False;
								vObjectServicesRow.QuantityIsChanged = False;
							EndDo;
						EndIf;
					EndIf;
					// Prices
					If IsManualRoomPrice = 3 Then
						CopyPrices(vSrvObj.Prices, vObj.Prices);
					ElsIf IsManualRoomPrice = 1 Then
						If vObj.IsForFolioSplit And Not IsBlankString(vAccType.SharePercent) Then
							CopyPrices(vSrvObj.Prices, vObj.Prices);
						Else
							CopyPrices(vSrvObj.Prices, vObj.Prices, 0);
						EndIf;
					Else
						If ValueIsFilled(vAccType.AccommodationType) And (vAccType.AccommodationType.Type = Enums.AccomodationTypes.Beds OR vAccType.AccommodationType.Type = Enums.AccomodationTypes.Room) Then
							CopyPrices(vSrvObj.Prices, vObj.Prices);
						Else
							CopyPrices(vSrvObj.Prices);
						EndIf;
					EndIf;
					// Fill room rates
					vSrvObj.RoomRates.Load(vObj.RoomRates.Unload());
					For Each vSrvObjRoomRatesRow In vSrvObj.RoomRates Do
						vSrvObjRoomRatesRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef();
						vSrvObjRoomRatesRow.AccommodationTemplate = Catalogs.AccommodationTemplates.EmptyRef();
					EndDo;
				EndIf;
				// Resort fee and tourist tax
				If vAccType.IsNoResortFee Then
					vSrvObj.TouristicTaxExemptionReason = vObj.TouristicTaxExemptionReason;
					vSrvObj.TouristicTaxExemptionReasonFillDate = vObj.TouristicTaxExemptionReasonFillDate;
					vSrvObj.TouristicTaxExemptionConfirmationData = "";
					ProcessResortFee(vSrvObj.Prices, vObj.Prices);
				EndIf;
			EndIf;
			If Not cmCheckUserPermissions("HavePermissionToEditAccommodationCheckInDate") Then
				If BegOfDay(vObj.CheckInDate) < BegOfDay(CurrentSessionDate()) And BegOfDay(CurrentSessionDate()) < BegOfDay(vObj.CheckOutDate) Then
					vSrvObj.CheckInDate = cm1SecondShift(CurrentSessionDate());
					vSrvObj.Duration = vSrvObj.pmCalculateDuration();
				EndIf;
			EndIf;
			If vSrvObj.AccommodationType <> vAccType.AccommodationType Then
				vSrvObj.AccommodationType = vAccType.AccommodationType;
			EndIf;
			If vSrvObj.SharePercent <> vAccType.SharePercent Then
				vSrvObj.SharePercent = vAccType.SharePercent;
			EndIf;
			If vSrvObj.GuestAge <> vAccType.GuestAge Then
				vSrvObj.GuestAge = vAccType.GuestAge;
			EndIf;
			If Not vAccType.IsForFolioSplitIsDifferent Then
				vSrvObj.IsForFolioSplit = vObj.IsForFolioSplit;
			Else
				vSrvObj.IsForFolioSplit = vAccType.pIsForFolioSplit;
			EndIf;
			vWarnings = "";
			vSrvObj.pmCalculateServices(vWarnings, , , , , vSrvObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
			If vAccTypesTable.IndexOf(vAccType) = 0 Then
				If TypeOf(vObj) = Type("FormDataStructure") Then
					ValueToFormAttribute(vSrvObj, "Object");
				EndIf;
				If pShowMessages Then
					If Not IsBlankString(vWarnings) Then
						SetObjectAndFormAttributeConformity(vSrvObj, "Object");
						vUM = New UserMessage();
						vUM.SetData(vSrvObj);
						vUM.Field = "RoomRate";
						vUM.Text = cmNStr(vWarnings);
						vUM.Message();
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// We have to group all amounts by currencies
		vSrv = vSrvObj.Services.Unload(, "Sum, DiscountSum, CommissionSum, Quantity, FolioCurrency, AccountingDate, IsInPrice, Service");
		// We have to group all amounts by currencies
		vSrv.GroupBy("FolioCurrency, AccountingDate, Service, IsInPrice", "Sum, DiscountSum, CommissionSum, Quantity");
		For Each vSrvRow In vSrv Do
			FillPropertyValues(vMainSrvTable.Add(), vSrvRow);
		EndDo;
		i = i + 1;
	EndDo;
	// Shift dates for breakfast back one day
	For Each vMainSrvTableRow In vMainSrvTable Do
		vThereAreServices = True;
		If vMainSrvTableRow.IsInPrice And ValueIsFilled(vMainSrvTableRow.Service.QuantityCalculationRule) Then
			vAccountingDateMove = cmGetAccountingDateMove(vMainSrvTableRow.Service.QuantityCalculationRule, False, vObj, True);
			If vAccountingDateMove < 0 Then
				vMainSrvTableRow.AccountingDate = vMainSrvTableRow.AccountingDate - 24*3600;
			EndIf;
		EndIf;
	EndDo;
	vMainSrvTable.Sort("AccountingDate");
	// Do calculation
	If ValueIsFilled(vObj.Agent) And vObj.Agent = vObj.Customer And ValueIsFilled(vObj.AgentCommissionType) And 
		cmCustomerIsPayer(vObj.ChargingRules.Unload(), vObj.Customer, vObj.Contract, vObj.GuestGroup, vObj.IgnoreGroupChargingRules) Then
		// Calculate first day price
		vCheckInDate = Undefined;
		vCheckInCurrency = Undefined;
		vCheckInPrice = 0;
		For Each vMainSrvTableRow In vMainSrvTable Do
			If vMainSrvTableRow.IsInPrice Then
				If vMainSrvTableRow.AccountingDate <> vCheckInDate And vCheckInDate <> Undefined Then
					Break;
				Else
					vCheckInDate = vMainSrvTableRow.AccountingDate;
					If vCheckInCurrency = Undefined Then
						vCheckInCurrency = vMainSrvTableRow.FolioCurrency;
					ElsIf vCheckInCurrency <> vMainSrvTableRow.FolioCurrency Then
						Continue;
					EndIf;
					vCheckInPrice = vCheckInPrice + vMainSrvTableRow.Sum - vMainSrvTableRow.DiscountSum - vMainSrvTableRow.CommissionSum;
				EndIf;
			EndIf;
		EndDo;
		If vCheckInCurrency <> Undefined Then
			rPricePresentation = cmFormatSum(vCheckInPrice, vCheckInCurrency, , , True);
		EndIf;
		// Calculate total amounts
		vMainSrvTable.GroupBy("Service, FolioCurrency", "Sum, DiscountSum, CommissionSum");
		vResortFeeTable = vMainSrvTable.Copy();
		SplitTotalsByResortFee(vMainSrvTable, vResortFeeTable);
		// Fill total amount presentation
		vFTotalArray = New Array;
		For Each vTotal In vMainSrvTable Do
			If vFTotalArray.Count()=0 Then
				vFTotalArray.Add(tcOnServer.cmFormattedSumString(vTotal.Sum - vTotal.DiscountSum - vTotal.CommissionSum, vTotal.FolioCurrency));
				Sum = vTotal.Sum - vTotal.DiscountSum - vTotal.CommissionSum;
			Else
				vFTotalArray.Add(?(pRowMode, Chars.LF, "; "));
				vFTotalArray.Add(tcOnServer.cmFormattedSumString(vTotal.Sum - vTotal.DiscountSum - vTotal.CommissionSum, vTotal.FolioCurrency));
				Sum = Sum + vTotal.Sum - vTotal.DiscountSum - vTotal.CommissionSum;
			EndIf;
		EndDo;
		vTotalStr = New FormattedString(vFTotalArray);
		// Fill resort fee amount presentation
		vRFTotalArray = New Array;
		For Each vRFTotal In vResortFeeTable Do
			If vRFTotalArray.Count() = 0 Then
				If cmIfTouristTaxIsCharging(vHotel, BegOfDay(vObj.CheckInDate), vObj.RoomRate) Then
					vRFTotalArray.Add(tcOnServer.cmFormattedSumTitle(NStr("en='Tourist tax: '; ru='Тур. налог: '; de='Kurtaxe: '"), True));
				Else
					vRFTotalArray.Add(tcOnServer.cmFormattedSumTitle(NStr("en='Resort fee: '; ru='Кур. сбор: '; de='Resortgebühr: '"), True));
				EndIf;
				vRFTotalArray.Add(tcOnServer.cmFormattedSumString(vRFTotal.Sum - vRFTotal.DiscountSum - vRFTotal.CommissionSum, vRFTotal.FolioCurrency, True));
			Else
				vRFTotalArray.Add(?(pRowMode, Chars.LF, "; "));
				vRFTotalArray.Add(tcOnServer.cmFormattedSumString(vRFTotal.Sum - vRFTotal.DiscountSum - vRFTotal.CommissionSum, vRFTotal.FolioCurrency, True));
			EndIf;
		EndDo;
		rResortFeeStr = New FormattedString(vRFTotalArray);
	Else
		// Calculate first day price
		vCheckInDate = Undefined;
		vCheckInCurrency = Undefined;
		vCheckInPrice = 0;
		For Each vMainSrvTableRow In vMainSrvTable Do
			If vMainSrvTableRow.IsInPrice Then
				If vMainSrvTableRow.AccountingDate <> vCheckInDate And vCheckInDate <> Undefined Then
					Break;
				Else
					vCheckInDate = vMainSrvTableRow.AccountingDate;
					If vCheckInCurrency = Undefined Then
						vCheckInCurrency = vMainSrvTableRow.FolioCurrency;
					ElsIf vCheckInCurrency <> vMainSrvTableRow.FolioCurrency Then
						Continue;
					EndIf;
					vCheckInPrice = vCheckInPrice + vMainSrvTableRow.Sum - vMainSrvTableRow.DiscountSum;
				EndIf;
			EndIf;
		EndDo;
		If vCheckInCurrency <> Undefined Then
			rPricePresentation = cmFormatSum(vCheckInPrice, vCheckInCurrency, , , True);
		EndIf;
		// Calculate total amount
		vMainSrvTable.GroupBy("Service, FolioCurrency", "Sum, DiscountSum, CommissionSum");
		vResortFeeTable = vMainSrvTable.Copy();
		SplitTotalsByResortFee(vMainSrvTable, vResortFeeTable);
		// Fill total amount presentation
		vFTotalArray = New Array;
		For Each vTotal In vMainSrvTable Do
			If vFTotalArray.Count()=0 Then
				vFTotalArray.Add(tcOnServer.cmFormattedSumString(vTotal.Sum - vTotal.DiscountSum, vTotal.FolioCurrency));
				Sum = vTotal.Sum - vTotal.DiscountSum;
			Else
				vFTotalArray.Add(?(pRowMode, Chars.LF, "; "));
				vFTotalArray.Add(tcOnServer.cmFormattedSumString(vTotal.Sum - vTotal.DiscountSum, vTotal.FolioCurrency));
				Sum = Sum + vTotal.Sum - vTotal.DiscountSum;
			EndIf;
		EndDo;
		vTotalStr = new FormattedString(vFTotalArray);
		// Fill resort fee amount presentation
		vRFTotalArray = New Array;
		For Each vRFTotal In vResortFeeTable Do
			If vRFTotalArray.Count() = 0 Then
				If cmIfTouristTaxIsCharging(vHotel, BegOfDay(vObj.CheckInDate), vObj.RoomRate) Then
					vRFTotalArray.Add(tcOnServer.cmFormattedSumTitle(NStr("en='Tourist tax: '; ru='Тур. налог: '; de='Kurtaxe: '"), True));
				Else
					vRFTotalArray.Add(tcOnServer.cmFormattedSumTitle(NStr("en='Resort fee: '; ru='Кур. сбор: '; de='Resortgebühr: '"), True));
				EndIf;
				vRFTotalArray.Add(tcOnServer.cmFormattedSumString(vRFTotal.Sum - vRFTotal.DiscountSum, vRFTotal.FolioCurrency, True));
			Else
				vRFTotalArray.Add(?(pRowMode, Chars.LF, "; "));
				vRFTotalArray.Add(tcOnServer.cmFormattedSumString(vRFTotal.Sum - vRFTotal.DiscountSum, vRFTotal.FolioCurrency, True));
			EndIf;
		EndDo;
		rResortFeeStr = New FormattedString(vRFTotalArray);
	EndIf;	
	If IsBlankString(vTotalStr) Then
		If vThereAreServices Then
			vTotalStr = "---";
		Else
			vTotalStr = "N/A";
		EndIf;
	EndIf;	
	// Build tourist tax group title
	BuildRoomRateGroupCollapsedTitle(pObj);
	// Return
	Return vTotalStr; 
EndFunction // GetTotalSumPresentation

// -----------------------------------------------------------------------------
&AtServer
Procedure SplitTotalsByResortFee(vMainSrvTable, vResortFeeTable)
	s = 0;
	While s < vMainSrvTable.Count() Do
		vMainSrvTableRow = vMainSrvTable.Get(s);
		If ValueIsFilled(vMainSrvTableRow.Service) And vMainSrvTableRow.Service.IsResortFee Then
			vMainSrvTable.Delete(s);
		Else
			s = s + 1;
		EndIf;
	EndDo;
	r = 0;
	While r < vResortFeeTable.Count() Do
		vResortFeeTableRow = vResortFeeTable.Get(r);
		If ValueIsFilled(vResortFeeTableRow.Service) And Not vResortFeeTableRow.Service.IsResortFee Then
			vResortFeeTable.Delete(r);
		Else
			r = r + 1;
		EndIf;
	EndDo;
	vMainSrvTable.GroupBy("FolioCurrency", "Sum, DiscountSum, CommissionSum");
	vResortFeeTable.GroupBy("FolioCurrency", "Sum, DiscountSum, CommissionSum");
EndProcedure // SplitTotalsByResortFee

// -----------------------------------------------------------------------------
&AtServer
Procedure CustomerOnChangeAtServer(pObj = Undefined) Export
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	If ValueIsFilled(vObj.Customer) Then
		// Customer type
		vObj.CustomerType = vObj.Customer.CustomerType;
		// Room rate type
		If ValueIsFilled(vObj.CustomerType) Then
			If Not ValueIsFilled(vObj.RoomRateType) Then
				vObj.RoomRateType = vObj.CustomerType.RoomRateType;
			EndIf;
		EndIf;
		// Contact person
		If Not IsBlankString(vObj.Customer.ContactPerson) Then
			vObj.ContactPerson = TrimR(vObj.Customer.ContactPerson);
		EndIf;
		// Planned payment method
		If Not ValueIsFilled(vObj.ParentDoc) Then
			If ValueIsFilled(vObj.Customer.PlannedPaymentMethod) Then
				vObj.PlannedPaymentMethod = vObj.Customer.PlannedPaymentMethod;
			EndIf;
		EndIf;
		// Agent
		vObj.Agent = vObj.Customer.Agent;
		If ValueIsFilled(vObj.Customer.AgentCommissionType) Then
			If Not ValueIsFilled(vObj.Agent) Then
				vObj.Agent = vObj.Customer;
			EndIf;
			vObj.AgentCommission = vObj.Agent.AgentCommission;
			vObj.AgentCommissionType = vObj.Agent.AgentCommissionType;
			vObj.AgentCommissionServiceGroup = vObj.Agent.AgentCommissionServiceGroup;
		EndIf;
		If Not ValueIsFilled(vObj.Agent) Then
			vObj.AgentCommission = 0;
			vObj.AgentCommissionType = Undefined;
			vObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		EndIf;
		// Room rate
		vOldRoomRate = vObj.RoomRate;
		vRoomRateWasUpdated = False;
		If ValueIsFilled(vObj.Customer.RoomRate) And (Not ValueIsFilled(vObj.Customer.RoomRate.Hotel) Or vObj.Customer.RoomRate.Hotel = vObj.Hotel) Then
			vRoomRateWasUpdated = True;
			If vObj.RoomRate <> vObj.Customer.RoomRate Then
				vObj.PriceCalculationDate = '00010101';
			EndIf;
			vObj.RoomRate = vObj.Customer.RoomRate;
			vObj.RoomRateServiceGroup = vObj.Customer.RoomRateServiceGroup;
		ElsIf vObj.Customer.RoomRates.Count() > 0 Then
			vRoomRatesAllowed = cmGetAllowedRoomRates(vObj.CheckInDate, vObj.CheckOutDate, vObj.Date, vObj.RoomType, vObj.Hotel);
			If vRoomRatesAllowed.Count() > 0 Then
				For Each vRRRow In vObj.Customer.RoomRates Do
					vRRRowRate = vRRRow.RoomRate;
					If ValueIsFilled(vRRRowRate) And (Not ValueIsFilled(vRRRowRate.Hotel) Or vRRRowRate.Hotel = vObj.Hotel) Then
						If vRoomRatesAllowed.FindByValue(vRRRowRate) <> Undefined Then
							vRoomRateWasUpdated = True;
							vObj.RoomRate = vRRRowRate;
							vObj.RoomRateServiceGroup = vObj.Customer.RoomRateServiceGroup;
							If vObj.RoomRate <> vOldRoomRate Then
								vObj.PriceCalculationDate = '00010101';
							EndIf;
							Break;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		// Check if room rate was updated
		If vRoomRateWasUpdated Then
			// Get bound attributes
			vObj.RoomRateType = vObj.RoomRate.RoomRateType;
			SetDurationCaption(vObj);
			vObj.RoomRateServiceGroup = vObj.Customer.RoomRateServiceGroup;
			vObj.DoNotPrintRate = vObj.RoomRate.DoNotPrintRate;
			// Source of business
			If ValueIsFilled(vObj.RoomRate.SourceOfBusiness) Then
				vObj.SourceOfBusiness = vObj.RoomRate.SourceOfBusiness;
			EndIf;
			// Marketing code
			If ValueIsFilled(vObj.RoomRate.MarketingCode) Then
				vObj.MarketingCode = vObj.RoomRate.MarketingCode;
			EndIf;
			// Client type
			If ValueIsFilled(vObj.RoomRate.ClientType) Then
				vObj.ClientType = vObj.RoomRate.ClientType;
				vObj.ClientTypeConfirmationText = vObj.RoomRate.ClientTypeConfirmationText;
			EndIf;
			// Company
			If ValueIsFilled(vObj.RoomRate.Company) Then
				vObj.Company = vObj.RoomRate.Company;
			EndIf;
			// Allotment
			If ValueIsFilled(vObj.RoomRate.Allotment) And vObj.RoomQuota <> vObj.RoomRate.Allotment Then
				vObj.RoomQuota = vObj.RoomRate.Allotment;
				// Company
				If ValueIsFilled(vObj.RoomQuota.Company) And vObj.RoomQuota.Company <> vObj.Company Then
					vObj.Company = vObj.RoomQuota.Company;
				EndIf;
			EndIf;
		EndIf;
		// Marketing code
		If ValueIsFilled(vObj.Customer.MarketingCode) Then
			vObj.MarketingCode = vObj.Customer.MarketingCode;
			vObj.MarketingCodeConfirmationText = "";
		EndIf;
		// Source of business
		If ValueIsFilled(vObj.Customer.SourceOfBusiness) Then
			vObj.SourceOfBusiness = vObj.Customer.SourceOfBusiness;
		EndIf;
		// Client type
		If ValueIsFilled(vObj.Customer.ClientType) And (Not ValueIsFilled(vObj.Customer.ClientType.Hotel) Or vObj.Customer.ClientType.Hotel = vObj.Hotel) Then
			vObj.ClientType = vObj.Customer.ClientType;
			vObj.ClientTypeConfirmationText = vObj.Customer.ClientTypeConfirmationText;
		EndIf;
		// Customer remarks
		If Not IsBlankString(vObj.Customer.Remarks) And vObj.Customer.CopyRemarksToDocuments Then
			rIsHousekeepingRemarks = False;
			vCustRemarks = TrimAll(vObj.Customer.Remarks);
			vRemarks = cmGetRemarks(vCustRemarks, vObj.RoomType, rIsHousekeepingRemarks);
			If rIsHousekeepingRemarks Then
				vObj.HousekeepingRemarks = TrimAll(vRemarks + Chars.LF + TrimAll(vObj.HousekeepingRemarks));
			Else
				vObj.Remarks = TrimAll(vRemarks + Chars.LF + TrimAll(vObj.Remarks));
			EndIf;
		EndIf;
		// Contract
		If ValueIsFilled(vObj.Contract) Then
			If vObj.Contract.Owner <> vObj.Customer Then
				vObj.Contract = Catalogs.Contracts.EmptyRef();
			EndIf;
		EndIf;
		If Not ValueIsFilled(vObj.Contract) Then
			vDefaultContract = vObj.Customer.Contract;
			If ValueIsFilled(vDefaultContract) And ValueIsFilled(vDefaultContract.Hotel) And vDefaultContract.Hotel <> vObj.Hotel Then
				vDefaultContract = Undefined;
			EndIf;
			If Not ValueIsFilled(vDefaultContract) Then
				vValidContracts = cmGetListOfValidContracts(vObj.Customer, vObj.CheckInDate, vObj.CheckOutDate, ?(ValueIsFilled(vObj.GuestGroup), vObj.GuestGroup.CreateDate, vObj.Date), vObj.Hotel);
				If vValidContracts.Count() = 1 Then
					vDefaultContract = vValidContracts.Get(0).Value;
				EndIf;
			EndIf;
			If ValueIsFilled(vDefaultContract) Then
				vObj.Contract = vDefaultContract;
				vMessage = "";
				ContractOnChangeAtServer(vObj, vMessage);
				If Not IsBlankString(vMessage) Then
					tcCommonFunctionOnClientServer.UserMessage(vMessage);
				EndIf;
				// Load customer contact persons list
				LoadCustomerContactPersonsList(vObj);
				// Set object value
				If vUseParameterObject = False Then
					ValueToFormAttribute(vObj, "Object");
					// Calculate totals
					TotalSum = CalculateTotalServices(, , False, False);
					// Rebuild remarks panel header
					BuildThisObjectRemarksDataDecoration();
				EndIf;
				Return;
			EndIf;
		EndIf;
		// Do not print rate
		If vObj.Customer.DoNotPrintRate Then
			vObj.DoNotPrintRate = True;
		EndIf;
		// Check allotment
		vAllotment = vObj.RoomQuota;
		If ValueIsFilled(vAllotment) And vAllotment.CustomerOrContractChangeIsNotAllowed Then
			If ValueIsFilled(vAllotment.Customer) And vAllotment.Customer <> vObj.Customer Then
				vObj.RoomQuota = Catalogs.RoomQuotas.EmptyRef();
			EndIf;
		EndIf;
		// Calculate customer operational balance
		ShowCustomerOperationalBalance(True, vObj);
		// Check should we show customer related message or not
		If vObj.Customer.ShowRemarksInAccommodations And Not IsBlankString(vObj.Customer.Remarks) Then
			vUM = New UserMessage();
			vUM.SetData(vObj);
			vUM.Field = "Customer";
			vUM.Text = TrimR(vObj.Customer.Remarks);
			vUM.Message();
		EndIf;
	Else
		// Contact person
		vObj.ContactPerson = "";
		// Contract
		vObj.Contract = Catalogs.Contracts.EmptyRef();
		// Clear agent
		vObj.Agent = Catalogs.Customers.EmptyRef();
		vObj.AgentCommission = 0;
		vObj.AgentCommissionType = Undefined;
		vObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		// Remove customer charging rules if any
		RemoveCustomerChargingRules(vObj);
		// Reset customer operational balance
		ShowCustomerOperationalBalance(False, vObj);
	EndIf;
	// Operational agent commission turnovers
	If ValueIsFilled(vObj.Agent) Then
		// Calculate agent operational commission turnovers
		ShowAgentOperationalCommissionTurnovers(True, vObj); 
	Else
		// Reset agent operational commission turnovers
		ShowAgentOperationalCommissionTurnovers(False, vObj);
	EndIf;
	// Load customer contact persons list
	LoadCustomerContactPersonsList(vObj);
	// Discount
	vObj.pmSetDiscounts();
	// Charging rules
	vObj.pmLoadChargingRules(?(ValueIsFilled(vObj.Contract), vObj.Contract, vObj.Customer));
	// Fill table with valid room type/accommodation type combinations
	FillTypesTableAtServer(vObj);
	// Check that current accomodation type is in the list of valid types.
	// If not open selection with focus set on first valid one
	ResetAccommodationType("Customer", vObj);
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings, , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate)) Then
		If Not IsOnOpenForm Then
			tcCommonFunctionOnClientServer.UserMessage(tcOnServer.cmNStrAtServer(vWarnings));
		EndIf;
	EndIf;
	// Set planned payment method from the first charging rule
	Payer = vObj.pmSetPlannedPaymentMethod(TPayer);
	If Payer = Enums.WhoPays.ChargingRules Then
		Items.GroupChargingRules.Show();
	Else
		Items.GroupChargingRules.Hide();
	EndIf;
	// Save room rate
	SavRoomRate = vObj.RoomRate;
	// Refresh analitical parameters
	BuildThisObjectClientDataDecoration(vObj);
	// Build commission group hidden title
	BuildCommissionGroupCollapsedTitle(vObj);	
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle(vObj);
	// Build room rate group hidden title
	BuildRoomRateGroupCollapsedTitle(vObj);
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Calculate totals
	TotalSum = CalculateTotalServices(vObj, , False, False);
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
		// Terms choice list
		FillServicePackageChoiceList();
	EndIf;                            
	// Rebuild remarks panel header
	BuildThisObjectRemarksDataDecoration();
	// Show discounts
	If ValueIsFilled(Object.DiscountType) Or ValueIsFilled(Object.DiscountCard) Or Object.Discount <> 0 Then
		Items.GroupDiscounts.Show();
	EndIf;
EndProcedure // CustomerOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure LoadCustomerContactPersonsList(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	Items.ContactPerson.ChoiceList.Clear();
	If ValueIsFilled(vObj.Customer) Then
		vCPList = vObj.Customer.GetObject().pmLoadCustomerContactPersonsList();
		If vCPList.Count() > 0 Then
			Items.ContactPerson.ChoiceListButton = True;
			Items.ContactPerson.ChoiceList.LoadValues(vCPList.UnloadValues());
		Else
			Items.ContactPerson.ChoiceListButton = False;
		EndIf;
	Else
		Items.ContactPerson.ChoiceListButton = False;
	EndIf;
EndProcedure // LoadCustomerContactPersonsList	

// -----------------------------------------------------------------------------
&AtServer
Function GetContractRoomRate(pObj)
	vContractRoomRate = Undefined;
	If ValueIsFilled(pObj.Contract) Then
		vReservationDate = pObj.Date;
		If ValueIsFilled(pObj.GuestGroup) And ValueIsFilled(pObj.GuestGroup.CreateDate) Then
			vReservationDate = pObj.GuestGroup.CreateDate;
		EndIf;
		If ValueIsFilled(pObj.Contract.RoomRate) And (Not ValueIsFilled(pObj.Contract.RoomRate.Hotel) Or pObj.Contract.RoomRate.Hotel = pObj.Hotel) Then
			vContractRoomRate = pObj.Contract.RoomRate;
		EndIf;
		For Each vRRRow In pObj.Contract.RoomRates Do
			vRoomType = pObj.RoomType;
			If ValueIsFilled(pObj.RoomTypeUpgrade) Then
				vRoomType = pObj.RoomTypeUpgrade;
			EndIf;
			If ValueIsFilled(vRoomType) And ValueIsFilled(vRRRow.RoomType) Then
				If vRRRow.RoomType.IsFolder And Not vRoomType.BelongsToItem(vRRRow.RoomType) Then
					Continue;
				ElsIf Not vRRRow.RoomType.IsFolder And vRoomType <> vRRRow.RoomType Then 
					Continue;
				EndIf;
			EndIf;
			If ValueIsFilled(vRRRow.RoomRate) And (Not ValueIsFilled(vRRRow.RoomRate.Hotel) Or vRRRow.RoomRate.Hotel = pObj.Hotel) Then
				If Not ValueIsFilled(vRRRow.CheckInDateFrom) And Not ValueIsFilled(vRRRow.CheckInDateTo) And 
				   Not ValueIsFilled(vRRRow.ReservationDateFrom) And Not ValueIsFilled(vRRRow.ReservationDateTo) Then
					vContractRoomRate = vRRRow.RoomRate;
					Break;
				ElsIf (Not ValueIsFilled(vRRRow.ReservationDateFrom) Or ValueIsFilled(vRRRow.ReservationDateFrom) And vRRRow.ReservationDateFrom <= vReservationDate) And 
					  (Not ValueIsFilled(vRRRow.ReservationDateTo) Or ValueIsFilled(vRRRow.ReservationDateTo) And EndOfDay(vRRRow.ReservationDateTo) > vReservationDate) And 
					  (Not ValueIsFilled(vRRRow.CheckInDateFrom) Or ValueIsFilled(vRRRow.CheckInDateFrom) And vRRRow.CheckInDateFrom <= pObj.CheckInDate) And 
					  (Not ValueIsFilled(vRRRow.CheckInDateTo) Or ValueIsFilled(vRRRow.CheckInDateTo) And EndOfDay(vRRRow.CheckInDateTo) > pObj.CheckInDate) Then
					vContractRoomRate = vRRRow.RoomRate;
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vContractRoomRate;
EndFunction // GetContractRoomRate

// -----------------------------------------------------------------------------
&AtServer
Procedure ContractOnChangeAtServer(pObj = Undefined, rMessage = "", pDoNotChangeTerms = False)
	rMessage = "";
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	// Get object value
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Save current payment method
	vPrevPlannedPaymentMethod = vObj.PlannedPaymentMethod;
	// Check if contract is valid
	If ValueIsFilled(vObj.Contract) Then
		vValidContracts = cmGetListOfValidContracts(vObj.Contract.Owner, vObj.CheckInDate, '00010101', ?(ValueIsFilled(vObj.GuestGroup), vObj.GuestGroup.CreateDate, vObj.Date), vObj.Hotel);
		If vValidContracts.FindByValue(vObj.Contract) = Undefined Then
			rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF) + NStr("en='Contract is not valid! '; ru='Договор нельзя использовать! '; de='Vertrag ist nicht gültig! '") + TrimAll(vObj.Contract.Description);
			vObj.Contract = Undefined;
		EndIf;
	EndIf;
	// Process contract change
	If ValueIsFilled(vObj.Contract) Then
		vContract = vObj.Contract;
		// Room quota
		If ValueIsFilled(vContract.RoomQuota) Then
			vObj.RoomQuota = vContract.RoomQuota;
			// Check allotment company
			If ValueIsFilled(vObj.RoomQuota.Company) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) And vObj.RoomQuota.Company <> SessionParameters.CurrentUser.Company Then
				vObj.RoomQuota = Catalogs.RoomQuotas.EmptyRef();
				rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF) + NStr("en='You do not have rights to use " + TrimAll(vObj.RoomQuota.Company) + " company allotment!'; ru='Нет прав использовать квоту компании " + TrimAll(vObj.RoomQuota.Company) + "!'; de='Sie sind nicht berechtigt, die Zimmerquote der Firma " + TrimAll(vObj.RoomQuota.Company) + " verwenden!'");
			EndIf;
			If ValueIsFilled(vObj.RoomQuota) And ValueIsFilled(vObj.RoomQuota.Company) Then
				vObj.Company = vObj.RoomQuota.Company;
			EndIf;
		EndIf;
		// Planned payment method
		If Not ValueIsFilled(vObj.ParentDoc) Then
			If ValueIsFilled(vContract.PlannedPaymentMethod) Then
				vObj.PlannedPaymentMethod = vContract.PlannedPaymentMethod;
			EndIf;
		EndIf;
		// Agent commission
		If Not vContract.IsSubagent Then
			vObj.Agent = vContract.Agent;
			If ValueIsFilled(vObj.Customer) And ValueIsFilled(vContract.AgentCommissionType) Then
				If Not ValueIsFilled(vObj.Agent) Then
					vObj.Agent = vObj.Customer;
				EndIf;
				vObj.AgentCommission = vContract.AgentCommission;
				vObj.AgentCommissionType = vContract.AgentCommissionType;
				vObj.AgentCommissionServiceGroup = vContract.AgentCommissionServiceGroup;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vObj.Agent) Then
			vObj.AgentCommission = 0;
			vObj.AgentCommissionType = Undefined;
			vObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		EndIf;
		// Room rate
		vContractRoomRate = GetContractRoomRate(vObj);
		If ValueIsFilled(vContractRoomRate) Then
			If vObj.RoomRate <> vContractRoomRate Then
				vObj.PriceCalculationDate = '00010101';
			EndIf;
			vObj.RoomRate = vContractRoomRate;
			vObj.RoomRateType = vObj.RoomRate.RoomRateType;
			SetDurationCaption(vObj);
			vObj.RoomRateServiceGroup = vContract.RoomRateServiceGroup;
			vObj.DoNotPrintRate = vObj.RoomRate.DoNotPrintRate;
			// Source of business
			If ValueIsFilled(vObj.RoomRate.SourceOfBusiness) Then
				vObj.SourceOfBusiness = vObj.RoomRate.SourceOfBusiness;
			EndIf;
			// Marketing code
			If ValueIsFilled(vObj.RoomRate.MarketingCode) Then
				vObj.MarketingCode = vObj.RoomRate.MarketingCode;
			EndIf;
			// Client type
			If ValueIsFilled(vObj.RoomRate.ClientType) Then
				vObj.ClientType = vObj.RoomRate.ClientType;
				vObj.ClientTypeConfirmationText = vObj.RoomRate.ClientTypeConfirmationText;
			EndIf;
			// Company
			If ValueIsFilled(vObj.RoomRate.Company) Then
				vObj.Company = vObj.RoomRate.Company;
			EndIf;
			// Allotment
			If ValueIsFilled(vObj.RoomRate.Allotment) And vObj.RoomQuota <> vObj.RoomRate.Allotment Then
				vObj.RoomQuota = vObj.RoomRate.Allotment;
				// Company
				If ValueIsFilled(vObj.RoomQuota.Company) And vObj.RoomQuota.Company <> vObj.Company Then
					vObj.Company = vObj.RoomQuota.Company;
				EndIf;
			EndIf;
		EndIf;
		// Contract company
		If ValueIsFilled(vContract.Company) Then
			vObj.Company = vContract.Company;
		EndIf;
		// Marketing code
		If ValueIsFilled(vContract.MarketingCode) Then
			vObj.MarketingCode = vContract.MarketingCode;
			vObj.MarketingCodeConfirmationText = "";
		EndIf;
		// Source of business
		If ValueIsFilled(vContract.SourceOfBusiness) Then
			vObj.SourceOfBusiness = vContract.SourceOfBusiness;
		EndIf;
		// Client type
		If ValueIsFilled(vContract.ClientType) And (Not ValueIsFilled(vContract.ClientType.Hotel) Or vContract.ClientType.Hotel = vObj.Hotel) Then
			vObj.ClientType = vContract.ClientType;
			vObj.ClientTypeConfirmationText = vContract.ClientTypeConfirmationText;
		EndIf;
		// Do not print rate
		If vContract.DoNotPrintRate Then
			vObj.DoNotPrintRate = True;
		EndIf;
		// Meal board term
		If Items.ServicePackage.Visible Then
			If ValueIsFilled(vContract.MealBoardTerm) And Not pDoNotChangeTerms Then
				If Not ValueIsFilled(vObj.ServicePackage) Then
					vObj.ServicePackage = vContract.MealBoardTerm;
				EndIf;
			EndIf;
			vTermsArray = GetMealBoardTermsList(vObj.Hotel, vContract).UnloadValues();
			Items.ServicePackage.ChoiceList.LoadValues(vTermsArray);
			Items.ServicePackageBeforeUpgrade.ChoiceList.LoadValues(vTermsArray);
		EndIf;
		// Check allotment
		vAllotment = vObj.RoomQuota;
		If ValueIsFilled(vAllotment) And vAllotment.CustomerOrContractChangeIsNotAllowed Then
			If ValueIsFilled(vAllotment.Contract) And vAllotment.Contract <> vObj.Contract Then
				vObj.RoomQuota = Catalogs.RoomQuotas.EmptyRef();
			ElsIf ValueIsFilled(vAllotment.Customer) And vAllotment.Customer <> vObj.Customer Then
				vObj.RoomQuota = Catalogs.RoomQuotas.EmptyRef();
			EndIf;
		EndIf;
		// Check overallotment
		If Not vObj.Posted And Not vObj.IsByReservation And ValueIsFilled(vContract) And ValueIsFilled(vContract.RoomQuota) And vObj.RoomQuota = vContract.RoomQuota Then
			If ValueIsFilled(vObj.RoomQuota) Then
				If ValueIsFilled(vObj.RoomQuota.OverAllotmentRoomRate) And vObj.RoomRate <> vObj.RoomQuota.OverAllotmentRoomRate Or 
				   ValueIsFilled(vObj.RoomQuota.OverAllotmentContract) And vObj.Contract <> vObj.RoomQuota.OverAllotmentContract Then
					vAttrInError = "";
					vOverAllotmentMessage = CheckOverallotment(vObj, vAttrInError);
					If Not IsBlankString(vOverAllotmentMessage) Then
						vUM = New UserMessage();
						vUM.SetData(vObj);
						vUM.Field = vAttrInError;
						vUM.Text = vOverAllotmentMessage;
						vUM.Message();
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Charging rules
		vObj.pmLoadChargingRules(vContract);
		// Calculate contract operational balance
		ShowCustomerOperationalBalance(True, vObj);
	Else
		vObj.Agent = Catalogs.Customers.EmptyRef();
		vObj.AgentCommission = 0;
		vObj.AgentCommissionType = Undefined;
		vObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		// Clear commission from accommodation plan
		ClearRoomRatesCommission(vObj);
		// Room rate
		vOldRoomRate = vObj.RoomRate;
		vRoomRateWasUpdated = False;
		If ValueIsFilled(vObj.Customer) Then
			vObj.RoomRateServiceGroup = vObj.Customer.RoomRateServiceGroup;
			If ValueIsFilled(vObj.Customer.RoomRate) And (Not ValueIsFilled(vObj.Customer.RoomRate.Hotel) Or vObj.Customer.RoomRate.Hotel = vObj.Hotel) Then
				vRoomRateWasUpdated = True;
				If vObj.RoomRate <> vObj.Customer.RoomRate Then
					vObj.PriceCalculationDate = '00010101';
				EndIf;
				vObj.RoomRate = vObj.Customer.RoomRate;
			ElsIf vObj.Customer.RoomRates.Count() > 0 Then
				vRoomRatesAllowed = cmGetAllowedRoomRates(vObj.CheckInDate, vObj.CheckOutDate, vObj.Date, vObj.RoomType, vObj.Hotel);
				If vRoomRatesAllowed.Count() > 0 Then
					For Each vRRRow In vObj.Customer.RoomRates Do
						vRRRowRate = vRRRow.RoomRate;
						If ValueIsFilled(vRRRowRate) And (Not ValueIsFilled(vRRRowRate.Hotel) Or vRRRowRate.Hotel = vObj.Hotel) Then
							If vRoomRatesAllowed.FindByValue(vRRRowRate) <> Undefined Then
								vRoomRateWasUpdated = True;
								vObj.RoomRate = vRRRowRate;
								If vObj.RoomRate <> vOldRoomRate Then
									vObj.PriceCalculationDate = '00010101';
								EndIf;
								Break;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
			// Check if room rate was updated
			If vRoomRateWasUpdated Then
				vObj.RoomRateType = vObj.RoomRate.RoomRateType;
				SetDurationCaption(vObj);
				vObj.DoNotPrintRate = vObj.RoomRate.DoNotPrintRate;
				// Source of business
				If ValueIsFilled(vObj.RoomRate.SourceOfBusiness) Then
					vObj.SourceOfBusiness = vObj.RoomRate.SourceOfBusiness;
				EndIf;
				// Marketing code
				If ValueIsFilled(vObj.RoomRate.MarketingCode) Then
					vObj.MarketingCode = vObj.RoomRate.MarketingCode;
				EndIf;
				// Client type
				If ValueIsFilled(vObj.RoomRate.ClientType) Then
					vObj.ClientType = vObj.RoomRate.ClientType;
					vObj.ClientTypeConfirmationText = vObj.RoomRate.ClientTypeConfirmationText;
				EndIf;
				// Company
				If ValueIsFilled(vObj.RoomRate.Company) Then
					vObj.Company = vObj.RoomRate.Company;
				EndIf;
				// Allotment
				If ValueIsFilled(vObj.RoomRate.Allotment) And vObj.RoomQuota <> vObj.RoomRate.Allotment Then
					vObj.RoomQuota = vObj.RoomRate.Allotment;
					// Company
					If ValueIsFilled(vObj.RoomQuota.Company) And vObj.RoomQuota.Company <> vObj.Company Then
						vObj.Company = vObj.RoomQuota.Company;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Charging rules
		vObj.pmLoadChargingRules(vObj.Customer);
		// Operational balance
		If ValueIsFilled(vObj.Customer) Then
			// Calculate customer operational balance
			ShowCustomerOperationalBalance(True, vObj); 
		Else
			// Reset customer operational balance
			ShowCustomerOperationalBalance(False, vObj);
		EndIf;
	EndIf;
	// Operational agent commission turnovers
	If ValueIsFilled(vObj.Agent) Then
		// Calculate agent operational commission turnovers
		ShowAgentOperationalCommissionTurnovers(True, vObj); 
	Else
		// Reset agent operational commission turnovers
		ShowAgentOperationalCommissionTurnovers(False, vObj);
	EndIf;
	// Check should we switch guest group to the complex mode
	If ValueIsFilled(vObj.ParentDoc) And TypeOf(vObj.ParentDoc) = Type("DocumentRef.Reservation") Then
		If ValueIsFilled(vObj.GuestGroup) And vObj.GuestGroup = vObj.ParentDoc.GuestGroup And 
		   cm0SecondShift(vObj.CheckInDate) = cm0SecondShift(vObj.ParentDoc.CheckOutDate) Then
			If vObj.AgentCommission <> vObj.ParentDoc.AgentCommission Then
				vGuestGroupObj = vObj.GuestGroup.GetObject();
				vGuestGroupObj.OneCustomerPerGuestGroup = False;
				vGuestGroupObj.Write();
			EndIf;
		EndIf;
	EndIf;
	// Discount
	vObj.pmSetDiscounts();
	// Fill table with valid room type/accommodation type combinations
	FillTypesTableAtServer(vObj);
	// Check that current accomodation type is in the list of valid types.
	// If not open selection with focus set on first valid one
	ResetAccommodationType("Contract", vObj); 
	// Automatic services list calculation	
	vWarnings = "";
	If vObj.pmCalculateServices(vWarnings, , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate)) Then
		rMessage = rMessage + ?(IsBlankString(rMessage), "", Chars.LF) + tcOnServer.cmNStrAtServer(vWarnings);
	EndIf;
	// Set planned payment method from the first charging rule
	Payer = vObj.pmSetPlannedPaymentMethod(TPayer);
	If Payer = Enums.WhoPays.ChargingRules Then
		Items.GroupChargingRules.Show();
	Else
		Items.GroupChargingRules.Hide();
	EndIf;
	// Save room rate
	SavRoomRate = vObj.RoomRate;
	// Check if planned payment method has changed
	If vObj.PlannedPaymentMethod <> vPrevPlannedPaymentMethod Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Planned payment method has changed!';ru='Изменился планируемый способ оплаты!';de='Die geplante Zahlungsmethode hat sich geändert!'"));
	EndIf;
	// Refresh analitical parameters
	BuildThisObjectClientDataDecoration(vObj);
	// Build commission group hidden title
	BuildCommissionGroupCollapsedTitle(vObj);
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle(vObj);
	// Build room rate group hidden title
	BuildRoomRateGroupCollapsedTitle(vObj);
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Set object value
	If Not vUseParameterObject Then
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		TotalSum = CalculateTotalServices(, , False, False);
		// Terms choice list
		FillServicePackageChoiceList();
	EndIf;
	// Show discounts
	If ValueIsFilled(Object.DiscountType) Or ValueIsFilled(Object.DiscountCard) Or Object.Discount <> 0 Then
		Items.GroupDiscounts.Show();
	EndIf;
EndProcedure // ContractOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ShowCustomerOperationalBalance(pShow = True, pObj = Undefined)
	// Check parameters
	If pShow = Undefined Then
		pShow = True;
	EndIf;
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If cmCheckUserPermissions("HavePermissionToViewCustomerOperationalBalance") And pShow Then
		// Customer operational balance
		vCustBalanceCurrency = Undefined;
		vCustBalance = cmCalculateCustomerOperationalBalance(vObj.Customer, vObj.Contract, vObj.Hotel, , vCustBalanceCurrency);
		TCustomerOperationalBalance = cmFormatSum(vCustBalance, vCustBalanceCurrency);
	Else
		TCustomerOperationalBalance = "";
	EndIf;
EndProcedure // ShowCustomerOperationalBalance

// -----------------------------------------------------------------------------
&AtServer
Procedure ShowAgentOperationalCommissionTurnovers(pShow = True, pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If pShow = Undefined Then
		pShow = True;
	EndIf;
	If pShow And cmCheckUserPermissions("HavePermissionToViewCustomerOperationalBalance") And 
	   ValueIsFilled(vObj.Agent) And (ValueIsFilled(vObj.Contract) And vObj.Customer = vObj.Agent Or vObj.Customer <> vObj.Agent And ValueIsFilled(vObj.Agent.AgentCommissionContract)) Then
		// Agent commission turnovers
		vAgentCommissionCurrency = Undefined;
		vAgentCommission = cmCalculateAgentCommissionTurnovers(vObj.Agent, vObj.Agent, ?(ValueIsFilled(vObj.Contract) And vObj.Customer = vObj.Agent, vObj.Contract, vObj.Agent.AgentCommissionContract), vObj.Hotel, , , vAgentCommissionCurrency);
		TAgentOperationalCommissionTurnovers = cmFormatSum(vAgentCommission, vAgentCommissionCurrency);
	Else
		TAgentOperationalCommissionTurnovers = "";
	EndIf;
EndProcedure // ShowAgentOperationalCommissionTurnovers

// -----------------------------------------------------------------------------
&AtServer
Procedure ResetAccommodationType(pItemName, pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	vResetAccommodationType = False;
	If ValueIsFilled(vObj.RoomType) Then
		vTypesTable = FormAttributeToValue("TypesTable");
		If ValueIsFilled(vObj.AccommodationType) Then
			vArray = vTypesTable.FindRows(New Structure("RoomType, AccommodationType", vObj.RoomType, vObj.AccommodationType));
			If vArray.Count() = 0 And ValueIsFilled(vObj.RoomTypeUpgrade) Then
				vTypesTable = vObj.pmFillTypesTable(, vObj.RoomTypeUpgrade);
				vArray = vTypesTable.FindRows(New Structure("RoomType, AccommodationType", vObj.RoomTypeUpgrade, vObj.AccommodationType));
				If vArray.Count() > 0 Then
					ValueToFormAttribute(vTypesTable, "TypesTable");
				EndIf;
			EndIf;
			If vArray.Count() = 0 Then
				vResetAccommodationType = True;
			EndIf;
		Else
			vResetAccommodationType = True;
		EndIf;
		If vResetAccommodationType Then
			vArray = vTypesTable.FindRows(New Structure("RoomType", vObj.RoomType));
			For Each vEl In vArray Do
				If pItemName = "RoomType" Then
					vObj.AccommodationType = vEl.AccommodationType;
					AccommodationTypeOnChangeAtServer(True, vObj);
				EndIf;
				Break;
			EndDo;
		EndIf;
	EndIf;
	ThisObject.Modified = True;
EndProcedure // ResetAccommodationType

// -----------------------------------------------------------------------------
&AtServer
Procedure AccommodationTypeOnChangeAtServer(pRecalculateServices = True, pObj = Undefined, pCheckIsForFolioSplit = False)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;		
	EndIf;
	If pRecalculateServices = Undefined Then
		pRecalculateServices = True;
	EndIf;
	// Check if accommodation type corresponds to the first template accommodation type
	If pCheckIsForFolioSplit And Not OneGuestMode And ValueIsFilled(vObj.AccommodationTemplate) And ValueIsFilled(vObj.AccommodationType) Then
		vAccommodationTypes = vObj.AccommodationTemplate.AccommodationTypes;
		If vAccommodationTypes.Count() > 0 Then
			If vAccommodationTypes.Get(0).AccommodationType <> vObj.AccommodationType Then
				If Not vObj.IsForFolioSplit Then
					vObj.IsForFolioSplit = True;
				EndIf;
			Else
				If vObj.IsForFolioSplit <> vObj.AccommodationTemplate.IsForFolioSplit Then
					vObj.IsForFolioSplit = vObj.AccommodationTemplate.IsForFolioSplit;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Update first room rates row
	If ValueIsFilled(vObj.AccommodationType) And vObj.RoomRates.Count() > 0 Then
		v1RRRow = vObj.RoomRates.Find(BegOfDay(vObj.CheckInDate), "AccountingDate");
		If v1RRRow = Undefined Then
			v1RRRow = vObj.RoomRates.Insert(0);
			v1RRRow.AccountingDate = BegOfDay(vObj.CheckInDate);
		EndIf;
		v1RRRow.AccommodationType = vObj.AccommodationType;
		vObj.RoomRates.Sort("AccountingDate, ChangeTime");
	EndIf;
	// Calculate resources
	vObj.pmCalculateResources();
	// Automatic services list calculation
	If pRecalculateServices Then
		// Calculate totals
		TotalSum = CalculateTotalServices(vObj, , False, False);
	EndIf;
	If vObj.Posted And BegOfDay(CurrentSessionDate()) >= BegOfDay(vObj.CheckInDate) And 
	   ValueIsFilled(vObj.AccommodationStatus) And vObj.AccommodationStatus.IsInHouse Then
		// Do change room
		DoChangeRoom(vObj);
	EndIf;
	If vUseParameterObject = False Then		
		// Set object value
		ValueToFormAttribute(vObj, "Object");
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
EndProcedure // AccommodationTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Function AccommodationTypeStartChoiceAtClient(pNoRoom = False)
	vChooseList = New ValueList;
	If ValueIsFilled(Object.RoomType) Then
		vArray = TypesTable.FindRows(New Structure("RoomType", Object.RoomType));
		For Each vTypesTableRow In vArray Do
			If vChooseList.FindByValue(vTypesTableRow.AccommodationType) = Undefined Then
				If pNoRoom Then
					If tcOnServer.cmGetAttributeByRef(vTypesTableRow.AccommodationType, "NumberOfRooms") <> 0 Then
						Continue;
					Else
						vChooseList.Add(vTypesTableRow.AccommodationType);
					EndIf;
				Else
					vChooseList.Add(vTypesTableRow.AccommodationType);
				EndIf;
			EndIf;
		EndDo;
	Else
		For Each vTypesTableRow In TypesTable Do
			If vChooseList.FindByValue(vTypesTableRow.AccommodationType) = Undefined Then
				If pNoRoom Then
					If tcOnServer.cmGetAttributeByRef(vTypesTableRow.AccommodationType, "NumberOfRooms") <> 0 Then
						Continue;
					Else
						vChooseList.Add(vTypesTableRow.AccommodationType);
					EndIf;
				Else
					vChooseList.Add(vTypesTableRow.AccommodationType);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vChooseList;
EndFunction // AccommodationTypeStartChoiceAtClient

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomTypeOnChangeAtServer(pRecalculateServices = True, pRecalculateDiscounts = False, pObj = Undefined)
	ChangeRoomMessageText = "";
	Items.ChangeRoomMessageTextGroup.Visible = False;
	// Check parameters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	If pRecalculateServices = Undefined Then
		pRecalculateServices = True;
	EndIf;
	vSavPriceCalculationDate = vObj.PriceCalculationDate;
	If ValueIsFilled(vObj.RoomType) Then
		// Check room
		If Not vObj.RoomType.IsFolder Then
			// Check virtual room type
			If ValueIsFilled(vObj.RoomType.BaseRoomType) Then
				vObj.RoomTypeUpgrade = vObj.RoomType;
				vObj.RoomType = vObj.RoomType.BaseRoomType;
				RoomPrice = 0;
				IsManualRoomPrice = 2;
				Items.RoomPrice.Visible = False;
				Items.RoomTypeUpgrade.Visible = True;
				// Build room rate group hidden title
				BuildRoomRateGroupCollapsedTitle(vObj);
			EndIf;
			If ValueIsFilled(vObj.Room) Then
				vRoomAttrs = vObj.Room.GetObject().pmGetRoomAttributes(cm1SecondShift(vObj.CheckInDate));
				For Each vRoomAttrsRow In vRoomAttrs Do
					If vObj.RoomType <> vRoomAttrsRow.RoomType Then
						vObj.Room = Catalogs.Rooms.EmptyRef();
					EndIf;
					Break;
				EndDo;
			EndIf;
		EndIf;
		// Check if hotel was changed
		If vObj.RoomType.Owner <> vObj.Hotel Then
			vObj.Hotel = vObj.RoomType.Owner;
			vObj.pmProcessHotelChange();
		EndIf;
		// Company
		If ValueIsFilled(vObj.RoomType.Company) Then
			If vObj.Company <> vObj.RoomType.Company And (Not ValueIsFilled(vObj.Contract) OR ValueIsFilled(vObj.Contract) And Not ValueIsFilled(vObj.Contract.Company)) Then
				If CompanyCouldBeChanged(vObj, vObj.AccommodationStatus) Then
					vObj.Company = vObj.RoomType.Company;
				EndIf;
			EndIf;
		EndIf;
		// Check overallotment
		If Not vObj.Posted And Not vObj.IsByReservation And ValueIsFilled(vObj.RoomQuota) Then
			If ValueIsFilled(vObj.RoomQuota.OverAllotmentRoomRate) And vObj.RoomRate <> vObj.RoomQuota.OverAllotmentRoomRate Or 
			   ValueIsFilled(vObj.RoomQuota.OverAllotmentContract) And vObj.Contract <> vObj.RoomQuota.OverAllotmentContract Then
				vAttrInError = "";
				vOverAllotmentMessage = CheckOverallotment(vObj, vAttrInError);
				If Not IsBlankString(vOverAllotmentMessage) Then
					vUM = New UserMessage();
					vUM.SetData(vObj);
					vUM.Field = vAttrInError;
					vUM.Text = vOverAllotmentMessage;
					vUM.Message();
				EndIf;
			EndIf;
		EndIf;
		// Fill default beds
		If ValueIsFilled(vObj.RoomType.DefaultBedsSetup) And Not ValueIsFilled(vObj.BedsSetup) Then
			vObj.BedsSetup = vObj.RoomType.DefaultBedsSetup;
			// Form appearance
			BuildThisObjectClientDataDecoration(vObj);
		EndIf;
	EndIf;
	// Fill table with valid room type/accommodation type combinations
	FillTypesTableAtServer(vObj);
	// Calculate resources
	vObj.pmCalculateResources();
	// Recalculate discounts
	If pRecalculateDiscounts <> Undefined And pRecalculateDiscounts Then
		vObj.pmSetDiscounts();
	EndIf;	
	// Check that current accomodation type is in the list of valid types.
	// If not reset it to the first valid one
	ResetAccommodationType("RoomType", vObj);
	// Get accommodation types
	CheckGuestFieldCount(vObj);
	// Automatic services list calculation
	If pRecalculateServices Then
		// Calculate totals
		TotalSum = CalculateTotalServices(vObj, , False, False);
	EndIf;
	If vObj.Posted And BegOfDay(CurrentSessionDate()) >= BegOfDay(vObj.CheckInDate) And 
	   ValueIsFilled(vObj.AccommodationStatus) And vObj.AccommodationStatus.IsInHouse Then
		// Do change room
		DoChangeRoom(vObj);
	EndIf;
	// Price calculation date reset for other guests in the room
	If vSavPriceCalculationDate <> vObj.PriceCalculationDate Then
		For Each vGGRow In GuestsInGroup Do
			vGGRow.PriceCalculationDateShouldBeUpdated = True;
		EndDo;
	EndIf;
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle(vObj);
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Set object value
	If vUseParameterObject = False Then	
		ValueToFormAttribute(vObj, "Object");
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
EndProcedure // RoomTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutDateOnChangeAtServer(pObj = Undefined, pIsOnOpenForm = False) Export
	Modified = True;
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	// Get object value
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	If vObj.CheckOutDate < vObj.CheckInDate Then
		vObj.Duration = 1;
		vObj.CheckOutDate = vObj.pmCalculateCheckOutDate();
	Else
		// Calculate duration
		vObj.Duration = vObj.pmCalculateDuration();
	EndIf;
	CheckInTime = cmExtractTime(vObj.CheckInDate);
	CheckOutTime = cmExtractTime(vObj.CheckOutDate);
	// Update price calculation date
	vObj.pmUpdatePriceCalculationDate();
	// Read foreigner registry documents
	ReadForeignerRegistryDocuments(vObj);
	// Fill check-in/check-out day of week names
	If ValueIsFilled(vObj.CheckInDate) Then
		CheckInDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(vObj.CheckInDate)));
	Else
		CheckInDayOfWeek = "";
	EndIf;
	If ValueIsFilled(vObj.CheckOutDate) Then
		CheckOutDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(vObj.CheckOutDate)));
	Else
		CheckOutDayOfWeek = "";
	EndIf;
	// Check overallotment
	If Not vObj.Posted And Not vObj.IsByReservation And ValueIsFilled(vObj.RoomQuota) Then
		If ValueIsFilled(vObj.RoomQuota.OverAllotmentRoomRate) And vObj.RoomRate <> vObj.RoomQuota.OverAllotmentRoomRate Or 
		   ValueIsFilled(vObj.RoomQuota.OverAllotmentContract) And vObj.Contract <> vObj.RoomQuota.OverAllotmentContract Then
			vAttrInError = "";
			vOverAllotmentMessage = CheckOverallotment(vObj, vAttrInError);
			If Not IsBlankString(vOverAllotmentMessage) Then 
				tcCommonFunctionOnClientServer.UserMessage(vOverAllotmentMessage, vObj, vAttrInError, , True);
			EndIf;
		EndIf;
	EndIf;
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;

	If Not IsOnOpenForm And Not pIsOnOpenForm Then
		// Calculate totals
		If ValueIsFilled(Object.RoomType) And Object.Duration < 60 Then
			// In case of mistake in a year it's too long to wait for calculation for mistakenly long period
			TotalSum = CalculateTotalServices(, , False, False);
		Else
			TotalSum = CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // CheckOutDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckInDateOnChangeAtServer(pObj = Undefined, pIsOnOpenForm = False) Export 
	Modified = True;
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	// Get object value
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	If ValueIsFilled(vObj.RoomRate) Then
		If ValueIsFilled(vObj.RoomRate.DefaultCheckInTime) Or ValueIsFilled(vObj.RoomRate.DefaultCheckOutTime) Then
			vObj.CheckInDate = cm1SecondShift(BegOfDay(vObj.CheckInDate)+(vObj.RoomRate.DefaultCheckInTime-BegOfDay(vObj.RoomRate.DefaultCheckInTime)));
		ElsIf ValueIsFilled(vObj.RoomRate.ReferenceHour) Then
			vObj.CheckInDate = cm1SecondShift(BegOfDay(vObj.CheckInDate)+(vObj.RoomRate.ReferenceHour-BegOfDay(vObj.RoomRate.ReferenceHour)));
		Else
			vObj.CheckInDate = cm1SecondShift(BegOfDay(vObj.CheckInDate) + (CurrentSessionDate() - BegOfDay(CurrentSessionDate())));
		EndIf;
		CheckInTime = cmExtractTime(vObj.CheckInDate);
	EndIf;
	If vObj.CheckInDate > vObj.CheckOutDate Then
		vObj.Duration = 1;
		// Calculate check out date
		vObj.CheckOutDate = vObj.pmCalculateCheckOutDate();
		CheckOutTime = cmExtractTime(vObj.CheckOutDate);
	Else
		// Calculate duration
		vObj.Duration = vObj.pmCalculateDuration();
	EndIf;
	// Check overallotment
	If Not vObj.Posted And Not vObj.IsByReservation And ValueIsFilled(vObj.RoomQuota) Then
		If ValueIsFilled(vObj.RoomQuota.OverAllotmentRoomRate) And vObj.RoomRate <> vObj.RoomQuota.OverAllotmentRoomRate Or 
		   ValueIsFilled(vObj.RoomQuota.OverAllotmentContract) And vObj.Contract <> vObj.RoomQuota.OverAllotmentContract Then
			vAttrInError = "";
			vOverAllotmentMessage = CheckOverallotment(vObj, vAttrInError);
			If Not IsBlankString(vOverAllotmentMessage) Then    
				tcCommonFunctionOnClientServer.UserMessage(vOverAllotmentMessage, vObj, vAttrInError, , True);
			EndIf;
		EndIf;
	EndIf;
	// Update price calculation date
	vObj.pmUpdatePriceCalculationDate();
	// Set discounts
	vObj.pmSetDiscounts();
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	// Fill check-in/check-out day of week names
	If ValueIsFilled(vObj.CheckInDate) Then
		CheckInDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(vObj.CheckInDate)));
	Else
		CheckInDayOfWeek = "";
	EndIf;
	If ValueIsFilled(vObj.CheckOutDate) Then
		CheckOutDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(vObj.CheckOutDate)));
	Else
		CheckOutDayOfWeek = "";
	EndIf;
	
	If Not IsOnOpenForm And Not pIsOnOpenForm Then
		// Calculate totals
		If ValueIsFilled(Object.RoomType) And Object.Duration < 60 Then
			TotalSum = CalculateTotalServices(, , False, False);
		Else
			// In case of mistake in a year it's too long to wait for calculation for mistakenly long period
			TotalSum = CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // CheckInDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DurationOnChangeAtServer(pObj = Undefined, pIsOnOpenForm = False)   
	Modified = True;
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	// Get object value
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Calculate check out date
	vObj.CheckOutDate = vObj.pmCalculateCheckOutDate();
	// Extract check-out time
	CheckOutTime = cmExtractTime(vObj.CheckOutDate);
	// Update price calculation date
	vObj.pmUpdatePriceCalculationDate();
	// Read foreigner registry documents
	ReadForeignerRegistryDocuments(vObj);
	// Check overallotment
	If Not vObj.Posted And Not vObj.IsByReservation And ValueIsFilled(vObj.RoomQuota) Then
		If ValueIsFilled(vObj.RoomQuota.OverAllotmentRoomRate) And vObj.RoomRate <> vObj.RoomQuota.OverAllotmentRoomRate Or 
		   ValueIsFilled(vObj.RoomQuota.OverAllotmentContract) And vObj.Contract <> vObj.RoomQuota.OverAllotmentContract Then
			vAttrInError = "";
			vOverAllotmentMessage = CheckOverallotment(vObj, vAttrInError);
			If Not IsBlankString(vOverAllotmentMessage) Then     
				tcCommonFunctionOnClientServer.UserMessage(vOverAllotmentMessage, vObj, vAttrInError, , True);
			EndIf;
		EndIf;
	EndIf;
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	// Fill check-in/check-out day of week names
	If ValueIsFilled(vObj.CheckInDate) Then
		CheckInDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(vObj.CheckInDate)));
	Else
		CheckInDayOfWeek = "";
	EndIf;
	If ValueIsFilled(vObj.CheckOutDate) Then
		CheckOutDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(vObj.CheckOutDate)));
	Else
		CheckOutDayOfWeek = "";
	EndIf;

	If Not IsOnOpenForm And Not pIsOnOpenForm Then
		// Calculate totals
		If ValueIsFilled(Object.RoomType) And Object.Duration < 60 Then
			TotalSum = CalculateTotalServices(, , False, False);
		Else
			// In case of mistake in a year it's too long to wait for calculation for mistakenly long period
			TotalSum = CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // DurationOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomQuotaOnChangeAtServer(pRecalculateServices = True, pObj = Undefined, pDoNotChangeTerms = False)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	// Get object value
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	If ValueIsFilled(vObj.RoomQuota) Then
		// Check allotment company
		If ValueIsFilled(vObj.RoomQuota.Company) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) And 
		   vObj.RoomQuota.Company <> SessionParameters.CurrentUser.Company Then
			vObj.RoomQuota = Catalogs.RoomQuotas.EmptyRef();
			vMessage = NStr("en='You do not have rights to use " + TrimAll(vObj.RoomQuota.Company) + " company allotment!'; ru='Нет прав использовать квоту компании " + TrimAll(vObj.RoomQuota.Company) + "!'; de='Sie sind nicht berechtigt, die Zimmerquote der Firma " + TrimAll(vObj.RoomQuota.Company) + " verwenden!'");
			vUM = New UserMessage();
			vUM.SetData(vObj);
			vUM.Field = "RoomQuota";
			vUM.Text = vMessage;
			vUM.Message();
			// Set object value
			If vUseParameterObject = False Then
				ValueToFormAttribute(vObj, "Object");
			EndIf;
			Return;
		EndIf;
		// Room rate type
		If ValueIsFilled(vObj.RoomQuota.RoomRate) And ValueIsFilled(vObj.RoomQuota.RoomRate.RoomRateType) Then
			vObj.RoomRateType = vObj.RoomQuota.RoomRate.RoomRateType;
		EndIf;
		// Agent
		If ValueIsFilled(vObj.RoomQuota.Agent) Then
			vObj.Agent = vObj.RoomQuota.Agent;
		EndIf;
		// Customer
		vCustomerWasChanged = False;
		If ValueIsFilled(vObj.RoomQuota.Customer) And vObj.Customer <> vObj.RoomQuota.Customer Then
			vObj.Customer = vObj.RoomQuota.Customer;
			vCustomerWasChanged = True;
			// Customer type
			vObj.CustomerType = vObj.Customer.CustomerType;
			// Contact person
			vObj.ContactPerson = "";
			If IsBlankString(vObj.ContactPerson) Then
				If Not IsBlankString(vObj.Customer.ContactPerson) Then
					vObj.ContactPerson = TrimR(vObj.Customer.ContactPerson);
				EndIf;
			EndIf;
			// Load customer contact persons list
			LoadCustomerContactPersonsList(vObj);
			// Room rate
			If ValueIsFilled(vObj.Customer.RoomRate) And (Not ValueIsFilled(vObj.Customer.RoomRate.Hotel) Or vObj.Customer.RoomRate.Hotel = vObj.Hotel) Then
				If vObj.RoomRate <> vObj.Customer.RoomRate Then
					vObj.PriceCalculationDate = '00010101';
				EndIf;
				vObj.RoomRate = vObj.Customer.RoomRate;
				vObj.RoomRateType = vObj.RoomRate.RoomRateType;
				SetDurationCaption(vObj);
				vObj.RoomRateServiceGroup = vObj.Customer.RoomRateServiceGroup;
				vObj.DoNotPrintRate = vObj.RoomRate.DoNotPrintRate;
				// Source of business
				If ValueIsFilled(vObj.RoomRate.SourceOfBusiness) Then
					vObj.SourceOfBusiness = vObj.RoomRate.SourceOfBusiness;
				EndIf;
				// Marketing code
				If ValueIsFilled(vObj.RoomRate.MarketingCode) Then
					vObj.MarketingCode = vObj.RoomRate.MarketingCode;
				EndIf;
				// Client type
				If ValueIsFilled(vObj.RoomRate.ClientType) Then
					vObj.ClientType = vObj.RoomRate.ClientType;
					vObj.ClientTypeConfirmationText = vObj.RoomRate.ClientTypeConfirmationText;
				EndIf;
				// Company
				If ValueIsFilled(vObj.RoomRate.Company) Then
					vObj.Company = vObj.RoomRate.Company;
				EndIf;
			EndIf;
			// Marketing code
			If ValueIsFilled(vObj.Customer.MarketingCode) Then
				vObj.MarketingCode = vObj.Customer.MarketingCode;
				vObj.MarketingCodeConfirmationText = "";
			EndIf;
			// Source of business
			If ValueIsFilled(vObj.Customer.SourceOfBusiness) Then
				vObj.SourceOfBusiness = vObj.Customer.SourceOfBusiness;
			EndIf;
			// Check should we show customer related message or not
			If vObj.Customer.ShowRemarksInAccommodations And Not IsBlankString(vObj.Customer.Remarks) Then
				vMessage = TrimR(vObj.Customer.Remarks);
				vUM = New UserMessage();
				vUM.SetData(vObj);
				vUM.Field = "Customer";
				vUM.Text = vMessage;
				vUM.Message();
			EndIf;
		EndIf;
		// Contract
		vContractWasChanged = False;
		If ValueIsFilled(vObj.RoomQuota.Contract) And vObj.Contract <> vObj.RoomQuota.Contract And (Not ValueIsFilled(vObj.RoomQuota.Contract.Hotel) Or vObj.RoomQuota.Contract.Hotel = vObj.Hotel) Then
			vObj.Contract = vObj.RoomQuota.Contract;
			vContractWasChanged = True;
			// Room rate
			vContractRoomRate = GetContractRoomRate(vObj);
			If ValueIsFilled(vContractRoomRate) Then
				If vObj.RoomRate <> vContractRoomRate Then
					vObj.PriceCalculationDate = '00010101';
				EndIf;
				vObj.RoomRate = vContractRoomRate;
				vObj.RoomRateType = vObj.RoomRate.RoomRateType;
				SetDurationCaption(vObj);
				vObj.RoomRateServiceGroup = vObj.Contract.RoomRateServiceGroup;
				vObj.DoNotPrintRate = vObj.RoomRate.DoNotPrintRate;
				// Source of business
				If ValueIsFilled(vObj.RoomRate.SourceOfBusiness) Then
					vObj.SourceOfBusiness = vObj.RoomRate.SourceOfBusiness;
				EndIf;
				// Marketing code
				If ValueIsFilled(vObj.RoomRate.MarketingCode) Then
					vObj.MarketingCode = vObj.RoomRate.MarketingCode;
				EndIf;
				// Client type
				If ValueIsFilled(vObj.RoomRate.ClientType) Then
					vObj.ClientType = vObj.RoomRate.ClientType;
					vObj.ClientTypeConfirmationText = vObj.RoomRate.ClientTypeConfirmationText;
				EndIf;
				// Company
				If ValueIsFilled(vObj.RoomRate.Company) Then
					vObj.Company = vObj.RoomRate.Company;
				EndIf;
			EndIf;
			// Contract company
			If ValueIsFilled(vObj.Contract.Company) Then
				vObj.Company = vObj.Contract.Company;
			EndIf;
			// Meal board term
			If Items.ServicePackage.Visible Then
				If ValueIsFilled(vObj.Contract.MealBoardTerm) And Not pDoNotChangeTerms Then
					If Not ValueIsFilled(vObj.ServicePackage) Then
						vObj.ServicePackage = vObj.Contract.MealBoardTerm;
					EndIf;
				EndIf;
				vTermsArray = GetMealBoardTermsList(vObj.Hotel, vObj.Contract).UnloadValues();
				Items.ServicePackage.ChoiceList.LoadValues(vTermsArray);
				Items.ServicePackageBeforeUpgrade.ChoiceList.LoadValues(vTermsArray);
			EndIf;
		EndIf;
		// Agent commission
		If ValueIsFilled(vObj.Agent) Then
			If ValueIsFilled(vObj.Contract) Then
				If vObj.Contract.AgentCommission <> 0 Then
					vObj.AgentCommission = vObj.Contract.AgentCommission;
					vObj.AgentCommissionType = vObj.Contract.AgentCommissionType;
					vObj.AgentCommissionServiceGroup = vObj.Contract.AgentCommissionServiceGroup;
				EndIf;
			ElsIf ValueIsFilled(vObj.Customer) Then
				If vObj.Customer.AgentCommission <> 0 Then
					vObj.AgentCommission = vObj.Customer.AgentCommission;
					vObj.AgentCommissionType = vObj.Customer.AgentCommissionType;
					vObj.AgentCommissionServiceGroup = vObj.Customer.AgentCommissionServiceGroup;
				Endif;
			EndIf;
		EndIf;
		// Company
		If ValueIsFilled(vObj.RoomQuota.Company) Then
			vObj.Company = vObj.RoomQuota.Company;
		EndIf;
		// Check overallotment
		If Not vObj.Posted And Not vObj.IsByReservation And ValueIsFilled(vObj.RoomQuota) Then
			If ValueIsFilled(vObj.RoomQuota.OverAllotmentRoomRate) And vObj.RoomRate <> vObj.RoomQuota.OverAllotmentRoomRate Or 
			   ValueIsFilled(vObj.RoomQuota.OverAllotmentContract) And vObj.Contract <> vObj.RoomQuota.OverAllotmentContract Then
				vAttrInError = "";
				vOverallotmentMessage = CheckOverallotment(vObj, vAttrInError);
				If Not IsBlankString(vOverAllotmentMessage) Then
					vUM = New UserMessage();
					vUM.SetData(vObj);
					vUM.Field = vAttrInError;
					vUM.Text = vOverAllotmentMessage;
					vUM.Message();
				EndIf;
			EndIf;
		EndIf;
		// Discount
		vObj.pmSetDiscounts();
		// Charging rules
		If vCustomerWasChanged Or vContractWasChanged Then
			vObj.pmLoadChargingRules(?(ValueIsFilled(vObj.Contract), vObj.Contract, vObj.Customer));
		EndIf;
		// Fill table with valid room type/accommodation type combinations
		FillTypesTableAtServer(vObj);
		// Check that current accomodation type is in the list of valid types.
		// If not open selection with focus set on first valid one
		ResetAccommodationType("RoomQuota", vObj);
		// Automatic services list calculation	
		If pRecalculateServices Then
			// Calculate totals
			TotalSum = CalculateTotalServices(vObj, , False, False);
		EndIf;
		// Set planned payment method from the first charging rule
		Payer = vObj.pmSetPlannedPaymentMethod(TPayer);
		If Payer = Enums.WhoPays.ChargingRules Then
			Items.GroupChargingRules.Show();
		Else
			Items.GroupChargingRules.Hide();
		EndIf;
		// Save room rate
		SavRoomRate = vObj.RoomRate;
		// Do not print rate
		If ValueIsFilled(vObj.Contract) And vObj.Contract.DoNotPrintRate Then
			vObj.DoNotPrintRate = True;
		ElsIf ValueIsFilled(vObj.Customer) And vObj.Customer.DoNotPrintRate Then
			vObj.DoNotPrintRate = True;
		EndIf;
	EndIf;
	// Build commission group hidden title
	BuildCommissionGroupCollapsedTitle(vObj);
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle(vObj);
	// Build room rate group hidden title
	BuildRoomRateGroupCollapsedTitle(vObj);
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
		// Terms choice list
		FillServicePackageChoiceList();
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
EndProcedure // RoomQuotaOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentOnChangeAtServer(pObj = Undefined)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	If ValueIsFilled(vObj.Agent) Then
		// Agent commission
		If vObj.Agent.AgentCommission <> 0 Then
			vObj.AgentCommission = vObj.Agent.AgentCommission;
			vObj.AgentCommissionType = vObj.Agent.AgentCommissionType;
			vObj.AgentCommissionServiceGroup = vObj.Agent.AgentCommissionServiceGroup;
		EndIf;
		// Calculate agent operational commission turnovers
		ShowAgentOperationalCommissionTurnovers(True, vObj);
		// Check should we show agent related message or not
		If vObj.Agent.ShowRemarksInAccommodations And Not IsBlankString(vObj.Agent.Remarks) And vObj.Agent <> vObj.Customer Then
			tcCommonFunctionOnClientServer.UserMessage(TrimR(vObj.Agent.Remarks));
		EndIf;
	Else
		// Reset agent commission
		vObj.AgentCommission = 0;
		vObj.AgentCommissionType = Undefined;
		vObj.AgentCommissionServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		// Clear commission from accommodation plan
		ClearRoomRatesCommission(vObj);
		// Reset agent operational commission turnovers
		ShowAgentOperationalCommissionTurnovers(False, vObj);
	EndIf;
	If vUseParameterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
		// Terms choice list
		FillServicePackageChoiceList();
	EndIf;
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // AgentOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearRoomRatesCommission(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Clear agent commission
	For Each vRRRow In vObj.RoomRates Do
		vRRRow.AgentCommission = "";
	EndDo;
	// Delete empty room rates rows
	DeleteEmptyRoomRatesRows(vObj);
	// Fill form object
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	ThisObject.Modified = True;
EndProcedure // ClearRoomRatesCommission

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteEmptyRoomRatesRows(pObj = Undefined)
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Delete empty room rates rows
	vPrevIsBookedOut = False;
	i = 0;
	While i < vObj.RoomRates.Count() Do
		vRRRow = vObj.RoomRates.Get(i);
		If Not vObj.pmDeleteEmptyChangeHistoryRecord(vRRRow, i, vPrevIsBookedOut) Then
			vPrevIsBookedOut = vRRRow.IsBookedOut;
			i = i + 1;
		EndIf;
	EndDo;
	// Fill form object
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // DeleteEmptyRoomRatesRows

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestOnChangeAtServer(pObj = Undefined)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	If ValueIsFilled(vObj.Guest) Then
		vObj.GuestFullName = vObj.Guest.FullName;
		SelGuest1 = vObj.GuestFullName;
		Items.SelGuest1.TextEdit = False;
		// Room rate
		If ValueIsFilled(vObj.Guest.RoomRate) And (Not ValueIsFilled(vObj.Guest.RoomRate.Hotel) Or vObj.Guest.RoomRate.Hotel = vObj.Hotel) Then
			If vObj.RoomRate <> vObj.Guest.RoomRate Then
				vObj.PriceCalculationDate = '00010101';
			EndIf;
			vObj.RoomRate = vObj.Guest.RoomRate;
			vObj.RoomRateType = vObj.RoomRate.RoomRateType;
			SetDurationCaption(vObj);
			vObj.RoomRateServiceGroup = vObj.Guest.RoomRateServiceGroup;
			vObj.DoNotPrintRate = vObj.RoomRate.DoNotPrintRate;
			// Source of business
			If ValueIsFilled(vObj.RoomRate.SourceOfBusiness) Then
				vObj.SourceOfBusiness = vObj.RoomRate.SourceOfBusiness;
			EndIf;
			// Marketing code
			If ValueIsFilled(vObj.RoomRate.MarketingCode) Then
				vObj.MarketingCode = vObj.RoomRate.MarketingCode;
			EndIf;
			// Client type
			If ValueIsFilled(vObj.RoomRate.ClientType) Then
				vObj.ClientType = vObj.RoomRate.ClientType;
				vObj.ClientTypeConfirmationText = vObj.RoomRate.ClientTypeConfirmationText;
				If ValueIsFilled(vObj.ClientType.Parent) 
					And ValueIsFilled(vObj.ClientType.Parent.HotelProduct) 
					And Not ValueIsFilled(vObj.ClientType.HotelProduct) 
					And Not ValueIsFilled(vObj.HotelProduct) Then
					vObj.HotelProduct = vObj.ClientType.Parent.HotelProduct;
				ElsIf ValueIsFilled(vObj.ClientType.HotelProduct) And Not ValueIsFilled(vObj.HotelProduct) Then
					vObj.HotelProduct = vObj.ClientType.HotelProduct;
				EndIf;
			EndIf;
			// Company
			If ValueIsFilled(vObj.RoomRate.Company) Then
				vObj.Company = vObj.RoomRate.Company;
			EndIf;
		EndIf;
		// Marketing code
		If ValueIsFilled(vObj.Guest.MarketingCode) Then
			If vObj.MarketingCode <> vObj.Guest.MarketingCode Then
				vObj.MarketingCode = vObj.Guest.MarketingCode;
				vObj.MarketingCodeConfirmationText = "";
			EndIf;
		EndIf;
		// Source of business
		If ValueIsFilled(vObj.Guest.SourceOfBusiness) Then
			If vObj.SourceOfBusiness <> vObj.Guest.SourceOfBusiness Then
				vObj.SourceOfBusiness = vObj.Guest.SourceOfBusiness;
			EndIf;
		EndIf;
		// Client type
		vClientTypeHasChanged = False;
		If ValueIsFilled(vObj.Guest.ClientType) And (Not ValueIsFilled(vObj.Guest.ClientType.Hotel) Or vObj.Guest.ClientType.Hotel = vObj.Hotel) Then
			If vObj.ClientType <> vObj.Guest.ClientType Then
				vClientTypeHasChanged = True;
				vObj.ClientType = vObj.Guest.ClientType;
				vObj.ClientTypeConfirmationText = vObj.Guest.ClientTypeConfirmationText;
				If ValueIsFilled(vObj.ClientType.Parent) 
					And ValueIsFilled(vObj.ClientType.Parent.HotelProduct) 
					And Not ValueIsFilled(vObj.ClientType.HotelProduct) 
					And Not ValueIsFilled(vObj.HotelProduct) Then
					vObj.HotelProduct = vObj.ClientType.Parent.HotelProduct;
				ElsIf ValueIsFilled(vObj.ClientType.HotelProduct) And Not ValueIsFilled(vObj.HotelProduct) Then
					vObj.HotelProduct = vObj.ClientType.HotelProduct;
				EndIf;
			EndIf;
		EndIf;
		// Guest remarks
		If Not IsBlankString(vObj.Guest.Remarks) And vObj.Guest.CopyRemarksToDocuments Then
			vObj.Remarks = TrimAll(TrimAll(vObj.Guest.Remarks) + Chars.LF + TrimAll(vObj.Remarks));
		EndIf;
		// Client contact data
		If Not IsBlankString(vObj.Guest.Phone) Then
			vObj.Phone = vObj.Guest.Phone;
		EndIf;
		If Not IsBlankString(vObj.Guest.Fax) Then
			vObj.Fax = vObj.Guest.Fax;
		EndIf;
		If Not IsBlankString(vObj.Guest.EMail) Then
			vObj.EMail = vObj.Guest.EMail;
		EndIf;     
		If Not IsBlankString(vObj.Guest.EMailAdditional) Then
			EMail2 = vObj.Guest.EMailAdditional;
		EndIf; 
		// Room properties
		ThisObject.RoomPropertiesFromGuest = GetRoomPropertiesFromGuestValueList(vObj);
		
		// Default room
		If ValueIsFilled(vObj.AccommodationType) And 
		   ValueIsFilled(vObj.CheckInDate) And 
		   ValueIsFilled(vObj.CheckOutDate) And 
		   vObj.CheckOutDate > vObj.CheckInDate And 
		   Not ValueIsFilled(vObj.Room) Then
			GetDefaultRoomAtServer(vObj);
			If ValueIsFilled(vObj.Room) Then
				RoomOnChangeAtServer(False, vObj, vClientTypeHasChanged);
			EndIf;
		EndIf;
	Else
		vObj.GuestFullName = "";
		Items.SelGuest1.TextEdit = True;
	EndIf;
	// Discount
	vObj.pmSetDiscounts();
	// Charging rules
	If ValueIsFilled(vObj.Guest) Then
		If vObj.Guest.ChargingRules.Count() > 0 Then
			vObj.pmLoadChargingRules(vObj.Guest);
		EndIf;
	EndIf;
	// Set planned payment method
	Payer = vObj.pmSetPlannedPaymentMethod(TPayer);
	If Payer = Enums.WhoPays.ChargingRules Then
		Items.GroupChargingRules.Show();
	Else
		Items.GroupChargingRules.Hide();
	EndIf;
	// Calculate totals
	TotalSum = CalculateTotalServices(vObj, , False, Items.GroupTouristTax.Visible);
	// Refresh analitical parameters
	BuildThisObjectClientDataDecoration(vObj);
	// Build commission group hidden title
	BuildCommissionGroupCollapsedTitle(vObj);
	// Build room rate hidden title
	BuildRoomRateGroupCollapsedTitle(vObj);
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Read foreigner registry documents
	ReadForeignerRegistryDocuments(vObj);
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
		// Terms choice list
		FillServicePackageChoiceList();
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
	// Build form caption
	BuildThisObjectCaption(SelGuest1);
	// Show discounts
	If ValueIsFilled(Object.DiscountType) Or ValueIsFilled(Object.DiscountCard) Or Object.Discount <> 0 Then
		Items.GroupDiscounts.Show();
	EndIf;
EndProcedure // GuestOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildThisObjectCaption(pGuest = "")
	vFormCaption = "";
	// Get guest full name and number of check-ins
	vGuestFullName = "";
	vGuestCountryCode = "";
	vGuestNumberOfCheckIns = 0;
	If ValueIsFilled(Object.Guest) Then
		vGuestFullName = TrimAll(Object.Guest.FullName);
		If ValueIsFilled(Object.Guest.Citizenship) Then
			vGuestCountryCode = " (" + TrimAll(Object.Guest.Citizenship.ISOCode) + ")";
		EndIf;
		vGuestNumberOfCheckIns = Object.Guest.GetObject().pmCountNumberOfCheckIns();
	Else
		vGuestFullName = TrimAll(pGuest);
	EndIf;
	If Not IsBlankString(vGuestFullName) Then
		vFormCaption = NStr("en='Check-in ';ru='Размещ. ';de='Check-in '") + vGuestFullName;
	Else
		vFormCaption = NStr("en='Check-in ';ru='Размещ. ';de='Check-in '") + TrimAll(Object.Number);
	EndIf;
	If Not IsBlankString(vGuestCountryCode) Then
		vFormCaption = vFormCaption + vGuestCountryCode;
	EndIf;
	If ValueIsFilled(Object.Room) Then
		vFormCaption = vFormCaption + ", " + TrimAll(Object.Room);
	EndIf;
	If ValueIsFilled(Object.RoomType) Then
		vFormCaption = vFormCaption + " " + TrimAll(Object.RoomType.Code);
	EndIf;
	If vGuestNumberOfCheckIns > 0 Then
		vFormCaption = vFormCaption + NStr("en=', check-ins: ';ru=', заездов: ';de=', check-ins: '") + vGuestNumberOfCheckIns;
	EndIf;
	vFormCaption = vFormCaption + ?(IsBlankString(vGuestFullName), "", ", " + NStr("en='N'; ru='№'; de='N'") + TrimAll(Object.Number)) + ", " + TrimAll(Object.Hotel);
	vFormCaption = vFormCaption + ", " + Trimall(Object.Author);
	ThisObject.Title = vFormCaption;
	ThisObject.AutoTitle = False;
EndProcedure // BuildThisObjectCaption

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildThisObjectRemarksDataDecoration()
	Items.GroupRemarks.CollapsedRepresentationTitle = "";
	If Not IsBlankString(Object.Remarks) Or Not IsBlankString(Object.HousekeepingRemarks) Then
		Items.GroupRemarks.CollapsedRepresentationTitle = TrimAll(?(Not IsBlankString(Object.Remarks), NStr("en='Remarks: '; ru='Примечания: '; de='Bemerkungen: '") + TrimAll(Object.Remarks), "") + 
																  ?(Not IsBlankString(Object.HousekeepingRemarks), " • " + NStr("en='Housekeeping: '; ru='Горничные: '; de='Housekeeping: '") + TrimAll(Object.HousekeepingRemarks), ""));
	EndIf;
EndProcedure // BuildThisObjectRemarksDataDecoration	

// -----------------------------------------------------------------------------
&AtServer
Procedure SourceOfBusinessOnChangeAtServer()
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // SourceOfBusinessOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure MarketingCodeOnChangeAtServer(pObj = Undefined)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;	
	// Set room rate type
	If ValueIsFilled(vObj.MarketingCode) Then
		If Not ValueIsFilled(vObj.RoomRateType) Then
			vObj.RoomRateType = vObj.MarketingCode.RoomRateType;
		EndIf;
	EndIf;
	// Fill discount type and other discount parameters if filled
	vObj.pmSetDiscounts();
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Calculate totals
	TotalSum = CalculateTotalServices(vObj, , False, False);
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
		// Terms choice list
		FillServicePackageChoiceList();
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
EndProcedure // MarketingCodeOnChangeAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure BoardPlaceOnChangeAtServer()
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // BoardPlaceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClientTypeOnChangeAtServer(pObj = Undefined)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Fill hotel product
	If ValueIsFilled(vObj.ClientType.Parent) 
		And ValueIsFilled(vObj.ClientType.Parent.HotelProduct) 
		And Not ValueIsFilled(vObj.ClientType.HotelProduct) 
		And Not  ValueIsFilled(vObj.HotelProduct) Then
		vObj.HotelProduct = vObj.ClientType.Parent.HotelProduct;
	ElsIf ValueIsFilled(vObj.ClientType.HotelProduct) And Not ValueIsFilled(vObj.HotelProduct) Then
		vObj.HotelProduct = vObj.ClientType.HotelProduct;
	EndIf;
	vObj.pmSetDiscounts();
	// Fill table with valid room type/accommodation type combinations
	FillTypesTableAtServer(vObj);
	// Check that current accomodation type is in the list of valid types.
	// If not open selection with focus set on first valid one
	ResetAccommodationType("ClientType", vObj);
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Calculate totals
	TotalSum = CalculateTotalServices(vObj, , False, False);
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
		// Terms choice list
		FillServicePackageChoiceList();
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
EndProcedure // ClientTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomRateOnChangeAtServer(pObj = Undefined, pDoPriceRecalc = False)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Check if period has changed
	vObj.pmUpdatePriceCalculationDate();
	If ValueIsFilled(vObj.RoomRate) Then
		// Reset check-out time to the rate defaults
		If vObj.RoomRate <> SavRoomRate And ValueIsFilled(SavRoomRate) Then
			If ValueIsFilled(vObj.RoomRate.DefaultCheckOutTime) And ValueIsFilled(SavRoomRate.DefaultCheckOutTime) And 
			   vObj.RoomRate.DefaultCheckOutTime <> SavRoomRate.DefaultCheckOutTime Then
				vObjCheckOutTime = cmExtractTime(vObj.CheckOutDate);
				If vObjCheckOutTime = SavRoomRate.DefaultCheckOutTime Then
					vObj.CheckOutDate = cm0SecondShift(BegOfDay(vObj.CheckOutDate) + (vObj.RoomRate.DefaultCheckOutTime - BegOfDay(vObj.RoomRate.DefaultCheckOutTime)));
					CheckOutTime = cmExtractTime(vObj.CheckOutDate);
				EndIf;
			EndIf;
			vObj.Duration = vObj.pmCalculateDuration();
		EndIf;
		SetDurationCaption(vObj);
		vObj.RoomRateType = vObj.RoomRate.RoomRateType;
		// Check user permissions to use this room rate
		vRoomRatesAllowed = GetAllowedRoomRates();
		If vRoomRatesAllowed.Count() > 0 Then
			If vRoomRatesAllowed.FindByValue(vObj.RoomRate) = Undefined Then
				vObj.RoomRate = SavRoomRate;
				SetDurationCaption(vObj);
				If ValueIsFilled(vObj.RoomRate) Then
					vObj.RoomRateType = vObj.RoomRate.RoomRateType;
				EndIf;
				ValueToFormAttribute(vObj, "Object");
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='You do not have rights to use room rate choosen!';ru='Нет прав на использование выбранного тарифа!';de='Sie haben keine Rechte, den ausgewählten Tarif zu verwenden!'"));
				Return;
			EndIf;
		EndIf;
		// Source of business
		If ValueIsFilled(vObj.RoomRate.SourceOfBusiness) Then
			vObj.SourceOfBusiness = vObj.RoomRate.SourceOfBusiness;
		EndIf;
		// Marketing code
		If ValueIsFilled(vObj.RoomRate.MarketingCode) Then
			vObj.MarketingCode = vObj.RoomRate.MarketingCode;
		EndIf;
		// Client type
		If ValueIsFilled(vObj.RoomRate.ClientType) Then
			vObj.ClientType = vObj.RoomRate.ClientType;
			vObj.ClientTypeConfirmationText = vObj.RoomRate.ClientTypeConfirmationText;
		EndIf;
		// Company
		If ValueIsFilled(vObj.RoomRate.Company) Then
			vObj.Company = vObj.RoomRate.Company;
		EndIf;
		// Allotment
		If ValueIsFilled(vObj.RoomRate.Allotment) And vObj.RoomQuota <> vObj.RoomRate.Allotment Then
			vObj.RoomQuota = vObj.RoomRate.Allotment;
			// Company
			If ValueIsFilled(vObj.RoomQuota.Company) And vObj.RoomQuota.Company <> vObj.Company Then
				vObj.Company = vObj.RoomQuota.Company;
			EndIf;
		EndIf;
		// Do not print rate
		If Not vObj.DoNotPrintRate Then
			vObj.DoNotPrintRate = vObj.RoomRate.DoNotPrintRate;
		EndIf;
		// Check charging mode
		If ValueIsFilled(vObj.Hotel) And vObj.Hotel.CloseOfPeriodDoChargeServices Then
			Items.DoChargingToDate.Visible = True;
		Else
			If ValueIsFilled(vObj.RoomRate) And vObj.RoomRate.CloseOfPeriodDoChargeServices Then
				Items.DoChargingToDate.Visible = True;
			Else
				Items.DoChargingToDate.Visible = False;
			EndIf;
		EndIf;
	EndIf;
	// Reset price calculation date
	If ValueIsFilled(vObj.RoomRate) And ValueIsFilled(SavRoomRate) And vObj.RoomRate <> SavRoomRate Then
		vObj.PriceCalculationDate = '00010101';
		// Get accommodation types
		CheckGuestFieldCount(vObj);
		// Update room rates row
		vRoomRateChangeDate = BegOfDay(CurrentSessionDate());
		If vRoomRateChangeDate < BegOfDay(vObj.CheckInDate) Or vRoomRateChangeDate >= BegOfDay(vObj.CheckOutDate) Then
			vRoomRateChangeDate = BegOfDay(vObj.CheckInDate);
		EndIf;
		If vRoomRateChangeDate > BegOfDay(vObj.CheckInDate) Then
			// Add check in date row
			If SavRoomRate <> vObj.RoomRate Then
				vCIRRow = vObj.RoomRates.Find(BegOfDay(vObj.CheckInDate), "AccountingDate");
				If vCIRRow = Undefined Then
					vCIRRow = vObj.RoomRates.Insert(0);
					vCIRRow.AccountingDate = BegOfDay(vObj.CheckInDate);
				EndIf;
				If Not ValueIsFilled(vCIRRow.RoomRate) Then 
					vCIRRow.RoomRate = SavRoomRate;
				EndIf;
				If Not ValueIsFilled(vCIRRow.AccommodationType) Then
					If vObj.AccommodationType <> SavAccommodationType Then
						vCIRRow.AccommodationType = SavAccommodationType;
					EndIf;
				EndIf;
			EndIf;
			// Add row for room rate change date
			vRRRow = vObj.RoomRates.Find(vRoomRateChangeDate, "AccountingDate");
			If vRRRow = Undefined Then
				vRRRow = vObj.RoomRates.Add();
				vRRRow.AccountingDate = vRoomRateChangeDate;
			EndIf;
			vRRRow.ChangeTime = cmGetReferenceHour(vObj.RoomRate);
			vRRRow.RoomRate = vObj.RoomRate;
			If vObj.AccommodationType <> SavAccommodationType Then
				vRRRow.AccommodationType = vObj.AccommodationType;
			EndIf;
			vObj.RoomRates.Sort("AccountingDate, ChangeTime");
		EndIf;
	EndIf;
	// Discount
	vObj.pmSetDiscounts();
	// Fill table with valid room type/accommodation type combinations
	FillTypesTableAtServer(vObj);
	// Check that current accomodation type is in the list of valid types.
	// If not open selection with focus set on first valid one
	ResetAccommodationType("RoomRate", vObj);
	// Calculate check-out date
	If ValueIsFilled(SavRoomRate) And ValueIsFilled(vObj.RoomRate) And 
	   vObj.RoomRate.DurationCalculationRuleType <> SavRoomRate.DurationCalculationRuleType Then
		vObj.CheckOutDate = vObj.pmCalculateCheckOutDate();
		CheckOutTime = cmExtractTime(vObj.CheckOutDate);
		// Fill check-out day of week names
		If ValueIsFilled(vObj.CheckOutDate) Then
			CheckOutDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(vObj.CheckOutDate)));
		Else
			CheckOutDayOfWeek = "";
		EndIf;
	EndIf;
	// Automatic services list calculation
	If pDoPriceRecalc Then
		vWarnings = "";
		If vObj.pmCalculateServices(vWarnings, , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate)) Then
			tcCommonFunctionOnClientServer.UserMessage(tcOnServer.cmNStrAtServer(vWarnings));
		EndIf;
	EndIf;
	// Calculate totals
	If pDoPriceRecalc Then
		TotalSum = CalculateTotalServices(vObj, , False, False);
	Else
		TotalSum = CalculateTotalServices(vObj);
	EndIf;
	// Refresh analitical parameters
	BuildThisObjectClientDataDecoration(vObj);
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle(vObj);
	// Build commission group hidden title
	BuildCommissionGroupCollapsedTitle(vObj);
	// Build room rate group hidden title
	BuildRoomRateGroupCollapsedTitle(vObj);
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
		// Terms choice list
		FillServicePackageChoiceList();
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
	// Save room rate
	SavRoomRate = Object.RoomRate;
	SavAccommodationType = Object.AccommodationType;
EndProcedure // RoomRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function AccommodationStatusOnChangeAtServer(pObj = Undefined)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Check user permissions
	If ValueIsFilled(vObj.AccommodationStatus) Then
		If vObj.AccommodationStatus.IsActive And Not vObj.AccommodationStatus.IsInHouse Then
			If Not cmCheckUserPermissions("HavePermissionToManuallySetCheckedOutAccommodationStatus") Then
				If vObj.IsNew() Then
					If ValueIsFilled(vObj.Hotel) Then
						AccommodationStatus = vObj.Hotel.CheckInAccommodationStatus;
					Else
						AccommodationStatus = Undefined;
					EndIf;
				Else
					vObj.AccommodationStatus = vObj.Ref.AccommodationStatus;
				EndIf;
				// Set object value
				If vUseParameterObject = False Then
					ValueToFormAttribute(vObj, "Object");
				EndIf;
				Return NStr("en='You do not have rights to manually set <Checked out> accommodation status! Action will be canceled.';ru='Нет прав на ручную установку статуса <Выезд> у размещения! Действие будет отменено.';de='Sie haben keine Rechte, bei Unterbringungen den Status <Abreise> manuell einzustellen! Die Aktion wird abgebrochen!'");
			EndIf;
		EndIf;
		If Not vObj.AccommodationStatus.IsActive Then
			If Not cmCheckUserPermissions("HavePermissionToCancelAccommodations") Then
				If vObj.IsNew() Then
					If ValueIsFilled(vObj.Hotel) Then
						vObj.AccommodationStatus = vObj.Hotel.CheckInAccommodationStatus;
					Else
						vObj.AccommodationStatus = Undefined;
					EndIf;
				Else
					vObj.AccommodationStatus = vObj.Ref.AccommodationStatus;
				EndIf;
				// Set object value
				If vUseParameterObject = False Then
					ValueToFormAttribute(vObj, "Object");
				EndIf;
				Return NStr("ru='Нет прав на отмену (аннуляцию) размещения! Действие будет отменено.'; 
				            |de='You do not have rights to cancel accommodation! Action will be canceled.'; 
				            |en='You do not have rights to cancel accommodation! Action will be canceled.'");
			EndIf;
		EndIf;
		// Update other guests reservation status
		vAnnulationStatus = Not vObj.AccommodationStatus.IsActive;
		For Each vGuestInGroupRow In GuestsInGroup Do
			If Not vGuestInGroupRow.IsStatusChanged Then
				vGuestInGroupRow.AccommodationStatus = vObj.AccommodationStatus;
				vGuestInGroupRow.IsAnnulation = False;
				If vAnnulationStatus Then
					vGuestInGroupRow.IsAnnulation = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
	// Build status group hidden title
	BuildStatusGroupCollapsedTitle(vObj);
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	// Refill status choice list
	FillAccommodationStatusListChoice();
	// Return
	Return ""; 
EndFunction // AccommodationStatusOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentCommissionTypeOnChangeAtServer(pObj = Undefined)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	If Not ValueIsFilled(vObj.AgentCommissionType) Then
		If vObj.AgentCommission <> 0 Then
			vObj.AgentCommission = 0;
		EndIf;
	EndIf;
	// Clear commission from accommodation plan
	ClearRoomRatesCommission(vObj);
	If vUseParameterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // AgentCommissionTypeOnChangeAtServer()

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentCommissionServiceGroupOnChangeAtServer(pObj = Undefined)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	If vUseParameterObject = False Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // AgentCommissionServiceGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomPropertiesPresentation()
	// Room properties
	vRPPresentation = "";
	For Each vRPItem In ThisObject.RoomProperties Do
		If ValueIsFilled(vRPItem.Value) Then
			If IsBlankString(vRPPresentation) Then
				vRPPresentation = TrimAll(vRPItem.Value.Description);
			Else
				vRPPresentation = vRPPresentation + ", " + TrimAll(vRPItem.Value.Description);
			EndIf;
		EndIf;
	EndDo;
	Return vRPPresentation;
EndFunction // GetRoomPropertiesPresentation

// -----------------------------------------------------------------------------
&AtServer
Function FillRoomPropertiesList()
	// Get all service packages available for use
	vRoomPropertiesList = cmGetAllRoomProperties(Undefined, Object.Hotel, True);
	// Check service packages already being selected
	For Each vRP In ThisObject.RoomProperties Do
		If ValueIsFilled(vRP.Value) Then
			vRPItem = vRoomPropertiesList.FindByValue(vRP.Value);
			If vRPItem <> Undefined Then
				vRPItem.Check = True;
			EndIf;
		EndIf;
	EndDo;
	Return vRoomPropertiesList;
EndFunction // FillRoomPropertiesList

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveRoomPropertiesList(pRoomPropertiesList)
	If ThisObject.RoomProperties.Count() > 0 Then
		ThisObject.RoomProperties.Clear();
	EndIf;
	If pRoomPropertiesList.Count() > 0 Then
		For Each vRPItem In pRoomPropertiesList Do
			If vRPItem.Check Then
				ThisObject.RoomProperties.Add(vRPItem.Value);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // SaveRoomPropertiesList

// -----------------------------------------------------------------------------
&AtServer
Function FillDocumentRoomProperties()
	Object.RoomProperties.Clear();
	For Each vRoomPropertiesItem In ThisObject.RoomProperties Do
		vRoomPropertiesRow = Object.RoomProperties.Add();
		vRoomPropertiesRow.RoomProperty = vRoomPropertiesItem.Value;
	EndDo;
EndFunction // FillDocumentRoomProperties

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationStartChoice_AfterInput(pValue, pParametrs) Export
	
	If pValue <> Undefined Then
		SaveRoomPropertiesList(pValue);
	EndIf;
	
	// Fill presentation
	ThisObject.RoomPropertiesPresentation = GetRoomPropertiesPresentation();
	// Save room properties to the document object
	FillDocumentRoomProperties();
	// Parameters group presentation
	BuildThisObjectClientDataDecoration()
	
EndProcedure
// -----------------------------------------------------------------------------
&AtServer
Procedure CheckInTimeOnChangeAtServer(pObj = Undefined)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Get time in seconds
	vCheckInTime = CheckInTime - BegOfDay(CheckInTime);
	vObj.CheckInDate = cm1SecondShift(BegOfDay(vObj.CheckInDate) + vCheckInTime);
	// Calculate duration
	vObj.Duration = vObj.pmCalculateDuration();
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;                            
	// Calculate totals
	If ValueIsFilled(Object.RoomType) Then
		TotalSum = CalculateTotalServices(, , False, False);
	Else
		TotalSum = CalculateTotalServices();
	EndIf;
	// Mark this form as changed
	ThisObject.Modified = True;
EndProcedure // CheckInTimeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutTimeOnChangeAtServer(pObj = Undefined)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Get time in seconds
	vCheckOutTime = CheckOutTime - BegOfDay(CheckOutTime);
	vObj.CheckOutDate = cm0SecondShift(BegOfDay(vObj.CheckOutDate) + vCheckOutTime);
	// Calculate duration
	vObj.Duration = vObj.pmCalculateDuration();
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;                            
	// Calculate totals
	If ValueIsFilled(Object.RoomType) Then
		TotalSum = CalculateTotalServices(, , False, False);
	Else
		TotalSum = CalculateTotalServices();
	EndIf;
	// Mark this form as changed
	ThisObject.Modified = True;
EndProcedure // CheckOutTimeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInTimeAfterChoice(pDayTime, pExtraParams) Export
	If pDayTime <> Undefined Then
		CheckInTime = pDayTime.Value;
		CheckInTimeOnChangeAtServer();
	EndIf;
	ThisObject.Modified = True;
EndProcedure // CheckInTimeAfterChoice

// -----------------------------------------------------------------------------
&AtServer
Function GetDayTimes(pItemName)
	vDayTimes = cmGetDayTimes();
	vList = New ValueList();
	For Each vDayTimesRow In vDayTimes Do
		If pItemName = "CheckInTime" Then
			vList.Add(vDayTimesRow.Time, vDayTimesRow.Presentation);
		ElsIf pItemName = "CheckOutTime" Then
			vList.Add(?(ValueIsFilled(vDayTimesRow.Time4CheckOutDate), vDayTimesRow.Time4CheckOutDate, vDayTimesRow.Time), vDayTimesRow.Presentation);
		EndIf;
	EndDo;
	Return vList;
EndFunction // GetDayTimes

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutTimeAfterChoice(pDayTime, pExtraParams) Export
	If pDayTime <> Undefined Then
		CheckOutTime = pDayTime.Value;
		CheckOutTimeOnChangeAtServer();
	EndIf;
	ThisObject.Modified = True;
EndProcedure // CheckOutTimeAfterChoice

// -----------------------------------------------------------------------------
&AtServerNoContext
Function FindGuestGroupByDescription(pHotel, pGuestGroup, pGroupDescription)
	If IsBlankString(pGroupDescription) Then
		Return Undefined;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuestGroups.Ref,
	|	GuestGroups.Code,
	|	GuestGroups.Status,
	|	GuestGroups.Customer,
	|	GuestGroups.Contract,
	|	GuestGroups.Client,
	|	GuestGroups.CheckInDate,
	|	GuestGroups.Duration,
	|	GuestGroups.CheckOutDate,
	|	GuestGroups.ClientDoc.RoomQuota AS RoomQuota,
	|	GuestGroups.ClientDoc.RoomType AS RoomType,
	|	GuestGroups.ClientDoc.RoomRate AS RoomRate,
	|	GuestGroups.ClientDoc.ServicePackage AS MealBoardTerm,
	|	GuestGroups.ClientDoc.DiscountType AS DiscountType,
	|	GuestGroups.ClientDoc.Discount AS Discount
	|FROM
	|	Catalog.GuestGroups AS GuestGroups
	|WHERE
	|	GuestGroups.Owner = &qHotel
	|	AND GuestGroups.Ref <> &qGroupToSkip
	|	AND GuestGroups.Description = &qGroupDescription
	|	AND NOT GuestGroups.DeletionMark
	|	AND ISNULL(GuestGroups.Status.IsActive, FALSE)
	|	AND NOT GuestGroups.IsFolder";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qGroupToSkip", pGuestGroup);
	vQry.SetParameter("qGroupDescription", pGroupDescription);
	vGroups = vQry.Execute().Unload();
	If vGroups.Count() > 0 Then
		vGroupRow = vGroups.Get(0);
		Return New Structure("GuestGroup, Code, Status, Customer, Contract, Client, CheckInDate, Duration, CheckOutDate, RoomQuota, RoomType, RoomRate, MealBoardTerm, DiscountType, Discount", 
		                     vGroupRow.Ref, TrimAll(vGroupRow.Code), vGroupRow.Status, vGroupRow.Customer, vGroupRow.Contract, 
		                     vGroupRow.Client, vGroupRow.CheckInDate, vGroupRow.Duration, vGroupRow.CheckOutDate, 
							 vGroupRow.RoomQuota, vGroupRow.RoomType, vGroupRow.RoomRate, vGroupRow.MealBoardTerm, 
							 vGroupRow.DiscountType, vGroupRow.Discount);
	Else
		Return Undefined;
	EndIf;
EndFunction // FindGuestGroupByDescription

// -----------------------------------------------------------------------------
&AtServerNoContext
Function FindGuestGroupByID(pHotel, pGuestGroup, pGroupID)
	If IsBlankString(pGroupID) Then
		Return Undefined;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuestGroups.Ref,
	|	GuestGroups.Code,
	|	GuestGroups.Status,
	|	GuestGroups.Customer,
	|	GuestGroups.Contract,
	|	GuestGroups.Client,
	|	GuestGroups.CheckInDate,
	|	GuestGroups.Duration,
	|	GuestGroups.CheckOutDate,
	|	GuestGroups.ClientDoc.RoomQuota AS RoomQuota,
	|	GuestGroups.ClientDoc.RoomType AS RoomType,
	|	GuestGroups.ClientDoc.RoomRate AS RoomRate,
	|	GuestGroups.ClientDoc.ServicePackage AS MealBoardTerm,
	|	GuestGroups.ClientDoc.DiscountType AS DiscountType,
	|	GuestGroups.ClientDoc.Discount AS Discount
	|FROM
	|	Catalog.GuestGroups AS GuestGroups
	|WHERE
	|	GuestGroups.Owner = &qHotel
	|	AND GuestGroups.Ref <> &qGroupToSkip
	|	AND GuestGroups.ID = &qGroupID
	|	AND NOT GuestGroups.DeletionMark
	|	AND ISNULL(GuestGroups.Status.IsActive, FALSE)
	|	AND NOT GuestGroups.IsFolder";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qGroupToSkip", pGuestGroup);
	vQry.SetParameter("qGroupID", pGroupID);
	vGroups = vQry.Execute().Unload();
	If vGroups.Count() > 0 Then
		vGroupRow = vGroups.Get(0);
		Return New Structure("GuestGroup, Code, Status, Customer, Contract, Client, CheckInDate, Duration, CheckOutDate, RoomQuota, RoomType, RoomRate, MealBoardTerm, DiscountType, Discount", 
		                     vGroupRow.Ref, TrimAll(vGroupRow.Code), vGroupRow.Status, vGroupRow.Customer, vGroupRow.Contract, 
		                     vGroupRow.Client, vGroupRow.CheckInDate, vGroupRow.Duration, vGroupRow.CheckOutDate, 
							 vGroupRow.RoomQuota, vGroupRow.RoomType, vGroupRow.RoomRate, vGroupRow.MealBoardTerm, 
							 vGroupRow.DiscountType, vGroupRow.Discount);
	Else
		Return Undefined;
	EndIf;
EndFunction // FindGuestGroupByID

// -----------------------------------------------------------------------------
&AtServer
Procedure GroupDescriptionOnChangeAtServer(pObj = Undefined)
	// Check paramters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(vObj.GuestGroup) Then
		vGuestGroupObj = vObj.GuestGroup.GetObject();
		vGuestGroupObj.Description = TrimAll(ThisObject.GuestGroupDescription);
		vGuestGroupObj.Write();
	Else
		ThisObject.GuestGroupDescription = "";
	EndIf;
	// Build guest group group hidden title
	BuildGuestGroupGroupCollapsedTitle(vObj);
EndProcedure // GroupDescriptionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestGroupCreateDateOnChangeAtServer(pObj = Undefined)
	// Check paramters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(vObj.GuestGroup) Then
		If ValueIsFilled(ThisObject.GuestGroupCreateDate) Then
			vGuestGroupObj = vObj.GuestGroup.GetObject();
			vGuestGroupObj.CreateDate = ThisObject.GuestGroupCreateDate;
			vGuestGroupObj.Write();
		Else
			ThisObject.GuestGroupCreateDate = vObj.GuestGroup.CreateDate;
		EndIf;
	Else
		ThisObject.GuestGroupCreateDate = '00010101';
	EndIf;
	// Build guest group group hidden title
	BuildGuestGroupGroupCollapsedTitle(vObj);
EndProcedure // GuestGroupCreateDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GroupIDOnChangeAtServer(pObj = Undefined)
	// Check paramters
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(vObj.GuestGroup) Then
		vGuestGroupObj = vObj.GuestGroup.GetObject();
		vGuestGroupObj.ID = TrimAll(ThisObject.GuestGroupID);
		vGuestGroupObj.Write();
	Else
		ThisObject.GuestGroupID = "";
	EndIf;
	// Build guest group group hidden title
	BuildGuestGroupGroupCollapsedTitle(vObj);
EndProcedure // GroupIDOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestGroupOnChangeAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Fill group description
	If ValueIsFilled(vObj.GuestGroup) Then
		vGuestGroup = vObj.GuestGroup;
		GuestGroupDescription = TrimAll(vGuestGroup.Description);
		GuestGroupID = TrimAll(vGuestGroup.ID);
		GuestGroupCreateDate = vGuestGroup.CreateDate;
	Else
		GuestGroupDescription = "";
		GuestGroupID = "";
		GuestGroupCreateDate = '00010101';
	EndIf;
	// Build guest group group hidden title
	BuildGuestGroupGroupCollapsedTitle(vObj);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
	// Mark this form as changed
	ThisObject.Modified = True;
EndProcedure // GuestGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCustomersChoiceDataList(pText)
	vChoiceDataList = New ValueList;
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	Customers.Ref,
	|	Customers.Description,
	|	Customers.Presentation
	|FROM
	|	Catalog.Customers AS Customers
	|WHERE
	|	Customers.Description LIKE &qText
	|	AND NOT Customers.DeletionMark
	|	AND NOT Customers.IsFolder";
	vQry.SetParameter("qText", "%"+pText+"%");
	vQryResult = vQry.Execute().Select();
	While vQryResult.Next() Do
		vChoiceDataList.Add(vQryResult.Ref, vQryResult.Presentation + ?(ValueIsFilled(vQryResult.Ref.DateOfBirth), NStr("en=', birth ';ru=', род. ';de=', birth '") + Format(vQryResult.Ref.DateOfBirth, "DF=dd.MM.yyyy"), ""));
	EndDo;
	// Return
	Return PutToTempStorage(vChoiceDataList);
EndFunction // GetCustomersChoiceDataList

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckGuestRemarksAtServer(vValue)
	If ValueIsFilled(vValue) And TypeOf(vValue) = Type("CatalogRef.Clients") Then
		vIsInBlackList = vValue.IsInBlackList;
		vIsInWhiteList = vValue.IsInWhiteList;
		vRemarks = TrimAll(vValue.Remarks);
		If vIsInBlackList Then
			GuestRemarks = TrimAll(vValue.FullName) + NStr("en = ' is in the ""black"" list: '; ru = ' в ""черном"" списке: '; de = ' ist auf der ""Schwarzen"" Liste: '") + Chars.LF + vRemarks;
			Items.GuestRemarks.Visible = True;
			Items.GuestRemarks.TextColor = WebColors.Red;
			Items.GuestRemarks.BorderColor = WebColors.Red;
		ElsIf vIsInWhiteList Then
			GuestRemarks = TrimAll(vValue.FullName) + NStr("en = ' is in the ""VIP"" list: '; ru = ' в ""VIP"" списке: '; de = ' ist auf der ""VIP"" Liste: '") + Chars.LF + vRemarks;
			Items.GuestRemarks.Visible = True;
			Items.GuestRemarks.TextColor = WebColors.Green;
			Items.GuestRemarks.BorderColor = WebColors.Green;
		Else
			If Not IsBlankString(vRemarks)  Then 
				GuestRemarks = TrimAll(vValue.FullName) + Chars.LF + vRemarks;
		        Items.GuestRemarks.Visible = True;
				Items.GuestRemarks.TextColor = Items.Number.TextColor;
			Else
				GuestRemarks = "";
		        Items.GuestRemarks.Visible = False;
				Items.GuestRemarks.TextColor = Items.Number.TextColor;
			EndIf;
			Items.GuestRemarks.BorderColor = Items.Number.BorderColor;
		EndIf;
	Else
		GuestRemarks = "";
        Items.GuestRemarks.Visible = NOT IsBlankString(GuestRemarks);
		Items.GuestRemarks.TextColor = Items.Number.TextColor;
		Items.GuestRemarks.BorderColor = Items.Number.BorderColor;
	EndIf;
EndProcedure // CheckGuestRemarksAtServer

// -----------------------------------------------------------------------------
&AtServer
Function fmGetSexByName(pGuestObj)
	If ValueIsFilled(pGuestObj.Citizenship) Then
		If Not pGuestObj.Citizenship.IsVisaNecessaryForEntrance Then
			If StrLen(TrimAll(pGuestObj.SecondName)) < 2 Then
				vLastCharLastName = Upper(Right(TrimAll(pGuestObj.LastName), 1));
				vLastCharFirstName = Upper(Right(TrimAll(pGuestObj.FirstName), 1));
				If (vLastCharLastName = "А") Or (vLastCharLastName = "Я") Or
					(vLastCharFirstName = "А") Or (vLastCharFirstName = "Я") Then
					Return Enums.Sex.Female;
				Else
					Return Enums.Sex.Male;
				EndIf;
			Else
				vLastCharSecondName = Upper(Right(TrimAll(pGuestObj.SecondName), 1));
				If vLastCharSecondName = "А" Then
					Return Enums.Sex.Female;
				Else
					Return Enums.Sex.Male;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndFunction // fmGetSexByName

// -----------------------------------------------------------------------------
&AtServer
Function GetAccommodationAnnulationStatus(pRef)
	Return cmGetAccommodationAnnulationStatus(pRef);
EndFunction // GetAccommodationAnnulationStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterClientChoiceByPhoneOrEMail(pChoiceItem, pExtraParams) Export
	If pChoiceItem <> Undefined Then
		vStructure = pChoiceItem .Value;
		Object.Guest = vStructure.Client;
		SelGuest1 = vStructure.ClientFullName; 
		GuestOnChangeAtServer();
		CheckGuestRemarksOnClient(Items.SelGuest1);
		ThisObject.Modified = True;
	EndIf;
EndProcedure // AfterClientChoiceByPhoneOrEMail

// -----------------------------------------------------------------------------
&AtServer
Function PhoneOnChangeAtServer(rPhone)
	rPhone = SMS.GetValidPhoneNumber(rPhone);
	vQry = New Query;
	vQry.Text =
	"SELECT TOP 10
	|	Clients.Ref,
	|	Clients.FullName,
	|	Clients.DateOfBirth,
	|	Clients.Phone
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	NOT Clients.IsFolder
	|	AND NOT Clients.DeletionMark
	|	AND Clients.Phone = &qPhone
	|ORDER BY
	|	Clients.FullName,
	|	Clients.Code";
	vQry.SetParameter("qPhone", rPhone);
	vQryResult = vQry.Execute().Unload();
	vResultList = New ValueList();
	For Each vQryResultRow In vQryResult Do
		vResultStructure = New Structure("Client, ClientFullName, Phone");
		vResultStructure.Client = vQryResultRow.Ref;
		vResultStructure.ClientFullName = TrimAll(vQryResultRow.FullName);
		vResultStructure.Phone = TrimAll(vQryResultRow.Phone);
		vResultList.Add(vResultStructure, TrimAll(vQryResultRow.FullName) + " (" + Format(vQryResultRow.DateOfBirth, "DF=dd.MM.yyyy") + ")");
	EndDo;
	// Return
	Return vResultList;
EndFunction // PhoneOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function EMailOnChangeAtServer(pEMail)
	vQry = New Query;
	vQry.Text =
	"SELECT TOP 10
	|	Clients.Ref,
	|	Clients.FullName,
	|	Clients.DateOfBirth,
	|	Clients.EMail
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	NOT Clients.IsFolder
	|	AND NOT Clients.DeletionMark
	|	AND Clients.EMail = &qEMail
	|ORDER BY
	|	Clients.FullName,
	|	Clients.Code";
	vQry.SetParameter("qEMail", pEMail);
	vQryResult = vQry.Execute().Unload();
	vResultList = New ValueList();
	For Each vQryResultRow In vQryResult Do
		vResultStructure = New Structure("Client, ClientFullName, EMail");
		vResultStructure.Client = vQryResultRow.Ref;
		vResultStructure.ClientFullName = TrimAll(vQryResultRow.FullName);
		vResultStructure.EMail = TrimAll(vQryResultRow.EMail);
		vResultList.Add(vResultStructure, TrimAll(vQryResultRow.FullName) + " (" + Format(vQryResultRow.DateOfBirth, "DF=dd.MM.yyyy") + ")");
	EndDo;
	// Return
	Return vResultList;
EndFunction // EMailOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function PlannedPaymentMethodOnChangeAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.PlannedPaymentMethod) Then
		vFolioToUpdate = Undefined;
		vChargingRules = vObj.ChargingRules.Unload();
		If Not vObj.IgnoreGroupChargingRules Then
			cmAddGuestGroupChargingRules(vChargingRules, vObj.GuestGroup);
		EndIf;
		If vChargingRules.Count() > 0 Then
			// Set planned payment method to the accommodation service folio
			If vObj.Services.Count() > 0 Then
				vIndx = vObj.Services.Count() - 1;
				While vIndx >= 0 Do
					vSrvRow = vObj.Services.Get(vIndx);
					If ValueIsFilled(vSrvRow.Folio) Then
						If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice And Not vSrvRow.RoomRevenueAmountsOnly Then
							vFolioToUpdate = vSrvRow.Folio;
							Break;
						EndIf;
					EndIf;
					vIndx = vIndx - 1;
				EndDo;
			EndIf;
			If Not ValueIsFilled(vFolioToUpdate) Then
				// Set planned payment method to the folio from the first charging rule
				vCRRow = vChargingRules.Get(0);
				If ValueIsFilled(vCRRow.ChargingFolio) Then
					vFolioToUpdate = vCRRow.ChargingFolio;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vFolioToUpdate) Then
			If vFolioToUpdate.PaymentMethod <> vObj.PlannedPaymentMethod Then
				vFolioObj = vFolioToUpdate.GetObject();
				vFolioObj.PaymentMethod = vObj.PlannedPaymentMethod;
				vFolioObj.Write(DocumentWriteMode.Write);
			Endif;
		EndIf;
	EndIf;
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle(vObj);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
EndFunction // PlannedPaymentMethodOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef)
	#If ThickClientOrdinaryApplication Then
		vExtProcData = pExtProcRef.ExternalProcessingStorage.Get();
		vExtProcPath = GetTempFileName(".efd");
		vExtProcData.Write(vExtProcPath);
		vExtProcObj = ExternalDataProcessors.Create(vExtProcPath, False);
		vStruct = New Structure("InputParameter, ObjectPrintingForm, OneGuestMode", FormDataToValue(Object, Type("DocumentObject.Accommodation")), pPrintFormTypeRef, OneGuestMode);
		FillPropertyValues(vExtProcObj, vStruct);
		vFrm = vExtProcObj.GetForm();
		vFrm.Open();
		BeginDeletingFiles(Undefined, vExtProcPath);
	#Else
		vURL = GetURL(pExtProcRef, "ExternalProcessingStorage"); 
		vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef,"FileName")));
		vParams = New Structure("InputParameter, ObjectPrintingForm, OneGuestMode", Object.Ref, pPrintFormTypeRef, OneGuestMode);
	    vFrm = GetForm("ExternalDataProcessor." + vName + ".Form", vParams);
		vFrm.Open();
	#EndIf
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtServer
Function GetExternalProcessingValidName(Val pStr)
	Return cmGetValidName(pStr); 	
EndFunction // GetExternalProcessingValidName

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef)
	#If ThickClientOrdinaryApplication Then
		vExtRepData = pExtRepRef.Report.ExternalProcessingStorage.Get();
		vExtRepPath = GetTempFileName(".erf");
		vExtRepData.Write(vExtRepPath);
		vExtRepObj = ExternalReports.Create(vExtRepPath, False);
		vStruct = New Structure("Document, ObjectPrintingForm, OneGuestMode", Object.Ref, pPrintFormTypeRef, OneGuestMode);
		FillPropertyValues(vExtRepObj, vStruct);
		// Open report's default form
		vExtRepFrm = vExtRepObj.GetForm();
		vExtRepFrm.Open();
		BeginDeletingFiles(New NotifyDescription, vExtRepPath);
	#Else
		vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef,"Report"), "ExternalProcessingStorage"); 
		vName = ConnectExternalReport(vURL, "ExternalReportForm");
		vParams = New Structure("Document, ObjectPrintingForm, OneGuestMode", Object.Ref, pPrintFormTypeRef, OneGuestMode);
		OpenForm("ExternalReport." + vName + ".Form", vParams);
	#EndIf
EndProcedure // OpenExternalReportForm

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestForm(pTypeOfPrintForm)
	vDocument = Undefined;
	If Not ValueIsFilled(Object.Ref) Then
		vDocument = GetObjectref();
	Else
		vDocument = Object.Ref;
	EndIf;
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", pTypeOfPrintForm);
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("Document, GuestGroup, ObjectPrintingForm", vDocument, Undefined, vObjPrtForm), ThisObject, Object.Ref);
EndProcedure // PrintGuestForm

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestsForms(pTypeOfPrintForm)
	vDocument = Undefined;
	If Not ValueIsFilled(Object.Ref) Then
		vDocument = GetObjectref();
	Else
		vDocument = Object.Ref;
	EndIf;
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", pTypeOfPrintForm);
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("Document, GuestGroup, ObjectPrintingForm", vDocument, Object.GuestGroup, vObjPrtForm), ThisObject, Object.Ref);
EndProcedure // PrintGuestsForms

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestPersonalDataProcessingConsent()
	vLang = Undefined;
	vDocument = Undefined;
	If Not ValueIsFilled(Object.Ref) Then
		vDocument = GetObjectref();
	Else
		vDocument = Object.Ref;
	EndIf;
	If ValueIsFilled(Object.Guest) Then
		vLang = tcOnServer.cmGetAttributeByRef(Object.Guest, "Language");
	EndIf;
	vInputParameter = New ValueList();
	vInputParameter.Add(vDocument);
	If Not OneGuestMode Then
		For Each vRowData In GuestsInGroup Do
			If ValueIsFilled(vRowData.Ref) And ValueIsFilled(vRowData.GuestRef) Then
				vInputParameter.Add(vRowData.Ref);
			EndIf;
		EndDo;
	EndIf;
	vPrtForm = PredefinedValue("Catalog.ObjectPrintingForms.AccommodationPrintGuestPersonalDataProcessingConsent");
	vParams = New Structure("InputParameter, ObjectPrintingForm, Lang", vInputParameter, vPrtForm, vLang);
	OpenForm("Document.Accommodation.Form.tcAccommodationPrintForm", vParams, ThisObject, new UUID);
EndProcedure // PrintGuestPersonalDataProcessingConsent

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestRefusalToPayResortFee()
	vLang = Undefined;
	vDocument = Undefined;
	If Not ValueIsFilled(Object.Ref) Then
		vDocument = GetObjectref();
	Else
		vDocument = Object.Ref;
	EndIf;
	If ValueIsFilled(Object.Guest) Then
		vLang = tcOnServer.cmGetAttributeByRef(Object.Guest, "Language");
	EndIf;
	vInputParameter = New ValueList();
	vInputParameter.Add(vDocument);
	If Not OneGuestMode Then
		For Each vRowData In GuestsInGroup Do
			If ValueIsFilled(vRowData.Ref) And ValueIsFilled(vRowData.GuestRef) Then
				vInputParameter.Add(vRowData.Ref);
			EndIf;
		EndDo;
	EndIf;
	vPrtForm = PredefinedValue("Catalog.ObjectPrintingForms.AccommodationPrintGuestRefusalToPayResortFee");
	vParams = New Structure("InputParameter, ObjectPrintingForm, Lang", vInputParameter, vPrtForm, vLang);
	OpenForm("Document.Accommodation.Form.tcAccommodationPrintForm", vParams, ThisObject, new UUID);
EndProcedure // PrintGuestRefusalToPayResortFee

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGuestDepartureNotificationForm(pTypeOfPrintForm)
	vDocument = Undefined;
	If ValueIsFilled(Object.Ref) Then
		vDocument = Object.Ref;
	EndIf;
	If Not ValueIsFilled(vDocument) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Document should be saved first!'; ru='Документ сначала должен быть сохранен!'; de='Dokument sollte zuerst gespeichert werden!'"));
		Return;
	EndIf;
	vObjPrtForm = tcOnServer.cmGetCatalogItemRefByName("ObjectPrintingForms", pTypeOfPrintForm);
	vFrm = OpenForm("Report.PrintGuestDepartureForm.Form.tcPrintGuestForm", New Structure("InputParameter, ObjectPrintingForm, OneGuestMode", vDocument, vObjPrtForm, OneGuestMode), ThisObject, Object.Ref);
EndProcedure // PrintGuestDepartureNotificationForm

// -----------------------------------------------------------------------------
&AtServer
Function GetObjectRef(pObj=Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
    vRef = vObj.pmGetThisDocumentRef();
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	Return vRef;
EndFunction // GetObjectRef

// -----------------------------------------------------------------------------
&AtServer
Function GetClientFullName(pRef)
	// Return
	Return pRef.FullName;
EndFunction // GetClientFullName

// -----------------------------------------------------------------------------
&AtServer
Function RoomChoiceProcessingAtServer(pRoom, pObj = Undefined)
	// Check paramters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	vObj.Room = pRoom; 
	vObj.BoardPlace = pRoom.BoardPlace;
	vRefillTypesArray = False;
	If pRoom.RoomType <> vObj.RoomType Then
		vRefillTypesArray = True;
	EndIf;
	vRoomPopUpTasksArray = RoomOnChangeAtServer(True, vObj);
	If ValueIsFilled(vObj.RoomType) And vRefillTypesArray Then
		vTypes = GetTypesArrayByRoomType(vObj.RoomType);
		Items.AccommodationType.ChoiceList.LoadValues(vTypes);
		For Each vGRow In GuestsInGroup Do
			Items["AccommodationType" + Format(GuestsInGroup.IndexOf(vGRow) + 2, "NFD=0; NG=")].ChoiceList.LoadValues(vTypes);
		EndDo;
	EndIf;
	If Not vUseParameterObject Then
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	Return vRoomPopUpTasksArray;
EndFunction // RoomChoiceProcessingAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetAllAccommodationStatuses()
	vAccommodationStatusesArray = New Array;
	vAccStses = cmGetAllAccommodationStatuses();
	For Each vAccSts In vAccStses Do
		// Fill choice array
		vAccommodationStatusesArray.Add(vAccSts.AccommodationStatus);
	EndDo;
	// Return
	Return vAccommodationStatusesArray;
EndFunction // GetAllAccommodationStatuses

// -----------------------------------------------------------------------------
&AtServer
Function CreateGuestItems(pCurrentObject = Undefined)
	vMessage = "";
	vGuestsInGroup = Undefined;
	vCurrObj = pCurrentObject;
	// Get object value
	If pCurrentObject = Undefined Then
		Try
			vCurrObj = FormAttributeToValue("Object");
		Except
			Return NStr("ru='Ошибка захвата объекта! Документ сохранен не будет!';en='Transaction error! The document will not be saved!';de='Transaction error! The document will not be saved!'");
		EndTry;
	EndIf;
	// Create guest items
	// <Current accommodation>
	vSelGuest = SelGuest1;
	If Upper(vSelGuest) <> Upper(vCurrObj.Guest.FullName) Then
		vGuestObj = Catalogs.Clients.CreateItem();
		// Fill attributes with default values
		vGuestObj.pmFillAttributesWithDefaultValues();
		// Get guest last name, first name and second name
		vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
		vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
		vGuestObj.LastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
		If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
			vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
			vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
			vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
			vGuestObj.FirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
			If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vGuestObj.SecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
			EndIf;
		EndIf; 
		vGuestObj.Sex = fmGetSexByName(vGuestObj);
		If ValueIsFilled(vCurrObj.Phone) Then
			vGuestObj.Phone = Object.Phone;
		EndIf;
		If ValueIsFilled(vCurrObj.EMail) Then
			vGuestObj.EMail = vCurrObj.EMail;
		EndIf;
		vGuestObj.Write();
		vGuestObj.pmBindClientToItsChargingRules();
		vGuestObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		UserWorkHistory.Add(vGuestObj.Ref);
		vCurrObj.Guest = vGuestObj.Ref;
		If vCurrObj.Guest.ChargingRules.Count() > 0 Then
			vCurrObj.pmLoadChargingRules(vCurrObj.Guest);
		EndIf;
	EndIf;
	// <Other guests in group accommodations>
	vGuestsInGroup = FormAttributeToValue("GuestsInGroup");
	For Each vGuest In vGuestsInGroup Do
		If vGuest.IsAnnulation Then
			Continue;
		EndIf;
		vSelGuest = vGuest.Guest;
		If cmIsBrokenRef("Catalog.Clients", vGuest.GuestRef) Then
			vGuest.GuestRef = Undefined;
		EndIf;
		If ValueIsFilled(vGuest.AccommodationType) Then
			If Not ValueIsFilled(vGuest.GuestRef) Then
				If ValueIsFilled(vSelGuest) Then
					vGuestObj = Catalogs.Clients.CreateItem();
					// Fill attributes with default values
					vGuestObj.pmFillAttributesWithDefaultValues();
					// Get guest last name, first name and second name
					vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
					vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
					vGuestObj.LastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
					If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
						vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
						vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
						vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
						vGuestObj.FirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
						If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
							vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
							vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
							vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
							vGuestObj.SecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
						EndIf;
					EndIf; 
					vGuestObj.Sex = fmGetSexByName(vGuestObj);
					vGuestObj.Write();
					vGuestObj.pmBindClientToItsChargingRules();
					vGuestObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					UserWorkHistory.Add(vGuestObj.Ref);
					vGuest.GuestRef = vGuestObj.Ref;
					// Fill form attribute
					ThisObject["Guest" + String(vGuestsInGroup.IndexOf(vGuest) + 2)] = vGuestObj.Ref;
				EndIf;
			EndIf;
		Else
			vMessage = NStr("ru='У гостя не указан вид размещения! Документ сохранен не будет!';en='Empty accommodation type! The document will not be saved!';de='Leerer Unterkunftstyp! Das Dokument wird nicht gespeichert!'");
		EndIf;	
	EndDo;
	If vGuestsInGroup <> Undefined Then
		ValueToFormAttribute(vGuestsInGroup, "GuestsInGroup");
	EndIf;
	If pCurrentObject = Undefined Then
		ValueToFormAttribute(vCurrObj, "Object");
	EndIf;
	Return vMessage;
EndFunction // CreateGuestItems

// -----------------------------------------------------------------------------
&AtServer
Function WriteAtServer(pCurrentObject = Undefined, rWarning = "", pDoNotCloseMode = False, pWriteMode = Undefined, rAddRoomsToAllotment = False, rAllotmentBalances = Undefined) Export
	vMessage = "";
	rWarning = "";
	// Check paramters
	vUseParametrObject = True;
	vCurrObj = pCurrentObject;
	// Get object value
	If pCurrentObject = Undefined Then
		Try
			vCurrObj = FormAttributeToValue("Object");
		Except
			Return NStr("ru='Ошибка захвата объекта! Документ сохранен не будет!';en='Transaction error! The document will not be saved!';de='Transaction error! The document will not be saved!'");
		EndTry;
		vUseParametrObject = False;
	EndIf;
	// Check mealboard terms
	If Items.ServicePackage.Visible Then
		If Not ValueIsFilled(vCurrObj.ServicePackage) And ValueIsFilled(vCurrObj.RoomRate) And vCurrObj.RoomRate.MealBoardTermsIsMandatory Then
			If Not ValueIsFilled(vCurrObj.Reservation) Or ValueIsFilled(vCurrObj.Reservation) And ValueIsFilled(vCurrObj.Reservation.ServicePackage) Then
				Return NStr("ru='Вид питания должен быть указан! У гостей, которые не питаются в отеле, укажите <Только проживание>';
				            |en='Mealboard terms should be filled! Specify <Bed only> for guests not eating in the hotel';
							|de='Die Mealboard terms muss angegeben werden! Bitte geben Sie bei Gästen, die nicht im Hotel speisen, <Nur Unterkunft> an'");
			EndIf;
		EndIf;
	EndIf;
	// Checks for new accommodations
	If vCurrObj.IsNew() And ValueIsFilled(vCurrObj.AccommodationStatus) And vCurrObj.AccommodationStatus.IsActive And vCurrObj.AccommodationStatus.IsInHouse Then
		// Check reservation check-in date
		If Not ValueIsFilled(vCurrObj.Reservation) And Not cmCheckUserPermissions("HavePermissionToCreateReservationsInThePast") Then
			vCurrentDate = BegOfDay(CurrentSessionDate());
			If ValueIsFilled(vCurrObj.Hotel) And ValueIsFilled(vCurrObj.Hotel.AccountingDate) Then
				vCurrentDate = vCurrObj.Hotel.AccountingDate;
			EndIf;
			If BegOfDay(vCurrObj.CheckInDate) < vCurrentDate Then
				Return NStr("en='You do not have rights to create reservation in the past!'; ru='Нет прав создавать бронь в прошлом!'; de='Sie haben keine Berechtigung, in der Vergangenheit Reservierungen vorzunehmen!'");
			EndIf;
		EndIf;
		// Check allotment company
		If ValueIsFilled(vCurrObj.RoomQuota) And ValueIsFilled(vCurrObj.RoomQuota.Company) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) And 
		   vCurrObj.RoomQuota.Company <> SessionParameters.CurrentUser.Company Then
			If Not ValueIsFilled(vCurrObj.Reservation) Or ValueIsFilled(vCurrObj.Reservation) And vCurrObj.Reservation.RoomQuota <> vCurrObj.RoomQuota Then
				Return NStr("en='You do not have rights to use " + TrimAll(vCurrObj.RoomQuota.Company) + " company allotment!'; ru='Нет прав использовать квоту компании " + TrimAll(vCurrObj.RoomQuota.Company) + "!'; de='Sie sind nicht berechtigt, die Zimmerquote der Firma " + TrimAll(vCurrObj.RoomQuota.Company) + " verwenden!'");
			EndIf;
		EndIf;
		// Check room rate is valid period
		If Not ValueIsFilled(vCurrObj.Reservation) Or 
		   ValueIsFilled(vCurrObj.Reservation) And vCurrObj.Reservation.RoomRate <> vCurrObj.RoomRate Then
			vCurrObjRoomRate = vCurrObj.RoomRate;
			If ValueIsFilled(vCurrObjRoomRate) And 
			  (BegOfDay(vCurrObj.CheckInDate) < BegOfDay(vCurrObjRoomRate.DateValidFrom) Or ValueIsFilled(vCurrObjRoomRate.DateValidTo) And BegOfDay(vCurrObjRoomRate.DateValidTo) < BegOfDay(vCurrObj.CheckOutDate)) Then
				Return NStr("en='Room rate choosen is not valid for the reservation period!'; ru='Выбранный тариф не действует на периоде проживания брони!'; de='Der gewählte Tarif gilt nicht für die Dauer der Buchung!'");
			EndIf;
		EndIf;
	EndIf;
	// Write additional email
	If ValueIsFilled(vCurrObj.Guest) And Not IsBlankString(EMail2) Then
		vObjGuest = vCurrObj.Guest.GetObject();
		vObjGuest.EMailAdditional = TrimAll(EMail2);
		vObjGuest.Write();   
		vObjGuest.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndIf;
	// Store some values
	vOldCurrObjRoomRate = Undefined;
	vOldCurrObjAccommodationType = Undefined;
	vCurrObjRef = vCurrObj.Ref;
	If ValueIsFilled(vCurrObjRef) Then
		vOldCurrObjRoomRate = vCurrObjRef.RoomRate;
		vOldCurrObjAccommodationType = vCurrObjRef.AccommodationType;
	EndIf;
	// Begin transaction
	Try
		// Create guest items
		vMessage = CreateGuestItems(vCurrObj);
		If Not IsBlankString(vMessage) Then
			Return vMessage;
		EndIf;
		// <Current accommodatoion>
		BeginTransaction();
		// Check accommodation types 
		vPersonsCount = 1;
		vBedsCount = 0;
		If ValueIsFilled(vCurrObj.AccommodationType) Then
			If ValueIsFilled(vCurrObj.AccommodationType.NumberOfRooms) Then
				If ValueIsFilled(vCurrObj.Room) Then
					vBedsCount = vCurrObj.Room.NumberOfBedsPerRoom;
				ElsIf ValueIsFilled(vCurrObj.RoomType) Then
					vBedsCount = vCurrObj.RoomType.NumberOfBedsPerRoom;
				Else
					RollbackTransaction();
					ThisObject.CurrentItem = Items.RoomType;
					vMessage = NStr("en='The field is not filled: Room type';ru='Не заполнено поле: Тип номера';de='Das Feld ist nicht ausgefullt: Zimmertyp'");
					Return vMessage;
				EndIf;
			ElsIf ValueIsFilled(vCurrObj.AccommodationType.NumberOfBeds) Then
				vBedsCount = vBedsCount + vCurrObj.AccommodationType.NumberOfBeds;
			EndIf;
			// Recalculate attributes bound to accommodation type
			vCurrObj.pmCalculateResources();
		Else
			RollbackTransaction();
			ThisObject.CurrentItem = Items.AccommodationType;
			vMessage = NStr("en='The field is not filled: Accommodation type';ru='Не заполнено поле: Вид размещения';de='Das Feld ist nicht ausgefullt: Unterbringungstyp'");
			Return vMessage;
		EndIf;
		// <Other guests in group accommodations>
		vGuestsInGroup = FormAttributeToValue("GuestsInGroup");
		For Each vRow In vGuestsInGroup Do
			vPersonsCount = vPersonsCount + 1;
			If ValueIsFilled(vRow.AccommodationType) Then
				If ValueIsFilled(vRow.AccommodationType.NumberOfBeds) Then
					vBedsCount = vBedsCount + vRow.AccommodationType.NumberOfBeds;
				EndIf;
			EndIf;
		EndDo;
		// Check permissions
		If ValueIsFilled(vCurrObj.Room) Then
			// Check number of beds
			If Not cmCheckUserPermissions("HavePermissionToUseOccupiedRooms") Then
				If vBedsCount > vCurrObj.Room.NumberOfBedsPerRoom Then
					RollbackTransaction();
					vMessage = NStr("en='" + String(vCurrObj.Room.NumberOfBedsPerRoom-vBedsCount) + " vacant beds are not available!';ru='В номере не хватает " + String(0-(vCurrObj.Room.NumberOfBedsPerRoom-vBedsCount)) + " свободных мест!';de='" + String(vCurrObj.Room.NumberOfBedsPerRoom-vBedsCount) + " vacant beds are not available!'");
					Return vMessage;
				EndIf;
			EndIf;
			// Check number of persons
			If Not cmCheckUserPermissions("HavePermissionToIgnoreNumberOfGuestsPerRoomLimits") Then
				If vPersonsCount > vCurrObj.Room.NumberOfPersonsPerRoom Then
					RollbackTransaction();
					vMessage = NStr("en='Unable to check-in " + String(vCurrObj.Room.NumberOfPersonsPerRoom-vPersonsCount) + " guests in room!';ru='Невозможно разместить " + String(0-(vCurrObj.Room.NumberOfPersonsPerRoom-vPersonsCount)) + " гостей в номере!';de='Unable to check-in " + String(vCurrObj.Room.NumberOfPersonsPerRoom-vPersonsCount) + " guests in room!'");
					Return vMessage;
				EndIf;
			EndIf;
		ElsIf ValueIsFilled(vCurrObj.RoomType) Then
			// Check number of beds
			If Not cmCheckUserPermissions("HavePermissionToUseOccupiedRooms") Then
				If vBedsCount > vCurrObj.RoomType.NumberOfBedsPerRoom Then
					RollbackTransaction();
					vMessage = NStr("en='" + String(vCurrObj.RoomType.NumberOfBedsPerRoom-vBedsCount) + " vacant beds are not available!';ru='В номере не хватает " + String(0-(vCurrObj.RoomType.NumberOfBedsPerRoom-vBedsCount)) + " свободных мест!';de='" + String(vCurrObj.RoomType.NumberOfBedsPerRoom-vBedsCount) + " vacant beds are not available!'");
					Return vMessage;
				EndIf;
			EndIf;
			// Check number of persons
			If Not cmCheckUserPermissions("HavePermissionToIgnoreNumberOfGuestsPerRoomLimits") Then
				If vPersonsCount > vCurrObj.RoomType.NumberOfPersonsPerRoom Then
					RollbackTransaction();
					vMessage = NStr("en='Unable to check-in " + vCurrObj.RoomType.NumberOfPersonsPerRoom-vPersonsCount + " guests in room!';ru='Невозможно разместить " + String(0-(vCurrObj.RoomType.NumberOfPersonsPerRoom-vPersonsCount)) + " гостей в номере!';de='Unable to check-in " + vCurrObj.RoomType.NumberOfPersonsPerRoom-vPersonsCount + " guests in room!'");
					Return vMessage;
				EndIf;
			EndIf;
		Else
			RollbackTransaction();
			ThisObject.CurrentItem = Items.RoomType;
			vMessage = NStr("en='The field is not filled: Room type';ru='Не заполнено поле: Тип номера';de='Das Feld ist nicht ausgefullt: Zimmertyp'");
			Return vMessage;
		EndIf;
		// Do UndoPosting of all one room documents
		If pWriteMode <> DocumentWriteMode.Write Then
			If Not vCurrObj.IsNew() Then
				vCurrObj.pmClearInventoryRegisterRecords();
			EndIf;
			For Each vRow In vGuestsInGroup Do
				If ValueIsFilled(vRow.Ref) Then
					vGuestObj = vRow.Ref.GetObject();
					If Not vGuestObj.IsNew() Then
						vGuestObj.pmClearInventoryRegisterRecords();
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		// Synchronize current accommodation room rates and document attributes
		vCurrObj.RoomRates.Sort("AccountingDate Desc");
		For Each vRRRow In vCurrObj.RoomRates Do
			vLastRoomRate = vRRRow.RoomRate;
			vLastAccommodationType = vRRRow.AccommodationType;
			vLastRoom = vRRRow.Room;
			vLastRoomType = vRRRow.RoomType;
			If vRRRow.AccountingDate <= BegOfDay(CurrentSessionDate()) Then
				If ValueIsFilled(vLastRoomRate) And vLastRoomRate <> vCurrObj.RoomRate Then
					NeedServicesRecalculation = True;
					vCurrObj.RoomRate = vLastRoomRate;
					If ValueIsFilled(vCurrObj.RoomRate) Then
						vCurrObj.RoomRateType = vCurrObj.RoomRate.RoomRateType;
					EndIf;
				EndIf;
				If ValueIsFilled(vLastAccommodationType) And vLastAccommodationType <> vCurrObj.AccommodationType Then
					NeedServicesRecalculation = True;
					vCurrObj.AccommodationType = vLastAccommodationType;
				EndIf;
				If ValueIsFilled(vLastRoom) And vLastRoom <> vCurrObj.Room Then
					NeedServicesRecalculation = True;
					vCurrObj.Room = vLastRoom;
					vCurrObj.RoomType = vLastRoomType;
				EndIf;
				Break;
			EndIf;
		EndDo;
		vCurrObj.RoomRates.Sort("AccountingDate, ChangeTime");
		// Save guest age if it is possible
		If NumberOfAdults = 0 And NumberOfKids > 0 Then
			vCurrObj.GuestAge = ThisObject["KidAge1"];
			If ValueIsFilled(vCurrObj.Guest) Then
				vCurrObj.GuestCitizenship = vCurrObj.Guest.Citizenship;
			EndIf;
		ElsIf Not OneGuestMode Then
			vCurrObj.GuestAge = 0;
		EndIf;
		// Default customer
		If Not ValueIsFilled(vCurrObj.Customer) And ValueIsFilled(vCurrObj.Guest) And 
		   ValueIsFilled(vCurrObj.Company) And vCurrObj.Company.CreateIndividualsCustomerForEachClient Then
			vCurrObj.Customer = CreateCustomerFromGuest(vCurrObj.Guest);
			CustomerOnChangeAtServer(vCurrObj);
			NeedServicesRecalculation = False;
		EndIf;
		// Calculate services
		If NeedServicesRecalculation Then
			vCurrObj.pmCalculateServices( , , , , , vCurrObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vCurrObj.AccommodationTemplate));
			// Fill accommodation template
			If Not OneGuestMode Then
				FillAccommodationTemplate(vCurrObj);
			EndIf;
		EndIf;
		// Posting
		// <Current accommodation>
		vCurrObj.AdditionalProperties.Insert("DoNotCloseMode", pDoNotCloseMode);
		vCurrObj.AdditionalProperties.Insert("GuestsInRoom", vGuestsInGroup);
		vCurrObj.AdditionalProperties.Insert("WarningMessage", "");
		vCurrObj.Write(?(pWriteMode = Undefined, DocumentWriteMode.Posting, pWriteMode));
		// Save data to the document history
		If pWriteMode <> DocumentWriteMode.Write Then
			vCurrObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			SavedButNotPostedWhileOpen = False;
		EndIf;
		// Write to user work history
		UserWorkHistory.Add(vCurrObj.Ref);
		// Fill warning
		If Not IsBlankString(vCurrObj.AdditionalProperties.WarningMessage) Then
			rWarning = rWarning + ?(IsBlankString(rWarning), "", Chars.LF) + cmNStr(vCurrObj.AdditionalProperties.WarningMessage);
		EndIf;
		
		// Fill flag to modify allotment
		rAddRoomsToAllotment = False;
		If vCurrObj.AdditionalProperties.Property("AddRoomsToAllotment") And vCurrObj.AdditionalProperties.AddRoomsToAllotment Then
			rAddRoomsToAllotment = True;
		EndIf;
		rAllotmentBalances = Undefined;
		If vCurrObj.AdditionalProperties.Property("AllotmentBalances") And TypeOf(vCurrObj.AdditionalProperties.AllotmentBalances) = Type("Array") Then
			rAllotmentBalances = vCurrObj.AdditionalProperties.AllotmentBalances;
		EndIf;
		
		// Save custom fields
		SaveCustomFields(vCurrObj.Ref);
		// Load and show room interface command
		SetRoomInterfacesFilter(vCurrObj);
		// Process other room guests
		vGuestsRefTable = New ValueTable;
		vGuestsRefTable.Columns.Add("Ref");
		vGuestsRefTable.Columns.Add("Row");
		// <Other guests in group accommodations>
		i = 0;
		For Each vRow In vGuestsInGroup Do
			If ValueIsFilled(vRow.AccommodationType) Then
				vRowAccommodationType = vRow.AccommodationType;
				vGuestRowIndex = vGuestsInGroup.IndexOf(vRow) + 1;
				vObjectRef = Undefined;
				vObject = Undefined;
				vObjectReservation = Undefined;
				If ValueIsFilled(vRow.Ref) Then
					vObjectRef = vRow.Ref;
					vObjectReservation = vObjectRef.Reservation;
					vObject = vObjectRef.GetObject();
					If vCurrObj.IsForFolioSplit And 
					  (ValueIsFilled(vCurrObj.GuestGroup) And Not vCurrObj.GuestGroup.OneCustomerPerGuestGroup Or 
					   ValueIsFilled(vCurrObj.Company) And vCurrObj.Company.CreateIndividualsCustomerForEachClient And ValueIsFilled(vCurrObj.Customer) And ValueIsFilled(vCurrObj.Guest) And vCurrObj.Customer.Client = vCurrObj.Guest) Then
						FillPropertyValues(vObject, vCurrObj, , "Date, Author, AccommodationStatus, Guest, AccommodationType, SharePercent, GuestFullName, Car, Remarks, HousekeepingRemarks, SortCode, ExternalCode, ParentDoc, Reservation, IsByReservation, Phone, EMail, Fax, CreditCard, ClientType, HotelProduct, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants, RoomPropertiesDescriptions, RoomPropertiesCodes, AccommodationTemplate, PriceCalculationDate, LegalRepresentative, RelationType, ServicePackage, Customer, Contract, Company, Agent, TouristicTaxExemptionReason, TouristicTaxExemptionReasonFillDate, TouristicTaxExemptionConfirmationData" + ?(vRow.IsForFolioSplitIsDifferent, ", IsForFolioSplit", ""));
					Else
						FillPropertyValues(vObject, vCurrObj, , "Date, Author, AccommodationStatus, Guest, AccommodationType, SharePercent, GuestFullName, Car, Remarks, HousekeepingRemarks, SortCode, ExternalCode, ParentDoc, Reservation, IsByReservation, Phone, EMail, Fax, CreditCard, ClientType, HotelProduct, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants, RoomPropertiesDescriptions, RoomPropertiesCodes, AccommodationTemplate, PriceCalculationDate, LegalRepresentative, RelationType, ServicePackage, TouristicTaxExemptionReason, TouristicTaxExemptionReasonFillDate, TouristicTaxExemptionConfirmationData" + ?(vRow.IsForFolioSplitIsDifferent, ", IsForFolioSplit", ""));
					EndIf;
					// Folio split
					If vRow.IsForFolioSplitIsDifferent Then
						vObject.IsForFolioSplit = vRow.pIsForFolioSplit;
					EndIf;
					// Update charging rules if necessary
					vPostToRoomMainFolio = False;
					vDoNotCreatePersonalFolios = False;
					vRefAccommodationType = vObjectRef.AccommodationType;
					vRefPostToRoomMainFolio = False;
					vRefDoNotCreatePersonalFolios = False;
					If vRowAccommodationType.PostToRoomMainFolio And vRowAccommodationType.DoNotCreatePersonalFolios Then
						vPostToRoomMainFolio = True;
						vDoNotCreatePersonalFolios = True;
					Else
						If Not vObject.IsForFolioSplit Then
							If vRowAccommodationType.PostToRoomMainFolio Then
								vPostToRoomMainFolio = True;
							EndIf;
						EndIf;
					EndIf;
					If vRefAccommodationType.PostToRoomMainFolio And vRefAccommodationType.DoNotCreatePersonalFolios Then
						vRefPostToRoomMainFolio = True;
						vRefDoNotCreatePersonalFolios = True;
					Else
						If Not vObjectRef.IsForFolioSplit Then
							If vRefAccommodationType.PostToRoomMainFolio Then
								vRefPostToRoomMainFolio = True;
							EndIf;
						EndIf;
					EndIf;
					If vPostToRoomMainFolio <> vRefPostToRoomMainFolio Or 
					   vDoNotCreatePersonalFolios <> vRefDoNotCreatePersonalFolios Or 
					   vObjectRef.IsForFolioSplit <> vObject.IsForFolioSplit Or
					   vObjectRef.PlannedPaymentMethod <> vObject.PlannedPaymentMethod Or
					   vObjectRef.Customer <> vObject.Customer Or 
					   vObjectRef.Contract <> vObject.Contract Then
						// Try to save external transfer rules
						vChargingRulesCopy = vObject.ChargingRules.Unload();
						vCRTransfers = vChargingRulesCopy.FindRows(New Structure("IsTransfer", True));
						j = 0;
						While j < vCRTransfers.Count() Do
							vCRTransfersRow = vCRTransfers.Get(j);
							vCRRowFolio = vCRTransfersRow.ChargingFolio;
							If ValueIsFilled(vCRRowFolio) Then
								If ValueIsFilled(vCRRowFolio.ParentDoc) And TrimAll(vCRRowFolio.ParentDoc.Number) = TrimAll(vObject.Number) Then
									vCRTransfers.Delete(j);
									Continue;
								EndIf;
							EndIf;
							j = j + 1;
						EndDo;
						// Try to remove transfer rules to main room guest
						If vObject.IsForFolioSplit And Not vObjectRef.IsForFolioSplit Then
							j = 0;
							While j < vObject.ChargingRules.Count() Do
								vCRTransfersRow = vObject.ChargingRules.Get(j);
								If vCRTransfersRow.IsTransfer Then
									vCRRowFolio = vCRTransfersRow.ChargingFolio;
									If ValueIsFilled(vCRRowFolio) Then
										If ValueIsFilled(vCRRowFolio.ParentDoc) And TrimAll(vCRRowFolio.ParentDoc.Number) = TrimAll(vObject.Number) Then
											vObject.ChargingRules.Delete(j);
											Continue;
										EndIf;
									EndIf;
								EndIf;
								j = j + 1;
							EndDo;
						EndIf;
						// Update document charging rules if neccessary
						If vPostToRoomMainFolio Then
							If vDoNotCreatePersonalFolios Then
								cmLoadMainRoomGuestChargingRules(vObject, vCurrObj);
							Else
								If vObject.IsForFolioSplit Then
									If vObjectRef.IsForFolioSplit Then
										cmCompareAndUpdateDocumentChargingRules(vObject, vCurrObj, vPostToRoomMainFolio);
									Else
										cmCreateChargingRulesBasedOnParent(vObject, vCurrObj);
									EndIf;
								Else
									If vObject.Hotel.ChargingRules.Find(True, "IsPersonal") = Undefined Then
										cmLoadMainRoomGuestChargingRules(vObject, vCurrObj);
									Else
										cmCompareAndUpdateDocumentChargingRules(vObject, vCurrObj, vPostToRoomMainFolio);
									EndIf;
								EndIf;
							EndIf;
						ElsIf Not (vCurrObj.IsForFolioSplit And ValueIsFilled(vCurrObj.GuestGroup) And Not vCurrObj.GuestGroup.OneCustomerPerGuestGroup) Then
							cmCompareAndUpdateDocumentChargingRules(vObject, vCurrObj, vPostToRoomMainFolio);
						EndIf;
						// Restore transfer rules
						t = 0;
						For Each vCRTransfersRow In vCRTransfers Do
							If vObject.ChargingRules.Find(vCRTransfersRow.ChargingFolio, "ChargingFolio") = Undefined Then
								vTrCRRow = vObject.ChargingRules.Insert(t);
								FillPropertyValues(vTrCRRow, vCRTransfersRow);
								t = t + 1;
							EndIf;
						EndDo;
					EndIf;
					// Fill charging rules rows owners
					For Each vCRRow In vObject.ChargingRules Do
						vChargingFolio = vCRRow.ChargingFolio;
						If vCRRow.Owner <> vChargingFolio.ParentDoc Then
							If ValueIsFilled(vChargingFolio.Contract) Then
								If vCRRow.Owner <> vChargingFolio.Contract Then
									vCRRow.Owner = vChargingFolio.Contract;
								EndIf;
							ElsIf ValueIsFilled(vChargingFolio.Customer) Then
								If vCRRow.Owner <> vChargingFolio.Customer Then
									vCRRow.Owner = vChargingFolio.Customer;
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				Else
					vObjectReservation = Undefined;
					vObject = Documents.Accommodation.CreateDocument();
					vAttributesToCopyFromReservation = "";
					If GuestsToCheckInList.Count() > 0 And i < (GuestsToCheckInList.Count() - 1) Then
						vObjectReservation = GuestsToCheckInList[i+1].Value;
						If ValueIsFilled(vObjectReservation) Then
							vObject.Fill(vObjectReservation);
							vAttributesToCopyFromReservation = ", RoomRate, TouristicTaxExemptionReason, TouristicTaxExemptionReasonFillDate, TouristicTaxExemptionConfirmationData, IsForFolioSplit";
						EndIf;
					EndIf;
					If vCurrObj.IsForFolioSplit And 
					  (ValueIsFilled(vCurrObj.GuestGroup) And Not vCurrObj.GuestGroup.OneCustomerPerGuestGroup Or 
					   ValueIsFilled(vCurrObj.Company) And vCurrObj.Company.CreateIndividualsCustomerForEachClient And ValueIsFilled(vCurrObj.Customer) And ValueIsFilled(vCurrObj.Guest) And vCurrObj.Customer.Client = vCurrObj.Guest) Then 
						If vObjectReservation = Undefined Then
							FillPropertyValues(vObject, vCurrObj, , "Date, Author, Guest, AccommodationType, SharePercent, GuestFullName, Car, Remarks, HousekeepingRemarks, SortCode, ExternalCode, ParentDoc, Reservation, IsByReservation, Phone, EMail, Fax, CreditCard, ClientType, HotelProduct, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants, RoomPropertiesDescriptions, RoomPropertiesCodes, AccommodationTemplate, PriceCalculationDate, LegalRepresentative, RelationType, ServicePackage, Customer, Contract");
							// Folio split
							If vRow.IsForFolioSplitIsDifferent Then
								vObject.IsForFolioSplit = vRow.pIsForFolioSplit;
							EndIf;
						Else
							FillPropertyValues(vObject, vCurrObj, , "Date, Author, Guest, AccommodationType, SharePercent, GuestFullName, Car, Remarks, HousekeepingRemarks, SortCode, ExternalCode, ParentDoc, Reservation, IsByReservation, Phone, EMail, Fax, CreditCard, ClientType, HotelProduct, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants, RoomPropertiesDescriptions, RoomPropertiesCodes, AccommodationTemplate, PriceCalculationDate, LegalRepresentative, RelationType, ServicePackage, Customer, Contract" + vAttributesToCopyFromReservation);
						EndIf;
					ElsIf vObjectReservation <> Undefined And vCurrObj.IsForFolioSplit And 
						  ValueIsFilled(vCurrObj.GuestGroup) And Not vCurrObj.GuestGroup.OneCustomerPerGuestGroup Then
						FillPropertyValues(vObject, vCurrObj, , "Date, Author, Guest, AccommodationType, SharePercent, GuestFullName, Car, Remarks, HousekeepingRemarks, SortCode, ExternalCode, ParentDoc, Reservation, IsByReservation, Phone, EMail, Fax, CreditCard, ClientType, HotelProduct, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants, RoomPropertiesDescriptions, RoomPropertiesCodes, AccommodationTemplate, PriceCalculationDate, LegalRepresentative, RelationType, ServicePackage, Customer, Contract, Company, Agent" + vAttributesToCopyFromReservation);
					Else
						FillPropertyValues(vObject, vCurrObj, , "Date, Author, Guest, AccommodationType, SharePercent, GuestFullName, Car, Remarks, HousekeepingRemarks, SortCode, ExternalCode, ParentDoc, Reservation, IsByReservation, Phone, EMail, Fax, CreditCard, ClientType, HotelProduct, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants, RoomPropertiesDescriptions, RoomPropertiesCodes, AccommodationTemplate, PriceCalculationDate, LegalRepresentative, RelationType, ServicePackage" + vAttributesToCopyFromReservation);
					EndIf;
					If Not IsNew And BegOfDay(vCurrObj.CheckInDate) < BegOfDay(CurrentSessionDate()) And BegOfDay(CurrentSessionDate()) < BegOfDay(vCurrObj.CheckOutDate) Then
						vObject.CheckInDate = cm1SecondShift(CurrentSessionDate());
						vObject.Duration = vObject.pmCalculateDuration();
					EndIf;
					vObject.pmFillAuthorAndDate();
					vObject.Car = "";
					vObject.Remarks = "";
					vObject.HousekeepingRemarks = "";
					If Not (GuestsToCheckInList.Count() > 0 And i < (GuestsToCheckInList.Count() - 1)) Then
						If Not ValueIsFilled(vObject.ParentDoc) And ValueIsFilled(vCurrObj.Reservation) And vCurrObj.Reservation.NumberOfPersons > 1 Then
							vObject.ParentDoc = vCurrObj.ParentDoc;
							vObject.Reservation = vCurrObj.Reservation;
							vObject.IsByReservation = vCurrObj.IsByReservation;
						EndIf;
					EndIf;
					// Charging rules
					If ValueIsFilled(vObject.ParentDoc) Then
						If TypeOf(vObject.ParentDoc) = Type("DocumentRef.Accommodation") Then
							// Use folios from the base document
							vObject.ChargingRules.Load(vObject.ParentDoc.ChargingRules.Unload());
						Else
							// Check parent reservation charging folio parent document
							vBaseFolioParentDocIsReservation = True;
							If Not ValueIsFilled(vObject.ParentDoc.ParentDoc) Or ValueIsFilled(vObject.ParentDoc.ParentDoc) And TypeOf(vObject.ParentDoc.ParentDoc) <> Type("DocumentRef.Reservation") Then
								For Each vCRRow In vObject.ParentDoc.ChargingRules Do
									If ValueIsFilled(vCRRow.ChargingFolio) And 
									   ValueIsFilled(vCRRow.ChargingFolio.ParentDoc) And 
									   TypeOf(vCRRow.ChargingFolio.ParentDoc) = Type("DocumentRef.Accommodation") And 
									   Not vCRRow.IsMaster And Not vCRRow.IsTransfer Then
										vBaseFolioParentDocIsReservation = False;
										Break;
									EndIf;
								EndDo;
							EndIf;
							// Create charging rules
							If vObject.ParentDoc.RoomQuantity = 1 And vBaseFolioParentDocIsReservation Then
								// Use folios from the base document
								cmUseParentChargingRules(vObject, vObject.ParentDoc);
							ElsIf vObject.ParentDoc.RoomQuantity = 1 And vRowAccommodationType.PostToRoomMainFolio Then
								// Use folios from the base document, but mark them as transfer
								If vRowAccommodationType.DoNotCreatePersonalFolios Then
									cmLoadMainRoomGuestChargingRules(vObject, vObject.ParentDoc);
								Else
									cmUseParentChargingRules(vObject, vObject.ParentDoc, True);
								EndIf;
							Else
								// Create folios as copy of base folios
								cmCreateChargingRulesBasedOnParent(vObject, vObject.ParentDoc);
							EndIf;
							// Check if is for folio split flag has changed
							vObjectRef = vObject.ParentDoc;
							vPostToRoomMainFolio = False;
							vDoNotCreatePersonalFolios = False;
							vRefAccommodationType = vObjectRef.AccommodationType;
							vRefPostToRoomMainFolio = False;
							vRefDoNotCreatePersonalFolios = False;
							If vRowAccommodationType.PostToRoomMainFolio And vRowAccommodationType.DoNotCreatePersonalFolios Then
								vPostToRoomMainFolio = True;
								vDoNotCreatePersonalFolios = True;
							Else
								If Not vObject.IsForFolioSplit Then
									If vRowAccommodationType.PostToRoomMainFolio Then
										vPostToRoomMainFolio = True;
									EndIf;
								EndIf;
							EndIf;
							If vRefAccommodationType.PostToRoomMainFolio And vRefAccommodationType.DoNotCreatePersonalFolios Then
								vRefPostToRoomMainFolio = True;
								vRefDoNotCreatePersonalFolios = True;
							Else
								If Not vObjectRef.IsForFolioSplit Then
									If vRefAccommodationType.PostToRoomMainFolio Then
										vRefPostToRoomMainFolio = True;
									EndIf;
								EndIf;
							EndIf;
							If vPostToRoomMainFolio <> vRefPostToRoomMainFolio Or 
							   vDoNotCreatePersonalFolios <> vRefDoNotCreatePersonalFolios Or 
							   vObjectRef.IsForFolioSplit <> vObject.IsForFolioSplit Or
							   vObjectRef.PlannedPaymentMethod <> vObject.PlannedPaymentMethod Or
							   vObjectRef.Customer <> vObject.Customer Or 
							   vObjectRef.Contract <> vObject.Contract Then
								// Try to save external transfer rules
								vChargingRulesCopy = vObject.ChargingRules.Unload();
								vCRTransfers = vChargingRulesCopy.FindRows(New Structure("IsTransfer", True));
								j = 0;
								While j < vCRTransfers.Count() Do
									vCRTransfersRow = vCRTransfers.Get(j);
									vCRRowFolio = vCRTransfersRow.ChargingFolio;
									If ValueIsFilled(vCRRowFolio) Then
										If ValueIsFilled(vCRRowFolio.ParentDoc) And TrimAll(vCRRowFolio.ParentDoc.Number) = TrimAll(vObject.Number) Then
											vCRTransfers.Delete(j);
											Continue;
										EndIf;
									EndIf;
									j = j + 1;
								EndDo;
								// Try to remove transfer rules to main room guest
								If vObject.IsForFolioSplit And Not vObjectRef.IsForFolioSplit Then
									j = 0;
									While j < vObject.ChargingRules.Count() Do
										vCRTransfersRow = vObject.ChargingRules.Get(j);
										If vCRTransfersRow.IsTransfer Then
											vCRRowFolio = vCRTransfersRow.ChargingFolio;
											If ValueIsFilled(vCRRowFolio) Then
												If ValueIsFilled(vCRRowFolio.ParentDoc) And TrimAll(vCRRowFolio.ParentDoc.Number) = TrimAll(vObject.Number) Then
													vObject.ChargingRules.Delete(j);
													Continue;
												EndIf;
											EndIf;
										EndIf;
										j = j + 1;
									EndDo;
								EndIf;
								// Update document charging rules if neccessary
								If vPostToRoomMainFolio Then
									If vDoNotCreatePersonalFolios Then
										cmLoadMainRoomGuestChargingRules(vObject, vCurrObj);
									Else
										If vObject.IsForFolioSplit Then
											If vObjectRef.IsForFolioSplit Then
												cmCompareAndUpdateDocumentChargingRules(vObject, vCurrObj, vPostToRoomMainFolio);
											Else
												cmCreateChargingRulesBasedOnParent(vObject, vCurrObj);
											EndIf;
										Else
											If vObject.Hotel.ChargingRules.Find(True, "IsPersonal") = Undefined Then
												cmLoadMainRoomGuestChargingRules(vObject, vCurrObj);
											Else
												cmCompareAndUpdateDocumentChargingRules(vObject, vCurrObj, vPostToRoomMainFolio);
											EndIf;
										EndIf;
									EndIf;
								ElsIf Not (vCurrObj.IsForFolioSplit And ValueIsFilled(vCurrObj.GuestGroup) And Not vCurrObj.GuestGroup.OneCustomerPerGuestGroup) Then
									cmCompareAndUpdateDocumentChargingRules(vObject, vCurrObj, vPostToRoomMainFolio);
								EndIf;
								// Restore transfer rules
								t = 0;
								For Each vCRTransfersRow In vCRTransfers Do
									If vObject.ChargingRules.Find(vCRTransfersRow.ChargingFolio, "ChargingFolio") = Undefined Then
										vTrCRRow = vObject.ChargingRules.Insert(t);
										FillPropertyValues(vTrCRRow, vCRTransfersRow);
										t = t + 1;
									EndIf;
								EndDo;
							EndIf;
							// Fill charging rules rows owners
							For Each vCRRow In vObject.ChargingRules Do
								vChargingFolio = vCRRow.ChargingFolio;
								If vCRRow.Owner <> vChargingFolio.ParentDoc Then
									If ValueIsFilled(vChargingFolio.Contract) Then
										If vCRRow.Owner <> vChargingFolio.Contract Then
											vCRRow.Owner = vChargingFolio.Contract;
										EndIf;
									ElsIf ValueIsFilled(vChargingFolio.Customer) Then
										If vCRRow.Owner <> vChargingFolio.Customer Then
											vCRRow.Owner = vChargingFolio.Customer;
										EndIf;
									EndIf;
								EndIf;
							EndDo;
						EndIf;
					Else
						// Charging rules
						If vRowAccommodationType.PostToRoomMainFolio Then
							If vRowAccommodationType.DoNotCreatePersonalFolios Then
								cmLoadMainRoomGuestChargingRules(vObject, vCurrObj);
							Else
								If vCurrObj.IsForFolioSplit Then
									cmCreateChargingRulesBasedOnParent(vObject, vCurrObj);
								Else
									cmUseParentChargingRules(vObject, vCurrObj, True);
								EndIf;
							EndIf;
						Else
							cmCreateChargingRulesBasedOnParent(vObject, vCurrObj);
						EndIf;
					EndIf;
				EndIf;
				If vObject <> Undefined Then
					If vObject.IsNew() Then
						vObject.SetNewObjectRef(Documents.Accommodation.GetRef(New UUID()));
					EndIf;
					vObject.Guest = vRow.GuestRef;
					vObject.LegalRepresentative = vRow.LegalRepresentative;
					vObject.RelationType = vRow.RelationType;
					If ValueIsFilled(vObject.Guest) Then
						If vObject.Guest.ChargingRules.Count() > 0 Then
							vObject.pmLoadChargingRules(vObject.Guest);
						EndIf;
						If ValueIsFilled(vObject.Guest.ClientType) And (Not ValueIsFilled(vObject.Guest.ClientType.Hotel) Or vObject.Guest.ClientType.Hotel = vObject.Hotel) Then
							vObject.ClientType = vObject.Guest.ClientType;
						EndIf;
					EndIf;
					vCurGuestAge = 0;
					vCurKidIndex = vGuestRowIndex - NumberOfAdults + 1;
					If vCurKidIndex > 0 Then
						vCurGuestAge = ThisObject["KidAge" + String(vCurKidIndex)];
					EndIf;
					vObject.GuestAge = vCurGuestAge;
					vObject.GuestCitizenship = vRow.GuestCitizenship;
					vObject.AccommodationType = vRow.AccommodationType;
					vObject.SharePercent = vRow.SharePercent;
					vObject.GuestFullName = vRow.Guest;
					If Not ValueIsFilled(vObject.ClientType) And ValueIsFilled(vCurrObj.ClientType) And ValueIsFilled(vCurrObj.ClientType.Mode) Then
						If vCurrObj.ClientType.Mode = Enums.ClientTypeModes.PerRoom Then
							If ValueIsFilled(vCurrObj.Room) And vCurrObj.Room = vObject.Room Then
								vObject.ClientType = vCurrObj.ClientType;
							EndIf;
						ElsIf vCurrObj.ClientType.Mode = Enums.ClientTypeModes.PerGroup Then
							vObject.ClientType = vCurrObj.ClientType;
						EndIf;
					EndIf;
					If ValueIsFilled(vRow.AccommodationStatus) Then
						vObject.AccommodationStatus = vRow.AccommodationStatus;
					EndIf;
					If ValueIsFilled(vObject.RoomRate) Then
						vObject.RoomRateType = vObject.RoomRate.RoomRateType;
					EndIf;
					vObject.RoomType = vCurrObj.RoomType;
					vObject.Room = vCurrObj.Room;
					vObject.HotelProduct = vRow.HotelProduct;
					// Occupation percents
					If vObject.IsNew() Or Not vCurrObj.IsForFolioSplit Then
						vObject.OccupationPercents.Load(vCurrObj.OccupationPercents.Unload());
					EndIf;
					// Service packages
					If ValueIsFilled(vCurrObj.ServicePackage) Then
						If vCurrObj.ServicePackage.IsMealBoardTerm Then
							If vObject.IsNew() And Not ValueIsFilled(vObject.Reservation) Or Not vObject.IsNew() And Not vCurrObj.IsForFolioSplit Then
								vObject.ServicePackage = vCurrObj.ServicePackage;
							EndIf;
						Else
							If vCurrObj.ServicePackage.IsPerPerson Then
								If vObject.IsNew() And Not ValueIsFilled(vObject.Reservation) Or Not vObject.IsNew() And Not vCurrObj.IsForFolioSplit Then
									vObject.ServicePackage = vCurrObj.ServicePackage;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					vUpdateSP = False;
					For Each vSrvPkgRow In vCurrObj.ServicePackages Do
						If ValueIsFilled(vSrvPkgRow.ServicePackage) And vSrvPkgRow.ServicePackage.IsPerPerson Then
							If vObject.IsNew() And Not ValueIsFilled(vObject.Reservation) Or Not vCurrObj.IsForFolioSplit Then
								If Not vUpdateSP Then
									vUpdateSP = True;
									vObject.ServicePackages.Clear();
								EndIf;
								vSrvObjPkgRow = vObject.ServicePackages.Add();
								vSrvObjPkgRow.ServicePackage = vSrvPkgRow.ServicePackage;
								vSrvObjPkgRow.Quantity = vSrvPkgRow.Quantity;
								vSrvObjPkgRow.DateFrom = vSrvPkgRow.DateFrom;
								vSrvObjPkgRow.DateTo = vSrvPkgRow.DateTo;
							EndIf;
						EndIf;
					EndDo;
					// Services
					If vObject.IsNew() Then
						If IsManualRoomPrice = 3 Then
							vObject.Services.Load(vCurrObj.Services.Unload());
						Else
							If vObject.AccommodationType = vCurrObj.AccommodationType Then
								vObject.Services.Load(vCurrObj.Services.Unload());
							Else
								vObject.Services.Load(vCurrObj.Services.Unload(New Structure("IsManual", False)));
								For Each vObjectServicesRow In vObject.Services Do
									vObjectServicesRow.IsManualPrice = False;
									vObjectServicesRow.QuantityIsChanged = False;
								EndDo;
							EndIf;
						EndIf;
					Else
						If vCurrObj.IsForFolioSplit And Not vObject.Ref.IsForFolioSplit Then
							If vObject.AccommodationType = vCurrObj.AccommodationType Then
								vObject.Services.Load(vCurrObj.Services.Unload());
							Else
								vObject.Services.Load(vCurrObj.Services.Unload(New Structure("IsManual", False)));
								For Each vObjectServicesRow In vObject.Services Do
									vObjectServicesRow.IsManualPrice = False;
									vObjectServicesRow.QuantityIsChanged = False;
								EndDo;
							EndIf;
						EndIf;
					EndIf;
					// Prices
					If vObject.IsNew() Or Not vCurrObj.IsForFolioSplit Then
						If IsManualRoomPrice = 3 Then
							CopyPrices(vObject.Prices, vCurrObj.Prices);
						ElsIf IsManualRoomPrice = 1 Then
							If vCurrObj.IsForFolioSplit And Not IsBlankString(vRow.SharePercent) Then
								CopyPrices(vObject.Prices, vCurrObj.Prices);
							Else
								CopyPrices(vObject.Prices, vCurrObj.Prices, 0);
							EndIf;
						Else
							If vObject.AccommodationType = vCurrObj.AccommodationType Then
								CopyPrices(vObject.Prices, vCurrObj.Prices);
							Else
								CopyPrices(vObject.Prices);
							EndIf;
						EndIf;
					ElsIf vCurrObj.IsForFolioSplit Then
						If IsManualRoomPrice = 3 And Not vRow.ManualPricesAreDifferent Then
							CopyPrices(vObject.Prices, vCurrObj.Prices);
						ElsIf IsManualRoomPrice = 1 Then
							If vCurrObj.IsForFolioSplit And Not IsBlankString(vRow.SharePercent) Then
								vRow.ManualPricesAreDifferent = False;
								CopyPrices(vObject.Prices, vCurrObj.Prices);
							ElsIf Not vRow.ManualPricesAreDifferent Then
								CopyPrices(vObject.Prices, vCurrObj.Prices, 0);
							EndIf;
						EndIf;
					EndIf;
					// Resort fee and tourist tax
					If vRow.IsNoResortFee Then
						vObject.TouristicTaxExemptionReason = vCurrObj.TouristicTaxExemptionReason;
						vObject.TouristicTaxExemptionReasonFillDate = vCurrObj.TouristicTaxExemptionReasonFillDate;
						vObject.TouristicTaxExemptionConfirmationData = vCurrObj.TouristicTaxExemptionConfirmationData;
						ProcessResortFee(vObject.Prices, vCurrObj.Prices);
					EndIf;
					// Load current document room rates
					vObject.RoomRates.Clear();
					For Each vCORRRow In vCurrObj.RoomRates Do
						vRRRow = vObject.RoomRates.Find(vCORRRow.AccountingDate, "AccountingDate");
						If vRRRow = Undefined Then
							vRRRow = vObject.RoomRates.Add();
							vRRRow.AccountingDate = vCORRRow.AccountingDate;
							vRRRow.ChangeTime = vCORRRow.ChangeTime;
						EndIf;
						If ValueIsFilled(vCORRRow.RoomRate) Then
							If ValueIsFilled(vOldCurrObjRoomRate) And vOldCurrObjRoomRate = vObject.Ref.RoomRate Then
								vRRRow.RoomRate = vCORRRow.RoomRate;
							EndIf;
						EndIf;
						If ValueIsFilled(vCORRRow.AccommodationType) Then
							If vCORRRow.AccommodationType = vCurrObj.AccommodationType Then
								vRRRow.AccommodationType = vObject.AccommodationType;
							ElsIf ValueIsFilled(vOldCurrObjAccommodationType) And vCORRRow.AccommodationType = vOldCurrObjAccommodationType Then
								vRRRow.AccommodationType = vObject.Ref.AccommodationType;
							EndIf;
						EndIf;
						If ValueIsFilled(vCORRRow.Room) Then
							vRRRow.Room = vCORRRow.Room;
							vRRRow.RoomType = vCORRRow.RoomType;
						EndIf;
						If Not IsBlankString(vCORRRow.AgentCommission) Then
							vRRRow.AgentCommission = vCORRRow.AgentCommission;
						EndIf;
						If Not IsBlankString(vCORRRow.Discount) Then
							vRRRow.Discount = vCORRRow.Discount;
						EndIf;
						If ValueIsFilled(vCORRRow.PriceCalculationDate) Then
							vRRRow.PriceCalculationDate = vCORRRow.PriceCalculationDate;
						EndIf;
						If ValueIsFilled(vCORRRow.ClientType) Then
							vRRRow.ClientType = vCORRRow.ClientType;
						EndIf;
						If ValueIsFilled(vCORRRow.BoardPlace) Then
							vRRRow.BoardPlace = vCORRRow.BoardPlace;
						EndIf;
						If ValueIsFilled(vCORRRow.MarketingCode) Then
							vRRRow.MarketingCode = vCORRRow.MarketingCode;
						EndIf;
						If ValueIsFilled(vCORRRow.SourceOfBusiness) Then
							vRRRow.SourceOfBusiness = vCORRRow.SourceOfBusiness;
						EndIf;
						If ValueIsFilled(vCORRRow.ServicePackage) Then
							vRRRow.ServicePackage = vCORRRow.ServicePackage;
						EndIf;
						vRRRow.DoNotChangeAvailability = vCORRRow.DoNotChangeAvailability;
						vRRRow.IsBookedOut = vCORRRow.IsBookedOut;
						vRRRow.BookOutHotel = vCORRRow.BookOutHotel;
						vRRRow.BookOutPrice = vCORRRow.BookOutPrice;
						vRRRow.BookOutPriceCurrency = vCORRRow.BookOutPriceCurrency;
					EndDo;
					// Reservation
					If ValueIsFilled(vObject.ParentDoc) Then
						vParentDoc = vObject.ParentDoc;
						If vObject.IsNew() And ValueIsFilled(vObject.AccommodationType) And 
						   vObject.AccommodationType = vParentDoc.AccommodationType Then
							// Client type
							vObject.ClientType = vParentDoc.ClientType;
							vObject.ClientTypeConfirmationText = vParentDoc.ClientTypeConfirmationText;
							// Board place
							vObject.BoardPlace = vParentDoc.BoardPlace;
							// Room rates
							For Each vPDRRRow In vParentDoc.RoomRates Do
								vRRRow = vObject.RoomRates.Find(vPDRRRow.AccountingDate, "AccountingDate");
								If vRRRow = Undefined Then
									vRRRow = vObject.RoomRates.Add();
									vRRRow.AccountingDate = vPDRRRow.AccountingDate;
									vRRRow.ChangeTime = vPDRRRow.ChangeTime;
								EndIf;
								If Not ValueIsFilled(vRRRow.RoomRate) And ValueIsFilled(vPDRRRow.RoomRate) Then
									vRRRow.RoomRate = vPDRRRow.RoomRate;
								EndIf;
								If Not ValueIsFilled(vRRRow.AccommodationType) And ValueIsFilled(vPDRRRow.AccommodationType) Then
									vRRRow.AccommodationType = vPDRRRow.AccommodationType;
								EndIf;
								If Not ValueIsFilled(vRRRow.AccommodationTemplate) And ValueIsFilled(vPDRRRow.AccommodationTemplate) Then
									vRRRow.AccommodationTemplate = vPDRRRow.AccommodationTemplate;
									vRRRow.NumberOfAdults = vPDRRRow.NumberOfAdults;
									vRRRow.NumberOfTeenagers = vPDRRRow.NumberOfTeenagers;
									vRRRow.NumberOfChildren = vPDRRRow.NumberOfChildren;
									vRRRow.NumberOfInfants = vPDRRRow.NumberOfInfants;
								EndIf;
								If Not ValueIsFilled(vRRRow.Room) And ValueIsFilled(vPDRRRow.Room) Then
									vRRRow.Room = vPDRRRow.Room;
									vRRRow.RoomType = vPDRRRow.RoomType;
									vRRRow.ChangeTime = vPDRRRow.ChangeTime;
								EndIf;
								If IsBlankString(vRRRow.AgentCommission) And Not IsBlankString(vPDRRRow.AgentCommission) Then
									vRRRow.AgentCommission = vPDRRRow.AgentCommission;
								EndIf;
								If IsBlankString(vRRRow.Discount) And Not IsBlankString(vPDRRRow.Discount) Then
									vRRRow.Discount = vPDRRRow.Discount;
								EndIf;
								If ValueIsFilled(vPDRRRow.PriceCalculationDate) Then
									vRRRow.PriceCalculationDate = vPDRRRow.PriceCalculationDate;
								EndIf;
								If ValueIsFilled(vPDRRRow.ClientType) Then
									vRRRow.ClientType = vPDRRRow.ClientType;
								EndIf;
								If ValueIsFilled(vPDRRRow.BoardPlace) Then
									vRRRow.BoardPlace = vPDRRRow.BoardPlace;
								EndIf;
								If ValueIsFilled(vPDRRRow.MarketingCode) Then
									vRRRow.MarketingCode = vPDRRRow.MarketingCode;
								EndIf;
								If ValueIsFilled(vPDRRRow.SourceOfBusiness) Then
									vRRRow.SourceOfBusiness = vPDRRRow.SourceOfBusiness;
								EndIf;
								If ValueIsFilled(vPDRRRow.ServicePackage) Then
									vRRRow.ServicePackage = vPDRRRow.ServicePackage;
								EndIf;
								vRRRow.DoNotChangeAvailability = vPDRRRow.DoNotChangeAvailability;
								vRRRow.IsBookedOut = vPDRRRow.IsBookedOut;
								vRRRow.BookOutHotel = vPDRRRow.BookOutHotel;
								vRRRow.BookOutPrice = vPDRRRow.BookOutPrice;
								vRRRow.BookOutPriceCurrency = vPDRRRow.BookOutPriceCurrency;
							EndDo;
							// Load manual prices
							If IsManualRoomPrice <> 1 And IsManualRoomPrice <> 3 Then
								If vObject.ParentDoc.Prices.Count() > 0 Then
									CopyPrices(vObject.Prices, vObject.ParentDoc.Prices);
								EndIf;
							EndIf;
							// Load services
							If vObject.ParentDoc.RoomRate = vObject.RoomRate Then
								vObject.Services.Load(vObject.ParentDoc.Services.Unload(New Structure("IsManual", False)));
							EndIf;
							// Load occupation percents
							vObject.OccupationPercents.Load(vObject.ParentDoc.OccupationPercents.Unload());
							If TypeOf(vObject.ParentDoc) <> Type("DocumentRef.Accommodation") Then
								// Load manual services
								vObject.pmLoadManualServicesFromParentDoc(vObject.ParentDoc);
								// Load service packages
								If vObject.IsNew() Then
									vObject.ServicePackages.Load(vObject.ParentDoc.ServicePackages.Unload());
								EndIf;
							EndIf;
							// External system code
							vObject.ExternalCode = vParentDoc.ExternalCode;
						EndIf;
					EndIf;
					// Also copy discounts from the current or base document
					If vObject.IsNew() And ValueIsFilled(vObject.ParentDoc) And vObject.ParentDoc <> vCurrObj.Ref And 
					   ValueIsFilled(vCurrObj.ParentDoc) And vCurrObj.Discount = vCurrObj.ParentDoc.Discount Then
						vParentDocRef = vObject.ParentDoc;
						vObject.Discount = vParentDocRef.Discount;
						vObject.DiscountSum = vParentDocRef.DiscountSum;
						vObject.DiscountType = vParentDocRef.DiscountType;
						vObject.DiscountConfirmationText = vParentDocRef.DiscountConfirmationText;
						vObject.DiscountServiceGroup = vParentDocRef.DiscountServiceGroup;
						vObject.DiscountCard = vParentDocRef.DiscountCard;
						vObject.TurnOffAutomaticDiscounts = vParentDocRef.TurnOffAutomaticDiscounts;
					Else
						vCopyDiscounts = True;
						If ValueIsFilled(vCurrObj.DiscountType) Then
							If vCurrObj.DiscountType.IsPersonalDiscount Then
								vCopyDiscounts = False;
							ElsIf vCurrObj.DiscountType.IsAmountDiscount And 
								(vObject.RoomRate <> vCurrObj.RoomRate Or vObject.RoomType <> vCurrObj.RoomType Or vObject.AccommodationType <> vCurrObj.AccommodationType) Then
								vCopyDiscounts = False;
							EndIf;
						EndIf;
						If vCopyDiscounts Then
							vObject.Discount = vCurrObj.Discount;
							vObject.DiscountSum = vCurrObj.DiscountSum;
							vObject.DiscountType = vCurrObj.DiscountType;
							vObject.DiscountConfirmationText = vCurrObj.DiscountConfirmationText;
							vObject.DiscountServiceGroup = vCurrObj.DiscountServiceGroup;
							vObject.DiscountCard = vCurrObj.DiscountCard;
							vObject.TurnOffAutomaticDiscounts = vCurrObj.TurnOffAutomaticDiscounts;
						Else
							vObject.Discount = 0;
							vObject.DiscountSum = 0;
							vObject.DiscountType = Catalogs.DiscountTypes.EmptyRef();
							vObject.DiscountConfirmationText = "";
							vObject.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
							vObject.DiscountCard = Catalogs.DiscountCards.EmptyRef();
							vObject.pmSetDiscounts();
						EndIf;
					EndIf;
					// Remove some changes if necessary
					vBaseRef = vObjectRef;
					If Not ValueIsFilled(vObjectRef) Then
						vBaseRef = vObjectReservation;
					EndIf;
					If ValueIsFilled(vBaseRef) And Not vObject.IsNew() Then
						If ValueIsFilled(vObjectRef) Then
							If vRow.CheckInDateIsDifferent Then
								vObject.CheckInDate = vObjectRef.CheckInDate;
								vObject.Duration = vObjectRef.Duration;
							EndIf;
						EndIf;
						If vRow.CheckOutDateIsDifferent Then
							vObject.CheckOutDate = vBaseRef.CheckOutDate;
							vObject.Duration = vObject.pmCalculateDuration();
						EndIf;
						If vRow.RoomRateIsDifferent Then
							vObject.RoomRate = vBaseRef.RoomRate;
							vObject.PriceCalculationDate = vBaseRef.PriceCalculationDate;
							If ValueIsFilled(vObject.RoomRate) Then
								vObject.RoomRateType = vObject.RoomRate.RoomRateType;
							EndIf;
						Else
							vObject.PriceCalculationDate = vCurrObj.PriceCalculationDate;
						EndIf;
						If vRow.ClientTypeIsDifferent Then
							vObject.ClientType = vBaseRef.ClientType;
						EndIf;
						If vRow.BoardPlaceIsDifferent Then
							vObject.BoardPlace = vBaseRef.BoardPlace;
						EndIf;
						If vRow.DiscountsAreDifferent Then
							vObject.DiscountCard = vBaseRef.DiscountCard;
							vObject.DiscountType = vBaseRef.DiscountType;
							vObject.Discount = vBaseRef.Discount;
							vObject.DiscountConfirmationText = vBaseRef.DiscountConfirmationText;
							vObject.DiscountServiceGroup = vBaseRef.DiscountServiceGroup;
							vObject.DiscountSum = vBaseRef.DiscountSum;
							vObject.TurnOffAutomaticDiscounts = vBaseRef.TurnOffAutomaticDiscounts;
						EndIf;
						If vRow.ManualPricesAreDifferent Then
							CopyPrices(vObject.Prices, vBaseRef.Prices);
						EndIf;
						If vRow.ServicePackagesAreDifferent Then
							vObject.ServicePackage = vBaseRef.ServicePackage;
							vObject.ServicePackages.Load(vBaseRef.ServicePackages.Unload());
						EndIf;
						If vRow.RoomRatesAreDifferent Or vRow.CheckInDateIsDifferent Or vRow.CheckOutDateIsDifferent Then
							For Each vBaseRRRow In vBaseRef.RoomRates Do
								If ValueIsFilled(vBaseRRRow.AccountingDate) Then
									If vBaseRRRow.AccountingDate < BegOfDay(vCurrObj.CheckInDate) And vBaseRRRow.AccountingDate >= BegOfDay(vObject.CheckInDate) Or 
									   vBaseRRRow.AccountingDate >= BegOfDay(vCurrObj.CheckOutDate) And vBaseRRRow.AccountingDate <= BegOfDay(vObject.CheckOutDate) Then
										vRRRow = vObject.RoomRates.Insert(0);
										FillPropertyValues(vRRRow, vBaseRRRow);
									Else
										vRRRow = vObject.RoomRates.Find(vBaseRRRow.AccountingDate, "AccountingDate");
										If vRRRow = Undefined Then
											vRRRow = vObject.RoomRates.Add();
											vRRRow.AccountingDate = vBaseRRRow.AccountingDate;
											vRRRow.ChangeTime = vBaseRRRow.ChangeTime;
										EndIf;
										If vRow.RoomRatesAreDifferent Then
											vRRRow.RoomRate = vBaseRRRow.RoomRate;
											vRRRow.AccommodationType = vBaseRRRow.AccommodationType;
											vRRRow.AccommodationTemplate = vBaseRRRow.AccommodationTemplate;
											vRRRow.NumberOfAdults = vBaseRRRow.NumberOfAdults;
											vRRRow.NumberOfTeenagers = vBaseRRRow.NumberOfTeenagers;
											vRRRow.NumberOfChildren = vBaseRRRow.NumberOfChildren;
											vRRRow.NumberOfInfants = vBaseRRRow.NumberOfInfants;
											vRRRow.PriceCalculationDate = vBaseRRRow.PriceCalculationDate;
										EndIf;
									EndIf;
								EndIf;
							EndDo;
							vObject.RoomRates.Sort("AccountingDate, ChangeTime");
						EndIf;
					Else
						vObject.PriceCalculationDate = vCurrObj.PriceCalculationDate;
					EndIf;
					// Synchronize room rates and document attributes
					vObject.RoomRates.Sort("AccountingDate Desc");
					For Each vRRRow In vObject.RoomRates Do
						vLastRoomRate = vRRRow.RoomRate;
						vLastAccommodationType = vRRRow.AccommodationType;
						vLastRoom = vRRRow.Room;
						vLastRoomType = vRRRow.RoomType;
						If vRRRow.AccountingDate <= BegOfDay(CurrentSessionDate()) Then
							If ValueIsFilled(vLastRoomRate) And vLastRoomRate <> vObject.RoomRate Then
								vObject.RoomRate = vLastRoomRate;
								If ValueIsFilled(vObject.RoomRate) Then
									vObject.RoomRateType = vObject.RoomRate.RoomRateType;
								EndIf;
							EndIf;
							If ValueIsFilled(vLastAccommodationType) And vLastAccommodationType <> vObject.AccommodationType Then
								vObject.AccommodationType = vLastAccommodationType;
							EndIf;
							If ValueIsFilled(vLastRoom) And vLastRoom <> vObject.Room Then
								vObject.Room = vLastRoom;
								vObject.RoomType = vLastRoomType;
							EndIf;
							Break;
						EndIf;
					EndDo;
					vObject.RoomRates.Sort("AccountingDate, ChangeTime");
					// Vaucher type
					vObject.HotelProduct = vRow.HotelProduct;
					If Not ValueIsFilled(vObject.HotelProduct) Or ValueIsFilled(vObject.HotelProduct) And vObject.HotelProduct.IsFolder Then
						If ValueIsFilled(vObject.RoomRate.HotelProductType) And vObject.RoomRate.HotelProductType <> vObject.HotelProduct Then
							vObject.HotelProduct = vObject.RoomRate.HotelProductType;
						EndIf;
					EndIf;
					// Process master charging rules	
					vObject.pmRemoveIsMasterChargingRules();
					// Recalculate bound attributes
					vObject.pmCalculateResources();
					// Price calculation date reset
					If vRow.PriceCalculationDateShouldBeUpdated Then
						vObject.PriceCalculationDate = vCurrObj.PriceCalculationDate;
					EndIf;
					// Default customer
					If Not ValueIsFilled(vObject.Customer) And ValueIsFilled(vObject.Guest) And Not ValueIsFilled(vObject.Reservation) And  
					   vObject.IsForFolioSplit And ValueIsFilled(vObject.Company) And vObject.Company.CreateIndividualsCustomerForEachClient Then
						vObject.Customer = CreateCustomerFromGuest(vObject.Guest);
						CustomerOnChangeAtServer(vObject);
					Else
						// Calculate services
						vObject.pmCalculateServices( , , , , , vObject.IsForFolioSplit, , ?(OneGuestMode, Undefined, vCurrObj.AccommodationTemplate));
					EndIf;
					// Load manual prices
					If vObject.IsNew() Then
						If ValueIsFilled(vObject.ParentDoc) Then
							If vObject.AccommodationType = vObject.ParentDoc.AccommodationType And vObject.RoomType = vObject.ParentDoc.RoomType Then
								vObject.pmLoadManualPricesFromParentDoc(vObject.ParentDoc);
							EndIf;
						EndIf;
						If vObject.AccommodationType = vCurrObj.AccommodationType And vObject.RoomType = vCurrObj.RoomType Then
							vObject.pmLoadManualPricesFromParentDoc(vCurrObj.Ref);
						EndIf;
					EndIf;
					// Set planned payment method
					vObject.pmSetPlannedPaymentMethod();
					// Document auto time
					vObject.SetTime(AutoTimeMode.CurrentOrLast);
					// Merge documents from one room 
					If vObject.NumberOfPersons = 1 Then
						If ValueIsFilled(vCurrObj.Ref) And ValueIsFilled(vCurrObj.Room) Then
							If vObject.Room = vCurrObj.Room And ValueIsFilled(vObject.AccommodationType) And vObject.AccommodationType.Type <> Enums.AccomodationTypes.Beds Then
								// Set date and time
								vObject.SetTime(AutoTimeMode.DontUse);
								vObject.Date = vCurrObj.Date + 1;
							EndIf;
						EndIf;
					EndIf;
					// Posting
					vObject.AdditionalProperties.Insert("DoNotCloseMode", pDoNotCloseMode);
					
					vObject.AdditionalProperties.Insert("AddRoomsToAllotment", rAddRoomsToAllotment);
					vObject.AdditionalProperties.Insert("AllotmentBalances", rAllotmentBalances);
					
					vObject.Write(?(pWriteMode = Undefined, DocumentWriteMode.Posting, pWriteMode));
					// Save data to the document history
					If pWriteMode <> DocumentWriteMode.Write Then
						vObject.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					EndIf;

					If vObject.AdditionalProperties.Property("AddRoomsToAllotment") And vObject.AdditionalProperties.AddRoomsToAllotment Then
						rAddRoomsToAllotment = True;
					EndIf;
					If vObject.AdditionalProperties.Property("AllotmentBalances") And TypeOf(vObject.AdditionalProperties.AllotmentBalances) = Type("Array") Then
						rAllotmentBalances = vObject.AdditionalProperties.AllotmentBalances;
					EndIf;
					
					// Check should we reassign room services and phone calls to this guest
					cmCheckMissedRoomServices(vObject.Ref);
					UserWorkHistory.Add(vObject.Ref);
					// Save object reference
					vNewRef = vGuestsRefTable.Add();
					vNewRef.Ref = vObject.Ref;
					vNewRef.Row = vRow;
					// Save reference to the guests in group value table row
					vRow.Ref = vObject.Ref;
					vRow.GuestRef = vObject.Guest;
					// Clear flag that we should reset price calculation date
					vRow.PriceCalculationDateShouldBeUpdated = False;
				EndIf;
			ElsIf ValueIsFilled(vRow.Ref) And vRow.Ref.Posted And vRow.IsAnnulation	And ValueIsFilled(vRow.AccommodationStatus) Then
				vObjectRef = vRow.Ref;
				vObject = vObjectRef.GetObject();
				vObject.AccommodationStatus = vRow.AccommodationStatus;
				// Posting
				vObject.AdditionalProperties.Insert("DoNotCloseMode", pDoNotCloseMode);
				vObject.Write(?(pWriteMode = Undefined, DocumentWriteMode.Posting, pWriteMode));
				// Save data to the document history
				If pWriteMode <> DocumentWriteMode.Write Then
					vObject.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
		// Commit transaction
		CommitTransaction();
		// Enable check-out button
		Items.FormCheckOut.Enabled = True;
		// Fill guests in group value table
		ValueToFormAttribute(vGuestsInGroup, "GuestsInGroup");
		// Update guests availability
		Try
			vIndex = 1;
			For Each vRow In vGuestsInGroup Do
				If ValueIsFilled(vRow.GuestRef) Then
					Items["SelGuest"+String(vIndex)].TextEdit = False;
				Else
					Items["SelGuest"+String(vIndex)].TextEdit = True;
				EndIf;
				vIndex = vIndex + 1;
			EndDo;
		Except
		EndTry;
	Except
		vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
		If IsBlankString(vErrorDescription) Then
			vErrorDescription = "Error";
		EndIf;
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Return vErrorDescription;
	EndTry;
	vAccommodationArray = New Array;
	vAccommodationArray.Add(vCurrObj.Ref);
	For Each vRow in vGuestsRefTable Do
		vRow.Row.Ref = vRow.Ref;
		vAccommodationArray.Add(vRow.Ref);
	EndDo;
	If ThisObject.Modified Then   
		WasChanged = True;
		If pWriteMode <> DocumentWriteMode.Write Then
			ThisObject.Modified = False;
		EndIf;
		NeedServicesRecalculation = False;
	EndIf;
	If Not vUseParametrObject Then
		// Set object value
		vCurrObj.Read();
		ValueToFormAttribute(vCurrObj, "Object");
	EndIf;
	// Hotel365
	vFrmAction = Catalogs.ObjectFormActions.AccommodationSendWelcomeSMS;
	If Not WasPosted And CheckForSentSMS() And vFrmAction.IsActive And vFrmAction.AutomaticallyRunOnFirstObjectWrite And vFrmAction.ObjectType = Documents.Accommodation.EmptyRef() Then
		vSMSWarning = SendWelcomeSMSAtServer();
		rWarning = rWarning + ?(IsBlankString(rWarning), "", Chars.LF) + vSMSWarning;
	EndIf;
	// Was posted
	WasPosted = True;  
	// Calculate totals
	If pDoNotCloseMode Then
		TotalSum = CalculateTotalServices(, False, False, False, True);
	EndIf;
	// Return
	Return "";
EndFunction // WriteAtServer

// ----------------------------------------------------------------------------
// 
// Returns:
//  Boolean - necessity to send SMS
//
&AtServer
Function CheckForSentSMS()
	vSendSMS = False;
	
	vExtSys = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(Object.Hotel);
	If ValueIsFilled(vExtSys) And vExtSys.IsActive Then
		vQuery = New Query;
		vQuery.Text = 
			"SELECT
			|	SMSMessagesSliceLast.MessageID AS MessageID
			|FROM
			|	InformationRegister.SMSMessages.SliceLast(
			|			,
			|			ClientDoc.Number = &qClientDocNumber
			|				AND CASE
			|					WHEN &qTemplateIsFilled
			|						THEN SMSTemplate = &qSMSTemplate
			|				END) AS SMSMessagesSliceLast";
		
		vQuery.SetParameter("qClientDocNumber", Object.Number);
		vQuery.SetParameter("qTemplateIsFilled", ValueIsFilled(vExtSys.SMSTemplate));
		vQuery.SetParameter("qSMSTemplate", vExtSys.SMSTemplate);
		
		vQueryResult = vQuery.Execute();
		
		If vQueryResult.IsEmpty() Then
			vSendSMS = True;
		EndIf;
	EndIf;
	
	Return vSendSMS;
EndFunction // CheckForSentSMS

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose_AfterAnswering(pAnswer, pCancel) Export
	pCancel = False;
	vCancel = Undefined;
	If pAnswer <> Undefined Then
		If pAnswer = DialogReturnCode.Yes Then
			// Check attributes
			If Not CheckAttributes() Then
				pCancel = True;
				IsInBeforeCloseEvent = False;
				Return;
			EndIf;
			// Check user PIN if necessary
			If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
				OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "BeforeClose_AfterAnswering"), ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
				Return;
			EndIf;
			EmployeePINCodeChecked = False;
			// Save document
			vWarning = "";
			vAddRoomsToAllotment = False;
			vAllotmentBalances = Undefined;
			vResult = WriteAtServer(, vWarning, True, , vAddRoomsToAllotment, vAllotmentBalances);
			If Not IsBlankString(vWarning) Then
				If ValueIsFilled(vResult) Then
					tcCommonFunctionOnClientServer.UserMessage(vWarning);
				Else
					ShowMessageBox(, vWarning);
				EndIf;
			EndIf;
			vBreakProcessing = False;
			If ValueIsFilled(vResult) Then
				If vResult <> "Error" Then
					tcCommonFunctionOnClientServer.UserMessage(NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
				Else
					tcCommonFunctionOnClientServer.UserMessage(NStr("en='Documents posting error!';ru='Ошибка проводки документа!';de='Fehler bei der Durchführung des Dokuments!'"));
				EndIf;
				pCancel = True;
				IsInBeforeCloseEvent = False;
				vBreakProcessing = True;
			Else
				// Notify changes
				IsOnCloseForm = True;
				Notify("Subsystem.Accounts.Changed", Object.Ref, ThisObject);
				Notify("Document.Accommodation.Write", Object.Ref, ThisObject);
				If GuestsToCheckInList.Count()>0 Then
					Notify("CheckIn", Object.Ref, ThisObject);
				EndIf;
			EndIf;
		 	If vAddRoomsToAllotment Then
				ShowQueryBox(New NotifyDescription("AddRoomsToAllotment", ThisObject, New Structure("AllotmentBalances", vAllotmentBalances)), 
							 NStr("en='Add missing rooms to the allotment?'; ru='Добавить недостающие номера в квоту?'; de='Fehlende Zimmer zum Allotment hinzufügen?'"), 
							 QuestionDialogMode.YesNo, , DialogReturnCode.No);
			EndIf;
			If vBreakProcessing Then
				Return;
			EndIf;
		ElsIf pAnswer = DialogReturnCode.No Then
			vCancel = BeforeCloseAtServer(); 
		ElsIf pAnswer = DialogReturnCode.Cancel Then
			pCancel = True;
			IsInBeforeCloseEvent = False;
			Return;
		EndIf;
	Else
		vCancel = BeforeCloseAtServer(); 
	EndIf;
	If vCancel <> "Error" And vCancel <> "LockError" Then
		ThisObject.Modified = False;
		If vCancel <> Undefined Then
			If Not vCancel And Not WasAlreadyPrint And WasPosted And WasNew Then
				vPrintFormsList = PerformAutomaticPrinting();
				For Each vFormType In vPrintFormsList Do
					vExternalProcessing = Undefined;
					If ValueIsFilled(vFormType.Value) Then
						vExternalProcessing = tcOnServer.cmGetAttributeByRef(vFormType.Value, "ExternalProcessing");
					EndIf;
					If ValueIsFilled(vExternalProcessing) Then
						Try
							OpenExternalProcedureForm(vExternalProcessing, vFormType.Value);
						Except
							tcCommonFunctionOnClientServer.UserMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"));
							vExternalProcessing = Undefined;
						EndTry;
						Continue;
					EndIf;
					If ValueIsFilled(vFormType.Presentation) Then
						If vFormType.Presentation = "AccommodationPrintGuestForm2Forms5" 
							Or vFormType.Presentation = "AccommodationPrintGuestFormFreeForm" 
							Or vFormType.Presentation = "AccommodationPrintGuestRegistrationForm" Then
							PrintGuestForm(vFormType.Presentation);
						ElsIf vFormType.Presentation = "AccommodationPrintGuestsForms2Forms5" 
							Or vFormType.Presentation = "AccommodationPrintGuestsFormsFreeForm" 
							Or vFormType.Presentation = "AccommodationPrintGuestRegistrationForms" Then
							PrintGuestsForms(vFormType.Presentation)
						ElsIf vFormType.Presentation = "AccommodationPrintGuestPersonalDataProcessingConsent" Then
							PrintGuestPersonalDataProcessingConsent();
						ElsIf vFormType.Presentation = "AccommodationPrintGuestRefusalToPayResortFee" Then
							PrintGuestRefusalToPayResortFee();
						ElsIf vFormType.Presentation = "AccommodationPrintDepartureNotificationForm" Then
							PrintGuestDepartureNotificationForm(vFormType.Presentation);
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		If pAnswer <> Undefined Then
			ThisObject.Close();
		EndIf;
	Else
		If vCancel <> "LockError" Then
			pCancel = True;
		Else
			If IsInBeforeCloseEvent Then
				If ThisObject.IsOpen() Then
					ThisObject.Modified = False;
					ThisObject.Close();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	IsInBeforeCloseEvent = False;
	If Not pCancel Then
		WasNew = False;
	EndIf;
EndProcedure // BeforeClose_AfterAnswering

// -----------------------------------------------------------------------------
&AtServer
Function BeforeCloseAtServer()
	vCancel = Undefined;
	Try
		vObj = FormAttributeToValue("Object");
	Except
		Return "LockError";
	EndTry; 
	If SavedButNotPostedWhileOpen Then
		vRefs = New Array();
		vRefs.Add(Object.Ref);
		For Each vRow In GuestsInGroup Do
			If ValueIsFilled(vRow.Ref) Then
				vRefs.Add(vRow.Ref);
			EndIf;
		EndDo;
		If RollBackMainDocumentToTheLastPostedState(vRefs) Then
			Return "Error";
		Else
			SavedButNotPostedWhileOpen = False;
		EndIf;
	EndIf;
	cmUpdateChargingRulesFoliosLineNumbers(vObj.ChargingRules);
	If WasNew Then 
		If Not WasPosted Then
			// Delete folios used by this document
			If vCancel = Undefined Then
				// If folio left in the list do not have any transactions based on it then delete it
				vObj.pmDeleteUnusedChargingRuleFolios();
				For Each vRes In GuestsInGroup Do
					If ValueIsFilled(vRes.Ref) Then
						vResObj = vRes.Ref.GetObject();
						vResObj.pmDeleteUnusedChargingRuleFolios();
					EndIf;
				EndDo;
				// Update charging rule folios to restore it's parent doc
				If ValueIsFilled(vObj.ParentDoc) Then
					If TypeOf(vObj.ParentDoc) = Type("DocumentRef.Reservation") Then
						For Each vCRRow In vObj.ChargingRules Do
							If ValueIsFilled(vCRRow.ChargingFolio) Then
								vChargingFolio = vCRRow.ChargingFolio;
								vParentDoc = vChargingFolio.ParentDoc;
								If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") And Not ValueIsFilled(vParentDoc.DataVersion) Then
									vChargingFolioObj = vChargingFolio.GetObject();
									vChargingFolioObj.ParentDoc = vObj.ParentDoc;
									vChargingFolioObj.Write(DocumentWriteMode.Write);
								EndIf;
							EndIf;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	vCancel = False;
	// Return
	Return vCancel;
EndFunction // BeforeCloseAtServer

// -----------------------------------------------------------------------------
&AtServer
Function PerformAutomaticPrinting()
	vDocObj = FormAttributeToValue("Object");
	vPrintFormsList = New ValueList;
	// Get language
	vLanguage = vDocObj.pmGetDocumentLanguage();
	// Get list of automatic print froms for this object type
	vForms = cmGetObjectPrintingForms(Documents.Accommodation.EmptyRef(), vLanguage);
	vAutoForms = vForms.FindRows(New Structure("AutomaticallyPrintOnFirstObjectWrite", True));
	// Call object print forms handler for each form
	For Each vAutoForm In vAutoForms Do
		If vAutoForm.ObjectPrintingForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestForm2Forms5 Or 
		   vAutoForm.ObjectPrintingForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestsForms2Forms5 Or 
		   vAutoForm.ObjectPrintingForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestsFormsFreeForm Or
		   vAutoForm.ObjectPrintingForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestRegistrationForms Or
		   Find(Upper(vAutoForm.ObjectPrintingForm.Parameter), "GUEST_GROUP_FORM") > 0 Then
		    vGroupPrintingForms = FormAttributeToValue("GroupPrintingForms");
		    vAlreadyProcessedGroupForms = vGroupPrintingForms.FindRows(New Structure("ObjectPrintingForm, GuestGroup", vAutoForm.ObjectPrintingForm, vDocObj.GuestGroup)); 
			If vAlreadyProcessedGroupForms.Count() > 0 Then
				Continue;   
			EndIf;
			vAlreadyProcessedGroupForm = vGroupPrintingForms.Add();
			vAlreadyProcessedGroupForm.ObjectPrintingForm = vAutoForm.ObjectPrintingForm;
			vAlreadyProcessedGroupForm.GuestGroup = vDocObj.GuestGroup;
			ValueToFormAttribute(vGroupPrintingForms, "GroupPrintingForms");
		EndIf;
		vTypeOfPrintForm = GetTypeOfPrintFormOnClose(vAutoForm.ObjectPrintingForm, vDocObj);
		vPrintFormsList.Add(vAutoForm.ObjectPrintingForm, vTypeOfPrintForm);
	EndDo;
	// Return
	Return vPrintFormsList;
EndFunction // PerformAutomaticPrinting

// -----------------------------------------------------------------------------
&AtServer
Function GetTypeOfPrintFormOnClose(pForm, pDocObj = Undefined)
	vTypeOfPrintForm = "";
	// Check predefined forms
	If pForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestForm2Forms5 Then
		vTypeOfPrintForm = "AccommodationPrintGuestForm2Forms5";
		PrintFormTypeRefOnClose = pForm;
	ElsIf pForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestFormFreeForm Then
		vTypeOfPrintForm = "AccommodationPrintGuestFormFreeForm";
		PrintFormTypeRefOnClose = pForm;
	ElsIf pForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestsForms2Forms5 Then
		vTypeOfPrintForm = "AccommodationPrintGuestsForms2Forms5";
		PrintFormTypeRefOnClose = pForm;
	ElsIf pForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestsFormsFreeForm Then
		vTypeOfPrintForm = "AccommodationPrintGuestsFormsFreeForm";
		PrintFormTypeRefOnClose = pForm;
	ElsIf pForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestRegistrationForm Then
		vTypeOfPrintForm = "AccommodationPrintGuestRegistrationForm";
		PrintFormTypeRefOnClose = pForm;
	ElsIf pForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestRegistrationForms Then
		vTypeOfPrintForm = "AccommodationPrintGuestRegistrationForms";
		PrintFormTypeRefOnClose = pForm;
	ElsIf pForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestPersonalDataProcessingConsent Then
		vTypeOfPrintForm = "AccommodationPrintGuestPersonalDataProcessingConsent";
		PrintFormTypeRefOnClose = pForm;
	ElsIf pForm = Catalogs.ObjectPrintingForms.AccommodationPrintGuestRefusalToPayResortFee Then
		vTypeOfPrintForm = "AccommodationPrintGuestRefusalToPayResortFee";
		PrintFormTypeRefOnClose = pForm;
	ElsIf pForm = Catalogs.ObjectPrintingForms.AccommodationPrintDepartureNotificationForm Then
		vTypeOfPrintForm = "AccommodationPrintDepartureNotificationForm";
		PrintFormTypeRefOnClose = pForm;
	// Run report
	ElsIf ValueIsFilled(pForm.Report) Then
		If Not cmGenerateReport(pForm.Report, pDocObj.Ref) Then
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Failed to run report!';ru='Не удалось выполнить отчет!';de='Der Bericht konnte nicht ausgeführt werden!'"));
		EndIf;
	Else        
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='No print form processor found!';ru='В настройках печатной формы не задан обработчик!';de='In den Einstellungen der Druckunterlagen wurde kein Bearbeiter vorgegeben!'"));
	EndIf;
	Return vTypeOfPrintForm;
EndFunction // GetTypeOfPrintFormOnClose

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateTotals()
	vObject = FormAttributeToValue("Object");
	// Check room rates plan
	vObject.pmCheckRoomRates();
	// Fill discount type and other discount parameters if filled
	vObject.pmSetDiscounts();
	// Automatic services list calculation	
	vObject.pmCalculateServices( , , , , , vObject.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObject.AccommodationTemplate));
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObject);
	// Value to form attributes
	ValueToFormAttribute(vObject, "Object");
	// Calculate totals
	TotalSum = CalculateTotalServices();
	// Terms choice list
	FillServicePackageChoiceList();
EndProcedure // RecalculateTotals

// -----------------------------------------------------------------------------
&AtClient
Function CheckAttributes()
	#If ThickClientOrdinaryApplication Then
		vCancel = False;
		vMessage = CreateGuestItems();
		If Not IsBlankString(vMessage) Then
			vCancel = True;
			ShowMessageBox(Undefined, vMessage);
			Return Not vCancel;
		EndIf;
		If IsNew And ValueIsFilled(Object.AccommodationStatus) And tcOnServer.cmGetAttributeByRef(Object.AccommodationStatus, "IsActive") Then
			// Check if reservation is checked-in already
			If Not vCancel Then
				If ValueIsFilled(Object.Reservation) Then
					vReservationStatus = tcOnServer.cmGetAttributeByRef(Object.Reservation, "ReservationStatus");
					If vReservationStatus.IsCheckIn Then
						If Not cmCheckUserPermissions("HavePermissionToCheckInBasedOnInactiveReservations") Then
							vCancel = True;
							vMessage = "ru='Процедура заселения уже выполнена!';en='Guest has been already checked-in!';de='Gast wurde bereits eingecheckt!'";
						EndIf;
					ElsIf Not vReservationStatus.IsActive And Not vReservationStatus.IsPreliminary Then
						If Not cmCheckUserPermissions("HavePermissionToCheckInBasedOnInactiveReservations") Then
							vCancel = True;
							vMessage = "ru='Нет прав на заселение по не активной брони!';en='You have no rights to checked-in by inactive reservation!';de='Sie haben kein Recht zum Check-in bei inaktiver Reservierung!'";
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			// Check if client type is entered
			If Not vCancel Then
				If Not cmCheckUserPermissions("HavePermissionToSkipInputOfClientType") Then
					If Not ValueIsFilled(Object.ClientType) Then
						// Ask user to choose client type
						vFrm = Catalogs.ClientTypes.GetChoiceForm();
						vClientType = vFrm.DoModal();
						If vClientType = Undefined Then
							vCancel = True;
							vMessage = "ru='Не указан тип клиента!';en='Client type should be filled!';de='Client type should be filled!'";
						Else
							Object.ClientType = vClientType;
							If Not ValueIsFilled(Object.ClientType) Then
								vCancel = True;
								vMessage = "ru='Не указан тип клиента!';en='Client type should be filled!';de='Client type should be filled!'";
							Else
								// Recalculate totals at server
								RecalculateTotals();
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			// Check if trip purpose is entered
			If Not vCancel Then
				If Not cmCheckUserPermissions("HavePermissionToSkipInputOfGuestTripPurpose") Then
					If Not ValueIsFilled(Object.TripPurpose) Then
						// Ask user to choose trip purpose
						vFrm = Catalogs.TripPurposes.GetChoiceForm();
						vTripPurpose = vFrm.DoModal();
						If vTripPurpose = Undefined Then
							vCancel = True;
							vMessage = "ru='Не указана цель визита гостя!';en='Guest trip purpose should be filled!';de='Guest trip purpose should be filled!'";
						Else
							Object.TripPurpose = vTripPurpose;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			// Check if marketing code is entered
			If Not vCancel Then
				If Not cmCheckUserPermissions("HavePermissionToSkipInputOfAccommodationMarketingCode") Then
					If Not ValueIsFilled(Object.MarketingCode) Then
						// Ask user to choose marketing code
						vFrm = Catalogs.MarketingCodes.GetChoiceForm();
						vMarketingCode = vFrm.DoModal();
						If vMarketingCode = Undefined Then
							vCancel = True;
							vMessage = "ru='Не указано направление маркетинга!';en='Marketing code should be filled!';de='Marketing code should be filled!'";
						Else
							Object.MarketingCode = vMarketingCode;
							If Not ValueIsFilled(Object.MarketingCode) Then
								vCancel = True;
								vMessage = "ru='Не указано направление маркетинга!';en='Marketing code should be filled!';de='Marketing code should be filled!'";
							Else
								// Set room rate type
								If Not ValueIsFilled(Object.RoomRateType) Then
									Object.RoomRateType = tcOnServer.cmGetAttributeByRef(Object.MarketingCode, "RoomRateType");
								EndIf;
								// Recalculate totals at server
								RecalculateTotals();
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			// Check if source of business is entered
			If Not vCancel Then
				If Not cmCheckUserPermissions("HavePermissionToSkipInputOfAccommodationSourceOfBusiness") Then
					If Not ValueIsFilled(Object.SourceOfBusiness) Then
						// Ask user to choose source of business
						vFrm = Catalogs.SourcesOfBusiness.GetChoiceForm();
						vSourceOfBusiness = vFrm.DoModal();
						If vSourceOfBusiness = Undefined Then
							vCancel = True;
							vMessage = "ru='Не указан источник информации о гостинице!';en='Source of business should be filled!';de='Source of business should be filled!'";
						Else
							Object.SourceOfBusiness = vSourceOfBusiness;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// Client decoration
		BuildThisObjectClientDataDecoration();
		// Build commission group hidden title
		BuildCommissionGroupCollapsedTitle();
		// Build accounting group hidden title
		BuildAccountingGroupCollapsedTitle();
		// Build room rate group hidden title
		BuildRoomRateGroupCollapsedTitle();
		// Build discounts group hidden title
		BuildDiscountsGroupCollapsedTitle();
		// Form is modified
		ThisObject.Modified = True;
		If vCancel Then
			If Not IsBlankString(vMessage) Then
				ShowMessageBox(, NStr(vMessage));
			EndIf;
		EndIf;
	#Else
		vCancel = CheckAttributesAtServer();
	#EndIf
	// Check document extra attributes
	If Not vCancel Then
		vCancel = Not CheckFilling();
	EndIf;
	Return Not vCancel;
EndFunction // CheckAttributes

// -----------------------------------------------------------------------------
&AtServer
Function CheckAttributesAtServer()
	vCancel = False;
	vObj = FormAttributeToValue("Object");
	SetObjectAndFormAttributeConformity(vObj, "Object");
	vMessage = CreateGuestItems(vObj);
	If Not IsBlankString(vMessage) Then
		vCancel = True;
		vUM = New UserMessage();
		vUM.SetData(vObj);
		vUM.Field = "Guest";
		vUM.Text = vMessage;
		vUM.Message();
		// Object to form attribute
		ValueToFormAttribute(vObj, "Object");
		Return vCancel;
	EndIf;
	vAttributeInErr = "";
	vCancel	= vObj.pmCheckDocumentAttributes(vObj, vObj.Posted, vMessage, vAttributeInErr, True);
	If vCancel Then
		vUM = New UserMessage();
		vUM.SetData(vObj);
		vUM.Field = vAttributeInErr;
		vUM.Text = NStr(vMessage);
		vUM.Message();
	Else
		If Not tcCommonFunctionOnClientServer.CheckEmail(vObj.EMail) Then
			vCancel = True;
		EndIf;
		If Not tcCommonFunctionOnClientServer.CheckEmail(EMail2) Then
			vCancel = True;
		EndIf;
		If IsNew And ValueIsFilled(vObj.AccommodationStatus) And vObj.AccommodationStatus.IsActive Then
			// Check if reservation is active
			If ValueIsFilled(vObj.Reservation) Then
				vReservationStatus = vObj.Reservation.ReservationStatus;
				If vReservationStatus.IsCheckIn Then
					If Not cmCheckUserPermissions("HavePermissionToCheckInBasedOnInactiveReservations") Then
						vMessage = NStr("ru='Процедура заселения уже выполнена!';en='Guest has been already checked-in!';de='Gast wurde bereits eingecheckt!'");
						vUM = New UserMessage();
						vUM.SetData(vObj);
						vUM.Field = "Reservation";
						vUM.Text = vMessage;
						vUM.Message();
						vCancel = True;
					EndIf;
				ElsIf Not vReservationStatus.IsActive And Not vReservationStatus.IsPreliminary Then
					If Not cmCheckUserPermissions("HavePermissionToCheckInBasedOnInactiveReservations") Then
						vMessage = NStr("ru='Нет прав на заселение по не активной брони!';en='You have no rights to checked-in by inactive reservation!';de='Sie haben kein Recht zum Check-in bei inaktiver Reservierung!'");
						vUM = New UserMessage();
						vUM.SetData(vObj);
						vUM.Field = "Reservation";
						vUM.Text = vMessage;
						vUM.Message();
						vCancel = True;
					EndIf;
				EndIf;
			EndIf;
			// Check if client type is entered
			If Not cmCheckUserPermissions("HavePermissionToSkipInputOfClientType") Then
				If Not ValueIsFilled(vObj.ClientType) Then
					vMessage = NStr("ru='Не указан тип клиента!';en='Client type should be filled!';de='Client type should be filled!'");
					vUM = New UserMessage();
					vUM.SetData(vObj);
					vUM.Field = "ClientType";
					vUM.Text = vMessage;
					vUM.Message();
					vCancel = True;
				EndIf;
			EndIf;
			// Check if trip purpose is entered
			If Not cmCheckUserPermissions("HavePermissionToSkipInputOfGuestTripPurpose") Then
				If Not ValueIsFilled(vObj.TripPurpose) Then
					vMessage = NStr("ru='Не указана цель визита гостя!';en='Guest trip purpose should be filled!';de='Guest trip purpose should be filled!'");
					vUM = New UserMessage();
					vUM.SetData(vObj);
					vUM.Field = "TripPurpose";
					vUM.Text = vMessage;
					vUM.Message();
					vCancel = True;
				EndIf;
			EndIf;
			// Check if marketing code is entered
			If Not cmCheckUserPermissions("HavePermissionToSkipInputOfAccommodationMarketingCode") Then
				If Not ValueIsFilled(vObj.MarketingCode) Then
					vMessage = NStr("ru='Не указано направление маркетинга!';en='Marketing code should be filled!';de='Marketing code should be filled!'");
					vUM = New UserMessage();
					vUM.SetData(vObj);
					vUM.Field = "MarketingCode";
					vUM.Text = vMessage;
					vUM.Message();
					vCancel = True;
				EndIf;
			EndIf;
			// Check if source of business is entered
			If Not cmCheckUserPermissions("HavePermissionToSkipInputOfAccommodationSourceOfBusiness") Then
				If Not ValueIsFilled(vObj.SourceOfBusiness) Then
					vMessage = NStr("ru='Не указан источник информации о гостинице!';en='Source of business should be filled!';de='Source of business should be filled!'");
					vUM = New UserMessage();
					vUM.SetData(vObj);
					vUM.Field = "SourceOfBusiness";
					vUM.Text = vMessage;
					vUM.Message();
					vCancel = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Object to form attribute
	ValueToFormAttribute(vObj, "Object");
	// Client decoration
	BuildThisObjectClientDataDecoration();
	// Build commission group hidden title
	BuildCommissionGroupCollapsedTitle();
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle();
	// Build room rate group hidden title
	BuildRoomRateGroupCollapsedTitle();
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle();
	// Return
	Return vCancel;
EndFunction // CheckAttributesAtServer

// ----------------------------------------------------------------------------
&AtClient
Procedure AddRoomsToAllotment(pUA, pExtraParams) Export
	If pUA = DialogReturnCode.Yes Then
		vMessage = "";
		If AddRoomsToAllotmentAtServer(pExtraParams.AllotmentBalances, vMessage) Then
			ShowMessageBox(, NStr("en='Success! Try to save reservation again...'; ru='Успешно! Попробуйте еще раз сохранить бронь...'; de='Erfolgreich! Versuchen Sie noch einmal, Ihre Reservierung zu speichern...'"));
		Else
			ShowMessageBox(, NStr("en='Failed to add rooms to the allotment! Error is: '; ru='Не удалось добавить номера в квоту! Ошибка: '; de='Zimmer konnten dem Kontingent nicht hinzugefügt werden! Fehler ist: '") + vMessage, , NStr("en='Error!'; ru='Ошибка!'; de='Fehler!'"));
		EndIf;
		Read();
	EndIf;
EndProcedure // AddRoomsToAllotment

// ----------------------------------------------------------------------------
&AtServer
Function AddRoomsToAllotmentAtServer(pAllotmentBalancesArray, rMessage)
	vSuccess = True;
	rMessage = "";
	Try
		BeginTransaction(DataLockControlMode.Managed);
		For Each vAllotmentBalancesStruct In pAllotmentBalancesArray Do
			If vAllotmentBalancesStruct.RoomsRemains < 0 Then
				cmAddRoomsToAllotment(vAllotmentBalancesStruct.RoomQuota, vAllotmentBalancesStruct.RoomRate, vAllotmentBalancesStruct.RoomType, vAllotmentBalancesStruct.PeriodFrom, vAllotmentBalancesStruct.PeriodTo, -vAllotmentBalancesStruct.RoomsRemains);
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		rMessage = cmGetRootErrorDescription(ErrorInfo());
		vSuccess = False;
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	Return vSuccess;
EndFunction // AddRoomsToAllotmentAtServer

// -----------------------------------------------------------------------------
&AtServer
Function RoomOnChangeAtServer(pRecalculateServices = True, pObj = Undefined, pClientTypeIsChanged = False)
	ChangeRoomMessageText = "";
	Items.ChangeRoomMessageTextGroup.Visible = False;
	vRoomPopUpTasksArray = New Array();
	// Check parameters
	If pRecalculateServices = Undefined Then
		pRecalculateServices = True;
	EndIf;
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
    If ValueIsFilled(vObj.Room) Then
		// Retrieve room resources
		vRoomAttrs = vObj.Room.GetObject().pmGetRoomAttributes(cm1SecondShift(vObj.CheckInDate));
		For Each vRoomAttrsRow In vRoomAttrs Do
			// Check if room type was changed
			If vRoomAttrsRow.RoomType <> vObj.RoomType Then
				If ValueIsFilled(vObj.RoomRate) Then
					vRoomRatePriceTagType = vObj.RoomRate.PriceTagType;
					If vRoomRatePriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomType Or 
					   vRoomRatePriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType Then
						ClearOccupationPercentAtServer(CurrentDate(), vObj);
					ElsIf vRoomRatePriceTagType = Enums.PriceTagTypes.ByOccupancyPercentPerRoomClass And ValueIsFilled(vObj.RoomType) And ValueIsFilled(vRoomAttrsRow.RoomType) Then
						vNewRoomTypeClass = vRoomAttrsRow.RoomType.RoomClass;
						vOldRoomTypeClass = vObj.RoomType.RoomClass;
						If vNewRoomTypeClass <> vOldRoomTypeClass Then
							ClearOccupationPercentAtServer(CurrentDate(), vObj);
						EndIf;
					EndIf;
				EndIf;
				vObj.RoomType = vRoomAttrsRow.RoomType;
				If Items.GroupRoomType.Visible Then
					If ValueIsFilled(vObj.RoomType) Then
						WindowView = vObj.RoomType.WindowView;
						RoomTypeClass = vObj.RoomType.RoomClass;
					Else
						WindowView = Undefined;
						RoomTypeClass = Undefined;
					EndIf;
				EndIf;
				RoomTypeOnChangeAtServer(False, False, vObj);
				// Set room type company
				If ValueIsFilled(vObj.RoomType) Then
					vRoomType = vObj.RoomType;
					If ValueIsFilled(vRoomType.Company) Then
						If vObj.Company <> vRoomType.Company And (Not ValueIsFilled(vObj.Contract) OR ValueIsFilled(vObj.Contract) And Not ValueIsFilled(vObj.Contract.Company)) Then
							If CompanyCouldBeChanged(vObj, vObj.AccommodationStatus) Then
								vObj.Company = vRoomType.Company;
							EndIf;
						EndIf;
					EndIf;
				EndIf; 
			EndIf;
			Break;
		EndDo;
		// Check if hotel was changed
		If ValueIsFilled(vObj.RoomType) Then
			If vObj.RoomType.Owner <> vObj.Hotel Then
				vObj.Hotel = vObj.RoomType.Owner;
				vObj.pmProcessHotelChange();
			EndIf;
		EndIf;
		// Set room company
		vRoom = vObj.Room;    
		If ValueIsFilled(vRoom.Company) Then
			If vObj.Company <> vRoom.Company And (Not ValueIsFilled(vObj.Contract) OR ValueIsFilled(vObj.Contract) And Not ValueIsFilled(vObj.Contract.Company)) Then
				If CompanyCouldBeChanged(vObj, vObj.AccommodationStatus) Then
					vObj.Company = vRoom.Company;
				EndIf;
			EndIf;
		EndIf;   
		vObj.BoardPlace = vRoom.BoardPlace;
	EndIf;
	// Calculate resources
	vObj.pmCalculateResources();
	// Check if room was cleared
	If vObj.Posted And Not ValueIsFilled(vObj.Room) And ValueIsFilled(SavRoomType) And SavRoomType = vObj.RoomTypeUpgrade Then
		vObj.RoomType = SavRoomType;
		vObj.RoomTypeUpgrade = Undefined;
		IsManualRoomPrice = 0;
		ManualPriceAppearance(vObj);
		// Process room type change
		RoomTypeOnChangeAtServer(False, False, vObj);
		// Build room rate group hidden title
		BuildRoomRateGroupCollapsedTitle(vObj);
	EndIf;
	// Charging rules
	If ValueIsFilled(vObj.Room) Then
		vObj.pmLoadChargingRules(vObj.Room);
	EndIf;
	// Automatic services list calculation
	If pRecalculateServices Then
		// Calculate totals
		TotalSum = CalculateTotalServices(vObj, , False, False);
	EndIf;
	// Check room choosen
	If ValueIsFilled(vObj.Room) And ValueIsFilled(vObj.RoomType) And ValueIsFilled(vObj.Hotel) And 
	   BegOfDay(CurrentSessionDate()) >= BegOfDay(vObj.CheckInDate) And BegOfDay(CurrentSessionDate()) <= BegOfDay(vObj.CheckOutDate) Then
		// Check stop sale flag
		If vObj.RoomType.StopSale Then
			vRemarks = "";
			If cmIsStopSalePeriod(vObj.RoomType, CurrentSessionDate(), vObj.CheckOutDate, vRemarks) Then
				ChangeRoomMessageText = NStr("en='You have chosen room type with stop sale flag turned on!';ru='Выбрали тип номера снятый с продажи!';de='Sie haben einen Zimmertyp gewählt, der aus dem Angebot genommen wurde!'") + Chars.LF + vRemarks;
				Items.ChangeRoomMessageTextGroup.Visible = True;
				Items.ChangeRoomMessageText.TextColor = WebColors.Red;
			EndIf;
		EndIf;
		If vObj.Room.StopSale Then
			vRemarks = "";
			If cmIsRoomStopSalePeriod(vObj.Room, CurrentSessionDate(), vObj.CheckOutDate, vRemarks) Then
				ChangeRoomMessageText = NStr("en='You have chosen room with stop sale flag turned on!';ru='Выбрали номер снятый с продажи!';de='Sie haben ein Zimmer gewählt, das aus dem Angebot genommen wurde!'") + Chars.LF + vRemarks;
				Items.ChangeRoomMessageTextGroup.Visible = True;
				Items.ChangeRoomMessageText.TextColor = WebColors.Red;
			EndIf;
		EndIf;
		// Check room status and if there are guests in the room
		vOccupiedBeds = 0;
		vOccupiedPersons = 0;
		vRoomPresentation = cmGetRoomPresentation(vObj.Hotel, vObj.Room, CurrentSessionDate(), vOccupiedBeds, vOccupiedPersons, vObj.Number);
		If vOccupiedPersons > 0 Then
			ChangeRoomMessageText = NStr("ru='В выбранном номере есть гости!" + Chars.LF + vRoomPresentation + "'; 
			                             |de='There are guests in the room choosen!" + Chars.LF + vRoomPresentation + "';
			                             |en='There are guests in the room choosen!" + Chars.LF + vRoomPresentation + "'");
			Items.ChangeRoomMessageTextGroup.Visible = True;
			Items.ChangeRoomMessageText.TextColor = WebColors.Red;
		Else
			// Check room status
			vCurRoomStatus = vObj.Room.RoomStatus;
			If vCurRoomStatus <> vObj.Hotel.VacantRoomStatus And
			   Not (ValueIsFilled(vCurRoomStatus) And vCurRoomStatus.RoomIsVacantClear) And
			   vCurRoomStatus <> vObj.Hotel.OccupiedRoomStatus And
			   vCurRoomStatus <> vObj.Hotel.ReservedRoomStatus And
			   vCurRoomStatus <> Catalogs.RoomStatuses.EmptyRef() Then
				ChangeRoomMessageText = NStr("ru='Статус выбранного номера: " + TrimAll(vCurRoomStatus) + "!'; 
				                             |de='Room choosen status is " + TrimAll(vCurRoomStatus) + "!';
				                             |en='Room choosen status is " + TrimAll(vCurRoomStatus) + "!'");
				Items.ChangeRoomMessageTextGroup.Visible = True;
				Items.ChangeRoomMessageText.TextColor = WebColors.Red;
			EndIf;
		EndIf;
	EndIf;
	// Check if this room is in room quota
	If ValueIsFilled(vObj.Room) Then
		If Not ValueIsFilled(vObj.RoomQuota) Then
			vQuotasForRoom = cmGetRoomQuotasForRoom(vObj.Hotel, vObj.RoomType, vObj.Room, vObj.CheckInDate, vObj.CheckOutDate);
			If vQuotasForRoom.Count() > 0 Then
				vQuotasForRoomRow = vQuotasForRoom.Get(0);
				If vQuotasForRoomRow.RoomsInQuota > 0 Or vQuotasForRoomRow.BedsInQuota > 0 Then
					vObj.RoomQuota = vQuotasForRoomRow.RoomQuota;
					RoomQuotaOnChangeAtServer(True, vObj, True);
				EndIf;
			EndIf;
		EndIf;
		// Get room pop up tasks
		If Not IsBlankString(vObj.Room.Remarks) And ValueIsFilled(vObj.Hotel) And vObj.Hotel.ShowRoomRemarksAsPopUpAtRoomSelection Then
			vRoomPopUpTasksArray.Add(TrimAll(vObj.Room.Remarks));
		EndIf;
		vRoomPopUpTasks = cmGetMessagesForObject(vObj.Room, , , , True);
		For Each vRoomPopUpTasksRow In vRoomPopUpTasks Do
			vRoomPopUpTasksArray.Add(vRoomPopUpTasksRow.Remarks);
		EndDo;
	EndIf;
	If vObj.Posted And BegOfDay(CurrentSessionDate()) >= BegOfDay(vObj.CheckInDate) And 
	   ValueIsFilled(vObj.AccommodationStatus) And vObj.AccommodationStatus.IsInHouse Then
		// Do change room
		DoChangeRoom(vObj);
	EndIf;
	If pClientTypeIsChanged Then
		vObj.pmSetDiscounts();
	EndIf;	
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle(vObj);
	// Set room status picture
	SetRoomStatusPictureAtServer(vObj);
	// Set object value
	If vUseParameterObject = False Then	
		ValueToFormAttribute(vObj, "Object");
		// Terms choice list
		FillServicePackageChoiceList();
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
	Return vRoomPopUpTasksArray;
EndFunction // RoomOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SetRoomAttributesExported() Export
	SetRoomAttributesExportedAtServer();
EndProcedure // SetRoomAttributesExported

// -----------------------------------------------------------------------------
&AtServer
Procedure SetRoomAttributesExportedAtServer()
    If ValueIsFilled(Object.Room) Then
		// Retrieve room resources
		vRoomAttrs = Object.Room.GetObject().pmGetRoomAttributes(cm1SecondShift(Object.CheckInDate));
		For Each vRoomAttrsRow In vRoomAttrs Do
			If Items.GroupRoomType.Visible Then
				vRoomType = Object.RoomType;
				If ValueIsFilled(vRoomType) Then
					WindowView = vRoomType.WindowView;
					RoomTypeClass = vRoomType.RoomClass;
				Else
					WindowView = Undefined;
					RoomTypeClass = Undefined;
				EndIf;
			EndIf;
			Break;
		EndDo;
	EndIf;
	// Fill check-in/check-out day of week names
	If ValueIsFilled(Object.CheckInDate) Then
		CheckInDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(Object.CheckInDate)));
	Else
		CheckInDayOfWeek = "";
	EndIf;
	If ValueIsFilled(Object.CheckOutDate) Then
		CheckOutDayOfWeek = Title(cmGetDayOfWeekName(WeekDay(Object.CheckOutDate)));
	Else
		CheckOutDayOfWeek = "";
	EndIf;
EndProcedure // SetRoomAttributesExportedAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetRoomStatusPictureAtServer(pObj)
	If ValueIsFilled(pObj.Room) Then
		Items.RoomStatusIcon.Picture = cmGetRoomStatusIcon(pObj.Room.RoomStatus);
		Items.RoomStatusIcon.ToolTip = TrimAll(pObj.Room.RoomStatus);
	Else
		Items.RoomStatusIcon.Picture = PictureLib.Empty;
		Items.RoomStatusIcon.ToolTip = "";
	EndIf;
EndProcedure // SetRoomStatusPictureAtServer

// -----------------------------------------------------------------------------
&AtServer
Function DoChangeRoom(pObj = Undefined)
	vUseParameterObject = True;
	// Check parameters
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	// Fill default change room date and time
	vChangeRoomDateTime = vObj.CheckInDate;
	vChangeRoomTime = cmExtractTime(vChangeRoomDateTime);
	If BegOfDay(CurrentSessionDate()) > BegOfDay(vObj.CheckOutDate) Then
		vChangeRoomDateTime = vObj.CheckInDate;
		vChangeRoomTime = cmExtractTime(vChangeRoomDateTime);
	ElsIf BegOfDay(CurrentSessionDate()) <> BegOfDay(vObj.CheckInDate) Then
		vChangeRoomDateTime = CurrentSessionDate();
		vChangeRoomTime = cmExtractTime(vChangeRoomDateTime);
		vChangeRoomDateTime = BegOfDay(vChangeRoomDateTime) + (vChangeRoomTime - BegOfDay(vChangeRoomTime));
	EndIf;
	// Update room rates if change room date is not equal to the check-in date
	vObj.pmDoChangeRoom(vChangeRoomDateTime);
	// Calculate totals
	TotalSum = CalculateTotalServices(vObj, , False, False);
	If vUseParameterObject = False Then	
		// Set object value
		ValueToFormAttribute(vObj, "Object");
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
EndFunction // DoChangeRoom

// -----------------------------------------------------------------------------
&AtServer
Function CompanyCouldBeChanged(pObj = Undefined, pAccommodationStatus)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If ValueIsFilled(pAccommodationStatus) And ValueIsFilled(vObj.PlannedPaymentMethod) Then
		If Not vObj.PlannedPaymentMethod.IsByBankTransfer And pAccommodationStatus.IsCheckIn Then
			Return True;
		Else
			Return False;
		EndIf;
	Else
		Return True;
	EndIf;
EndFunction // CompanyCouldBeChanged

// -----------------------------------------------------------------------------
&AtServer
Procedure FixReservationConditionsOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(vObj, , False, False);
	ValueToFormAttribute(vObj, "Object");
	// Recalculate footer totals
	CalculateServicesFooterTotals();
EndProcedure // FixReservationConditionsOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentCommissionOnChangeAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(vObj, , False, False);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Recalculate footer totals
	CalculateServicesFooterTotals();
EndProcedure // AgentCommissionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomPropertiesValueList(pObj = Undefined)
	vObj = Object;
	If pObj <> Undefined Then
		vObj = pObj;
	EndIf;
	vValueList = New ValueList();
	vValueList.LoadValues(vObj.RoomProperties.Unload().UnloadColumn("RoomProperty"));
	Return vValueList;
EndFunction // GetRoomPropertiesValueList

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomPropertiesFromGuestValueList(pObj = Undefined)
	vObj = Object;
	If pObj <> Undefined Then
		vObj = pObj;
	EndIf;
	vValueList = New ValueList();
	If vObj.Guest.RoomProperties.Count() > 0 Then
		vValueList.LoadValues(vObj.Guest.RoomProperties.Unload().UnloadColumn("RoomProperty"));
	EndIf;
	Return vValueList;
EndFunction // GetRoomPropertiesFromGuestValueList

// -----------------------------------------------------------------------------
&AtServer
Procedure NumberOfKidsOnChangeAtServer(pOnOpen = False, pGuestsList = Undefined, pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	vGuestAge = 0;
	vGuestsAges = New ValueList;
	If pGuestsList <> Undefined Then
		For Each vGuestsListRow In pGuestsList Do
			If ValueIsFilled(vGuestsListRow.Guest) And ValueIsFilled(vGuestsListRow.Guest.DateOfBirth) Then
				vGuestAge = GetClientAge(vGuestsListRow.Guest, vObj.CheckInDate);
			Else
				vGuestAge = vGuestsListRow.GuestAge;
			EndIf;
			vGuestsAges.Add(vGuestAge);
		EndDo;
	EndIf;
	If NumberOfKids = 0 Then
		Items.AgeDecoration.Visible = False;
		If LastKidsNumber > 0 Then
			For vInd = 1 To LastKidsNumber Do
				Try
					Items["KidAge"+String(vInd)].Visible = False;
					ThisObject["KidAge"+String(vInd)] = 0;
				Except
				EndTry;
			EndDo;
		EndIf;
	Else
		If Not pOnOpen Then
			If NumberOfKids > NumberOfKidAgeFields Then
				NumberOfKids = NumberOfKidAgeFields;
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='Maximum number of children allowed is " + NumberOfKidAgeFields + "!';ru='Максимально возможное число детей равно " + NumberOfKidAgeFields + "!';de='Maximum number of children allowed is " + NumberOfKidAgeFields + "!'"));
			EndIf;
		EndIf;
		Items.AgeDecoration.Visible = True;
		If NumberOfKids < LastKidsNumber Then
			For vInd = NumberOfKids + 1 To LastKidsNumber Do
				Try
					Items["KidAge"+String(vInd)].Visible = False;
						vIndex = vInd - 1;
						If NumberOfAdults = 0 Then
							vIndex = vIndex - 1;
						EndIf;
						If vGuestsAges.Count() > vIndex Then
							ThisObject["KidAge" + String(vInd)] = vGuestsAges[vIndex].Value;
						EndIf;
				Except
				EndTry;
			EndDo;
		ElsIf NumberOfKids > LastKidsNumber Then
			vNumberOfFieldsToAdd = 0;
			If NumberOfKids > NumberOfKidAgeFields Then
				Try
					For vInd = LastKidsNumber + 1 To NumberOfKidAgeFields Do
						Items["KidAge"+String(vInd)].Visible = True;
						vIndex = vInd - 1;
						If NumberOfAdults = 0 Then
							vIndex = vIndex - 1;
						EndIf;
						If vGuestsAges.Count() > vIndex Then
							ThisObject["KidAge" + String(vInd)] = vGuestsAges[vIndex].Value;
						EndIf;
					EndDo;
				Except
				EndTry;
				vNumberOfFieldsToAdd = NumberOfKids - NumberOfKidAgeFields;
				If LastKidsNumber > NumberOfKidAgeFields Then
					vNumberOfFieldsToAdd = vNumberOfFieldsToAdd - (LastKidsNumber - NumberOfKidAgeFields);
				EndIf;
				AddKidAgeAttributes(vNumberOfFieldsToAdd, vGuestsAges);
			Else
				Try
					For vInd = LastKidsNumber + 1 To NumberOfKids Do
						Items["KidAge"+String(vInd)].Visible = True;
						vIndex = vInd - 1;
						If NumberOfAdults = 0 And LastKidsNumber > 0 Then
							vIndex = vIndex - 1;
						EndIf;
						If vGuestsAges.Count() > vIndex Then
							ThisObject["KidAge" + String(vInd)] = vGuestsAges[vIndex].Value;
						EndIf;
					EndDo;
				Except
				EndTry;
			EndIf;
		EndIf;
	EndIf;
	CheckGuestFieldCount(vObj, pOnOpen);
	LastKidsNumber = NumberOfKids;
EndProcedure // NumberOfKidsOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AddKidAgeAttributes(pNumberOfFields, pAgesList)
	vTempArray = New Array;
	For vInd = 1 To pNumberOfFields Do
		vTempArray.Add(New FormAttribute("KidAge"+String(NumberOfKidAgeFields+vInd), New TypeDescription("Number")));
	EndDo;
	ChangeAttributes(vTempArray);	
	If ValueIsFilled(pAgesList) And pAgesList.Count() >= NumberOfKidAgeFields + pNumberOfFields Then
		For vInd = 1 To pNumberOfFields Do
			ThisObject["KidAge"+String(NumberOfKidAgeFields+vInd)] = pAgesList[NumberOfKidAgeFields+vInd-1].Value;
		EndDo;
	EndIf;
	For vInd = 1 To pNumberOfFields Do
		vNewField = Items.Add("KidAge"+String(NumberOfKidAgeFields+vInd), Type("FormField"), Items.KidsGroup);
		vNewField.Type = FormFieldType.InputField;
		vNewField.HorizontalAlign = ItemHorizontalLocation.Center;
		vNewField.Width = 2;
		vNewField.TitleLocation = FormItemTitleLocation.None;
		vNewField.SpinButton = False;
		vNewField.DataPath = "KidAge"+String(NumberOfKidAgeFields+vInd);
		vNewField.SetAction("OnChange", "KidAgeOnChange");
	EndDo;
	NumberOfKidAgeFields = NumberOfKidAgeFields + pNumberOfFields;
EndProcedure // AddKidAgeAttributes

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckGuestFieldCount(pObj = Undefined, pOnOpen = False, pDoNotRecalculateTotals = False) Export
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	vGIGCount = GuestsInGroup.Count();
	vAccTemplateIsFound = True;
	
	// Reset guest remarks
	GuestRemarks = "";
    Items.GuestRemarks.Visible = False;
	Items.GuestRemarks.TextColor = Items.Number.TextColor;
	Items.GuestRemarks.BorderColor = Items.Number.BorderColor;
	
	// Build array of kid ages
	vNumberOfPersons = 0;
	vAgeArray = New Array;
	If NumberOfKids > 0 Then
		For vInd = 1 To NumberOfKids Do
			Try
				vAge = ThisObject["KidAge"+String(vInd)];
				If vAge > 0 Then
					vAgeArray.Add(vAge);
				EndIf;
			Except
			EndTry;
		EndDo;
		vNumberOfPersons = NumberOfAdults + NumberOfKids;
	Else
		vNumberOfPersons = NumberOfAdults;
	EndIf;
	vMaxPersonsNumber = 0;
	If ValueIsFilled(vObj.Room) Then
		vMaxPersonsNumber = vObj.Room.NumberOfPersonsPerRoom;
	ElsIf ValueIsFilled(vObj.RoomType) Then
		vMaxPersonsNumber = vObj.RoomType.NumberOfPersonsPerRoom;
	Else
		vMaxPersonsNumber = vNumberOfPersons;
	EndIf;
	If LastKidsNumber < NumberOfKids Then
		If ValueIsFilled(vObj.Room) Or ValueIsFilled(vObj.RoomType) Then
			If vMaxPersonsNumber<(NumberOfKids+NumberOfAdults) Then
				For vInd = 0 To (NumberOfKids+NumberOfAdults-vMaxPersonsNumber-1) Do
					If NumberOfKids-vInd <= 0 Then
						break;
					EndIf;
					vKidAgeItem = Items["KidAge"+String(NumberOfKids-vInd)];
					If vKidAgeItem.Visible Then
						If ThisObject["KidAge"+String(NumberOfKids-vInd)] = 0 Then
							vKidAgeItem.Visible = False;
							NumberOfKids = NumberOfKids - 1;
							If NumberOfKids = 0 Then
								Items.AgeDecoration.Visible = False;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				GuestRemarks = NStr("en='It is not possible to check-in this number of guests into the given room type!';ru='В выбранный тип номера указанное число гостей разместить нельзя!';de='Im Zimmer des gewählten Typs kann die genannten Anzahl von Gästen nicht untergebracht werden!'");
				Items.GuestRemarks.Visible = True;
				Items.GuestRemarks.TextColor = WebColors.Red;
				Items.GuestRemarks.BorderColor = Items.Number.BorderColor;
			EndIf;
		EndIf;
	EndIf;
	// Build structure with children ages
	vChildrenAgesStruct = Undefined;
	If ValueIsFilled(vObj.Contract) Then
		vAllotmentContract = vObj.Contract;
		If vAllotmentContract.TeenagersMaxAge <> 0 Or vAllotmentContract.ChildrenMaxAge <> 0 Or vAllotmentContract.InfantsMaxAge <> 0 Then
			vChildrenAgesStruct = vAllotmentContract;
		EndIf;
	EndIf;
	// Get active special offers
	vHotel = vObj.Hotel;
	If vHotel.TeenagersMaxAge <> 0 Or vHotel.ChildrenMaxAge <> 0 Or vHotel.InfantsMaxAge <> 0 Then
		vOffers = cmGetConfirmedSpecialOffersForReservation(vObj.Ref, vObj.Hotel, vObj.RoomRate, vObj.RoomRateType, vObj.Guest, vObj.ClientType, vObj.Customer, vObj.CustomerType, vObj.GuestGroup, vObj.SourceOfBusiness, vObj.MarketingCode, vObj.TripPurpose, vObj.CheckInDate, vObj.Duration, vObj.CheckOutDate, ?(ValueIsFilled(vObj.GuestGroup), vObj.GuestGroup.CreateDate, vObj.Date), vObj.RoomType);
		For Each vOffersRow In vOffers Do
			vOffer = vOffersRow.SpecialOffer;
			If vOffer.TeenagersMaxAge <> 0 Or vOffer.ChildrenMaxAge <> 0 Or vOffer.InfantsMaxAge <> 0 Then
				vChildrenAgesStruct = vOffer;
				Break;
			EndIf;
		EndDo;
	EndIf;
	// Find accommodation template for the given number of persons and children ages
	If Not OneGuestMode Then
		If ValueIsFilled(vObj.RoomType) Or pOnOpen Then
			vNumberOfGuestsInDatabase = GuestsInGroup.Count() + 1 + GetNumberOfNotCheckedInGuests();
			vNumberOfGuestsInTemplate = vNumberOfGuestsInDatabase;
			If ValueIsFilled(vObj.AccommodationTemplate) Then
				vAccTemplateFromDatabase = vObj.AccommodationTemplate;
				vNumberOfGuestsInTemplate = vAccTemplateFromDatabase.NumberOfAdults + vAccTemplateFromDatabase.NumberOfTeenagers + vAccTemplateFromDatabase.NumberOfChildren + vAccTemplateFromDatabase.NumberOfInfants;
			EndIf;
			vAccommodationTemplates = cmGetAvailableAccommodationTypesWithKidsAges(NumberOfAdults, vAgeArray.Count(), vAgeArray, "", vObj.Hotel, ?(ValueIsFilled(vObj.RoomTypeUpgrade), vObj.RoomTypeUpgrade, vObj.RoomType), , False, , vChildrenAgesStruct, ?(pOnOpen And vNumberOfGuestsInDatabase = vNumberOfGuestsInTemplate, vObj.AccommodationTemplate, Undefined));
			If pOnOpen Then		
				vThereAreDifferentCheckInDates = False;
				For Each vGGRow In GuestsInGroup Do
					If vGGRow.CheckInDateIsDifferent Then
						vThereAreDifferentCheckInDates = True;
						Break;
					EndIf;
				EndDo;
				If vAccommodationTemplates = Undefined Then
					vAccTemplateIsFound = False;
				ElsIf vAccommodationTemplates.Count() = 0 Then
					vAccTemplateIsFound = False;
				ElsIf Not vThereAreDifferentCheckInDates Then
					For Each vAccommodationTemplatesRow In vAccommodationTemplates Do
						If ValueIsFilled(vAccommodationTemplatesRow.AccTemplate) And vAccommodationTemplatesRow.AccTemplate.IsForFolioSplit And Not vObj.IsForFolioSplit Then
							Continue;
						EndIf;
						If ValueIsFilled(vObj.RoomType) And Not OneGuestMode And vNumberOfGuestsInDatabase <> vNumberOfGuestsInTemplate Then
							If vObj.AccommodationTemplate <> vAccommodationTemplatesRow.AccTemplate Then
								vObj.AccommodationTemplate = vAccommodationTemplatesRow.AccTemplate;
								Modified = True;
							EndIf;
						EndIf;
						If vObj.AccommodationType = vAccommodationTemplatesRow.AccommodationType Then
							If ValueIsFilled(vObj.AccommodationTemplate) And vObj.AccommodationTemplate.IsForFolioSplit And Not vObj.IsForFolioSplit Then
								vObj.IsForFolioSplit = True;
								Modified = True;
							EndIf;
						EndIf;
						Break;
					EndDo;
				EndIf;
			EndIf;
			If Not pOnOpen Then		
				// Get room type prices
				vCurRoomTypeAccTypes = Undefined;
				If vAccommodationTemplates = Undefined Then
					Try
						For vInd = vMaxPersonsNumber+1 To LastNumberOfAdults+LastKidsNumber Do
							Items["Guest"+String(vInd)+"Group"].Visible = False;
							ThisObject["Guest"+String(vInd)] = Undefined;
							ThisObject["AccommodationType"+String(vInd)] = Undefined;
							ThisObject["SharePercent"+String(vInd)] = "";
							ThisObject["HotelProduct"+String(vInd)] = Undefined;
							ThisObject["Guest"+String(vInd)+"Registration"] = Undefined;
						EndDo;       
						If ThisObject.CurrentItem <> Undefined Then
							If Left(ThisObject.CurrentItem.Name, 6)="KidAge" Then
								ThisObject[ThisObject.CurrentItem.Name] = 0;
								For vInd = 1 To NumberOfKidAgeFields Do
									vKidAgeItem = Items["KidAge"+String(vInd)];
									If vKidAgeItem.Visible Then
										If ThisObject["KidAge"+String(vInd)] = 0 Then
											vKidAgeItem.Visible = False;
											NumberOfKids = NumberOfKids - 1;
											If NumberOfKids = 0 Then
												Items.AgeDecoration.Visible = False;
											EndIf;
										EndIf;
									EndIf;
								EndDo;
							EndIf;
						EndIf;
					Except
					EndTry;
					If vMaxPersonsNumber > vAgeArray.Count() Then
						NumberOfAdults = vMaxPersonsNumber-vAgeArray.Count();
					Else
						NumberOfAdults = 1;
						NumberOfKids = vMaxPersonsNumber - 1;
						LastKidsNumber = NumberOfKids;
						For vInd = 1 To NumberOfKidAgeFields Do
							vKidAgeItem = Items["KidAge"+String(vInd)];
							If vKidAgeItem.Visible Then
								If vInd>NumberOfKids Then
									ThisObject["KidAge"+String(vInd)] = 0;
									vKidAgeItem.Visible = False;
									If NumberOfKids = 0 Then
										Items.AgeDecoration.Visible = False;
									EndIf;
								EndIf;
							Else
								If vInd<=NumberOfKids Then
									vKidAgeItem.Visible = True;
									Items.AgeDecoration.Visible = True;
								EndIf;
							EndIf;
						EndDo;
					EndIf;
					LastNumberOfAdults = NumberOfAdults;
					If pObj = Undefined Then
						ValueToFormAttribute(vObj, "Object");
					EndIf;
					Return;
				EndIf;
				vCurRoomTypeAccTypes = New Array;
				If vAccommodationTemplates <> Undefined Then
					vFirstAccTemplate = Undefined;
					For Each vRow In vAccommodationTemplates Do
						If ValueIsFilled(vRow.AccTemplate) And vObj.IsForFolioSplit <> vRow.AccTemplate.IsForFolioSplit Then
							Continue;
						EndIf;
						If vFirstAccTemplate = Undefined Then
							vFirstAccTemplate = vRow.AccTemplate;
							If Not OneGuestMode Then
								vObj.AccommodationTemplate = vFirstAccTemplate;
								If ValueIsFilled(vFirstAccTemplate) Then
									vObj.NumberOfAdults = vFirstAccTemplate.NumberOfAdults;
									vObj.NumberOfTeenagers = vFirstAccTemplate.NumberOfTeenagers;
									vObj.NumberOfChildren = vFirstAccTemplate.NumberOfChildren;
									vObj.NumberOfInfants = vFirstAccTemplate.NumberOfInfants;
									UpdateTemplateInChangesPlan(vObj);
								EndIf;
							EndIf;
						EndIf;
						If vFirstAccTemplate <> Undefined And vFirstAccTemplate <> vRow.AccTemplate Then
							Break;
						Endif;
						vCurRoomTypeAccTypes.Add(vRow);
					EndDo;
				EndIf;
				If vCurRoomTypeAccTypes.Count() < vNumberOfPersons Then
					For vInd = vCurRoomTypeAccTypes.Count() To vNumberOfPersons-1 Do
						If vInd = 0 Then
							If ValueIsFilled(vObj.AccommodationType) Then
								vNewRowStruc = New Structure("AccommodationType", vObj.AccommodationType);
							Else
								vNewRowStruc = New Structure("AccommodationType", cmGetAccommodationTypeRoom(vObj.Hotel));
							EndIf;
						Else
							If GuestsInGroup.Count() >= vInd Then
								vNewRowStruc = New Structure("AccommodationType", GuestsInGroup.Get(vInd - 1).AccommodationType);
							Else
								vNewRowStruc = New Structure("AccommodationType", Catalogs.AccommodationTypes.EmptyRef());
							EndIf;
						EndIf;
						vCurRoomTypeAccTypes.Add(vNewRowStruc);
					EndDo;
					If vNumberOfPersons > 1 Then
						vAccTemplateIsFound = False;
						vKidsAgesAreEmpty = False;
						Try
							If NumberOfKids > 0 Then
								For vKidIdx = 1 To NumberOfKids Do
									If ThisObject["KidAge"+String(vKidIdx)] = 0 Then
										vKidsAgesAreEmpty = True;
										Break;
									EndIf;
								EndDo;
							EndIf;
						Except
						EndTry;
						If vKidsAgesAreEmpty Then
							Items.GuestRemarks.Visible = True;
							GuestRemarks = NStr("en='Please specify kids ages!';ru='Пожалуйста укажите возраст детей!';de='Bitte geben Sie das Alter der Kinder!'");
							Items.GuestRemarks.TextColor = WebColors.Blue;
							Items.GuestRemarks.BorderColor = Items.Number.BorderColor;
						Else
							If Not vObj.IsForFolioSplit Then
								Items.GuestRemarks.Visible = True;
								GuestRemarks = NStr("en='Accommodation template not found!';ru='Шаблон размещения на данное количество гостей не найден!';de='Vorlage für die Unterbringungen für diese Anzahl von Gästen wurde nicht gefunden!'");
								Items.GuestRemarks.TextColor = WebColors.Red;
								Items.GuestRemarks.BorderColor = Items.Number.BorderColor;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				If vCurRoomTypeAccTypes <> Undefined Then
					If vNumberOfPersons > NumberOfGuestFields Then
						Try
							vIndex = 1;
							For Each vAccTypeRow In vCurRoomTypeAccTypes Do
								If vIndex = 1 Then
									vObj.AccommodationType = vAccTypeRow.AccommodationType;
								Else
									If vIndex > NumberOfGuestFields Then
										AddGuestFieldAttributes(1, vObj);
									EndIf;
									Items["Guest"+String(vIndex)+"Group"].Visible = True;
									Items["Guest"+String(vIndex)+"Group"].Enabled = True;
									ThisObject["AccommodationType"+String(vIndex)] = vAccTypeRow.AccommodationType;
									vGuest = ThisObject["Guest"+String(vIndex)];
									If vGIGCount<(vIndex-1) Then
										vNewRow = GuestsInGroup.Add();
										vNewRow.AccommodationType = vAccTypeRow.AccommodationType;
										vNewRow.GuestRef = vGuest;
										vNewRow.Guest = vGuest.FullName;
										vNewRow.AccommodationStatus = vObj.AccommodationStatus;
										vNewRow.IsAnnulation = False;
										vNewRow.IsGuest = True;
										vGIGCount = vGIGCount + 1;
									Else
										vGiGRow = GuestsInGroup.Get(vIndex-2);
										vGiGRow.AccommodationType = vAccTypeRow.AccommodationType;
										vGiGRow.AccommodationStatus = vObj.AccommodationStatus;
										vGiGRow.IsAnnulation = False;
										vGiGRow.IsStatusChanged = False;
										vGiGRow.IsGuest = True;
										vGiGRow.GuestRef = vGuest;
										If ValueIsFilled(vGuest) Then
											vGiGRow.Guest = vGuest.FullName;
										EndIf;
									EndIf;
									If ValueIsFilled(vGuest) Then
										Items["SelGuest"+String(vIndex)].TextEdit = False;
									Else
										Items["SelGuest"+String(vIndex)].TextEdit = True;
									EndIf;
								EndIf;
								vIndex = vIndex + 1;
							EndDo;
						Except
						EndTry;
					Else
						Try
							vIndex = 1;
							For Each vAccTypeRow In vCurRoomTypeAccTypes Do
								If vIndex = 1 Then
									vObj.AccommodationType = vAccTypeRow.AccommodationType;
								Else
									Items["Guest"+String(vIndex)+"Group"].Visible = True;
									Items["Guest"+String(vIndex)+"Group"].Enabled = True;
									ThisObject["AccommodationType"+String(vIndex)] = vAccTypeRow.AccommodationType;
									vGuest = ThisObject["Guest"+String(vIndex)];
									If vGIGCount<(vIndex-1) Then
										vNewRow = GuestsInGroup.Add();
										vNewRow.AccommodationType = vAccTypeRow.AccommodationType;
										vNewRow.GuestRef = vGuest;
										vNewRow.Guest = vGuest.FullName;
										vNewRow.AccommodationStatus = vObj.AccommodationStatus;
										vNewRow.IsAnnulation = False;
										vNewRow.IsGuest = True;
										If BegOfDay(Object.CheckInDate) < BegOfDay(CurrentSessionDate()) Then
											vNewRow.CheckInDateIsDifferent = True;
										EndIf;
										vGIGCount = vGIGCount + 1;
									Else
										vGiGRow = GuestsInGroup.Get(vIndex-2);
										vGiGRow.AccommodationType = vAccTypeRow.AccommodationType;
										vGiGRow.AccommodationStatus = vObj.AccommodationStatus;
										vGiGRow.IsAnnulation = False;
										vGiGRow.IsStatusChanged = False;
										vGiGRow.IsGuest = True;
										vGiGRow.GuestRef = vGuest;
										If ValueIsFilled(vGuest) Then
											vGiGRow.Guest = vGuest.FullName;
										EndIf;
									EndIf;
									If ValueIsFilled(vGuest) Then
										Items["SelGuest"+String(vIndex)].TextEdit = False;
									Else
										Items["SelGuest"+String(vIndex)].TextEdit = True;
									EndIf;
								EndIf;
								vIndex = vIndex + 1;
							EndDo;
							If vGIGCount >= vNumberOfPersons Then
								vRowsToDeleteArray = New Array;
								For vInd = vNumberOfPersons To vGIGCount Do
									vRow = GuestsInGroup.Get(vInd-1);
									if ValueIsFilled(vRow.Ref) Then
										Items["Guest"+String(vInd+1)+"Group"].Enabled = False;
										vAnnulationStatus = cmGetAccommodationAnnulationStatus(vRow.Ref);
										vRow.AccommodationStatus = vAnnulationStatus;
										vRow.IsStatusChanged = True;
										vRow.IsAnnulation = True;
									Else
										Items["Guest"+String(vInd+1)+"Group"].Visible = False;
										ThisObject["Guest"+String(vInd+1)] = Undefined;
										ThisObject["SelGuest"+String(vInd+1)] = "";
										ThisObject["AccommodationType"+String(vInd+1)] = Undefined;
										ThisObject["SharePercent"+String(vInd+1)] = "";
										ThisObject["HotelProduct"+String(vInd+1)] = Undefined;
										Items["SelGuest"+String(vInd+1)].TextEdit = True;
										vRowsToDeleteArray.Add(vRow);
									EndIf;
								EndDo;
								For Each vRow in vRowsToDeleteArray Do
									GuestsInGroup.Delete(vRow);
								EndDo;
							ElsIf vNumberOfPersons < LastNumberOfAdults+LastKidsNumber Then
								For vInd = vNumberOfPersons+1 To LastNumberOfAdults+LastKidsNumber Do
									Items["Guest"+String(vInd)+"Group"].Visible = False;
									ThisObject["Guest"+String(vInd)] = Undefined;
									ThisObject["SelGuest"+String(vInd)] = "";
									ThisObject["AccommodationType"+String(vInd)] = Undefined;
									ThisObject["SharePercent"+String(vInd)] = "";
									ThisObject["HotelProduct"+String(vInd)] = Undefined;
									Items["SelGuest"+String(vInd)].TextEdit = True;
								EndDo;
							EndIf;
						Except
						EndTry;                                  
					EndIf;
				EndIf;
				// Process overrides
				If ValueIsFilled(vObj.RoomRate) And ValueIsFilled(vObj.AccommodationTemplate) Then
					vOverrides = cmGetRoomRateOverrides(vObj.RoomRate, vObj.Hotel, vObj.AccommodationTemplate, ?(ValueIsFilled(vObj.RoomTypeUpgrade), vObj.RoomTypeUpgrade, vObj.RoomType));
					If vOverrides.Count() > 0 Then
						vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vObj.AccommodationType, 1));
						If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
							vObj.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
						EndIf;
						vIndex = 2;
						For Each vGiGRow In GuestsInGroup Do
							vOverrideRows = vOverrides.FindRows(New Structure("AccommodationType, TemplateLineNumber", vGiGRow.AccommodationType, vIndex));
							If vOverrideRows.Count() > 0 And ValueIsFilled(vOverrideRows.Get(0).ToAccommodationType) Then
								vGiGRow.AccommodationType = vOverrideRows.Get(0).ToAccommodationType;
								ThisForm["AccommodationType"+String(vIndex)] = vGiGRow.AccommodationType;
							EndIf;
							vIndex = vIndex + 1;
						EndDo;
					EndIf;
				EndIf;
				If Not pDoNotRecalculateTotals Then
					TotalSum = CalculateTotalServices(vObj, , False, False);
				EndIf;
			Else
				If vNumberOfPersons > NumberOfGuestFields Then
					Try
						vIndex = 1;
						For Each vGiGRow In GuestsInGroup Do
							If vIndex >= NumberOfGuestFields Then
								AddGuestFieldAttributes(1, vObj);
							EndIf;
							ThisObject["Guest"+String(vIndex+1)] = vGiGRow.GuestRef;
							ThisObject["SelGuest"+String(vIndex+1)] = vGiGRow.Guest;
							Items["Guest"+String(vIndex+1)+"Group"].Visible = True;
							Items["Guest"+String(vIndex+1)+"Group"].Enabled = True;
							ThisObject["AccommodationType"+String(vIndex+1)] = vGiGRow.AccommodationType;
							ThisObject["SharePercent"+String(vIndex+1)] = vGiGRow.SharePercent;
							Items["SharePercent"+String(vIndex+1)].Visible = vObj.IsForFolioSplit;
							ThisObject["HotelProduct"+String(vIndex+1)] = vGiGRow.HotelProduct;
							If ValueIsFilled(vGiGRow.GuestRef) Then
								Items["SelGuest"+String(vIndex+1)].TextEdit = False;
							Else
								Items["SelGuest"+String(vIndex+1)].TextEdit = True;
							EndIf;
							vIndex = vIndex + 1;
						EndDo;
					Except
					EndTry;
				Else
					Try
						vIndex = 1;
						For Each vGiGRow In GuestsInGroup Do
							Items["Guest"+String(vIndex+1)+"Group"].Visible = True;
							Items["Guest"+String(vIndex+1)+"Group"].Enabled = True;
							ThisObject["Guest"+String(vIndex+1)] = vGiGRow.GuestRef;
							ThisObject["SelGuest"+String(vIndex+1)] = vGiGRow.Guest;
							ThisObject["AccommodationType"+String(vIndex+1)] = vGiGRow.AccommodationType;
							ThisObject["SharePercent"+String(vIndex+1)] = vGiGRow.SharePercent;
							Items["SharePercent"+String(vIndex+1)].Visible = vObj.IsForFolioSplit;
							ThisObject["HotelProduct"+String(vIndex+1)] = vGiGRow.HotelProduct;
							If ValueIsFilled(vGiGRow.GuestRef) Then
								Items["SelGuest"+String(vIndex+1)].TextEdit = False;
							Else
								Items["SelGuest"+String(vIndex+1)].TextEdit = True;
							EndIf;
							vIndex = vIndex + 1;
						EndDo;
					Except
					EndTry;                                  
				EndIf;
				If Object.AccommodationTemplate <> vObj.AccommodationTemplate Then
					// Recalculate totals
					If Not pDoNotRecalculateTotals Then
						TotalSum = CalculateTotalServices(vObj, , False, False);
					EndIf;
				EndIf;
			EndIf;
		Else
			Try
				If vNumberOfPersons > NumberOfGuestFields Then
					For vInd = 2 To NumberOfGuestFields Do
						Items["Guest"+String(vInd)+"Group"].Visible = True;
						Items["Guest"+String(vInd)+"Group"].Enabled = True;
						ThisObject["HotelProduct"+String(vInd)] = Undefined;
					EndDo;
					vNumberOfFieldsToAdd = vNumberOfPersons - NumberOfGuestFields;
					AddGuestFieldAttributes(vNumberOfFieldsToAdd, vObj);
				Else
					For vInd = 2 To vNumberOfPersons Do
						Items["Guest"+String(vInd)+"Group"].Visible = True;
						Items["Guest"+String(vInd)+"Group"].Enabled = True;
						ThisObject["HotelProduct"+String(vInd)] = Undefined;
					EndDo;
					If vGIGCount >= vNumberOfPersons Then
						vRowsToDeleteArray = New Array;
						For vInd = vNumberOfPersons To vGIGCount Do
							Items["Guest"+String(vInd+1)+"Group"].Visible = False;
							ThisObject["Guest"+String(vInd+1)] = Undefined;
							ThisObject["SelGuest"+String(vInd+1)] = "";
							ThisObject["AccommodationType"+String(vInd+1)] = Undefined;
							ThisObject["SharePercent"+String(vInd+1)] = "";
							ThisObject["HotelProduct"+String(vInd+1)] = Undefined;
							Items["SelGuest"+String(vInd+1)].TextEdit = True;
							vRowsToDeleteArray.Add(GuestsInGroup.Get(vInd-1));
						EndDo;
						For Each vRow in vRowsToDeleteArray Do
							GuestsInGroup.Delete(vRow);
						EndDo;
					ElsIf vNumberOfPersons < LastNumberOfAdults+LastKidsNumber Then
						For vInd = vNumberOfPersons+1 To LastNumberOfAdults+LastKidsNumber Do
							Items["Guest"+String(vInd)+"Group"].Visible = False;
							ThisObject["Guest"+String(vInd)] = Undefined;
							ThisObject["SelGuest"+String(vInd)] = "";
							ThisObject["AccommodationType"+String(vInd)] = Undefined;
							ThisObject["SharePercent"+String(vInd)] = "";
							ThisObject["HotelProduct"+String(vInd)] = Undefined;
							Items["SelGuest"+String(vInd)].TextEdit = True;
						EndDo;
					EndIf;
				EndIf;
				For Each vGiG In GuestsInGroup Do
					vInd = GuestsInGroup.IndexOf(vGiG) + 2;
					If ThisObject["AccommodationType"+String(vInd)] = Undefined Then
						vGiG.AccommodationType = Undefined;
						vGiG.SharePercent = "";
					EndIf;
				EndDo;
			Except
			EndTry;
		EndIf;
	EndIf;
	
	// Check all accommodation types
	vAccTypesAreEditable = Not vAccTemplateIsFound Or vObj.IsForFolioSplit;
	If Not vAccTypesAreEditable Then
		For Each vGiG In GuestsInGroup Do
			If Not ValueIsFilled(vGiG.AccommodationType) Then
				vAccTypesAreEditable = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	If Not vAccTypesAreEditable Then
		If vObj.Hotel.MoreThen3ChildrenAgeRangesAreUsed Then
			vAccTypesAreEditable = True;
		EndIf;
	EndIf;
	If GuestsInGroup.Count() > 0 Then
		vAccTypeItem = ThisObject.Items.AccommodationType;
		If vAccTypesAreEditable Then
			vAccTypeItem.Enabled = True;
		Else	
			vAccTypeItem.Enabled = False;
		EndIf;
	EndIf;
	Items.SharePercent.Visible = vObj.IsForFolioSplit;
	vTypes = Items.AccommodationType.ChoiceList.UnloadValues();
	For Each vGiG In GuestsInGroup Do
		vInd = GuestsInGroup.IndexOf(vGiG) + 2;
		Items["SharePercent" + vInd].Visible = vObj.IsForFolioSplit;
		Items["SharePercent" + vInd].SetAction("OnChange", "ExtraGuestSharePercentOnChange");
		vAccTypeItem = ThisObject.Items["AccommodationType" + vInd];
		vAccTypeItem.Enabled = vAccTypesAreEditable;
		vAccTypeItem.ChoiceList.LoadValues(vTypes);
		If vAccTypesAreEditable Then
			vAccTypeItem.SetAction("StartChoice", "ExtraGuestAccommodationTypeStartChoice");
			vAccTypeItem.SetAction("OnChange", "ExtraGuestAccommodationTypeOnChange");
		EndIf;
	EndDo;
	
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
EndProcedure // CheckGuestFieldCount

// -----------------------------------------------------------------------------
&AtServer
Function GetNumberOfNotCheckedInGuests()
	vNCIGuests = 0;
	If Object.Posted And Object.AccommodationStatus.IsInHouse And Object.AccommodationStatus.IsActive Then
		vReservationsList = New ValueList();
		If ValueIsFilled(Object.Reservation) Then
			vReservationsList.Add(Object.Reservation);
		EndIf;
		For Each vGiGRow In GuestsInGroup Do
			vSameRoomOtherDoc = vGiGRow.Ref;
			If ValueIsFilled(vSameRoomOtherDoc) And ValueIsFilled(vSameRoomOtherDoc.Reservation) Then
				vReservationsList.Add(vSameRoomOtherDoc.Reservation);
			EndIf;
		EndDo;
		// Run query
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Reservations.Ref AS Ref
		|FROM
		|	Document.Reservation AS Reservations
		|WHERE
		|	Reservations.Number = &qNumber
		|	AND Reservations.GuestGroup = &qGuestGroup
		|	AND Reservations.Hotel = &qHotel
		|	AND Reservations.Posted
		|	AND (Reservations.ReservationStatus.IsActive
		|			OR Reservations.ReservationStatus.IsPreliminary)
		|	AND NOT Reservations.ReservationStatus.IsCheckIn
		|	AND NOT Reservations.Ref IN (&qReservationsList)
		|
		|ORDER BY
		|	Reservations.SortCode";
		vQry.SetParameter("qHotel", Object.Hotel);
		vQry.SetParameter("qGuestGroup", Object.GuestGroup);
		vQry.SetParameter("qNumber", Object.Number);
		vQry.SetParameter("qReservationsList", vReservationsList);
		vResult = vQry.Execute().Unload();
		vNCIGuests = vResult.Count();
	EndIf;
	Return vNCIGuests;
EndFunction // GetNumberOfNotCheckedInGuests

// -----------------------------------------------------------------------------
&AtServer
Procedure ReadForeignerRegistryDocuments(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	// Read foreigner registry documents
	vGuest = vObj.Guest;
	vGuestCheckOutDate = vObj.CheckOutDate;
	vIndex = 1;
	vHotelCitizenship = vObj.Hotel.Citizenship;
	If vHotelCitizenship.Code = 643 Then // Russia
		While True Do
			If ValueIsFilled(vGuest) And vGuest.Citizenship <> vHotelCitizenship Then
				Items["Guest"+String(vIndex)+"RegistrationGroup"].Visible = True;
				vCitizenshipISOCode = TrimAll(vGuest.Citizenship.ISOCode);
				Items["Guest"+String(vIndex)+"RegistrationIndent"].Title = vCitizenshipISOCode;
				vGuestRegDoc = GetGuestForeignerRegistryRecord(vGuest, vObj);
				ThisObject["Guest"+String(vIndex)+"Registration"] = vGuestRegDoc;
				If Not ValueIsFilled(vGuestRegDoc) Then
					Items["Guest"+String(vIndex)+"RegistrationAction"].Title = NStr("en='Register'; ru='Зарегистрировать'; de='Registrieren'");
					Items["Guest"+String(vIndex)+"RegistrationAction"].TextColor = WebColors.Red;
				ElsIf BegOfDay(vGuestRegDoc.CheckOutDate) < BegOfDay(vGuestCheckOutDate) Then
					Items["Guest"+String(vIndex)+"RegistrationAction"].Title = NStr("en='Extend registration N '; ru='Продлить регистрацию № '; de='Anmeldung verlängern Nr. '") + TrimAll(vGuestRegDoc.Number);
					Items["Guest"+String(vIndex)+"RegistrationAction"].TextColor = WebColors.Red;
				Else
					Items["Guest"+String(vIndex)+"RegistrationAction"].Title = NStr("en='Registration N '; ru='Регистрация № '; de='Anmeldung Nr. '") + TrimAll(vGuestRegDoc.Number);
					Items["Guest"+String(vIndex)+"RegistrationAction"].TextColor = WebColors.Green;
				EndIf;
				Items["Group"+String(vIndex)+"LegalRepresentativeLine"].Visible = False;
			Else
				Items["Guest"+String(vIndex)+"RegistrationGroup"].Visible = False;
				Items["Guest"+String(vIndex)+"RegistrationIndent"].Title = "";
				ThisObject["Guest"+String(vIndex)+"Registration"] = Undefined;
				Items["Guest"+String(vIndex)+"RegistrationAction"].Title = "";
				Items["Guest"+String(vIndex)+"RegistrationAction"].TextColor = Items["Guest"+String(vIndex)+"RegistrationIndent"].TextColor;
				
				// Legal representative
				If ValueIsFilled(vGuest) Then
					If ValueIsFilled(vGuest.DateOfBirth) And vGuest.Age < 18 And GetFunctionalOption("LegalRepresentativeForChildren") Or GetFunctionalOption("LegalRepresentativeForAdults") Then
						Items["Group"+String(vIndex)+"LegalRepresentativeLine"].Visible = True;
						
						If vIndex > 1 Then
							vLegalRepresentative = ThisObject["LegalRepresentative"+String(vIndex)];
							vRelationType = ThisObject["RelationType"+String(vIndex)];
						Else
							vLegalRepresentative = vObj.LegalRepresentative;
							vRelationType =  vObj.RelationType;
						EndIf;
						vLegalRepresentativeTxt = "";
						If ValueIsFilled(vLegalRepresentative) Then
							vLegalRepresentativeTxt = vLegalRepresentative.Description;
						EndIf;	
						If ValueIsFilled(vRelationType) Then
							vRelationTypeTxt = cmNStr(TrimAll(vRelationType.Description), SessionParameters.CurrentLanguage);
							If IsBlankString(vRelationTypeTxt) Then
								vRelationTypeTxt = TrimAll(vRelationType.Description);
							EndIf;	
							vRelationTypeTxt = ?(IsBlankString(vLegalRepresentativeTxt), vRelationTypeTxt, ", "+vRelationTypeTxt); 
						Else
							vRelationTypeTxt = "";
						EndIf;	
						If IsBlankString(vLegalRepresentativeTxt) And IsBlankString(vRelationTypeTxt) Then
							ThisObject["LegalRepresentativePresentation"+String(vIndex)] = Nstr("en = 'Not specified...'; de = 'Unbestimmt...'; ru = 'Не указан...'") ;
						Else
							ThisObject["LegalRepresentativePresentation"+String(vIndex)] = vLegalRepresentativeTxt + vRelationTypeTxt; 
						EndIf;
					Else
						Items["Group"+String(vIndex)+"LegalRepresentativeLine"].Visible = False;
					EndIf;
				Else
					Items["Group"+String(vIndex)+"LegalRepresentativeLine"].Visible = False;
				EndIf
			EndIf;
			
			vIndex = vIndex + 1;
			If vIndex > (GuestsInGroup.Count() + 1) Then
				Break;
			EndIf;
			vGuest = ThisObject["Guest"+String(vIndex)];
			vGIG = GuestsInGroup.Get(vIndex - 2);
			If ValueIsFilled(vGIG.Ref) Then
				vGuestCheckOutDate = vGIG.Ref.CheckOutDate;
			EndIf;
		EndDo;
	Else
		Items["Group"+String(vIndex)+"LegalRepresentativeLine"].Visible = False;	
	EndIf;	
EndProcedure // ReadForeignerRegistryDocuments

// -----------------------------------------------------------------------------
&AtServer
Function GetGuestForeignerRegistryRecord(pGuest, pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = FormAttributeToValue("Object");
	EndIf;
	vGuestRegDoc = Undefined;
	
	// Check guest attributes
	If Not ValueIsFilled(pGuest) Then
		Return Undefined;
	EndIf;
	
	// Build and run query to get records for the current document
	vQry = New Query;
	vQry.Text = 
	"SELECT TOP 1
	|	ForeignerRegistryRecord.Ref AS ForeignerRegistryRecord
	|FROM
	|	Document.ForeignerRegistryRecord AS ForeignerRegistryRecord
	|WHERE
	|	ForeignerRegistryRecord.Guest = &qGuest
	|	AND ForeignerRegistryRecord.ParentDoc.GuestGroup = &qGuestGroup
	|	AND ForeignerRegistryRecord.Posted
	|
	|ORDER BY
	|	ForeignerRegistryRecord.CheckOutDate DESC,
	|	ForeignerRegistryRecord.PointInTime DESC";
	vQry.SetParameter("qGuestGroup", vObj.GuestGroup);
	vQry.SetParameter("qGuest", pGuest);
	vFRs = vQry.Execute().Unload();
	If vFRs.Count() > 0 Then
		vGuestRegDoc = vFRs.Get(0).ForeignerRegistryRecord;
	EndIf;
	
	// Return
	Return vGuestRegDoc;
EndFunction // GetGuestForeignerRegistryRecord

// -----------------------------------------------------------------------------
&AtServer
Procedure AddGuestFieldAttributes(pNumberOfFieldsToAdd, pObj)
	For vInd = 1 To pNumberOfFieldsToAdd Do
		vTempArray = New Array;	
		vTempArray.Add(New FormAttribute("Guest"+String(NumberOfGuestFields+vInd), New TypeDescription("CatalogRef.Clients")));
		vTempArray.Add(New FormAttribute("SelGuest"+String(NumberOfGuestFields+vInd), New TypeDescription("String")));
		vTempArray.Add(New FormAttribute("LastGuestFullName"+String(NumberOfGuestFields+vInd), New TypeDescription("String")));
		vTempArray.Add(New FormAttribute("AccommodationType"+String(NumberOfGuestFields+vInd), New TypeDescription("CatalogRef.AccommodationTypes")));
		vTempArray.Add(New FormAttribute("SharePercent"+String(NumberOfGuestFields+vInd), cmGetStringTypeDescription(6)));
		vTempArray.Add(New FormAttribute("GuestChangesDescription"+String(NumberOfGuestFields+vInd), New TypeDescription("String")));
		vTempArray.Add(New FormAttribute("HotelProduct"+String(NumberOfGuestFields+vInd), New TypeDescription("CatalogRef.HotelProducts")));
		vTempArray.Add(New FormAttribute("Guest"+String(NumberOfGuestFields+vInd)+"Registration", cmGetDocumentTypeDescription("ForeignerRegistryRecord")));
		vTempArray.Add(New FormAttribute("LegalRepresentative"+String(NumberOfGuestFields+vInd), New TypeDescription("CatalogRef.Clients")));    
		vTempArray.Add(New FormAttribute("LegalRepresentativePresentation"+String(NumberOfGuestFields+vInd), New TypeDescription("String")));
		vTempArray.Add(New FormAttribute("RelationType"+String(NumberOfGuestFields+vInd), New TypeDescription("CatalogRef.RelationTypes")));
		Try
			ChangeAttributes(,vTempArray);
		Except
		EndTry;
		ChangeAttributes(vTempArray);
		// Vertical guest group
		vGuestGroup = Items.Add("Guest"+String(NumberOfGuestFields+vInd)+"Group", Type("FormGroup"), Items.GuestsGroup);
		vGuestGroup.Title = NStr("en='""Guest №';ru='Группа ""Гость №';de='Gruppe ""Gast Nr.'")+String(NumberOfGuestFields+vInd)+NStr("ru='""';en='"" group';de='"" gruppe'");
		vGuestGroup.Type = FormGroupType.UsualGroup;
		vGuestGroup.Representation = UsualGroupRepresentation.None;
		vGuestGroup.Group = ChildFormItemsGroup.Vertical;
		vGuestGroup.ChildItemsWidth = ChildFormItemsWidth.Auto;
		vGuestGroup.BackColor = StyleColors.FormBackColor;
		vGuestGroup.ShowTitle = False;
		// First horizontal guest group
		vGuestGroup = Items.Add("Guest"+String(NumberOfGuestFields+vInd)+"HGroup", Type("FormGroup"), Items["Guest"+String(NumberOfGuestFields+vInd)+"Group"]);
		vGuestGroup.Title = "";
		vGuestGroup.Type = FormGroupType.UsualGroup;
		vGuestGroup.Representation = UsualGroupRepresentation.None;
		vGuestGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
		vGuestGroup.ChildItemsWidth = ChildFormItemsWidth.Auto;
		vGuestGroup.ShowTitle = False;
		// Second horizontal guest group
		vGuestGroup = Items.Add("Guest"+String(NumberOfGuestFields+vInd)+"H1Group", Type("FormGroup"), Items["Guest"+String(NumberOfGuestFields+vInd)+"HGroup"]);
		vGuestGroup.Title = "";
		vGuestGroup.Type = FormGroupType.UsualGroup;
		vGuestGroup.Representation = UsualGroupRepresentation.None;
		vGuestGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
		vGuestGroup.ChildItemsWidth = ChildFormItemsWidth.LeftWidest;
		vGuestGroup.ShowTitle = False;
		// Guest field
		vNewField = Items.Add("SelGuest"+String(NumberOfGuestFields+vInd), Type("FormField"), vGuestGroup);
		vNewField.Type = FormFieldType.InputField;
		vNewField.DataPath = "SelGuest"+String(NumberOfGuestFields+vInd);
		vNewField.Title = NStr("en='Guest №';ru='Гость №';de='Gast Nr.'")+String(NumberOfGuestFields+vInd);
		vNewField.ClearButton = True;
		vNewField.ChoiceButton = True;
		vNewField.OpenButton = True;
		vNewField.SetAction("OnChange", "AddGuestOnChange");
		vNewField.SetAction("StartChoice", "AddGuestStartChoice");
		vNewField.SetAction("Clearing", "AddGuestClearing");
		vNewField.SetAction("Opening", "AddGuestOpening");
		vNewField.SetAction("ChoiceProcessing", "AddGuestChoiceProcessing");
		vNewField.SetAction("AutoComplete", "AddGuestAutoComplete");
		vNewField.SetAction("TextEditEnd", "AddGuestTextEditEnd");
		vNewField.AutoMaxWidth = False;
		vNewField.InputHint = NStr("en='Last name goes first'; ru='Фамилия Имя Отчество'; de='Nachname geht zuerst'");
		// Accommodation type field
		vNewField = Items.Add("AccommodationType"+String(NumberOfGuestFields+vInd), Type("FormField"), vGuestGroup);
		vNewField.Type = FormFieldType.InputField;
		vNewField.Enabled = pObj.IsForFolioSplit;
		vNewField.TextEdit = pObj.IsForFolioSplit;
		vNewField.DataPath = "AccommodationType"+String(NumberOfGuestFields+vInd);
		vNewField.OpenButton = False;
		vNewField.DropListButton = False;
		vNewField.ChoiceButton = True;
		vNewField.ClearButton = False;
		vNewField.SpinButton = False;
		vNewField.CreateButton = False;
		vNewField.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;
		vNewField.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
		vNewField.TitleLocation = FormItemTitleLocation.None;	
		vNewField.Width = 10;
		vNewField.AutoMaxWidth = False;
		// Share percent field
		vNewField = Items.Add("SharePercent"+String(NumberOfGuestFields+vInd), Type("FormField"), vGuestGroup);
		vNewField.Type = FormFieldType.InputField;
		vNewField.Visible = pObj.IsForFolioSplit;
		vNewField.Enabled = True;
		vNewField.TextEdit = True;
		vNewField.DataPath = "SharePercent"+String(NumberOfGuestFields+vInd);
		vNewField.ChoiceButton = False;
		vNewField.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
		vNewField.TitleLocation = FormItemTitleLocation.Right;
		vNewField.Title = "%";
		vNewField.ToolTip = NStr("en='Fraction in % (50, 30, 0...) or fraction like x/y (1/2, 1/3, ...)'; 
		                         |ru='Доля в % (50, 30, 0...) или дробь вида x/y (1/2, 1/3, ...)'; 
								 |de='Fraktion in % (50, 30, 0...) oder Fraktion wie x/y (1/2, 1/3, ...)'");
		vNewField.EditFormat = "NFD=0; NG=";
		vNewField.Width = 3;
		vNewField.AutoMaxWidth = True;
		vNewField.HorizontalStretch = False;
		// Hotel product field
		vNewField = Items.Add("HotelProduct"+String(NumberOfGuestFields+vInd), Type("FormField"), vGuestGroup);
		vNewField.Type = FormFieldType.InputField;
		vNewField.Enabled = UseHotelProducts;
		vNewField.Visible = UseHotelProducts;
		vNewField.Title = NStr("en='Vaucher'; de='Reisescheck'; ru='Путевка'");
		vNewField.TextEdit = True;
		vNewField.DataPath = "HotelProduct"+String(NumberOfGuestFields+vInd);
		vNewField.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;
		vNewField.CreateButton = False;
		vNewField.DropListButton = False;
		vNewField.ChoiceButton = True;
		vNewField.ClearButton = True;
		vNewField.OpenButton = True;
		vNewField.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
		vNewField.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
		vNewField.Width = 12;
		vNewField.AutoMaxWidth = False;
		vNewField.SetAction("OnChange", "ExtraGuestHotelProductOnChange");
		vNewField.SetAction("StartChoice", "ExtraGuestHotelProductStartChoice");
		vNewField.SetAction("Opening", "ExtraGuestHotelProductOpening");
		vNewField.SetAction("Creating", "ExtraGuestHotelProductCreating");
		vNewField.SetAction("ChoiceProcessing", "ExtraGuestHotelProductChoiceProcessing");
		vNewField.SetAction("AutoComplete", "HotelProductAutoComplete");
		vNewField.SetAction("TextEditEnd", "ExtraGuestHotelProductTextEditEnd");
		// Set main guest field
		vNewField = Items.Add("ButtonSetMainGuest"+String(NumberOfGuestFields+vInd), Type("FormButton"), Items["Guest"+String(NumberOfGuestFields+vInd)+"HGroup"]);
		vNewField.Type = FormButtonType.UsualButton;
		vNewField.Enabled = True;
		vNewField.CommandName = "SetMainGuest";
		vNewField.Width = 3;
		vNewField.ShapeRepresentation = ButtonShapeRepresentation.WhenActive;
		vNewField.SkipOnInput = True;
		// Open detailed form button 
		If Items.ButtonOpenDetailedForm1.Visible Then
			vNewField = Items.Add("ButtonOpenDetailedForm"+String(NumberOfGuestFields+vInd), Type("FormButton"), Items["Guest"+String(NumberOfGuestFields+vInd)+"HGroup"]);
			vNewField.Type = FormButtonType.UsualButton;
			vNewField.Enabled = True;
			vNewField.CommandName = "OpenExtraGuestOrdinaryApplicationForm";
			vNewField.Width = 3;
			vNewField.SkipOnInput = True;
		EndIf;
		// Horizontal guest group with foreigner registry record data
		vForeignerGuestGroup = Items.Add("Guest"+String(NumberOfGuestFields+vInd)+"RegistrationGroup", Type("FormGroup"), Items["Guest"+String(NumberOfGuestFields+vInd)+"Group"]);
		vForeignerGuestGroup.Title = "";
		vForeignerGuestGroup.Type = FormGroupType.UsualGroup;
		vForeignerGuestGroup.Representation = UsualGroupRepresentation.None;
		vForeignerGuestGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
		vForeignerGuestGroup.ChildItemsWidth = ChildFormItemsWidth.Auto;
		vForeignerGuestGroup.ShowTitle = False;
		// Guest registration indent
		vNewField = Items.Add("Guest"+String(NumberOfGuestFields+vInd)+"RegistrationIndent", Type("FormDecoration"), Items["Guest"+String(NumberOfGuestFields+vInd)+"RegistrationGroup"]);
		vNewField.Type = FormDecorationType.Label;
		vNewField.Visible = True;
		vNewField.Enabled = True;
		vNewField.Width = 9;
		vNewField.HorizontalAlign = ItemHorizontalLocation.Right;
		vNewField.HorizontalStretch = False;
		// Guest registration action
		vNewField = Items.Add("Guest"+String(NumberOfGuestFields+vInd)+"RegistrationAction", Type("FormDecoration"), Items["Guest"+String(NumberOfGuestFields+vInd)+"RegistrationGroup"]);
		vNewField.Type = FormDecorationType.Label;
		vNewField.Visible = True;
		vNewField.Enabled = True;
		vNewField.Width = 0;
		vNewField.Hyperlink = True;
		vNewField.SetAction("Click", "GuestRegistrationActionClick");
		// Guest registration document
		vNewField = Items.Add("Guest"+String(NumberOfGuestFields+vInd)+"RegistrationDocument", Type("FormField"), Items["Guest"+String(NumberOfGuestFields+vInd)+"RegistrationGroup"]);
		vNewField.Type = FormFieldType.LabelField;
		vNewField.Visible = False;
		vNewField.Enabled = True;
		vNewField.Hyperlink = True;
		vNewField.TitleLocation = FormItemTitleLocation.None;
		vNewField.AutoMaxWidth = False;
		vNewField.DataPath = "Guest"+String(NumberOfGuestFields+vInd)+"Registration";
		// Horizontal guest group with legal representative
		vLegalRepresentativeGuestGroupLine = Items.Add("Group"+String(NumberOfGuestFields+vInd)+"LegalRepresentativeLine", Type("FormGroup"), Items["Guest"+String(NumberOfGuestFields+vInd)+"Group"]);
		vLegalRepresentativeGuestGroupLine.Title = Nstr("en = 'Legal representative row'; de = 'Zeile des gesetzlichen Vertreters'; ru = 'Строка законного представителя'");
		vLegalRepresentativeGuestGroupLine.Type = FormGroupType.UsualGroup;
		vLegalRepresentativeGuestGroupLine.Behavior = UsualGroupBehavior.Usual;
		vLegalRepresentativeGuestGroupLine.Representation = UsualGroupRepresentation.None;
		vLegalRepresentativeGuestGroupLine.Group = ChildFormItemsGroup.AlwaysHorizontal;
		vLegalRepresentativeGuestGroupLine.ChildItemsWidth = ChildFormItemsWidth.Auto;
		vLegalRepresentativeGuestGroupLine.ShowTitle = False;
		vLegalRepresentativeGuestGroupLine.Visible = False;
		// Guest legal representative indent
		vNewField = Items.Add("GuestLegalRepresentativeIndent"+String(NumberOfGuestFields+vInd), Type("FormDecoration"), vLegalRepresentativeGuestGroupLine);
		vNewField.Type = FormDecorationType.Label;
		vNewField.Visible = True;
		vNewField.Enabled = True;
		vNewField.Width = 9;
		vNewField.HorizontalStretch = False;
		// Horizontal guest group with legal representative
		vLegalRepresentativeGuestGroup = Items.Add("Group"+String(NumberOfGuestFields+vInd)+"LegalRepresentative", Type("FormGroup"), vLegalRepresentativeGuestGroupLine);
		vLegalRepresentativeGuestGroup.Title = Nstr("en = 'Legal representative'; de = 'Gesetzlicher Vertreter'; ru = 'Законный представитель'");
		vLegalRepresentativeGuestGroup.Type = FormGroupType.UsualGroup;
		vLegalRepresentativeGuestGroup.Behavior = UsualGroupBehavior.Popup;
		vLegalRepresentativeGuestGroup.ControlRepresentation = UsualGroupControlRepresentation.Picture;
		vLegalRepresentativeGuestGroup.Representation = UsualGroupRepresentation.None;
		vLegalRepresentativeGuestGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
		vLegalRepresentativeGuestGroup.ChildItemsWidth = ChildFormItemsWidth.Auto;
		vLegalRepresentativeGuestGroup.ShowTitle = True;
		vLegalRepresentativeGuestGroup.TitleDataPath = "LegalRepresentativePresentation" + String(NumberOfGuestFields+vInd);
		vLegalRepresentativeGuestGroup.Visible = True;
		// Guest legal representative
		vNewField = Items.Add("LegalRepresentative"+String(NumberOfGuestFields+vInd)+"", Type("FormField"), Items["Group"+String(NumberOfGuestFields+vInd)+"LegalRepresentative"]);
		vNewField.Type = FormFieldType.InputField;
		vNewField.Title = Nstr("en = 'Legal representative'; de = 'Gesetzlicher Vertreter'; ru = 'Законный представитель'"); 
		vNewField.Visible = True;
		vNewField.Enabled = True;
		vNewField.OpenButton = True;
		vNewField.ClearButton = True;
		vNewField.TitleLocation = FormItemTitleLocation.Left;
		vNewField.AutoMaxWidth = False;
		vNewField.DataPath = "LegalRepresentative"+String(NumberOfGuestFields+vInd);
		vNewField.SetAction("OnChange", "LegalRepresentativeOnChange");
		vNewField.SetAction("Clearing", "LegalRepresentativeOnChange");
		// Guest relation type
		vNewField = Items.Add("RelationType"+String(NumberOfGuestFields+vInd)+"", Type("FormField"), Items["Group"+String(NumberOfGuestFields+vInd)+"LegalRepresentative"]);
		vNewField.Type = FormFieldType.InputField;
		vNewField.Title = Nstr("en = 'Relation type'; de = 'Beziehungstyp'; ru = 'Степень родства'"); 
		vNewField.Visible = True;
		vNewField.Enabled = True;
		vNewField.ClearButton = True;
		vNewField.OpenButton = False;
		vNewField.QuickChoice = True;
		vNewField.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
		vNewField.TitleLocation = FormItemTitleLocation.Left;
		vNewField.AutoMaxWidth = False;
		vNewField.DataPath = "RelationType"+String(NumberOfGuestFields+vInd);
		vNewField.SetAction("OnChange", "LegalRepresentativeOnChange");
		vNewField.SetAction("Clearing", "LegalRepresentativeOnChange");
		// Horizontal guest group with changes
		vGuestGroup = Items.Add("Guest"+String(NumberOfGuestFields+vInd)+"ChangesGroup", Type("FormGroup"), Items["Guest"+String(NumberOfGuestFields+vInd)+"Group"]);
		vGuestGroup.Visible = False;
		vGuestGroup.Title = "";
		vGuestGroup.Type = FormGroupType.UsualGroup;
		vGuestGroup.Representation = UsualGroupRepresentation.None;
		vGuestGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
		vGuestGroup.ChildItemsWidth = ChildFormItemsWidth.Auto;
		vGuestGroup.ShowTitle = False;
		// Guest changes indent
		vNewField = Items.Add("GuestChangesIndent"+String(NumberOfGuestFields+vInd), Type("FormDecoration"), Items["Guest"+String(NumberOfGuestFields+vInd)+"ChangesGroup"]);
		vNewField.Type = FormDecorationType.Label;
		vNewField.Visible = True;
		vNewField.Enabled = True;
		vNewField.Width = 9;
		vNewField.HorizontalStretch = False;
		// Guest changes description
		vNewField = Items.Add("GuestChangesDescription"+String(NumberOfGuestFields+vInd), Type("FormField"), Items["Guest"+String(NumberOfGuestFields+vInd)+"ChangesGroup"]);
		vNewField.Type = FormFieldType.LabelField;
		vNewField.Visible = True;
		vNewField.Enabled = True;
		vNewField.Hyperlink = True;
		vNewField.TitleLocation = FormItemTitleLocation.None;
		vNewField.DataPath = "GuestChangesDescription"+String(NumberOfGuestFields+vInd);
		vNewField.SetAction("Click", "GuestChangesDescriptionClick");
		vNewField.AutoMaxWidth = False;
		vNewField.HorizontalStretch = True;
		// Clear changes form button 
		vNewField = Items.Add("ButtonClearChanges"+String(NumberOfGuestFields+vInd), Type("FormButton"), Items["Guest"+String(NumberOfGuestFields+vInd)+"ChangesGroup"]);
		vNewField.Type = FormButtonType.UsualButton;
		vNewField.Visible = True;
		vNewField.Enabled = True;
		vNewField.CommandName = "ClearExtraGuestChanges";
		vNewField.Width = 3;
		vNewField.SkipOnInput = True;
		vNewField.AutoMaxWidth = False;
		vNewField.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	EndDo;
	NumberOfGuestFields = NumberOfGuestFields + pNumberOfFieldsToAdd;
EndProcedure // AddGuestFieldAttributes

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetClientAgeAtServer(pGuest, pCheckInDate)
	vClientAge = cmGetClientAge(pGuest.DateOfBirth, pCheckInDate);
	If vClientAge = 0 And ValueIsFilled(pGuest.DateOfBirth) Then
		vClientAge = 1;
	EndIf;
	Return vClientAge;
EndFunction // GetClientAgeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetClientAge(pGuest = Undefined, pDate, pDateOfBirth=Undefined)
	If pGuest <> Undefined Then
		If Not ValueIsFilled(pGuest.DateOfBirth) Then
			Return 0;
		EndIf;
		vDateOfBirth = pGuest.DateOfBirth;
	Else
		If Not ValueIsFilled(pDateOfBirth) Then
			Return 0;
		EndIf;
		vDateOfBirth = pDateOfBirth;
	EndIf;
	If Not ValueIsFilled(pDate) Then
		Return 0;
	EndIf;
	vAge = Year(pDate) - Year(vDateOfBirth) - 1;
	vBirthDateDayOfYear = DayOfYear(vDateOfBirth);
	vDateDayOfYear = DayOfYear(pDate);
	If vDateDayOfYear >= vBirthDateDayOfYear Then
		vAge = vAge + 1;
	EndIf;
	If vAge < 0 Then
		vAge = 0;
	ElsIf vAge = 0 And ValueIsFilled(vDateOfBirth) Then
		vAge = 1;
	EndIf;
	Return vAge;
EndFunction // GetClientAge

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupStartChoiceEnd(pResult, pAdditionalParameters) Export
	pItem = pAdditionalParameters.pItem;
	vFrmResult = pResult;
	If vFrmResult <> Undefined Then
		Object.GuestGroup = vFrmResult;
		GuestGroupOnChange(pItem);
	EndIf;
EndProcedure // GuestGroupStartChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure FillServicePackagesPresentation()
	TServicePackagesPresentation = "";
	If ValueIsFilled(Object.ServicePackage) And Not Object.ServicePackage.IsMealBoardTerm Then
		TServicePackagesPresentation = TrimAll(Object.ServicePackage.Description);
	EndIf;
	For Each vServicePackageRow In Object.ServicePackages Do
		If ValueIsFilled(vServicePackageRow.ServicePackage) Then
			If IsBlankString(TServicePackagesPresentation) Then
				TServicePackagesPresentation = TrimAll(vServicePackageRow.ServicePackage.Description);
			Else
				TServicePackagesPresentation = TServicePackagesPresentation + ", " + TrimAll(vServicePackageRow.ServicePackage.Description);
			EndIf;
			If vServicePackageRow.Quantity > 1 Then
				TServicePackagesPresentation = TServicePackagesPresentation + " (" + Format(vServicePackageRow.Quantity, "NFD=0; NG=") + ")";
			EndIf;				
			If ValueIsFilled(vServicePackageRow.DateFrom) Or ValueIsFilled(vServicePackageRow.DateTo) Then
				TServicePackagesPresentation = TServicePackagesPresentation + " " + Format(vServicePackageRow.DateFrom, "DF=dd.MM.yy") + " - " + Format(vServicePackageRow.DateTo, "DF=dd.MM.yy");
			EndIf;
		EndIf;
	EndDo;
EndProcedure // FillServicePackagesPresentation

// -----------------------------------------------------------------------------
&AtServer
Function GetServicePackagesListAtServer(pWithoutMealBoardTerms = False)
	vServicePackagesList = New ValueList();
	If ValueIsFilled(Object.ServicePackage) And Not pWithoutMealBoardTerms Then
		vSP = Object.ServicePackage;
		vCheck = True;
		vSPStruct = New Structure("ServicePackage, Quantity, DateFrom, DateTo", vSP, 0, '00010101', '00010101');
		vServicePackagesList.Add(vSPStruct, , vCheck);
	EndIf;
	For Each vSPRow In Object.ServicePackages Do
		If ValueIsFilled(vSPRow.ServicePackage) Then
			vSP = vSPRow.ServicePackage;
			vCheck = True;
			vSPStruct = New Structure("ServicePackage, Quantity, DateFrom, DateTo", vSP, 0, '00010101', '00010101');
			vServicePackagesList.Add(vSPStruct, , vCheck);
		EndIf;
	EndDo;
	// Get all service packages available for use
	vAllowedServicePackagesList = cmGetAllowedServicePackages(Object.Hotel, BegOfDay(Object.CheckInDate), BegOfDay(Object.CheckOutDate), , pWithoutMealBoardTerms, True);
	For Each vAllowedServicePackagesListItem In vAllowedServicePackagesList Do
		vSP = vAllowedServicePackagesListItem.Value;
		vCheck = False;
		vSPStruct = New Structure("ServicePackage, Quantity, DateFrom, DateTo", vSP, 0, '00010101', '00010101');
		vFound = False;
		For Each vServicePackagesListItem In vServicePackagesList Do
			If vServicePackagesListItem.Value.ServicePackage = vSP Then
				vFound = True;
				Break;
			EndIf;
		EndDo;
		If Not vFound Then
			vServicePackagesList.Add(vSPStruct, , vCheck);
		EndIf;
	EndDo;
	Return vServicePackagesList;
EndFunction // GetServicePackagesListAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveServicePackagesListAtServer(pServicePackagesList)
	If ValueIsFilled(Object.ServicePackage) And Not Items.ServicePackage.Visible Then
		Object.ServicePackage = Catalogs.ServicePackages.EmptyRef();
	EndIf;
	If Object.ServicePackages.Count() > 0 Then
		Object.ServicePackages.Clear();
	EndIf;
	If pServicePackagesList.Count() > 0 Then
		vIsFirstItem = True;
		For Each vSPItem In pServicePackagesList Do
			If vSPItem.Check Then
				vSPStruct = vSPItem.Value;
				If vIsFirstItem And Not Items.ServicePackage.Visible And Not vSPStruct.Quantity > 1 And 
				   Not ValueIsFilled(vSPStruct.DateFrom) And Not ValueIsFilled(vSPStruct.DateTo) Then
					vIsFirstItem = False;
					Object.ServicePackage = vSPStruct.ServicePackage;
				Else
					vSPRow = Object.ServicePackages.Add();
					FillPropertyValues(vSPRow, vSPStruct);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If IsNew Then
		// Reset price calculation date
		Object.PriceCalculationDate = '00010101';
	EndIf;
	// Fill service packages presentation
	FillServicePackagesPresentation();
EndProcedure // SaveServicePackagesListAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure FillAmenitiesFromServicePackages(pServicePackagesList)
	vRemarksCheckedAmenities = New ValueList();
	vHousekeepingRemarksCheckedAmenities = New ValueList();
	vRemarksAmenitiesList = GetAmenitiesList(Object.Remarks, 1);
	vHousekeepingRemarksAmenitiesList = GetAmenitiesList(Object.HousekeepingRemarks, 2);
	For Each vServicePackagesListItem In pServicePackagesList Do
		vSP = vServicePackagesListItem.Value.ServicePackage;
		vRemarksAmenity = tcOnServer.cmGetAttributeByRef(vSP, "ReservationRemarksAmenity");
		vHousekeepingRemarksAmenity = tcOnServer.cmGetAttributeByRef(vSP, "ReservationHousekeepingRemarksAmenity");
		If ValueIsFilled(vRemarksAmenity) Then
			For Each vRemarksAmenitiesListItem In vRemarksAmenitiesList Do
				If vRemarksAmenitiesListItem.Value = vRemarksAmenity Then
					If vServicePackagesListItem.Check Then
						vRemarksAmenitiesListItem.Check = True;
						If vRemarksCheckedAmenities.FindByValue(vRemarksAmenity) = Undefined Then
							vRemarksCheckedAmenities.Add(vRemarksAmenity);
						EndIf;
					Else
						If vRemarksCheckedAmenities.FindByValue(vRemarksAmenity) = Undefined Then
							vRemarksAmenitiesListItem.Check = False;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		If ValueIsFilled(vHousekeepingRemarksAmenity) Then
			For Each vHousekeepingRemarksAmenitiesListItem In vHousekeepingRemarksAmenitiesList Do
				If vHousekeepingRemarksAmenitiesListItem.Value = vHousekeepingRemarksAmenity Then
					If vServicePackagesListItem.Check Then
						vHousekeepingRemarksAmenitiesListItem.Check = True;
						If vHousekeepingRemarksCheckedAmenities.FindByValue(vHousekeepingRemarksAmenity) = Undefined Then
							vHousekeepingRemarksCheckedAmenities.Add(vHousekeepingRemarksAmenity);
						EndIf;
					Else
						If vHousekeepingRemarksCheckedAmenities.FindByValue(vHousekeepingRemarksAmenity) = Undefined Then
							vHousekeepingRemarksAmenitiesListItem.Check = False;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	AmenitiesAfterChoice(vRemarksAmenitiesList, "Remarks");
	AmenitiesAfterChoice(vHousekeepingRemarksAmenitiesList, "HousekeepingRemarks");
EndProcedure //  FillAmenitiesFromServicePackages

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicePackagesClearingAtServer(pStandardProcessing)
	If Not Items.ServicePackage.Visible Then
		Object.ServicePackage = Catalogs.ServicePackages.EmptyRef();
	EndIf;
	Object.ServicePackages.Clear();
	// Fill service packages presentation
	FillServicePackagesPresentation();
EndProcedure // ServicePackagesClearingAtServer

// -----------------------------------------------------------------------------
&AtServer
Function NeedToFillPriceChangeReason()
	// Get all active price change reasons
	vNeedToFillPriceChangeReason = False;
	vListOfChangePriceReasons = cmGetAllReasonsForPriceChange();
	If vListOfChangePriceReasons.Count() > 0 Then
		// Choose price change reason
		vPricesRow = Undefined;
		For Each vPrRow In Object.Prices Do
			If ValueIsFilled(vPrRow.Service) And vPrRow.Service.IsRoomRevenue Then
				vPricesRow = vPrRow;
				Break;
			EndIf;
		EndDo;
		vServicesRow = Undefined;
		For Each vSrRow In Object.Services Do
			If ValueIsFilled(vSrRow.Service) And vSrRow.IsManualPrice Then
				vServicesRow = vSrRow;
				Break;
			EndIf;
		EndDo;
		// Check if there are any manual price change
		If ValueIsFilled(Object.RoomTypeUpgrade) Or 
		   vPricesRow <> Undefined Or 
		   vServicesRow <> Undefined Or 
		   ValueIsFilled(Object.DiscountType) Or
		   Object.Discount <> 0 Then
			vNeedToFillPriceChangeReason = True;
		EndIf;
	EndIf;
	Return vNeedToFillPriceChangeReason;
EndFunction // NeedToFillPriceChangeReason

// -----------------------------------------------------------------------------
&AtClient
Procedure FillPriceChangeReason()
	If NeedToFillPriceChangeReason() Then
		If Not ValueIsFilled(Object.PriceChangeReason) Then
			// Ask for price change reason
			vParametersStructure = New Structure("Hotel, PriceChangeReason", Object.Hotel, Object.PriceChangeReason);
			vNotifyDescr = New NotifyDescription("AfterPriceChangeReasonSelection", ThisObject);
			vResultStructure = OpenForm("CommonForm.tcPriceChangeReasonSelection", New Structure("SettingStructure", vParametersStructure), ThisObject, , , , vNotifyDescr, FormWindowOpeningMode.LockWholeInterface);
		EndIf;
	Else
		If ValueIsFilled(Object.PriceChangeReason) Then
			Object.PriceChangeReason = "";
			PriceChangeReason = NStr("en='<price change reason>'; ru='<причина изменения цены>'; de='<Preisänderungsgründe>'");
		EndIf;
	EndIf;
	// Refresh analitical parameters
	BuildThisObjectClientDataDecoration();
EndProcedure // FillPriceChangeReason

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterPriceChangeReasonSelection(pValue, pAdditionalParameters) Export
	If Not pValue = Undefined Then
		vResultStructure = pValue;
		If Object.PriceChangeReason <> vResultStructure.PriceChangeReason Then
			Object.PriceChangeReason = vResultStructure.PriceChangeReason;
			PriceChangeReason = Object.PriceChangeReason;
			If IsBlankString(PriceChangeReason) Then
				PriceChangeReason = NStr("en='<price change reason>'; ru='<причина изменения цены>'; de='<Preisänderungsgründe>'");
			EndIf;
		EndIf;
		BuildThisObjectClientDataDecoration();
		ThisObject.Modified = True;
		ThisObject.RefreshDataRepresentation();
	EndIf;
EndProcedure // AfterPriceChangeReasonSelection

// -----------------------------------------------------------------------------
&AtServer
Function HaveRightsForManualPriceChange()
	Return cmCheckUserPermissions("HavePermissionToAddManualPrices");
EndFunction // HaveRightsForManualPriceChange

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomPriceOnChangeAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	vObj.Prices.Clear();
	If IsManualRoomPrice = 0 Then
		RoomPrice = 0;
		vObj.RoomTypeUpgrade = Catalogs.RoomTypes.EmptyRef();
	ElsIf IsManualRoomPrice = 1 Or IsManualRoomPrice = 3 Then
		If ValueIsFilled(vObj.RoomRate) Then
			vRoomRate = vObj.RoomRate;
		Else
			vRoomRate = vObj.Hotel.RoomRate;
		EndIf;
		vPrices = vRoomRate.GetObject().pmGetRoomRatePrices(vObj.CheckInDate, vObj.PriceCalculationDate, vObj.ClientType, vObj.RoomType, vObj.AccommodationType, , , , , True, , , , vObj.AccommodationTemplate, vObj.IsForFolioSplit);
		If ValueIsFilled(vObj.ClientType) And (vPrices.Count() = 0 Or vPrices.FindRows(New Structure("IsRoomRevenue", True)).Count() = 0) Then
			vPrices = vRoomRate.GetObject().pmGetRoomRatePrices(vObj.CheckInDate, vObj.PriceCalculationDate, Catalogs.ClientTypes.EmptyRef(), vObj.RoomType, vObj.AccommodationType, , , , , True, , , , vObj.AccommodationTemplate, vObj.IsForFolioSplit);
		EndIf;
		If vPrices.Count() > 0 Then
			vNewPrice = vObj.Prices.Add();
			For Each vPricesRow In vPrices Do
				If vPricesRow.IsRoomRevenue And vPricesRow.IsInPrice And Not vPricesRow.RoomRevenueAmountsOnly Then
					vNewPrice.Service = vPricesRow.Service;
					vNewPrice.Unit = vPricesRow.Service.Unit;
					vNewPrice.Currency = vPricesRow.Currency;
					Break;
				EndIf;
			EndDo;
			vNewPrice.Price = RoomPrice;
		EndIf;
		// Terms choice list
		FillServicePackageChoiceList();
	ElsIf IsManualRoomPrice = 2 Then
		RoomPrice = 0;
	EndIf;	
	// Automatic services list calculation
	vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
	// Build room rate group hidden title
	BuildRoomRateGroupCollapsedTitle(vObj);
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // RoomPriceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountOnChangeAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Automatic services list calculation
	vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
	// Terms choice list
	FillServicePackageChoiceList();
EndProcedure // DiscountOnChangeAtServer

// -----------------------------------------------------------------------------
// Check if there are future reservations in chain
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
Procedure CheckIfCheckOutDateTimeIsFilled()
	If ValueIsFilled(CheckOutDateTime) Then
		DetachIdleHandler("CheckIfCheckOutDateTimeIsFilled");
		// Check balances for selected accommodations
		vResultMessage = "";
		vResult = CheckAccommodationsBalances(AccList, vResultMessage);
		If Not IsBlankString(vResultMessage) Then
			tcCommonFunctionOnClientServer.UserMessage(vResultMessage);
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Accommodation.CheckBalances';ru='Размещение.ПроверкаБаланса';de='Accommodation.CheckBalances'"), Undefined, "Documents.Folio", , vResultMessage);
			If Not vResult Then
				Return;
			EndIf;
		EndIf;
		// Check if advances were cleared
		vResultMessage = "";
		vResult = CheckIfAdvancesWereCleared(AccList, vResultMessage);
		If Not IsBlankString(vResultMessage) Then
			tcCommonFunctionOnClientServer.UserMessage(vResultMessage);
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Accommodation.CheckIfAdvancesWereCleared';ru='Размещение.ПроверкаЗачетаАванса';de='Accommodation.CheckIfAdvancesWereCleared'"), Undefined, "Documents.Folio", , vResultMessage);
			If Not vResult Then
				Return;
			EndIf;
		EndIf;
		// Check future reservations
		vMessage = CheckFutureReservationsAtServer(Object.Ref, CheckOutDateTime);
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf;
		// Do check-out
		vResult = CheckOutAtServer(Object.Ref, AccList, CheckOutDateTime, False);
		If ValueIsFilled(vResult) Then
			If vResult = "SendNotifications" Then
				// Send notification to all open forms
				Notify("Subsystem.Accounts.Changed", Object.Ref, ThisObject);
				Notify("Document.ResourceReservation.Write", , ThisObject);
				// Notify that accommodation is changed
				Notify("Document.Accommodation.Write", Object.Ref, ThisObject);
				// Close document form if possible
				If Not ThisObject.Modified And ThisObject.IsOpen() Then
					// Refresh document data
					ThisObject.Read();
					// Open folios list
					OpenFolios(Undefined);
					// Close form
					ThisObject.Close();
				Else
					// Refresh document data
					ThisObject.Read();
					If SavedButNotPostedWhileOpen Then
						ThisObject.Modified = True;
					EndIf;
				EndIf;
			Else
				ShowMessageBox(, vResult);
				// Refresh document data
				ThisObject.Read();
				If SavedButNotPostedWhileOpen Then
					ThisObject.Modified = True;
				EndIf;
			EndIf;
		Else
			// Notify that accommodation is changed
			Notify("Document.Accommodation.Write", Object.Ref, ThisObject);
			// Close document form if possible
			If Not ThisObject.Modified And ThisObject.IsOpen() Then
				// Refresh document data
				ThisObject.Read();
				// Open folios list
				OpenFolios(Undefined);
				// Close form
				ThisObject.Close();
			Else
				// Refresh document data
				ThisObject.Read();
				If SavedButNotPostedWhileOpen Then
					ThisObject.Modified = True;
				EndIf;
			EndIf;
			// Check if we have to print customer folios automatically
			If tcOnServer.cmGetAttributeByRef(Object.Hotel, "PrintCustomerFolioAfterCheckout") Then
				PrintCustomerFolios();
			EndIf;
		EndIf;
	Else
		Return;
	EndIf;
EndProcedure // CheckIfCheckOutDateTimeIsFilled

// -----------------------------------------------------------------------------
&AtServer
Function CheckOutAtServer(pRef, pAccList, pCheckOutDate, pFixReservationConditions)
	vResult = "";
	vCurRoom = Undefined;
	Try
		BeginTransaction(DataLockControlMode.Managed);
		For Each vAccItem In pAccList Do
			vAccDoc = vAccItem.Value;
			// Commit transaction if room has changed
			If vCurRoom <> Undefined And vCurRoom <> vAccDoc.Room Then
				If TransactionActive() Then
					CommitTransaction();
					// Start transaction
					BeginTransaction(DataLockControlMode.Managed);
				EndIf;
			EndIf;
			If vCurRoom <> vAccDoc.Room Then
				vCurRoom = vAccDoc.Room;
			EndIf;
			// Process document
			If vAccDoc.Posted And TypeOf(vAccDoc) = Type("DocumentRef.Accommodation") Then
				vSkipDocument = False;
				If cmCheckUserPermissions("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
					vCheckOutDate = vAccDoc.CheckOutDate;
					If BegOfDay(vCheckOutDate) > BegOfDay(CurrentSessionDate()) Then
						vSkipDocument = True;
					EndIf;
				EndIf;
				If Not vSkipDocument Then
					// Do check-out
					vAccObj = vAccDoc.GetObject();
					If pFixReservationConditions Then
						vAccObj.FixReservationConditions = pFixReservationConditions;
					EndIf;
					vAccObj.pmCheckOut(pCheckOutDate, , vAccObj.IsForFolioSplit);
					vAccObj.Write(DocumentWriteMode.Posting);
					vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					// Hide client name data if necessary
					If vAccObj.pmHideClientNameAndNameHistory() Then
						vResult = "SendNotifications";
					EndIf;
				EndIf;
			Else
				Raise NStr("ru='Отметили в списке размещений для выселения не проведенное размещение! Процедура выселения возможна только для проведенных размещений. Операция отменена.';
				|de='Sie haben in der Unterbringungsliste für die Räumung einer nicht erfolgten Unterbringung markiert! Die Räumung ist nur für erfolgte Unterbringungen möglich. Die Operation wurde abgebrochen.'; 
				|en='You have selected not posted accommodation for check out! Check out procedure is possible for posted accommodations only. Operation is canceled.'");
			EndIf;
			
			// Check if rooms are the same
			If vAccDoc.Room <> vCurRoom Then
				vCurRoom = Undefined;
			EndIf;
		EndDo;
        If TransactionActive() Then
			CommitTransaction();
		EndIf;
	Except
		vErrInfo = ErrorInfo();
		Try
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
		Except
		EndTry;
		WriteLogEvent(NStr("en='Accommodation.CheckOut';ru='Размещение.Выселение';de='Accommodation.CheckOut'"), EventLogLevel.Warning, pRef.Metadata(), pRef, cmGetRootErrorDescription(vErrInfo));
		// Try to save current accommodation with in-house state
		vErrorDescription = cmGetRootErrorDescription(vErrInfo);
		vResult = vErrorDescription;
		If (Find(vErrorDescription, "CHECKOUT_WITH_DEBT") > 0 Or Find(vErrorDescription, "ADVANCES_NOT_CLEARED")) And 
		   vAccDoc <> Undefined Then
			Try
				BeginTransaction(DataLockControlMode.Managed);
				// Do change check-out date and time
				vCurRoom = vAccDoc.Room;
				For Each vAccItem In pAccList Do
					vAccDoc = vAccItem.Value;
					If vCurRoom = vAccDoc.Room Then
						If vAccDoc.Posted And TypeOf(vAccDoc) = Type("DocumentRef.Accommodation") Then
							vSkipDocument = False;
							If cmCheckUserPermissions("HavePermissionToCheckOutOnExpectedCheckOutTime") Then
								vCheckOutDate = vAccDoc.CheckOutDate;
								If BegOfDay(vCheckOutDate) > BegOfDay(CurrentSessionDate()) Then
									vSkipDocument = True;
								EndIf;
							EndIf;
							If Not vSkipDocument Then
								vAccObj = vAccDoc.GetObject();
								If pFixReservationConditions Then
									vAccObj.FixReservationConditions = pFixReservationConditions;
								EndIf;
								vAccObj.CheckOutDate = pCheckOutDate;
								// Calculate duration
								vAccObj.Duration = vAccObj.pmCalculateDuration();
								// Automatic services list calculation
								vAccObj.pmCalculateServices( , , , , , vAccObj.IsForFolioSplit);
								vAccObj.Write(DocumentWriteMode.Posting);
								vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				If TransactionActive() Then
					CommitTransaction();
				EndIf;
			Except
				Try
					If TransactionActive() Then
						RollbackTransaction();
					EndIf;
				Except
				EndTry;
			EndTry;
		EndIf;
	EndTry;
	Return vResult;
EndFunction // CheckOutAtServer

// -----------------------------------------------------------------------------
// Description: Function checks balances for the given accommodations value list
// Parameters: Value list of accommodations
// Return value: Empty string if balances are zero. Message text if balances are not zero.
// -----------------------------------------------------------------------------
&AtServer
Function CheckAccommodationsBalances(pAccList, rResultMessage)
	vResult = True;
	rResultMessage = "";
	vFolios = cmGetDocumentFoliosWithDebts(pAccList);
	If vFolios.Count() > 0 Then
		vThereAreDebts = False;
		vThereAreDeposits = False;
		vDebtsMessage = NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF;
		For Each vFoliosRow In vFolios Do
			vFolioRef = vFoliosRow.Folio;
			If vFoliosRow.SumBalance < 0 Then
				vThereAreDeposits = True;
			ElsIf vFoliosRow.SumBalance > 0 Then
				vThereAreDebts = True;
			EndIf;
			If ValueIsFilled(vFolioRef) Then
				vIsCustomerDebt = False;
				If ValueIsFilled(vFolioRef.Customer) And Not vFolioRef.Customer.IsIndividual Then
					vIsCustomerDebt = True;
				EndIf;
				If vIsCustomerDebt Then
					If Not cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithCustomerDebts") Then
						vResult = False;
					EndIf;
				Else
					If Not cmCheckUserPermissions("HavePermissionToCheckOutAccommodationsWithClientDebts") Then
						vResult = False;
					EndIf;
				EndIf;
				vDebtsMessage = vDebtsMessage + Chars.LF + "#" + TrimAll(vFolioRef.Number) + " " + 
				                TrimAll(vFolioRef.Client) + NStr("ru = ', номер '; en = ', room '; de = ', zimmer '") + 
				                TrimAll(vFolioRef.Room) + NStr("ru = ', период '; en = ', period '; de = ', period '") + 
				                Format(vFolioRef.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
				                Format(vFolioRef.DateTimeTo, "DF='dd.MM.yy HH:mm'") + " = " + 
				                cmFormatSum(vFoliosRow.SumBalance, vFolioRef.FolioCurrency, "NZ=");
			EndIf;
		EndDo;
		If Not vResult Then
			If vThereAreDebts And Not vThereAreDeposits Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEBTS!';ru='ЕСТЬ ЗАДОЛЖЕННОСТЬ!';de='ES LIEGT EINE SCHULD VOR!'");
			ElsIf Not vThereAreDebts And vThereAreDeposits Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEPOSITS!';ru='ЕСТЬ ПЕРЕПЛАТА!';de='ES LIEGT EINE ÜBERZAHLUNG VOR!'");
			Else
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='There are DEBTS AND DEPOSITS!';ru='ЕСТЬ ЗАДОЛЖЕННОСТЬ И ПЕРЕПЛАТА!';de='ES LIEGT EINE SCHULD oder ÜBERZAHLUNG vor!'");
			EndIf;
		Else
			vDebtsMessage = "";
		EndIf;
		rResultMessage = vDebtsMessage;
	EndIf;
	Return vResult;
EndFunction // CheckAccommodationsBalances

// -----------------------------------------------------------------------------
// Description: Function checks if advances cleared was done for the given list of accommodations
// Parameters: Value list of accommodations
// Return value: Empty string if balances are zero. Message text if balances are not zero.
// -----------------------------------------------------------------------------
&AtServer
Function CheckIfAdvancesWereCleared(pAccList, rResultMessage)
	vResult = True;
	rResultMessage = "";
	vDebtsMessage = "";
	If cmCheckUserPermissions("HavePermissionToCheckIfAdvancesClearingIsDone") Then
		vFolios = cmGetDocumentFoliosWithNotClearedAdvances(pAccList);
		If vFolios.Count() > 0 Then
			For Each vFoliosRow In vFolios Do
				vFolioRef = vFoliosRow.Folio;
				If ValueIsFilled(vFolioRef) Then
					vFolioPaymentMethod = vFolioRef.PaymentMethod;
					If ValueIsFilled(vFolioPaymentMethod) And vFolioPaymentMethod.PrintCheque And Not vFolioPaymentMethod.PrintNonFiscalCheque Then
						vResult = False;
						vDebtsMessage = ?(IsBlankString(vDebtsMessage), NStr("en='Folios: ';ru='По лицевым счетам: ';de='Nach Personenkonten: '") + Chars.LF, "");
						vDebtsMessage = vDebtsMessage + Chars.LF + "#" + TrimAll(vFolioRef.Number) + " " + 
						                TrimAll(vFolioRef.Client) + NStr("ru = ', номер '; en = ', room '; de = ', zimmer '") + 
						                TrimAll(vFolioRef.Room) + NStr("ru = ', период '; en = ', period '; de = ', period '") + 
						                Format(vFolioRef.DateTimeFrom, "DF='dd.MM.yy HH:mm'") + " - " + 
						                Format(vFolioRef.DateTimeTo, "DF='dd.MM.yy HH:mm'");
					EndIf;
				EndIf;
			EndDo;
			If Not vResult Then
				vDebtsMessage = vDebtsMessage + Chars.LF + Chars.LF + NStr("en='Advance is not cleared!'; ru='Не выполнен зачет аванса!'; de='Vorauszahlung wurde nicht verrechnet!'");
			EndIf;
			rResultMessage = vDebtsMessage;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // CheckIfAdvancesWereCleared

// -----------------------------------------------------------------------------
// Description: Asks user to enter guest check-out date
// Parameters: Guest check-in date, Guest planned check-out date
// Return value: Check-out date
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
	vOnCloseNotifyDescription = New NotifyDescription("GetCheckOutDateAfterUserInput", ThisObject, New Structure("CheckInDate, CheckOutDate", pCheckInDate, pCheckOutDate));
	vParams = New Structure("FillingValues", New Structure("Date, Time, Description, IsProtected, DateIsProtected", vDate, vTime, vDescription, vIsProtected, vDateIsProtected));
	OpenForm("CommonForm.tcInputDateTime", vParams, ThisObject, , , , vOnCloseNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // GetCheckOutDate

// -----------------------------------------------------------------------------
&AtClient
Procedure GetCheckOutDateAfterUserInput(pCheckOutDateTime, pExtraParameters) Export
	CheckOutDateTime = '00010101';
	// Check check out date and time entered
	If Not ValueIsFilled(pCheckOutDateTime) Then
		ShowMessageBox(, NStr("ru='Процедура выселения отменена!';
		                      |de='Das Ausweisungsverfahren wurde abgebrochen'; 
						      |en='Check-out procedure is canceled!'"));
		Return;
	EndIf;
	If pCheckOutDateTime < pExtraParameters.CheckInDate Then
		ShowMessageBox(, NStr("ru='Ввели дату и время выселения, которые раньше чем дата и время заезда!';
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
			ShowMessageBox(, NStr("ru='Нет прав выселения в прошлом!';
			                      |de='Sie haben ein abreise Datum und Zeit angegeben, das in der Vergangenheit liegt. Sie sind berechtigt, eine Räumung nur am aktuellen oder künftigen Datum vorzunehmen!'; 
			                      |en='You have entered check-out date in the past. You have rights to do check-out by current or future dates only!'"));
			Return;
		EndIf;
	EndIf;
	CheckOutDateTime = pCheckOutDateTime;
EndProcedure // GetCheckOutDateAfterUserInput

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintCustomerFolios()
	vLang = tcOnServer.cmGetSessionParametersAttribute("CurrentLanguage");
	If ValueIsFilled(vLang) Then
		vLangCode = tcOnServer.cmGetAttributeByRef(vLang, "Code");
		vPrintFormName = "AfterCheckoutFolioPrintForm" + Title(TrimAll(vLangCode));
		vPrintFormTypeRef = tcOnServer.cmGetAttributeByRef(Object.Hotel, vPrintFormName);
		If ValueIsFilled(vPrintFormTypeRef) Then
			// Get list of customer folios for this room
			vFoliosList = GetListOfCustomerFolios(Object.Number, Object.GuestGroup);
			If vFoliosList.Count() > 0 Then
				vParams = New Structure("InputParameter, ObjectPrintingForm, Folios", vFoliosList.Get(0).Value, vPrintFormTypeRef, vFoliosList);
				OpenForm("Document.Folio.Form.tcFolioPrintForm", vParams, ThisObject, new UUID);
			EndIf;
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Print form is not specified for language '; ru='Не указана печатная форма для языка '; de='Druckformular ist nicht für die Sprache angegeben '") + Upper(vLangCode) + "!");
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
// Description: Extracts time from the date with time
// Parameters: Date with time
// Return value: Time part of the date
// -----------------------------------------------------------------------------
&AtClient
Function ExtractTime(pDateTime)
	vTime = Date(1, 1, 1, Hour(pDateTime), Minute(pDateTime), 0);
	Return vTime;
EndFunction // ExtractTime

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountTypeOnChangeAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Set discounts
	vObj.pmSetDiscounts();
	// Discount
	If ValueIsFilled(vObj.DiscountType) Then
		vObj.DiscountServiceGroup = vObj.DiscountType.DiscountServiceGroup;
		If vObj.DiscountType.IsAccumulatingDiscount Then
			// Fill manual services accumulation discounts
			For Each vCurRow In vObj.Services Do
				If vCurRow.IsManual Then
					If cmIsServiceInServiceGroup(vCurRow.Service, vObj.DiscountServiceGroup) Then
						vObj.pmCalculateAccumulationDiscountForAdditionalService(vCurRow);
						vObj.pmCalculateServiceDiscounts(vCurRow);
					Else
						vCurRow.DiscountType = Catalogs.DiscountTypes.EmptyRef();
						vCurRow.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
						vCurRow.Discount = 0;
						vCurRow.DiscountConfirmationText = "";
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		If vObj.DiscountType.AskForConfirmation Then
			vObj.DiscountConfirmationText = TrimAll(vObj.DiscountType.ConfirmationPattern) + Char(8226);
		Else
			vObj.DiscountConfirmationText = "";
		EndIf;
		vDiscountTypeObj = vObj.DiscountType.GetObject();
		vObj.Discount = vDiscountTypeObj.pmGetDiscount(vObj.CheckInDate, , vObj.Hotel);
	Else
		vObj.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
		vObj.Discount = 0;
		vObj.DiscountConfirmationText = "";
		// Clear manual services discounts
		For Each vCurRow In vObj.Services Do
			If vCurRow.IsManual And ValueIsFilled(vCurRow.DiscountType) Then
				vCurRow.DiscountType = Catalogs.DiscountTypes.EmptyRef();
				vCurRow.DiscountServiceGroup = Catalogs.ServiceGroups.EmptyRef();
				vCurRow.Discount = 0;
				vCurRow.DiscountConfirmationText = "";
			EndIf;
		EndDo;
	EndIf;
	// Clear manual discounts from the accommodation plan table
	For Each vRRRow In vObj.RoomRates Do
		vRRRow.Discount = "";
	EndDo;
	// Delete empty room rates rows
	vPrevIsBookedOut = False;
	i = 0;
	While i < vObj.RoomRates.Count() Do
		vRRRow = vObj.RoomRates.Get(i);
		If Not vObj.pmDeleteEmptyChangeHistoryRecord(vRRRow, i, vPrevIsBookedOut) Then
			vPrevIsBookedOut = vRRRow.IsBookedOut;
			i = i + 1;
		EndIf;
	EndDo;
	// Automatic services list calculation
	vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
	// Terms choice list
	FillServicePackageChoiceList();
EndProcedure // DiscountTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomTypeUpgradeOnChangeAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Automatic services list calculation
	vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
	// Build room rate group hidden title
	BuildRoomRateGroupCollapsedTitle(vObj);
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
	// Reset description
	ChangeRoomMessageText = "";
EndProcedure // RoomTypeUpgradeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
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
Procedure OpenForeignerRegistryRecordForm(pAccRef)
	If Not ValueIsFilled(pAccRef) Then
		Return;
	EndIf;
	// Check if current guest record exists. If yes then open it
	vMessage = "";
	vRecords = GetForeignerRegistryRecordsList(pAccRef, vMessage);
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndIf;
	// Get last one from the list
	vDocRef = Undefined;
	If vRecords <> Undefined And vRecords.Count() > 0 Then
		vDocRef = vRecords.Get(vRecords.Count()-1).Value;
	EndIf;
	vFrm = Undefined;
	#If ThickClientOrdinaryApplication Then
		If ValueIsFilled(vDocRef) Then
			vFrm = vDocRef.GetForm();
		Else
			// If not then create new
			vFrm = Documents.ForeignerRegistryRecord.GetNewDocumentForm(, ThisObject, pAccRef);
			vFrm.ThisObject.Fill(pAccRef);
			vFrm.CloseOnOwnerClose = False;
		EndIf;
		vFrm.Open();
	#Else
		If ValueIsFilled(vDocRef) Then
			vFrm = OpenForm("Document.ForeignerRegistryRecord.ObjectForm", New Structure("Key", vDocRef), ThisObject, vDocRef);
		Else
			vFrm = OpenForm("Document.ForeignerRegistryRecord.ObjectForm", New Structure("Basis", pAccRef), ThisObject, pAccRef);
		EndIf;
	#EndIf
EndProcedure // OpenForeignerRegistryRecordForm

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
Function GetGroupInvoices(pGuestGroup)
	vDocs = pGuestGroup.GetObject().pmGetSettlements();
	vInvoicesList = New ValueList();
	vInvoicesList.LoadValues(vDocs.UnloadColumn("Invoice"));
	For Each vInvoicesListItem In vInvoicesList Do
		vInv = vInvoicesListItem.Value;
		vInvoicesListItem.Presentation = TrimAll(vInv) + " - " + cmFormatSum(vInv.SumDue, vInv.AccountingCurrency);
	EndDo;
	Return vInvoicesList;
EndFunction // GetGroupInvoices

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
	OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language", pInvoice, vLang), ThisObject, pInvoice);
EndProcedure // PrintInvoice

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
&AtClient
Procedure GroupInvoiceSelection(pInvItem, pExtraParams) Export
	If pInvItem <> Undefined Then
		OpenForm("Document.Settlement.ObjectForm", New Structure("Key", pInvItem.Value), ThisObject, pInvItem.Value);
	EndIf;
EndProcedure // GroupInvoiceSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardAfterUserInput(pCreditCard) Export
	If ValueIsFilled(pCreditCard) Then
		Object.CreditCard = pCreditCard;
		CreditCardPresentation = TrimAll(Object.CreditCard);
		Items.ClearCreditCard.Visible = True;
		ThisObject.Modified = True;
	Else
		CreditCardPresentation = NStr("en='<Credit card>'; ru='<Кредитная карта>'; de='<Kreditkarte>'");
		Items.ClearCreditCard.Visible = False;
	EndIf;
EndProcedure // CreditCardAfterUserInput

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CreateCustomerFromGuest(pGuest)
	vCustomer = Catalogs.Customers.EmptyRef();
	vCreateNew = True;
	// Try to find customer with guest ref
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Customers.Ref AS Ref
	|FROM
	|	Catalog.Customers AS Customers
	|WHERE
	|	NOT Customers.DeletionMark
	|	AND NOT Customers.IsFolder
	|	AND Customers.Client = &qClient
	|	AND Customers.IsIndividual 
	|
	|ORDER BY
	|	Customers.Code DESC";
	vQry.SetParameter("qClient", pGuest);
	vCustomers = vQry.Execute().Unload();
	If vCustomers.Count() > 0 Then
		vCreateNew = False;
		vCustomer = vCustomers.Get(0).Ref;
	EndIf;	
	// Try to find customer with guest full name
	If Not ValueIsFilled(vCustomer) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Customers.Ref AS Ref,
		|	Customers.LegacyName AS LegacyName,
		|	Customers.Description AS Description,
		|	Customers.DateOfBirth AS DateOfBirth,
		|	1 AS SortCode
		|FROM
		|	Catalog.Customers AS Customers
		|WHERE
		|	NOT Customers.DeletionMark
		|	AND NOT Customers.IsFolder
		|	AND Customers.Description = &qDescription
		|	AND Customers.DateOfBirth = &qDateOfBirth
		|	AND Customers.DateOfBirth <> &qEmptyDate
		|
		|UNION ALL
		|
		|SELECT
		|	Customers.Ref,
		|	Customers.LegacyName,
		|	Customers.Description,
		|	Customers.DateOfBirth,
		|	2
		|FROM
		|	Catalog.Customers AS Customers
		|WHERE
		|	NOT Customers.DeletionMark
		|	AND NOT Customers.IsFolder
		|	AND Customers.Description = &qDescription
		|	AND Customers.DateOfBirth = &qEmptyDate
		|
		|ORDER BY
		|	SortCode,
		|	Description";
		vQry.SetParameter("qDescription", Upper(TrimAll(pGuest.FullName)));
		vQry.SetParameter("qDateOfBirth", pGuest.DateOfBirth);
		vQry.SetParameter("qEmptyDate", '00010101');
		vCustomers = vQry.Execute().Unload();
		If vCustomers.Count() > 0 Then
			vCreateNew = False;
			vCustomer = vCustomers.Get(0).Ref;
		EndIf;   
	EndIf;
	If vCreateNew Then
		vCustObj = Catalogs.Customers.CreateItem();
		vIndividualsFolder = Constants.IndividualsFolder.Get();
		If Not ValueIsFilled(vIndividualsFolder) Then
			vIndividualsFolder = Catalogs.Customers.IndividualsFolder;
		EndIf;
		vCustObj.Parent = vIndividualsFolder;
		vCustObj.pmFillAttributesWithDefaultValues();
		vCustObj.Description = pGuest.FullName;
		vCustObj.LegacyName = pGuest.FullName + 
		                      ?(ValueIsFilled(pGuest.DateOfBirth), ", " + Format(pGuest.DateOfBirth, "DF=dd.MM.yyyy"), "") + 
							  ?(IsBlankString(pGuest.IdentityDocumentNumber), "", ", " + TrimAll(pGuest.IdentityDocumentType) + " " + TrimAll(pGuest.IdentityDocumentSeries) + " " + TrimAll(pGuest.IdentityDocumentNumber));
		vCustObj.LegacyAddress = pGuest.Address;
		vCustObj.Phone = pGuest.Phone;
		vCustObj.Fax = pGuest.Fax;
		vCustObj.EMail = pGuest.EMail;
		vCustObj.Language = pGuest.Language;
		vCustObj.IdentityDocumentIssueDate = pGuest.IdentityDocumentIssueDate;
		vCustObj.IdentityDocumentIssuedBy = pGuest.IdentityDocumentIssuedBy;
		vCustObj.IdentityDocumentNumber = pGuest.IdentityDocumentNumber;
		vCustObj.IdentityDocumentSeries = pGuest.IdentityDocumentSeries;
		vCustObj.IdentityDocumentType = pGuest.IdentityDocumentType;
		vCustObj.IdentityDocumentValidToDate = pGuest.IdentityDocumentValidToDate;
		vCustObj.DateOfBirth = pGuest.DateOfBirth;
		vCustObj.Client = pGuest;
		vCustObj.IsIndividual = True;
		vCustObj.pmFillPlannedPaymentMethodFromChargingRules();
		vCustObj.Write();
		vCustObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		
		vCustomer = vCustObj.Ref;
	EndIf;
	Return vCustomer;
EndFunction // CreateCustomerFromGuest

// -----------------------------------------------------------------------------
&AtServer
Function GetGuestDocumentRefByItemID(pItemName)
	vInd = 0;
	vIndStr = Right(pItemName, 2);
	If Not cmIsNumber(vIndStr) Then
		vIndStr = Right(pItemName, 1);
		If Not cmIsNumber(vIndStr) Then
			Return Object.Ref;
		Else
			vInd = Number(vIndStr);
		EndIf;
	Else
		vInd = Number(vIndStr);
	EndIf;
	If vInd = 0 Then
		Return Undefined;
	Else
		vInd = vInd - 2;
		If vInd < 0 Then
			Return Undefined;
		Else
			If vInd > GuestsInGroup.Count() Then
				Return Undefined;
			Else
				If vInd < GuestsInGroup.Count() Then
					Return GuestsInGroup.Get(vInd).Ref;
				Else
					Return Undefined;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndFunction // GetGuestDocumentRefByItemID

// -----------------------------------------------------------------------------
&AtServer
Procedure ExtraGuestAccommodationTypeOnChangeAtServer(pInd = "")
	vInd = Number(pInd) - 2;
	If vInd >= 0 Then
		// Update accommodation type in the guests in group value table
		vGuestsInGroup = FormAttributeToValue("GuestsInGroup");
		vGiGRow = vGuestsInGroup.Get(vInd);
		vGiGRow.AccommodationType = ThisObject["AccommodationType" + String(pInd)];
		ValueToFormAttribute(vGuestsInGroup, "GuestsInGroup");
		// Get object value
		vObj = FormAttributeToValue("Object");
		// Calculate totals
		TotalSum = CalculateTotalServices(vObj, , False, False);
		// Set object value
		ValueToFormAttribute(vObj, "Object");
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
EndProcedure // ExtraGuestAccommodationTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetArrayOfAllClientTypes()
	vCTTable = cmGetAllClientTypes(Object.Hotel);
	vCTArray = vCTTable.UnloadColumn("ClientType");
	Return vCTArray;
EndFunction // GetArrayOfAllClientTypes

// -----------------------------------------------------------------------------
&AtServer
Function GetArrayOfAllSourceOfBusiness()
	vSOBTable = cmGetAllSourcesOfBusiness();
	vSOBArray = vSOBTable.UnloadColumn("SourceOfBusiness");
	Return vSOBArray;
EndFunction // GetListOfAllSourceOfBusiness

// ----------------------------------------------------------------------------
&AtServer
Function GetArrayOfAllTripPurposes()
	vTPTable = cmGetAllTripPurposes();
	vTPArray = vTPTable.UnloadColumn("TripPurpose");
	Return vTPArray;
EndFunction // GetArrayOfAllTripPurposes

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeConfirmationTextChange()
	If ValueIsFilled(Object.ClientType) Then
		If tcOnServer.cmGetAttributeByRef(Object.ClientType, "AskForConfirmation") Then
			Object.ClientTypeConfirmationText = tcOnServer.cmGetAttributeByRef(Object.ClientType, "ConfirmationPattern");
			ShowInputString( New NotifyDescription("AfterClientTypeConfirmationTextChange", ThisObject), 
							Object.ClientTypeConfirmationText,
							NStr("ru='Заполните шаблон строки подтверждения!';
					        |de='Vorlage der Bestätigungszeile ausfüllen!';
	                        |en='Please fill confirmation text pattern!'"),
	                   		100, 
							False); 
		Else
			Object.ClientTypeConfirmationText = "";
			ClientTypeOnChangeAtServer();
			BuildThisObjectClientDataDecoration();
			ThisObject.Modified = True;
		EndIf;
	Else
		Object.ClientTypeConfirmationText = "";
		ClientTypeOnChangeAtServer();
		BuildThisObjectClientDataDecoration();
		ThisObject.Modified = True;
	EndIf;
EndProcedure // ClientTypeConfirmationTextChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterClientTypeConfirmationTextChange(pText, pExtraPerams) Export 
	If pText <> Undefined Then
		Object.ClientTypeConfirmationText = pText;
		If Upper(TrimAll(Object.ClientTypeConfirmationText)) = Upper(TrimAll(tcOnServer.cmGetAttributeByRef(Object.ClientType, "ConfirmationPattern"))) Then
			ShowMessageBox(, NStr("ru='Строка подтверждения совпадает с шаблоном! Выбор типа клиента будет отменен.';
			                  |de='Zeile für die Bestätigung stimmt mit Vorlage überein! Die Auswahl des Kundentyps wird zurückgesetzt!'; 
			                  |en='Confirmation text is the same as confirmation pattern! Client type will be cleared.'"));
			Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
			Object.ClientTypeConfirmationText = "";
		ElsIf IsBlankString(Object.ClientTypeConfirmationText) Then
			ShowMessageBox(,NStr("ru='Строка подтверждения не введена! Выбор типа клиента будет отменен.';
			                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl des Kundentyps wird zurückgesetzt.'; 
							  |en='Confirmation text is not entered! Client type will be cleared.'"));
			Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
			Object.ClientTypeConfirmationText = "";	
		EndIf;
	Else
		ShowMessageBox(, NStr("ru='Строка подтверждения не введена! Выбор типа клиента будет отменен.';
		                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl des Kundentyps wird zurückgesetzt.'; 
						  |en='Confirmation text is not entered! Client type will be cleared.'"));
		Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
		Object.ClientTypeConfirmationText = "";
	EndIf;
	ClientTypeOnChangeAtServer();
	BuildThisObjectClientDataDecoration();
	ThisObject.Modified = True;
EndProcedure // AfterClientTypeConfirmationTextChange

// -----------------------------------------------------------------------------
&AtServer
Function GetAllowedRoomRates()
	vRoomRates = New ValueList();
	If ValueIsFilled(Object.Contract) And Object.Contract.RoomRates.Count() > 0 Then
		vRoomRates.LoadValues(Object.Contract.RoomRates.UnloadColumn("RoomRate"));
	ElsIf ValueIsFilled(Object.Customer) And Object.Customer.RoomRates.Count() > 0 Then
		vRoomRates.LoadValues(Object.Customer.RoomRates.UnloadColumn("RoomRate"));
	EndIf;
	r = 0;
	While r < vRoomRates.Count() Do
		If Not ValueIsFilled(vRoomRates.Get(r).Value) Then
			vRoomRates.Delete(r);
		Else
			r = r + 1;
		EndIf;
	EndDo;
	vRoomRatesAllowed = cmGetAllowedRoomRates(Object.CheckInDate, Object.CheckOutDate, ?(ValueIsFilled(Object.Reservation), Object.Reservation.Date, Object.Date), , Object.Hotel);
	If vRoomRatesAllowed.Count() > 0 Then
		If vRoomRates.Count() > 0 Then
			i = 0;
			While i < vRoomRates.Count() Do
				vFrmRoomRate = vRoomRates.Get(i);
				If vRoomRatesAllowed.FindByValue(vFrmRoomRate.Value) = Undefined Then
					If Not (ValueIsFilled(Object.ParentDoc) And Object.ParentDoc.RoomRate = Object.RoomRate) Then
						vRoomRates.Delete(i);
					Else
						i = i + 1;
					EndIf;
				Else
					i = i + 1;
				EndIf;
			EndDo;
		Else
			vRoomRates.LoadValues(vRoomRatesAllowed.UnloadValues());
		EndIf;
	EndIf;
	Return vRoomRates;
EndFunction // GetAllowedRoomRates

// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCardIsBlocked(vDiscountCard) 
	Return vDiscountCard.IsBlocked;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountCardsEmptyRef()
	  Object.DiscountCard = Catalogs.DiscountCards.EmptyRef();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCheckInDate(vDiscountCard) 
	If BegOfDay(Object.CheckInDate) < vDiscountCard.ValidFrom Or
	   BegOfDay(Object.CheckInDate) >= ?(ValueIsFilled(vDiscountCard.ValidTo), vDiscountCard.ValidTo, EndOfDay(Object.CheckInDate)) Then
		Return True;
	Else 
		Return False;
	EndIf;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCardClient(vDiscountCard) 
	Return vDiscountCard.Client;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function CheckUserPermissions(Bv)
	Return cmCheckUserPermissions(Bv);	
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountCardOnChangeAtServer()
	vObject = FormAttributeToValue("Object", Type("DocumentObject.Accommodation"));
	vObject.pmSetDiscounts();
	BuildDiscountsGroupCollapsedTitle(vObject);
	ValueToFormAttribute(vObject, "Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
	// Terms choice list
	FillServicePackageChoiceList();
EndProcedure // DiscountCardOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetClient(vCard)
	If ValueIsFilled(vCard.Client) Then
		Return vCard.Client;
	Else
		Return Catalogs.Clients.EmptyRef();
	EndIf;
EndFunction

// -----------------------------------------------------------------------------
// Description: Function tries to find and return client identification card by card identifier
// Parameters: Card identifier
// Return value: Client identification card reference or empty reference
// -----------------------------------------------------------------------------
&AtServer
Function GetClientIdentificationCardById(pIdentifier, pUseDeleted = False) 
    Return cmGetClientIdentificationCardById(pIdentifier);
EndFunction // cmGetClientIdentificationCardById

// -----------------------------------------------------------------------------
// Description: Function tries to find and return discount card by card identifier
// Parameters: Card identifier
// Return value: Discount card reference or empty reference
// -----------------------------------------------------------------------------
&AtServer
Function GetDiscountCardById(pIdentifier, pSearchMarkedForDeletion = False) 
	Return cmGetDiscountCardById(pIdentifier);
EndFunction // cmGetDiscountCardById

// -----------------------------------------------------------------------------
&AtServer
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
Function FillParametersCard(pDocRef)
	vParameters = New Structure("Folio, Client, AccommodationType, CheckInDate, CheckOutDate, ParentDoc, Room, IdentityCardSystemParameters");
	
	vCurDoc = pDocRef;
	
	If ValueIsFilled(vCurDoc.Room) Then
		vParameters.Room = vCurDoc.Room;
	EndIf;
	vParameters.CheckInDate = cmGetKeyCardCheckInTime(vCurDoc.CheckInDate, ?(TypeOf(vCurDoc) = Type("DocumentRef.Reservation"), True, False));
	vParameters.CheckOutDate = cmGetLastCheckOutDateInChain(vCurDoc);
	vParameters.Client = vCurDoc.Guest;
	vParameters.AccommodationType = vCurDoc.AccommodationType;
	vParameters.ParentDoc = vCurDoc;
	vCurWstn = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vCurWstn) Then
		If vCurWstn.HasConnectionToIdentityCardsProcessingSystem Then
			vParameters.IdentityCardSystemParameters = vCurWstn.IdentityCardsProcessingSystemParameters;
		EndIf;
	EndIf;
	// Fill folio from the last charging rule
	vParameters.Folio = Documents.Folio.EmptyRef();
	If vCurDoc.ChargingRules.Count() > 0 Then
		vParameters.Folio = vCurDoc.ChargingRules.Get(vCurDoc.ChargingRules.Count()-1).ChargingFolio;
	EndIf;
	Return vParameters;
EndFunction // FillParametersCard

// -----------------------------------------------------------------------------
&AtServerNoContext
Function FillParametersKeyCard(pDocRef)
	Return tcOnServer.cmFillParametersKeyCard(pDocRef);
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function SendWelcomeSMSAtServer()
	vMessage = "";
	vExtSys = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(Object.Hotel);
	If NOT ValueIsFilled(vExtSys) Then
		// the integration with hotel365 is not set
		Return NStr("en = 'Integration with the hotel365 service is not configured'; de = 'Die Integration mit hotel365 ist nicht konfiguriert'; ru = 'Не настроена интеграция с сервисом hotel365'");
	EndIf;
	If NOT vExtSys.IsActive Then
		// the integration with hotel365 is switched off
		Return NStr("en = 'The Integration with hotel365 is switched off'; de = 'Die Integration mit hotel365 ist ausgeschaltet'; ru = 'Интеграция с hotel365 отключена'");
	EndIf;

	If ValueIsFilled(Object.AccommodationStatus) And Object.AccommodationStatus.IsActive And Object.AccommodationStatus.IsCheckIn Then
		// Get list of accommodations to send message to
		vDocsList = New ValueList();
		If ValueIsFilled(Object.Guest) And Object.Guest.NoSMSDelivery Then
			vMessage = vMessage + StrTemplate(NStr("en='Guest %1 refused SMS notifications!'; ru='Гость %1 отказался от СМС оповещений!'; de='Gast %1 hat SMS-Benachrichtigungen abgelehnt'"), TrimAll(Object.Guest));
		Else
			vDocsList.Add(Object.Ref);
		EndIf;
		For Each vRow In GuestsInGroup Do
			If ValueIsFilled(vRow.GuestRef) And vRow.GuestRef <> Object.Guest And ValueIsFilled(vRow.AccommodationStatus) And vRow.AccommodationStatus.IsActive And vRow.AccommodationStatus.IsCheckIn Then
				If vRow.GuestRef.NoSMSDelivery Then
					vMessage = vMessage + StrTemplate(NStr("en='Guest %1 refused SMS notifications!'; ru='Гость %1 отказался от СМС оповещений!'; de='Gast %1 hat SMS-Benachrichtigungen abgelehnt'"), TrimAll(vRow.GuestRef));
					Continue;
				EndIf;
				vPhone = ?(Not IsBlankString(vRow.Ref.Phone), TrimAll(vRow.Ref.Phone), TrimAll(vRow.GuestRef.Phone));
				If Not IsBlankString(vPhone) Then
					vDocsList.Add(vRow.Ref);
				EndIf;
			EndIf;
		EndDo;
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
EndFunction // SendWelcomeSMSAtServer

// -----------------------------------------------------------------------------
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
		|	ClientDataScans.Ref
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
&AtServer
Function CheckForExistingBackgroundJobs()
	Return AsyncCalls.CheckForExistingBackgroundJobsInRegister(Object.Ref);
EndFunction

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomTypeByViewAtServer(pHotel, pRoomTypeClass, pWindowView)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomTypes.Ref
	|FROM
	|	Catalog.RoomTypes AS RoomTypes
	|WHERE
	|	RoomTypes.Owner = &qHotel
	|	AND (&qRoomClassIsFilled
	|				AND RoomTypes.RoomClass = &qRoomClass
	|			OR NOT &qRoomClassIsFilled)
	|	AND (&qViewIsFilled
	|				AND RoomTypes.WindowView = &qView
	|			OR NOT &qViewIsFilled)
	|	AND NOT RoomTypes.IsFolder
	|	AND NOT RoomTypes.DeletionMark
	|
	|ORDER BY
	|	RoomTypes.SortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qRoomClass", pRoomTypeClass);
	vQry.SetParameter("qRoomClassIsFilled", ValueIsFilled(pRoomTypeClass));
	vQry.SetParameter("qView", pWindowView);
	vQry.SetParameter("qViewIsFilled", ValueIsFilled(pWindowView));
	vRoomTypes = vQry.Execute().Unload();
	If vRoomTypes.Count() > 0 Then
		Return vRoomTypes.Get(0).Ref;
	Else
		Return Catalogs.RoomTypes.EmptyRef();
	EndIf;
EndFunction // GetRoomTypeByViewAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicePackageOnChangeAtServer()
	If ValueIsFilled(Object.ServicePackage) And Object.Prices.Count() > 0 Then
		vServicePackage = Object.ServicePackage;
		If vServicePackage.IsMealBoardTerm And ValueIsFilled(vServicePackage.RoomRevenueService) Then
			// 1. Get current room revenue service
			vOldRoomRevenueService = Undefined;
			For Each vSrvRow In Object.Services Do
				If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
					vOldRoomRevenueService = vSrvRow.Service;
					Break;
				EndIf;
			EndDo;
			// 2. Replace old service with the new one
			If ValueIsFilled(vOldRoomRevenueService) Then
				For Each vPricesRow In Object.Prices Do
					If vPricesRow.Service = vOldRoomRevenueService Then
						vPricesRow.Service = vServicePackage.RoomRevenueService;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ServicePackageOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckOverallotment(pObj, rAttrInError = "")
	vMessage = "";
	vIsOverallotment = False;
	vAllotmentBalances = cmGetRoomQuotaBalances(pObj.Hotel, pObj.RoomType, pObj.Customer, pObj.Contract, pObj.Agent, pObj.RoomQuota, pObj.CheckInDate, pObj.CheckOutDate);
	For Each vAllotmentBalancesRow In vAllotmentBalances Do
		If vAllotmentBalancesRow.RemainsRooms <= 0 And BegOfDay(vAllotmentBalancesRow.Period) < BegOfDay(pObj.CheckOutDate) Then
			vIsOverallotment = True;
			Break;
		EndIf;
	EndDo;
	If vIsOverallotment Then
		vOverAllotmentContract = pObj.RoomQuota.OverAllotmentContract;
		vOverAllotmentRoomRate = pObj.RoomQuota.OverAllotmentRoomRate;
		If ValueIsFilled(vOverAllotmentContract) And (Not ValueIsFilled(vOverAllotmentContract.Hotel) Or vOverAllotmentContract.Hotel = pObj.Hotel) Then
			pObj.Customer = vOverAllotmentContract.Owner;
			pObj.Contract = vOverAllotmentContract;
			ContractOnChangeAtServer(pObj, , True);
		Else
			vOverAllotmentContract = Undefined;
		EndIf;
		If ValueIsFilled(vOverAllotmentRoomRate) And (Not ValueIsFilled(vOverAllotmentRoomRate.Hotel) Or vOverAllotmentRoomRate.Hotel = pObj.Hotel) Then
			pObj.RoomRate = vOverAllotmentRoomRate;
			RoomRateOnChangeAtServer(pObj, False);
		Else
			vOverAllotmentRoomRate = Undefined;
		EndIf;
		SetDurationCaption(pObj);
		If ValueIsFilled(pObj.RoomRate) Then
			pObj.RoomRateType = pObj.RoomRate.RoomRateType;
		EndIf;
		If pObj.RoomRate <> SavRoomRate Then
			pObj.PriceCalculationDate = '00010101';
		EndIf;
		SavRoomRate = pObj.RoomRate;
		If ValueIsFilled(vOverAllotmentContract) Then
			vMessage = NStr("en='There will be overcommitment after this reservation! This reservation contract will be changed to '; ru='По выбранной квоте будет перебронирование! Договор в брони будет изменен на '; de='Auf dem gewählten Allotment wird es eine Umbuchung geben! Vertreter in der Reservierung wird geändert zu '") + TrimAll(pObj.Contract);
			rAttrInError = "Contract";
		ElsIf ValueIsFilled(vOverAllotmentRoomRate) Then
			vMessage = NStr("en='There will be overcommitment after this reservation! This reservation room rate will be changed to '; ru='По выбранной квоте будет перебронирование! Тариф в брони будет изменен на '; de='Auf dem gewählten Allotment wird es eine Umbuchung geben! Tarif in der Reservierung wird geändert zu '") + TrimAll(pObj.RoomRate);
			rAttrInError = "RoomRate";
		EndIf;
	EndIf;
	Return vMessage;
EndFunction // CheckOverallotment

// -----------------------------------------------------------------------------
&AtServer
Procedure FillOrders()
	vObject	= Undefined;
	If ValueIsFilled(Object.Ref) Then
		vObject	= Object.Ref;
	ElsIf ValueIsFilled(Object.Reservation) Then
		vObject	= Object.Reservation;
	Else
		TOrders = "";	
		Items.DecorationOrders.Title = TOrders;
		Items.DecorationOrders.Visible = False;
		Return;
	EndIf;
	vDocs = New ValueTable;
	vDocs.Columns.Add("Doc");
	vDocRow = vDocs.Add();
	vDocRow.Doc = vObject;
	While ValueIsFilled(vObject.ParentDoc) Do
		vFindDoc = vDocs.Find(vObject.ParentDoc,"Doc");
		If ValueIsFilled(vFindDoc) Then
			Break;
		Else
			vDocRow = vDocs.Add();
			vDocRow.Doc = vObject.ParentDoc;
			vObject = vObject.ParentDoc; 
		EndIf;
	EndDo;	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 5
	|	SUM(Orders.Sum) AS Sum,
	|	Orders.Service AS Service,
	|	Orders.Type AS Type,
	|	Orders.PointInTime AS PointInTime
	|FROM
	|	Document.Order AS Orders
	|WHERE
	|	Orders.ParentDoc IN(&ParentDoc)
	|	AND NOT ISNULL(Orders.Status.isOrderCancel, FALSE)
	|
	|GROUP BY
	|	Orders.Service,
	|	Orders.Type,
	|	Orders.PointInTime
	|
	|ORDER BY
	|	Orders.PointInTime DESC";
	vQuery.SetParameter("ParentDoc", vDocs.UnloadColumn("Doc"));	
	vQueryResult = vQuery.Execute();	
	vSelectionDetailRecords = vQueryResult.Select();
	TOrders = "";	
	While vSelectionDetailRecords.Next() Do
		TOrders = TOrders + "• " + ?(ValueIsFilled(vSelectionDetailRecords.Service), String(vSelectionDetailRecords.Service), String(vSelectionDetailRecords.Type)) + " - " + vSelectionDetailRecords.Sum + Chars.LF;
	EndDo;
	TOrders = TrimAll(TOrders);
	Items.DecorationOrders.Title = TOrders;
	If IsBlankString(TOrders) Then
		Items.DecorationOrders.Visible = False;
	Else
		Items.DecorationOrders.Visible = True;
	EndIf;
EndProcedure // FillOrders

// -----------------------------------------------------------------------------
&AtServer
Procedure ExtraGuestHotelProductOnChangeAtServer(pInd = "")
	vInd = Number(pInd) - 2;
	If vInd >= 0 Then
		// Update vaucher in the guests in group value table
		vGiGRow = GuestsInGroup.Get(vInd);      
		vCurHotelProduct = ThisObject["HotelProduct" + pInd];
		If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToForbiddenClearHotelProducts") Then   
			If ValueIsFilled(vGiGRow.Ref.HotelProduct) And Not ValueIsFilled(vCurHotelProduct) Then    
				ThisObject["HotelProduct" + pInd] = vGiGRow.Ref.HotelProduct;
				vErrMsg = NStr("en = 'No permission to clear hotel product'; de = 'Keine Erlaubnis zur Freigabe von Hotelprodukten'; ru = 'Нет прав на очистку путевок'");    
				tcCommonFunctionOnClientServer.UserMessage(vErrMsg, , "ThisObject.HotelProduct" + pInd);        
				Return;	
			EndIf;
		EndIf;
		vGiGRow.HotelProduct = vCurHotelProduct;
		// Get object value
		vObj = FormAttributeToValue("Object");
		// Calculate totals
		TotalSum = CalculateTotalServices(vObj, , False, False);
		// Set object value
		ValueToFormAttribute(vObj, "Object");
		// Recalculate footer totals
		CalculateServicesFooterTotals();
	EndIf;
	// Reset vaucher text
	VaucherText = "";
EndProcedure // ExtraGuestHotelProductOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelProductOnChangeAtServer()   
	If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToForbiddenClearHotelProducts") Then   
		If ValueIsFilled(Object.Ref.HotelProduct) And Not ValueIsFilled(Object.HotelProduct) Then  
			Object.HotelProduct = Object.Ref.HotelProduct;
			vErrMsg = NStr("en = 'No permission to clear hotel product'; de = 'Keine Erlaubnis zur Freigabe von Hotelprodukten'; ru = 'Нет прав на очистку путевок'");    
			tcCommonFunctionOnClientServer.UserMessage(vErrMsg, , "Object.HotelProduct");        
			Return;	
		EndIf;
	EndIf;
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Fill room quota
	If ValueIsFilled(vObj.HotelProduct) And Not vObj.HotelProduct.IsFolder Then
		If ValueIsFilled(vObj.HotelProduct.RoomQuota) Then
			vObj.RoomQuota = vObj.HotelProduct.RoomQuota;
			If ValueIsFilled(vObj.RoomQuota.Company) And ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Company) And 
			   vObj.RoomQuota.Company <> SessionParameters.CurrentUser.Company Then
				vObj.RoomQuota = Catalogs.RoomQuotas.EmptyRef();
			EndIf;
			RoomQuotaOnChangeAtServer(, vObj, True);
		EndIf;
		// If fixed cost product and cost is set then switch off automatic discounts
		If vObj.HotelProduct.FixProductCost And vObj.HotelProduct.Sum > 0 Then
			vObj.TurnOffAutomaticDiscounts = True;
		EndIf;
	EndIf;
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Reset vaucher text
	VaucherText = "";
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // HotelProductOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AddZeroResortFeePriceAtServer(pResortFeeService, pResortFeeCurrency, pReason)
	vObj = FormAttributeToValue("Object");
	// Check if this row already exists
	vPRow = vObj.Prices.Find(pResortFeeService, "Service");
	If vPRow = Undefined Then
		// Add row to manual prices
		vPRow = vObj.Prices.Add();
	EndIf;
	vPRow.Service = pResortFeeService;
	vPRow.Price = 0;
	vPRow.Currency = pResortFeeCurrency;
	vPRow.Unit = TrimAll(pResortFeeService.Unit);
	vPRow.Remarks = pReason;
	// Recalculate services
	vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
	// Move object back
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // AddZeroResortFeePriceAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ResortFeeExemptAfterQuery(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.Yes Then
		For Each vGGRow In GuestsInGroup Do
			vGGRow.IsNoResortFee = True;
		EndDo;
	Else
		For Each vGGRow In GuestsInGroup Do
			vGGRow.IsNoResortFee = False;
		EndDo;
	EndIf;
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // ResortFeeExemptAfterQuery

// -----------------------------------------------------------------------------
&AtServer
Function GetResortFeeService(rCurrency, pSilentMode = False)
	vService = Undefined;
	For Each vSrvRow In Object.Services Do
		If ValueIsFilled(vSrvRow.Service) And ValueIsFilled(vSrvRow.Service.QuantityCalculationRule) And 
		  (vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 Or 
		   vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO Or 
		   vSrvRow.Service.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022) Then
			vService = vSrvRow.Service;
			If ValueIsFilled(vSrvRow.FolioCurrency) Then
				rCurrency = vSrvRow.FolioCurrency;
			EndIf;
			Break;
		EndIf;
	EndDo;
	If Not ValueIsFilled(vService) And Not pSilentMode Then
		vUM = New UserMessage();
		vUM.Text = NStr("en='Resort fee service is not found!'; ru='Не найдена услуга курортного сбора!'; de='Kein Kurtax Dienstleistung verfügbar!'");
		vUM.Message();
	EndIf;
	Return vService;
EndFunction // GetResortFeeService

// -----------------------------------------------------------------------------
&AtServer
Function GetClientFeedback(pDoc)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ClientFeedback.Ref AS Ref
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
Procedure AccommodationFillClientFeedback(pAction) 
	If ValueIsFilled(Object.Guest) Then
		// Try to find existing client feedback
		vFeedbackDoc = GetClientFeedback(Object.Ref);
		If ValueIsFilled(vFeedbackDoc) Then
			OpenForm("Document.ClientFeedback.ObjectForm", New Structure("Key", vFeedbackDoc), ThisObject);
		Else
			OpenForm("Document.ClientFeedback.ObjectForm", New Structure("Basis", Object.Ref), ThisObject);
		EndIf;
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Guest is not filled!'; ru='В размещении не указан гость!'; de='Gast ist nicht gefüllt!'"));
	EndIf;
EndProcedure // AccommodationFillClientFeedback

// -----------------------------------------------------------------------------
&AtServer
Procedure FillAccommodationTemplate(pCurrentObject)
	If Not ValueIsFilled(pCurrentObject.AccommodationTemplate) Then
		vAgeArray = New Array;
		If NumberOfKids > 0 Then
			For vInd = 1 To NumberOfKids Do
				Try
					vAge = ThisObject["KidAge"+String(vInd)];
					If vAge > 0 Then
						vAgeArray.Add(vAge);
					EndIf;
				Except
				EndTry;
			EndDo;
		EndIf;
		// Build structure with children ages
		vChildrenAgesStruct = Undefined;
		If ValueIsFilled(pCurrentObject.Contract) Then
			vAllotmentContract = pCurrentObject.Contract;
			If vAllotmentContract.TeenagersMaxAge <> 0 Or vAllotmentContract.ChildrenMaxAge <> 0 Or vAllotmentContract.InfantsMaxAge <> 0 Then
				vChildrenAgesStruct = vAllotmentContract;
			EndIf;
		EndIf;
		// Get active special offers
		vHotel = pCurrentObject.Hotel;
		If vHotel.TeenagersMaxAge <> 0 Or vHotel.ChildrenMaxAge <> 0 Or vHotel.InfantsMaxAge <> 0 Then
			vOffers = cmGetConfirmedSpecialOffersForReservation(pCurrentObject.Ref, pCurrentObject.Hotel, pCurrentObject.RoomRate, pCurrentObject.RoomRateType, pCurrentObject.Guest, pCurrentObject.ClientType, pCurrentObject.Customer, pCurrentObject.CustomerType, pCurrentObject.GuestGroup, pCurrentObject.SourceOfBusiness, pCurrentObject.MarketingCode, pCurrentObject.TripPurpose, pCurrentObject.CheckInDate, pCurrentObject.Duration, pCurrentObject.CheckOutDate, ?(ValueIsFilled(pCurrentObject.GuestGroup), pCurrentObject.GuestGroup.CreateDate, pCurrentObject.Date), pCurrentObject.RoomType);
			For Each vOffersRow In vOffers Do
				vOffer = vOffersRow.SpecialOffer;
				If vOffer.TeenagersMaxAge <> 0 Or vOffer.ChildrenMaxAge <> 0 Or vOffer.InfantsMaxAge <> 0 Then
					vChildrenAgesStruct = vOffer;
					Break;
				EndIf;
			EndDo;
		EndIf;
		// Find accommodation template for the given number of persons and children ages
		vAccommodationTemplate = Undefined;
		vAccommodationTemplates = cmGetAvailableAccommodationTypesWithKidsAges(NumberOfAdults, vAgeArray.Count(), vAgeArray, "", pCurrentObject.Hotel, ?(ValueIsFilled(pCurrentObject.RoomTypeUpgrade), pCurrentObject.RoomTypeUpgrade, pCurrentObject.RoomType), , False, , vChildrenAgesStruct);
		If vAccommodationTemplates <> Undefined Then
			For Each vAccommodationTemplatesRow In vAccommodationTemplates Do
				vAccTemplate = vAccommodationTemplatesRow.AccTemplate;
				If pCurrentObject.IsForFolioSplit = vAccTemplate.IsForFolioSplit Then
					vAccommodationTemplate = vAccTemplate;
					Break;
				EndIf;
			EndDo;
		EndIf;
		If ValueIsFilled(vAccommodationTemplate) Then
			pCurrentObject.AccommodationTemplate = vAccommodationTemplate;
			pCurrentObject.NumberOfAdults = vAccommodationTemplate.NumberOfAdults;
			pCurrentObject.NumberOfTeenagers = vAccommodationTemplate.NumberOfTeenagers;
			pCurrentObject.NumberOfChildren = vAccommodationTemplate.NumberOfChildren;
			pCurrentObject.NumberOfInfants = vAccommodationTemplate.NumberOfInfants;
			UpdateTemplateInChangesPlan(pCurrentObject);
		EndIf;
	EndIf;
EndProcedure // FillAccommodationTemplate

// -----------------------------------------------------------------------------
&AtServer
Procedure RecalculateServicesAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Automatic services list calculation	
	vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
	// Set object payer
	Payer = vObj.pmSetPlannedPaymentMethod(TPayer);
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle(vObj);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // RecalculateServicesAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesChange(pCurRow)
	// Check type of charging rule
	If pCurRow.ChargingRule = PredefinedValue("Enum.ChargingRuleTypes.RoomRevenueAmount") Or 
	   pCurRow.ChargingRule = PredefinedValue("Enum.ChargingRuleTypes.RoomRevenuePrice") Or
	   pCurRow.ChargingRule = PredefinedValue("Enum.ChargingRuleTypes.RoomRevenuePriceByRoomType") Or 
	   pCurRow.ChargingRule = PredefinedValue("Enum.ChargingRuleTypes.RoomRevenuePricePercent") Then
		// Check next charging rule row
		vCurIndex = Object.ChargingRules.IndexOf(pCurRow);
		If (vCurIndex + 1) < Object.ChargingRules.Count() Then
			vNextRow = Object.ChargingRules[vCurIndex + 1];
			If vNextRow <> Undefined And vNextRow.ChargingRule <> PredefinedValue("Enum.ChargingRuleTypes.RestOfRoomRevenuePrice") Then
				vNewRow = Object.ChargingRules.Insert(vCurIndex + 1);
				FillPropertyValues(vNewRow, vNextRow);
				vNewRow.ChargingRule = PredefinedValue("Enum.ChargingRuleTypes.RestOfRoomRevenuePrice");
				vNewRow.ChargingRuleValue = Undefined;
			EndIf;
		EndIf;
	EndIf;
	// Recalculate services	
	RecalculateServicesAtServer();
EndProcedure // ChargingRulesChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChangeChargingRules(pValue, pCurRow) Export 
	If pValue <> Undefined Then
		FillPropertyValues(pCurRow, pValue);
		ChargingRulesChange(pCurRow);
	Else
		If Not ValueIsFilled(pCurRow.ChargingFolio) Or Not ValueIsFilled(pCurRow.ChargingRule) Then
			Object.ChargingRules.Delete(Object.ChargingRules.IndexOf(pCurRow));
			// Recalculate services	
			RecalculateServicesAtServer();
		EndIf;
	EndIf;
EndProcedure // AfterChangeChargingRules

// -----------------------------------------------------------------------------
&AtServer
Function ChargingRulesAddRowAtServer()
	vNewRow = Object.ChargingRules.Insert(0);
	Return vNewRow.GetID();
EndFunction // ChargingRulesAddRowAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesServiceOnChangeAtServer(pCurrentRow)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined And ValueIsFilled(vCurData.Service) Then
		vObj = FormAttributeToValue("Object");
		// Check service charging rules
		vChargingRules = Object.ChargingRules.Unload();
		If Not Object.IgnoreGroupChargingRules Then
			cmAddGuestGroupChargingRules(vChargingRules, Object.GuestGroup);
		EndIf;
		vObj.pmSetServiceFolioBasedOnChargingRules(vCurData, vChargingRules, True);
		If ValueIsFilled(vCurData.Folio) Then
			vCurData.FolioCurrency = vCurData.Folio.FolioCurrency;
			vCurData.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, vCurData.FolioCurrency, ?(ValueIsFilled(vCurData.AccountingDate), vCurData.AccountingDate, Object.ExchangeRateDate));
		EndIf;
		// Get service parameters
		vCurPrice = vCurData.Price;
		vCurUnit = vCurData.Service.Unit;
		vCurCurrency = vCurData.FolioCurrency;
		vCompany = Object.Company;
		If ValueIsFilled(vCurData.Folio) And vCurData.Folio.DoNotUpdateCompany Then
			vCompany = vCurData.Folio.Company;
		EndIf;
		vCurVATRate = vCompany.VATRate;
		vCurData.Company = vCompany;
		vSrvPrices = vCurData.Service.GetObject().pmGetServicePrices(Object.Hotel, vCurData.AccountingDate, 
		                                                             Object.ClientType); 
		For Each vSrvPricesRow In vSrvPrices Do
			If vSrvPricesRow.Price <> 0 Then
				vCurPrice = vSrvPricesRow.Price;
				vCurCurrency = vSrvPricesRow.Currency;
			EndIf;
			vCurUnit = vCurData.Service.Unit;
			If Not vCompany.IsUsingSimpleTaxSystem Then
				vCurVATRate = vSrvPricesRow.VATRate;
			EndIf;
			Break;
		EndDo;
		vCurData.Price = Round(cmConvertCurrencies(vCurPrice, vCurCurrency, , 
		                                           vCurData.FolioCurrency, 
		                                           vCurData.FolioCurrencyExchangeRate, 
		                                           ?(ValueIsFilled(vCurData.AccountingDate), vCurData.AccountingDate, Object.ExchangeRateDate), Object.Hotel), 2);
		If vCurData.IsManual Then
			vCurData.Unit = vCurUnit;
			vCurData.VATRate = vCurVATRate;
			vCurData.IsRoomRevenue = vCurData.Service.IsRoomRevenue;
			vCurData.IsResourceRevenue = vCurData.Service.IsResourceRevenue;
			vCurData.RoomRevenueAmountsOnly = vCurData.Service.RoomRevenueAmountsOnly;
			vCurData.IsInPrice = vCurData.Service.IsInPrice;
		EndIf;
		cmPriceOnChange(vCurData.Price, vCurData.Quantity, vCurData.Sum, vCurData.VATRate, vCurData.VATSum, vCurData.AccountingDate);
		If ValueIsFilled(Object.DiscountType) Or Object.Discount <> 0 Then
			If cmIsServiceInServiceGroup(vCurData.Service, Object.DiscountServiceGroup) Then
				vCurData.DiscountType = Object.DiscountType;
				vCurData.DiscountServiceGroup = Object.DiscountServiceGroup;
				If Object.DiscountType.IsAccumulatingDiscount Then
					vObj.pmCalculateAccumulationDiscountForAdditionalService(vCurData);
				ElsIf Object.DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
					vCurData.Discount = Object.DiscountType.GetObject().pmGetDiscount(vCurData.AccountingDate, vCurData.Service, Object.Hotel);
				Else
					vCurData.Discount = Object.Discount;
				EndIf;
			EndIf;
		EndIf;
		vObj.pmCalculateServiceDiscounts(vCurData);
		// Calculate commission for this service if applicable
		vComplexCommission = vObj.pmGetComplexCommission();
		vRoomRates = vObj.pmGetAccommodationPlan();
		vObj.pmSetServiceCommissions(vCurData, vRoomRates, vComplexCommission);
		// Set manual price 
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
		EndIf;
		// Recalculate rate sum
		UpdateRowRateSumAtServer(vObj, vCurData.LineNumber);
		// Fill service composition
		If Not IsBlankString(vCurData.Service.Composition) Then
			vCurData.Remarks = TrimAll(vCurData.Service.Composition);
		EndIf;
		// Fill resource and service times
		If ValueIsFilled(vCurData.Service.Resource) And Not ValueIsFilled(vCurData.ServiceResource) And ValueIsFilled(vCurData.AccountingDate) Then
			vCurData.ServiceResource = vCurData.Service.Resource;
			vResourceObj = vCurData.ServiceResource.GetObject();
			vDefaultTimes = vResourceObj.pmGetResourceDefaultChargingTimes(vCurData.AccountingDate);
			vCurData.TimeFrom = vDefaultTimes.TimeFrom;
			vCurData.TimeTo = vDefaultTimes.TimeTo;
			vCurData.DoResourceReservation = True;
		EndIf;
		// Check if user can edit service price
		Items.FixedChargesPrice.ReadOnly = False;
		If Not vCurData.Service.AllowChangePrice Then
			If Not cmCheckUserPermissions("HavePermissionToEditServicePrices") Then
				Items.FixedChargesPrice.ReadOnly = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ServicesServiceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesPriceOnChangeAtServer(pCurrentRow, pDoNotRecalcTotals = False)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		cmPriceOnChange(vCurData.Price, vCurData.Quantity, vCurData.Sum, vCurData.VATRate, vCurData.VATSum, vCurData.AccountingDate);
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
		EndIf;
		vObj = FormAttributeToValue("Object");
		// Recalculate discounts
		vObj.pmCalculateServiceDiscounts(vCurData);
		// Recalculate commissions
		vObj.pmCalculateServiceCommissions(vCurData);
		// Recalculate rate sum
		UpdateRowRateSumAtServer(vObj, vCurData.LineNumber);
		// Calculate totals
		If Not pDoNotRecalcTotals Then
			TotalSum = CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // ServicesPriceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesQuantityOnChangeAtServer(pCurrentRow, pDoNotRecalcTotals = False)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		// Mark service as changed manually
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
			vCurData.QuantityIsChanged = True;
		EndIf;
		// Recalculate service sum and VAT sum
		cmQuantityOnChange(vCurData.Price, vCurData.Quantity, vCurData.Sum, vCurData.VATRate, vCurData.VATSum);
		vObj = FormAttributeToValue("Object");
		// Recalculate service room sales parameters
		cmRecalculateServiceRoomSalesParameters(vCurData, Object);
		// Recalculate discounts
		vObj.pmCalculateServiceDiscounts(vCurData);
		// Recalculate commissions
		vObj.pmCalculateServiceCommissions(vCurData);
		// Recalculate rate sum
		UpdateRowRateSumAtServer(vObj, vCurData.LineNumber);
		// Calculate totals
		If Not pDoNotRecalcTotals Then
			TotalSum = CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // ServicesQuantityOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesSumOnChangeAtServer(pCurrentRow, pDoNotRecalcTotals = False)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		vCurQuantity = vCurData.Quantity;
		cmSumOnChange(vCurData.Service, vCurData.Price, vCurData.Quantity, vCurData.Sum, vCurData.VATRate, vCurData.VATSum, , vCurData.AccountingDate);
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
			If vCurData.Quantity <> vCurQuantity Then
				vCurData.QuantityIsChanged = True;
			EndIf;
		EndIf;
		vObj = FormAttributeToValue("Object");
		// Recalculate discounts
		vObj.pmCalculateServiceDiscounts(vCurData);
		// Recalculate commissions
		vObj.pmCalculateServiceCommissions(vCurData);
		// Recalculate rate sum
		UpdateRowRateSumAtServer(vObj, vCurData.LineNumber);
		// Calculate totals
		If Not pDoNotRecalcTotals Then
			TotalSum = CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // ServicesSumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesDiscountOnChangeAtServer(pCurrentRow, pDoNotRecalcTotals = False)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
			vCurData.DiscountIsChanged = True;
		EndIf;
		vObj = FormAttributeToValue("Object");
		// Recalculate discounts
		vObj.pmCalculateServiceDiscounts(vCurData);
		// Recalculate commissions
		vObj.pmCalculateServiceCommissions(vCurData);
		// Recalculate rate sum
		UpdateRowRateSumAtServer(vObj, vCurData.LineNumber);
		// Calculate totals
		If Not pDoNotRecalcTotals Then
			TotalSum = CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // ServicesDiscountOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesDiscountSumOnChangeAtServer(pCurrentRow, pDoNotRecalcTotals = False)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		vCurData.VATDiscountSum = cmCalculateVATSum(vCurData.VATRate, vCurData.DiscountSum, vCurData.AccountingDate);
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
			vCurData.DiscountIsChanged = True;
		EndIf;
		vObj = FormAttributeToValue("Object");
		// Recalculate commissions
		vObj.pmCalculateServiceCommissions(vCurData);
		// Recalculate rate sum
		UpdateRowRateSumAtServer(vObj, vCurData.LineNumber);
		// Calculate totals
		If Not pDoNotRecalcTotals Then
			TotalSum = CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // ServicesDiscountSumOnChangeAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure ServicesVATRateOnChangeAtServer(pCurrentRow, pDoNotRecalcTotals = False)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		vCurData.VATSum = cmCalculateVATSum(vCurData.VATRate, vCurData.Sum, vCurData.AccountingDate);
		vCurData.VATDiscountSum = cmCalculateVATSum(vCurData.VATRate, vCurData.DiscountSum, vCurData.AccountingDate);
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
		EndIf;
		vObj = FormAttributeToValue("Object");
		// Recalculate commissions
		vObj.pmCalculateServiceCommissions(vCurData);
		// Recalculate rate sum
		UpdateRowRateSumAtServer(vObj, vCurData.LineNumber);
		// Calculate totals
		If Not pDoNotRecalcTotals Then
			TotalSum = CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // ServicesVATRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesAgentCommissionOnChangeAtServer(pCurrentRow, pDoNotRecalcTotals = False)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
			vCurData.CommissionIsChanged = True;
		EndIf;
		vObj = FormAttributeToValue("Object");
		// Recalculate commissions
		vObj.pmCalculateServiceCommissions(vCurData);
		// Recalculate rate sum
		UpdateRowRateSumAtServer(vObj, vCurData.LineNumber);
		// Calculate totals
		If Not pDoNotRecalcTotals Then
			TotalSum = CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // ServicesAgentCommissionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesCommissionSumOnChangeAtServer(pCurrentRow, pDoNotRecalcTotals = False)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
			vCurData.CommissionIsChanged = True;
		EndIf;
		vCurData.VATCommissionSum = cmCalculateVATSum(vCurData.VATRate, vCurData.CommissionSum, vCurData.AccountingDate);
		// Recalculate rate sum
		vObj = FormAttributeToValue("Object");
		UpdateRowRateSumAtServer(vObj, vCurData.LineNumber);
		// Calculate totals
		If Not pDoNotRecalcTotals Then
			TotalSum = CalculateTotalServices();
		EndIf;
	EndIf;
EndProcedure // ServicesCommissionSumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesServiceResourceOnChangeAtServer(pCurrentRow)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.ServiceResource) And TypeOf(vCurData.ServiceResource) = Type("CatalogRef.Resources") Then
			If Not ValueIsFilled(vCurData.TimeFrom) And Not ValueIsFilled(vCurData.TimeTo) Then
				vResourceObj = vCurData.ServiceResource.GetObject();
				vDefaultTimes = vResourceObj.pmGetResourceDefaultChargingTimes(vCurData.AccountingDate);
				vCurData.TimeFrom = vDefaultTimes.TimeFrom;
				vCurData.TimeTo = vDefaultTimes.TimeTo;
			EndIf;
			If ValueIsFilled(vCurData.Service) And vCurData.Service.Resource = vCurData.ServiceResource Then
				vCurData.DoResourceReservation = True;
			EndIf;
			If Not vCurData.IsManual Then
				vCurData.IsManualPrice = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ServicesServiceResourceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesTimeFromOnChangeAtServer(pCurrentRow)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		If vCurData.Quantity > 0 And ValueIsFilled(vCurData.TimeFrom) And Not ValueIsFilled(vCurData.TimeTo) Then
			vCurData.TimeTo = vCurData.TimeFrom + vCurData.Quantity*3600;
		EndIf;
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
		EndIf;
	EndIf;
EndProcedure // ServicesTimeFromOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesTimeToOnChangeAtServer(pCurrentRow)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
		EndIf;
	EndIf;
EndProcedure // ServicesTimeToOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DecorationTotalSumClickAtServer()
	ThisObject.Modified = True;
	// Calculate totals
	TotalSum = CalculateTotalServices(, False, False, True, True);
	// Refresh grid
	FillGridAtServer();
EndProcedure // DecorationTotalSumClickAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
		vResRef = Object.Reservation;
		vGuestsToCheckInList = GuestsToCheckInList.Copy();
		FreeLockedDocs(vResRef, vGuestsToCheckInList, GuestsInGroup.Count(), ThisObject.UUID);
	EndIf;    
	If WasChanged = False Then
		vEventDescription = NStr("en = 'View document'; de = 'Ein Dokument anzeigen'; ru = 'Просмотр документа'");
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Object.Ref, vEventDescription, Object.Hotel);  
	EndIf;
EndProcedure // OnCloseAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure FreeLockedDocs(pObjectReservation, pGuestsToCheckInList, pGuestsInGroupCount, pThisObjectUUID)
	// Unlock all locked reservation objects
	If ValueIsFilled(pObjectReservation) Then
		UnlockDataForEdit(pObjectReservation, pThisObjectUUID);
	EndIf;
	If pGuestsToCheckInList.Count() > 0 Then
		i = 1;
		While i <= pGuestsInGroupCount Do
			If i < pGuestsToCheckInList.Count() Then
				vReservation = pGuestsToCheckInList.Get(i).Value;
				UnlockDataForEdit(vReservation, pThisObjectUUID);
			EndIf;
			i = i + 1;
		EndDo;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SetDurationCaption(pObj = Undefined)
	vObj = Object;
	If pObj <> Undefined Then
		vObj = pObj;
	EndIf;
	If ValueIsFilled(vObj.RoomRate) Then
		If vObj.RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
			Items.DurationGroup.Title = NStr("en='days'; ru='дней'; de='Tage'");
		ElsIf vObj.RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByNights Or 
			  vObj.RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			Items.DurationGroup.Title = NStr("en='nights'; ru='ночей'; de='Nächte'");
		ElsIf vObj.RoomRate.DurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByHours Then
			Items.DurationGroup.Title = NStr("en='hours'; ru='часов'; de='Stunden'");
		Else
			Items.DurationGroup.Title = NStr("en='dur.'; ru='прод.'; de='Dauer'");
		EndIf;
	Else
		Items.DurationGroup.Title = NStr("en='dur.'; ru='прод.'; de='Dauer'");
	EndIf;
EndProcedure // SetDurationCaption

// -----------------------------------------------------------------------------
&AtServer
Procedure AccommodationTemplateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	vTemplate = vObj.AccommodationTemplate;
	If ValueIsFilled(vTemplate) Then
		vObj.NumberOfAdults = vTemplate.NumberOfAdults;
		vObj.NumberOfTeenagers = vTemplate.NumberOfTeenagers;
		vObj.NumberOfChildren = vTemplate.NumberOfChildren;
		vObj.NumberOfInfants = vTemplate.NumberOfInfants;
		// Update accommodation types
		For i = 0 To (vTemplate.AccommodationTypes.Count() - 1) Do
			vTemplateRow = vTemplate.AccommodationTypes.Get(i);
			If i = 0 Then
				vObj.AccommodationType = vTemplateRow.AccommodationType;
				// Update first room rates row
				If ValueIsFilled(vObj.AccommodationType) And vObj.RoomRates.Count() > 0 Then
					v1RRRow = vObj.RoomRates.Find(BegOfDay(vObj.CheckInDate), "AccountingDate");
					If v1RRRow = Undefined Then
						v1RRRow = vObj.RoomRates.Insert(0);
						v1RRRow.AccountingDate = BegOfDay(vObj.CheckInDate);
					EndIf;
					v1RRRow.AccommodationType = vObj.AccommodationType;
					vObj.RoomRates.Sort("AccountingDate, ChangeTime");
				EndIf;
				// Calculate resources
				vObj.pmCalculateResources();
				// Is folio split
				If vObj.IsForFolioSplit <> vTemplate.IsForFolioSplit Then
					vObj.IsForFolioSplit = vTemplate.IsForFolioSplit;
				EndIf;
			ElsIf i <= GuestsInGroup.Count() Then
				ThisObject["AccommodationType" + String(i + 1)] = vTemplateRow.AccommodationType;
				vGiGRow = GuestsInGroup.Get(i - 1);
				vGiGRow.AccommodationType = vTemplateRow.AccommodationType;
			EndIf;
		EndDo;
		// If number of persons in template is less then number of persons in the reservation then set folio split flag for leftovers
		If vTemplate.AccommodationTypes.Count() < (GuestsInGroup.Count() + 1) Then
			For i = (vTemplate.AccommodationTypes.Count() - 1) To (GuestsInGroup.Count() - 1) Do
				vGiGRow = GuestsInGroup.Get(i);
				vGiGRow.pIsForFolioSplit = True;
				vGiGRow.IsForFolioSplitIsDifferent = True;
			EndDo;
		EndIf;
		// Calculate totals
		TotalSum = CalculateTotalServices(vObj, , False, False);
	Else
		vObj.NumberOfAdults = 0;
		vObj.NumberOfTeenagers = 0;
		vObj.NumberOfChildren = 0;
		vObj.NumberOfInfants = 0;
	EndIf;
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Recalculate footer totals
	CalculateServicesFooterTotals();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomRatesAccommodationTemplateOnChangeAtServer()
	vCurRow = Items.RoomRates.CurrentRow;
	If vCurRow = Undefined Then
		Return;
	EndIf;
	vCurData = Object.RoomRates.FindByID(vCurRow);
	vTemplate = vCurData.AccommodationTemplate;
	If ValueIsFilled(vTemplate) Then
		vCurData.NumberOfAdults = vTemplate.NumberOfAdults;
		vCurData.NumberOfTeenagers = vTemplate.NumberOfTeenagers;
		vCurData.NumberOfChildren = vTemplate.NumberOfChildren;
		vCurData.NumberOfInfants = vTemplate.NumberOfInfants;
	Else
		vCurData.NumberOfAdults = 0;
		vCurData.NumberOfTeenagers = 0;
		vCurData.NumberOfChildren = 0;
		vCurData.NumberOfInfants = 0;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesAccommodationTemplateOnChange(Item)
	RoomRatesAccommodationTemplateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildCommissionGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If pObj = Undefined Then
		vObj = Object;
	EndIf;
	If vObj.Agent.IsEmpty() Then
		Items.GroupAgentCommission.CollapsedRepresentationTitle = NStr("en='Agent: ';ru='Агент: ';de='Vertreter: '") + ?(ValueIsFilled(vObj.Agent), TrimAll(vObj.Agent), NStr("en='<empty>';ru='<пусто>';de='<leer>'"));
	Else
		vAgentCommissionPresentation = TrimAll(vObj.AgentCommission);
		If ValueIsFilled(vObj.Agent) Then
			If vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.Percent") Then
				vAgentCommissionPresentation = TrimAll(vObj.AgentCommission) + NStr("en='%';ru='%';de='%'");
			ElsIf vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.FirstDayPercent") Then
				vAgentCommissionPresentation = TrimAll(vObj.AgentCommission) + NStr("en='% for the 1-st day';ru='% за 1-ый день';de='% für den ersten Tag'");
			ElsIf vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.AmountPerCheckInPerClient") Then
				vAgentCommissionPresentation = cmFormatSum(vObj.AgentCommission, vObj.Agent.AccountingCurrency) + NStr("en=' per guest per check-in';ru=' за гостя за заезд';de=' pro Gast pro Check-in'");
			ElsIf vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.AmountPerCheckInPerRoom") Then
				vAgentCommissionPresentation = cmFormatSum(vObj.AgentCommission, vObj.Agent.AccountingCurrency) + NStr("en=' per room per check-in';ru=' за номер за заезд';de=' pro Zimmer pro Check-in'");
			ElsIf vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.AmountPerDayPerClient") Then
				vAgentCommissionPresentation = cmFormatSum(vObj.AgentCommission, vObj.Agent.AccountingCurrency) + NStr("en=' per guest per night';ru=' за гостя за ночь';de=' pro Gast pro Nacht'");
			ElsIf vObj.AgentCommissionType = PredefinedValue("Enum.AgentCommissionTypes.AmountPerDayPerRoom") Then
				vAgentCommissionPresentation = cmFormatSum(vObj.AgentCommission, vObj.Agent.AccountingCurrency) + NStr("en=' per room per night';ru=' за номер за ночь';de=' pro Zimmer pro Nacht'");
			EndIf;
		EndIf;
		Items.GroupAgentCommission.CollapsedRepresentationTitle = NStr("en='Agent: ';ru='Агент: ';de='Vertreter: '") + ?(ValueIsFilled(vObj.Agent), TrimAll(vObj.Agent), NStr("en='<empty>';ru='<пусто>';de='<leer>'")) + 
		                                                          " • " + NStr("en='Commission ';ru='Комиссия ';de='Kommission '") + ?(ValueIsFilled(vObj.AgentCommission), vAgentCommissionPresentation, NStr("en='<empty>';ru='<пусто>';de='<leer>'")) + 
		                                                          NStr("en=' for ';ru=' за ';de=' für '") + ?(ValueIsFilled(vObj.AgentCommissionServiceGroup), TrimAll(vObj.AgentCommissionServiceGroup), NStr("en='all services';ru='все услуги';de='alle Dienstleistungen'"));
	EndIf;
EndProcedure // BuildCommissionGroupCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildAccountingGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	vTitle = NStr("en='Pays: '; ru='Платит: '; de='Zahler: '") + TrimAll(Payer) + 
			 ?(Payer = Enums.WhoPays.Customer, " " + TrimAll(vObj.Customer) + ?(ValueIsFilled(vObj.Contract), ", " + TrimAll(vObj.Contract), ""), ?(Payer = Enums.WhoPays.Agent, " " + TrimAll(vObj.Agent), "")) + 
	         NStr("en=' by '; ru=', '; de=', '") + TrimAll(vObj.PlannedPaymentMethod) + 
	         NStr("en=' to '; ru=' фирме: '; de=' an '") + TrimAll(vObj.Company) + 
			 ?(IsBlankString(vObj.ContactPerson), "", ", " + TrimAll(vObj.ContactPerson));
	Items.GroupAccounting.CollapsedRepresentationTitle = vTitle;
	If Payer = Enums.WhoPays.Customer Or Payer = Enums.WhoPays.Agent Then
		Items.DecorationGuestPays.Visible = False;
		Items.DecorationCustomerPays.Visible = True;
		Items.DecorationChargingRules.Visible = False;
	ElsIf Payer = Enums.WhoPays.Guest Then 
		Items.DecorationGuestPays.Visible = False;
		Items.DecorationCustomerPays.Visible = False;
		Items.DecorationChargingRules.Visible = False;
	Else
		Items.DecorationGuestPays.Visible = False;
		Items.DecorationCustomerPays.Visible = False;
		Items.DecorationChargingRules.Visible = True;
	EndIf;
EndProcedure // BuildAccountingGroupCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildRoomRateGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	// Room type for price calculation
	If ValueIsFilled(vObj.RoomTypeUpgrade) And IsManualRoomPrice = 0 Then
		IsManualRoomPrice = 2;
		// Items visibility
		Items.RoomPrice.Visible = False;
		Items.RoomTypeUpgrade.Visible = True;
	EndIf;
	If ValueIsFilled(vObj.RoomRate) And Not IsBlankString(vObj.RoomRate.Remarks) Then
		Items.RoomRateRemarks.Visible = True;
	Else
		Items.RoomRateRemarks.Visible = False;
	EndIf;
	// Build group collapsed title
	vTitle = NStr("en='Room rate: '; ru='Тариф: '; de='Tarif: '") + TrimAll(vObj.RoomRate) + 
			 ?(ValueIsFilled(vObj.ServicePackage) And vObj.ServicePackage.IsMealBoardTerm, ", " + TrimAll(vObj.ServicePackage), "") + 
			 ?(IsBlankString(TServicePackagesPresentation), "", ", " + TrimAll(TServicePackagesPresentation)) + 
			 ?(IsManualRoomPrice = 0, "", ?(ValueIsFilled(vObj.RoomTypeUpgrade), NStr("en=', price for '; ru=', цена для '; de=', Preis für '") + TrimAll(vObj.RoomTypeUpgrade.Code), ", " + PricePresentation + ?(IsManualRoomPrice = 1, NStr("en=' per room'; ru=' за номер'; de=' pro Zimmer'"), NStr("en=' per guest'; ru=' за гостя'; de=' pro Gast'"))));
	// Tourist tax
	If Items.GroupTouristTax.Visible Then
		vTouristTaxTitle = "";
		If ValueIsFilled(vObj.TouristicTaxExemptionReason) Then
			vTouristTaxTitle = NStr("en='Tourist tax exemption'; ru='Освобождение от тур. налога'; de='Befreiung von der Kurtaxe'");
			vTouristTaxTitle = vTouristTaxTitle + 
			                   ": " + TrimAll(vObj.TouristicTaxExemptionReason);
			vTitle = vTitle + ", " + vTouristTaxTitle;
		Else
			vTouristTaxTitle = NStr("en='Tourist tax'; ru='Туристический налог'; de='Kurtaxe'");
			If ValueIsFilled(vObj.TouristicTaxAccountingDate) Then
				vTouristTaxTitle = vTouristTaxTitle + ": " + Format(vObj.TouristicTaxAccountingDate, "DF=dd.MM.yyyy");
			EndIf;
		EndIf;
		Items.GroupTouristTax.Title = vTouristTaxTitle;
	EndIf;
	// Main rates group title
	Items.GroupRoomRate.CollapsedRepresentationTitle = vTitle;
EndProcedure // BuildRoomRateGroupCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildDiscountsGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	vTitle = "";
	If Not IsBlankString(vObj.DiscountConfirmationText) Then
		vTitle = vTitle + ?(IsBlankString(vTitle), "", ", ") + TrimAll(vObj.DiscountConfirmationText);
	EndIf;
	If vObj.Discount <> 0 Or ValueIsFilled(vObj.DiscountType) Then
		vTitle = vTitle + ?(IsBlankString(vTitle), "", ", ") + TrimAll(vObj.Discount) + ?(ValueIsFilled(vObj.DiscountType), ?(vObj.DiscountType.IsAmountDiscount, " - ", "% - ") + TrimAll(vObj.DiscountType), "%");
	EndIf;
	If ValueIsFilled(vObj.DiscountCard) Then
		vTitle = vTitle + ?(IsBlankString(vTitle), "", ", ") + NStr("en='card: '; ru='карта: '; de='Karte: '") + TrimAll(vObj.DiscountCard);
	EndIf;
	If ValueIsFilled(vObj.DiscountServiceGroup) Then
		vTitle = vTitle + ?(IsBlankString(vTitle), "", ", ") + NStr("en='for services: '; ru='для услуг: '; de='für die Dienstleistungen: '") + TrimAll(vObj.DiscountServiceGroup);
	EndIf;
	If ValueIsFilled(vObj.PriceChangeReason) Then
		vTitle = vTitle + ?(IsBlankString(vTitle), "", ", ") + NStr("en='Reason: ';ru='Причина: ';de='Grund: '") + TrimAll(vObj.PriceChangeReason);
	EndIf;
	vTitle = NStr("en='Discount: '; ru='Скидка: '; de='Rabatt: '") + TrimAll(vTitle);
	Items.GroupDiscounts.CollapsedRepresentationTitle = vTitle;
	If ValueIsFilled(vObj.DiscountType) And vObj.DiscountType.IsAmountDiscount Then
		Items.DiscountSum.Visible = True;
	Else
		Items.DiscountSum.Visible = False;
	EndIf;
EndProcedure // BuildDiscountsGroupCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildStatusGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	vTitle = NStr("en='Status: '; ru='Статус: '; de='Status: '") + TrimAll(vObj.AccommodationStatus);
	If ValueIsFilled(vObj.GuaranteeType) Then
		vTitle = vTitle + NStr("en=', guarantee: '; ru=', гарантия: '; de=', Garantie: '") + TrimAll(vObj.GuaranteeType.Code);
	EndIf;
	Items.GroupStatusInfo.CollapsedRepresentationTitle = vTitle;
EndProcedure // BuildStatusGroupCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildGuestGroupGroupCollapsedTitle(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	vTitle = NStr("en='Group: '; ru='Группа: '; de='Gruppe: '") + TrimAll(vObj.GuestGroup) + ?(IsBlankString(GuestGroupDescription), "", ", " + TrimAll(GuestGroupDescription)) + ?(IsBlankString(GuestGroupDescription), "", ", Ref.# " + TrimAll(GuestGroupID));
	If ValueIsFilled(GuestGroupCreateDate) Then
		vTitle = vTitle + NStr("en=', created: '; ru=', создана: '; de=', erstellt am: '") + Format(GuestGroupCreateDate, "DF=dd.MM.yyyy");
	EndIf;
	Items.GroupGuestGroup.CollapsedRepresentationTitle = vTitle;
EndProcedure // BuildGuestGroupGroupCollapsedTitle

// -----------------------------------------------------------------------------
&AtServer
Procedure ContactPersonOnChangeAtServer()
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle();
EndProcedure // ContactPersonOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function ChargingRulesCopyRowAtServer(pCurID)
	vCurRow = Object.ChargingRules.FindByID(pCurID);
	If vCurRow <> Undefined Then
		vNewRow = Object.ChargingRules.Add();
		FillPropertyValues(vNewRow, vCurRow,,"LineNumber"); 
	EndIf;
	Return vNewRow.GetID();
EndFunction // ChargingRulesAddRowAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearServicesManualChangesAtServer()
	For Each vSrvRow In Object.Services Do
		If vSrvRow.IsManualPrice Then
			vSrvRow.IsManualPrice = False;
		EndIf;
		If vSrvRow.QuantityIsChanged Then
			vSrvRow.QuantityIsChanged = False;
		EndIf;
		If vSrvRow.DiscountIsChanged Then
			vSrvRow.DiscountIsChanged = False;
		EndIf;
		If vSrvRow.CommissionIsChanged Then
			vSrvRow.CommissionIsChanged = False;
		EndIf;
		If vSrvRow.CalendarDayTypeIsChanged Then
			vSrvRow.CalendarDayTypeIsChanged = False;
			vSrvRow.CalendarDayType = Undefined;
			vSrvRow.PriceTag = Undefined;
		EndIf;
	EndDo;
EndProcedure // ClearServicesManualChangesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesFolioOnChangeAtServer(pCurrentRow)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined And ValueIsFilled(vCurData.Folio) Then
		vObj = FormAttributeToValue("Object");
		// Fill main folio parameters
		vCurData.FolioCurrency = vCurData.Folio.FolioCurrency;
		vCurData.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(Object.Hotel, vCurData.FolioCurrency, ?(ValueIsFilled(vCurData.AccountingDate), vCurData.AccountingDate, Object.ExchangeRateDate));
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
		EndIf;
		// Check if service folio corresponds to the charging rules
		vCurFolio = vCurData.Folio;
		vChargingRules = Object.ChargingRules.Unload();
		If Not Object.IgnoreGroupChargingRules Then
			cmAddGuestGroupChargingRules(vChargingRules, Object.GuestGroup);
		EndIf;
		vObj.pmSetServiceFolioBasedOnChargingRules(vCurData, vChargingRules, True);
		If ValueIsFilled(vCurData.Service) And ValueIsFilled(vCurData.Folio) And vCurData.Folio <> vCurFolio Then
			vCurData.Folio = vCurFolio;
			vNewCRRow = Object.ChargingRules.Insert(0);
			cmUpdateChargingRulesFoliosLineNumbers(Object.ChargingRules);
			vNewCRRow.ChargingFolio = vCurFolio;
			vNewCRRow.ChargingRule = Enums.ChargingRuleTypes.One;
			vNewCRRow.ChargingRuleValue = vCurData.Service;
			// Update owner
			vIsTransfer = vNewCRRow.IsTransfer;
			vNewCRRow.Owner = GetChargingRuleOwnerByFolioAtServer(Object.Ref, vCurFolio, vIsTransfer);
			vNewCRRow.IsTransfer = vIsTransfer;
		EndIf;
		If Not vCurData.IsManual Then
			vObj.pmSetFolioBasedOnChargingRules(Object.Services, True);
		EndIf;
	EndIf;
EndProcedure // ServicesFolioOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetItemIndex(pName)
	vIndex = "";
	vStrLen = StrLen(pName);
	While vStrLen > 0 Do
		vChar = Mid(pName, vStrLen, 1);
		If cmIsNumber(vChar) Then
			vIndex = vChar + vIndex;
		Else
			Break;
		EndIf;
		vStrLen = vStrLen - 1;
	EndDo;
	Return vIndex;
EndFunction // GetItemIndex

// -----------------------------------------------------------------------------
&AtServer
Procedure FillFunctionsButton()
	Query = New Query;
	Query.Text = 
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
	
	Query.SetParameter("ObjectType", Documents.Accommodation.EmptyRef());	
	QueryResult = Query.Execute();	
	SelectionRecords = QueryResult.Select();
	Actions.Clear();
	While SelectionRecords.Next() Do
		If SelectionRecords.PredefinedDataName = "" 
			or SelectionRecords.PredefinedDataName = "AccommodationFillOrder"
			or SelectionRecords.PredefinedDataName = "AccommodationSendWelcomeSMS" 
			or SelectionRecords.PredefinedDataName = "AccommodationFillClientFeedback" 
			or SelectionRecords.PredefinedDataName = "AccommodationFillAccommodation" 
			or SelectionRecords.PredefinedDataName = "AccommodationGuestGroupFillSettlement"
			or SelectionRecords.PredefinedDataName = "AccommodationGuestGroupFillInvoice"
			or SelectionRecords.PredefinedDataName = "AccommodationPrintCoupons" 
			or SelectionRecords.PredefinedDataName = "AccommodationPrintRoomCoupons"
			or SelectionRecords.PredefinedDataName = "AccommodationPrintGuestGroupCoupons"
			or SelectionRecords.PredefinedDataName = "AccommodationChangeRoom"
			or SelectionRecords.PredefinedDataName = "AccommodationFillInvoice" Then
			vNewRow = Actions.Add();
			vNewRow.Action = SelectionRecords.Ref;
			vNewRow.IsDefault = SelectionRecords.IsDefault;
			
			vID = vNewRow.GetID();
			
			vCommand = Commands.Add("Func"+vID);
			vCommand.Action = "FuncButtonClick";
			If SelectionRecords.IsDefault Then
				vStructure = New Structure("Title,CommandName",
				TrimAll(SelectionRecords.Code) + " " + cmNStr(SelectionRecords.ref),"Func"+vID);
			Else
				vStructure = New Structure("Title,CommandName",
				TrimAll(SelectionRecords.Code) + " " + cmNStr(SelectionRecords.ref),"Func"+vID);
			EndIf;
			
			tcOnServer.cmCreateItem(ThisObject,?( SelectionRecords.IsDefault,Items.FormGroupFunctionsDefault,Items.FormGroupFunctionsNotDefault),"Func"+vID,"FormButton",vStructure);
		EndIf;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationFillInvoice()
	vInvoiceSum  = GetInvoiceSum(Object.Ref); 		
	If vInvoiceSum.NewExtraAmount = 0 Then
		vParam = New Structure;
		vParam.Insert("ParentDoc", Object.Ref);
		OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisObject, True);	
	Else
		vUCMenu = New ValueList(); 
		vUCMenu.Add(1, NStr("en = 'extra amount '; de = 'zusätzlicher Betrag '; ru = 'доплату '") + tcOnServer.FormatSum(vInvoiceSum.NewExtraAmount, Object.ReportingCurrency));
		vUCMenu.Add(2, NStr("en = 'total amount '; de = 'Gesamtsumme'; ru = 'полную сумму '") + tcOnServer.FormatSum(vInvoiceSum.NewFullAmount, Object.ReportingCurrency));
		vUCMenu.Add(3, NStr("en = 'Cancel'; de = 'Absagen'; ru = 'Отмена'"));
		
		ShowQueryBox(New NotifyDescription("AccommodationFillInvoiceChoose", ThisObject), Nstr("en = 'Create an account for'; de = 'Erstellen Sie ein Konto für'; ru = 'Сформировать счет на'"), vUCMenu); 
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationFillInvoiceChoose(pQuestionResult, pAdditionalParameters) Export
	If pQuestionResult = 2 Then
		vParam = New Structure;
		vParam.Insert("ParentDoc", Object.Ref);
		OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisObject, True);	
	ElsIf pQuestionResult = 1 Then
		vParam = New Structure;
		vParam.Insert("ParentDoc", Object.Ref);
		vParam.Insert("ExtraService", True);
		OpenForm("Document.ProformaInvoice.Form.tcDocumentForm", vParam, ThisObject, True);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetInvoiceSum(pParentDoc)   
	vRes = New Structure("NewFullAmount, NewExtraAmount", 0, 0);
	vDocObj = Documents.ProformaInvoice.CreateDocument();	
	vDocObj.Fill(pParentDoc);
	vDocObj.ParentDoc = Undefined;
	vDocObj.Fill(pParentDoc.GuestGroup);	
	vGuestGroupObj = pParentDoc.GuestGroup.GetObject();
	vExistingInvoices = vGuestGroupObj.pmGetInvoices();
	If vExistingInvoices.Count() > 0 Then
		vNewInvServices = vDocObj.Services.Unload();
		For Each vExistingInvoicesRow In vExistingInvoices Do
			If vExistingInvoicesRow.InvoiceDate <= vDocObj.Date And vExistingInvoicesRow.Invoice <> vDocObj.Ref Then
				For Each vExistingInvoicesServicesRow In vExistingInvoicesRow.Invoice.Services Do
					vNewInvServicesRow = vNewInvServices.Add();
					FillPropertyValues(vNewInvServicesRow, vExistingInvoicesServicesRow, , "LineNumber");
					vNewInvServicesRow.Quantity = -vNewInvServicesRow.Quantity;
					vNewInvServicesRow.Sum = -vNewInvServicesRow.Sum;
					vNewInvServicesRow.VATSum = -vNewInvServicesRow.VATSum;
					vNewInvServicesRow.DiscountSum = -vNewInvServicesRow.DiscountSum;
					vNewInvServicesRow.CommissionSum = -vNewInvServicesRow.CommissionSum;
					vNewInvServicesRow.VATCommissionSum = -vNewInvServicesRow.VATCommissionSum;
					vNewInvServicesRow.NumberOfPersons = -vNewInvServicesRow.NumberOfPersons;
					vNewInvServicesRow.RoomQuantity = -vNewInvServicesRow.RoomQuantity;
				EndDo;
			EndIf;
		EndDo;
		vNewInvServices.GroupBy("AccountingDate, Service, Price, Unit, VATRate, Remarks, Client, AccommodationType, RoomType, Room, Resource, IsInPrice, IsRoomRevenue, IsResourceRevenue, DateTimeFrom, DateTimeTo, CalendarDayType, Discount, HotelProduct, Agent, AgentCommissionType, AgentCommission, GuestGroup", "Quantity, Sum, VATSum, NumberOfPersons, RoomQuantity, DiscountSum, CommissionSum, VATCommissionSum");
		i = 0;
		While i < vNewInvServices.Count() Do
			vNewInvServicesRow = vNewInvServices.Get(i);
			If vNewInvServicesRow.Quantity < 0 Then
			ElsIf vNewInvServicesRow.Quantity = 0 And vNewInvServicesRow.Sum = 0 Then
				vNewInvServices.Delete(i);
				Continue;
			EndIf;
			i = i + 1;
		EndDo;
		vRes.NewFullAmount = vDocObj.Services.Total("Sum");
		vRes.NewExtraAmount = vNewInvServices.Total("Sum");
	EndIf;	 
	Return vRes;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationChangeRoom()
	vChangeRoomDateTime = CurrentDate();
	vChangeRoomTime = ExtractTime(vChangeRoomDateTime);
	If ValueIsFilled(Object.RoomRate) Then
		vDurationCalculationRuleType = tcOnServer.cmGetAttributeByRef(Object.RoomRate, "DurationCalculationRuleType");
		If ValueIsFilled(vDurationCalculationRuleType) And vDurationCalculationRuleType = PredefinedValue("Enum.DurationCalculationRuleTypes.ByReferenceHour") Then
			vChangeRoomTime = ExtractTime(tcOnServer.cmGetAttributeByRef(Object.RoomRate, "ReferenceHour"));
		Else
			vChangeRoomTime = ExtractTime(Object.CheckOutDate);
		EndIf;
	Else
		vChangeRoomTime = ExtractTime(Object.CheckOutDate);
	EndIf;
	// Ask user to input change room date and time
	OpenForm("CommonForm.tcInputDateTime", 
	         New Structure("FillingValues", 
			 New Structure("Description, Date, Time", 
			               NStr("ru='Укажите дату и время переселения...';
						        |de='Geben Sie das Datum und die Zeit der Verlegung an…';
								|en='Input change room date and time please...'"), 
						   vChangeRoomDateTime, vChangeRoomTime)), 
	         ThisObject, Object.Ref, , , 
			 New NotifyDescription("AccommodationChangeRoomDateTimeIsSelected", ThisObject));
EndProcedure // AccommodationChangeRoom

// -----------------------------------------------------------------------------
&AtServerNoContext
Function ZeroSecondShift(pDateTime)
	Return cm0SecondShift(pDateTime);
EndFunction // ZeroSecondShift

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationChangeRoomDateTimeIsSelected(pChangeRoomDateTime, pExtraParams) Export
	If pChangeRoomDateTime = Undefined Then
		ShowMessageBox(, NStr("ru='Процедура переселения отменена!';de='Das Umsiedlungsverfahren wurde abgebrochen!';en='Change room procedure is canceled!'"));
		Return;
	EndIf;
	If ZeroSecondShift(pChangeRoomDateTime) <= ZeroSecondShift(Object.CheckInDate) Then
		ShowMessageBox(, NStr("ru='Ввели дату и время переселения, которые раньше чем дата и время заезда!';
		                      |de='Sie haben ein Datum und eine Zeit des Umzuges eingegeben, die vor dem Anreisedatum und der Anreisezeit liegen!'; 
		                      |en='You have entered change room date and time that are earlier then check-in date and time!'"));
		Return;
	EndIf;
	// If change room time is just after check-in time then do not ceate new accommoation and change room directly in this form
	vFreeOfChargeTime = GetFreeOfChargeTime();
	If (pChangeRoomDateTime - Object.CheckInDate) <= vFreeOfChargeTime Then
		Object.Room = PredefinedValue("Catalog.Rooms.EmptyRef");
		ThisObject.CurrentItem = Items.Room;
		ShowMessageBox(, NStr("ru='Переселяете в течение периода бесплатного осмотра текущего номера! Измените номер комнаты в текущей брони.';
		                      |de='Sie werden während der kostenlosen Check-in-Zeit Ihres aktuellen Zimmers umgesiedelt! Ändern Sie die Zimmernummer in der aktuellen Buchung.'; 
		                      |en='You are relocating during the free of charge period of the current room! Change the room number in the current reservation.'"));
		Return;
	EndIf;
	// New check-out date
	vCheckOutDate = Object.CheckOutDate;
	If pChangeRoomDateTime >= vCheckOutDate Then
		vCheckOutDate = BegOfDay(pChangeRoomDateTime) + (Object.CheckOutDate - BegOfDay(Object.CheckOutDate)) + 24*3600;
	EndIf;
	// Guests to check-in list
	vGuestsToCheckInList = Undefined;
	If Not OneGuestMode Then
		vGuestsToCheckInList = New ValueList();
		vGuestsToCheckInList.Add(Object.Ref);
		For Each vGuestRow In GuestsInGroup Do
			If Not vGuestRow.IsAnnulation Then
				vGuestsToCheckInList.Add(vGuestRow.Ref);
			EndIf;
		EndDo;
	EndIf;
	// Open new period form
	OpenForm("Document.Accommodation.ObjectForm", New Structure("Basis, CheckInDate, CheckOutDate, OneGuestMode, IsForFolioSplit, GuestsToCheckInList", Object.Ref, pChangeRoomDateTime, vCheckOutDate, OneGuestMode, Object.IsForFolioSplit, vGuestsToCheckInList), , Object.Ref);
	ThisObject.Close();
EndProcedure // AccommodationChangeRoomDateTimeIsSelected

// -----------------------------------------------------------------------------
&AtServer
Function GetAccommodationService()
	vAccommodationService = Undefined;
	For Each vServicesRow In Object.Services Do
		If vServicesRow.IsRoomRevenue And vServicesRow.IsInPrice Then
			vAccommodationService = vServicesRow.Service;
			Break;
		EndIf;
	EndDo;
	Return vAccommodationService;
EndFunction // GetAccommodationService

// -----------------------------------------------------------------------------
&AtServer
Function GetFreeOfChargeTime()
	vFreeOfChargeTime = 3600;
	vAccService = GetAccommodationService();
	If ValueIsFilled(vAccService) And ValueIsFilled(vAccService.QuantityCalculationRule) Then
		If vAccService.QuantityCalculationRule.FreeOfChargeChangeRoomTime > 0 Then
			vFreeOfChargeTime = 3600 * vAccService.QuantityCalculationRule.FreeOfChargeChangeRoomTime;
		ElsIf vAccService.QuantityCalculationRule.RoomExaminationFreeOfChargeTime > 0 Then
			vFreeOfChargeTime = 3600 * vAccService.QuantityCalculationRule.RoomExaminationFreeOfChargeTime;
		EndIf;
	EndIf;
	Return vFreeOfChargeTime;
EndFunction // GetFreeOfChargeTime

// -----------------------------------------------------------------------------
&AtServer
Function GetListPrintCoupons(pBase, pService)
	// Build value list with charges to process
	vCouponsList = New ValueList();
	vQry = New Query();
	If TypeOf(pBase) = Type("DocumentRef.Accommodation") Then
		vQry.Text = 
		"SELECT
		|	SalesMovements.Hotel AS Hotel,
		|	SalesMovements.ServiceDate AS Date,
		|	SalesMovements.Recorder.Number AS Number,
		|	SalesMovements.Service AS Service,
		|	SalesMovements.Client AS Client,
		|	SalesMovements.Room AS Room,
		|	SalesMovements.Resource AS Resource,
		|	SalesMovements.GuestGroup AS GuestGroup,
		|	SUM(SalesMovements.Quantity) AS Quantity
		|FROM
		|	AccumulationRegister.Sales AS SalesMovements
		|WHERE
		|	SalesMovements.Service = &qService
		|	AND SalesMovements.ServiceDate >= &qBegOfCurrentDate
		|	AND SalesMovements.ParentDoc = &qParentDoc
		|	AND (NOT SalesMovements.Folio.IsClosed)
		|	AND NOT SalesMovements.IsCorrection
		|
		|GROUP BY
		|	SalesMovements.Hotel,
		|	SalesMovements.ServiceDate,
		|	SalesMovements.Recorder.Number,
		|	SalesMovements.Service,
		|	SalesMovements.Client,
		|	SalesMovements.Room,
		|	SalesMovements.Resource,
		|	SalesMovements.GuestGroup
		|
		|HAVING
		|	SUM(SalesMovements.Quantity) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	SalesForecastMovements.Hotel,
		|	SalesForecastMovements.ServiceDate,
		|	SalesForecastMovements.Recorder.Number,
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Client,
		|	SalesForecastMovements.Room,
		|	SalesForecastMovements.Resource,
		|	SalesForecastMovements.GuestGroup,
		|	SUM(SalesForecastMovements.Quantity)
		|FROM
		|	AccumulationRegister.SalesForecast AS SalesForecastMovements
		|WHERE
		|	SalesForecastMovements.Service = &qService
		|	AND SalesForecastMovements.ServiceDate >= &qBegOfCurrentDate
		|	AND SalesForecastMovements.ParentDoc = &qParentDoc
		|
		|GROUP BY
		|	SalesForecastMovements.Hotel,
		|	SalesForecastMovements.ServiceDate,
		|	SalesForecastMovements.Recorder.Number,
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Client,
		|	SalesForecastMovements.Room,
		|	SalesForecastMovements.Resource,
		|	SalesForecastMovements.GuestGroup
		|
		|HAVING
		|	SUM(SalesForecastMovements.Quantity) <> 0
		|
		|ORDER BY
		|	Date";
		vQry.SetParameter("qParentDoc", pBase);
	ElsIf TypeOf(pBase) = Type("CatalogRef.Rooms") Then
		vQry.Text = 
		"SELECT
		|	SalesMovements.Hotel AS Hotel,
		|	SalesMovements.ServiceDate AS Date,
		|	SalesMovements.Recorder.Number AS Number,
		|	SalesMovements.Service AS Service,
		|	SalesMovements.Client AS Client,
		|	SalesMovements.Room AS Room,
		|	SalesMovements.Resource AS Resource,
		|	SalesMovements.GuestGroup AS GuestGroup,
		|	SUM(SalesMovements.Quantity) AS Quantity
		|FROM
		|	AccumulationRegister.Sales AS SalesMovements
		|WHERE
		|	SalesMovements.Service = &qService
		|	AND SalesMovements.ServiceDate >= &qBegOfCurrentDate
		|	AND SalesMovements.Room = &qRoom
		|	AND SalesMovements.GuestGroup = &qGuestGroup
		|	AND NOT SalesMovements.Folio.IsClosed
		|	AND NOT SalesMovements.IsCorrection
		|
		|GROUP BY
		|	SalesMovements.Hotel,
		|	SalesMovements.ServiceDate,
		|	SalesMovements.Recorder.Number,
		|	SalesMovements.Service,
		|	SalesMovements.Client,
		|	SalesMovements.Room,
		|	SalesMovements.Resource,
		|	SalesMovements.GuestGroup
		|
		|HAVING
		|	SUM(SalesMovements.Quantity) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	SalesForecastMovements.Hotel,
		|	SalesForecastMovements.ServiceDate,
		|	SalesForecastMovements.Recorder.Number,
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Client,
		|	SalesForecastMovements.Room,
		|	SalesForecastMovements.Resource,
		|	SalesForecastMovements.GuestGroup,
		|	SUM(SalesForecastMovements.Quantity)
		|FROM
		|	AccumulationRegister.SalesForecast AS SalesForecastMovements
		|WHERE
		|	SalesForecastMovements.Service = &qService
		|	AND SalesForecastMovements.ServiceDate >= &qBegOfCurrentDate
		|	AND SalesForecastMovements.Room = &qRoom
		|	AND SalesForecastMovements.GuestGroup = &qGuestGroup
		|
		|GROUP BY
		|	SalesForecastMovements.Hotel,
		|	SalesForecastMovements.ServiceDate,
		|	SalesForecastMovements.Recorder.Number,
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Client,
		|	SalesForecastMovements.Room,
		|	SalesForecastMovements.Resource,
		|	SalesForecastMovements.GuestGroup
		|
		|HAVING
		|	SUM(SalesForecastMovements.Quantity) <> 0
		|
		|ORDER BY
		|	Date";
		vQry.SetParameter("qRoom", pBase);
		vQry.SetParameter("qGuestGroup", Object.GuestGroup);
	ElsIf TypeOf(pBase) = Type("CatalogRef.GuestGroups") Then
		vQry.Text = 
		"SELECT
		|	SalesMovements.Hotel AS Hotel,
		|	SalesMovements.ServiceDate AS Date,
		|	SalesMovements.Recorder.Number AS Number,
		|	SalesMovements.Service AS Service,
		|	SalesMovements.Client AS Client,
		|	SalesMovements.Room AS Room,
		|	SalesMovements.Resource AS Resource,
		|	SalesMovements.GuestGroup AS GuestGroup,
		|	SUM(SalesMovements.Quantity) AS Quantity
		|FROM
		|	AccumulationRegister.Sales AS SalesMovements
		|WHERE
		|	SalesMovements.Service = &qService
		|	AND SalesMovements.ServiceDate >= &qBegOfCurrentDate
		|	AND SalesMovements.GuestGroup = &qGuestGroup
		|	AND NOT SalesMovements.Folio.IsClosed
		|	AND NOT SalesMovements.IsCorrection
		|
		|GROUP BY
		|	SalesMovements.Hotel,
		|	SalesMovements.ServiceDate,
		|	SalesMovements.Recorder.Number,
		|	SalesMovements.Service,
		|	SalesMovements.Client,
		|	SalesMovements.Room,
		|	SalesMovements.Resource,
		|	SalesMovements.GuestGroup
		|
		|HAVING
		|	SUM(SalesMovements.Quantity) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	SalesForecastMovements.Hotel,
		|	SalesForecastMovements.ServiceDate,
		|	SalesForecastMovements.Recorder.Number,
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Client,
		|	SalesForecastMovements.Room,
		|	SalesForecastMovements.Resource,
		|	SalesForecastMovements.GuestGroup,
		|	SUM(SalesForecastMovements.Quantity)
		|FROM
		|	AccumulationRegister.SalesForecast AS SalesForecastMovements
		|WHERE
		|	SalesForecastMovements.Service = &qService
		|	AND SalesForecastMovements.ServiceDate >= &qBegOfCurrentDate
		|	AND SalesForecastMovements.GuestGroup = &qGuestGroup
		|
		|GROUP BY
		|	SalesForecastMovements.Hotel,
		|	SalesForecastMovements.ServiceDate,
		|	SalesForecastMovements.Recorder.Number,
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Client,
		|	SalesForecastMovements.Room,
		|	SalesForecastMovements.Resource,
		|	SalesForecastMovements.GuestGroup
		|
		|HAVING
		|	SUM(SalesForecastMovements.Quantity) <> 0
		|
		|ORDER BY
		|	Date";
		vQry.SetParameter("qGuestGroup", pBase);
	EndIf;
	vQry.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vQry.SetParameter("qService", pService);
	vQry.SetParameter("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	vRows = vQry.Execute().Unload();
	For Each vRow In vRows Do
		vCouponsList.Add(New Structure("Hotel, Date, CouponBarCode, Service, Client, Room, Resource, GuestGroup, Quantity", 
		                 vRow.Hotel, vRow.Date, cmBuildCouponBarCode(1, vRow.Number, vRow.Service, vRow.Date, vRow.Quantity), 
						 vRow.Service, vRow.Client, vRow.Room, vRow.Resource, vRow.GuestGroup, vRow.Quantity));
	EndDo;
	Return vCouponsList;
EndFunction // GetListPrintCoupons

// -----------------------------------------------------------------------------
&AtServer
Function GetListServices(pBase)
	vQry = New Query();
	If TypeOf(pBase) = Type("DocumentRef.Accommodation") Then
		vQry.Text = 
		"SELECT
		|	SalesMovements.Service AS Service,
		|	SalesMovements.Service.SortCode AS ServiceSortCode,
		|	SalesMovements.Service.Code AS ServiceCode,
		|	SUM(SalesMovements.Quantity) AS Quantity
		|FROM
		|	AccumulationRegister.Sales AS SalesMovements
		|WHERE
		|	SalesMovements.ParentDoc = &qParentDoc
		|	AND SalesMovements.Service.ServiceRegistrationIsTurnedOn
		|	AND NOT SalesMovements.IsCorrection
		|
		|GROUP BY
		|	SalesMovements.Service,
		|	SalesMovements.Service.SortCode,
		|	SalesMovements.Service.Code
		|
		|HAVING
		|	SUM(SalesMovements.Quantity) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Service.SortCode,
		|	SalesForecastMovements.Service.Code,
		|	SUM(SalesForecastMovements.Quantity)
		|FROM
		|	AccumulationRegister.SalesForecast AS SalesForecastMovements
		|WHERE
		|	SalesForecastMovements.ParentDoc = &qParentDoc
		|	AND SalesForecastMovements.Service.ServiceRegistrationIsTurnedOn
		|
		|GROUP BY
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Service.SortCode,
		|	SalesForecastMovements.Service.Code
		|
		|HAVING
		|	SUM(SalesForecastMovements.Quantity) <> 0
		|
		|ORDER BY
		|	ServiceSortCode,
		|	ServiceCode";
		vQry.SetParameter("qParentDoc", pBase);
	ElsIf TypeOf(pBase) = Type("CatalogRef.Rooms") Then
		vQry.Text = 
		"SELECT
		|	SalesMovements.Service AS Service,
		|	SalesMovements.Service.SortCode AS ServiceSortCode,
		|	SalesMovements.Service.Code AS ServiceCode,
		|	SUM(SalesMovements.Quantity) AS Quantity
		|FROM
		|	AccumulationRegister.Sales AS SalesMovements
		|WHERE
		|	SalesMovements.Room = &qRoom
		|	AND SalesMovements.GuestGroup = &qGuestGroup
		|	AND SalesMovements.Service.ServiceRegistrationIsTurnedOn
		|	AND NOT SalesMovements.IsCorrection
		|
		|GROUP BY
		|	SalesMovements.Service,
		|	SalesMovements.Service.SortCode,
		|	SalesMovements.Service.Code
		|
		|HAVING
		|	SUM(SalesMovements.Quantity) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Service.SortCode,
		|	SalesForecastMovements.Service.Code,
		|	SUM(SalesForecastMovements.Quantity)
		|FROM
		|	AccumulationRegister.SalesForecast AS SalesForecastMovements
		|WHERE
		|	SalesForecastMovements.Room = &qRoom
		|	AND SalesForecastMovements.GuestGroup = &qGuestGroup
		|	AND SalesForecastMovements.Service.ServiceRegistrationIsTurnedOn
		|
		|GROUP BY
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Service.SortCode,
		|	SalesForecastMovements.Service.Code
		|
		|HAVING
		|	SUM(SalesForecastMovements.Quantity) <> 0
		|
		|ORDER BY
		|	ServiceSortCode,
		|	ServiceCode";
		vQry.SetParameter("qRoom", pBase);
		vQry.SetParameter("qGuestGroup", Object.GuestGroup);
	ElsIf TypeOf(pBase) = Type("CatalogRef.GuestGroups") Then
		vQry.Text = 
		"SELECT
		|	SalesMovements.Service AS Service,
		|	SalesMovements.Service.SortCode AS ServiceSortCode,
		|	SalesMovements.Service.Code AS ServiceCode,
		|	SUM(SalesMovements.Quantity) AS Quantity
		|FROM
		|	AccumulationRegister.Sales AS SalesMovements
		|WHERE
		|	SalesMovements.GuestGroup = &qGuestGroup
		|	AND SalesMovements.Service.ServiceRegistrationIsTurnedOn
		|	AND NOT SalesMovements.IsCorrection
		|
		|GROUP BY
		|	SalesMovements.Service,
		|	SalesMovements.Service.SortCode,
		|	SalesMovements.Service.Code
		|
		|HAVING
		|	SUM(SalesMovements.Quantity) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Service.SortCode,
		|	SalesForecastMovements.Service.Code,
		|	SUM(SalesForecastMovements.Quantity)
		|FROM
		|	AccumulationRegister.SalesForecast AS SalesForecastMovements
		|WHERE
		|	SalesForecastMovements.GuestGroup = &qGuestGroup
		|	AND SalesForecastMovements.Service.ServiceRegistrationIsTurnedOn
		|
		|GROUP BY
		|	SalesForecastMovements.Service,
		|	SalesForecastMovements.Service.SortCode,
		|	SalesForecastMovements.Service.Code
		|
		|HAVING
		|	SUM(SalesForecastMovements.Quantity) <> 0
		|
		|ORDER BY
		|	ServiceSortCode,
		|	ServiceCode";
		vQry.SetParameter("qGuestGroup", pBase);
	Else
		Return Undefined;
	EndIf;
	vQry.SetParameter("qReceipt", AccumulationRecordType.Receipt);
	vServices = vQry.Execute().Unload();
	vServicesList = new ValueList();
	For Each vService In vServices Do
		vServicesList.Add(vService.Service);	
	EndDo;
	Return vServicesList;
EndFunction // GetListServices

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationPrintCoupons(pAction, pBase)
	// Check workstation settings
	vCurrentWorkstation = tcOnServer.cmGetSessionParametersAttribute("CurrentWorkstation");
	If Not ValueIsFilled(vCurrentWorkstation) Then
		ShowMessageBox(,NStr("en='Current workstation is not defined!';ru='Не определено текущее рабочее место!';de='Der aktuelle Arbeitsplatz ist nicht festgelegt!'"));
		Return;
	EndIf;
	If Not tcOnServer.cmGetAttributeByRef(vCurrentWorkstation,"HasConnectionToRibbonPrinter") Then
		ShowMessageBox(,NStr("en='Current workstation has not connected to a ribbon printer!';ru='К текущему рабочему месту не подключен ленточный принтер!';de='An diesen Arbeitsplatz ist kein Banddrucker angeschlossen!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(tcOnServer.cmGetAttributeByRef(vCurrentWorkstation,"RibbonPrinterConnectionParameters")) Then
		ShowMessageBox(,NStr("en='Ribbon printer connection parameters are missing!';ru='У текущего рабочего места не указаны параметры подключения ленточного принтера!';de='Beim aktuellen Arbeitsplatz sind keine Parameter für den Anschluss an den Banddrucker angegeben!'"));
		Return;
	EndIf;
	// Check base object
	If Not ValueIsFilled(pBase) Then
		Return;
	EndIf;
	
	vService = Undefined;
	
	vServices = GetListServices(pBase);
		
	If vServices.Count() = 0 Then
		Return;
	ElsIf vServices.Count() = 1 Then
		vService = vServices[0].Value;
	Else	
		vServices.ShowChooseItem(new NotifyDescription("AfterChooseItemToCoupons",ThisObject, New Structure("Action,Base",pAction,pBase)),NStr("en='Choose service...';ru='Выберите услугу...';de='Wählen Sie die Dienstleistung...'"));
		Return;
	EndIf;
	
	vCouponsList = GetListPrintCoupons(pBase, vService);
	
	If vCouponsList = Undefined Then
		Return;	
	EndIf;
	// Print coupons list
	If vCouponsList.Count() > 0 Then
		// Get language
		vLanguage = tcOnServer.cmGetAttributeByRef(Object.Hotel,"Language");
		If ValueIsFilled(Object.Guest) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(Object.Guest,"Language")) Then
			vLanguage = tcOnServer.cmGetAttributeByRef(Object.Guest,"Language");
		EndIf;
		vRibbonPrinterConnection = tcOnServer.cmGetAttributeByRef(vCurrentWorkstation,"RibbonPrinterConnectionParameters");
		vDriverType = tcOnServer.cmGetAttributeByRef(vRibbonPrinterConnection, "DriverType");
		If vDriverType = PredefinedValue("Enum.RibbonPrinterDrivers.SystemPrinter") Then
			OpenForm("DataProcessor.PrintCouponSystemPrinter.Form.tcCouponPrintForm", New Structure("SelLanguage, SelObjList, RibbonPrinterConnectionParameters", vLanguage, vCouponsList, vRibbonPrinterConnection), ThisObject, ThisObject.UUID);
		ElsIf vDriverType = PredefinedValue("Enum.RibbonPrinterDrivers.Intermec") Then
			OpenForm("DataProcessor.IntermecRibbonPrinterDriver.Form.tcCouponPrintForm", New Structure("SelLanguage, SelObjList, RibbonPrinterConnectionParameters", vLanguage, vCouponsList, vRibbonPrinterConnection), ThisObject, ThisObject.UUID);	
		ElsIf vDriverType = PredefinedValue("Enum.RibbonPrinterDrivers.Atol") Then
			ShowMessageBox(,NStr("ru='Данный принтер временно не поддерживается в тонком клиенте';en='This printer is temporarily not supported in the thin client';de='Dieser Drucker wird im Thin Client vorübergehend nicht unterstützt'"));	
		EndIf;
	Else
		ShowMessageBox(,NStr("en='Nothing to print!';ru='Нет услуг для печати!';de='Es gibt keine Dienste für den Druck!'"));
	EndIf;
EndProcedure // AccommodationPrintCoupons

// -----------------------------------------------------------------------------
&AtServer
Function GetActionForNumber(pActionsNumber)
	vActions = Actions.FindByID(Number(pActionsNumber)).Action;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vActions);
	vStruct.Insert("PredefinedDataName",vActions.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vActions.ExternalProcessing);
	vStruct.Insert("DataProcessor",vActions.DataProcessor);
	
	Return vStruct;
	
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function RunDataProcessor(pDataProcessor, pParameter, pIsInteractive = False, rReturnParameter)
	vPARAM = New Structure("InputParameter, OutputParameter", pParameter, rReturnParameter);
	vResult = cmRunDataProcessor(pDataProcessor, vPARAM, pIsInteractive);
	rReturnPameter = vPARAM.OutputParameter;
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPrintingButton()
	Query = New Query;
	Query.Text = 
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
	
	Query.SetParameter("ObjectType", Documents.Accommodation.EmptyRef());	
	QueryResult = Query.Execute();	
	SelectionRecords = QueryResult.Select(QueryResultIteration.ByGroups);
	PrintForms.Clear();
	vLang = Object.Guest.Language;
	While SelectionRecords.Next() Do
		SelectionDetailRecords = SelectionRecords.Select(QueryResultIteration.ByGroups);
		
		If vLang = SelectionRecords.Language or not ValueIsFilled(SelectionRecords.Language) Then
			vParentLang = Items.FormGroupPrintingNotDefaultMain;
		ElsIf not vLang = SelectionRecords.Language Then
			vParentLang = tcOnServer.cmCreateItem(ThisObject,Items.FormGroupPrintingNotDefaultExtra,"Print"+SelectionRecords.Language,"FormGroup",
			New Structure("Type,Title",
			FormGroupType.Popup,SelectionRecords.Language));
		EndIf;
		
		While SelectionDetailRecords.Next() Do
			If SelectionDetailRecords.PredefinedDataName = "" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintHotelProduct" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestGroupHotelProducts" Or 
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestCardFreeForm" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestsCardsFreeForm" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestCardForm4G" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestsCardsForm4G" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestForm2Forms5" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestFormFreeForm" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestRegistrationForm" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestRegistrationForms" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestsForms2Forms5" Or
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestsFormsFreeForm" Or 
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestPersonalDataProcessingConsent" Or 
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintGuestRefusalToPayResortFee" Or 
			   SelectionDetailRecords.PredefinedDataName = "AccommodationPrintDepartureNotificationForm" Then
			   
				vNewRow = PrintForms.Add();
				vNewRow.PrintForm = SelectionDetailRecords.Ref;
				vNewRow.IsDefault = SelectionDetailRecords.IsDefault;
				
				vID = vNewRow.GetID();
				
				vCommand = Commands.Add("Print"+vID);
				vCommand.Action = "PrintButtonClick";
				If SelectionDetailRecords.IsDefault Then
					vParent = Items.FormGroupPrintingDefault;
				Else
					vParent = vParentLang;
				EndIf;
				vStructure = New Structure("Title,CommandName",
				TrimAll(SelectionDetailRecords.Code) + " " + cmNStr(SelectionDetailRecords.ref),"Print"+vID);
				
				tcOnServer.cmCreateItem(ThisObject,vParent,"Print"+vID,"FormButton",vStructure);
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetPrintFormForNumber(pActionsNumber)
	vPrintForms = PrintForms.FindByID(Number(pActionsNumber)).PrintForm;
	
	vStruct = New Structure();
	vStruct.Insert("Ref",vPrintForms);
	vStruct.Insert("PredefinedDataName",vPrintForms.PredefinedDataName);	
	vStruct.Insert("ExternalProcessing",vPrintForms.ExternalProcessing);
	vStruct.Insert("Report",vPrintForms.Report);
	vStruct.Insert("Language",vPrintForms.Language);
	
	Return vStruct;
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintHotelProduct(pLang, pForm, pDocObj = Undefined)
	#If ThickClientOrdinaryApplication Then
		vReport = Undefined;
		If ValueIsFilled(pForm.Report) Then
			vReport = cmBuildReportObject(pForm.Report);
		ElsIf ValueIsFilled(pForm.ExternalProcessing) Then
			vReport = cmGetExternalDataProcessorObject(pForm.ExternalProcessing);
		Else
			vReport = Reports.PrintHotelProducts.Create();
		EndIf;
		If pDocObj = Undefined Then
			If pForm = Catalogs.ObjectPrintingForms.ReservationPrintHotelProduct Then
				vReport.Document = Object.Ref;
			EndIf;
			vReport.GuestGroup = Object.GuestGroup;
			Try
				vReport.Room = Object.Room;
				vReport.CheckInDate = BegOfDay(Object.CheckInDate);
			Except
			EndTry;
		Else
			If pForm = Catalogs.ObjectPrintingForms.ReservationPrintHotelProduct Then
				vReport.Document = pDocObj.Ref;
			EndIf;
			vReport.GuestGroup = pDocObj.GuestGroup;
			Try
				vReport.Room = pDocObj.Room;
				vReport.CheckInDate = BegOfDay(pDocObj.CheckInDate);
			Except
			EndTry;
		EndIf;
		vFrm = vReport.GetForm();
		vFrm.SelObjectPrintForm = pForm;
		vFrm.Open();
	#Else
		If pForm = PredefinedValue("Catalog.ObjectPrintingForms.AccommodationPrintHotelProduct") Then
			vParams = new Structure("SelDocument, SelRoom, SelGuestGroup, SelCheckInDate, SelObjectPrintForm", 
			                         Object.Ref,
									 Object.Room,
									 Object.GuestGroup,
									 Object.CheckInDate,
									 pForm);	
		ElsIf pForm = PredefinedValue("Catalog.ObjectPrintingForms.AccommodationPrintGuestGroupHotelProducts") Then
			vParams = new Structure("SelGuestGroup, SelCheckInDate, SelObjectPrintForm", 
			                         Object.GuestGroup,
									 Object.CheckInDate,
									 pForm);
		EndIf;
		OpenForm("Report.PrintHotelProducts.Form.tcReportForm", vParams, ThisObject, ThisObject.UUID);
	#EndIf
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure PriceCalculationDateOnChangeAtServer()
	vObj = FormAttributeToValue("Object");
	// Reset price calculation dates in the change history
	For Each vRRRow In vObj.RoomRates Do
		If ValueIsFilled(vRRRow.PriceCalculationDate) Then
			vRRRow.PriceCalculationDate = '00010101';
		EndIf;
	EndDo;
	// Automatic services list calculation	
	vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
	// Set object value
	ValueToFormAttribute(vObj, "Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // PriceCalculationDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetRoomRoomTypeAtServer(Val pDate, pRoom)
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	vRoomAttrs = pRoom.GetObject().pmGetRoomAttributes(pDate);
	If vRoomAttrs.Count() > 0 Then
		Return vRoomAttrs.Get(0).RoomType;
	Else
		Return pRoom.RoomType;
	EndIf;
EndFunction // GetRoomRoomTypeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateTotalsOnClient() Export
	RecalculateTotals();
EndProcedure // RecalculateTotalsOnClient

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearResortFeeExemptionAtServer(pDoClear = False)
	// Get resort fee service
	vResortFeeServiceCurrency = Undefined;
	vResortFeeService = GetResortFeeService(vResortFeeServiceCurrency, True);
	// Get object
	vObj = FormAttributeToValue("Object");
	// Clear touristic tax exemption data
	vObj.TouristicTaxExemptionReason = Undefined;
	vObj.TouristicTaxExemptionReasonFillDate = '00010101';
	vObj.TouristicTaxExemptionConfirmationData = "";
	BuildRoomRateGroupCollapsedTitle(vObj);
	// Check if this row already exists
	vPRow = vObj.Prices.Find(vResortFeeService, "Service");
	If vPRow <> Undefined Or ValueIsFilled(Object.TouristicTaxExemptionReason) Or pDoClear Then
		// Delete row to manual prices
		If vPRow <> Undefined Then
			vObj.Prices.Delete(vPRow);
		EndIf;
		// Recalculate services
		vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
		// Move object back
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		TotalSum = CalculateTotalServices(, , False, False);
	EndIf;
EndProcedure // ClearResortFeeExemptionAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetChargingRuleOwnerByFolioAtServer(pThisDocRef, pFolio, rIsTransfer)
	If ValueIsFilled(pFolio) Then
		vHotel = pFolio.Hotel;
		vParentDoc = pFolio.ParentDoc;
		If pThisDocRef <> vParentDoc And ValueIsFilled(vParentDoc) Then
			rIsTransfer = True;
		EndIf;
		If rIsTransfer And ValueIsFilled(vParentDoc) And 
		  (TypeOf(vParentDoc) = Type("DocumentRef.Reservation") Or 
		   TypeOf(vParentDoc) = Type("DocumentRef.ResourceReservation") Or
		   TypeOf(vParentDoc) = Type("DocumentRef.Accommodation")) Then
			Return vParentDoc;
		ElsIf ValueIsFilled(pFolio.Contract) Then
			Return pFolio.Contract;
		ElsIf ValueIsFilled(pFolio.Customer) And ValueIsFilled(vHotel) And 
		      Not pFolio.Customer = vHotel.IndividualsCustomer Then
			Return pFolio.Customer;
		ElsIf ValueIsFilled(pFolio.Client) Then
			Return pFolio.Client;
		EndIf;
	EndIf;
	Return Undefined;
EndFunction // GetChargingRuleOwnerByFolioAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetListOfRoomRatesAtServer(pText, pCheckInDate, pCheckOutDate, pReservationDate, pRoomType, pHotel)
	vRatesList = cmGetAllowedRoomRates(pCheckInDate, pCheckOutDate, pReservationDate, pRoomType, pHotel);
	i = 0;
	While i < vRatesList.Count() Do
		vRoomRate = vRatesList.Get(i).Value;
		If StrFind(lower(vRoomRate.Description), lower(TrimAll(pText))) = 0 Then
			vRatesList.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	Return vRatesList;
EndFunction // GetListOfRoomRatesAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateTemplateInChangesPlan(pObj = Undefined)
	vObj = pObj;
	If vObj = Undefined Then
		vObj = Object;
	EndIf;
	For Each vRRRow In vObj.RoomRates Do
		If ValueIsFilled(vRRRow.AccommodationTemplate) And vRRRow.AccommodationTemplate <> pObj.AccommodationTemplate Then
			vRRRow.AccommodationTemplate = pObj.AccommodationTemplate;
		EndIf;
	EndDo;
EndProcedure // UpdateTemplateInChangesPlan

// -----------------------------------------------------------------------------
&AtServer
Procedure CompanyOnChangeAtServer()
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle();
	// Build room rate group hidden title
	BuildRoomRateGroupCollapsedTitle();
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle();
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillServicePackageChoiceList()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServicePackages.Ref AS Ref
	|FROM
	|	Catalog.ServicePackages AS ServicePackages
	|WHERE
	|	ServicePackages.IsMealBoardTerm
	|	AND NOT ServicePackages.DeletionMark
	|	AND NOT ServicePackages.IsFolder
	|	AND (&qExcludeFC
	|				AND NOT ServicePackages.IsFC
	|			OR NOT &qExcludeFC)
	|	AND (ServicePackages.Hotel = &qHotel
	|			OR ServicePackages.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	ServicePackages.SortCode,
	|	ServicePackages.Description";
	vQry.SetParameter("qHotel", Object.Hotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	If ValueIsFilled(Object.RoomRate) And tcOnServer.cmGetAttributeByRef(Object.RoomRate, "IsComplimentary") Or 
	   Object.Discount = 100 Or 
	   RoomPrice = 0 And (IsManualRoomPrice = 1 Or IsManualRoomPrice = 3) Then
		vQry.SetParameter("qExcludeFC", False);
	Else
		vQry.SetParameter("qExcludeFC", True);
	EndIf;
	vTermsArray = vQry.Execute().Unload().UnloadColumn("Ref");
	Items.ServicePackage.ChoiceList.LoadValues(vTermsArray);
	Items.ServicePackageBeforeUpgrade.ChoiceList.LoadValues(vTermsArray);
EndProcedure // FillServicePackageChoiceList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTasksPresentation()
	TTasks = "";
	vShowClosed = False;
	TasksTab.Clear();
	If ValueIsFilled(Object.Ref) Then
		vTasks = cmGetMessagesForObject(Object.Ref, True);
		If ValueIsFilled(Object.GuestGroup) Then
			vGroupTasks = cmGetMessagesForObject(Object.GuestGroup);
			For Each vGroupTasksRow In vGroupTasks Do
				vTasksRow = vTasks.Add();
				FillPropertyValues(vTasksRow, vGroupTasksRow);
			EndDo;
		EndIf;
		If ValueIsFilled(Object.Customer) Then
			vCustomerTasks = cmGetMessagesForObject(Object.Customer);
			For Each vCustomerTasksRow In vCustomerTasks Do
				vTasksRow = vTasks.Add();
				FillPropertyValues(vTasksRow, vCustomerTasksRow);
			EndDo;
		EndIf;
		For Each vTasksRow In vTasks Do
			If vTasksRow.IsClosed Then
				vShowClosed = True;
				Continue;
			EndIf;	
			TasksTab.Add(New Structure("PopUp, Remarks, ReservationTaskArea, ValidFromDate, ValidToDate", vTasksRow.PopUp, vTasksRow.Remarks, vTasksRow.ReservationTaskArea, vTasksRow.ValidFromDate, vTasksRow.ValidToDate));
			vTaskRemarks = TrimAll(vTasksRow.Remarks);
			If Left(vTaskRemarks, 1) = "•" Then
				TTasks = TTasks + vTaskRemarks + Chars.LF;
			Else
				TTasks = TTasks + "• " + vTaskRemarks + Chars.LF;
			EndIf;
		EndDo;
	ElsIf ValueIsFilled(Object.Reservation) Then
		vTasks = cmGetMessagesForObject(Object.Reservation, True);
		For Each vTasksRow In vTasks Do
			If vTasksRow.IsClosed Then
				vShowClosed = True;
				Continue;
			EndIf;
			TasksTab.Add(New Structure("PopUp, Remarks, ReservationTaskArea, ValidFromDate, ValidToDate", vTasksRow.PopUp, vTasksRow.Remarks, vTasksRow.ReservationTaskArea, vTasksRow.ValidFromDate, vTasksRow.ValidToDate));
			vTaskRemarks = TrimAll(vTasksRow.Remarks);
			If Left(vTaskRemarks, 1) = "•" Then
				TTasks = TTasks + vTaskRemarks + Chars.LF;
			Else
				TTasks = TTasks + "• " + vTaskRemarks + Chars.LF;
			EndIf;
		EndDo;
	EndIf;
	TTasks = TrimAll(TTasks);
	Items.DecorationTasks.Title = TTasks;
	If IsBlankString(TTasks) Then
		Items.DecorationTasks.Visible = False;
	Else
		Items.DecorationTasks.Visible = True;
	EndIf;
	Items.ShowClosedTasks.Visible = vShowClosed;
EndProcedure // FillTasksPresentation

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestGroupOpeningAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmCreateGuestGroup();
	ValueToFormAttribute(vObj, "Object");
	GuestGroupOnChangeAtServer();	
EndProcedure // GuestGroupOpeningAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure InsertServicePackageAtServer(pServicePackage)
	vObj = FormAttributeToValue("Object");
	// Fill accommodation plan by dates
	vRoomRates = vObj.pmGetAccommodationPlan();
	// Get complex commission
	vComplexCommission = vObj.pmGetComplexCommission();
	// Get package services	          
	vServicePackagesServices = Catalogs.ServicePackages.GetServices(pServicePackage, Object.CheckInDate, Object.PriceCalculationDate);
	vPackageServices = vServicePackagesServices.FindRows(New Structure("ClientType", Object.ClientType));
	If ValueIsFilled(Object.ClientType) And vPackageServices.Count() = 0 Then
		vPackageServices = vServicePackagesServices.FindRows(New Structure("ClientType", Catalogs.ClientTypes.EmptyRef()));
	EndIf;
	// Choose rows of the client type choosen
	For Each vServicePackageRow In vPackageServices Do
		// Check accommodation type
		If ValueIsFilled(vServicePackageRow.AccommodationType) And 
		   vServicePackageRow.AccommodationType <> Object.AccommodationType Then
			Continue;
		EndIf;
		
		// Get accounting date from the package service settings
		vAccountingDatesList = New ValueList();
		If ValueIsFilled(vServicePackageRow.AccountingDate) Then
			vAccountingDatesList.Add(BegOfDay(vServicePackageRow.AccountingDate));
		ElsIf vServicePackageRow.AccountingDayNumber = 9999 Then
			vAccountingDatesList.Add(BegOfDay(Object.CheckOutDate));
		ElsIf vServicePackageRow.AccountingDayNumber <> 0 Then
			vAccountingDatesList.Add(BegOfDay(Object.CheckInDate) + (vServicePackageRow.AccountingDayNumber - 1)*24*3600);
		ElsIf ValueIsFilled(vServicePackageRow.QuantityCalculationRule) Then
			vCurDate = BegOfDay(Object.CheckInDate);
			While vCurDate <= BegOfDay(Object.CheckOutDate) Do
				// Check calendar day type
				If ValueIsFilled(vServicePackageRow.CalendarDayType) Then
					vRoomRate = Object.RoomRate;
					vPriceCalculationDate = Object.PriceCalculationDate;
					If Object.RoomRates.Count() > 0 Then
						vRoomRatesRow = Object.RoomRates.FindRows(New Structure("AccountingDate", vCurDate));
						If vRoomRatesRow.Count() > 0 Then  
							vRoomRatesRowID = vRoomRatesRow[0]; 
							If ValueIsFilled(vRoomRatesRowID.RoomRate) Then
								vRoomRate = vRoomRatesRowID.RoomRate;
								If ValueIsFilled(vRoomRatesRowID.PriceCalculationDate) Then
									vPriceCalculationDate = vRoomRatesRowID.PriceCalculationDate;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					vCalendarDayType = cmGetCalendarDayType(vRoomRate, vCurDate, Object.CheckInDate, Object.CheckOutDate, , ?(ValueIsFilled(Object.RoomTypeUpgrade), Object.RoomTypeUpgrade, Object.RoomType), vPriceCalculationDate);
					If vCalendarDayType <> vServicePackageRow.CalendarDayType Then
						// Go to the next date
						vCurDate = vCurDate + 24*3600;
						Continue;
					EndIf;
				EndIf;
				// Fill parameters
				vCurPrice = vServicePackageRow.Price;
				vCurCurrency = vServicePackageRow.Currency;
				vCurRemarks = "";
				vIsDayUse = False;
				vWrkDate = vCurDate;
				// Calculate quantity
				vCurQuantity = cmCalculateServiceQuantity(vServicePackageRow.Service, vServicePackageRow.QuantityCalculationRule, 
														  vWrkDate, Object.CheckInDate, Object.CheckOutDate, 
														  vObj, vObj, True, True, False, False, True, True, 
														  vCurPrice, vCurCurrency, vCurRemarks, vIsDayUse);
				// Add current accounting date if quantity being calculated is not equal zero
				If vCurQuantity <> 0 Then
					vAccountingDatesList.Add(vWrkDate);
				EndIf;
				// Go to the next date
				vCurDate = vCurDate + 24*3600;
			EndDo;
		ElsIf Not ValueIsFilled(vServicePackageRow.QuantityCalculationRule) And Not ValueIsFilled(vServicePackageRow.AccountingDate) And vServicePackageRow.AccountingDayNumber = 0 Then
			// Add all days in the reservation period
			vCurDate = BegOfDay(Object.CheckInDate);
			While vCurDate <= BegOfDay(Object.CheckOutDate) Do
				// Check calendar day type
				If ValueIsFilled(vServicePackageRow.CalendarDayType) Then
					vRoomRate = Object.RoomRate;
					vPriceCalculationDate = Object.PriceCalculationDate;
					If Object.RoomRates.Count() > 0 Then
						vRoomRatesRow = Object.RoomRates.FindRows(New Structure("AccountingDate", vCurDate));
						If vRoomRatesRow.Count() > 0 Then  
							vRoomRatesRowID = vRoomRatesRow[0]; 
							If ValueIsFilled(vRoomRatesRowID.RoomRate) Then
								vRoomRate = vRoomRatesRowID.RoomRate;
								If ValueIsFilled(vRoomRatesRowID.PriceCalculationDate) Then
									vPriceCalculationDate = vRoomRatesRowID.PriceCalculationDate;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					vCalendarDayType = cmGetCalendarDayType(vRoomRate, vCurDate, Object.CheckInDate, Object.CheckOutDate, , ?(ValueIsFilled(Object.RoomTypeUpgrade), Object.RoomTypeUpgrade, Object.RoomType), vPriceCalculationDate);
					If vCalendarDayType <> vServicePackageRow.CalendarDayType Then
						// Go to the next date
						vCurDate = vCurDate + 24*3600;
						Continue;
					EndIf;
				EndIf;
				// Add current accounting date
				vAccountingDatesList.Add(vCurDate);
				// Go to the next date
				vCurDate = vCurDate + 24*3600;
			EndDo;
		EndIf;
		
		For Each vAccountingDatesItem In vAccountingDatesList Do
			vAccountingDate = vAccountingDatesItem.Value;
			
			// Add service
			vCurRow = Object.Services.Add();
			vCurRow.Service = vServicePackageRow.Service;
			vCurRow.IsRoomRevenue = vCurRow.Service.IsRoomRevenue;
			vCurRow.IsResourceRevenue = vCurRow.Service.IsResourceRevenue;
			vCurRow.RoomRevenueAmountsOnly = vCurRow.Service.RoomRevenueAmountsOnly;
			vCurRow.IsManual = True;
			vCurRow.IsInPrice = False; // All manual services could not be included in the room price
			vCurRow.IsManualPrice = False;
			vCurRow.Remarks = vServicePackageRow.Remarks;
			// Fill service composition
			If Not IsBlankString(vCurRow.Service.Composition) Then
				vCurRow.Remarks = TrimAll(vCurRow.Service.Composition);
			EndIf;
			
			// Fill accounting date
			vCurRow.AccountingDate = vAccountingDate;
			
			// Fill resource and service times
			If ValueIsFilled(vCurRow.Service.Resource) And ValueIsFilled(vCurRow.AccountingDate) Then
				vCurRow.ServiceResource = vCurRow.Service.Resource;
				vResourceObj = vCurRow.ServiceResource.GetObject();
				vDefaultTimes = vResourceObj.pmGetResourceDefaultChargingTimes(vCurRow.AccountingDate);
				vCurRow.TimeFrom = vDefaultTimes.TimeFrom;
				vCurRow.TimeTo = vDefaultTimes.TimeTo;
				vCurRow.DoResourceReservation = True;
			EndIf;
			
			// Fill service folio according to the charging rules
			vChargingRules = Object.ChargingRules.Unload();
			If Not Object.IgnoreGroupChargingRules Then
				cmAddGuestGroupChargingRules(vChargingRules, Object.GuestGroup);
			EndIf;
			vObj.pmSetServiceFolioBasedOnChargingRules(vCurRow, vChargingRules, True);
			
			// Fill company
			vCurRow.Company = Object.Company;
			If ValueIsFilled(vCurRow.Folio) And vCurRow.Folio.DoNotUpdateCompany Then
				vCurRow.Company = vCurRow.Folio.Company;
			EndIf;
			vCurRow.VATRate = vCurRow.Company.VATRate;
			If Not vCurRow.Company.IsUsingSimpleTaxSystem Then
				vCurRow.VATRate = vServicePackageRow.VATRate;
			EndIf;
			
			// Fill discounts
			If ValueIsFilled(Object.DiscountType) Or Object.Discount <> 0 Then
				If cmIsServiceInServiceGroup(vCurRow.Service, Object.DiscountServiceGroup) Then
					vCurRow.DiscountType = Object.DiscountType;
					vCurRow.DiscountServiceGroup = Object.DiscountServiceGroup;
					vCurRow.DiscountConfirmationText = Object.DiscountConfirmationText;
					If Object.DiscountType.IsAccumulatingDiscount Then
						vObj.pmCalculateAccumulationDiscountForAdditionalService(vCurRow);
					ElsIf Object.DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
						vCurRow.Discount = Object.DiscountType.GetObject().pmGetDiscount(vAccountingDate, vCurRow.Service, Object.Hotel);
					Else
						vCurRow.Discount = Object.Discount;
					EndIf;
				EndIf;
			EndIf;
			
			// Fill calendar day type
			If vCurRow.IsManual And ValueIsFilled(vCurRow.AccountingDate) And ValueIsFilled(Object.RoomRate) Then
				vCurRow.CalendarDayType = cmGetCalendarDayType(Object.RoomRate, vCurRow.AccountingDate, Object.CheckInDate, Object.CheckOutDate, , ?(ValueIsFilled(Object.RoomTypeUpgrade), Object.RoomTypeUpgrade, Object.RoomType), Object.PriceCalculationDate);
			EndIf;
				
			vCurPrice = vServicePackageRow.Price;
			vCurCurrency = vServicePackageRow.Currency;
			vCurRow.Unit = vServicePackageRow.Unit;
			vCurRow.Quantity = vServicePackageRow.Quantity * ?(vServicePackageRow.IsServicePerPerson, ?(Object.NumberOfPersons = 0, 1, Object.NumberOfPersons), 1);
			
			vCurRow.Price = Round(cmConvertCurrencies(vCurPrice, vCurCurrency, , 
			                                          vCurRow.FolioCurrency, 
			                                          vCurRow.FolioCurrencyExchangeRate, 
			                                          ?(ValueIsFilled(vCurRow.AccountingDate), vCurRow.AccountingDate, Object.ExchangeRateDate), Object.Hotel), 2);
													  
			cmPriceOnChange(vCurRow.Price, vCurRow.Quantity, vCurRow.Sum, vCurRow.VATRate, vCurRow.VATSum, vCurRow.AccountingDate);
			// Recalculate service room sales parameters
			cmRecalculateServiceRoomSalesParameters(vCurRow, vObj);
			// Recalculate service discounts
			vObj.pmCalculateServiceDiscounts(vCurRow);
			// Recalculate service commissions
			vObj.pmSetServiceCommissions(vCurRow, vRoomRates, vComplexCommission);
		EndDo;
	EndDo;
	// Calculate totals
	ManualServicesPriceAppearance();
EndProcedure // InsertServicePackageAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionCancelAtServer(pCurRow)
	vDocObj = pCurRow.Ref.GetObject();
	vDocObj.IsCanceled = True;
	vDocObj.IsProcessed = False;
	vDocObj.Write(DocumentWriteMode.Write);
EndProcedure // ActionCancelAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCurrencyExchangeRateAtServer(pHotel, pFolioCurrency, pExchangeRateDate) 
	Return cmGetCurrencyExchangeRate(pHotel, pFolioCurrency, pExchangeRateDate);
EndFunction // GetCurrencyExchangeRateAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function ContactPersonStartChoiceAtServer(pCustomer)
	vContactPersons = New ValueList();
	If ValueIsFilled(pCustomer) Then
		For Each vCPRow In pCustomer.ContactPersons Do
			vCP = "";
			If ValueIsFilled(vCPRow.Client) Then
				vCP = TrimAll(vCPRow.Client.FullName) + 
				      ?(IsBlankString(vCPRow.Position), "", ", " + TrimAll(vCPRow.Position)) + 
				      ?(IsBlankString(vCPRow.Phone), ?(IsBlankString(vCPRow.Client.Phone), "", ", " + TrimAll(vCPRow.Client.Phone)), ", " + TrimAll(vCPRow.Phone)) + 
				      ?(IsBlankString(vCPRow.Phone2), ?(IsBlankString(vCPRow.Client.Fax), "", ", " + TrimAll(vCPRow.Client.Fax)), ", " + TrimAll(vCPRow.Phone2)) + 
				      ?(IsBlankString(vCPRow.EMail), ?(IsBlankString(vCPRow.Client.EMail), "", ", " + TrimAll(vCPRow.Client.EMail)), ", " + TrimAll(vCPRow.EMail)) + 
				      ?(IsBlankString(vCPRow.ContactPerson), "", ", " + TrimAll(vCPRow.ContactPerson));
			Else
				vCP = TrimAll(vCPRow.ContactPerson) + 
				      ?(IsBlankString(vCPRow.Position), "", ", " + TrimAll(vCPRow.Position)) + 
				      ?(IsBlankString(vCPRow.Phone), "", ", " + TrimAll(vCPRow.Phone)) + 
				      ?(IsBlankString(vCPRow.Phone2), "", ", " + TrimAll(vCPRow.Phone2)) + 
				      ?(IsBlankString(vCPRow.EMail), "", ", " + TrimAll(vCPRow.EMail));
			EndIf;
			If Not IsBlankString(vCP) Then
				If vContactPersons.FindByValue(vCP) = Undefined Then
					vContactPersons.Add(vCP);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vContactPersons;
EndFunction // ContactPersonStartChoiceAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ContactPersonAfterChoice(pUC, pExtraParams) Export
	If pUC <> Undefined Then
		Object.ContactPerson = pUC.Value;
		ContactPersonOnChangeAtServer();
	EndIf;
EndProcedure // ContactPersonAfterChoice

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAmenitiesList(pRemarks, pAvailability = 0)
	vAmenitiesList = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Amenities.Description AS Description,
	|	Amenities.Ref AS Ref
	|FROM
	|	Catalog.Amenities AS Amenities
	|WHERE
	|	NOT Amenities.DeletionMark
	|	AND (Amenities.Availability = 0
	|			OR Amenities.Availability <> 0
	|				AND Amenities.Availability = &qAvailability
	|			OR &qAvailability = 0)
	|
	|ORDER BY
	|	Description";
	vQry.SetParameter("qAvailability", pAvailability);
	vAmenities = vQry.Execute().Unload();
	For Each vAmenitiesRow In vAmenities Do
		vAmenitiesListItem = vAmenitiesList.Add(vAmenitiesRow.Ref);
		If StrFind(pRemarks, TrimAll(vAmenitiesRow.Description)) > 0 Then
			vAmenitiesListItem.Check = True;
		EndIf;
	EndDo;
	Return vAmenitiesList;
EndFunction // GetAmenitiesList

// -----------------------------------------------------------------------------
&AtClient
Procedure AmenitiesAfterChoice(pUC, pExtraParams) Export
	vSTag = Char(8226) + " ";
	vETag = " " + Char(8226);
	If pUC <> Undefined Then
		vAmenitiesStr = "";
		For Each vUCItem In pUC Do
			If vUCItem.Check Then
				vAmenitiesStr = vAmenitiesStr + ?(IsBlankString(vAmenitiesStr), vSTag, ", ") + 
				                TrimAll(vUCItem.Value);
			EndIf;
		EndDo;
		If Not IsBlankString(vAmenitiesStr) Then
			vAmenitiesStr = vAmenitiesStr + vETag;
		EndIf;
		// Remove old amenities block from the remarks and add new amenities as first string
		vRemarks = Items[pExtraParams].EditText;
		vSPos = StrFind(vRemarks, vSTag);
		If vSPos > 0 Then
			vEPos = StrFind(vRemarks, vETag, , vSPos + 1);
			If vEPos > 0 Then
				vRemarks = TrimAll(Mid(vRemarks, vEPos + 3));
			EndIf;
		EndIf;
		Object[pExtraParams] = TrimAll(vAmenitiesStr + Chars.LF + vRemarks);
	EndIf;
EndProcedure // AmenitiesAfterChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure IsClosedForEditOnChangeAtServer()
	Items.IsClosedForEdit.Enabled = True;
	Items.RoomType.ReadOnly = False;
	Items.Room.ReadOnly = False;
	Items.Room.TextColor = New Color;
	If Object.IsClosedForEdit Then
		If ValueIsFilled(Object.Room) Then
			Items.Room.TextColor = WebColors.Red;
		EndIf;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToEditClosedForEditDocuments") Then
		Items.IsClosedForEdit.Enabled = False;
		If Object.IsClosedForEdit Then
			If ValueIsFilled(Object.Room) Then
				Items.RoomType.ReadOnly = True;
				Items.Room.ReadOnly = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // IsClosedForEditOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure NoPostAfterAnswer(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.Yes Then
		UpdateNoPostInGroupDocuments();
	EndIf;
EndProcedure // NoPostAfterAnswer

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateNoPostInGroupDocuments()
	vProcessMainRoomDocsOnly = False;
	If Object.RoomRate.RateChargeDirection = Enums.RateChargeDirections.MergeToTheMainRoomGuest Then
		vProcessMainRoomDocsOnly = True;
	EndIf;
	
	vResDocs = Object.GuestGroup.GetObject().pmGetReservations(True, True);
	For Each vResDocsRow In vResDocs Do
		vDoc = vResDocsRow.Reservation;
		If Object.Ref = vDoc Then
			Continue;
		EndIf;
		If vProcessMainRoomDocsOnly Then
			If Not ValueIsFilled(vDoc.AccommodationTemplate) Then
				Continue;
			EndIf;
		EndIf;
		vDocObj = vDoc.GetObject();
		vDocObj.NoPost = Object.NoPost;
		vDocObj.Write(DocumentWriteMode.Write);
		vDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndDo;
	
	vAccDocs = Object.GuestGroup.GetObject().pmGetAccommodations(True);
	For Each vAccDocsRow In vAccDocs Do
		vDoc = vAccDocsRow.Accommodation;
		If Object.Ref = vDoc Then
			Continue;
		EndIf;
		If vProcessMainRoomDocsOnly Then
			If Not ValueIsFilled(vDoc.AccommodationTemplate) Then
				Continue;
			EndIf;
		EndIf;
		vDocObj = vDoc.GetObject();
		vDocObj.NoPost = Object.NoPost;
		vDocObj.Write(DocumentWriteMode.Write);
		vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndDo;
EndProcedure // UpdateNoPostInGroupDocuments

// -----------------------------------------------------------------------------
&AtClient
Function ConvertToNumber(pAmountStr)
	vNumber = "";
	vNumberChars = "0123456789.,";
	For i = 1 To StrLen(pAmountStr) Do
		vChar = Mid(pAmountStr, i, 1);
		If StrFind(vNumberChars, vChar) > 0 Then
			vNumber = vNumber + vChar;
		EndIf;
	EndDo;
	Return vNumber;
EndFunction // ConvertToNumber

// -----------------------------------------------------------------------------
&AtServer
Procedure FillGridAtServer()
	// Main table    
	vPlan = new ValueTable();
	vPlan.Columns.Add("Resources",,NStr("en = 'Resource'; de = 'Ressourcen'; ru = 'Измерение'"));
	vPlan.Columns.Add("AccommodationPlanService", New TypeDescription("CatalogRef.Services"));
	vPlan.Columns.Add("AccommodationPlanAccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
	vPlan.Columns.Add("IsService");
	vPlan.Columns.Add("ResourceName");
	vPlan.Columns.Add("Sort");
    vPlan.Columns.Add("Total",,NStr("en = 'Total'; de = 'Total'; ru = 'Итого'"));
	
	// Get all periods
	vRoomRates = Object.RoomRates.Unload();
	vPeriods = vRoomRates.Copy(, "AccountingDate");
	
	// Add periods services
	vPeriodsServices = Object.Services.Unload(,"AccountingDate");
	For Each vId In vPeriodsServices Do
		If ValueIsFilled(vId.AccountingDate) Then
			If vPeriods.Find(vId.AccountingDate, "AccountingDate") = Undefined Then
				vRowPeriod = vPeriods.Add();
				vRowPeriod.AccountingDate = vId.AccountingDate;
			EndIf;
		EndIf;	
    EndDo;
    
    vRoomRates.Columns.Add("Price");
    vRoomRates.Columns.Add("Service");
    vTypesPlan = New Array();
	vTypesPlan.Add(Type("String"));
	vTypesPlan.Add(Type("Number"));
	vTypesPlan.Add(Type("CatalogRef.RoomRates"));
    vCurDate = BegOfDay(Object.CheckInDate);
	While vCurDate <= BegOfDay(Object.CheckOutDate) Do
    	vColumnName = "Column_"+Format(vCurDate,"DF=yyyyMMdd");
		If vPlan.Columns.Find(vColumnName) = Undefined Then
			vPlan.Columns.Add(vColumnName, New TypeDescription(vTypesPlan),Format(vCurDate,"DF='dd MMM ddd'"));
			vPlan.Columns.Add(vColumnName + "_Amount", New TypeDescription("String"),Format(vCurDate,"DF='dd MMM ddd'"));
			vPlan.Columns.Add(vColumnName + "_Unit", New TypeDescription("String"),Format(vCurDate,"DF='dd MMM ddd'"));
        EndIf;	
        If vPeriods.Find(vCurDate) = Undefined Then
            vRowPeriod = vPeriods.Add();
            vRowPeriod.AccountingDate = vCurDate;
        EndIf; 
		vCurDate = vCurDate + 24*3600;
	EndDo;
    
    vPeriods.GroupBy("AccountingDate");
    vPeriods.Sort("AccountingDate");
	
	vServices = Object.Services.Unload();
	// Fill
	vPrevRoomRates = New Structure("Room, RoomType, RoomRate, AccommodationTemplate, Adults, Children, Discount, Price, BoardPlace, ClientType, SourceOfBusiness, MarketingCode, ServicePackage");
	For Each vRowPeriod In vPeriods Do
		vCurDate = vRowPeriod.AccountingDate;
		// Add columns
		vColumnName = "Column_"+Format(vCurDate,"DF=yyyyMMdd");
		If vPlan.Columns.Find(vColumnName) = Undefined Then
			vPlan.Columns.Add(vColumnName,,Format(vCurDate,"DF='dd MMM ddd'"));
		EndIf;	
		vCurRoomRatesRow = vRoomRates.Find(vCurDate, "AccountingDate");
		vRowServices = vServices.FindRows(New Structure("AccountingDate,IsRoomRevenue,IsInPrice",vCurDate, True, True));
		// Fill rows
		// Room	
		FillRowPan(vPlan, "Room", NStr("en = 'Room'; de = 'Zimmer'; ru = 'Номер'"),	vColumnName, 1, vPrevRoomRates.Room, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.Room), Object.Room, Undefined, False);
		// Room type
		FillRowPan(vPlan, "RoomType", NStr("en = 'Room type'; de = 'Zimmertyp'; ru = 'Тип номера'"), vColumnName, 2, vPrevRoomRates.RoomType, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.RoomType), Object.RoomType, Undefined, False);
		// Room rate
		FillRowPan(vPlan, "RoomRate", NStr("en = 'Room rate'; de = 'Tarif'; ru = 'Тариф'"), vColumnName, 3, vPrevRoomRates.RoomRate, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.RoomRate), Object.RoomRate, Undefined, False);
		// Calendar day type
		If vRowServices.Count() > 0 Then
			FillRowPan(vPlan, "CalendarDayType", NStr("en = 'Calendar day type'; de = 'Kalendertagestyp'; ru = 'Тип дня календаря'"), vColumnName, 4, Undefined, vRowServices[0].CalendarDayType, Undefined, Undefined, False);
			If ValueIsFilled(vRowServices[0].PriceTag) Then
				FillRowPan(vPlan, "PriceTag", NStr("en = 'Price tag'; de = 'Preisschild'; ru = 'Признак цены'"), vColumnName, 5, Undefined, vRowServices[0].PriceTag, Undefined, Undefined, False);
			EndIf;
			vOPRows = Object.OccupationPercents.FindRows(New Structure("AccountingDate", vCurDate));
			If vOPRows.Count() > 0 Then
				FillRowPan(vPlan, "OccupancyPercent", NStr("en = 'Occupancy %'; de = 'Auslastung %'; ru = '% Загрузки'"), vColumnName, 6, Undefined, Format(vOPRows[0].OccupationPercent, "ND=4; NFD=1; NZ=") + "%", Undefined, Undefined, False);
			EndIf;
		EndIf;	
		// Client type
		FillRowPan(vPlan, "ClientType", NStr("en = 'Client type'; de = 'Kundentyp'; ru = 'Тип клиента'"), vColumnName, 7, vPrevRoomRates.ClientType, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.ClientType), Object.ClientType, Undefined, False);
		// Source of business
		FillRowPan(vPlan, "SourceOfBusiness", NStr("en = 'Source'; de = 'Quelle'; ru = 'Источник'"), vColumnName, 8, vPrevRoomRates.SourceOfBusiness, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.SourceOfBusiness), Object.SourceOfBusiness, Undefined, False);
		// Marketing code
		FillRowPan(vPlan, "MarketingCode", NStr("en = 'Market'; de = 'Market'; ru = 'Маркет'"), vColumnName, 9, vPrevRoomRates.MarketingCode, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.MarketingCode), Object.MarketingCode, Undefined, False);
		// Board place
		If Items.BoardPlace.Visible Then
			FillRowPan(vPlan, "BoardPlace", NStr("en = 'Board place'; de = 'Essensort'; ru = 'Место питания'"), vColumnName, 10, vPrevRoomRates.BoardPlace, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.BoardPlace), Object.BoardPlace, Undefined, False);
		EndIf;
		// Terms
		If Items.ServicePackage.Visible Then
			FillRowPan(vPlan, "Terms", NStr("en = 'Terms'; de = 'Essen'; ru = 'Питание'"), vColumnName, 11, vPrevRoomRates.ServicePackage, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.ServicePackage), Object.ServicePackage, Undefined, False);
		EndIf;
		// Accommodation template
		FillRowPan(vPlan, "AccommodationTemplate", NStr("en = 'Persons'; de = 'Personen'; ru = 'Состав'"), vColumnName, 12, vPrevRoomRates.AccommodationTemplate, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.AccommodationTemplate), Object.AccommodationTemplate, Undefined, False);
		// Adults
		FillRowPan(vPlan, "Adults", NStr("en = 'Adults'; de = 'Erwachsene'; ru = 'Взрослых'"), vColumnName, 13, vPrevRoomRates.Adults, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.NumberOfAdults), Object.NumberOfAdults, Undefined, False);
		// Children
		FillRowPan(vPlan, "Children", NStr("en = 'Children'; de = 'Kinder'; ru = 'Детей'"), vColumnName, 14, vPrevRoomRates.Children, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.NumberOfTeenagers+vCurRoomRatesRow.NumberOfTeenagers+vCurRoomRatesRow.NumberOfInfants), Object.NumberOfChildren+Object.NumberOfInfants+Object.NumberOfTeenagers, Undefined, False);
		// Discount
		FillRowPan(vPlan, "Discount", NStr("en = 'Discount %'; de = 'Rabatt %'; ru = 'Скидка %'"), vColumnName, 15, vPrevRoomRates.Discount, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.Discount), Object.Discount, Undefined, False);
	EndDo;
        
    If vPlan.Count() > 0 Then
        // Add prices
        vServicesTotals = New ValueTable;
        vResortFeeTotals = New ValueTable;
        // Get totals
        FillPricesAndServices(Object, vPlan, vServicesTotals, vResortFeeTotals, GuestPayOnly);
        // Totals by days
        vAccountingDateTotals = vServicesTotals.Copy();
		s = 0;
		While s < vAccountingDateTotals.Count() Do
			vServicesTotalsRow = vAccountingDateTotals.Get(s);
			vService = vServicesTotalsRow.Service;
			If ValueIsFilled(vService) And TypeOf(vService) = Type("CatalogRef.Services") And 
			   ValueIsFilled(vService.QuantityCalculationRule) Then
				vAccountingDateMove = cmGetAccountingDateMove(vService.QuantityCalculationRule, False, Object, True);
				If vAccountingDateMove <> 0 Then
			        vServicesTotalsRow.AccountingDate = vServicesTotalsRow.AccountingDate - 24*3600;
				EndIf;
			ElsIf vService = "RoomPrice" Then
				vAccountingDateTotals.Delete(s);
				Continue;
			EndIf;
			s = s + 1;
		EndDo;
        vAccountingDateTotals.GroupBy("AccountingDate", "Amount");
        vAccountingDateTotals.Sort("AccountingDate");
        
        vTotal = vAccountingDateTotals.Total("Amount"); 
		
		// Payments
		vTotalSumPayed = 0;
		If ValueIsFilled(Object.Ref) Then
			FillRowPan(vPlan, "Payments", NStr("en = 'Payments'; de = 'Zahlungen'; ru = 'Платежи'"), "Total", 998, Undefined, 0, 0, Undefined, False);
			
			vPayments = cmGetReservationPayments(Object.Ref, GuestPayOnly);
			For Each vPaymentsRow In vPayments Do
				vCurDate = vPaymentsRow.AccountingDate;
				vColumnName = "Column_"+Format(vCurDate, "DF=yyyyMMdd");
				If vPlan.Columns.Find(vColumnName) = Undefined Then
					vDayIndex = -1;
					For Each vPeriodsRow In vPeriods Do
						If vPeriodsRow.AccountingDate >= vCurDate Then
							vDayIndex = vPeriods.IndexOf(vPeriodsRow);
							Break;
						EndIf;
					EndDo;
					If vDayIndex = -1 Then
						vPlan.Columns.Insert(0, vColumnName, , Format(vCurDate, "DF='dd MMM ddd'"));
						vPeriodsRow = vPeriods.Insert(0);
						vPeriodsRow.AccountingDate = vCurDate;
					Else
						vPlan.Columns.Insert(vDayIndex, vColumnName, , Format(vCurDate, "DF='dd MMM ddd'"));
						If vPeriodsRow <> Undefined And vCurDate <> vPeriodsRow.AccountingDate Then
							vPeriodsRow = vPeriods.Insert(vDayIndex);
							vPeriodsRow.AccountingDate = vCurDate;
						EndIf;
					EndIf;
				EndIf;
				
				// Payments
				vCurSumPayed = cmConvertCurrencies(vPaymentsRow.SumExpense, vPaymentsRow.FolioCurrency, , Object.ReportingCurrency, , Object.ExchangeRateDate, Object.Hotel); 
				FillRowPan(vPlan, "Payments", NStr("en = 'Payments'; de = 'Zahlungen'; ru = 'Платежи'"), vColumnName, 997, Undefined, cmFormatSum(-vCurSumPayed, Object.ReportingCurrency, "NZ=0.00"), 0, Undefined, False);
				vTotalSumPayed = vTotalSumPayed + vCurSumPayed;
			EndDo;
			
			// Total payed
	        vRow = vPlan.Find("Payments");
			If Not vRow = Undefined Then
	           	vRow.Total = cmFormatSum(-vTotalSumPayed, Object.ReportingCurrency, "NZ=0.00");      	
			EndIf; 
			
			// Balance
			FillRowPan(vPlan, "Splitter", NStr("en = ''; de = ''; ru = ''"), "Total", 998, Undefined, "------------------------", 0, Undefined, False);
			FillRowPan(vPlan, "Balance", NStr("en = 'Balance'; de = 'Bilanz'; ru = 'Баланс'"), "Total", 999, Undefined, cmFormatSum(vTotal - vTotalSumPayed, Object.ReportingCurrency, "NZ=0.00"), 0, Undefined, False);
		EndIf;
       
        // Add items to the form
        vParentGroup = Items.GroupGrid;
        vAccommodationPlanItem = Items.Find("AccommodationPlan");
        If Not vAccommodationPlanItem = Undefined Then
			vConditionalAppearanceArr = New Array();
			For Each ItemConditionalAppearance In ConditionalAppearance.Items Do
				Try
					For Each ItemFilterConditionalAppearance In ItemConditionalAppearance.Filter.Items Do
						If ItemFilterConditionalAppearance.LeftValue = New DataCompositionField("AccommodationPlan.ResourceName") Then
							vConditionalAppearanceArr.Add(ItemConditionalAppearance);
							Break;
						EndIf;
					EndDo;
				Except
					Continue;
				EndTry;		
			EndDo;
			For Each vConditionalAppearanceItem In vConditionalAppearanceArr Do
				ConditionalAppearance.Items.Delete(vConditionalAppearanceItem);
			EndDo;
			Items.Delete(vAccommodationPlanItem);
            vDeleteArr = New Array;
            vDeleteArr.Add("AccommodationPlan");
            ThisObject.ChangeAttributes(,vDeleteArr);
        EndIf; 
        vArrTypes = New Array;
        vArrTypes.Add(Type("ValueTable"));
        vTypeDescription = New TypeDescription(vArrTypes);
        vArrAttributes = New Array;
        vTabName = "AccommodationPlan"; 
        vTabTitle = "AccommodationPlan";
        vArrAttributes.Add(New FormAttribute(vTabName, vTypeDescription, "", vTabTitle));
        
        For Each vColumn In vPlan.Columns Do
            vTypes = New Array;
            For Each vTypeRow In vColumn.ValueType.Types() Do
                If vTypeRow <> Type("Null") Then
                    vTypes.Add(vTypeRow);
                EndIf;
            EndDo;
            vArrAttributes.Add(New FormAttribute(vColumn.Name, New TypeDescription(vTypes), vTabName, vColumn.Title));
        EndDo;
        
        ThisObject.ChangeAttributes(vArrAttributes);      
        vTabForm = Items.Add(vTabTitle, Type("FormTable"), vParentGroup);
        vTabForm.DataPath = vTabName;
        vTabForm.Representation = TableRepresentation.List;
        vTabForm.CommandBarLocation = FormItemCommandBarLabelLocation.None;
        vTabForm.ChangeRowSet = False;    
        vTabForm.Footer = True;
        vTabForm.ChangeRowOrder = False;
        vTabForm.ChangeRowSet = False;
		vTabForm.RowSelectionMode = TableRowSelectionMode.Cell;
		vTabForm.SelectionMode = TableSelectionMode.SingleRow;
       	vTabForm.SetAction("Selection", "SelectionServiceInAccommodationPlan");
		vTabForm.SetAction("OnEditEnd", "OnEditEndInAccommodationPlan");
		vTabForm.SetAction("BeforeRowChange", "BeforeRowChangeInAccommodationPlan");
		vTabForm.SetAction("OnStartEdit", "OnStartEditInAccommodationPlan");
		vTabForm.SetAction("OnActivateField", "OnActivateFieldInAccommodationPlan");

        vArrColumns = New Array;
        For Each vColumn In vPlan.Columns Do 
            If vColumn.Name = "Sort" Then
                Continue;
            EndIf;	
            vNewItem = Items.Add(vColumn.Name, Type("FormField"), vTabForm);
            vNewItem.DataPath = vTabName + "." + vColumn.Name;
            vNewItem.FooterHorizontalAlign = ItemHorizontalLocation.Right;
            vNewItem.ShowInFooter = True;
			If vColumn.Name = "IsService" Or vColumn.Name = "AccommodationPlanService" Or 
			   vColumn.Name = "ResourceName" Or vColumn.Name = "AccommodationPlanAccommodationType" Or 
			   StrFind(vColumn.Name, "Column_") <> 0 And
			   (StrFind(vColumn.Name, "_Amount") <> 0 Or StrFind(vColumn.Name, "_Unit") <> 0) Then
                vNewItem.Visible = False;
            EndIf;
            If vColumn.Name = "Resources" Then
                vNewItem.FixingInTable = FixingInTable.Left;
                vNewItem.BackColor = New Color(242,242,242);
                vNewItem.FooterText = NStr("en = 'TOTAL:'; de = 'TOTAL:'; ru = 'ИТОГО:'");
                vNewItem.FooterFont = New Font(,12,True);
            EndIf;
            If vColumn.Name = "Total" Then
                vNewItem.FixingInTable = FixingInTable.Right;
                vNewItem.HorizontalAlign = ItemHorizontalLocation.Right;
                vNewItem.FooterText = cmFormatSum(vTotal, Object.ReportingCurrency, "NZ=0.00");
                vNewItem.FooterFont = New Font(,12,True);
                vNewItem.BackColor = New Color(242,242,242);
                vNewItem.FooterHorizontalAlign = ItemHorizontalLocation.Right;
            EndIf;
            If StrStartsWith(vColumn.Name, "Column_")  Then
                vArrColumns.Add(vColumn.Name);
                vStrDate = StrReplace(StrReplace(StrReplace(vColumn.Name, "Column_", ""), "_Amount", ""), "_Unit", "");
                vAccDate = Date(vStrDate);
                vRowTotal = vAccountingDateTotals.Find(vAccDate);
				vNewItem.Type = FormFieldType.InputField;
				vNewItem.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;
				vNewItem.CreateButton = False;
				vNewItem.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
				vNewItem.QuickChoice = False;
				vNewItem.DropListButton = False;
				vNewItem.OpenButton = False;
				vNewItem.ChooseType = False;
				vNewItem.SetAction("StartChoice", "StartChoiceInAccommodationPlan");
				vNewItem.SetAction("ChoiceProcessing", "AccommodationPlanChoiceProcessing");
                If Not vRowTotal = Undefined Then
                    vNewItem.FooterText = cmFormatSum(vRowTotal.Amount, Object.ReportingCurrency, "NZ=0.00");
                EndIf; 
            EndIf; 
        EndDo;
        
        // Add conditional appearance
        FillConditionalAppearance(vArrColumns, vServicesTotals);

        ThisObject.ValueToFormAttribute(vPlan, vTabName);
		
		FillConditionalAppearanceByAccommodationPlan();
    EndIf;
EndProcedure // FillGridAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillConditionalAppearanceByAccommodationPlan()
	If Items.Find("AccommodationPlan") <> Undefined Then
		vColumnsArr = New Array();
		For Each vAccommodationPlanColumns In Items.AccommodationPlan.ChildItems Do
			If StrStartsWith(vAccommodationPlanColumns.Name, "Column_") And 
					   StrFind(vAccommodationPlanColumns.Name, "_Amount") = 0 And StrFind(vAccommodationPlanColumns.Name, "_Unit") = 0 Then
				vColumnsArr.Add(vAccommodationPlanColumns);			   
			EndIf;
		EndDo;
		If vColumnsArr.Count() > 0 Then
			For Each vAccommodationPlanRow In ThisObject.AccommodationPlan Do
				If vAccommodationPlanRow.IsService Then
					For Each vAccommodationPlanColumns In vColumnsArr Do
					   If ValueIsFilled(vAccommodationPlanRow[vAccommodationPlanColumns.Name]) Then  
							vItemConditionalAppearance = ConditionalAppearance.Items.Add();
							vItemConditionalAppearance.Appearance.SetParameterValue("Text", TrimAll(vAccommodationPlanRow[vAccommodationPlanColumns.Name]) + " " + vAccommodationPlanRow[vAccommodationPlanColumns.Name + "_Unit"] + " = " + vAccommodationPlanRow[vAccommodationPlanColumns.Name + "_Amount"]);
							vItemConditionalAppearance.Use = True;
							ItemConditions1 = vItemConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
							ItemConditions1.LeftValue = New DataCompositionField("AccommodationPlan.ResourceName");
							ItemConditions1.ComparisonType = DataCompositionComparisonType.Equal;
							ItemConditions1.RightValue = vAccommodationPlanRow["ResourceName"];
							ItemConditions1.Use = True;
							If ValueIsFilled(vAccommodationPlanRow.AccommodationPlanAccommodationType) Then
								ItemConditions2 = vItemConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
								ItemConditions2.LeftValue = New DataCompositionField("AccommodationPlan.AccommodationPlanAccommodationType");
								ItemConditions2.ComparisonType = DataCompositionComparisonType.Equal;
								ItemConditions2.RightValue = vAccommodationPlanRow.AccommodationPlanAccommodationType;
								ItemConditions2.Use = True;
							EndIf;
							ItemAppearance = vItemConditionalAppearance.Fields.Items.Add();
							ItemAppearance.Field = New DataCompositionField(vAccommodationPlanColumns.Name);
							ItemAppearance.Use = True;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // FillConditionalAppearanceByAccommodationPlan

// -----------------------------------------------------------------------------
&AtServer
Procedure AccommodationPlanAttributeUpdate(pAccountingDate, pAttributeValue, pOldAttributeValue, pAttributeName)
	vObj = FormAttributeToValue("Object");
	If TypeOf(pAttributeValue) = Type("CatalogRef.CalendarDayTypes") Then
		vServicesRows = vObj.Services.FindRows(New Structure("AccountingDate, IsManual", pAccountingDate, False));
		For Each vRow In vServicesRows Do
			If ValueIsFilled(vRow.CalendarDayType) And vRow.CalendarDayType <> pAttributeValue Then
				vRow.CalendarDayType = pAttributeValue;
				vRow.CalendarDayTypeIsChanged = True;
			EndIf;
		EndDo;
	ElsIf TypeOf(pAttributeValue) = Type("CatalogRef.PriceTags") Then
		vServicesRows = vObj.Services.FindRows(New Structure("AccountingDate, IsInPrice, IsManual", pAccountingDate, True, False));
		For Each vRow In vServicesRows Do
			If ValueIsFilled(vRow.PriceTag) And vRow.PriceTag <> pAttributeValue Then
				vRow.PriceTag = pAttributeValue;
				vRow.CalendarDayTypeIsChanged = True;
			EndIf;
		EndDo;
	Else		
		// Delete manual price services for the accounting date choosen
		vMPServicesRows = vObj.Services.FindRows(New Structure("AccountingDate, IsRoomRevenue, IsManualPrice", pAccountingDate, True, True));
		For Each vMPServicesRow In vMPServicesRows Do
			vObj.Services.Delete(vMPServicesRow);
		EndDo;
		// Update room rates row
		vRoomRatesRow = vObj.RoomRates.Find(pAccountingDate, "AccountingDate");
		If vRoomRatesRow = Undefined Then
			vRoomRatesRow = vObj.RoomRates.Add();
			vRoomRatesRow.AccountingDate = pAccountingDate;
		EndIf;
		If pAttributeName = "Terms" Then
			vRoomRatesRow.ServicePackage = pAttributeValue;
		Else
			vRoomRatesRow[pAttributeName] = pAttributeValue;
		EndIf;
		// Reset price calculation date
		If pAttributeName = "RoomRate" Then
			vRoomRatesRow.PriceCalculationDate = '00010101';
			If BegOfDay(pAccountingDate) = BegOfDay(CurrentSessionDate()) Then
				If pAttributeValue <> vObj.RoomRate Then
					If ValueIsFilled(pAttributeValue) Then
						vObj.RoomRate = pAttributeValue;
						BuildRoomRateGroupCollapsedTitle(vObj);
					EndIf;	
				EndIf;
			EndIf;
		EndIf;
		// Check room rates row and if it corresponds to the document parameters then delete it
		If Not ValueIsFilled(vRoomRatesRow.AccommodationType) And
		   Not ValueIsFilled(vRoomRatesRow.Room) And 
		   Not ValueIsFilled(vRoomRatesRow.RoomType) And 
		   Not ValueIsFilled(vRoomRatesRow.RoomRate) And 
		   Not ValueIsFilled(vRoomRatesRow.PriceCalculationDate) And 
		   Not ValueIsFilled(vRoomRatesRow.AccommodationTemplate) And 
		   Not ValueIsFilled(vRoomRatesRow.ClientType) And 
		   Not ValueIsFilled(vRoomRatesRow.SourceOfBusiness) And 
		   Not ValueIsFilled(vRoomRatesRow.MarketingCode) And 
		   Not ValueIsFilled(vRoomRatesRow.ServicePackage) And 
		   Not ValueIsFilled(vRoomRatesRow.BoardPlace) And 
		   IsBlankString(vRoomRatesRow.Discount) And 
		   IsBlankString(vRoomRatesRow.AgentCommission) And 
		   Not vRoomRatesRow.DoNotChangeAvailability And 
		   Not vRoomRatesRow.IsBookedOut Then
			vObj.RoomRates.Delete(vRoomRatesRow);
		EndIf;
		vObj.RoomRates.Sort("AccountingDate, ChangeTime");
	EndIf;
	ValueToFormAttribute(vObj, "Object");
	Modified = True;
	TotalSum = CalculateTotalServices(, , False, True, True);
	vCurRow = Items["AccommodationPlan"].CurrentRow;
	FillGridAtServer();
	Try
		CurrentItem = Items["AccommodationPlan"];
		Items["AccommodationPlan"].CurrentItem = Items["Column_" + Format(pAccountingDate, "DF=yyyyMMdd")];
		Items["AccommodationPlan"].CurrentRow = vCurRow;
	Except
	EndTry;
EndProcedure // AccommodationPlanAttributeUpdate

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateRoomPriceAtServer()
	vDoCalculate = False;
	For Each vField In ChangedFieldsOfAccommodationPlan Do
		vSelRow = vField.Value;
		vFieldName = vSelRow.Field;
		If vSelRow.Continue Then
			Continue;
		EndIf;	
		vServicesRows = Object.Services.FindRows(New Structure("AccountingDate, IsInPrice", vSelRow.AccountingDate, True));
		// Calculate in price amount without accommodation
		vRoomRevenueRow = Undefined;
		vPackagesSum = 0;
		vPackagesDiscountSum = 0;
		For Each vServicesRow In vServicesRows Do
			If Not vServicesRow.IsRoomRevenue Or vServicesRow.IsRoomRevenue And vRoomRevenueRow <> Undefined Then
				vPackagesSum = vPackagesSum + vServicesRow.Sum;
				vPackagesDiscountSum = vPackagesDiscountSum + vServicesRow.DiscountSum;
			Else
				If vRoomRevenueRow = Undefined Then
					vRoomRevenueRow = vServicesRow;
				EndIf;
			EndIf;
		EndDo;
		If vRoomRevenueRow <> Undefined Then
			vPackagesAmount = vPackagesSum - vPackagesDiscountSum;
			vNewAccAmount = vSelRow.RoomPrice - vPackagesAmount;
			vOldAccAmount = vRoomRevenueRow.Sum - vRoomRevenueRow.DiscountSum;
			vRateDiff = vOldAccAmount - vNewAccAmount;
			
			// Update prices row
			vRoomRevenueRow.Sum = vNewAccAmount;
			vRoomRevenueRow.Price = Round(vRoomRevenueRow.Sum / ?(vRoomRevenueRow.Quantity = 0, 1, vRoomRevenueRow.Quantity), 2);
			vRoomRevenueRow.IsManualPrice = True;
			If vRoomRevenueRow.DiscountSum <> 0 Then
				vRoomRevenueRow.DiscountSum = 0;
				vRoomRevenueRow.Discount = 0;
				vRoomRevenueRow.DiscountIsChanged = True;
			EndIf;
			vObj = FormAttributeToValue("Object");
			vObj.pmCalculateServiceCommissions(vRoomRevenueRow);
			// Recalculate rate sum
			UpdateRowRateSumAtServer(vObj, vRoomRevenueRow.LineNumber);
			
			vDoCalculate = True;
		EndIf;
	EndDo;
	If vDoCalculate Then
		// Recalculate document totals
		ManualServicesPriceAppearance();
		// Refresh grid
		Modified = True;
		vCurRow = Items["AccommodationPlan"].CurrentRow;
		FillGridAtServer();
		Try
			CurrentItem = Items["AccommodationPlan"];
			Items["AccommodationPlan"].CurrentItem = Items[vFieldName];
			Items["AccommodationPlan"].CurrentRow = vCurRow;
		Except
		EndTry;
	EndIf;
EndProcedure // UpdateRoomPriceAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateRoomPrice() Export
	UpdateRoomPriceAtServer();
EndProcedure // UpdateRoomPrice

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateServiceQuantityAtServer()
	For Each vField In ChangedFieldsOfAccommodationPlan Do
		vSelRow = vField.Value;
		vFieldName = vSelRow.Field;
		If vSelRow.Continue Then
			Continue;
		EndIf;	
		vService = vSelRow.Service;
		vAccountingDate = vSelRow.AccountingDate;
		vUpdatedQuantity = vSelRow.ServiceQuantity;
		If ValueIsFilled(vAccountingDate) And ValueIsFilled(vService) Then
			// Change service accounting date if necessary
			If ValueIsFilled(vService.QuantityCalculationRule) Then
				vServiceDateMove = cmGetServiceDateMove(vService.QuantityCalculationRule, , , False, Object, True);
				vAccountingDate = vAccountingDate - vServiceDateMove*24*3600;
			EndIf;
			// Do processing
			vObj = FormAttributeToValue("Object");
			vCurSrv = Undefined;
			vServicesRows = vObj.Services.FindRows(New Structure("AccountingDate, Service", vAccountingDate, vService));
			If vServicesRows.Count() > 0 Then
				If vServicesRows.Count() = 1 Then
					vCurSrv = vServicesRows.Get(0);
					vCurSrv.AccountingDate = vAccountingDate;
					vCurSrv.Quantity = vUpdatedQuantity;
					If Not vCurSrv.IsManual Then
						vCurSrv.IsManualPrice = True;
						vCurSrv.QuantityIsChanged = True;
					EndIf;
					cmQuantityOnChange(vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, vCurSrv.AccountingDate);
					vObj.pmCalculateServiceDiscounts(vCurSrv);
					vObj.pmCalculateServiceCommissions(vCurSrv);
					// Recalculate rate sum
					If Not vCurSrv.IsManual Then
						UpdateRowRateSumAtServer(vObj, vCurSrv.LineNumber, True);
					EndIf;
				Else
					// Update all services for the current accounting date checking accommodation type
					vServiceForGivenAccommodationTypeIsFound = False;
					If ValueIsFilled(vSelRow.AccommodationType) Then
						vWrkUpdatedQuantity = vUpdatedQuantity;
						For Each vCurSrv In vServicesRows Do
							If vCurSrv.AccommodationType = vSelRow.AccommodationType Then
								vServiceForGivenAccommodationTypeIsFound = True;
								
								vCurSrv.AccountingDate = vAccountingDate;
								vCurSrv.Quantity = vWrkUpdatedQuantity;
								If Not vCurSrv.IsManual Then
									vCurSrv.IsManualPrice = True;
									vCurSrv.QuantityIsChanged = True;
								EndIf;
								cmQuantityOnChange(vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, vCurSrv.AccountingDate);
								vObj.pmCalculateServiceDiscounts(vCurSrv);
								vObj.pmCalculateServiceCommissions(vCurSrv);
								// Recalculate rate sum
								If Not vCurSrv.IsManual Then
									UpdateRowRateSumAtServer(vObj, vCurSrv.LineNumber, True);
								EndIf;
								
								vWrkUpdatedQuantity = 0;
							EndIf;
						EndDo;
					EndIf;
					If Not vServiceForGivenAccommodationTypeIsFound Then
						vUpdatedQuantity = vUpdatedQuantity/vServicesRows.Count();
						For Each vCurSrv In vServicesRows Do
							vCurSrv.AccountingDate = vAccountingDate;
							vCurSrv.Quantity = vUpdatedQuantity;
							If Not vCurSrv.IsManual Then
								vCurSrv.IsManualPrice = True;
								vCurSrv.QuantityIsChanged = True;
							EndIf;
							cmQuantityOnChange(vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, vCurSrv.AccountingDate);
							vObj.pmCalculateServiceDiscounts(vCurSrv);
							vObj.pmCalculateServiceCommissions(vCurSrv);
							// Recalculate rate sum
							If Not vCurSrv.IsManual Then
								UpdateRowRateSumAtServer(vObj, vCurSrv.LineNumber, True);
							EndIf;
						EndDo;
					EndIf;	
				EndIf;	
			Else
				vTemplateSrv = GetTemplateServiceRow(vService, vObj);
				If vTemplateSrv = Undefined Then
					tcCommonFunctionOnClientServer.UserMessage(NStr("en='Template service for a new charge is not found!';ru='Не найдена услуга - шаблон для нового начисления!';de='Dienstleistung - Vorlage für die neue Anrechnung wurde nicht gefunden'"));
					Return;
				EndIf;
				vCurSrv = vObj.Services.Add();
				FillPropertyValues(vCurSrv, vTemplateSrv, , "LineNumber");
				vCurSrv.AccountingDate = vAccountingDate;
				vCurSrv.Quantity = vUpdatedQuantity;
				vCurSrv.IsManual = True;
				vCurSrv.IsManualPrice = False;
				vCurSrv.QuantityIsChanged = False;
				cmQuantityOnChange(vCurSrv.Price, vCurSrv.Quantity, vCurSrv.Sum, vCurSrv.VATRate, vCurSrv.VATSum, vCurSrv.AccountingDate);
				vObj.pmCalculateServiceDiscounts(vCurSrv);
				vObj.pmCalculateServiceCommissions(vCurSrv);	
				// Recalculate rate sum
				If Not vCurSrv.IsManual Then
					UpdateRowRateSumAtServer(vObj, vCurSrv.LineNumber, True);
				EndIf;
			EndIf;
			ValueToFormAttribute(vObj, "Object");
			vDoCalculate = True;
		EndIf;
	EndDo;
	If vDoCalculate Then
		// Recalculate document totals
		ManualServicesPriceAppearance();
		
		// Refresh grid
		Modified = True;
		vCurRow = Items["AccommodationPlan"].CurrentRow;
		FillGridAtServer();
		Try
			CurrentItem = Items["AccommodationPlan"];
			Items["AccommodationPlan"].CurrentItem = Items[vFieldName];
			Items["AccommodationPlan"].CurrentRow = vCurRow;
		Except
		EndTry;
	EndIf;
EndProcedure // UpdateServiceQuantityAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateServiceQuantity() Export
	UpdateServiceQuantityAtServer();
EndProcedure // UpdateServiceQuantity

// -----------------------------------------------------------------------------
Function GetTemplateServiceRow(pService, pObj)
	For Each vSrvRow In pObj.Services Do
		If vSrvRow.Service = pService Then
			Return vSrvRow;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction // GetTemplateServiceRow

// -----------------------------------------------------------------------------
&AtServer
Procedure FillConditionalAppearance(Val vArrColumns, Val vServicesTotals)
    vServicesTotals.GroupBy("Service");
    For Each vRow In vServicesTotals Do
        // Set parameters
        vParams = New Structure;
        vParams.Insert("HorizontalAlign", HorizontalAlign.Right);
        
        // Set filter field
        vFilters = New ValueTable;
        vFilters.Columns.Add("Name");
        vFilters.Columns.Add("ComparisonType");
        vFilters.Columns.Add("Value");
        
        vStrFilter = vFilters.Add();
        vStrFilter.Name = "AccommodationPlan.ResourceName";
        vStrFilter.ComparisonType = DataCompositionComparisonType.Equal;
        vStrFilter.Value = String(vRow.Service);
        
        tcCommonFunctionOnClientServer.cmAddConditionalAppearance(ThisObject.ConditionalAppearance, vParams, vFilters, vArrColumns);
	EndDo;
	
	// Add cond. app. for payments
    vParams = New Structure;
    vParams.Insert("HorizontalAlign", HorizontalAlign.Right);
    
    // Set filter field
    vFilters = New ValueTable;
    vFilters.Columns.Add("Name");
    vFilters.Columns.Add("ComparisonType");
    vFilters.Columns.Add("Value");
    
    vStrFilter = vFilters.Add();
    vStrFilter.Name = "AccommodationPlan.ResourceName";
    vStrFilter.ComparisonType = DataCompositionComparisonType.Equal;
    vStrFilter.Value = "Payments";
    
    tcCommonFunctionOnClientServer.cmAddConditionalAppearance(ThisObject.ConditionalAppearance, vParams, vFilters, vArrColumns);
	
    vArrResource = New ValueList;
    vArrResource.Add("Room");
    vArrResource.Add("RoomType");
    vArrResource.Add("RoomRate");
	vArrResource.Add("CalendarDayType");
	vArrResource.Add("PriceTag");
	vArrResource.Add("OccupancyPercent");
    vArrResource.Add("ClientType");
    vArrResource.Add("AccommodationTemplate");
    vArrResource.Add("Adults");
    vArrResource.Add("Children");
    vArrResource.Add("Discount");
    vArrResource.Add("RoomPrice");
    
    // Set parameters
    vParams = New Structure;
    vParams.Insert("Font", New Font(,,True));
    
    // Set filter field
    vFilters = New ValueTable;
    vFilters.Columns.Add("Name");
    vFilters.Columns.Add("ComparisonType");
    vFilters.Columns.Add("Value");
    
    vStrFilter = vFilters.Add();
    vStrFilter.Name = "AccommodationPlan.ResourceName";
    vStrFilter.ComparisonType = DataCompositionComparisonType.InList;
    vStrFilter.Value = vArrResource;
    
    // Format fields
    vFields = New Array;
    vFields.Add("Resources");
    
    tcCommonFunctionOnClientServer.cmAddConditionalAppearance(ThisObject.ConditionalAppearance, vParams, vFilters, vFields);
EndProcedure // FillConditionalAppearance

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure FillRowPan(pTabValue, pAttributeName, pAttributeDescription, pColumnName, pSort, pPrevValue, pCurValue, pStaticValue, pService, pIsService, pAccommodationType = Undefined)
	If pAccommodationType = Undefined Then
		vCurRows = pTabValue.FindRows(New Structure("ResourceName", pAttributeName));
	Else
		vCurRows = pTabValue.FindRows(New Structure("ResourceName, AccommodationPlanAccommodationType", pAttributeName, pAccommodationType));
	EndIf;
	If vCurRows.Count() = 0 Then
		vCurRow = pTabValue.Add();
	Else
		vCurRow = vCurRows.Get(0);
	EndIf;
	vCurRow.ResourceName = pAttributeName;
	vCurRow.Resources = pAttributeDescription;
	vCurRow.Sort = pSort;
	If pService <> Undefined Then
		vCurRow.AccommodationPlanService = pService;
	Else
		vCurRow.AccommodationPlanService = Catalogs.Services.EmptyRef();	
	EndIf;
	vCurRow.IsService = pIsService;
	vCurRow.AccommodationPlanAccommodationType = pAccommodationType;
	If Not ValueIsFilled(pCurValue) Then
		If Not ValueIsFilled(pPrevValue) Then
			vCurRow[pColumnName] = pStaticValue;
		Else
			vCurRow[pColumnName] = pPrevValue;
		EndIf;	
	Else
		vCurRow[pColumnName] = pCurValue;
    EndIf;	
   	pPrevValue = vCurRow[pColumnName];
EndProcedure	

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure FillPricesAndServices(pObject, pPlan, pPrices = Undefined, pResortFee = Undefined, pGuestPayOnly = False)
    pPrices = New ValueTable();
    pPrices.Columns.Add("Amount", cmGetSumTypeDescription());
    pPrices.Columns.Add("Service");
    pPrices.Columns.Add("AccommodationPlanAccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
    pPrices.Columns.Add("Sort", cmGetNumberTypeDescription(1, 0));
    pPrices.Columns.Add("AccountingDate", cmGetDateTypeDescription());
    pPrices.Columns.Add("Quantity", cmGetQuantityTypeDescription());
	
	pResortFee = pPrices.Copy();
	
	vServices = pObject.Services.Unload();
	
	// Add services from bound orders
	If ValueIsFilled(pObject.Ref) Then
		vOrders = Orders.cmGetOrdersByParentDoc(pObject.Ref);
		For Each vOrdersRow In vOrders Do
			If ValueIsFilled(vOrdersRow.Charge) And vOrdersRow.Charge.Posted Then
				vServicesRow = vServices.Add();
				FillPropertyValues(vServicesRow, vOrdersRow.Charge);
				vServicesRow.AccountingDate = BegOfDay(vOrdersRow.Charge.Date);
			EndIf;
		EndDo;
	EndIf;
	
    For Each vRow In vServices Do
		If pGuestPayOnly Then
			If ValueIsFilled(vRow.Folio) Then
				vFolioCustomer = vRow.Folio.Customer;
				If ValueIsFilled(vFolioCustomer) And Not vFolioCustomer.IsIndividual Then
					Continue;
				EndIf;
			EndIf;
		EndIf;
		
		If ValueIsFilled(vRow.Service) And vRow.Service.IsResortFee Then
	        vNewRow = pResortFee.Add();
		Else
	        vNewRow = pPrices.Add();
		EndIf;
        If vRow.IsInPrice And vRow.IsRoomRevenue Then
            vNewRow.Service = "Price";
            vNewRow.Sort = 0;
            vNewRow.AccountingDate = vRow.AccountingDate;
	        vNewRow.Quantity = vRow.Quantity;
	        vNewRow.Amount = vRow.Sum - vRow.DiscountSum;
			
			vRoomRow = Undefined;
			vRoomRows = pPrices.FindRows(New Structure("Service, Sort, AccountingDate", "RoomPrice", 2, vRow.AccountingDate));
			If vRoomRows.Count() > 0 Then
				vRoomRow = vRoomRows.Get(0);
			Else
				vRoomRow = pPrices.Add();
				vRoomRow.Service = "RoomPrice";
				vRoomRow.Sort = 2;
				vRoomRow.AccountingDate = vRow.AccountingDate;
				vRoomRow.Quantity = vRow.Quantity;
			EndIf;
			vRoomRow.Amount = vRoomRow.Amount + vRow.Sum - vRow.DiscountSum;
        Else	
			vService = vRow.Service;
            vNewRow.Service = vService;
            vNewRow.AccommodationPlanAccommodationType = vRow.AccommodationType;
            vNewRow.Sort = ?(vRow.IsInPrice, 1, 3);
            vNewRow.AccountingDate = vRow.AccountingDate;
			vWrkAccountingDate = vRow.AccountingDate;
			If ValueIsFilled(vService) And ValueIsFilled(vService.QuantityCalculationRule) Then
				vAccountingDateMove = cmGetAccountingDateMove(vService.QuantityCalculationRule, vRow.IsManual, pObject, True); 
				If vAccountingDateMove > 0 Then
		        	vNewRow.AccountingDate = vNewRow.AccountingDate + 24*3600;
				ElsIf vAccountingDateMove < 0 Then
					vWrkAccountingDate = vWrkAccountingDate - 24*3600;
				EndIf;
			EndIf;
	        vNewRow.Quantity = vRow.Quantity;
	        vNewRow.Amount = vRow.Sum - vRow.DiscountSum;
			
			If vRow.IsInPrice Then
				vRoomRow = Undefined;
				vRoomRows = pPrices.FindRows(New Structure("Service, Sort, AccountingDate", "RoomPrice", 2, vWrkAccountingDate));
				If vRoomRows.Count() > 0 Then
					vRoomRow = vRoomRows.Get(0);
				Else
					vRoomRow = pPrices.Add();
					vRoomRow.Service = "RoomPrice";
					vRoomRow.Sort = 2;
					vRoomRow.AccountingDate = vWrkAccountingDate;
					vRoomRow.Quantity = vRow.Quantity;
				EndIf;
				vRoomRow.Amount = vRoomRow.Amount + vRow.Sum - vRow.DiscountSum;
			EndIf;
        EndIf; 
	EndDo;
	
	// Process resort fee
    pResortFee.GroupBy("AccountingDate, Service, Sort", "Quantity, Amount");
    pResortFee.Sort("Sort");
    vSort = 7;
    vCurService = Undefined;
	vCurServiceAvailability = Undefined;
    For Each vResortFeeRow In pResortFee Do
        vColumnName = "Column_"+Format(vResortFeeRow.AccountingDate,"DF=yyyyMMdd");
		vColumnNameAmount = "Column_"+Format(vResortFeeRow.AccountingDate,"DF=yyyyMMdd") + "_Amount";
		vColumnNameUnit = "Column_"+Format(vResortFeeRow.AccountingDate,"DF=yyyyMMdd") + "_Unit";
        If pPlan.Columns.Find(vColumnName) = Undefined Then
            pPlan.Columns.Add(vColumnName,,Format(vResortFeeRow.AccountingDate,"DF='dd MMM ddd'"));
		EndIf;
		If pPlan.Columns.Find(vColumnNameAmount) = Undefined Then
			pPlan.Columns.Add(vColumnNameAmount,,Format(vResortFeeRow.AccountingDate,"DF='dd MMM ddd'"));		
		EndIf;
		If pPlan.Columns.Find(vColumnNameUnit) = Undefined Then
			pPlan.Columns.Add(vColumnNameUnit,,Format(vResortFeeRow.AccountingDate,"DF='dd MMM ddd'"));		
		EndIf;	
        vService = vResortFeeRow.Service;
        If vService <> vCurService Then
            vSort = vSort + 1;
        EndIf; 
        If IsBlankString(vService.DescriptionTranslations) Then
            vDesc = vService.Description;
        Else 
            vDesc = cmNStr(vService.DescriptionTranslations);
            If IsBlankString(vDesc) Then
                vDesc = vService.Description;
            EndIf;
        EndIf; 
        FillRowPan(pPlan, String(vService), vDesc, vColumnName, vSort, Undefined, vResortFeeRow.Quantity, Undefined, vResortFeeRow.Service, True);
		FillRowPan(pPlan, String(vService), vDesc, vColumnNameAmount, vSort, Undefined, cmFormatSum(vResortFeeRow.Amount, pObject.ReportingCurrency, "NZ=0.00"), Undefined, vResortFeeRow.Service, True);
		FillRowPan(pPlan, String(vService), vDesc, vColumnNameUnit, vSort, Undefined, TrimAll(vService.Unit), Undefined, vResortFeeRow.Service, True);
        
        vCurService = vService;
    EndDo;
	
	// Fill totals
    vResortFeeTotals = pResortFee.Copy();
    vResortFeeTotals.GroupBy("Service", "Amount");
    For Each vResortFeeTotalsRow In vResortFeeTotals Do
        vRow = pPlan.Find(String(vResortFeeTotalsRow.Service));
        If Not vRow = Undefined Then
            vRow.Total = cmFormatSum(vResortFeeTotalsRow.Amount, pObject.ReportingCurrency, "NZ=0.00");      	
        EndIf;
    EndDo;
	
	// Process normal services
    pPrices.GroupBy("AccountingDate, Service, AccommodationPlanAccommodationType, Sort", "Quantity, Amount");	
    If pPrices.Find("Price") = Undefined Then
        vCurDate = BegOfDay(pObject.CheckInDate);
        While vCurDate <= BegOfDay(pObject.CheckOutDate) Do
            vRowPrice = pPrices.Add();
            vRowPrice.AccountingDate = vCurDate;
            vRowPrice.Service = "Price";
            vRowPrice.Sort = 0;
            vRowPrice.Amount = 0;
            vCurDate = vCurDate + 24*3600;
        EndDo;
    EndIf; 
    If pPrices.Find("RoomPrice") = Undefined Then
        vCurDate = BegOfDay(pObject.CheckInDate);
        While vCurDate <= BegOfDay(pObject.CheckOutDate) Do
            vRowPrice = pPrices.Add();
            vRowPrice.AccountingDate = vCurDate;
            vRowPrice.Service = "RoomPrice";
            vRowPrice.Sort = 2;
            vRowPrice.Amount = 0;
            vCurDate = vCurDate + 24*3600;
        EndDo;
    EndIf; 
    pPrices.Sort("Sort, Service, AccommodationPlanAccommodationType");
    vSort = 7;
    vCurService = Undefined;
	vCurServiceAvailability = Undefined;
    For Each vResultRow In pPrices Do
        vColumnName = "Column_"+Format(vResultRow.AccountingDate,"DF=yyyyMMdd");
		vColumnNameAmount = "Column_"+Format(vResultRow.AccountingDate,"DF=yyyyMMdd") + "_Amount";
		vColumnNameUnit = "Column_"+Format(vResultRow.AccountingDate,"DF=yyyyMMdd") + "_Unit";
        If pPlan.Columns.Find(vColumnName) = Undefined Then
            pPlan.Columns.Add(vColumnName,,Format(vResultRow.AccountingDate,"DF='dd MMM ddd'"));
		EndIf;
		If pPlan.Columns.Find(vColumnNameAmount) = Undefined Then
			pPlan.Columns.Add(vColumnNameAmount,,Format(vResultRow.AccountingDate,"DF='dd MMM ddd'"));		
		EndIf;
		If pPlan.Columns.Find(vColumnNameUnit) = Undefined Then
			pPlan.Columns.Add(vColumnNameUnit,,Format(vResultRow.AccountingDate,"DF='dd MMM ddd'"));		
		EndIf;	
        vService = vResultRow.Service;
        vAccommodationType = vResultRow.AccommodationPlanAccommodationType;
        If vService <> vCurService Then
            vSort = vSort + 1;
			vCurServiceAvailability = Undefined;
			If vService <> "Price" And vService <> "RoomPrice" Then
				If TypeOf(vService) = Type("CatalogRef.Services") And vService.AvailableQuantity <> 0 Then
					vWrkServicesList = New ValueList();
					vWrkServicesList.Add(vService);
					vCurServiceAvailability = cmServicesAvailableQuantityByDays(vWrkServicesList, pObject.Hotel, BegOfDay(pObject.CheckInDate), BegOfDay(pObject.CheckOutDate));
				EndIf;
			EndIf;					
        EndIf; 
        If vService = "Price" Then
            vDesc = NStr("en = 'Accommodation price'; de = 'Preis für Übernachtung'; ru = 'Цена за проживание'");
            FillRowPan(pPlan, String(vService), vDesc, vColumnName, vSort, Undefined, cmFormatSum(vResultRow.Amount, pObject.ReportingCurrency, "NZ=0.00"), Undefined, Undefined, False);
        ElsIf vService = "RoomPrice" Then
            vDesc = NStr("en = 'Room price'; de = 'Zimmer Preis'; ru = 'Цена за номер'");
            FillRowPan(pPlan, String(vService), vDesc, vColumnName, vSort, Undefined, cmFormatSum(vResultRow.Amount, pObject.ReportingCurrency, "NZ=0.00"), Undefined, Undefined, False);
        Else   
            If IsBlankString(vService.DescriptionTranslations) Then
                vDesc = vService.Description;
            Else 
                vDesc = Nstr(vService.DescriptionTranslations);
                If IsBlankString(vDesc) Then
                    vDesc = vService.Description;
                EndIf;
            EndIf; 
			If ValueIsFilled(vAccommodationType) Then
				vDesc = vDesc + " (" + TrimAll(vAccommodationType) + ")";
			EndIf;
			
			vAmountStr = cmFormatSum(vResultRow.Amount, pObject.ReportingCurrency, "NZ=0.00");
			vAvail = "";
			If ValueIsFilled(vResultRow.AccountingDate) And vCurServiceAvailability <> Undefined Then
				vCurServiceAvailabilityRow = vCurServiceAvailability.Find(vResultRow.AccountingDate, "AccountingDate");
				If vCurServiceAvailabilityRow <> Undefined And cmIsNumber(vCurServiceAvailabilityRow.AvailableQuantity) Then
					vAvail = "(" + Format(vCurServiceAvailabilityRow.AvailableQuantity, "NFD=0; NG=") + ")";
				EndIf;
			EndIf;
			If Not IsBlankString(vAvail) Then
				vAmountStr = vAmountStr + " " + vAvail;
			EndIf;
			
			FillRowPan(pPlan, String(vService), vDesc, vColumnName, vSort, Undefined, vResultRow.Quantity, Undefined, vResultRow.Service, True, vAccommodationType);
			FillRowPan(pPlan, String(vService), vDesc, vColumnNameAmount, vSort, Undefined, vAmountStr, Undefined, vResultRow.Service, True, vAccommodationType);
			FillRowPan(pPlan, String(vService), vDesc, vColumnNameUnit, vSort, Undefined, TrimAll(vService.Unit), Undefined, vResultRow.Service, True, vAccommodationType);
        EndIf; 
        
        vCurService = vService;
    EndDo;
	
	// Fill totals
    vPrceTotals = pPrices.Copy();
    vPrceTotals.GroupBy("Service, AccommodationPlanAccommodationType", "Amount");
    For Each vRowTotals In vPrceTotals Do
        vRows = pPlan.FindRows(New Structure("ResourceName, AccommodationPlanAccommodationType", String(vRowTotals.Service), vRowTotals.AccommodationPlanAccommodationType));
		If vRows.Count() = 1 Then
			vRow = vRows.Get(0);
           	vRow.Total = cmFormatSum(vRowTotals.Amount, pObject.ReportingCurrency, "NZ=0.00");      	
        EndIf; 
    EndDo; 
EndProcedure // FillPricesAndServices

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutReversalAtServer()
	If Object.AccommodationStatus = Object.Hotel.CheckOutAccommodationStatus Then
		Object.AccommodationStatus = Object.Hotel.CheckInAccommodationStatus;
	ElsIf Object.AccommodationStatus = Object.Hotel.MoveAndCheckOutAccommodationStatus Then
		Object.AccommodationStatus = Object.Hotel.CheckInAndMoveAccommodationStatus;
	Else
		Object.AccommodationStatus = Object.Hotel.CheckInAccommodationStatus;
	EndIf;
	If Not OneGuestMode Then
		For Each vOneRoomGuestsRow In GuestsInGroup Do
			vOneRoomGuestsRow.AccommodationStatus = Object.AccommodationStatus;
		EndDo;
	EndIf;
EndProcedure // CheckOutReversalAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetDataProcessorForExportGuestDataToUFMS()
	Return cmGetDataProcessorForExportGuestDataToUFMS(Object.Hotel);
EndFunction // GetDataProcessorForExportGuestDataToUFMS

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterDatesCheck(pDatesList, pCopiedData) Export
	If pDatesList <> Undefined Then
		For Each vDatesListItem In pDatesList Do
			If vDatesListItem.Check Then
				vDate = vDatesListItem.Value;
				vNewRow = Object.Services.Add();
				FillPropertyValues(vNewRow, pCopiedData, , "IsManualAuthor, IsManualDate");
				vNewRow.AccountingDate = vDate;
			EndIf;
		EndDo;
	EndIf;
	ManualServicesPriceAppearance();
EndProcedure // AfterDatesCheck

// -----------------------------------------------------------------------------
&AtServer
Procedure MoveToNewReservationAtServer(pDocsToSplit, pOneRoomDocs, pToNewGroup = False)
	vLeftDocsArray = New Array();
	For Each vOneRoomDocsItem In pOneRoomDocs Do
		If pDocsToSplit.FindByValue(vOneRoomDocsItem.Value) = Undefined Then
			vLeftDocsArray.Add(vOneRoomDocsItem.Value);
		EndIf;
	EndDo;
	vLeftAccommodationTemplate = cmGetAccommodationTemplateByDocsArray(vLeftDocsArray, ?(ValueIsFilled(Object.RoomTypeUpgrade), Object.RoomTypeUpgrade, Object.RoomType), Object.Hotel, Object.IsForFolioSplit);
	
	vSplittedDocsArray = New Array();
	For Each vDocsToSplitItem In pDocsToSplit Do
		vSplittedDocsArray.Add(vDocsToSplitItem.Value);
	EndDo;
	vSplittedAccommodationTemplate = cmGetAccommodationTemplateByDocsArray(vSplittedDocsArray, ?(ValueIsFilled(Object.RoomTypeUpgrade), Object.RoomTypeUpgrade, Object.RoomType), Object.Hotel, Object.IsForFolioSplit);
	
	Try
		BeginTransaction(DataLockControlMode.Managed);
		
		// Update documents left in the room
		vTemplateIsSet = False;
		i = 0;
		For Each vLeftDoc In vLeftDocsArray Do
			vLeftDocObj = vLeftDoc.GetObject();
			If Not vTemplateIsSet And ValueIsFilled(vLeftAccommodationTemplate) Then
				vLeftDocObj.AccommodationTemplate = vLeftAccommodationTemplate;
				vTemplateIsSet = True;
			Else
				vLeftDocObj.AccommodationTemplate = Undefined;
			EndIf;
			If ValueIsFilled(vLeftAccommodationTemplate) And vLeftAccommodationTemplate.IsForFolioSplit = vLeftDocObj.IsForFolioSplit Then
				If i < vLeftAccommodationTemplate.AccommodationTypes.Count() Then
					vLeftDocObj.AccommodationType = vLeftAccommodationTemplate.AccommodationTypes.Get(i).AccommodationType;
				EndIf;
			EndIf;
			vLeftDocObj.pmCalculateResources();
			vLeftDocObj.pmCalculateServices( , , , , , vLeftDocObj.IsForFolioSplit, , vLeftAccommodationTemplate);
			vLeftDocObj.Write(DocumentWriteMode.Posting);
			vLeftDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			
			i = i + 1;
		EndDo;
		
		// Update documents moved to another reservation/group
		vTemplateIsSet = False;
		vNewReservationGroup = Undefined;
		vNewReservationNumber = "";
		vFirstDocumentObj = Undefined;
		i = 0;
		For Each vSplittedDoc In vSplittedDocsArray Do
			vSplittedDocObj = vSplittedDoc.GetObject();
			If IsBlankString(vNewReservationNumber) Then
				vSplittedDocObj.SetNewNumber();
				vNewReservationNumber = vSplittedDocObj.Number;
			Else
				vSplittedDocObj.Number = vNewReservationNumber;
			EndIf;
			If pToNewGroup Then
				If vNewReservationGroup = Undefined Then
					vSplittedDocObj.pmCreateGuestGroup(vSplittedDocObj.GuestGroup);
					vNewReservationGroup = vSplittedDocObj.GuestGroup;
				EndIf;
			Else
				vNewReservationGroup = vSplittedDocObj.GuestGroup;
			EndIf;
			vSplittedDocObj.GuestGroup = vNewReservationGroup;
			If Not vTemplateIsSet And ValueIsFilled(vSplittedAccommodationTemplate) Then
				vSplittedDocObj.AccommodationTemplate = vSplittedAccommodationTemplate;
				vTemplateIsSet = True;
			Else
				vSplittedDocObj.AccommodationTemplate = Undefined;
			EndIf;
			If ValueIsFilled(vSplittedAccommodationTemplate) And vSplittedAccommodationTemplate.IsForFolioSplit = vSplittedDocObj.IsForFolioSplit Then
				If i < vSplittedAccommodationTemplate.AccommodationTypes.Count() Then
					vSplittedDocObj.AccommodationType = vSplittedAccommodationTemplate.AccommodationTypes.Get(i).AccommodationType;
				EndIf;
			EndIf;
			vSplittedDocObj.pmCalculateResources();
			If i = 0 Then
				vSplittedDocObj.pmLoadDefaultChargingRules();
				vFirstDocumentObj = vSplittedDocObj;
			Else
				vPostToRoomMainFolio = False;
				vDoNotCreatePersonalFolios = False;
				If ValueIsFilled(vFirstDocumentObj.AccommodationType) And vFirstDocumentObj.AccommodationType.Type = Enums.AccomodationTypes.Room And 
				   ValueIsFilled(vSplittedDocObj.AccommodationType) And vSplittedDocObj.AccommodationType.PostToRoomMainFolio Then
					vPostToRoomMainFolio = True;
					If vSplittedDocObj.AccommodationType.DoNotCreatePersonalFolios Then
						vDoNotCreatePersonalFolios = True;
					EndIf;
				EndIf;
				If vPostToRoomMainFolio Then
					If vDoNotCreatePersonalFolios Then
						cmLoadMainRoomGuestChargingRules(vSplittedDocObj, vFirstDocumentObj);
					Else
						If vFirstDocumentObj.IsForFolioSplit Then
							If vSplittedDocObj.Ref.IsForFolioSplit Then
								cmCompareAndUpdateDocumentChargingRules(vSplittedDocObj, vFirstDocumentObj, vPostToRoomMainFolio);
							Else
								cmCreateChargingRulesBasedOnParent(vSplittedDocObj, vFirstDocumentObj);
							EndIf;
						Else
							If vSplittedDocObj.Hotel.ChargingRules.Find(True, "IsPersonal") = Undefined Then
								cmLoadMainRoomGuestChargingRules(vSplittedDocObj, vFirstDocumentObj);
							Else
								cmCompareAndUpdateDocumentChargingRules(vSplittedDocObj, vFirstDocumentObj, vPostToRoomMainFolio);
							Endif;
						EndIf;
					EndIf;
				Else
					cmCompareAndUpdateDocumentChargingRules(vSplittedDocObj, vFirstDocumentObj, vPostToRoomMainFolio);
				EndIf;
			EndIf;
			// Calculate services
			vSplittedDocObj.pmCalculateServices( , , , , , vSplittedDocObj.IsForFolioSplit, , vSplittedAccommodationTemplate);
			// Save changes
			vSplittedDocObj.AdditionalProperties.Insert("DoNotCheckRests", True);
			vSplittedDocObj.Write(DocumentWriteMode.Posting);
			vSplittedDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			
			i = i + 1;
		EndDo;
		
		CommitTransaction();
	Except
		vErrorInfo = ErrorInfo();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Raise cmGetRootErrorDescription(vErrorInfo);
	EndTry;
EndProcedure // MoveToNewReservationAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterGuestsToMoveToNewReservationSelection(pGuestsList, pExtraParams) Export
	If pGuestsList <> Undefined Then
		vDocsList = New ValueList();
		For Each vGuestsListItem In pGuestsList Do
			If vGuestsListItem.Check Then
				vDocsList.Add(vGuestsListItem.Value);
			EndIf;
		EndDo;
		If vDocsList.Count() > 0 Then
			// Save this document first
			If ThisObject.Modified Then
				Post(Commands["Post"]);
			EndIf;
			// Do processing
			vOneRoomDocsList = pExtraParams.OneRoomGuests;
			vMoveToNewGroup = pExtraParams.MoveToNewGroup;
			MoveToNewReservationAtServer(vDocsList, vOneRoomDocsList, vMoveToNewGroup);
			// Notify end
			For Each vDocsListItem In vDocsList Do
				Notify("Document.Accommodation.Write", vDocsListItem.Value, ThisObject);
			EndDo;
			Notify("Document.Accommodation.Splitted", Object.Ref, FormOwner);
			// Close this document form
			ThisObject.Close();
			// Finish
			ShowMessageBox(, NStr("en='Successfully!'; ru='Успешно!'; de='Erfolgreich!'"), 2);
		Else
			ShowMessageBox(, NStr("en='No guests selected!'; ru='Не выбраны гости!'; de='Keine Gäste ausgewählt!'"));
		EndIf;
	EndIf;
EndProcedure // AfterGuestsToMoveToNewReservationSelection

// -----------------------------------------------------------------------------
&AtServer
Procedure CopyTransferRulesToOtherRoomGuestsAtServer(pDocsList, pTranferRules)
	For Each vDocsListItem In pDocsList Do
		vDocObj = vDocsListItem.Value.GetObject();
		t = 0;
		For Each vTranferRulesRow In pTranferRules Do
			If vDocObj.ChargingRules.Find(vTranferRulesRow.ChargingFolio, "ChargingFolio") = Undefined Then
				vTrCRRow = vDocObj.ChargingRules.Insert(t);
				FillPropertyValues(vTrCRRow, vTranferRulesRow);
				t = t + 1;
			EndIf;
		EndDo;
		vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
		vDocObj.Write(DocumentWriteMode.Posting);
		vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndDo;
EndProcedure // CopyTransferRulesToOtherRoomGuestsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterGuestsToCopyTransferRulesSelection(pGuestsList, pTranferRules) Export
	If pGuestsList <> Undefined Then
		vDocsList = New ValueList();
		For Each vGuestsListItem In pGuestsList Do
			If vGuestsListItem.Check Then
				vDocsList.Add(vGuestsListItem.Value);
			Endif;
		EndDo;
		If vDocsList.Count() > 0 Then
			// Save this document first
			If ThisObject.Modified Then
				Post(Commands["Post"]);
			EndIf;
			// Do processing
			CopyTransferRulesToOtherRoomGuestsAtServer(vDocsList, pTranferRules);
			// Notify end
			For Each vDocsListItem In vDocsList Do
				Notify("Document.Accommodation.Write", vDocsListItem.Value, ThisObject);
			EndDo;
			Notify("Document.Accommodation.Write", Object.Ref, ThisObject);
			// Finish
			ShowMessageBox(, NStr("en='Successfully!'; ru='Успешно!'; de='Erfolgreich!'"), 2);
		Else
			ShowMessageBox(, NStr("en='No guests selected!'; ru='Не выбраны гости!'; de='Keine Gäste ausgewählt!'"));
		EndIf;
	EndIf;
EndProcedure // AfterGuestsToCopyTransferRulesSelection

// -----------------------------------------------------------------------------
&AtServer
Procedure CopyPackagesToOtherRoomGuestsAtServer(pDocsList, pPackagesList, pReplace = False)
	vServicePackage = Undefined;
	For Each vPackagesListItem In pPackagesList Do
		If vPackagesListItem.Check Then
			If vPackagesListItem.Value.Quantity = 0 Then
				vServicePackage = vPackagesListItem.Value.ServicePackage;
				Break;
			EndIf;
		EndIf;
	EndDo;
	For Each vDocsListItem In pDocsList Do
		vDocObj = vDocsListItem.Value.GetObject();
		If pReplace Or ValueIsFilled(vServicePackage) Then
			vDocObj.ServicePackage = vServicePackage;
		EndIf;
		If pReplace Then
			vDocObj.ServicePackages.Clear();
		EndIf;
		For Each vPackagesListItem In pPackagesList Do
			If vPackagesListItem.Check Then
				If vPackagesListItem.Value.Quantity <> 0 Then
					vDocObjServicePackagesRow = vDocObj.ServicePackages.Find(vPackagesListItem.Value.ServicePackage, "ServicePackage");
					If vDocObjServicePackagesRow = Undefined Then
						vDocObjServicePackagesRow = vDocObj.ServicePackages.Add();
					EndIf;
					FillPropertyValues(vDocObjServicePackagesRow, vPackagesListItem.Value);
				EndIf;
			EndIf;
		EndDo;
		vDocObj.pmCalculateServices( , , , , , vDocObj.IsForFolioSplit);
		vDocObj.Write(DocumentWriteMode.Posting);
		vDocObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
	EndDo;
EndProcedure // CopyTransferRulesToOtherRoomGuestsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterReplaceServicePackagesSelection(pUC, pExtraParam) Export
	If pUC = Undefined Or pUC = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	ReplaceServicePackages = False;
	If pUC = DialogReturnCode.Yes Then
		ReplaceServicePackages = True;
	EndIf;
	// Get packages to be copied list
	vPackagesList = New ValueList();
	If ValueIsFilled(Object.ServicePackage) Then
		vPackagesList.Add(New Structure("ServicePackage, Quantity, DateFrom, DateTo", Object.ServicePackage, 0, '00010101', '00010101'), TrimAll(Object.ServicePackage), True);
	EndIf;
	For Each vObjectServicePackagesRow In Object.ServicePackages Do
		vPackagesList.Add(New Structure("ServicePackage, Quantity, DateFrom, DateTo", vObjectServicePackagesRow.ServicePackage, vObjectServicePackagesRow.Quantity, vObjectServicePackagesRow.DateFrom, vObjectServicePackagesRow.DateTo), 
		                  TrimAll(vObjectServicePackagesRow.ServicePackage) + 
		                  NStr("en=', q-ty: '; ru=', кол-во: '; de=', menge: '") + 
		                  Format(vObjectServicePackagesRow.Quantity, "NFD=0; NZ=; NG=") + 
						  ?(ValueisFilled(vObjectServicePackagesRow.DateFrom), NStr("en=' from '; ru=' с '; de=' von '") + Format(vObjectServicePackagesRow.DateFrom, "DF=dd.MM.yyyy"), "") + 
						  ?(ValueisFilled(vObjectServicePackagesRow.DateTo), NStr("en=' to '; ru=' по '; de=' bis '") + Format(vObjectServicePackagesRow.DateTo, "DF=dd.MM.yyyy"), ""), 
						  True);
	EndDo;
	// Ask user to check service packages that have to be copied
	If vPackagesList.Count() > 0 Then
		// Get one room guests
		vOneRoomGuests = GetOneRoomGuests(Object.Ref);
		// Remove current document
		i = 0;
		While i < vOneRoomGuests.Count() Do
			vOneRoomGuestsItem = vOneRoomGuests.Get(i);
			If vOneRoomGuestsItem.Value = Object.Ref Then
				vOneRoomGuests.Delete(i);
				Break;
			Else
				i = i + 1;
			EndIf;
		EndDo;
		// Check if there are some guests
		If vOneRoomGuests.Count() > 0 Then
			// Build value list with documents
			vGuestsList = New ValueList();
			For Each vOneRoomGuestsItem In vOneRoomGuests Do
				vDocRef = vOneRoomGuestsItem.Value;
				vGuestsList.Add(vOneRoomGuestsItem.Value, tcOnServer.cmGetAttributeByRef(vDocRef, "GuestFullName") + " (" + TrimAll(tcOnServer.cmGetAttributeByRef(vDocRef, "AccommodationType")) + ")", False);
			EndDo;
			vPackagesList.ShowCheckItems(New NotifyDescription("AfterServicePackagesToCopyPackagesSelection", ThisObject, vGuestsList), NStr("en='Checkmark packages you need to copy...'; ru='Отметьте пакеты, которые нужно скопировать...'; de='Markieren Sie die zu kopierenden Pakete...'"));
		Else
			ShowMessageBox(, NStr("en='There are no sharers in the room!'; ru='В номере нет других гостей этой брони!'; de='Es gibt keine Mitspieler im Zimmer!'"));
		EndIf;
	Else
		ShowMessageBox(, NStr("en='There are no service packages in the reservation!'; ru='В брони нет пакетов услуг!'; de='Es gibt keine Dienstleistungspaket im Reservierung!'"));
	EndIf;
EndProcedure // AfterReplaceServicePackagesSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterServicePackagesToCopyPackagesSelection(pPackagesList, pGuestsList) Export
	If pPackagesList <> Undefined Then
		vThereAreSomethingToCopy = False;
		For Each vPackagesListItem In pPackagesList Do
			If vPackagesListItem.Check Then
				vThereAreSomethingToCopy = True;
				Break;
			EndIf;
		EndDo;
		If vThereAreSomethingToCopy Then
			pGuestsList.ShowCheckItems(New NotifyDescription("AfterGuestsToCopyPackagesSelection", ThisObject, pPackagesList), NStr("en='Checkmark guests...'; ru='Отметьте гостей...'; de='Gäste markieren...'"));
		Else
			ShowMessageBox(, NStr("en='There are no service packages checked!'; ru='Нет отмеченных пакетов услуг!'; de='Es gibt keine Dienstleistungspaketen markiert!'"));
		EndIf;
	EndIf;
EndProcedure // AfterServicePackagesToCopyPackagesSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterGuestsToCopyPackagesSelection(pGuestsList, pPackagesList) Export
	If pGuestsList <> Undefined Then
		vDocsList = New ValueList();
		For Each vGuestsListItem In pGuestsList Do
			If vGuestsListItem.Check Then
				vDocsList.Add(vGuestsListItem.Value);
			Endif;
		EndDo;
		If vDocsList.Count() > 0 Then
			// Do processing
			CopyPackagesToOtherRoomGuestsAtServer(vDocsList, pPackagesList, ReplaceServicePackages);
			// Notify end
			For Each vDocsListItem In vDocsList Do
				Notify("Document.Reservation.Write", vDocsListItem.Value, ThisObject);
			EndDo;
			Notify("Document.Reservation.Write", Object.Ref, ThisObject);
			// Finish
			ShowMessageBox(, NStr("en='Successfully!'; ru='Успешно!'; de='Erfolgreich!'"), 2);
		Else
			ShowMessageBox(, NStr("en='No guests selected!'; ru='Не выбраны гости!'; de='Keine Gäste ausgewählt!'"));
		EndIf;
	EndIf;
EndProcedure // AfterGuestsToCopyPackagesSelection

// -----------------------------------------------------------------------------
&AtServer
Procedure SharePercentOnChangeAtServer()
	// Update all other share percents
	If IsBlankString(Object.SharePercent) Then
		// Clear share percent from everywhere
		For i = 0 To (GuestsInGroup.Count() - 1) Do
			vGiGRow = GuestsInGroup.Get(i);
			vGiGRow.SharePercent = "";
			ThisForm["SharePercent" + (i + 2)] = vGiGRow.SharePercent;
		EndDo;
	ElsIf cmIsNumber(Object.SharePercent) Then
		// Check that fraction is positive
		If Number(Object.SharePercent) < 0 Then
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Fraction entered should be positive!'; 
			             |ru='Введенная доля не должна быть отрицательной!'; 
						 |de='Der eingegebene Bruch sollte positiv sein!'"));
			Object.SharePercent = "";
			Return;
		EndIf;
		If Number(Object.SharePercent) > 100 Then
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='Fraction entered should be less or equal 100%!'; 
			             |ru='Введенная доля не должна быть больше 100%!'; 
						 |de='Der eingegebene Bruch darf nicht mehr als 100% sein!'"));
			Object.SharePercent = "";
			Return;
		EndIf;
		Try
			// Check should we offer splitting by equal fractions
			vCopyToAll = False;
			If Number(Object.SharePercent) <> 0 Then
				vTotalShare = Number(Object.SharePercent) * (1 + GuestsInGroup.Count());
				If vTotalShare = 100 Then
					vCopyToAll = True;
				EndIf;
			EndIf;
			// Update attributes
			For i = 0 To (GuestsInGroup.Count() - 1) Do
				vGiGRow = GuestsInGroup.Get(i);
				If vCopyToAll Then
					vGiGRow.SharePercent = String(Number(Object.SharePercent));
				ElsIf i = 0 Then
					vGiGRow.SharePercent = String(100 - Number(Object.SharePercent));
				Else
					vGiGRow.SharePercent = "0";
				EndIf;
				ThisObject["SharePercent" + (i + 2)] = vGiGRow.SharePercent;
			EndDo;
		Except
		EndTry;
	Else
		vFraction = TrimAll(Object.SharePercent);
		// Check fraction format
		If Not IsBlankString(vFraction) Then
			vNom = 0; vDenom = 0;
			If Not cmParseFractionFormat(vFraction, vNom, vDenom) Then
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='Fraction entered is of wrong format! Should be a % number or fraction like x/y where y > x.'; 
				             |ru='Введенная доля имеет неправильный формат! Должно быть число % или дробь вида x/y, где y > x.'; 
							 |de='Die eingegebene Bruch hat nicht das richtige Format! Muss eine % Zahl oder ein Bruch der Form x/y sein, wobei y > x.'"));
				Object.SharePercent = "";
			Else
				// Check should we offer splitting by equal fractions
				vCopyToAll = False;
				vTotalNom = vNom * (1 + GuestsInGroup.Count());
				If vTotalNom = vDenom And vDenom > 0 Then
					vCopyToAll = True;
				EndIf;
				// Update attributes
				If vCopyToAll Then
					For i = 0 To (GuestsInGroup.Count() - 1) Do
						vGiGRow = GuestsInGroup.Get(i);
						vGiGRow.SharePercent = vFraction;
						ThisObject["SharePercent" + (i + 2)] = vGiGRow.SharePercent;
					EndDo;
				Else
					// Set "0" to all other guests
					For i = 0 To (GuestsInGroup.Count() - 1) Do
						vGiGRow = GuestsInGroup.Get(i);
						If IsBlankString(vGiGRow.SharePercent) Then
							vGiGRow.SharePercent = "0";
							ThisObject["SharePercent" + (i + 2)] = vGiGRow.SharePercent;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		Else
			// Set "" to all other guests
			For i = 0 To (GuestsInGroup.Count() - 1) Do
				vGiGRow = GuestsInGroup.Get(i);
				If Not IsBlankString(vGiGRow.SharePercent) Then
					vGiGRow.SharePercent = "";
					ThisObject["SharePercent" + (i + 2)] = vGiGRow.SharePercent;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
EndProcedure // SharePercentOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ExtraGuestSharePercentOnChangeAtServer(pInd = "")
	vInd = Number(pInd) - 2;
	If vInd >= 0 Then
		If IsBlankString(ThisForm["SharePercent" + pInd]) Then
			ThisForm["SharePercent" + pInd] = "";
		ElsIf cmIsNumber(ThisObject["SharePercent" + pInd]) Then
			If Number(ThisObject["SharePercent" + pInd]) < 0 Then
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='Fraction entered should be positive!'; 
				             |ru='Введенная доля не должна быть отрицательной!'; 
							 |de='Der eingegebene Bruch sollte positiv sein!'"));
				ThisObject["SharePercent" + pInd] = "";
				Return;
			EndIf;
			If Number(ThisObject["SharePercent" + pInd]) > 100 Then
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='Fraction entered should be less or equal 100%!'; 
				             |ru='Введенная доля не должна быть больше 100%!'; 
							 |de='Der eingegebene Bruch darf nicht mehr als 100% sein!'"));
				ThisObject["SharePercent" + pInd] = "";
				Return;
			EndIf;
			Try
				// Update all other share percents
				vPercent = Number(Object.SharePercent);
				vRest = 0;
				For i = 0 To (GuestsInGroup.Count() - 1) Do
					If i < vInd Then
						vPercent = vPercent + Number(GuestsInGroup.Get(i).SharePercent);
					ElsIf i = vInd Then
						vGiGRow = GuestsInGroup.Get(i);
						vGiGRow.SharePercent = ThisObject["SharePercent" + pInd];
						vPercent = vPercent + Number(vGiGRow.SharePercent);
					ElsIf i = (vInd + 1) Then
						vRest = 100 - vPercent;
						vGiGRow = GuestsInGroup.Get(i);
						vGiGRow.SharePercent = String(vRest);
						ThisObject["SharePercent" + (i + 2)] = vGiGRow.SharePercent;
					Else
						vGiGRow = GuestsInGroup.Get(i);
						vGiGRow.SharePercent = "0";
						ThisObject["SharePercent" + (i + 2)] = vGiGRow.SharePercent;
					EndIf;
				EndDo;
				// Check total share percent
				vPercent = Number(Object.SharePercent);
				For i = 0 To (GuestsInGroup.Count() - 1) Do
					vPercent = vPercent + Number(GuestsInGroup.Get(i).SharePercent);
				EndDo;
				If vPercent <> 100 Then
					vDiff = 100 - vPercent;
					If vInd > 0 Then
						vGiGRow = GuestsInGroup.Get(vInd - 1);
						vGiGRow.SharePercent = String(Number(vGiGRow.SharePercent) + vDiff);
						ThisObject["SharePercent" + (vInd + 1)] = vGiGRow.SharePercent;
					Else
						Object.SharePercent = String(Number(Object.SharePercent) + vDiff);
					EndIf;
				EndIf;
			Except
				vGiGRow = GuestsInGroup.Get(vInd);
				vGiGRow.SharePercent = ThisObject["SharePercent" + pInd];
			EndTry;
		Else
			vFraction = ThisObject["SharePercent" + pInd];
			// Check fraction format
			If Not IsBlankString(vFraction) Then
				If Not cmParseFractionFormat(vFraction) Then
					tcCommonFunctionOnClientServer.UserMessage(NStr("en='Fraction entered is of wrong format! Should be a % number or fraction like x/y where y > x.'; 
					             |ru='Введенная доля имеет неправильный формат! Должно быть число % или дробь вида x/y, где y > x.'; 
								 |de='Die eingegebene Bruch hat nicht das richtige Format! Muss eine % Zahl oder ein Bruch der Form x/y sein, wobei y > x.'"));
					ThisObject["SharePercent" + pInd] = "";
				Else
					vGiGRow = GuestsInGroup.Get(vInd);
					vGiGRow.SharePercent = ThisObject["SharePercent" + pInd];
					// Set "0" to all other guests
					For i = 0 To (GuestsInGroup.Count() - 1) Do
						If i > vInd Then
							vGiGRow = GuestsInGroup.Get(i);
							If IsBlankString(vGiGRow.SharePercent) Then
								vGiGRow.SharePercent = "0";
								ThisObject["SharePercent" + (i + 2)] = vGiGRow.SharePercent;
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			Else
				vGiGRow = GuestsInGroup.Get(vInd);
				vGiGRow.SharePercent = ThisObject["SharePercent" + pInd];
			EndIf;
		EndIf;
		// Calculate totals
		TotalSum = CalculateTotalServices(, , False, False);
	EndIf;
EndProcedure // ExtraGuestSharePercentOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceCalculationDateFinishChoice(pSelectValue, pExtraParam) Export 
	If Not pSelectValue = Undefined Then
		If pSelectValue.Value = "CurrentValue" Then
			// Calculate date
			Object.PriceCalculationDate = Undefined;
			PriceCalculationDateOnChangeAtServer();
		ElsIf pSelectValue.Value = "ByParentDoc" Then
			// Fill by parent
			FillPriceCalculationDateByParentDoc();
		EndIf;	
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPriceCalculationDateByParentDoc()
	If ValueIsFilled(Object.ParentDoc) Then
		Object.PriceCalculationDate = Object.ParentDoc.PriceCalculationDate; 
		For Each vParentDocRow In Object.ParentDoc.Services Do
			vFilterList = Object.Services.FindRows(New Structure("AccountingDate, Service, IsManual", vParentDocRow.AccountingDate, vParentDocRow.Service, vParentDocRow.IsManual));
			For Each vFilterRow In vFilterList Do
				vFilterRow.CalendarDayType = vParentDocRow.CalendarDayType;
			EndDo;
		EndDo;
		RecalculateServicesAtServer();
	EndIf;
EndProcedure // FillPriceCalculationDateByParentDoc	

// -----------------------------------------------------------------------------
&AtServer
Procedure UploadTable(pTempStorage)
	vTable = GetFromTempStorage(pTempStorage);	
	For Each vRow In vTable Do
		vNewRow = Object.Services.Add();
		FillPropertyValues(vNewRow, vRow);
	EndDo;
EndProcedure // UploadTable

// -----------------------------------------------------------------------------
&AtServer
Function GetRows(val vSelectedRows)
	vRowsArray = New Array;
	For Each vSelectedRowID In vSelectedRows Do
		vRowsArray.Add(Object.Services.FindByID(vSelectedRowID));	
	EndDo;
	Return PutToTempStorage(Object.Services.Unload(vRowsArray), ThisObject.UUID); 	
EndFunction // GetRows

// -----------------------------------------------------------------------------
&AtClient
Procedure PastedColumnOnChange(pColumnName, pRowID)
	If pColumnName = "Price" Then 
		ServicesPriceOnChangeAtServer(pRowID, True);
	ElsIf pColumnName = "Quantity" Then
		ServicesQuantityOnChangeAtServer(pRowID, True);
	ElsIf pColumnName = "Sum" Then
		ServicesSumOnChangeAtServer(pRowID, True);	
	ElsIf pColumnName = "Discount" Then
		ServicesDiscountOnChangeAtServer(pRowID, True);	
	ElsIf pColumnName = "DiscountSum" Then
		ServicesDiscountSumOnChangeAtServer(pRowID, True);	
	ElsIf pColumnName = "AgentCommission" Then
		ServicesAgentCommissionOnChangeAtServer(pRowID, True);	
	ElsIf pColumnName = "CommissionSum" Then
		ServicesCommissionSumOnChangeAtServer(pRowID, True);
	ElsIf pColumnName = "TimeFrom" Then
		ServicesTimeFromOnChangeAtServer(pRowID);
	EndIf;	
EndProcedure // ServicesPastedColumnOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestHotelProductChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If pItem.EditText <> "" Then
		VaucherText = pItem.EditText;
	EndIf;
	vInd = GetItemIndex(pItem.Name);
	If Not IsBlankString(vInd) Then
		vVaucherType = Undefined;
		vGiGIndex = Number(vInd) - 2;
		If TypeOf(pSelectedValue) = Type("String") Then
			vVaucher = ThisObject[pItem.Name];
			If ValueIsFilled(vVaucher) And tcOnServer.cmGetAttributeByRef(vVaucher, "IsFolder") Then
				vVaucherType = vVaucher;
			EndIf;
		EndIf;
		If TypeOf(pSelectedValue) = Type("String") And GetAllHotelProductFolders() And Not ValueIsFilled(vVaucherType) Then 
			ThisObject[pItem.Name] = Undefined;
			GuestsInGroup.Get(vGiGIndex).HotelProduct = ThisObject[pItem.Name];
			vFrm = OpenForm("Catalog.HotelProducts.Form.tcGroupChoiceForm", New Structure("ChoiceMode", True), pItem);
		Else
			vObject = Object;
			
			vMessage = CreateGuestItems(vObject);
			If Not IsBlankString(vMessage) Then
				ShowMessageBox(, vMessage);
				Return;
			EndIf;
			
			vGuestsInGroup = GuestsInGroup[vGiGIndex];
			vClient = vGuestsInGroup.GuestRef;
			vDocRef = GetGuestDocumentRefByItemID(pItem.Name);
			vDocGuest = GetDocGuest(vDocRef);
			
			If Not IsBlankString(VaucherText) Then
				If SelectedValueIsFolder(pSelectedValue) Then
					If Not vGuestsInGroup.Ref.isEmpty() And ValueIsFilled(vDocGuest) And vClient = vDocGuest Then
						ThisObject[pItem.Name] = CreateNewVaucher(vDocRef, pSelectedValue, VaucherText);
					Else
						vStruct = New Structure("Hotel, Client, Description, Code", vObject.Hotel, vClient, VaucherText, VaucherText);
						ThisObject[pItem.Name] = CreateNewVaucher(vStruct, pSelectedValue, VaucherText);
					EndIf;
				ElsIf TypeOf(pSelectedValue) = Type("String") Then
					If Not vGuestsInGroup.Ref.isEmpty() And ValueIsFilled(vDocGuest) And vClient = vDocGuest Then
						ThisObject[pItem.Name] = CreateNewVaucher(vDocRef, vVaucherType, VaucherText);
					Else
						vStruct = New Structure("Hotel, Client, Description, Code", vObject.Hotel, vClient, VaucherText, VaucherText);
						ThisObject[pItem.Name] = CreateNewVaucher(vStruct, vVaucherType, VaucherText);
					EndIf;
				ElsIf Not TypeOf(pSelectedValue) = Type("String") Then
					ThisObject[pItem.Name] = pSelectedValue;
				EndIf;
			ElsIf Not TypeOf(pSelectedValue) = Type("String") Then 
				ThisObject[pItem.Name] = pSelectedValue;
			EndIf;

			GuestsInGroup.Get(vGiGIndex).HotelProduct = ThisObject[pItem.Name];

			// Reset vaucher text
			VaucherText = "";
		EndIf;
	EndIf;
EndProcedure // ExtraGuestHotelProductChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If pItem.EditText <> "" Then
		VaucherText = pItem.EditText;
	EndIf;
	vVaucherType = Undefined;
	If TypeOf(pSelectedValue)= Type("String") Then
		vVaucher = Object.HotelProduct;
		If ValueIsFilled(vVaucher) And tcOnServer.cmGetAttributeByRef(vVaucher, "IsFolder") Then
			vVaucherType = vVaucher;
		EndIf;
	EndIf;
	If TypeOf(pSelectedValue) = Type("String") And GetAllHotelProductFolders() And Not ValueIsFilled(vVaucherType) Then
		Object.HotelProduct = Undefined;
		vFrm = OpenForm("Catalog.HotelProducts.Form.tcGroupChoiceForm", New Structure("ChoiceMode", True), pItem);
	Else 
		vObject = Object;
		
		vMessage = CreateGuestItems(vObject);
		If Not IsBlankString(vMessage) Then
			ShowMessageBox(, vMessage);
			Return;
		EndIf;
		
		If Not IsBlankString(VaucherText) Then
			If SelectedValueIsFolder(pSelectedValue) Then
				Object.HotelProduct = CreateNewVaucher(vObject, pSelectedValue, VaucherText);
			ElsIf TypeOf(pSelectedValue) = Type("String") Then
				Object.HotelProduct = CreateNewVaucher(vObject, vVaucherType, VaucherText);
			ElsIf Not TypeOf(pSelectedValue) = Type("String") Then 
				Object.HotelProduct = pSelectedValue;
			EndIf;
		ElsIf Not TypeOf(pSelectedValue) = Type("String") Then
			Object.HotelProduct = pSelectedValue;
		EndIf;

		// Reset vaucher text
		VaucherText = "";
	EndIf;
EndProcedure // HotelProductChoiceProcessing  

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	If pWait = 0 Then
		pStandardProcessing = True;
		pChoiceData = Undefined;
	ElsIf IsBlankString(pText) Then
		pStandardProcessing = True;
		pChoiceData = Undefined;
		If pItem = Items.HotelProduct Then
			Object.HotelProduct = Undefined;
			// Reset vaucher text
			VaucherText = "";  
			HotelProductOnChangeAtServer();
		Else
			ThisObject[pItem.Name] = Undefined;
			vInd = GetItemIndex(pItem.Name);
			If Not IsBlankString(vInd) Then
				Try
					GuestsInGroup.Get(Number(vInd) - 2).HotelProduct = Undefined;     
					ExtraGuestHotelProductOnChangeAtServer(vInd);
				Except
				EndTry;
			EndIf;
		EndIf;
		Modified = True;
	Else
		pStandardProcessing = False;
		If StrLen(pText) > 0 Then
			pChoiceData = GetHotelProducts(pText, Object.Hotel);
			If pChoiceData.Count() = 0 Then
				pChoiceData.Add(pText, NStr("en='--Vaucher not found--';ru='--Путевка не найдена--';de='--Reisescheck nicht gefunden--'"));
			EndIf;
		EndIf;
		Modified = True; 
	EndIf;
EndProcedure // HotelProductAutoComplete

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetDocGuest(pDocRef)
	Return pDocRef.Guest;
EndFunction // GetServicesSum

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetServicesSum(pObject)
	vSrvSum = 0;
	For Each vSrvRow In pObject.Services Do
		If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.IsHotelProductService Then
			vSrvSum = vSrvSum + vSrvRow.Sum - vSrvRow.DiscountSum;
		EndIf;
	EndDo;
	Return vSrvSum;
EndFunction // GetServicesSum

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CreateNewVaucher(pObject, pSelectedValue, pText)
	If TypeOf(pObject) = Type("Structure") Then 
		vFillingValues = pObject; 
		vFillingValues.Insert("Parent", ?(TypeOf(pSelectedValue) = Type("CatalogRef.HotelProducts"), pSelectedValue, Catalogs.HotelProducts.EmptyRef()));
	Else
		vFillingValues = New Structure("Parent, Code, Description, Hotel, RoomQuota, RoomType, Client, CheckInDate, Duration, CheckOutDate, PaymentMethod, Sum, Currency", 
		?(TypeOf(pSelectedValue) = Type("CatalogRef.HotelProducts"), pSelectedValue, Catalogs.HotelProducts.EmptyRef()), TrimAll(pText), TrimAll(pText), pObject.Hotel, pObject.RoomQuota, pObject.RoomType, pObject.Guest, pObject.CheckInDate, pObject.Duration, pObject.CheckOutDate, pObject.PlannedPaymentMethod, GetServicesSum(pObject), GetCurrency(pObject.Hotel));
	EndIf;
	
	vCatalogItem = Catalogs.HotelProducts.CreateItem();
	FillPropertyValues(vCatalogItem, vFillingValues);
	vCatalogItem.Description = Catalogs.HotelProducts.SetVaucherNumberPresentation(vCatalogItem.Description, vCatalogItem.Parent);
	vCatalogItem.Code = vCatalogItem.Description;
	vCatalogItem.Write();
	Return vCatalogItem.Ref;
EndFunction // CreateNewVaucher

// -----------------------------------------------------------------------------
&AtServerNoContext
Function SelectedValueIsFolder(pSelVal)
	If TypeOf(pSelVal) = Type("CatalogRef.HotelProducts") And ValueIsFilled(pSelVal) And pSelVal.IsFolder Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // SelectedValueIsFolder

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAllHotelProductFolders()
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	HotelProducts.Ref AS HotelProduct
	|FROM
	|	Catalog.HotelProducts AS HotelProducts
	|WHERE
	|	HotelProducts.IsFolder = TRUE
	|	AND HotelProducts.DeletionMark = FALSE
	|
	|ORDER BY
	|	HotelProducts.Code";
	vList = vQry.Execute().Unload();
	If vList.Count() > 0 Then
		Return True;
	Else
		return False;
	EndIf;
Endfunction // GetAllHotelProductFolders 

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetHotelProducts(pText, pHotel)
	vChoiceDataList = New ValueList;
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	HotelProducts.Ref AS Ref
	|FROM
	|	Catalog.HotelProducts AS HotelProducts
	|WHERE
	|	HotelProducts.Description LIKE &qText
	|	AND (HotelProducts.Hotel = &qHotel
	|			OR HotelProducts.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND NOT HotelProducts.IsFolder
	|	AND NOT HotelProducts.DeletionMark";
	vQry.SetParameter("qText", pText+"%");
	vQry.SetParameter("qHotel", pHotel);
	vQryResult = vQry.Execute().Select();
	While vQryResult.Next() Do
		vChoiceDataList.Add(vQryResult.Ref);
	EndDo;
	Return vChoiceDataList;
EndFunction // GetHotelProducts

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCurrency(pHotel)
	Return pHotel.FolioCurrency;
EndFunction // GetCurrency

// ----------------------------------------------------------------------------
&AtClient
Procedure FillAmenitiesFromRackRate(pRoomRate, IsClearing = False)
	vRemarksAmenitiesList = GetAmenitiesList(Object.Remarks, 1);
	vHousekeepingRemarksAmenitiesList = GetAmenitiesList(Object.HousekeepingRemarks, 2);
	
	vRemarksAmenity = tcOnServer.cmGetAttributeByRef(pRoomRate, "ReservationRemarksAmenity");
	vHousekeepingRemarksAmenity = tcOnServer.cmGetAttributeByRef(pRoomRate, "ReservationHousekeepingRemarksAmenity");
	If ValueIsFilled(vRemarksAmenity) Then
		For Each vRemarksAmenitiesListItem In vRemarksAmenitiesList Do
			If vRemarksAmenitiesListItem.Value = vRemarksAmenity Then
				If IsClearing Then
					vRemarksAmenitiesListItem.Check = False; 
				Else
					vRemarksAmenitiesListItem.Check = True; 
				EndIf;
			EndIf;
		EndDo;	
	EndIf;
	If ValueIsFilled(vHousekeepingRemarksAmenity) Then
		For Each vHousekeepingRemarksAmenitiesListItem In vHousekeepingRemarksAmenitiesList Do
			If vHousekeepingRemarksAmenitiesListItem.Value = vHousekeepingRemarksAmenity Then
				If IsClearing Then
					vHousekeepingRemarksAmenitiesListItem.Check = False;
				Else
					vHousekeepingRemarksAmenitiesListItem.Check = True; 
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	AmenitiesAfterChoice(vRemarksAmenitiesList, "Remarks");
	AmenitiesAfterChoice(vHousekeepingRemarksAmenitiesList, "HousekeepingRemarks");
EndProcedure // FillAmenitiesFromRackRate

// ----------------------------------------------------------------------------
&AtClient
Procedure RefreshDocumentRepresentation()
	// Items to refresh
	vItemsArray = New Array();
	vItemsArray.Add(Items.ChargingRules);
	vItemsArray.Add(Items.Services);
	vItemsArray.Add(Items.FixedCharges);
	RefreshDataRepresentation(vItemsArray);
EndProcedure // RefreshDocumentRepresentation

// -----------------------------------------------------------------------------
&AtClient
Function GetRemarksForAPDEX()
	
	vAPDEXParams = New Structure;         
	vAPDEXParams.Insert("Number", Object.Number);  
	vAPDEXParams.Insert("Status", String(Object.AccommodationStatus));
	vAPDEXParams.Insert("CheckInDate", String(Object.CheckInDate));
	vAPDEXParams.Insert("CheckOutDate", String(Object.CheckOutDate));
	vAPDEXParams.Insert("RoomType", String(Object.RoomType));
	vAPDEXParams.Insert("RoomRate", String(Object.RoomRate)); 
	vAPDEXParams.Insert("GuestGroup", String(Object.GuestGroup));
	vAPDEXParams.Insert("Guest", String(Object.Guest));  
	vAPDEXParams.Insert("RoomQuota", String(Object.RoomQuota));
	
	Return vAPDEXParams;
EndFunction // GetRemarksForAPDEX

// -----------------------------------------------------------------------------
&AtClient
Procedure TouristicTaxExemptionReasonOnChange(pItem)
	If ValueIsFilled(Object.TouristicTaxExemptionReason) Then
		If Not ValueIsFilled(Object.TouristicTaxExemptionReasonFillDate) Then
			Object.TouristicTaxExemptionReasonFillDate = tcOnServer.GetCurrentSessionDate();
		EndIf;
		// Ask user should we exempt other room guests from paying the resort fee
		If Not OneGuestMode Then
			ShowQueryBox(New NotifyDescription("ResortFeeExemptAfterQuery", ThisObject), NStr("en='Add exempt from tourist tax to room other guests?'; ru='Освободить других гостей номера от уплаты туристического налога?'; de='Lassen Zimmer andere Gäste die Kurtax nicht bezahlen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
	Else
		If ValueIsFilled(Object.TouristicTaxExemptionReasonFillDate) Then
			Object.TouristicTaxExemptionReasonFillDate = '00010101';
			Object.TouristicTaxExemptionConfirmationData = "";
		EndIf;
		ClearResortFeeExemptionAtServer(True);
		// Ask user should we clear exempt from paying the resort fee from other room guests 
		If Not OneGuestMode Then
			ShowQueryBox(New NotifyDescription("ResortFeeExemptAfterQuery", ThisObject), NStr("en='Clear exempt from paying the tourist tax / resort fee from room other guests?'; ru='Отменить освобождение от уплаты туристического налога / курортного сбора у других гостей номера?'; de='Stornieren die Befreiung von der Zahlung einer Kurtax von Zimmer anderen Gäste?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
		EndIf;
	EndIf;
	BuildRoomRateGroupCollapsedTitle();
	// Form is modified
	ThisObject.Modified = True;
EndProcedure // TouristicTaxExemptionReasonOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TouristicTaxAccountingDateOnChange(pItem)
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
	ThisObject.Modified = True;
EndProcedure // TouristicTaxAccountingDateOnChange

// -----------------------------------------------------------------------------
&AtClient 
Procedure CarOpeningOnFinish(pCar, pExtraParams) Export
	If ValueIsFilled(pCar) And Not ThisObject.ReadOnly Then
		Object.Car = TrimAll(pCar);
		ThisObject.Modified = True;
	EndIf;
EndProcedure // CarOpeningOnFinish

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCarByDescriptionAtServer(pCarDesc) 
	vCardDesc = TrimAll(pCarDesc);
	vSplitterPos = StrFind(vCardDesc, " - ");
	If vSplitterPos > 0 Then
		vCardDesc = TrimAll(Left(vCardDesc, vSplitterPos - 1));
	EndIf;
	Return Catalogs.GuestVehicles.GetVehicleByDescription(vCardDesc);
EndFunction // GetCarByDescriptionAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountConfirmationTextEditEnd(pText, pExtraParams) Export
	If ValueIsFilled(pText) And Not ThisObject.ReadOnly Then
		Object.DiscountConfirmationText = TrimAll(pText);
		If Right(TrimR(Object.DiscountConfirmationText), 1) <> Char(8226) Then
			Object.DiscountConfirmationText = TrimAll(Object.DiscountConfirmationText) + Char(8226);
		EndIf;
		ThisObject.Modified = True;
	EndIf;
EndProcedure // DiscountConfirmationTextEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedChargesRemarksStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)   
	pStandardProcessing = False;
	vCurrData = Items.FixedCharges.CurrentData;
	If vCurrData <> Undefined Then            
		vND = New NotifyDescription("AfterInputTextFixedChargesRemarks", ThisObject, New Structure("CurRow", vCurrData));
		OpenForm("CommonForm.tcInputText", New Structure("Text", vCurrData.Remarks), pItem, , , , vND, FormWindowOpeningMode.LockOwnerWindow); 
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterInputTextFixedChargesRemarks(pText, pExtraParams) Export 
	If pText <> Undefined Then
		pExtraParams.CurRow.Remarks = pText;	
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetBedsSetupList(pBedsSetup, pRoomType)
	vBedsSetupList = New ValueList();
	If ValueIsFilled(pRoomType) And pRoomType.AllowedBedsSetups.Count() > 0 Then
		For Each vRow In pRoomType.AllowedBedsSetups Do
			If ValueIsFilled(vRow.BedsSetup) And vBedsSetupList.FindByValue(vRow.BedsSetup) = Undefined Then
				vBedsSetupList.Add(vRow.BedsSetup);
			EndIf;
		EndDo;
	EndIf;
	If ValueIsFilled(pBedsSetup) Then
		If vBedsSetupList.FindByValue(pBedsSetup) = Undefined Then
			vBedsSetupList.Insert(0, pBedsSetup);
		EndIf;
	EndIf;
	Return vBedsSetupList;
EndFunction // GetBedsSetupList

// --------------------------------------------------------------------------------
&AtServer
Procedure ResetOtherRoomGuestsVouchersIfNeeded()
	vRoomRateType = Object.RoomRateType;
	If Not ValueIsFilled(vRoomRateType) And ValueIsFilled(Object.RoomRate) And ValueIsFilled(Object.RoomRate.RoomRateType) Then
		vRoomRateType = Object.RoomRate.RoomRateType;
	EndIf;
	If ValueIsFilled(vRoomRateType) And vRoomRateType.AutoGenerationOfVoucherNumbers And ValueIsFilled(vRoomRateType.VoucherType) Then
		For Each vGiGRow In GuestsInGroup Do
			i = GuestsInGroup.IndexOf(vGiGRow) + 2;
			If ValueIsFilled(vGiGRow.HotelProduct) And vGiGRow.HotelProduct = Object.HotelProduct Then
				vGiGRow.HotelProduct = Catalogs.HotelProducts.EmptyRef();
				ThisObject["HotelProduct" + i] = vGiGRow.HotelProduct;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // ResetOtherRoomGuestsVouchersIfNeeded

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdateRowRateSumAtServer(pObj, pLineNumber, pUseObj = False)
	vLineNumber = pLineNumber;
	vObj = Object;
	If pUseObj Then
		vObj = pObj;
	EndIf;
	vSrvRows = vObj.Services.FindRows(New Structure("LineNumber", vLineNumber));
	If vSrvRows.Count() = 1 Then
		vSrvRow = vSrvRows.Get(0);
		
		// If this is not an accommodation service then try to find and position to it assuming that it is somewhere up
		vIsAccommodationService = True;
		vAccountingDate = vSrvRow.AccountingDate;
		If Not (vSrvRow.IsInPrice And vSrvRow.IsRoomRevenue And Not vSrvRow.RoomRevenueAmountsOnly And Not vSrvRow.IsSplit) Then
			vIsAccommodationService = False;
			
			If BegOfDay(vObj.CheckInDate) < BegOfDay(vObj.CheckOutDate) Then
				vSrvRowService = vSrvRow.Service;
				If ValueIsFilled(vSrvRowService) And ValueIsFilled(vSrvRowService.QuantityCalculationRule) Then
					vAccountingDateMove = cmGetAccountingDateMove(vSrvRowService.QuantityCalculationRule, vSrvRow.IsManual, pObj, True);
					If vAccountingDateMove < 0 Then
						vAccountingDate = vAccountingDate + vAccountingDateMove*(24*3600);
					EndIf;
				EndIf;
			EndIf;
			
			vLineNumber = vLineNumber - 1;
			While vLineNumber > 0 Do
				vPrevSrvRows = vObj.Services.FindRows(New Structure("LineNumber", vLineNumber));
				If vPrevSrvRows.Count() = 1 Then
					vPrevSrvRow = vPrevSrvRows.Get(0);
					If Not vPrevSrvRow.IsManual Then
						If vPrevSrvRow.IsInPrice And vPrevSrvRow.IsRoomRevenue And Not vPrevSrvRow.RoomRevenueAmountsOnly And Not vPrevSrvRow.IsSplit And 
						   vPrevSrvRow.AccountingDate = vAccountingDate Then
							vIsAccommodationService = True;
							vSrvRow = vPrevSrvRow;
							Break;
						Else
							vPrevSrvRowAccountingDate = vPrevSrvRow.AccountingDate;
							If BegOfDay(vObj.CheckInDate) < BegOfDay(vObj.CheckOutDate) Then
								vPrevSrvRowService = vPrevSrvRow.Service;
								If ValueIsFilled(vPrevSrvRowService) And ValueIsFilled(vPrevSrvRowService.QuantityCalculationRule) Then
									vAccountingDateMove = cmGetAccountingDateMove(vPrevSrvRowService.QuantityCalculationRule, vPrevSrvRow.IsManual, pObj, True);
									If vAccountingDateMove < 0 Then
										vPrevSrvRowAccountingDate = vPrevSrvRowAccountingDate + vAccountingDateMove*(24*3600);
									EndIf;
								EndIf;
							EndIf;
							If vPrevSrvRowAccountingDate <> vAccountingDate Then
								Break;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
				vLineNumber = vLineNumber - 1;
			EndDo;
		EndIf;
		
		// We need to update the rate sum in the accommodation service row to the total daily rate amount including all in price extra services
		If vIsAccommodationService And vSrvRow.IsInPrice And vSrvRow.IsRoomRevenue And Not vSrvRow.RoomRevenueAmountsOnly And Not vSrvRow.IsSplit Then
			vSrvRow.RateSum = vSrvRow.Sum;
			vSrvRow.RateDiscountSum = vSrvRow.DiscountSum;
			vSrvRow.RateCommissionSum = vSrvRow.CommissionSum;

			vLineNumber = vLineNumber + 1;
			While vLineNumber <= vObj.Services.Count() Do
				vNextSrvRows = vObj.Services.FindRows(New Structure("LineNumber", vLineNumber));
				If vNextSrvRows.Count() = 1 Then
					vNextSrvRow = vNextSrvRows.Get(0);
					If Not vNextSrvRow.IsManual Then
						If vNextSrvRow.IsInPrice And Not (vNextSrvRow.IsRoomRevenue And Not vNextSrvRow.RoomRevenueAmountsOnly And Not vNextSrvRow.IsSplit) Then
							vNextSrvRow.RateSum = 0;
							vNextSrvRow.RateDiscountSum = 0;
							vNextSrvRow.RateCommissionSum = 0;
							vNextSrvRowAccountingDate = vNextSrvRow.AccountingDate;
							If BegOfDay(vObj.CheckInDate) < BegOfDay(vObj.CheckOutDate) Then
								vNextSrvRowService = vNextSrvRow.Service;
								If ValueIsFilled(vNextSrvRowService) And ValueIsFilled(vNextSrvRowService.QuantityCalculationRule) Then
									vAccountingDateMove = cmGetAccountingDateMove(vNextSrvRowService.QuantityCalculationRule, vNextSrvRow.IsManual, pObj, True);
									If vAccountingDateMove < 0 Then
										vNextSrvRowAccountingDate = vNextSrvRowAccountingDate + vAccountingDateMove*(24*3600);
									EndIf;
								EndIf;
							EndIf;
							If vNextSrvRowAccountingDate = vAccountingDate Then
								If vSrvRow.Folio = vNextSrvRow.Folio Then
									vSrvRow.RateSum = vSrvRow.RateSum + vNextSrvRow.Sum;
									vSrvRow.RateDiscountSum = vSrvRow.RateDiscountSum + vNextSrvRow.DiscountSum;
									vSrvRow.RateCommissionSum = vSrvRow.RateCommissionSum + vNextSrvRow.CommissionSum;
								EndIf;
							Else
								Break;
							EndIf;
						ElsIf vNextSrvRow.IsInPrice And vNextSrvRow.IsRoomRevenue And Not vNextSrvRow.RoomRevenueAmountsOnly And Not vNextSrvRow.IsSplit Then
							Break;
						Else
							vNextSrvRow.RateSum = 0;
							vNextSrvRow.RateDiscountSum = 0;
							vNextSrvRow.RateCommissionSum = 0;
						EndIf;
					EndIf;
				EndIf;
				vLineNumber = vLineNumber + 1;
			EndDo;
		Else
			vSrvRow.RateSum = 0;
			vSrvRow.RateDiscountSum = 0;
			vSrvRow.RateCommissionSum = 0;
		EndIf;
	EndIf;
EndProcedure // UpdateRowRateSumAtServer

#EndRegion
