 
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Initialization
	WasNew = False;
	WasAlreadyPrint = False;
	LastKidsNumber = 0;
	LastNumberOfAdults = 1;
	NumberOfAdults = 1;
	NumberOfGuestFields = 5;
	NumberOfKidAgeFields = 12;
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
				
				vStructure = New Structure("AccommodationType, Amount, GuestName, GuestRef, DateOfBirth, Phone, Email, HotelProduct", vAccommodationType, Undefined, Undefined, Undefined, vAge, Undefined, Undefined, Undefined); 
				
				DocsList.Add(vStructure, vAccommodationType.SortCode);
			EndDo;
		EndIf;
	EndIf;
	If Parameters.Property("GuestsToCheckInList") And TypeOf(Parameters.GuestsToCheckInList) = Type("ValueList") Then
		GuestsToCheckInList.LoadValues(Parameters.GuestsToCheckInList.UnloadValues());
	EndIf;
	// Phone2
	If IsBlankString(Object.Fax) Then
		Items.AddPhone2.Visible = True;
		Items.Fax.Visible = false;
	Else
		Items.AddPhone2.Visible = False;
		Items.Fax.Visible = True;
	EndIf;

	vKeyParameter = ThisForm.Parameters.Key;
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
	
	If ThisForm.Parameters.Property("ParentAccommodation") And Not OneGuestMode Then
		vParentDoc = ThisForm.Parameters.ParentAccommodation;
		If ValueIsFilled(vParentDoc) And TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") Then
			vNewObj = Documents.Accommodation.CreateDocument();
			vNewObj.Fill(vParentDoc);
			vNewObj.Room = vParentDoc.Room;
			ValueToFormAttribute(vNewObj, "Object");
		EndIf;
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
	
	// Fill Accommodation Statuses
	FillAccommodationStatusListChoice();
	
	// Fill parameters
	Items.ClientType.ChoiceList.LoadValues(GetArrayOfAllClientTypes());
	Items.SourceOfBusiness.ChoiceList.LoadValues(GetArrayOfAllSourceOfBusiness());
	
	// Fill room properties
	ThisForm.RoomProperties = GetRoomPropertiesValueList();
	
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
	
	// Beds setup
	UseBedsSetups = GetBedsSetupFunctionalOption();
	Items.BedsSetup.Visible = UseBedsSetups;
	
	// Main form processing
	OnOpenForm(Object.Posted);
	
	// Board place
	vBoardPlaces = cmGetBoardPlaces(Object.Hotel);
	If vBoardPlaces.Count() = 0 Then
		Items.BoardPlace.Visible = False;
	EndIf;
	
	// Check permissions
	OnOpenCheckPermissionsResult = BeforeOpenCheckPermissions();
	
	// Terms choice list
	FillServicePackageChoiceList();
	
	// Check if resort fee is used
	If Not ValueIsFilled(Object.Hotel.Region) Then
		Items.FormAddResortFeeExemption.Visible = False;
		Items.FormClearResortFeeExemption.Visible = False;
	EndIf;
	
	// Show room rate by default
	If Items.ServicePackage.Visible Then
		Items.GroupRoomRate.Show();
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
	
	// Check if this is main room document
	If OneGuestModeWasNotSet Then
		If ValueIsFilled(Object.Ref) And Not ValueIsFilled(Object.AccommodationTemplate) Then
			If Object.Posted And ValueIsFilled(Object.AccommodationStatus) And tcOnServer.cmGetAttributeByRef(Object.AccommodationStatus, "IsActive") Then
				vMainRoomDoc = GetMainRoomDocument(Object.Number, Object.Room, Object.GuestGroup);
				If ValueIsFilled(vMainRoomDoc) And vMainRoomDoc <> Object.Ref Then
					If tcOnServer.cmGetAttributeByRef(vMainRoomDoc, "CheckInDate") < Object.CheckOutDate And tcOnServer.cmGetAttributeByRef(vMainRoomDoc, "CheckOutDate") > Object.CheckInDate Then
						OpenForm("Document.Accommodation.ObjectForm", New Structure("Key, OneGuestMode", vMainRoomDoc, False), FormOwner, vMainRoomDoc);
						pCancel = True;
						Return;
					EndIf;
				EndIf;
			Else
				OpenForm("Document.Accommodation.ObjectForm", New Structure("Key, OneGuestMode", Object.Ref, True), FormOwner, tcOnServer.GetStringUUIDByRef(Object.Ref));
				pCancel = True;
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	If DocumentBackgroundJobsCount > 0 Then
		ThisForm.ReadOnly = True;
		ThisForm.Enabled = False;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'The document is being posted. Try again later.'; ru = 'Документ проводится, попробуйте открыть его позже.'; de = '-'")); //#Translate
	EndIf;
	
	If Not IsBlankString(OnOpenCheckPermissionsResult) Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(OnOpenCheckPermissionsResult);
		Return;
	EndIf;
	
	CurrentItem = Items.Room;
	
	Items.HotelProduct.ChoiceButtonRepresentation = ChoiceButtonRepresentation.Auto;
	Items.HotelProduct.CreateButton = True;
	Items.HotelProduct2.ChoiceButtonRepresentation = ChoiceButtonRepresentation.Auto;
	Items.HotelProduct2.CreateButton = True;
	Items.HotelProduct3.ChoiceButtonRepresentation = ChoiceButtonRepresentation.Auto;
	Items.HotelProduct3.CreateButton = True;
	Items.HotelProduct4.ChoiceButtonRepresentation = ChoiceButtonRepresentation.Auto;
	Items.HotelProduct4.CreateButton = True;
	Items.HotelProduct5.ChoiceButtonRepresentation = ChoiceButtonRepresentation.Auto;
	Items.HotelProduct5.CreateButton = True;
	
	If Not IsNew Then
		vTasksStructure = GetTasksStructure(Object.Ref);
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
				If vShow Then
					tcCommonFunctionOnClientServer.TextMessage(vTaskStruct.Remarks);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Set form functional option parameters
	SetFormFunctionalOptionParameters(New Structure("Hotel", Object.Hotel));
	
	AttachIdleHandler("FillTypesTableOnClient", 0.1, True);
EndProcedure // OnOpen

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
	If ThisForm.ReadOnly Then
		ThisForm.Modified = False;
	EndIf;
	vModified = ThisForm.Modified;
	If vModified Then
		pCancel = True;
		ShowQueryBox(New NotifyDescription("BeforeClose_AfterAnswering", ThisForm, pCancel), NStr("en='Data was changed! Save the changes?';ru='Данные были изменены! Сохранить изменения?';de='Die Daten wurden geändert! Änderungen speichern?'"), QuestionDialogMode.YesNoCancel);
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
	If pEventName = "Client.Change" Then
		If TypeOf(pSource) = Type("ClientApplicationForm") And pSource = ThisForm Then
			Object.Guest = pParameter;
			GuestOnChangeAtServer();
		ElsIf TypeOf(pSource) = Type("FormTable") And tcOnClient.GetParentForm(pSource) = ThisForm Then
			vFieldName = ThisForm.CurrentItem.Name;
			If Left(vFieldName, 8) = "SelGuest" Then
				If vFieldName = "SelGuest1" Then
					Object.Guest = pParameter;
					ThisForm[vFieldName] = GetClientFullName(pParameter);
					GuestOnChangeAtServer();
				Else
					ThisForm[Right(vFieldName, StrLen(vFieldName)-3)] = pParameter;
					ThisForm[vFieldName] = GetClientFullName(pParameter);
					AddGuestOnChange(ThisForm.CurrentItem);
				EndIf;
			EndIf;
		ElsIf TypeOf(pSource) = Type("FormField") And tcOnClient.GetParentForm(pSource) = ThisForm Then
			vFieldName = pSource.Name;
			If Left(vFieldName, 8) = "SelGuest" Then
				If vFieldName = "SelGuest1" Then
					Object.Guest = pParameter;
					ThisForm[vFieldName] = GetClientFullName(pParameter);
					GuestOnChangeAtServer();
				Else
					ThisForm[Right(vFieldName, StrLen(vFieldName)-3)] = pParameter;
					ThisForm[vFieldName] = GetClientFullName(pParameter);
					AddGuestOnChange(pSource);
				EndIf;
			EndIf;
		EndIf;
	ElsIf pEventName = "ForeignerRegistryRecord.Write" Then
		If TypeOf(pSource) = Type("FormField") And tcOnClient.GetParentForm(pSource) = ThisForm Then
			vFieldName = pSource.Name;
			If Left(vFieldName, 8) = "SelGuest" Then
				If Not IsOnCloseForm Then
					ThisForm.Read();
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
		If pSource = ThisForm.CurrentItem Then
			If pSource = Items.HotelProduct Then
				Object.HotelProduct = pParameter;
				HotelProductOnChangeAtServer();
				ThisForm.Modified = True;
			Else
				vInd = GetItemIndex(ThisForm.CurrentItem.Name);
				If Not IsBlankString(vInd) Then
					ThisForm[pSource.Name] = pParameter;
					ExtraGuestHotelProductOnChangeAtServer(vInd);
					ThisForm.Modified = True;
				EndIf;
			EndIf;
		EndIf;
	ElsIf pEventName = "HotelProduct.Deleted" Then
		If pSource = ThisForm.CurrentItem Then
			If pSource = Items.HotelProduct Then
				Object.HotelProduct = Undefined;
				HotelProductOnChangeAtServer();
				ThisForm.Modified = True;
			Else
				vInd = GetItemIndex(ThisForm.CurrentItem.Name);
				If Not IsBlankString(vInd) Then
					ThisForm[pSource.Name] = Undefined;
					ExtraGuestHotelProductOnChangeAtServer(vInd);
					ThisForm.Modified = True;
				EndIf;
			EndIf;
		EndIf;
	ElsIf pEventName = "Document.Reservation.Write" And ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(pParameter) And 
		  (TypeOf(pParameter) = Type("DocumentRef.Accommodation") Or TypeOf(pParameter) = Type("DocumentRef.Reservation")) And 
		   tcOnServer.cmGetAttributeByRef(pParameter, "GuestGroup") = Object.GuestGroup Then
			If Not IsOnCloseForm Then
				ThisForm.Read();
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
				ThisForm.Read();
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
		If ValueIsFilled(pParameter) And (pParameter = Object.Ref And pSource <> ThisForm Or GuestsInGroup.FindRows(New Structure("Ref", pParameter)).Count() > 0) Then
			If Not IsOnCloseForm Then
				ThisForm.Read();
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
		If pSource = ThisForm Then
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
		ElsIf pParameter.ModeAfterCheck = "ScanDocuments" Then
			ScanDocuments(Undefined);
		ElsIf pParameter.ModeAfterCheck = "GuestRegistrationActionClick" Then
			GuestRegistrationActionClick(ThisForm.CurrentItem);
		Else
			Post(Commands["Post"]);
		EndIf;
	ElsIf pEventName = "MessageWrite" Then
		FillTasksPresentation();
	ElsIf pEventName = "Reservation.RoomTypeUpgradeWasChanged" And pParameter = Object.Ref Then
		ManualPriceAppearance(, True);
	ElsIf pEventName = "Catalog.GuestGroups.Changed" And pParameter = Object.GuestGroup Then
		If Not IsOnCloseForm Then
			ThisForm.Read();
		EndIf;
	ElsIf pEventName = "System.Hotel.Changed" And pParameter <> Object.Hotel Then
		If ThisForm.Modified Then
			PostAndClose(Commands.PostAndClose);
		Else
			ThisForm.Close();
		EndIf;
	ElsIf pEventName = "ServicePackages.Changed" And pParameter <> Undefined And pSource = ThisForm Then
		SaveServicePackagesListAtServer(pParameter);
		FillAmenitiesFromServicePackages(pParameter);
		RoomRateOnChangeAtServer();
		RefreshDataRepresentation();
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	If Not FunctionsAndPrintFormsWereLoaded Then
		FillFunctionsButton();
		FillPrintingButton();
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

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestRegistrationActionClick(pItem)
	// Save document first
	If (WasPosted = False Or ThisForm.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "GuestRegistrationActionClick"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vResult = WriteAtServer(, vWarning);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.TextMessage(vWarning);
		EndIf;		
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.TextMessage(vResult);
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
	// Get guest index
	vIndexStr = "";
	vItemName = Mid(pItem.Name, 6);
	vNum = 1;
	While True Do
		If vNum > StrLen(vItemName) Then
			Break;
		EndIf;
		vChar = Mid(vItemName, vNum, 1);
		If StrFind("0123456789", vChar) > 0 Then
			vIndexStr = vIndexStr + vChar;
		Else
			Break;
		EndIf;
		vNum = vNum + 1;
	EndDo;
	If Not IsBlankString(vIndexStr) Then
		vIndex = Number(vIndexStr);
		vGuestRegDocument = ThisForm["Guest"+String(vIndex)+"Registration"];
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
Procedure CustomFieldOnChange(pItem)
	ThisForm.Modified = True;
EndProcedure // CustomFieldOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PayerOnChange(pItem)
	vIsNeedToOpenForm = PayerOnChangeAtServer();
	If vIsNeedToOpenForm Then
		vFrm = GetForm("Catalog.Customers.Form.mcListForm", New Structure("CurrentRow, ChoiceMode", Object.Customer, True), Items.Customer);
		vFrm.CloseOnOwnerClose = True;
		vFrm.CloseOnChoice = True;
		vFrm.Open();
	EndIf;
	ThisForm.Modified = True;
EndProcedure // PayerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	ClientTypeConfirmationTextChange();	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure MarketingCodeOnChange(pItem)
	MarketingCodeOnChangeAtServer();
	BuildThisFormClientDataDecoration();
	ThisObject.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SourceOfBusinessOnChange(pItem)
	SourceOfBusinessOnChangeAtServer();
	BuildThisFormClientDataDecoration();
	ThisForm.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TripPurposeOnChange(pItem)
	BuildThisFormClientDataDecoration();
	ThisObject.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BedsSetupOnChange(pItem)
	BuildThisFormClientDataDecoration();
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
Procedure CarOnChange(pItem)
	BuildThisFormClientDataDecoration();
	ThisForm.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure IsForFolioSplitOnChange(pItem)
	ThisForm.Modified = True;
	CheckGuestFieldCount();
	AccommodationTypeOnChangeAtServer(False);
	// Calculate totals
	TotalSum = CalculateTotalServices();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardOnChange(pItem)
	If ValueIsFilled(Object.DiscountCard) Then
		If GetDiscountCardIsBlocked(Object.DiscountCard) Then
			vMessage = NStr("en='Discount card is blocked!';ru='Дисконтная карта заблокирована!';de='Die Diskontkarte ist blockiert!'");
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
			DiscountCardsEmptyRef();
		ElsIf GetDiscountCheckInDate(Object.DiscountCard) Then
			vMessage = NStr("en='Discount card is not valid on guest check in date!';ru='Дисконтная карта не действует на дату заезда гостя!';de='Die Diskontkarte gilt nicht am Anreisetag des Gastes!'");
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
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
							tcCommonFunctionOnClientServer.TextMessage(vMessage);
							DiscountCardsEmptyRef();
						Else
							vMessage = NStr("ru='Дисконтная карта выдана на другого клиента: '; 
							                |de='Discount card was issued to the different client: ';
							                |en='Discount card was issued to the different client: ") + TrimAll(vClient) + "!";
							tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
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
Procedure ExtraGuestAccommodationTypeOnChange(pItem)
	vInd = GetItemIndex(pItem.Name);
	If Not IsBlankString(vInd) Then
		ExtraGuestAccommodationTypeOnChangeAtServer(vInd);
	EndIf;
	ThisForm.Modified = True;
EndProcedure // ExtraGuestAccommodationTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationOnChange(pItem)
	BuildThisFormClientDataDecoration();
	ThisForm.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationClearing(pItem, pStandardProcessing)
	ThisForm.RoomProperties.Clear();
	ThisForm.RoomPropertiesPresentation = GetRoomPropertiesPresentation();
	BuildThisFormClientDataDecoration();
	// Save room properties to the document object
	FillDocumentRoomProperties();
	ThisForm.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vChoiceFrm = OpenForm("Catalog.RoomRates.Form.tcChoiceForm", New Structure("ChoiceMode, Hotel, Company, Customer, Contract, PeriodFrom, PeriodTo, RoomRates, CurrentRow", True, Object.Hotel, PredefinedValue("Catalog.Companies.EmptyRef"), Object.Customer, Object.Contract, Object.CheckInDate, Object.CheckOutDate, New ValueList, Object.RoomRate), pItem);
EndProcedure // RoomRateStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountCardStartChoice(pItem, ChoiceData, StandardProcessing)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToInputDiscountCardNumberManually") Then
		StandardProcessing=False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ContractOnChange(pItem)
	vMessage = "";
	ContractOnChangeAtServer(, vMessage);
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
	ThisForm.Modified = True;
EndProcedure // ContractOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerOnChange(pItem)
	CustomerOnChangeAtServer();
	If ValueIsFilled(Object.Customer) Then
		Items.Contract.ReadOnly = False;
	Else
		Items.Contract.ReadOnly = True;
	EndIf;
	ThisForm.Modified = True;
EndProcedure // CustomerOnChange

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
	ThisForm.Modified = True;
EndProcedure // ResetAccommodationType

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTypeOnChange(pItem, pRecalculateServices = True)
	AccommodationTypeOnChangeAtServer(pRecalculateServices, , True);
	ThisForm.Modified = True;
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
	ClearOccupationPercents(CurrentDate());
	RoomTypeOnChangeAtServer(pRecalculateServices, pRecalculateDiscounts);
	ThisForm.Modified = True;
EndProcedure // RoomTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutDateOnChange(pItem)
	CheckOutDateOnChangeAtServer();
	ThisForm.Modified = True;
EndProcedure // CheckOutDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomQuotaOnChange(pItem)
	RoomQuotaOnChangeAtServer();
	ThisForm.Modified = True;
EndProcedure // RoomQuotaOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentOnChange(pItem)
	AgentOnChangeAtServer();
	BuildCommissionGroupCollapsedTitle();
	ThisForm.Modified = True;
EndProcedure // AgentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(pItem)
	DurationOnChangeAtServer();
	ThisForm.Modified = True;
EndProcedure // DurationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(pItem)
	CheckInDateOnChangeAtServer();
	ThisForm.Modified = True;
EndProcedure // CheckInDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestOnChange(pItem)
	GuestOnChangeAtServer();	
	CheckGuestRemarksOnClient(pItem);
	ThisForm.Modified = True;
EndProcedure // GuestOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
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
		If Object.RoomType <> vRoomType Then
			ClearOccupationPercents(CurrentDate());
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
		MainParametersChangeAtServer(vClientTypeHasChanged);
	ElsIf TypeOf(vRoomType) = Type("CatalogRef.RoomTypes") Then
		If Object.RoomType <> vRoomType Then
			ClearOccupationPercents(CurrentDate());
		EndIf;
		Object.RoomType = vRoomType;
		RoomTypeOnChangeAtServer(True, False);
	ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.Rooms") Then
		tcOnClient.AskRoomChangeQuestion(pSelectedValue, Object);
		RoomChoiceProcessingAtServer(pSelectedValue);
	EndIf;
	vTypes = GetTypesArrayByRoomType(vRoomType);
	Items.AccommodationType.ChoiceList.LoadValues(vTypes);
	For Each vGRow In GuestsInGroup Do
		Items["AccommodationType" + Format(GuestsInGroup.IndexOf(vGRow) + 2, "NFD=0; NG=")].ChoiceList.LoadValues(vTypes);
	EndDo;
	ThisForm.Modified = True;
EndProcedure // RoomTypeChoiceProcessing

// ----------------------------------------------------------------------------
&AtServer
Procedure MainParametersChangeAtServer(pClientTypeHasChanged)
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
	RoomOnChangeAtServer(False, , pClientTypeHasChanged);
	RoomRateOnChangeAtServer();
EndProcedure // MainParametersChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationStatusOnChange(pItem)
	vResult = AccommodationStatusOnChangeAtServer();
	If ValueIsFilled(vResult) Then
		tcCommonFunctionOnClientServer.TextMessage(vResult);
	EndIf;
EndProcedure // AccommodationStatusOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RemarksOnChange(pItem)
	BuildThisFormRemarksDataDecoration();
	ThisForm.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HousekeepingRemarksOnChange(pItem)
	BuildThisFormRemarksDataDecoration();
	ThisForm.Modified = True;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInTimeOnChange(pItem)
	CheckInTimeOnChangeAtServer();
	ThisForm.Modified = True;
EndProcedure // CheckInTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionServiceGroupOnChange(pItem)
	AgentCommissionServiceGroupOnChangeAtServer();
	BuildCommissionGroupCollapsedTitle();
	ThisForm.Modified = True;
EndProcedure // AgentCommissionServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionTypeOnChange(pItem)
	AgentCommissionTypeOnChangeAtServer();
	BuildCommissionGroupCollapsedTitle();
	ThisForm.Modified = True;
EndProcedure // AgentCommissionTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutTimeOnChange(pItem)
	CheckOutTimeOnChangeAtServer();
	ThisForm.Modified = True;
EndProcedure // CheckOutTimeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOutTimeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = GetDayTimes(pItem.Name);
	vNotifyDescription = New NotifyDescription("CheckOutTimeAfterChoice", ThisForm);
	vParams = New Structure("ValueList, MultipleChoice, Title", vList, False);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
EndProcedure // CheckOutTimeStartChoice

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
Procedure GuestGroupIDOnChange(pItem)
	// Check if there is another active guest group with this description
	vOtherGroupStruct = FindGuestGroupByID(Object.Hotel, Object.GuestGroup, TrimAll(GuestGroupID));
	If vOtherGroupStruct <> Undefined Then
		vUM = New UserMessage();
		vUM.Field = "GuestGroupID";
		vUM.DataKey = vOtherGroupStruct.GuestGroup;
		vUM.Text = NStr("en='Another group with code '; ru='В базе данных уже есть группа с кодом '; de='Die Datenbank hat bereits eine Gruppe mit einem Code '") + vOtherGroupStruct.Code + NStr("en=' exists with given Ref.#: '; ru=' и совпадающим Ref.#: '; de=' und einer passenden Ref.#: '") + TrimAll(GuestGroupID);
		vUM.Message();
	EndIf;
	// Save group description
	GroupIDOnChangeAtServer();
	ThisForm.Modified = True;
EndProcedure // GuestGroupIDOnChange

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
	ThisForm.Modified = True;
EndProcedure // GuestGroupDescriptionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vSelLastName = "";
	vSelFirstName = "";
	vSelSecondName = "";
	// Get clients search form
	If ValueIsFilled(Object.Guest) Then
		vSelLastName = tcOnServer.cmGetAttributeByRef(Object.Guest, "LastName");
		vSelFirstName = tcOnServer.cmGetAttributeByRef(Object.Guest, "FirstName");
		vSelSecondName = tcOnServer.cmGetAttributeByRef(Object.Guest, "SecondName");
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
	OpenForm("Catalog.Clients.Form.mcListForm", New Structure("ChoiceMode, MultipleChoice, SelLastName, SelFirstName, SelSecondName", True, False, vSelLastName, vSelFirstName, vSelSecondName), pItem);
EndProcedure // GuestStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	// Get client form
	If ValueIsFilled(Object.Guest) And (tcOnServer.cmGetAttributeByRef(Object.Guest, "FullName") = pItem.EditText) Then
		vFrm = GetForm("Catalog.Clients.ObjectForm", New Structure("Key", Object.Guest), pItem);
		vFrm.Open();
	Else
		vFrm = GetForm("Catalog.Clients.ObjectForm", , pItem, New UUID());
		vSelGuest = pItem.EditText;
		// Get guest last name, first name and second name
		vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
		vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
		If TypeOf(vFrm) = Type("ClientApplicationForm") Then
			vFrm.Object.LastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
			If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vFrm.Object.FirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
				If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
					vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
					vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
					vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
					vFrm.Object.SecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
				EndIf;
			EndIf;
		Else
			vFrm.LastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
			If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vFrm.FirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
				If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
					vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
					vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
					vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
					vFrm.SecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
				EndIf;
			EndIf;
		EndIf;
		vFrm.Open();
	EndIf;
EndProcedure // GuestOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckGuestRemarksOnClient(pItem)
	If TrimAll(pItem.Name) = "SelGuest1" Then
		vValue = Object["Guest"];
	Else
		vValue = ThisForm[StrReplace(TrimAll(pItem.Name), "Sel", "")];
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
			pItem.TextEdit = False;
			LastGuestFullName = SelGuest1;
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
	ThisForm.Modified = True;
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
		ThisForm[pItem.Name] = "";
		LastGuestFullName = "";
		ThisForm.Modified = True;
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
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;
		ThisForm.Modified = True;
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
			ThisForm[pItem.Name] = "";
			LastGuestFullName = "";
		ElsIf StrLen(pText) > 2 Then
			vChoiceDataUID = tcOnServer.cmGetGuestsChoiceDataList(pText);
			pChoiceData = GetFromTempStorage(vChoiceDataUID);
			If pChoiceData.Count() = 0 Then
				pChoiceData.Add(pText, NStr("en='--Guest not found--';ru='--Гость не найден--';de='--Gast nicht gefunden--'"));
			Else
				pChoiceData.Insert(0, TrimR(pText));
			EndIf;
		Else
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;
	EndIf;
	ThisForm.Modified = True;
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
	ThisForm.Modified = True;
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
				ThisForm.Modified = True;
			Else
				vNotifyDescription = New NotifyDescription("AfterClientChoiceByPhoneOrEMail", ThisForm);
				vParams = New Structure("ValueList, MultipleChoice, Title", vList, False);
				OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
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
				ThisForm.Modified = True;
			Else
				vNotifyDescription = New NotifyDescription("AfterClientChoiceByPhoneOrEMail", ThisForm);
				vParams = New Structure("ValueList, MultipleChoice, Title", vList, False);
				OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
			EndIf;
		EndIf;
	Else
		Items.AddPhone2.Visible = True;
		Items.Fax.Visible = false;
	EndIf;
	ThisForm.Modified = True;
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
				ThisForm.Modified = True;
			Else
				vNotifyDescription = New NotifyDescription("AfterClientChoiceByPhoneOrEMail", ThisForm);
				vParams = New Structure("ValueList, MultipleChoice, Title", vList, False);
				OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
			EndIf;
		EndIf;
	EndIf;
	ThisForm.Modified = True;
EndProcedure // EMailOnChange

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
	vFrm = GetForm("Catalog.RoomQuotas.ChoiceForm", New Structure("Filter, ChoiceMode", vFilter, True), pItem, Object.Ref);
	vFrm.Open();
EndProcedure // RoomQuotaStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vFilter = New Structure("Hotel", tcOnServer.cmGetCurrentHotelAttribute());
	vFrm = GetForm("Catalog.Customers.Form.mcListForm", New Structure("Filter, ChoiceMode", vFilter, True), pItem);
	vFrm.Open();
EndProcedure // CustomerStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vKidsAgeArray = New Array;
	For vNum = 1 To NumberOfKids Do
		vKidsAgeArray.Add(ThisForm["KidAge"+vNum]);
	EndDo;
	vParams = New Structure("Hotel, RoomType, CheckInDate, CheckOutDate, Duration, RoomRate, ClientType, RoomQuota, NumberOfAdults, NumberOfKids, AgeArray", 
	                         Object.Hotel, Object.RoomType, Object.CheckInDate, Object.CheckOutDate, Object.Duration, Object.RoomRate, Object.ClientType, Object.RoomQuota, NumberOfAdults, NumberOfKids, vKidsAgeArray);
	vFrm = OpenForm("Catalog.RoomTypes.Form.mcChoiceForm", vParams, pItem, , GetMainWindow());
EndProcedure // RoomTypeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	tcOnClient.AskRoomChangeQuestion(pSelectedValue, Object);
	RoomChoiceProcessingAtServer(pSelectedValue);
	ThisForm.Modified = True;
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
	OpenForm("Catalog.Rooms.Form.mcChoiceForm", New Structure("Hotel, DateFrom, DateTo, RoomType, RoomQuota, Company, NumberOfRooms, NumberOfBeds, SelRoomProperties", vHotel, vCheckInDate, vCheckOutDate, vRoomType, vRoomQuota, Undefined, vNumberOfRooms, vNumberOfBeds, RoomProperties), pItem);
EndProcedure // RoomStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesRoomStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.RoomRates.CurrentData;
	If Object.RoomQuantity > 1 Then
		Return;
	ElsIf vCurData = Undefined Then
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
	OpenForm("Catalog.Rooms.Form.mcChoiceForm", New Structure("Hotel, DateFrom, DateTo, RoomType, RoomQuota, Company, NumberOfRooms, NumberOfBeds", vHotel, vCheckInDate, vCheckOutDate, vRoomType, vRoomQuota, Undefined, vNumberOfRooms, vNumberOfBeds), pItem);
EndProcedure // RoomRatesRoomStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomOnChange(pItem)
	tcOnClient.AskRoomChangeQuestion(Object.Room, Object);
	RoomOnChangeAtServer();
	ThisForm.Modified = True;
EndProcedure // RoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInTimeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = GetDayTimes(pItem.Name);
	vNotifyDescription = New NotifyDescription("CheckInTimeAfterChoice", ThisForm);
	vParams = New Structure("ValueList, MultipleChoice, Title", vList, False);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
EndProcedure // CheckInTimeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPropertiesPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vRoomPropertiesList = FillRoomPropertiesList();

	vNotifyDescription = New NotifyDescription("RoomPropertiesPresentationStartChoice_AfterInput", ThisForm);
	vParams = New Structure("ValueList, MultipleChoice, Title", vRoomPropertiesList, True, NStr("en='Check room properties...'; ru='Отметьте свойства номеров...'; de='Markieren Zimmereigenschaften...'"));
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestOnChange(pItem)
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	If vItemIndex > 1 Then
		vGuest = ThisForm["Guest"+vItemIndex];
		If ValueIsFilled(vGuest) Then
			vClientAge = GetClientAgeAtServer(vGuest, Object.CheckInDate);
			If vClientAge > 0 Then
				vKidIndex = vItemIndex-NumberOfAdults;
				If vKidIndex > 0 Then
					If ThisForm["KidAge"+vKidIndex] <> vClientAge Then
						ThisForm["KidAge"+vKidIndex] = vClientAge;
						KidAgeOnChange(Items["KidAge"+vKidIndex]);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		vGiGRowIndex = vItemIndex-2;
		Try
			If ValueIsFilled(ThisForm["AccommodationType"+vItemIndex]) Then
				vGiGRow = GuestsInGroup.Get(vGiGRowIndex);
				vGiGRow.IsAnnulation = False;
				vGiGRow.IsGuest = True;
				vGiGRow.GuestRef = vGuest;
				vGiGRow.Guest = ThisForm[pItem.Name];
				CalculateTotalServices();
			EndIf;
			If ValueIsFilled(vGuest) Then
				Items["SelGuest"+vItemIndex].TextEdit = False;
			Else
				Items["SelGuest"+vItemIndex].TextEdit = True;
			EndIf;
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
	vSelLastName = "";
	vSelFirstName = "";
	vSelSecondName = "";
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	vGuest = ThisForm["Guest"+vItemIndex];
	// Get clients search form
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
	OpenForm("Catalog.Clients.Form.mcListForm", New Structure("ChoiceMode, MultipleChoice, SelLastname, SelFirstName, SelSecondName", True, False, vSelLastname, vSelFirstName, vSelSecondName), pItem);
EndProcedure // AddGuestStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestClearing(pItem, pStandardProcessing)
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	ThisForm["Guest"+vItemIndex] = "";
	Items["SelGuest"+vItemIndex].TextEdit = True;
	ThisForm[pItem.Name] = "";
	CheckGuestRemarksOnClient(pItem);
	ThisForm.Modified = True;
	// Read foreigner registry documents
	ReadForeignerRegistryDocuments();
EndProcedure // AddGuestClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	vGuest = ThisForm["Guest"+vItemIndex];
	// Get client form
	If ValueIsFilled(vGuest) And (tcOnServer.cmGetAttributeByRef(vGuest, "FullName") = pItem.EditText) Then
		vFrm = GetForm("Catalog.Clients.ObjectForm", New Structure("Key", vGuest), pItem);
		vFrm.Open();
	Else
		vFrm = GetForm("Catalog.Clients.ObjectForm", New Structure("TemplateGuest", Object.Guest), pItem, New UUID());
		vSelGuest = pItem.EditText;
		// Get guest last name, first name and second name
		vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
		vLastNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
		If TypeOf(vFrm) = Type("ClientApplicationForm") Then
			vFrm.Object.LastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
			If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vFrm.Object.FirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
				If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
					vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
					vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
					vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
					vFrm.Object.SecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
				EndIf;
			EndIf;
		Else
			vFrm.LastName = Title(Left(TrimAll(vSelGuest), vLastNameLastCharNumber));
			If vLastNameLastCharNumber<>StrLen(vSelGuest) Then
				vSelGuest = Mid(TrimAll(vSelGuest), vLastNameLastCharNumber+2, StrLen(vSelGuest));
				vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
				vFirstNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
				vFrm.FirstName = Title(Left(TrimAll(vSelGuest), vFirstNameLastCharNumber));
				If vFirstNameLastCharNumber<>StrLen(vSelGuest) Then
					vSelGuest = Mid(TrimAll(vSelGuest), vFirstNameLastCharNumber+2, StrLen(vSelGuest));
					vFindedCharNumber = Find(TrimAll(vSelGuest), " ");
					vSecondNameLastCharNumber = ?(vFindedCharNumber = 0, StrLen(vSelGuest), vFindedCharNumber - 1);
					vFrm.SecondName = Title(Left(TrimAll(vSelGuest), vSecondNameLastCharNumber));
				EndIf;
			EndIf;
		EndIf;
		vFrm.Open();
	EndIf;
EndProcedure // AddGuestOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	If ValueIsFilled(pSelectedValue) Then
		If TypeOf(pSelectedValue) = Type("CatalogRef.Clients") Then
			ThisForm["Guest"+vItemIndex] = pSelectedValue;
			ThisForm[pItem.Name] = tcOnServer.cmGetAttributeByRef(pSelectedValue, "FullName");
			ThisForm["LastGuestFullName"+vItemIndex] = ThisForm[pItem.Name];
			pItem.TextEdit = False;
		ElsIf TypeOf(pSelectedValue) = Type("String") Then
			ThisForm[pItem.Name] = pSelectedValue;
			ThisForm["Guest"+vItemIndex] = tcOnServer.cmGetCatalogItemRefByCode("Clients", "", True);
			pItem.TextEdit = True;
		EndIf;
		AddGuestOnChange(pItem);
	Else
		ThisForm["Guest"+vItemIndex] = tcOnServer.cmGetCatalogItemRefByCode("Clients",, True);
		pItem.TextEdit = True;
	EndIf;
	CheckGuestRemarksOnClient(pItem);
	ThisForm.Modified = True;
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
		ThisForm["Guest"+vItemIndex] = Undefined;
		ThisForm[pItem.Name] = "";
		ThisForm["LastGuestFullName"+vItemIndex] = "";
		ThisForm.Modified = True;
	Else
		pStandardProcessing = False;
		vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
		vGuest = ThisForm["Guest"+vItemIndex];
		If ValueIsFilled(vGuest) Then
			pItem.TextEdit = False;
			ThisForm[pItem.Name] = TrimR(ThisForm["LastGuestFullName"+vItemIndex]);
			vMessage = New UserMessage;
			vMessage.Field = pItem.Name;
			vMessage.Text = NStr("en='The data can be changed in the guest card only! (To open the guest card, click the magnifying glass; To write a new guest, click the delete icon and type guest name in the field)';ru='Данные могут быть изменены только в карточке гостя! (Для того, чтобы открыть карточку гостя, нажмите кнопку с изображением лупы; Для того, чтобы создать нового гостя, нажмите кнопку с крестиком и введите ФИО гостя в поле)';de='Die Daten können nur in der Karte des Gastes geändert werden! (Um die Karte des Gastes zu öffnen, drücken Sie die Taste mit der Lupe; um einen neuen Gast zu erstellen, drücken Sie die Taste mit dem Kreuz und geben Sie den Namen und den Vornamen des Gastes ins Feld ein)'");
			vMessage.Message();
		Else
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;
		ThisForm.Modified = True;
	EndIf;
EndProcedure // AddGuestAutoComplete

// -----------------------------------------------------------------------------
&AtClient
Procedure AddGuestTextEditEnd(pItem, pText, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vItemIndex = Number(Right(pItem.Name, StrLen(pItem.Name)-8));
	vGuest = ThisForm["Guest"+vItemIndex];
	If ValueIsFilled(vGuest) Then
		If IsBlankString(pText) Then
			pItem.TextEdit = True;
			ThisForm["Guest"+vItemIndex] = Undefined;
			ThisForm["LastGuestFullName"+vItemIndex] = "";
		ElsIf Lower(TrimAll(tcOnServer.cmGetAttributeByRef(vGuest, "FullName"))) <> Lower(TrimAll(pText)) And 
		      pItem.TextEdit Then
			pItem.TextEdit = False;
			ThisForm[pItem.Name] = ThisForm["LastGuestFullName"+vItemIndex];
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
			ThisForm["Guest"+vItemIndex] = Undefined;
			ThisForm["LastGuestFullName"+vItemIndex] = "";
		ElsIf StrLen(pText) > 2 Then
			vChoiceDataUID = tcOnServer.cmGetGuestsChoiceDataList(pText);
			pChoiceData = GetFromTempStorage(vChoiceDataUID);
			If pChoiceData.Count() = 0 Then
				pChoiceData.Add(pText, NStr("en='--Guest not found--';ru='--Гость не найден--';de='--Gast nicht gefunden--'"));
			Else
				pChoiceData.Insert(0, TrimR(pText));
			EndIf;
		Else
			pStandardProcessing = True;
			pChoiceData = Undefined;
		EndIf;
	EndIf;
	ThisForm.Modified = True;
EndProcedure // AddGuestTextEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vFrmResult = Undefined;
	
	OpenForm("Catalog.GuestGroups.ChoiceForm",, pItem,,,, New NotifyDescription("GuestGroupStartChoiceEnd", ThisForm, New Structure("pItem", pItem)), FormWindowOpeningMode.LockWholeInterface);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupCreateDateOnChange(pItem)
	GuestGroupCreateDateOnChangeAtServer();
	If ValueIsFilled(Object.Contract) Then
		vMessage = "";
		ContractOnChangeAtServer(, vMessage, True);
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		EndIf;
	EndIf;
	ThisForm.Modified = True;
EndProcedure // GuestGroupCreateDateOnChange

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
		ThisForm.Modified = True;
	Else
		pStandardProcessing = False;
		vText = TrimAll(pText);
		If StrLen(vText) > 2 Then
			vChoiceDataAddress = GetCustomersChoiceDataList(vText);
			pChoiceData = GetFromTempStorage(vChoiceDataAddress);
		EndIf;
		ThisForm.Modified = True;
	EndIf;
EndProcedure // CustomerAutoComplete

// -----------------------------------------------------------------------------
&AtClient
Procedure PlannedPaymentMethodOnChange(pItem)
	PlannedPaymentMethodOnChangeAtServer();
	ThisForm.Modified = True;
EndProcedure // PlannedPaymentMethodOnChange

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
	ThisForm.Modified = True;
EndProcedure // AgentCommissionOnChange

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
	ThisForm.Modified = True;
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
	ThisForm.Modified = True;
EndProcedure // KidAgeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(pItem)
	// Check rights to automatically open folios list after document write
	If pItem = Undefined Then
		If tcOnServer.cmCheckUserPermissionsAtServer("DoNotOpenFoliosListAfterAccommodationChange") Then
			Return;
		EndIf;
	EndIf;

	If (WasPosted = False Or ThisForm.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "OpenFolios"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vResult = WriteAtServer(, vWarning);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.TextMessage(vWarning);
		EndIf;		
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.TextMessage(vResult);
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
	vParametersStructure = New Structure("IsNew, WasPosted, IsFormModified, DocRef", IsNew, WasPosted, ThisForm.Modified, Object.Ref);
	OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), , Object.Ref);
EndProcedure // OpenFolios

// -----------------------------------------------------------------------------
&AtClient
Procedure NumberOfKidsOnChange(pItem)
	NumberOfKidsOnChangeAtServer();
	ThisForm.Modified = True;
EndProcedure // NumberOfKidsOnChange

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
			vNotifyDescription = New NotifyDescription("ContactPersonAfterChoice", ThisForm);
			vParams = New Structure("ValueList, MultipleChoice, Title", vCPList, False);
			OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
		EndIf;
	EndIf;
EndProcedure // ContactPersonStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RemarksStartChoice(pItem, pChoiceData, pStandardProcessing)
	vAmenitiesList = GetAmenitiesList(pItem.EditText, 1);
	vNotifyDescription = New NotifyDescription("AmenitiesAfterChoice", ThisForm, "Remarks");
	vParams = New Structure("ValueList, MultipleChoice, Title", vAmenitiesList, True, NStr("en='Choose amenities'; ru='Отметьте доп. удобства'; de='Wählen Sie Amenities'"));
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
EndProcedure // RemarksStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure HousekeepingRemarksStartChoice(pItem, pChoiceData, pStandardProcessing)
	vAmenitiesList = GetAmenitiesList(pItem.EditText, 2);
	vNotifyDescription = New NotifyDescription("AmenitiesAfterChoice", ThisForm, "HousekeepingRemarks");
	vParams = New Structure("ValueList, MultipleChoice, Title", vAmenitiesList, True, NStr("en='Choose amenities'; ru='Отметьте доп. удобства'; de='Wählen Sie Amenities'"));
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
EndProcedure // HousekeepingRemarksStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure IsClosedForEditOnChange(pItem)
	IsClosedForEditOnChangeAtServer();
EndProcedure // IsClosedForEditOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure NoPostOnChange(pItem)
	vQuery = NStr("en='Do change the <No external postings> flag for all group guests?'; ru='Изменить флаг <Запрет внешних начислений> для всех гостей группы?'; de='Ändern Sie das <Externe gebührenverbot> Flag für alle Gäste in der Gruppe?'");
	ShowQueryBox(New NotifyDescription("NoPostAfterAnswer", ThisForm), vQuery, QuestionDialogMode.YesNo, , DialogReturnCode.No);
EndProcedure // NoPostOnChange

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
Procedure IgnoreGroupChargingRulesOnChange(pItem)
	// Recalculate services	
	RecalculateServicesAtServer();
EndProcedure // IgnoreGroupChargingRulesOnChange

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
	ThisForm.Modified = True;
EndProcedure
 
// -----------------------------------------------------------------------------
&AtClient
Procedure RoomPriceOnChange(pItem)
	RoomPriceOnChangeAtServer();
	FillPriceChangeReason();
	ThisForm.Modified = True;
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
Procedure RoomTypeUpgradeOnChange(pItem)
	RoomTypeUpgradeOnChangeAtServer();
	FillPriceChangeReason();
EndProcedure // RoomTypeUpgradeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(pItem)
	DiscountTypeOnChangeAtServer();
	FillPriceChangeReason();
EndProcedure // DiscountTypeOnChange

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
	If (WasPosted = False Or ThisForm.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "OpenForeignerRegistryRecord"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vResult = WriteAtServer(, vWarning);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.TextMessage(vWarning);
		EndIf;		
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.TextMessage(vResult);
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
	OpenForeignerRegistryRecordForm(Object.Ref);
	For Each vRow In GuestsInGroup Do
		If ValueIsFilled(vRow.AccommodationType) Then
			OpenForeignerRegistryRecordForm(vRow.Ref);
		EndIf;
	EndDo;
	If Not ThisForm.Modified Then
		If ThisForm.IsOpen() Then
			ThisForm.Close();
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
	If ThisForm.Modified Then
		vMessage = CreateGuestItems();
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
			Return;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.CreditCard) Then
		OpenForm("Catalog.CreditCards.ObjectForm", New Structure("Key", Object.CreditCard), ThisForm, Object.CreditCard, , , , FormWindowOpeningMode.LockOwnerWindow);
	Else
	 	OpenForm("Catalog.CreditCards.ObjectForm", New Structure("FillingValues", New Structure("CardOwner", Object.Guest)), ThisForm);
	EndIf;
EndProcedure // CreditCardPresentationClick

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerOpening(pItem, pStandardProcessing)
	If Not ValueIsFilled(Object.Customer) Then
		If ThisForm.Modified Then
			vMessage = CreateGuestItems();
			If Not IsBlankString(vMessage) Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage);
				Return;
			EndIf;
		EndIf;
		CreateCustomerFromGuest();
		ThisForm.Modified = True;
	EndIf;
EndProcedure // CustomerOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestChangesDescriptionClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenExtraGuestOrdinaryApplicationForm(ThisForm.Commands.OpenExtraGuestOrdinaryApplicationForm);
EndProcedure // GuestChangesDescriptionClick

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeClassOnChange(pItem)
	If ValueIsFilled(Object.RoomRate) Then
		vRoomRatePriceTagType = tcOnServer.cmGetAttributeByRef(Object.RoomRate, "PriceTagType");
		If vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomType") Or 
		   vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomClass") Or 
		   vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType") Then
			Object.OccupationPercents.Clear();
		EndIf;
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
	ThisForm.Modified = True;
EndProcedure // RoomTypeClassOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeClassStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vKidsAgeArray = New Array;
	For i = 1 To NumberOfKids Do
		vKidsAgeArray.Add(ThisForm["KidAge"+i]);
	EndDo;
	vParams = New Structure("Hotel, RoomType, WindowView, CheckInDate, CheckOutDate, Duration, RoomRate, ClientType, RoomQuota, NumberOfAdults, NumberOfKids, AgeArray", 
	                         Object.Hotel, Object.RoomType, WindowView, Object.CheckInDate, Object.CheckOutDate, Object.Duration, Object.RoomRate, Object.ClientType, Object.RoomQuota, NumberOfAdults, NumberOfKids, vKidsAgeArray);
	vFrm = OpenForm("Catalog.RoomTypes.Form.mcChoiceForm", vParams, pItem, , GetMainWindow());
EndProcedure // RoomTypeClassStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomTypeClassChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	vOldRoomType = Object.RoomType;
	If TypeOf(pSelectedValue) = Type("Structure") Then
		If ValueIsFilled(pSelectedValue.CheckInDate) And 
		   ValueIsFilled(pSelectedValue.CheckOutDate) And 
		   pSelectedValue.CheckOutDate > pSelectedValue.CheckInDate Then
			Object.CheckInDate = pSelectedValue.CheckInDate;
			Object.CheckOutDate = pSelectedValue.CheckOutDate;
			Object.Duration = pSelectedValue.Duration;
		EndIf;
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
		If vOldRoomType <> Object.RoomType Then
			If ValueIsFilled(Object.RoomRate) Then
				vRoomRatePriceTagType = tcOnServer.cmGetAttributeByRef(Object.RoomRate, "PriceTagType");
				If vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomType") Or 
				   vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomClass") Or 
				   vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType") Then
					Object.OccupationPercents.Clear();
				EndIf;
			EndIf;
		EndIf;
		RoomTypeOnChangeAtServer(True, vClientTypeHasChanged);
		Object.RoomQuota = pSelectedValue.RoomQuota;
		If ValueIsFilled(Object.RoomQuota) Then
			RoomQuotaOnChangeAtServer(, True);
		EndIf;
		Object.RoomRate = pSelectedValue.RoomRate;
		RoomRateOnChangeAtServer();
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
		If vOldRoomType <> Object.RoomType Then
			If ValueIsFilled(Object.RoomRate) Then
				vRoomRatePriceTagType = tcOnServer.cmGetAttributeByRef(Object.RoomRate, "PriceTagType");
				If vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomType") Or 
				   vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomClass") Or 
				   vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType") Then
					Object.OccupationPercents.Clear();
				EndIf;
			EndIf;
		EndIf;
		RoomTypeOnChangeAtServer(True, False); 
	ElsIf TypeOf(pSelectedValue) = Type("CatalogRef.Rooms") Then
		tcOnClient.AskRoomChangeQuestion(pSelectedValue, Object);
		RoomChoiceProcessingAtServer(pSelectedValue);
	EndIf;
	vTypes = GetTypesArrayByRoomType(Object.RoomType);
	If ValueIsFilled(Object.AccommodationType) And vTypes.Count() > 0 Then
		If vTypes.Find(Object.AccommodationType) = Undefined Then
			Object.AccommodationType = Undefined;
		EndIf;
	EndIf;
	Items.AccommodationType.ChoiceList.LoadValues(vTypes);
	For Each vGRow In GuestsInGroup Do
		Items["AccommodationType" + Format(GuestsInGroup.IndexOf(vGRow) + 2, "NFD=0; NG=")].ChoiceList.LoadValues(vTypes);
	EndDo;
	ThisForm.Modified = True;
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
			   vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomClass") Or 
			   vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType") Then
				Object.OccupationPercents.Clear();
			EndIf;
		EndIf;
		RoomTypeOnChangeAtServer(True, False);
		vTypes = GetTypesArrayByRoomType(Object.RoomType);
		If ValueIsFilled(Object.AccommodationType) And vTypes.Count() > 0 Then
			If vTypes.Find(Object.AccommodationType) = Undefined Then
				Object.AccommodationType = Undefined;
			EndIf;
		EndIf;
		Items.AccommodationType.ChoiceList.LoadValues(vTypes);
		For Each vGRow In GuestsInGroup Do
			Items["AccommodationType" + Format(GuestsInGroup.IndexOf(vGRow) + 2, "NFD=0; NG=")].ChoiceList.LoadValues(vTypes);
		EndDo;
	EndIf;
	ThisForm.Modified = True;
EndProcedure // WindowViewOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BedsSetupStartChoice(pItem, pChoiceData, pChoiceByAdding, pStandardProcessing)
	Items.BedsSetup.ChoiceList.Clear();
	vBedsSetupList = GetBedsSetupList(Object.BedsSetup, Object.RoomType);
	For Each vBedsSetupListItem In vBedsSetupList Do
		Items.BedsSetup.ChoiceList.Add(vBedsSetupListItem.Value);
	EndDo;
EndProcedure // BedsSetupStartChoice

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
	vCreateDate = ?(ValueIsFilled(Object.GuestGroup), BegOfDay(tcOnServer.cmGetAttributeByRef(Object.GuestGroup, "CreateDate")), BegOfDay(Object.Date));
	vParams = New Structure("Filter, Hotel, ShowValidContractsOnly, PeriodFrom, PeriodTo, CreateDate", New Structure("Owner", Object.Customer), Object.Hotel, True, BegOfDay(Object.CheckInDate), '00010101', vCreateDate);
	OpenForm("Catalog.Contracts.ChoiceForm", vParams, pItem, Object.Ref, , , ,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // ContractStartChoice

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
			ClearOccupationPercents(vRowData.AccountingDate);
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
				tcCommonFunctionOnClientServer.TextMessage( NStr("en='Charge date should be inside reservation period!'; ru='Дата начисления должна быть внутри периода проживания!'; de='Datum sollte innerhalb der Reservierungsperiode sein!'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FixedChargesAccountingDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesChargingRuleOnChange(pItem)
	SetChargingRuleValueType();
EndProcedure // ChargingRulesChargingRuleOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure OrdersClick(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If IsBlankString(TOrders) Then
		vParam = New Structure();
		vParam.Insert("basis", Object.Ref);
		OpenForm("Document.Order.ObjectForm", vParam, ThisForm, True);	
	Else	
		vParam = New Structure;
		vParam.Insert("ParentDoc", Object.Ref);
		OpenForm("Document.Order.ListForm", vParam, ThisForm, True);
	EndIf;
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
	OpenForm("Catalog.ServicePackages.Form.tcChoiceFormWithPeriod", New Structure("Hotel, SelectedPackages, CheckInDate, CheckOutDate, MealBoardsAreUsed", Object.Hotel, vSelectedPackages, Object.CheckInDate, Object.CheckOutDate, Items.ServicePackage.Visible), ThisForm, Object.Ref, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // ServicePackagesStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackagesClearing(pItem, pStandardProcessing)
	ServicePackagesClearingAtServer(pStandardProcessing);
	vServicePackagesList = GetServicePackagesListAtServer(Items.ServicePackage.Visible);
	FillAmenitiesFromServicePackages(vServicePackagesList);
	RoomRateOnChangeAtServer();
	RefreshDataRepresentation();
EndProcedure // ServicePackagesClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceChangeReasonClick(pItem, pStandardProcessing)
	// Ask for price change reason
	pStandardProcessing = False;
	vParametersStructure = New Structure("Hotel, PriceChangeReason", Object.Hotel, Object.PriceChangeReason);
	vNotifyDescr = New NotifyDescription("AfterPriceChangeReasonSelection", ThisForm);
	vResultStructure = OpenForm("CommonForm.tcPriceChangeReasonSelection", New Structure("SettingStructure", vParametersStructure), ThisForm, , , , vNotifyDescr, FormWindowOpeningMode.LockWholeInterface);
EndProcedure // PriceChangeReasonClick

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductOnChange(pItem)
	HotelProductOnChangeAtServer();
EndProcedure // HotelProductOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelProductStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.HotelProducts.Form.tcListForm", New Structure("ChoiceMode, Hotel, RoomQuota, RoomType, CheckInDate", True, Object.Hotel, Undefined, Undefined, Undefined), pItem);
EndProcedure // HotelProductStartChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure ExtraGuestHotelProductOnChangeAtServer(pInd = "")
	vInd = Number(pInd) - 2;
	If vInd >= 0 Then
		// Update accommodation type in the guests in group value table
		vGuestsInGroup = FormAttributeToValue("GuestsInGroup");
		vGiGRow = vGuestsInGroup.Get(vInd);
		vGiGRow.HotelProduct = ThisForm["HotelProduct" + pInd];
		ValueToFormAttribute(vGuestsInGroup, "GuestsInGroup");
		// Get object value
		vObj = FormAttributeToValue("Object");
		// Calculate totals
		TotalSum = CalculateTotalServices(vObj);
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // ExtraGuestHotelProductOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestHotelProductOnChange(pItem)
	vInd = GetItemIndex(pItem.Name);
	If Not IsBlankString(vInd) Then
		ExtraGuestHotelProductOnChangeAtServer(vInd);
	EndIf;
	ThisForm.Modified = True;
EndProcedure // ExtraGuestHotelProductOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestHotelProductStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vInd = GetItemIndex(pItem.Name);
	If Not IsBlankString(vInd) Then
		OpenForm("Catalog.HotelProducts.Form.tcListForm", New Structure("ChoiceMode, Hotel, RoomQuota, RoomType, CheckInDate", True, Object.Hotel, Undefined, Undefined, Undefined), pItem);
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
			OpenForm("DataProcessor.PrintCouponSystemPrinter.Form.tcCouponPrintForm", New Structure("SelLanguage, SelObjList, RibbonPrinterConnectionParameters", vLanguage, vCouponsList, vRibbonPrinterConnection), ThisForm, ThisForm.UUID);
		ElsIf vDriverType = PredefinedValue("Enum.RibbonPrinterDrivers.Intermec") Then
			OpenForm("DataProcessor.IntermecRibbonPrinterDriver.Form.tcCouponPrintForm", New Structure("SelLanguage, SelObjList, RibbonPrinterConnectionParameters", vLanguage, vCouponsList, vRibbonPrinterConnection), ThisForm, ThisForm.UUID);	
		ElsIf vDriverType = PredefinedValue("Enum.RibbonPrinterDrivers.Atol") Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Данный принтер временно не поддерживается в тонком клиенте';en='This printer is temporarily not supported in the thin client';de='Dieser Drucker wird im Thin Client vorübergehend nicht unterstützt'"));	
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Nothing to print!';ru='Нет услуг для печати!';de='Es gibt keine Dienste für den Druck!'"));
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
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Room is not selected!'; ru='Не выбран номер!'; de='Keine Zimmer ausgewählt!'"));
		EndIf;
	EndIf;
	AttachIdleHandler("RecalculateTotalsOnClient", 0.1, True);
EndProcedure // RoomRatesOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesAfterDeleteRow(pItem)
	AttachIdleHandler("RecalculateTotalsOnClient", 0.1, True);
EndProcedure // RoomRatesAfterDeleteRow

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesOnChange(pItem)
	RecalculateServicesAtServer();
EndProcedure // ChargingRulesOnChange

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
				ShowQueryBox(New NotifyDescription("ResortFeeExemptAfterQuery", ThisForm), NStr("en='Add exempt from paying the resort fee to room other guests?'; ru='Освободить других гостей номера от уплаты курортного сбора?'; de='Lassen Zimmer andere Gäste die Kurtax nicht bezahlen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // AfterResortFeeExemptionChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure PriceCalculationDateOnChange(pItem)
	PriceCalculationDateOnChangeAtServer();
EndProcedure // PriceCalculationDateOnChange

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

// --------------------------------------------------------------------------------
&AtClient
Procedure ServicesVATRateOnChange(pItem)
	ServicesVATRateOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesVATRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicesCommissionSumOnChange(pItem)
	ServicesCommissionSumOnChangeAtServer(pItem.Parent.CurrentRow);
EndProcedure // ServicesCommissionSumOnChange

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
Procedure DiscountCardCreating(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.DiscountCards.ObjectForm", New Structure("FillingValues", New Structure("Client, Identifier", Object.Guest, pItem.EditText)), pItem, , , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // DiscountCardCreating

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationTemplateOnChange(pItem)
	AccommodationTemplateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRatesAccommodationTemplateOnChange(pItem)
	RoomRatesAccommodationTemplateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ContactPersonOnChange(pItem)
	ContactPersonOnChangeAtServer();
EndProcedure // ContactPersonOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyOnChange(pItem)
	CompanyOnChangeAtServer();
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
		If ValueIsFilled(ThisForm["HotelProduct"+vInd]) And tcOnServer.cmGetAttributeByRef(ThisForm["HotelProduct"+vInd], "IsFolder") Then
			pStandardProcessing = False;
			vFillingValues = New Structure("Parent, Code, Description, Hotel, RoomQuota, RoomType, Client, CheckInDate, Duration, CheckOutDate, PaymentMethod", 
			                               ThisForm["HotelProduct"+vInd], TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, ThisForm["Guest"+vInd], Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
			OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, ThisForm["Guest"+vInd]);
		ElsIf Not ValueIsFilled(ThisForm["HotelProduct"+vInd]) Then
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
			                               vParent, TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, ThisForm["Guest"+vInd], Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
			OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, ThisForm["Guest"+vInd]);
		EndIf;
	EndIf;
EndProcedure // ExtraGuestHotelProductOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure ExtraGuestHotelProductCreating(pItem, pStandardProcessing)
	vInd = GetItemIndex(pItem.Name);
	If Not IsBlankString(vInd) Then
		If ValueIsFilled(ThisForm["HotelProduct"+vInd]) And tcOnServer.cmGetAttributeByRef(ThisForm["HotelProduct"+vInd], "IsFolder") Then
			pStandardProcessing = False;
			vFillingValues = New Structure("Parent, Code, Description, Hotel, RoomQuota, RoomType, Client, CheckInDate, Duration, CheckOutDate, PaymentMethod", 
			                               ThisForm["HotelProduct"+vInd], TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, ThisForm["Guest"+vInd], Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
			OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, ThisForm["Guest"+vInd]);
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
			                               vParent, TrimAll(pItem.EditText), TrimAll(pItem.EditText), Object.Hotel, Object.RoomQuota, Object.RoomType, ThisForm["Guest"+vInd], Object.CheckInDate, Object.Duration, Object.CheckOutDate, Object.PlannedPaymentMethod);
			OpenForm("Catalog.HotelProducts.ObjectForm", New Structure("FillingValues", vFillingValues), pItem, ThisForm["Guest"+vInd]);
		EndIf;
	EndIf;
EndProcedure // ExtraGuestHotelProductCreating

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesOnStartEdit(pItem, pNewRow, pClone)
	vCurRow = Items.ChargingRules.CurrentData;
	If vCurRow <> Undefined Then
		If Not pClone Then
			If Not ValueIsFilled(vCurRow.ChargingRule) Then
				vCurRow.ChargingRule = PredefinedValue("Enum.ChargingRuleTypes.InRate");
			EndIf;
			If Not ValueIsFilled(vCurRow.ChargingFolio) Then
				vFolioDataStruct = New Structure("Hotel, Company, GuestGroup, Room, Client, DateTimeFrom, DateTimeTo, ParentDoc, LineNumber", Object.Hotel, Object.Company, Object.GuestGroup, Object.Room, Object.Guest, Object.CheckInDate, Object.CheckOutDate, Object.Ref, vCurRow.LineNumber);
				vCurRow.ChargingFolio = GetNewDocumentFolioAtServer(vFolioDataStruct);
			EndIf;
			SetChargingRuleValueType();
		EndIf;
	EndIf;
EndProcedure // ChargingRulesOnStartEdit

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesChargingFolioOpening(pItem, pStandardProcessing)
	vCurRow = Items.ChargingRules.CurrentData;
	If vCurRow <> Undefined Then
		If Not ValueIsFilled(vCurRow.ChargingFolio) Then
			pStandardProcessing = False;
			vFolioDataStruct = New Structure("Hotel, Company, GuestGroup, Room, Client, DateTimeFrom, DateTimeTo, ParentDoc, LineNumber", Object.Hotel, Object.Company, Object.GuestGroup, Object.Room, Object.Guest, Object.CheckInDate, Object.CheckOutDate, Object.Ref, vCurRow.LineNumber);
			vCurRow.ChargingFolio = GetNewDocumentFolioAtServer(vFolioDataStruct);
		EndIf;
	EndIf;
EndProcedure // ChargingRulesChargingFolioOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesChargingFolioCreating(pItem, pStandardProcessing)
	vCurRow = Items.ChargingRules.CurrentData;
	If vCurRow <> Undefined Then
		pStandardProcessing = False;
		vFolioDataStruct = New Structure("Hotel, Company, GuestGroup, Room, Client, DateTimeFrom, DateTimeTo, ParentDoc, LineNumber", Object.Hotel, Object.Company, Object.GuestGroup, Object.Room, Object.Guest, Object.CheckInDate, Object.CheckOutDate, Object.Ref, vCurRow.LineNumber);
		vCurRow.ChargingFolio = GetNewDocumentFolioAtServer(vFolioDataStruct);
	EndIf;
EndProcedure // ChargingRulesChargingFolioCreating

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesOwnerOnChange(pItem)
	vCurRow = Items.ChargingRules.CurrentData;
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.Owner) Then
			If TypeOf(vCurRow.Owner) = Type("DocumentRef.Reservation") Or TypeOf(vCurRow.Owner) = Type("DocumentRef.Accommodation") Then
				vCurRow.ChargingFolio = GetFolioFromReservation(vCurRow.Owner);
				vCurRow.IsTransfer = True;
			ElsIf TypeOf(vCurRow.Owner) = Type("DocumentRef.ResourceReservation") Then
				vCurRow.ChargingFolio = GetFolioFromResourceReservation(vCurRow.Owner);
				vCurRow.IsTransfer = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ChargingRulesOwnerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesChargingFolioOnChange(pItem)
	vCurRow = Items.ChargingRules.CurrentData;
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.ChargingFolio) Then
			vIsTransfer = vCurRow.IsTransfer;
			vCurRow.Owner = GetChargingRuleOwnerByFolioAtServer(Object.Ref, vCurRow.ChargingFolio, vIsTransfer);
			vCurRow.IsTransfer = vIsTransfer;
		EndIf;
	EndIf;
EndProcedure // ChargingRulesChargingFolioOnChange

#EndRegion

#Region FormCommandsEventHandlers

 // -----------------------------------------------------------------------------
&AtClient
Procedure CreateGroupProformaInvoice(pCommand)
	If (WasPosted = False Or ThisForm.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "CreateGroupProformaInvoice"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vResult = WriteAtServer(, vWarning);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.TextMessage(vWarning);
		EndIf;		
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.TextMessage(NStr(vResult));
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
	vForm = GetForm("Document.ProformaInvoice.ObjectForm");
	vFormData = vForm.Object;
	NewGroupProformaInvoice(vFormData,True);
	CopyFormData(vFormData, vForm.Object);
	vForm.Open();
EndProcedure // CreateGroupProformaInvoice

// -----------------------------------------------------------------------------
&AtClient
Procedure Post(pCommand)
	If ThisForm.ReadOnly Then
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
		OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "Write"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf;
	EmployeePINCodeChecked = False;
	// Do write procedure
	vWarning = "";
	vResult = WriteAtServer(, vWarning, True);
	If Not IsBlankString(vWarning) Then
		tcCommonFunctionOnClientServer.TextMessage(vWarning);
	EndIf;		
	If ValueIsFilled(vResult) And vResult <> "Error" Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
	ElsIf Not ValueIsFilled(vResult) Then
		vWriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
		AfterWriteAtServer(Undefined, vWriteParameters);
		// Notify changes
		Notify("Subsystem.Accounts.Changed", Object.Ref, ThisForm);
		Notify("Document.Accommodation.Write", Object.Ref, Undefined);
		If GuestsToCheckInList.Count()>0 Then
			Notify("CheckIn", Object.Ref, ThisForm);
		EndIf;
		Items.FormOpenBlockForm.Enabled = True;
		Items.FormCheckOut.Enabled = True;
		If ThisForm.IsNew Then
			ThisForm.IsNew = False;
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Documents posting error!';ru='Ошибка проводки документа!';de='Fehler bei der Durchführung des Dokuments!'"));
	EndIf;
EndProcedure // Post

// -----------------------------------------------------------------------------
&AtClient
Procedure PostAndClose(pCommand)
	If ThisForm.ReadOnly Then
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
		OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "WriteAndClose"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
		Return;
	EndIf;
	EmployeePINCodeChecked = False;
	// Do write procedure
	vWasModified = ThisForm.Modified Or WasNew;
	vWarning = "";
	vResult = WriteAtServer(, vWarning);
	If Not IsBlankString(vWarning) Then
		If ValueIsFilled(vResult) Then
			tcCommonFunctionOnClientServer.TextMessage(vWarning);
		Else
			tcCommonFunctionOnClientServer.TextMessage(vWarning);
		EndIf;
	EndIf;		
	If ValueIsFilled(vResult) And vResult <> "Error" Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
	ElsIf Not ValueIsFilled(vResult) Then
		IsOnCloseForm = True;
		// Notify changes in the accounts subsystem
		Notify("Subsystem.Accounts.Changed", Object.Ref, ThisForm);
		Notify("Document.Accommodation.Write", Object.Ref, ThisForm);
		// Open folios list
		If vWasModified Then
			OpenFolios(Undefined);
		EndIf;
		If GuestsToCheckInList.Count()>0 Then
			Notify("CheckIn", Object.Ref, ThisForm);
		EndIf;
		Close();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Documents posting error!';ru='Ошибка проводки документа!';de='Fehler bei der Durchführung des Dokuments!'"));
	EndIf;
EndProcedure // PostAndClose

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInHouseGuests(pCommand)
	OpenForm("Document.Accommodation.Form.mcAccommodationListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisForm);	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenInvoicesList(pCommand)
	vFrm = GetForm("Document.Settlement.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisForm);
	vFrm.SelGuestGroup = Object.GuestGroup;
	vFrm.Open();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenProformaInvoicesList(pCommand)
	vFrm = GetForm("Document.ProformaInvoice.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisForm);
	vFrm.SelGuestGroup = Object.GuestGroup;
	vFrm.Open();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenReservations(pCommand)
	OpenForm("Document.Reservation.Form.mcReservationListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisForm);	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenChangeHistory(pCommand)
	If ThisForm.IsNew Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Документ должен быть записан!';
		                  |de='Das Dokument muss aufgezeichnet sein!'; 
		                  |en='Please write document first!'"));
		Return;
	EndIf;
	vFrm = OpenForm("InformationRegister.AccommodationChangeHistory.ListForm", New Structure("Accommodation", Object.Ref), ThisForm, Object.Ref);
	vFrm.ReadOnly = ThisForm.ReadOnly;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenOrdinaryApplicationForm(pCommand)
	If ThisForm.IsNew Or ThisForm.Modified Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	Else
		ThisForm.UnlockFormDataForEdit();
	EndIf;
	OpenForm("Document.Accommodation.ObjectForm", New Structure("Key, OneGuestMode, IsForFolioSplit", Object.Ref, True, Object.IsForFolioSplit), ThisForm, tcOnServer.GetStringUUIDByRef(Object.Ref));
EndProcedure // OpenOrdinaryApplicationForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenBlockForm(pCommand)
	If ThisForm.IsNew Or ThisForm.Modified Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	Else
		ThisForm.UnlockFormDataForEdit();
	EndIf;
EndProcedure // OpenBlockForm

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckOut(pCommand)
	If (WasPosted = False Or ThisForm.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "CheckOut"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vResult = WriteAtServer(, vWarning);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.TextMessage(vWarning);
		EndIf;		
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.TextMessage(vResult);
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
		OpenForm("CommonForm.tcChangeRoomWizard", New Structure("DocRef, OperationType", Object.Ref, 2), ThisForm);
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
			Endif;
			i = i - 1;
		EndDo;
	EndIf;
	AccList.Add(Object.Ref);
	// *** CURRENT DOCUMENT ***
	// Check if document is posted
	If IsNew Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Процедура выселения не возможна для не проведенного размещения!';
		                      |de='Das Ausweisungsverfahren ist für nicht durchgeführte Unterbringungen nicht möglich!'; 
		                      |en='Check out procedure is not possible for the accommodation that is not posted!'"));
		Return;
	EndIf;
	// Check document form state. If document is open for read only then do 
	// message and cancel action
	If ThisForm.ReadOnly Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Action choosen is not permitted from the document opened for read only!';
		                      |ru='Действие не разрешено из документа открытого на просмотр!';
		                      |de='Die Aktion ist aus dem zur Ansicht geöffneten Dokument nicht erlaubt!'"));
		Return;
	EndIf;
	// Give warning if current date is less then expected check-out date
	If BegOfDay(Object.CheckOutDate) > BegOfDay(CurrentDate()) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Expected check-out date " + Format(Object.CheckOutDate, "DF=dd.MM.yyyy") + " is in the future!'; 
		             |de='Expected check-out date " + Format(Object.CheckOutDate, "DF=dd.MM.yyyy") + " is in the future!'; 
		             |ru='Дата планируемого выезда " + Format(Object.CheckOutDate, "DF=dd.MM.yyyy") + " в будущем!'"), MessageStatus.Important);
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
Procedure ScanDocuments(pCommand)
	If (WasPosted = False Or ThisForm.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "ScanDocuments"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vResult = WriteAtServer(, vWarning);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.TextMessage(vWarning);
		EndIf;		
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.TextMessage(vResult);
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
	vScanRef = GetClientDataScanDocument(Object.Ref);
	If ValueIsFilled(vScanRef) Then
		OpenForm("Document.ClientDataScans.ObjectForm", New Structure("Key, Guest, ParentDoc, GuestGroup, Room", vScanRef, Object.Guest, Object.Ref, Object.GuestGroup, Object.Room), ThisForm, Object.Ref);
	Else
		OpenForm("Document.ClientDataScans.ObjectForm", New Structure("basis", Object.Ref), ThisForm, Object.Ref);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Pay(pCommand)
	If (WasPosted = False Or ThisForm.Modified) Then
		// Check attributes
		If Not CheckAttributes() Then
			Return;
		EndIf;
		// Check user PIN if necessary
		If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
			OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "Pay"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
			Return;
		EndIf;
		EmployeePINCodeChecked = False;
		// Save document first
		vWarning = "";
		vResult = WriteAtServer(, vWarning);
		If Not IsBlankString(vWarning) Then
			tcCommonFunctionOnClientServer.TextMessage(vWarning);
		EndIf;		
		If ValueIsFilled(vResult) Then
			If vResult <> "Error" Then
				tcCommonFunctionOnClientServer.TextMessage(vResult);
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
		OpenForm("Document.Payment.ObjectForm", New Structure("Basis", vFolio), ThisForm);
	EndIf;
EndProcedure // Pay

// -----------------------------------------------------------------------------
&AtClient
Procedure Task(pCommand)
	stParam = New Structure("SetParamObject", Object.Ref);
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure // Task

// -----------------------------------------------------------------------------
&AtClient
Procedure SendWelcomeSMS(pCommand)
	vMessage = SendWelcomeSMSAtServer();
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndIf;
EndProcedure // SendWelcomeSMS

// -----------------------------------------------------------------------------
&AtClient
Procedure FillAccommodation(pCommand)
	// Save document first
	If ThisForm.Modified Then
		Post(pCommand);
		ThisForm.Modified = False;
		ThisForm.UnlockFormDataForEdit();
	EndIf;
	// Create form for the new accommodation
	OpenForm("Document.Accommodation.Form.tcDocumentForm", New Structure("ParentAccommodation", Object.Ref), , New UUID);
	// Close this document
	ThisForm.Close();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NewOrder(pCommand)
	If ValueIsFilled(Object.Ref) Then
		vParam = New Structure();
		vParam.Insert("basis", Object.Ref);
		OpenForm("Document.Order.ObjectForm", vParam, ThisForm, True);	
	EndIf;
EndProcedure // NewOrder

// -----------------------------------------------------------------------------
&AtClient
Procedure FuncButtonClick(pCommand)
	If ThisForm.IsNew Or ThisForm.Modified Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	
	vActionsNumber = StrReplace(pCommand.Name,"Func","");
	vAction = GetActionForNumber(vActionsNumber);
	
	If Not ValueIsFilled(vAction.ExternalProcessing) Then
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
		ElsIf vAction.PredefinedDataName = "AccommodationChangeRoom" Then
			AccommodationChangeRoom();
		ElsIf vAction.PredefinedDataName = "AccommodationFillInvoice" Then
			vParam = New Structure;
			vParam.Insert("ParentDoc", Object.Ref);
			OpenForm("Document.ProformaInvoice.Form.tcDocumentForm",vParam,ThisForm,True);	
		ElsIf vAction.PredefinedDataName = "AccommodationFillOrder" Then
			vParam = New Structure;
			vParam.Insert("basis",Object.Ref);
			OpenForm("Document.Order.Form.DocumentForm",vParam,ThisForm,True);
		// Run data processor
		ElsIf ValueIsFilled(vAction.DataProcessor) Then
			vReturnParameter = New Structure("Action, Data");
			If Not RunDataProcessor(vAction.DataProcessor, Object.Ref, True, vReturnParameter) Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to run data processor!';ru='Не удалось выполнить обработку!';de='Die Bearbeitung ist fehlgeschlagen!'"));
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
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='No data processor found for action!';ru='У действия не указан обработчик!';de='Bei der Aktion ist kein Bearbeiter angegeben!'"));
		EndIf;
	EndIf;   
EndProcedure

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
&AtClient
Procedure PrintButtonClick(pCommand)
	If ThisForm.IsNew Or ThisForm.Modified Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	
	vPrintNumber = StrReplace(pCommand.Name,"Print","");
	vPrintForm = GetPrintFormForNumber(vPrintNumber);
	
	// Load external print form
	If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
		Try
			OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
		EndTry;
	ElsIf ValueIsFilled(vPrintForm.Report) Then
		Try
			OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref);
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
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
Procedure ClearResortFeeExemption(pCommand)
	ClearResortFeeExemptionAtServer();
	// Ask user should we clear exempt from paying the resort fee from other room guests 
	If Not OneGuestMode Then
		ShowQueryBox(New NotifyDescription("ResortFeeExemptAfterQuery", ThisForm), NStr("en='Clear exempt from paying the resort fee from room other guests?'; ru='Отменить освобождение от уплаты курортного сбора у других гостей номера?'; de='Stornieren die Befreiung von der Zahlung einer Kurtax von Zimmer anderen Gäste?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
	EndIf;
EndProcedure // ClearResortFeeExemption

// -----------------------------------------------------------------------------
&AtClient
Procedure AddResortFeeExemption(pCommand)
	vList = tcOnClient.cmGetResortFeeExemptionReasonsList();
	vNotifyDescription = New NotifyDescription("AfterResortFeeExemptionChoice", ThisForm);
	vParams = New Structure("ValueList, MultipleChoice, Title", vList, False, NStr("en='Choose reason'; ru='Выберите причину'; de='Wählen Sie den Grund'"));
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
EndProcedure // AddResortFeeExemption

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeRoomWizard(pCommand)
	If Object.Ref.IsEmpty() Or ThisForm.Modified Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Документ должен быть записан!';
		                      |de='Das Dokument muss aufgezeichnet sein!'; 
		                      |en='Please write document first!'"));
		Return;
	EndIf;
	OpenForm("CommonForm.tcChangeRoomWizard",New Structure("DocRef,GuestTable",Object.Ref,GuestsInGroup),ThisForm);
EndProcedure // ChangeRoomWizard

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenResourceReservations(pCommand)
	vFrm = GetForm("Document.ResourceReservation.ListForm", New Structure("SelGuestGroup", Object.GuestGroup), ThisForm);
	vFrm.Open();
EndProcedure // OpenResourceReservations

// -----------------------------------------------------------------------------
&AtClient
Procedure NewTask(pCommand)
	If ValueIsFilled(Object.Ref) Then
		stParam = New Structure("SetParamObject, Type", Object.Ref, PredefinedValue("Enum.MessageTypes.Task"));
		OpenForm("Document.Message.Form.tcDocumentForm", stParam);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionCancel(pCommand)
	vCurRow = Items.RoomInterfaces.CurrentRow;
	If vCurRow <> Undefined Then
		If tcOnServer.cmGetAttributeByRef(vCurRow,"DeletionMark") Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Room interface is marked for deletion and could not be used!';ru='Доп. услуга помечена на удаление и не может быть отключена!';de='Zusätzliche Dienstleistung wurde zum Löschen markiert und kann nicht abgeschaltet werden!'"));
		ElsIf tcOnServer.cmGetAttributeByRef(vCurRow,"IsCanceled") Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Room interface is already cancelled!';ru='Доп. услуга уже отключена!';de='Zusätzliche Dienstleistung wurde bereits abgeschaltet!'"));
		ElsIf ValueIsFilled(tcOnServer.cmGetAttributeByRef(vCurRow,"RoomInterfaceType")) And tcOnServer.cmGetAttributeByRef(vCurRow,"RoomInterfaceType.ManualCancelIsForbidden") Then
			vMessage = NStr("en='Manual interface cancellation is forbidden!';ru='Ручное отключение услуги запрещено!';de='Das manuelle Abschalten des Dienstes ist verboten!'");
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(vCurRow,"RoomInterfaceType.RefusalReason")) Then
				vMessage = vMessage + Chars.LF + Chars.LF + tcOnServer.cmNStrAtServer(TrimAll(vCurRow.RoomInterfaceType.RefusalReason));
			EndIf;
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
		Else
			ActionCancelAtServer(vCurRow);
		EndIf;
	EndIf;
EndProcedure // ActionCancel

// -----------------------------------------------------------------------------
&AtClient
Procedure InsertServicePackage(pCommand)
	If Not ValueIsFilled(Object.CheckInDate) Or Not ValueIsFilled(Object.CheckOutDate) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Reservation period should be specified!';ru='Период планируемого проживания должен быть указан!';de='Der Zeitraum der geplanten Unterbringung muss angegeben sein!'"));
		Return;
	EndIf;
	// Open package choice form
	OpenForm("Catalog.ServicePackages.ChoiceForm", New Structure("SelPeriodFrom, SelPeriodTo", Object.CheckInDate, Object.CheckOutDate), ThisForm, Object.Ref);
EndProcedure // InsertServicePackage

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionInsert(pCommand)
	OpenForm("Document.RoomInterfaceStatus.ObjectForm", New Structure("Basis", ?(ValueIsFilled(Object.Ref), Object.Ref, Object.Room)), ThisForm, Object.Ref);
EndProcedure // ActionInsert

// -----------------------------------------------------------------------------
&AtClient
Procedure LoadDefaultChargingRules(pCommand)
	LoadDefaultChargingRulesAtServer();
EndProcedure // LoadDefaultChargingRules

// -----------------------------------------------------------------------------
&AtClient
Procedure RecalculateServices(pCommand)
	RecalculateServicesAtServer();
	ThisForm.Modified = True;
EndProcedure // RecalculateServices

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintGroupSettlement(pCommand)
	If ThisForm.Modified Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
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
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	Else
		If vResult = 0 Then
			vInvList = GetListOfGroupInvoices(Object.GuestGroup);
			If vInvList.Count() = 0 Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage);
			ElsIf vInvList.Count() = 1 Then
				vInvoice = vInvList.Get(0).Value;
			Else
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
&AtClient
Procedure CreateGroupSettlement(pCommand)
	If ThisForm.Modified Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	// Get list of all group invoices
	vInvoicesList = GetGroupInvoices(Object.GuestGroup);
	// Open new invoice form
	vFrm = OpenForm("Document.Settlement.ObjectForm", New Structure("Basis, ParentDoc, HasOfficialLetter", Object.GuestGroup, Object.Ref, Object.HasOfficialLetter), ThisForm, Object.GuestGroup);
	If vFrm.Object.Services.Count() = 0 Then
		If vInvoicesList.Count() > 0 Then
			// Invoice was already created
			vFrm.Close();
			// Show existing invoices
			If vInvoicesList.Count() = 1 Then
				vInvItem = vInvoicesList.Get(0);
				OpenForm("Document.Settlement.ObjectForm", New Structure("Key", vInvItem.Value), ThisForm, vInvItem.Value);
				vMessage = NStr("en='No data for the new invoice was found! Existing invoice was opened'; 
				                |ru='Нет данных для нового акта! Открылся существующий акт'; 
				                |de='Für die neue Rechnung wurden keine Daten gefunden! Bestehende Rechnung geöffnet'");
				tcCommonFunctionOnClientServer.TextMessage(vMessage);
			Else
				vMessage = NStr("en='No data for the new invoice was found! Please choose invoice from the list of existing invoices'; 
				                |ru='Нет данных для нового акта! Выберите один из существующих актов'; 
				                |de='Für die neue Rechnung wurden keine Daten gefunden! Wählen Sie eine der vorhandenen Rechnungen'");
				vNotifyDescription = New NotifyDescription("GroupInvoiceSelection", ThisForm);
				vParams = New Structure("ValueList, MultipleChoice, Title", vInvoicesList, False, vMessage);
				OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CreateGroupSettlement

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExtraGuestOrdinaryApplicationForm(pCommand)
	If ThisForm.IsNew Or ThisForm.Modified Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	vDocRef = GetGuestDocumentRefByItemID(ThisForm.CurrentItem.Name);
	If Not ValueIsFilled(vDocRef) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	OpenForm("Document.Accommodation.ObjectForm", New Structure("Key, OneGuestMode, IsForFolioSplit", vDocRef, True, tcOnServer.cmGetAttributeByRef(vDocRef, "IsForFolioSplit")), ThisForm, tcOnServer.GetStringUUIDByRef(vDocRef));
EndProcedure // OpenExtraGuestOrdinaryApplicationForm

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearExtraGuestChanges(pCommand)
	If ThisForm.IsNew Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
		Return;
	EndIf;
	vDocRef = GetGuestDocumentRefByItemID(ThisForm.CurrentItem.Name);
	If Not ValueIsFilled(vDocRef) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Save changes first!'; ru='Сначала сохраните изменения!'; de='Speichern Sie die Änderungen zuerst!'"));
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
			ThisForm["GuestChangesDescription" + String(vInd)] = vGiGRow.ChangesDescription;
			vCDItem = Items["Guest" + String(vInd) + "ChangesGroup"];
			vCDItem.Visible = False;
			Break;
		EndIf;
	EndDo;
EndProcedure // ClearExtraGuestChanges

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearServicesManualChanges(pCommand)
	ClearServicesManualChangesAtServer();
	RecalculateServicesAtServer();
	ManualServicesPriceAppearance();
	ThisForm.Modified = True;
EndProcedure // ClearServicesManualChanges

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearCreditCard(pCommand)
	Object.CreditCard = Undefined;
	CreditCardPresentation = NStr("en='<Credit card>'; ru='<Кредитная карта>'; de='<Kreditkarte>'");
	Items.ClearCreditCard.Visible = False;
	ThisForm.Modified = True;
EndProcedure // ClearCreditCard

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowDirectPostings(pCommand)
	If Object.Ref.IsEmpty() Or ThisForm.Modified Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Документ должен быть записан!';
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
EndProcedure // CheckOutReversal

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowClosedTasks(pCommand)
	stParam = New Structure("SetParamObject, ShowClosedMessages", Object.Ref, True);
	OpenForm("DataProcessor.Messages.Form.tcForm", stParam);
	Notify("DataProcessor.Messages.Form.Open", stParam);
EndProcedure // ShowClosedTasks

// -----------------------------------------------------------------------------
&AtClient
Procedure FillGrid(pCommand)
    If Object.ref.IsEmpty() Or ThisForm.Modified Then
        Items.GroupDecorationMessage.Visible = True;
        DecorationTotalSumClickAtServer();
    Else	
        Items.GroupDecorationMessage.Visible = False;
	    FillGridAtServer();
    EndIf; 
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AddPhone2(pCommand)
	Items.Fax.Visible = True;
	Items.AddPhone2.Visible = False;
EndProcedure

#EndRegion

#Region Internal

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
&AtClient
Procedure ClearOccupationPercents(pDate = Undefined)
	If ValueIsFilled(Object.RoomRate) Then
		vRoomRatePriceTagType = tcOnServer.cmGetAttributeByRef(Object.RoomRate, "PriceTagType");
		If (vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomType") Or 
		    vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomClass") Or 
		    vRoomRatePriceTagType = PredefinedValue("Enum.PriceTagTypes.ByOccupancyPercentPerRoomTypePerDayType")) And 
		   Not tcOnServer.cmGetAttributeByRef(Object.RoomRate, "DoNotRefillOccupationPercentsAfterInHouseRoomChange") Then
			If pDate = Undefined Then
				Object.OccupationPercents.Clear();
			Else
				vNum = 0;
				While vNum < Object.OccupationPercents.Count() Do
					vOccupationPercentsRow = Object.OccupationPercents.Get(vNum);
					If vOccupationPercentsRow.AccountingDate >= BegOfDay(pDate) Then
						Object.OccupationPercents.Delete(vNum);
					Else
						vNum = vNum + 1;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ClearOccupationPercents

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
	TotalSum = CalculateTotalServices();
	// Build status group hidden title
	BuildStatusGroupCollapsedTitle(vObj);
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	// Refill status choice list
	FillAccommodationStatusListChoice();
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
	TotalSum = CalculateTotalServices();
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
	TotalSum = CalculateTotalServices();
EndProcedure // AgentCommissionServiceGroupOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomPropertiesPresentation()
	// Room properties
	vRPPresentation = "";
	For Each vRPItem In ThisForm.RoomProperties Do
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
	For Each vRP In ThisForm.RoomProperties Do
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
	If ThisForm.RoomProperties.Count() > 0 Then
		ThisForm.RoomProperties.Clear();
	EndIf;
	If pRoomPropertiesList.Count() > 0 Then
		For Each vRPItem In pRoomPropertiesList Do
			If vRPItem.Check Then
				ThisForm.RoomProperties.Add(vRPItem.Value);
			EndIf;
		EndDo;
	EndIf;
EndProcedure // SaveRoomPropertiesList

// -----------------------------------------------------------------------------
&AtServer
Function FillDocumentRoomProperties()
	Object.RoomProperties.Clear();
	For Each vRoomPropertiesItem In ThisForm.RoomProperties Do
		vRoomPropertiesRow = Object.RoomProperties.Add();
		vRoomPropertiesRow.RoomProperty = vRoomPropertiesItem.Value;
	EndDo;
EndFunction // FillDocumentRoomProperties

&AtClient
Procedure RoomPropertiesPresentationStartChoice_AfterInput(pValue, pParametrs) Export
	
	If pValue <> Undefined Then
		SaveRoomPropertiesList(pValue);
	EndIf;
	
	// Fill presentation
	ThisForm.RoomPropertiesPresentation = GetRoomPropertiesPresentation();
	// Save room properties to the document object
	FillDocumentRoomProperties();
	// Parameters group presentation
	BuildThisFormClientDataDecoration()
	
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
	TotalSum = CalculateTotalServices();
	// Mark this form as changed
	ThisForm.Modified = True;
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
	TotalSum = CalculateTotalServices();
	// Mark this form as changed
	ThisForm.Modified = True;
EndProcedure // CheckOutTimeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInTimeAfterChoice(pDayTime, pExtraParams) Export
	If pDayTime <> Undefined Then
		CheckInTime = pDayTime.Value;
		CheckInTimeOnChangeAtServer();
	EndIf;
	ThisForm.Modified = True;
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
	ThisForm.Modified = True;
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
		vGuestGroupObj.Description = TrimAll(ThisForm.GuestGroupDescription);
		vGuestGroupObj.Write();
	Else
		ThisForm.GuestGroupDescription = "";
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
		If ValueIsFilled(ThisForm.GuestGroupCreateDate) Then
			vGuestGroupObj = vObj.GuestGroup.GetObject();
			vGuestGroupObj.CreateDate = ThisForm.GuestGroupCreateDate;
			vGuestGroupObj.Write();
		Else
			ThisForm.GuestGroupCreateDate = vObj.GuestGroup.CreateDate;
		EndIf;
	Else
		ThisForm.GuestGroupCreateDate = '00010101';
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
		vGuestGroupObj.ID = TrimAll(ThisForm.GuestGroupID);
		vGuestGroupObj.Write();
	Else
		ThisForm.GuestGroupID = "";
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
	TotalSum = CalculateTotalServices();
	// Mark this form as changed
	ThisForm.Modified = True;
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
		vChoiceDataList.Add(vQryResult.Ref, vQryResult.Presentation);
	EndDo;
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
		ThisForm.Modified = True;
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
	vURL = GetURL(pExtProcRef, "ExternalProcessingStorage"); 
	vName = ConnectExternalDataProcessor(vURL, GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(pExtProcRef,"FileName")));
	vParams = New Structure("InputParameter, ObjectPrintingForm, OneGuestMode", Object.Ref, pPrintFormTypeRef, OneGuestMode);
    vFrm = GetForm("ExternalDataProcessor." + vName + ".Form", vParams);
	vFrm.Open();
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
	vURL = GetURL(tcOnServer.cmGetAttributeByRef(pExtRepRef,"Report"), "ExternalProcessingStorage"); 
	vName = ConnectExternalReport(vURL, "ExternalReportForm");
	vParams = New Structure("Document, ObjectPrintingForm, OneGuestMode", Object.Ref, pPrintFormTypeRef, OneGuestMode);
	OpenForm("ExternalReport." + vName + ".Form", vParams);
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
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("Document, GuestGroup, ObjectPrintingForm", vDocument, Undefined, vObjPrtForm), ThisForm, Object.Ref);
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
	vFrm = OpenForm("Document.Accommodation.Form.tcPrintGuestForm", New Structure("Document, GuestGroup, ObjectPrintingForm", vDocument, Object.GuestGroup, vObjPrtForm), ThisForm, Object.Ref);
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
	OpenForm("Document.Accommodation.Form.tcAccommodationPrintForm", vParams, ThisForm, new UUID);
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
	OpenForm("Document.Accommodation.Form.tcAccommodationPrintForm", vParams, ThisForm, new UUID);
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
	vFrm = OpenForm("Report.PrintGuestDepartureForm.Form.tcPrintGuestForm", New Structure("InputParameter, ObjectPrintingForm, OneGuestMode", vDocument, vObjPrtForm, OneGuestMode), ThisForm, Object.Ref);
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
	Return pRef.FullName;
EndFunction // GetClientFullName

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomChoiceProcessingAtServer(pRoom, pObj = Undefined)
	// Check paramters
	vUseParameterObject = True;
	vObj = pObj;
	If pObj = Undefined Then
		// Get object value
		vObj = FormAttributeToValue("Object");
		vUseParameterObject = False;
	EndIf;
	vObj.Room = pRoom;
	vRefillTypesArray = False;
	If pRoom.RoomType <> vObj.RoomType Then
		vRefillTypesArray = True;
	EndIf;
	RoomOnChangeAtServer(True, vObj);
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
EndProcedure // RoomChoiceProcessingAtServer

// -------------------------------------------------------------------------
&AtClient
Function GetMainWindow()
	vWindows = GetWindows();
	vMainWindow = Undefined;
	For Each vWindow In vWindows Do
		If vWindow.IsMain Then
			vMainWindow = vWindow;
			Break;
		EndIf;
	EndDo;
	Return vMainWindow;
EndFunction // GetMainWindow

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
					ThisForm["Guest" + String(vGuestsInGroup.IndexOf(vGuest) + 2)] = vGuestObj.Ref;
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
Function WriteAtServer(pCurrentObject = Undefined, rWarning = "", pDoNotCloseMode = False) Export
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
					ThisForm.CurrentItem = Items.RoomType;
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
			ThisForm.CurrentItem = Items.AccommodationType;
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
			ThisForm.CurrentItem = Items.RoomType;
			vMessage = NStr("en='The field is not filled: Room type';ru='Не заполнено поле: Тип номера';de='Das Feld ist nicht ausgefullt: Zimmertyp'");
			Return vMessage;
		EndIf;
		// Do UndoPosting of all one room documents
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
		vCurrObj.RoomRates.Sort("AccountingDate Asc");
		// Save guest age if it is possible
		If NumberOfAdults = 0 And NumberOfKids > 0 Then
			vCurrObj.GuestAge = ThisForm["KidAge1"];
			If ValueIsFilled(vCurrObj.Guest) Then
				vCurrObj.GuestCitizenship = vCurrObj.Guest.Citizenship;
			EndIf;				
		ElsIf Not OneGuestMode Then
			vCurrObj.GuestAge = 0;
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
		vCurrObj.Write(DocumentWriteMode.Posting);
		// Save data to the document history
		vCurrObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		// Write to user work history
		UserWorkHistory.Add(vCurrObj.Ref);
		// Fill warning
		If Not IsBlankString(vCurrObj.AdditionalProperties.WarningMessage) Then
			rWarning = rWarning + ?(IsBlankString(rWarning), "", Chars.LF) + cmNStr(vCurrObj.AdditionalProperties.WarningMessage);
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
		vNum = 0;
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
					If vCurrObj.IsForFolioSplit And ValueIsFilled(vCurrObj.GuestGroup) And Not vCurrObj.GuestGroup.OneCustomerPerGuestGroup Then
						FillPropertyValues(vObject, vCurrObj, , "Date, Author, AccommodationStatus, Guest, AccommodationType, GuestFullName, Car, Remarks, HousekeepingRemarks, SortCode, ExternalCode, ParentDoc, Reservation, IsByReservation, Phone, EMail, Fax, CreditCard, ClientType, HotelProduct, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants, RoomPropertiesDescriptions, RoomPropertiesCodes, AccommodationTemplate, PriceCalculationDate, ServicePackage, Customer, Contract, Company, Agent, TouristicTaxExemptionReason, TouristicTaxExemptionReasonFillDate, TouristicTaxExemptionConfirmationData" + ?(vRow.IsForFolioSplitIsDifferent, ", IsForFolioSplit", ""));
					Else
						FillPropertyValues(vObject, vCurrObj, , "Date, Author, AccommodationStatus, Guest, AccommodationType, GuestFullName, Car, Remarks, HousekeepingRemarks, SortCode, ExternalCode, ParentDoc, Reservation, IsByReservation, Phone, EMail, Fax, CreditCard, ClientType, HotelProduct, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants, RoomPropertiesDescriptions, RoomPropertiesCodes, AccommodationTemplate, PriceCalculationDate, ServicePackage, TouristicTaxExemptionReason, TouristicTaxExemptionReasonFillDate, TouristicTaxExemptionConfirmationData" + ?(vRow.IsForFolioSplitIsDifferent, ", IsForFolioSplit", ""));
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
						i = 0;
						While i < vCRTransfers.Count() Do
							vCRTransfersRow = vCRTransfers.Get(i);
							vCRRowFolio = vCRTransfersRow.ChargingFolio;
							If ValueIsFilled(vCRRowFolio) Then
								If ValueIsFilled(vCRRowFolio.ParentDoc) And TrimAll(vCRRowFolio.ParentDoc.Number) = TrimAll(vObject.Number) Then
									vCRTransfers.Delete(i);
									Continue;
								EndIf;
							EndIf;
							i = i + 1;
						EndDo;
						// Try to remove transfer rules to main room guest
						If vObject.IsForFolioSplit And Not vObjectRef.IsForFolioSplit Then
							i = 0;
							While i < vObject.ChargingRules.Count() Do
								vCRTransfersRow = vObject.ChargingRules.Get(i);
								If vCRTransfersRow.IsTransfer Then
									vCRRowFolio = vCRTransfersRow.ChargingFolio;
									If ValueIsFilled(vCRRowFolio) Then
										If ValueIsFilled(vCRRowFolio.ParentDoc) And TrimAll(vCRRowFolio.ParentDoc.Number) = TrimAll(vObject.Number) Then
											vObject.ChargingRules.Delete(i);
											Continue;
										EndIf;
									EndIf;
								EndIf;
								i = i + 1;
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
					vObject = Documents.Accommodation.CreateDocument();
					vAttributesToCopyFromReservation = "";
					If GuestsToCheckInList.Count() > 0 And vNum < (GuestsToCheckInList.Count() - 1) Then
						vObjectReservation = GuestsToCheckInList[vNum+1].Value;
						If ValueIsFilled(vObjectReservation) Then
							vObject.Fill(vObjectReservation);
							vAttributesToCopyFromReservation = ", RoomRate, TouristicTaxExemptionReason, TouristicTaxExemptionReasonFillDate, TouristicTaxExemptionConfirmationData, IsForFolioSplit";
						EndIf;
					EndIf;
					If vCurrObj.IsForFolioSplit And ValueIsFilled(vCurrObj.GuestGroup) And Not vCurrObj.GuestGroup.OneCustomerPerGuestGroup Then
						FillPropertyValues(vObject, vCurrObj, , "Date, Author, Guest, AccommodationType, GuestFullName, Car, Remarks, HousekeepingRemarks, SortCode, ExternalCode, ParentDoc, Reservation, IsByReservation, Phone, EMail, Fax, CreditCard, ClientType, HotelProduct, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants, RoomPropertiesDescriptions, RoomPropertiesCodes, AccommodationTemplate, PriceCalculationDate, ServicePackage, Customer, Contract, Company, Agent" + vAttributesToCopyFromReservation);
					Else
						FillPropertyValues(vObject, vCurrObj, , "Date, Author, Guest, AccommodationType, GuestFullName, Car, Remarks, HousekeepingRemarks, SortCode, ExternalCode, ParentDoc, Reservation, IsByReservation, Phone, EMail, Fax, CreditCard, ClientType, HotelProduct, NumberOfAdults, NumberOfTeenagers, NumberOfChildren, NumberOfInfants, RoomPropertiesDescriptions, RoomPropertiesCodes, AccommodationTemplate, PriceCalculationDate, ServicePackage" + vAttributesToCopyFromReservation);
					EndIf;
					If Not IsNew And BegOfDay(vCurrObj.CheckInDate) < BegOfDay(CurrentSessionDate()) And BegOfDay(CurrentSessionDate()) < BegOfDay(vCurrObj.CheckOutDate) Then
						vObject.CheckInDate = cm1SecondShift(CurrentSessionDate());
						vObject.Duration = vObject.pmCalculateDuration();
					EndIf;
					vObject.pmFillAuthorAndDate();
					vObject.Car = "";
					vObject.Remarks = "";
					vObject.HousekeepingRemarks = "";
					If Not (GuestsToCheckInList.Count() > 0 And vNum < (GuestsToCheckInList.Count() - 1)) Then
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
						vCurGuestAge = ThisForm["KidAge" + String(vCurKidIndex)];
					EndIf;
					vObject.GuestAge = vCurGuestAge;
					vObject.GuestCitizenship = vRow.GuestCitizenship;
					vObject.AccommodationType = vRow.AccommodationType;
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
					// Occupation percents
					If vObject.IsNew() Or Not vCurrObj.IsForFolioSplit Then
						vObject.OccupationPercents.Load(vCurrObj.OccupationPercents.Unload());
					EndIf;
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
					If vObject.IsNew() Or Not vCurrObj.IsForFolioSplit Then
						If IsManualRoomPrice = 3 Then
							CopyPrices(vObject.Prices, vCurrObj.Prices);
						ElsIf IsManualRoomPrice = 1 Then
							CopyPrices(vObject.Prices, vCurrObj.Prices, 0);
						Else
							If vObject.AccommodationType = vCurrObj.AccommodationType Then
								CopyPrices(vObject.Prices, vCurrObj.Prices);
							Else
								CopyPrices(vObject.Prices);
							EndIf;
						EndIf;
					ElsIf vCurrObj.IsForFolioSplit And Not vRow.ManualPricesAreDifferent Then
						If IsManualRoomPrice = 3 Then
							CopyPrices(vObject.Prices, vCurrObj.Prices);
						ElsIf IsManualRoomPrice = 1 Then
							CopyPrices(vObject.Prices, vCurrObj.Prices, 0);
						EndIf;
					EndIf;
					// Resort fee 2018
					If vRow.IsNoResortFee Then
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
					// Calculate services
					vObject.pmCalculateServices( , , , , , vObject.IsForFolioSplit, , ?(OneGuestMode, Undefined, vCurrObj.AccommodationTemplate));
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
					vObject.Write(DocumentWriteMode.Posting);
					// Save data to the document history
					vObject.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
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
				EndIf;
			ElsIf ValueIsFilled(vRow.Ref) And vRow.Ref.Posted And vRow.IsAnnulation	And ValueIsFilled(vRow.AccommodationStatus) Then
				vObjectRef = vRow.Ref;
				vObject = vObjectRef.GetObject();
				vObject.AccommodationStatus = vRow.AccommodationStatus;
				// Posting
				vObject.AdditionalProperties.Insert("DoNotCloseMode", pDoNotCloseMode);
				vObject.Write(DocumentWriteMode.Posting);
				// Save data to the document history
				vObject.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
			vNum = vNum + 1;
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
	If ThisForm.Modified Then
		ThisForm.Modified = False;
		NeedServicesRecalculation = False;
	EndIf;
	If Not vUseParametrObject Then
		// Set object value 
		vCurrObj.Read();
		ValueToFormAttribute(vCurrObj, "Object");
	EndIf;
	// Hotel365
	vFrmAction = Catalogs.ObjectFormActions.AccommodationSendWelcomeSMS;
	If Not WasPosted And vFrmAction.IsActive And vFrmAction.AutomaticallyRunOnFirstObjectWrite And vFrmAction.ObjectType = Documents.Accommodation.EmptyRef() Then
		vSMSWarning = SendWelcomeSMSAtServer();
		rWarning = rWarning + ?(IsBlankString(rWarning), "", Chars.LF) + vSMSWarning;
	EndIf;
	// Was posted
	WasPosted = True;
	// Calculate totals
	If pDoNotCloseMode Then
		TotalSum = CalculateTotalServices(, False, False, False, True);
	EndIf;
	Return "";
EndFunction // WriteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose_AfterAnswering(pAnswer, pCancel) Export
	pCancel = False;
	vCancel = Undefined;
	If pAnswer <> Undefined Then
		If pAnswer = DialogReturnCode.Yes Then
			// Check user PIN if necessary
			If Not EmployeePINCodeChecked And tcOnServer.NeedToCheckEmployeePINCode() Then
				OpenForm("CommonForm.tcEmployeePINCheck", New Structure("ModeAfterCheck", "BeforeClose_AfterAnswering"), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
				Return;
			EndIf;
			EmployeePINCodeChecked = False;
			// Save document
			vWarning = "";
			vResult = WriteAtServer(, vWarning, True);
			If Not IsBlankString(vWarning) Then
				If ValueIsFilled(vResult) Then
					tcCommonFunctionOnClientServer.TextMessage(vWarning);
				Else
					tcCommonFunctionOnClientServer.TextMessage(vWarning);
				EndIf;
			EndIf;		
			If ValueIsFilled(vResult) Then
				If vResult <> "Error" Then
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Documents posting error! ';ru='Ошибка проводки документа! ';de='Fehler bei der Durchführung des Dokuments! '") + vResult);
				Else
					tcCommonFunctionOnClientServer.TextMessage(NStr("en='Documents posting error!';ru='Ошибка проводки документа!';de='Fehler bei der Durchführung des Dokuments!'"));
				EndIf;
				pCancel = True;
				IsInBeforeCloseEvent = False;
				Return;
			Else
				// Notify changes
				IsOnCloseForm = True;
				Notify("Subsystem.Accounts.Changed", Object.Ref, ThisForm);
				Notify("Document.Accommodation.Write", Object.Ref, ThisForm);
				If GuestsToCheckInList.Count()>0 Then
					Notify("CheckIn", Object.Ref, ThisForm);
				EndIf;
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
		ThisForm.Modified = False;
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
							tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
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
			ThisForm.Close();
		EndIf;
	Else
		If vCancel <> "LockError" Then
			pCancel = True;
		Else
			If IsInBeforeCloseEvent Then
				If ThisForm.IsOpen() Then
					ThisForm.Modified = False;
					ThisForm.Close();
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
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to run report!';ru='Не удалось выполнить отчет!';de='Der Bericht konnte nicht ausgeführt werden!'"));
		EndIf;
	Else        
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='No print form processor found!';ru='В настройках печатной формы не задан обработчик!';de='In den Einstellungen der Druckunterlagen wurde kein Bearbeiter vorgegeben!'"));
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
	vCancel = CheckAttributesAtServer();
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
	BuildThisFormClientDataDecoration();
	// Build commission group hidden title
	BuildCommissionGroupCollapsedTitle();
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle();
	// Build room rate group hidden title
	BuildRoomRateGroupCollapsedTitle();
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle();
	Return vCancel;
EndFunction // CheckAttributesAtServer

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
Procedure DoFormReadOnly()
	ThisForm.ReadOnly = True;
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
	Endif;
	// Save object back to form
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
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
		// Calculate totals
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
	
	If ThisForm.ReadOnly Then
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
		Items.NumberOfAdultsKids.Visible = False;
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
		            |	&qEmptyString AS ChangesDescription
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
					ThisForm["KidAge1"] = vKidAge;
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
				vGiGRow.ChangesDescription = TrimAll(vGiGRow.ChangesDescription) + ?(IsBlankString(vGiGRow.ChangesDescription), "", ", ") + NStr("en='Changes plan differs'; ru='План изм. отличается'; de='Änderungsplan ist anders'");
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
			If ValueIsFilled(vHotel) And (vHotel.TeenagersMaxAge <> 0 Or vHotel.ChildrenMaxAge <> 0 Or vHotel.InfantsMaxAge <> 0) Then
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
					ThisForm["KidAge"+String(NumberOfKids)] = vKidAge;
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
					ThisForm.Modified = True;
				EndIf;
				If ValueIsFilled(vLastAccommodationType) And vLastAccommodationType <> vObj.AccommodationType Then
					vObj.AccommodationType = vLastAccommodationType;
					vAccommodationTypeWasChanged = True;
					ThisForm.Modified = True;
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
			ThisForm.Modified = True;
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
			vNum = 0;
			For Each vGuestItem In GuestsToCheckInList Do
				vGuestItemValue = vGuestItem.Value;
				// Lock reservation
				LockDataForEdit(vGuestItemValue, , ThisForm.UUID);
				// Process reservations
				If vNum = 0 Then
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
					ThisForm.RoomProperties = GetRoomPropertiesValueList(vObj);
				Else
					vNewRow = GuestsInGroup.Add();
					vNewRow.Guest = vGuestItemValue.Guest.FullName;
					vNewRow.AccommodationType = vGuestItemValue.AccommodationType;
					vNewRow.GuestRef = vGuestItemValue.Guest;
					vNewRow.IsGuest = True;
					vNewRow.HotelProduct = vGuestItemValue.HotelProduct;
					vNewRow.GuestAge = vGuestItemValue.GuestAge;
				EndIf;
				vNum = vNum + 1;
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
				   (vAccType.AllowedClientAgeTo = 0 Or vAccType.AllowedClientAgeTo >= 18) Then
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
							ThisForm["KidAge"+String(NumberOfKids)] = vKidAge;
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
				vNewGuest.Guest = vDocIndRef.GuestName;
				vNewGuest.GuestRef= vDocIndRef.GuestRef;
				vNewGuest.IsAnnulation = False;
				vNewGuest.IsGuest = True;
				vNewGuest.HotelProduct = vDocIndRef.HotelProduct;
				
				If ValueIsFilled(vDocIndRef.DateOfBirth) Then
					vAge = GetClientAge( , vObj.CheckInDate, vDocIndRef.DateOfBirth);
					If vAge <> 0 And vAge<18 Then
						NumberOfKids = NumberOfKids + 1;
						Try
							Items["KidAge"+String(NumberOfKids)].Visible = True;
							ThisForm["KidAge"+String(NumberOfKids)] = vAge;
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
		ThisForm["GuestChangesDescription" + String(vInd)] = vGiGRow.ChangesDescription;
		vCDItem = Items["Guest" + String(vInd) + "ChangesGroup"];
		If Not IsBlankString(vGiGRow.ChangesDescription) Then
			vCDItem.Visible = True;
		Else
			vCDItem.Visible = False;
		EndIf;
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
					ChangeRoomMessageText = ChangeRoomMessageText + Chars.LF + vMessageText;
				EndIf;
			EndIf;
		EndDo;
		If IsBlankString(ChangeRoomMessageText) Then
			If ValueIsFilled(vObj.Reservation) Then
				vReservation = vObj.Reservation;
				If vReservation.RoomType <> vObj.RoomType And ValueIsFilled(vReservation.RoomType) And ValueIsFilled(vObj.RoomType) Then
					ChangeRoomMessageText = ChangeRoomMessageText + Chars.LF + NStr("en='Upsell '; ru='Ап-селл '; de='Upsell '") + TrimAll(vReservation.RoomType.Code) + " -> " + TrimAll(vObj.RoomType.Code);
					vChangeRoomMessageTextColor = WebColors.Blue;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vObj.RoomTypeUpgrade) And vObj.RoomType <> vObj.RoomTypeUpgrade Then
			ChangeRoomMessageText = ChangeRoomMessageText + ?(IsBlankString(ChangeRoomMessageText), "", ", ") + NStr("en='Prices by '; ru='Цены по '; de='Preise nach '") + TrimAll(vObj.RoomTypeUpgrade.Code);
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
					tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Все начисления размещения уже закрыты актами об оказании услуг! Редактирование такого размещения запрещено.';en='All accommodation charges are closed by invoices! Accommodation will be opened read only.';de='Alle Übernachtungskosten werden durch Rechnungen geschlossen! Die Unterkunft ist nur lesbar.'"));
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
	ThisForm.RoomPropertiesPresentation = GetRoomPropertiesPresentation();

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
		Items.ServicePackage.Visible = True;
		Items.ServicePackage.ChoiceList.LoadValues(GetMealBoardTermsList(Object.Hotel, Object.Contract).UnloadValues());
	Else
		Items.ServicePackage.Visible = False;
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
	Else
		Items.FormCheckOutReversal.Visible = False;
		Items.FormCheckOutReversal.Enabled = False;
	EndIf;
	
	// Build form caption
	BuildThisFormCaption();
	
	// Build remarks group hidden title
	BuildThisFormRemarksDataDecoration();
	
	// Build client's decoration
	BuildThisFormClientDataDecoration();
	
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
Procedure BuildThisFormClientDataDecoration(pObj = Undefined)
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
	
	Items.GroupProperties.CollapsedRepresentationTitle = NStr("en='Client type: ';ru='Тип клиента: ';de='Kundetyp: '") + ?(ValueIsFilled(vObj.ClientType), TrimAll(vObj.ClientType), NStr("en='<empty>';ru='<пусто>';de='<leer>'")) + 
	                                                     " • " + NStr("en='Marketing: ';ru='Маркетинг: ';de='Marketing: '") + ?(ValueIsFilled(vObj.MarketingCode), TrimAll(vObj.MarketingCode), NStr("en='<empty>';ru='<пусто>';de='<leer>'")) +  
	                                                     " • " + NStr("en='Trip purpose: ';ru='Цель визита: ';de='Ziel des Besuchs: '") + ?(ValueIsFilled(vObj.TripPurpose), TrimAll(vObj.TripPurpose), NStr("en='<empty>';ru='<пусто>';de='<leer>'")) + 
														 ?(ValueIsFilled(vObj.BedsSetup), " • " + NStr("en='Beds: ';ru='Кровати: ';de='Betten: '") + vObj.BedsSetup, "") + 
														 ?(Not IsBlankString(vRoomProperties), " • " + NStr("en='Room properties: ';ru='Свойства номера: ';de='Zimmer Eigenschaften: '") + vRoomProperties, "");
EndProcedure // BuildThisFormClientDataDecoration

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
Function GetTasksStructure(pDocRef)
	vTasksStructure = New Structure();
	If ValueIsFilled(pDocRef) Then
		vTasks = cmGetMessagesForObject(pDocRef);
		vNumber = 0;
		For Each vTasksRow In vTasks Do
			vTasksStructure.Insert(TrimAll("Tasks" + vNumber), New Structure("PopUp, Remarks, ReservationTaskArea", vTasksRow.PopUp, vTasksRow.Remarks, vTasksRow.ReservationTaskArea));
			vNumber = vNumber + 1;
		EndDo;
	EndIf;
	Return vTasksStructure;
EndFunction // GetTasksStructure

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

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure FillTypesTableOnClient()
	FillTypesTableAtServer();
EndProcedure // FillTypesTableOnClient

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
					  vCustFieldsRow.ValueType = cmGetCatalogTypeDescription("Regions") Then
					vField.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInDropList;
					vField.CreateButton = False;
					vField.ClearButton = True;
					vField.OpenButton = True;
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
			ThisForm[TrimAll(vCustFieldsValuesRow.CharacteristicCode)] = vCustFieldsValuesRow.CharacteristicValue;
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
		vRcdMgr.CharacteristicValue = ThisForm[CustomFieldsListItem.Presentation];
		vRcdMgr.Write(True);
	EndDo;
EndProcedure // SaveCustomFields

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
	ThisForm.Modified = True;
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
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не выбрана гостиница!';de='Kein Hotel ist gewählt!';en='Hotel is not filled!'"));
	EndIf;
	ThisForm.Modified = True;
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
		vNum = 0;
		While vNum < vObj.ChargingRules.Count() Do
			vCRRow = vObj.ChargingRules.Get(vNum);
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
						vCRRow.Owner = Undefined;
					EndIf;
				EndIf;
				If Not vBaseRuleIsFound Then
					vObj.ChargingRules.Delete(vNum);
				Else
					vNum = vNum + 1;
				EndIf;
			Else
				vNum = vNum + 1;
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
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не выбрана гостиница!';de='Kein Hotel ist gewählt!';en='Hotel is not filled!'"));
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
		DiscountDescription = DiscountDescription + NStr("en='Payer: ';ru='Плательщик: ';de='Zahler: '") + TrimAll(vObj.PayerAccommodation.Room) + ", " + TrimAll(vObj.PayerAccommodation.Guest) + Chars.LF;
	Else
		If Not IsBlankString(TPayer) Then
			DiscountDescription = DiscountDescription + NStr("en='Payer: ';ru='Плательщик: ';de='Zahler: '") + TPayer + Chars.LF;
		EndIf;
	EndIf;
	If vObj.IsByReservation Then
		vReservation = vObj.pmGetParentReservation();
		If ValueIsFilled(vReservation) Then
			DiscountDescription = DiscountDescription + NStr("en='By reservation N ';ru='По брони № ';de='Nach Reservierung Nr. '") + TrimAll(vReservation.Number) + " (" + Format(vReservation.Date, "DF=dd.MM.yyyy") + ")" + Chars.LF;
		EndIf;
	EndIf;
	If vObj.Discount <> 0 Then
		If IsBlankString(vObj.DiscountConfirmationText) Then
			If ValueIsFilled(vObj.DiscountType) Then
				DiscountDescription = DiscountDescription + NStr("en='Discount ';ru='Скидка ';de='Preisnachlass '") + Format(vObj.Discount, "ND=10; NFD=2; NZ=; NG=") + "% - " + TrimAll(vObj.DiscountType) + Chars.LF;
			Else
				DiscountDescription = DiscountDescription + NStr("en='Discount ';ru='Скидка ';de='Preisnachlass '") + Format(vObj.Discount, "ND=10; NFD=2; NZ=; NG=") + "% - " + NStr("en='Manual discount';ru='Ручная скидка';de='Manueller Preisnachlass'") + Chars.LF;
			EndIf;
		Else
			DiscountDescription = DiscountDescription + NStr("en='Discount ';ru='Скидка ';de='Preisnachlass '") + Format(vObj.Discount, "ND=10; NFD=2; NZ=; NG=") + "% - " + TrimAll(vObj.DiscountConfirmationText) + Chars.LF;
		EndIf;
	ElsIf vObj.DiscountSum <> 0 Then
		If IsBlankString(vObj.DiscountConfirmationText) Then
			DiscountDescription = DiscountDescription + NStr("en='Discount is ';ru='Скидка на ';de='Preisnachlass auf '") + Format(vObj.DiscountSum, "ND=17; NFD=2; NZ=") + " - " + TrimAll(vObj.DiscountType) + Chars.LF;
		Else
			DiscountDescription = DiscountDescription + NStr("en='Discount is ';ru='Скидка на ';de='Preisnachlass auf '") + Format(vObj.DiscountSum, "ND=17; NFD=2; NZ=") + " - " + TrimAll(vObj.DiscountConfirmationText) + Chars.LF;
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
	vNum = 0;
	While vNum < pTargetPrices.Count() Do
		vTgtPricesRow = pTargetPrices.Get(vNum);
		vTgtPricesSrv = vTgtPricesRow.Service;
		If ValueIsFilled(vTgtPricesSrv) And 
		   ValueIsFilled(vTgtPricesSrv.QuantityCalculationRule) And 
		   (vTgtPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 Or 
		    vTgtPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO Or 
		    vTgtPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022) Then
			vNum = vNum + 1;
		Else
			pTargetPrices.Delete(vNum);
		EndIf;
	EndDo;
	// Add source prices
	If pSourcePrices <> Undefined Then
		vNum = 0;
		While vNum < pSourcePrices.Count() Do
			vSrcPricesRow = pSourcePrices.Get(vNum);
			vSrcPricesSrv = vSrcPricesRow.Service;
			If ValueIsFilled(vSrcPricesSrv) And 
			   ValueIsFilled(vSrcPricesSrv.QuantityCalculationRule) And 
			   (vSrcPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018 Or 
			    vSrcPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2018CO Or 
			    vSrcPricesSrv.QuantityCalculationRule.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.ResortFeeRu2022) Then
				vNum = vNum + 1;
			Else
				vTgtPricesRow = pTargetPrices.Add();
				FillPropertyValues(vTgtPricesRow, vSrcPricesRow);
				If pRoomRatePrice <> Undefined Then
					vTgtPricesRow.Price = Number(pRoomRatePrice);
				EndIf;
				vNum = vNum + 1;
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
	vFirstRow = vAccTypesTable.Add();
	vFirstRow.AccommodationType = vObj.AccommodationType;
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
				vCurGuestAge = ThisForm["KidAge" + String(vCurKidIndex)];
			EndIf;
			vRow.GuestAge = vCurGuestAge;
		EndIf;
	EndDo;
	vAccTypesTable.Sort("Ref");
	vMainSrvTable = New ValueTable;
	vMainSrvTable.Columns.Add("Service");
	vMainSrvTable.Columns.Add("AccountingDate");
	vMainSrvTable.Columns.Add("FolioCurrency");
	vMainSrvTable.Columns.Add("IsInPrice");
	vMainSrvTable.Columns.Add("Quantity");
	vMainSrvTable.Columns.Add("Sum");
	vMainSrvTable.Columns.Add("DiscountSum");
	vMainSrvTable.Columns.Add("CommissionSum");
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
					vSrvObj.GuestAge = vAccType.GuestAge;
				EndIf;
				If vRecalculateServices Then
					vWarnings = "";
					vSrvObj.pmCalculateServices(vWarnings, , , , , vSrvObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
					If TypeOf(vObj) = Type("FormDataStructure") Then
						If ThisForm.Modified Then
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
					EndIf;
					vSrvObj.FixReservationConditions = vObj.FixReservationConditions;
					vSrvObj.RoomType = vObj.RoomType;
					vSrvObj.RoomTypeUpgrade = vObj.RoomTypeUpgrade;
					vSrvObj.AccommodationType = vAccType.AccommodationType;
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
					If Not vAccType.ManualPricesAreDifferent Then
						If IsManualRoomPrice = 3 Then
							CopyPrices(vSrvObj.Prices, vObj.Prices);
						ElsIf IsManualRoomPrice = 1 Then
							CopyPrices(vSrvObj.Prices, vObj.Prices, 0);
						Else
							If ValueIsFilled(vAccType.AccommodationType) And (vAccType.AccommodationType.Type = Enums.AccomodationTypes.Beds OR vAccType.AccommodationType.Type = Enums.AccomodationTypes.Room) Then
								CopyPrices(vSrvObj.Prices, vObj.Prices);
							Else
								CopyPrices(vSrvObj.Prices);
							EndIf;
						EndIf;
					EndIf;
					// Resort fee 2018
					If vAccType.IsNoResortFee Then
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
				vSrvObj = Documents.Accommodation.CreateDocument();
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
					CopyPrices(vSrvObj.Prices, vObj.Prices, 0);
				Else
					If ValueIsFilled(vAccType.AccommodationType) And (vAccType.AccommodationType.Type = Enums.AccomodationTypes.Beds OR vAccType.AccommodationType.Type = Enums.AccomodationTypes.Room) Then
						CopyPrices(vSrvObj.Prices, vObj.Prices);
					Else
						CopyPrices(vSrvObj.Prices);
					EndIf;
				EndIf;
				// Resort fee 2018
				If vAccType.IsNoResortFee Then
					ProcessResortFee(vSrvObj.Prices, vObj.Prices);
				EndIf;
				// Fill room rates
				vSrvObj.RoomRates.Load(vObj.RoomRates.Unload());
				For Each vSrvObjRoomRatesRow In vSrvObj.RoomRates Do
					vSrvObjRoomRatesRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef();
					vSrvObjRoomRatesRow.AccommodationTemplate = Catalogs.AccommodationTemplates.EmptyRef();
				EndDo;
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
			If vSrvObj.GuestAge <> vAccType.GuestAge Then
				vSrvObj.GuestAge = vAccType.GuestAge;
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
		// Calculate total amount
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
			If vRFTotalArray.Count()=0 Then
				vRFTotalArray.Add(tcOnServer.cmFormattedSumTitle(NStr("en='Resort fee: '; ru='Кур. сбор: '; de='Kurtaxe: '"), True));
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
		vTotalStr = New FormattedString(vFTotalArray);
		// Fill resort fee amount presentation
		vRFTotalArray = New Array;
		For Each vRFTotal In vResortFeeTable Do
			If vRFTotalArray.Count()=0 Then
				vRFTotalArray.Add(tcOnServer.cmFormattedSumTitle(NStr("en='Resort fee: '; ru='Кур. сбор: '; de='Kurtaxe: '"), True));
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
					tcCommonFunctionOnClientServer.TextMessage(vMessage);
				EndIf;
				// Load customer contact persons list
				LoadCustomerContactPersonsList(vObj);
				// Set object value
				If vUseParameterObject = False Then
					ValueToFormAttribute(vObj, "Object");
					// Calculate totals
					TotalSum = CalculateTotalServices(, , False, False);
					// Rebuild remarks panel header
					BuildThisFormRemarksDataDecoration();
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
			tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
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
	BuildThisFormClientDataDecoration(vObj);
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
	EndIf;                            
	// Calculate totals
	TotalSum = CalculateTotalServices(, , False, False);
	// Rebuild remarks panel header
	BuildThisFormRemarksDataDecoration();
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
			Items.ServicePackage.ChoiceList.LoadValues(GetMealBoardTermsList(vObj.Hotel, vContract).UnloadValues());
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
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Planned payment method has changed!';ru='Изменился планируемый способ оплаты!';de='Die geplante Zahlungsmethode hat sich geändert!'"));
	EndIf;
	// Refresh analitical parameters
	BuildThisFormClientDataDecoration(vObj);
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
		TotalSum = CalculateTotalServices(vObj);
	EndIf;
	If vObj.Posted And BegOfDay(CurrentSessionDate()) >= BegOfDay(vObj.CheckInDate) And 
	   ValueIsFilled(vObj.AccommodationStatus) And vObj.AccommodationStatus.IsInHouse Then
		// Do change room
		DoChangeRoom(vObj);
	EndIf;
	If vUseParameterObject = False Then		
		// Set object value
		ValueToFormAttribute(vObj, "Object");
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
			BuildThisFormClientDataDecoration(vObj);
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
		TotalSum = CalculateTotalServices(vObj);
	EndIf;
	If vObj.Posted And BegOfDay(CurrentSessionDate()) >= BegOfDay(vObj.CheckInDate) And 
	   ValueIsFilled(vObj.AccommodationStatus) And vObj.AccommodationStatus.IsInHouse Then
		// Do change room
		DoChangeRoom(vObj);
	EndIf;
	// Build accounting group hidden title
	BuildAccountingGroupCollapsedTitle(vObj);
	// Build discounts group hidden title
	BuildDiscountsGroupCollapsedTitle(vObj);
	// Set object value
	If vUseParameterObject = False Then	
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // RoomTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckOutDateOnChangeAtServer(pObj = Undefined) Export
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
				vUM = New UserMessage();
				vUM.SetData(vObj);
				vUM.Field = vAttrInError;
				vUM.Text = vOverAllotmentMessage;
				vUM.Message();
			EndIf;
		EndIf;
	EndIf;
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
	// Calculate totals
	TotalSum = CalculateTotalServices();
EndProcedure // CheckOutDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckInDateOnChangeAtServer(pObj = Undefined) Export
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
	// Update price calculation date
	vObj.pmUpdatePriceCalculationDate();
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
	// Calculate totals
	TotalSum = CalculateTotalServices();
EndProcedure // CheckInDateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure DurationOnChangeAtServer(pObj = Undefined)
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
	// Update price calculation date
	vObj.pmUpdatePriceCalculationDate();
	// Extract check-out time
	CheckOutTime = cmExtractTime(vObj.CheckOutDate);
	// Read foreigner registry documents
	ReadForeignerRegistryDocuments(vObj);
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
	// Calculate totals
	TotalSum = CalculateTotalServices();
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
				Items.ServicePackage.ChoiceList.LoadValues(GetMealBoardTermsList(vObj.Hotel, vObj.Contract).UnloadValues());
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
			TotalSum = CalculateTotalServices(vObj);
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
			tcCommonFunctionOnClientServer.TextMessage(TrimR(vObj.Agent.Remarks));
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
	TotalSum = CalculateTotalServices();
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
	ThisForm.Modified = True;
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
		// Room properties
		If vObj.Guest.RoomProperties.Count() > 0 Then
			vObj.RoomProperties.Load(vObj.Guest.RoomProperties.Unload());
			ThisForm.RoomProperties = GetRoomPropertiesValueList(vObj);
			ThisForm.RoomPropertiesPresentation = GetRoomPropertiesPresentation();
			BuildThisFormClientDataDecoration();
		EndIf;
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
	TotalSum = CalculateTotalServices(vObj);
	// Refresh analitical parameters
	BuildThisFormClientDataDecoration(vObj);
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
	EndIf;
	// Build form caption
	BuildThisFormCaption(SelGuest1);
	// Show discounts
	If ValueIsFilled(Object.DiscountType) Or ValueIsFilled(Object.DiscountCard) Or Object.Discount <> 0 Then
		Items.GroupDiscounts.Show();
	EndIf;
EndProcedure // GuestOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildThisFormCaption(pGuest = "")
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
	ThisForm.Title = vFormCaption;
	ThisForm.AutoTitle = False;
EndProcedure // BuildThisFormCaption

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildThisFormRemarksDataDecoration()
	Items.GroupRemarks.CollapsedRepresentationTitle = "";
	If Not IsBlankString(Object.Remarks) Or Not IsBlankString(Object.HousekeepingRemarks) Then
		Items.GroupRemarks.CollapsedRepresentationTitle = TrimAll(?(Not IsBlankString(Object.Remarks), NStr("en='Remarks: '; ru='Примечания: '; de='Bemerkungen: '") + TrimAll(Object.Remarks), "") + 
																  ?(Not IsBlankString(Object.HousekeepingRemarks), " • " + NStr("en='Housekeeping: '; ru='Горничные: '; de='Housekeeping: '") + TrimAll(Object.HousekeepingRemarks), ""));
	EndIf;
EndProcedure // BuildThisFormRemarksDataDecoration	

// -----------------------------------------------------------------------------
&AtServer
Procedure SourceOfBusinessOnChangeAtServer()
	// Calculate totals
	TotalSum = CalculateTotalServices();
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
	TotalSum = CalculateTotalServices(vObj);
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
		// Terms choice list
		FillServicePackageChoiceList();
	EndIf;
EndProcedure // MarketingCodeOnChangeAtServer

// ----------------------------------------------------------------------------
&AtServer
Procedure BoardPlaceOnChangeAtServer()
	// Calculate totals
	TotalSum = CalculateTotalServices();
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
	TotalSum = CalculateTotalServices(vObj);
	// Set object value
	If vUseParameterObject = False Then
		ValueToFormAttribute(vObj, "Object");
		// Terms choice list
		FillServicePackageChoiceList();
	EndIf;
EndProcedure // ClientTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	RoomRateOnChangeAtServer();
	ThisForm.Modified = True;
EndProcedure // RoomRateOnChange

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
	// Actions for new room rate
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
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to use room rate choosen!';ru='Нет прав на использование выбранного тарифа!';de='Sie haben keine Rechte, den ausgewählten Tarif zu verwenden!'"));
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
			tcCommonFunctionOnClientServer.TextMessage(tcOnServer.cmNStrAtServer(vWarnings));
		EndIf;
	EndIf;
	// Calculate totals
	If pDoPriceRecalc Then
		TotalSum = CalculateTotalServices(vObj, , False, False);
	Else
		TotalSum = CalculateTotalServices(vObj);
	EndIf;
	// Refresh analitical parameters
	BuildThisFormClientDataDecoration(vObj);
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
	EndIf;
	// Save room rate
	SavRoomRate = Object.RoomRate;
	SavAccommodationType = Object.AccommodationType;
EndProcedure // RoomRateOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetAllAccommodationStatuses()
	vAccommodationStatusesArray = New Array;
	vAccStses = cmGetAllAccommodationStatuses();
	For Each vAccSts In vAccStses Do
		// Fill choice array
		vAccommodationStatusesArray.Add(vAccSts.AccommodationStatus);
	EndDo;
	Return vAccommodationStatusesArray;
EndFunction // GetAllAccommodationStatuses

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomOnChangeAtServer(pRecalculateServices = True, pObj = Undefined, pClientTypeIsChanged = False)
	ChangeRoomMessageText = "";
	Items.ChangeRoomMessageTextGroup.Visible = False;
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
				vObj.pmClearOccupationPercents();
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
		TotalSum = CalculateTotalServices(vObj);
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
	If vUseParameterObject = False Then	
		// Set object value
		ValueToFormAttribute(vObj, "Object");
		// Terms choice list
		FillServicePackageChoiceList();
	EndIf;
EndProcedure // RoomOnChangeAtServer

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
	TotalSum = CalculateTotalServices(vObj);
	If vUseParameterObject = False Then	
		// Set object value
		ValueToFormAttribute(vObj, "Object");
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
	TotalSum = CalculateTotalServices(vObj);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // FixReservationConditionsOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AgentCommissionOnChangeAtServer()
	// Get object value
	vObj = FormAttributeToValue("Object");
	// Calculate totals
	TotalSum = CalculateTotalServices(vObj);
	// Set object value
	ValueToFormAttribute(vObj, "Object");
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
					Items["KidAge" + String(vInd)].Visible = False;
					ThisForm["KidAge" + String(vInd)] = 0;
				Except
				EndTry;
			EndDo;
		EndIf;
	Else
		If Not pOnOpen Then
			If NumberOfKids > NumberOfKidAgeFields Then
				NumberOfKids = NumberOfKidAgeFields;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Maximum number of children allowed is " + NumberOfKidAgeFields + "!';ru='Максимально возможное число детей равно " + NumberOfKidAgeFields + "!';de='Maximum number of children allowed is " + NumberOfKidAgeFields + "!'"));
			EndIf;
		EndIf;
		Items.AgeDecoration.Visible = True;
		If NumberOfKids < LastKidsNumber Then
			For vInd = NumberOfKids + 1 To LastKidsNumber Do
				Try
					Items["KidAge" + String(vInd)].Visible = False;
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
			ThisForm["KidAge"+String(NumberOfKidAgeFields+vInd)] = pAgesList[NumberOfKidAgeFields+vInd-1].Value;
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
				vAge = ThisForm["KidAge"+String(vInd)];
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
						If ThisForm["KidAge"+String(NumberOfKids-vInd)] = 0 Then
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
			vNumberOfGuestsInDatabase = GuestsInGroup.Count() + 1;
			vNumberOfGuestsInTemplate = vNumberOfGuestsInDatabase;
			If ValueIsFilled(vObj.AccommodationTemplate) And Not OneGuestMode Then
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
						If pOnOpen And ValueIsFilled(vObj.RoomType) And Not OneGuestMode And vNumberOfGuestsInDatabase <> vNumberOfGuestsInTemplate Then
							vObj.AccommodationTemplate = vAccommodationTemplatesRow.AccTemplate;
							Modified = True;
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
							ThisForm["Guest"+String(vInd)] = Undefined;
							ThisForm["AccommodationType"+String(vInd)] = Undefined;
							ThisForm["HotelProduct"+String(vInd)] = Undefined;
							ThisForm["Guest"+String(vInd)+"Registration"] = Undefined;
						EndDo;       
						If ThisForm.CurrentItem <> Undefined Then
							If Left(ThisForm.CurrentItem.Name, 6)="KidAge" Then
								ThisForm[ThisForm.CurrentItem.Name] = 0;
								For vInd = 1 To NumberOfKidAgeFields Do
									vKidAgeItem = Items["KidAge"+String(vInd)];
									If vKidAgeItem.Visible Then
										If ThisForm["KidAge"+String(vInd)] = 0 Then
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
									ThisForm["KidAge"+String(vInd)] = 0;
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
									If ThisForm["KidAge"+String(vKidIdx)] = 0 Then
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
									ThisForm["AccommodationType"+String(vIndex)] = vAccTypeRow.AccommodationType;
									vGuest = ThisForm["Guest"+String(vIndex)];
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
									ThisForm["AccommodationType"+String(vIndex)] = vAccTypeRow.AccommodationType;
									vGuest = ThisForm["Guest"+String(vIndex)];
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
										ThisForm["Guest"+String(vInd+1)] = Undefined;
										ThisForm["SelGuest"+String(vInd+1)] = "";
										ThisForm["AccommodationType"+String(vInd+1)] = Undefined;
										ThisForm["HotelProduct"+String(vInd+1)] = Undefined;
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
									ThisForm["Guest"+String(vInd)] = Undefined;
									ThisForm["SelGuest"+String(vInd)] = "";
									ThisForm["AccommodationType"+String(vInd)] = Undefined;
									ThisForm["HotelProduct"+String(vInd)] = Undefined;
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
					CalculateTotalServices(vObj);
				EndIf;
			Else
				If vNumberOfPersons > NumberOfGuestFields Then
					Try
						vIndex = 1;
						For Each vGiGRow In GuestsInGroup Do
							If vIndex >= NumberOfGuestFields Then
								AddGuestFieldAttributes(1, vObj);
							EndIf;
							ThisForm["Guest"+String(vIndex+1)] = vGiGRow.GuestRef;
							ThisForm["SelGuest"+String(vIndex+1)] = vGiGRow.Guest;
							Items["Guest"+String(vIndex+1)+"Group"].Visible = True;
							Items["Guest"+String(vIndex+1)+"Group"].Enabled = True;
							ThisForm["AccommodationType"+String(vIndex+1)] = vGiGRow.AccommodationType;
							ThisForm["HotelProduct"+String(vIndex+1)] = vGiGRow.HotelProduct;
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
							ThisForm["Guest"+String(vIndex+1)] = vGiGRow.GuestRef;
							ThisForm["SelGuest"+String(vIndex+1)] = vGiGRow.Guest;
							ThisForm["AccommodationType"+String(vIndex+1)] = vGiGRow.AccommodationType;
							ThisForm["HotelProduct"+String(vIndex+1)] = vGiGRow.HotelProduct;
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
						CalculateTotalServices(vObj);
					EndIf;
				EndIf;
			EndIf;
		Else
			Try
				If vNumberOfPersons > NumberOfGuestFields Then
					For vInd = 2 To NumberOfGuestFields Do
						Items["Guest"+String(vInd)+"Group"].Visible = True;
						Items["Guest"+String(vInd)+"Group"].Enabled = True;
						//ThisForm["AccommodationType"+String(vInd)] = Undefined;
						ThisForm["HotelProduct"+String(vInd)] = Undefined;
					EndDo;
					vNumberOfFieldsToAdd = vNumberOfPersons - NumberOfGuestFields;
					AddGuestFieldAttributes(vNumberOfFieldsToAdd, vObj);
				Else
					For vInd = 2 To vNumberOfPersons Do
						Items["Guest"+String(vInd)+"Group"].Visible = True;
						Items["Guest"+String(vInd)+"Group"].Enabled = True;
						//ThisForm["AccommodationType"+String(vInd)] = Undefined;
						ThisForm["HotelProduct"+String(vInd)] = Undefined;
					EndDo;
					If vGIGCount >= vNumberOfPersons Then
						vRowsToDeleteArray = New Array;
						For vInd = vNumberOfPersons To vGIGCount Do
							Items["Guest"+String(vInd+1)+"Group"].Visible = False;
							ThisForm["Guest"+String(vInd+1)] = Undefined;
							ThisForm["SelGuest"+String(vInd+1)] = "";
							ThisForm["AccommodationType"+String(vInd+1)] = Undefined;
							ThisForm["HotelProduct"+String(vInd+1)] = Undefined;
							Items["SelGuest"+String(vInd+1)].TextEdit = True;
							vRowsToDeleteArray.Add(GuestsInGroup.Get(vInd-1));
						EndDo;
						For Each vRow in vRowsToDeleteArray Do
							GuestsInGroup.Delete(vRow);
						EndDo;
					ElsIf vNumberOfPersons < LastNumberOfAdults+LastKidsNumber Then
						For vInd = vNumberOfPersons+1 To LastNumberOfAdults+LastKidsNumber Do
							Items["Guest"+String(vInd)+"Group"].Visible = False;
							ThisForm["Guest"+String(vInd)] = Undefined;
							ThisForm["SelGuest"+String(vInd)] = "";
							ThisForm["AccommodationType"+String(vInd)] = Undefined;
							ThisForm["HotelProduct"+String(vInd)] = Undefined;
							Items["SelGuest"+String(vInd)].TextEdit = True;
						EndDo;
					EndIf;
				EndIf;
				For Each vGiG In GuestsInGroup Do
					vInd = GuestsInGroup.IndexOf(vGiG) + 2;
					If ThisForm["AccommodationType"+String(vInd)] = Undefined Then
						vGiG.AccommodationType = Undefined;
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
		If Object.Hotel.MoreThen3ChildrenAgeRangesAreUsed Then
			vAccTypesAreEditable = True;
		EndIf;
	EndIf;
	If GuestsInGroup.Count() > 0 Then
		vAccTypeItem = ThisForm.Items.AccommodationType;
		If vAccTypesAreEditable Then
			vAccTypeItem.Enabled = True;
		Else	
			vAccTypeItem.Enabled = False;
		EndIf;
	EndIf;
	vTypes = Items.AccommodationType.ChoiceList.UnloadValues();
	For Each vGiG In GuestsInGroup Do
		vInd = GuestsInGroup.IndexOf(vGiG) + 2;
		vAccTypeItem = ThisForm.Items["AccommodationType"+String(vInd)];
		vAccTypeItem.Enabled = vAccTypesAreEditable;
		vAccTypeItem.ChoiceList.LoadValues(vTypes);
		If vAccTypesAreEditable Then
			vAccTypeItem.SetAction("StartChoice", "ExtraGuestAccommodationTypeStartChoice");
			vAccTypeItem.SetAction("OnChange", "ExtraGuestAccommodationTypeOnChange");
		EndIf;
	EndDo;
	
	If pObj = Undefined Then
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // CheckGuestFieldCount

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
	If vHotelCitizenship.Code = 643 Then //Russia
		While True Do
			If ValueIsFilled(vGuest) And vGuest.Citizenship <> vHotelCitizenship Then
				Items["Guest"+String(vIndex)+"RegistrationGroup"].Visible = True;
				vCitizenshipISOCode = TrimAll(vGuest.Citizenship.ISOCode);
				Items["Guest"+String(vIndex)+"RegistrationIndent"].Title = vCitizenshipISOCode;
				vGuestRegDoc = GetGuestForeignerRegistryRecord(vGuest, vObj);
				ThisForm["Guest"+String(vIndex)+"Registration"] = vGuestRegDoc;
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
			Else
				Items["Guest"+String(vIndex)+"RegistrationGroup"].Visible = False;
				Items["Guest"+String(vIndex)+"RegistrationIndent"].Title = "";
				ThisForm["Guest"+String(vIndex)+"Registration"] = Undefined;
				Items["Guest"+String(vIndex)+"RegistrationAction"].Title = "";
				Items["Guest"+String(vIndex)+"RegistrationAction"].TextColor = Items["Guest"+String(vIndex)+"RegistrationIndent"].TextColor;
			EndIf;
			
			vIndex = vIndex + 1;
			If vIndex > (GuestsInGroup.Count() + 1) Then
				Break;
			EndIf;
			vGuest = ThisForm["Guest"+String(vIndex)];
			vGIG = GuestsInGroup.Get(vIndex - 2);
			If ValueIsFilled(vGIG.Ref) Then
				vGuestCheckOutDate = vGIG.Ref.CheckOutDate;
			EndIf;
		EndDo;
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
		vTempArray.Add(New FormAttribute("GuestChangesDescription"+String(NumberOfGuestFields+vInd), New TypeDescription("String")));
		vTempArray.Add(New FormAttribute("HotelProduct"+String(NumberOfGuestFields+vInd), New TypeDescription("CatalogRef.HotelProducts")));
		vTempArray.Add(New FormAttribute("Guest"+String(NumberOfGuestFields+vInd)+"Registration", cmGetDocumentTypeDescription("ForeignerRegistryRecord")));
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
		// Second Horizontal guest group
		vGuestGroupInfo = Items.Add("Guest"+String(NumberOfGuestFields+vInd)+"H1GroupInfo", Type("FormGroup"), vGuestGroupInfo);
		vGuestGroupInfo.Title = "";
		vGuestGroupInfo.Type = FormGroupType.UsualGroup;
		vGuestGroupInfo.Representation = UsualGroupRepresentation.None;
		vGuestGroupInfo.Group = ChildFormItemsGroup.AlwaysHorizontal;
		vGuestGroupInfo.ChildItemsWidth = ChildFormItemsWidth.LeftWidest;
		vGuestGroupInfo.ShowTitle = False;
		// Accommodation type field
		vNewField = Items.Add("AccommodationType"+String(NumberOfGuestFields+vInd), Type("FormField"), vGuestGroupInfo);
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
		// Hotel product field
		vNewField = Items.Add("HotelProduct"+String(NumberOfGuestFields+vInd), Type("FormField"), vGuestGroup);
		vNewField.Type = FormFieldType.InputField;
		vNewField.Enabled = UseHotelProducts;
		vNewField.Visible = UseHotelProducts;
		vNewField.Title = NStr("en='Vaucher'; de='Reisescheck'; ru='Путевка'");
		vNewField.TextEdit = True;
		vNewField.DataPath = "HotelProduct"+String(NumberOfGuestFields+vInd);
		vNewField.ChoiceButtonRepresentation = ChoiceButtonRepresentation.Auto;
		vNewField.CreateButton = True;
		vNewField.DropListButton = False;
		vNewField.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
		vNewField.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
		vNewField.Width = 12;
		vNewField.AutoMaxWidth = False;
		vNewField.SetAction("StartChoice", "ExtraGuestHotelProductStartChoice");
		vNewField.SetAction("OnChange", "ExtraGuestHotelProductOnChange");
		vNewField.SetAction("Opening", "ExtraGuestHotelProductOpening");
		vNewField.SetAction("Creating", "ExtraGuestHotelProductCreating");
		// Open detailed form button 
		If Items.ButtonOpenDetailedForm1.Visible Then
			vNewField = Items.Add("ButtonOpenDetailedForm"+String(NumberOfGuestFields+vInd), Type("FormButton"), vGuestGroupInfo);
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
Procedure GuestGroupStartChoiceEnd(Result, AdditionalParameters) Export
	pItem = AdditionalParameters.pItem;
	vFrmResult = Result;
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
			vNotifyDescr = New NotifyDescription("AfterPriceChangeReasonSelection", ThisForm);
			vResultStructure = OpenForm("CommonForm.tcPriceChangeReasonSelection", New Structure("SettingStructure", vParametersStructure), ThisForm, , , , vNotifyDescr, FormWindowOpeningMode.LockWholeInterface);
		EndIf;
	Else
		If ValueIsFilled(Object.PriceChangeReason) Then
			Object.PriceChangeReason = "";
			PriceChangeReason = NStr("en='<price change reason>'; ru='<причина изменения цены>'; de='<Preisänderungsgründe>'");
		EndIf;
	EndIf;
	// Refresh analitical parameters
	BuildThisFormClientDataDecoration();
EndProcedure // FillPriceChangeReason

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterPriceChangeReasonSelection(pValue,pAdditionalParameters) Export
	If Not pValue = Undefined Then
		vResultStructure = pValue;
		If Object.PriceChangeReason <> vResultStructure.PriceChangeReason Then
			Object.PriceChangeReason = vResultStructure.PriceChangeReason;
			PriceChangeReason = Object.PriceChangeReason;
			If IsBlankString(PriceChangeReason) Then
				PriceChangeReason = NStr("en='<price change reason>'; ru='<причина изменения цены>'; de='<Preisänderungsgründe>'");
			EndIf;
		EndIf;
		BuildThisFormClientDataDecoration();
		ThisForm.Modified = True;
		ThisForm.RefreshDataRepresentation();
	EndIf;
EndProcedure // AfterPriceChangeReasonSelection

// -----------------------------------------------------------------------------
&AtServer
Function HaveRightsForManualPriceChange()
	Return cmCheckUserPermissions("HavePermissionToAddManualPrices");
EndFunction // HaveRightsForManualPriceChange

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
Procedure CheckIfCheckOutDateTimeIsFilled()
	If ValueIsFilled(CheckOutDateTime) Then
		DetachIdleHandler("CheckIfCheckOutDateTimeIsFilled");
		// Check balances for selected accommodations
		vResultMessage = "";
		vResult = CheckAccommodationsBalances(AccList, vResultMessage);
		If Not IsBlankString(vResultMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vResultMessage, MessageStatus.Important);
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Accommodation.CheckBalances';ru='Размещение.ПроверкаБаланса';de='Accommodation.CheckBalances'"), Undefined, "Documents.Folio", , vResultMessage);
			If Not vResult Then
				Return;
			EndIf;
		EndIf;
		// Check if advances were cleared
		vResultMessage = "";
		vResult = CheckIfAdvancesWereCleared(AccList, vResultMessage);
		If Not IsBlankString(vResultMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vResultMessage, MessageStatus.Important);
			tcOnServer.cmWriteLogEventAtServer(NStr("en='Accommodation.CheckIfAdvancesWereCleared';ru='Размещение.ПроверкаЗачетаАванса';de='Accommodation.CheckIfAdvancesWereCleared'"), Undefined, "Documents.Folio", , vResultMessage);
			If Not vResult Then
				Return;
			EndIf;
		EndIf;
		// Check future reservations
		vMessage = CheckFutureReservationsAtServer(Object.Ref, CheckOutDateTime);
		If Not IsBlankString(vMessage) Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
		EndIf;
		// Do check-out
		vResult = CheckOutAtServer(Object.Ref, AccList, CheckOutDateTime, False);
		If ValueIsFilled(vResult) Then
			If vResult = "SendNotifications" Then
				// Send notification to all open forms
				Notify("Subsystem.Accounts.Changed", Object.Ref, ThisForm);
				Notify("Document.ResourceReservation.Write", , ThisForm);
				// Notify that accommodation is changed
				Notify("Document.Accommodation.Write", Object.Ref, ThisForm);
				// Close document form if possible
				If Not ThisForm.Modified And ThisForm.IsOpen() Then
					// Refresh document data
					ThisForm.Read();
					// Open folios list
					OpenFolios(Undefined);
					// Close form
					ThisForm.Close();
				Else
					// Refresh document data
					ThisForm.Read();
				EndIf;
			Else
				tcCommonFunctionOnClientServer.TextMessage(vResult);
				// Refresh document data
				ThisForm.Read();
			EndIf;
		Else
			// Notify that accommodation is changed
			Notify("Document.Accommodation.Write", Object.Ref, ThisForm);
			// Close document form if possible
			If Not ThisForm.Modified And ThisForm.IsOpen() Then
				// Refresh document data
				ThisForm.Read();
				// Open folios list
				OpenFolios(Undefined);
				// Close form
				ThisForm.Close();
			Else
				// Refresh document data
				ThisForm.Read();
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
	vOnCloseNotifyDescription = New NotifyDescription("GetCheckOutDateAfterUserInput", ThisForm, New Structure("CheckInDate, CheckOutDate", pCheckInDate, pCheckOutDate));
	vParams = New Structure("FillingValues", New Structure("Date, Time, Description, IsProtected, DateIsProtected", vDate, vTime, vDescription, vIsProtected, vDateIsProtected));
	OpenForm("CommonForm.tcInputDateTime", vParams, ThisForm, , , , vOnCloseNotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
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
				OpenForm("Document.Folio.Form.tcFolioPrintForm", vParams, ThisForm, new UUID);
			EndIf;
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
		vFrm = OpenForm("Document.ForeignerRegistryRecord.ObjectForm", New Structure("Basis", pAccRef), ThisForm, pAccRef);
	EndIf;
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
	OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoice, Language", pInvoice, vLang), ThisForm, pInvoice);
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
		OpenForm("Document.Settlement.ObjectForm", New Structure("Key", pInvItem.Value), ThisForm, pInvItem.Value);
	EndIf;
EndProcedure // GroupInvoiceSelection

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardAfterUserInput(pCreditCard) Export
	If ValueIsFilled(pCreditCard) Then
		Object.CreditCard = pCreditCard;
		CreditCardPresentation = TrimAll(Object.CreditCard);
		Items.ClearCreditCard.Visible = True;
		ThisForm.Modified = True;
	Else
		CreditCardPresentation = NStr("en='<Credit card>'; ru='<Кредитная карта>'; de='<Kreditkarte>'");
		Items.ClearCreditCard.Visible = False;
	EndIf;
EndProcedure // CreditCardAfterUserInput

// -----------------------------------------------------------------------------
&AtServer
Procedure CreateCustomerFromGuest()
	vObj = FormAttributeToValue("Object");
	If ValueIsFilled(vObj.Guest) Then
		vCreateNew = True;
		vGuest = vObj.Guest;
		// Try to find customer with guest full name
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
		vQry.SetParameter("qDescription", Upper(TrimAll(vGuest.FullName)));
		vQry.SetParameter("qDateOfBirth", vGuest.DateOfBirth);
		vQry.SetParameter("qEmptyDate", '00010101');
		vQryRes = vQry.Execute().Unload();
		If vQryRes.Count() > 0 Then
			vCreateNew = False;
			For Each vQryResRow In vQryRes Do
				vObj.Customer = vQryResRow.Ref;
				CustomerOnChangeAtServer(vObj);
				Break;
			EndDo;
		EndIf;
		If vCreateNew Then
			vCustObj = Catalogs.Customers.CreateItem();
			vIndividualsFolder = Constants.IndividualsFolder.Get();
			If Not ValueIsFilled(vIndividualsFolder) Then
				vIndividualsFolder = Catalogs.Customers.IndividualsFolder;
			EndIf;
			vCustObj.Parent = vIndividualsFolder;
			vCustObj.pmFillAttributesWithDefaultValues();
			vCustObj.Description = vGuest.FullName;
			vCustObj.LegacyName = vGuest.FullName + 
			                      ?(ValueIsFilled(vGuest.DateOfBirth), ", " + Format(vGuest.DateOfBirth, "DF=dd.MM.yyyy"), "") + 
								  ?(IsBlankString(vGuest.IdentityDocumentNumber), "", ", " + TrimAll(vGuest.IdentityDocumentType) + " " + TrimAll(vGuest.IdentityDocumentSeries) + " " + TrimAll(vGuest.IdentityDocumentNumber));
			vCustObj.LegacyAddress = vGuest.Address;
			vCustObj.Phone = vGuest.Phone;
			vCustObj.Fax = vGuest.Fax;
			vCustObj.EMail = vGuest.EMail;
			vCustObj.Language = vGuest.Language;
			vCustObj.IdentityDocumentIssueDate = vGuest.IdentityDocumentIssueDate;
			vCustObj.IdentityDocumentIssuedBy = vGuest.IdentityDocumentIssuedBy;
			vCustObj.IdentityDocumentNumber = vGuest.IdentityDocumentNumber;
			vCustObj.IdentityDocumentSeries = vGuest.IdentityDocumentSeries;
			vCustObj.IdentityDocumentType = vGuest.IdentityDocumentType;
			vCustObj.IdentityDocumentValidToDate = vGuest.IdentityDocumentValidToDate;
			vCustObj.DateOfBirth = vGuest.DateOfBirth;
			vCustObj.Client = vGuest;
			vCustObj.IsIndividual = True;
			vCustObj.pmFillPlannedPaymentMethodFromChargingRules();
			vCustObj.Write();
			vCustObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			vObj.Customer = vCustObj.Ref;
			CustomerOnChangeAtServer(vObj);
		EndIf;
		ValueToFormAttribute(vObj, "Object");
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Please fill guest first!';ru='Сначала введите данные гостя!';de='Erst die Daten des Gastes eintragen!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // CreateCustomerFromGuest

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
		vGiGRow.AccommodationType = ThisForm["AccommodationType" + pInd];
		ValueToFormAttribute(vGuestsInGroup, "GuestsInGroup");
		// Get object value
		vObj = FormAttributeToValue("Object");
		// Calculate totals
		TotalSum = CalculateTotalServices(vObj);
		// Set object value
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure // ExtraGuestAccommodationTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetArrayOfAllClientTypes()
	vCTTable = cmGetAllClientTypes();
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

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeConfirmationTextChange()
	If ValueIsFilled(Object.ClientType) Then
		If tcOnServer.cmGetAttributeByRef(Object.ClientType, "AskForConfirmation") Then
			Object.ClientTypeConfirmationText = tcOnServer.cmGetAttributeByRef(Object.ClientType, "ConfirmationPattern");
			ShowInputString( New NotifyDescription("AfterClientTypeConfirmationTextChange", ThisForm), 
							Object.ClientTypeConfirmationText,
							NStr("ru='Заполните шаблон строки подтверждения!';
					        |de='Vorlage der Bestätigungszeile ausfüllen!';
	                        |en='Please fill confirmation text pattern!'"),
	                   		100, 
							False); 
		Else
			Object.ClientTypeConfirmationText = "";
			ClientTypeOnChangeAtServer();
			BuildThisFormClientDataDecoration();
			ThisForm.Modified = True;
		EndIf;
	Else
		Object.ClientTypeConfirmationText = "";
		ClientTypeOnChangeAtServer();
		BuildThisFormClientDataDecoration();
		ThisForm.Modified = True;
	EndIf;
EndProcedure // ClientTypeConfirmationTextChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterClientTypeConfirmationTextChange(pText, pExtraPerams) Export 
	If pText <> Undefined Then
		Object.ClientTypeConfirmationText = pText;
		If Upper(TrimAll(Object.ClientTypeConfirmationText)) = Upper(TrimAll(tcOnServer.cmGetAttributeByRef(Object.ClientType, "ConfirmationPattern"))) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Строка подтверждения совпадает с шаблоном! Выбор типа клиента будет отменен.';
			                  |de='Zeile für die Bestätigung stimmt mit Vorlage überein! Die Auswahl des Kundentyps wird zurückgesetzt!'; 
			                  |en='Confirmation text is the same as confirmation pattern! Client type will be cleared.'"));
			Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
			Object.ClientTypeConfirmationText = "";
		ElsIf IsBlankString(Object.ClientTypeConfirmationText) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Строка подтверждения не введена! Выбор типа клиента будет отменен.';
			                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl des Kundentyps wird zurückgesetzt.'; 
							  |en='Confirmation text is not entered! Client type will be cleared.'"));
			Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
			Object.ClientTypeConfirmationText = "";	
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Строка подтверждения не введена! Выбор типа клиента будет отменен.';
		                  |de='Die Zeile für die Bestätigung wurde nicht eingefügt! Die Auswahl des Kundentyps wird zurückgesetzt.'; 
						  |en='Confirmation text is not entered! Client type will be cleared.'"));
		Object.ClientType = PredefinedValue("Catalog.ClientTypes.EmptyRef");
		Object.ClientTypeConfirmationText = "";
	EndIf;
	ClientTypeOnChangeAtServer();
	BuildThisFormClientDataDecoration();
	ThisForm.Modified = True;
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
			vNum = 0;
			While vNum < vRoomRates.Count() Do
				vFrmRoomRate = vRoomRates.Get(vNum);
				If vRoomRatesAllowed.FindByValue(vFrmRoomRate.Value) = Undefined Then
					If Not (ValueIsFilled(Object.ParentDoc) And Object.ParentDoc.RoomRate = Object.RoomRate) Then
						vRoomRates.Delete(vNum);
					Else
						vNum = vNum + 1;
					EndIf;
				Else
					vNum = vNum + 1;
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
	TotalSum = CalculateTotalServices();
	// Terms choice list
	FillServicePackageChoiceList();
EndProcedure

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
&AtServer
Function SendWelcomeSMSAtServer()
	vMessage = "";
	vExtSys = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsHotel365(Object.Hotel);
	If NOT ValueIsFilled(vExtSys) Then
		// The integration with hotel365 is not set
		Return NStr("en = 'Integration with the hotel365 service is not configured'; de = 'Die Integration mit hotel365 ist nicht konfiguriert'; ru = 'Не настроена интеграция с сервисом hotel365'");
	EndIf;
	If NOT vExtSys.IsActive Then
		// The integration with hotel365 is switched off
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
		|	ClientDataScans.Date DESC";
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
	If vRoomTypes.Count() = 1 Then
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
Procedure HotelProductOnChangeAtServer()
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
	// Calculate totals
	TotalSum = CalculateTotalServices();
EndProcedure // HotelProductOnChangeAtServer


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
			
			tcOnServer.cmCreateItem(ThisForm,?( SelectionRecords.IsDefault,Items.FormGroupFunctionsDefault,Items.FormGroupFunctionsNotDefault),"Func"+vID,"FormButton",vStructure);
		EndIf;
	EndDo;
EndProcedure

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
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Current workstation is not defined!';ru='Не определено текущее рабочее место!';de='Der aktuelle Arbeitsplatz ist nicht festgelegt!'"));
		Return;
	EndIf;
	If Not tcOnServer.cmGetAttributeByRef(vCurrentWorkstation,"HasConnectionToRibbonPrinter") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Current workstation has not connected to a ribbon printer!';ru='К текущему рабочему месту не подключен ленточный принтер!';de='An diesen Arbeitsplatz ist kein Banddrucker angeschlossen!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(tcOnServer.cmGetAttributeByRef(vCurrentWorkstation,"RibbonPrinterConnectionParameters")) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Ribbon printer connection parameters are missing!';ru='У текущего рабочего места не указаны параметры подключения ленточного принтера!';de='Beim aktuellen Arbeitsplatz sind keine Parameter für den Anschluss an den Banddrucker angegeben!'"));
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
		vNotifyDescription = New NotifyDescription("AfterChooseItemToCoupons",ThisForm, New Structure("Action,Base",pAction,pBase));
		vParams = New Structure("ValueList, MultipleChoice, Title", vServices, False, NStr("en='Choose service...';ru='Выберите услугу...';de='Wählen Sie die Dienstleistung...'"));
		OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
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
			OpenForm("DataProcessor.PrintCouponSystemPrinter.Form.tcCouponPrintForm", New Structure("SelLanguage, SelObjList, RibbonPrinterConnectionParameters", vLanguage, vCouponsList, vRibbonPrinterConnection), ThisForm, ThisForm.UUID);
		ElsIf vDriverType = PredefinedValue("Enum.RibbonPrinterDrivers.Intermec") Then
			OpenForm("DataProcessor.IntermecRibbonPrinterDriver.Form.tcCouponPrintForm", New Structure("SelLanguage, SelObjList, RibbonPrinterConnectionParameters", vLanguage, vCouponsList, vRibbonPrinterConnection), ThisForm, ThisForm.UUID);	
		ElsIf vDriverType = PredefinedValue("Enum.RibbonPrinterDrivers.Atol") Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Данный принтер временно не поддерживается в тонком клиенте';en='This printer is temporarily not supported in the thin client';de='Dieser Drucker wird im Thin Client vorübergehend nicht unterstützt'"));	
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Nothing to print!';ru='Нет услуг для печати!';de='Es gibt keine Dienste für den Druck!'"));
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
			vParentLang = tcOnServer.cmCreateItem(ThisForm,Items.FormGroupPrintingNotDefaultExtra,"Print"+SelectionRecords.Language,"FormGroup",
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
				
				tcOnServer.cmCreateItem(ThisForm,vParent,"Print"+vID,"FormButton",vStructure);
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
	OpenForm("Report.PrintHotelProducts.Form.tcReportForm", vParams, ThisForm, ThisForm.UUID);
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
Procedure ClearResortFeeExemptionAtServer()
	// Get resort fee service
	vResortFeeServiceCurrency = Undefined;
	vResortFeeService = GetResortFeeService(vResortFeeServiceCurrency);
	// Get object
	vObj = FormAttributeToValue("Object");
	// Check if this row already exists
	vPRow = vObj.Prices.Find(vResortFeeService, "Service");
	If vPRow <> Undefined Then
		// Delete row to manual prices
		vObj.Prices.Delete(vPRow);
		// Recalculate services
		vObj.pmCalculateServices( , , , , , vObj.IsForFolioSplit, , ?(OneGuestMode, Undefined, vObj.AccommodationTemplate));
		// Move object back
		ValueToFormAttribute(vObj, "Object");
		// Calculate totals
		TotalSum = CalculateTotalServices(, , False, False);
	EndIf;
EndProcedure // ClearResortFeeExemptionAtServer

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
	TotalSum = CalculateTotalServices();
EndProcedure // ResortFeeExemptAfterQuery

// -----------------------------------------------------------------------------
&AtServer
Function GetResortFeeService(rCurrency)
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
	If Not ValueIsFilled(vService) Then
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
Procedure AccommodationFillClientFeedback(pAction)
	If ValueIsFilled(Object.Guest) Then
		// Try to find existing client feedback
		vFeedbackDoc = GetClientFeedback(Object.Ref);
		If ValueIsFilled(vFeedbackDoc) Then
			OpenForm("Document.ClientFeedback.ObjectForm", New Structure("Key", vFeedbackDoc), ThisForm);
		Else
			OpenForm("Document.ClientFeedback.ObjectForm", New Structure("Basis", Object.Ref), ThisForm);
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Guest is not filled!'; ru='В размещении не указан гость!'; de='Gast ist nicht gefüllt!'"));
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
					vAge = ThisForm["KidAge"+String(vInd)];
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
			vNewCRRow.ChargingFolio = vCurData.Folio;
			vNewCRRow.ChargingRule = Enums.ChargingRuleTypes.One;
			vNewCRRow.ChargingRuleValue = vCurData.Service;
			If ValueIsFilled(vCurFolio.Contract) Then
				vNewCRRow.Owner = vCurFolio.Contract;
			ElsIf ValueIsFilled(vCurFolio.Customer) Then
				vNewCRRow.Owner = vCurFolio.Customer;
			EndIf;
		EndIf;
		If Not vCurData.IsManual Then
			vObj.pmSetFolioBasedOnChargingRules(Object.Services, True);
		EndIf;
	EndIf;
EndProcedure // ServicesFolioOnChangeAtServer

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
Procedure ServicesPriceOnChangeAtServer(pCurrentRow)
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
		// Calculate totals
		TotalSum = CalculateTotalServices();
	EndIf;
EndProcedure // ServicesPriceOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesQuantityOnChangeAtServer(pCurrentRow)
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
		// Calculate totals
		TotalSum = CalculateTotalServices();
	EndIf;
EndProcedure // ServicesQuantityOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesSumOnChangeAtServer(pCurrentRow)
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
		// Calculate totals
		TotalSum = CalculateTotalServices();
	EndIf;
EndProcedure // ServicesSumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesDiscountOnChangeAtServer(pCurrentRow)
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
		// Calculate totals
		TotalSum = CalculateTotalServices();
	EndIf;
EndProcedure // ServicesDiscountOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesDiscountSumOnChangeAtServer(pCurrentRow)
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
		// Calculate totals
		TotalSum = CalculateTotalServices();
	EndIf;
EndProcedure // ServicesDiscountSumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesAgentCommissionOnChangeAtServer(pCurrentRow)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
			vCurData.CommissionIsChanged = True;
		EndIf;
		vObj = FormAttributeToValue("Object");
		// Recalculate commissions
		vObj.pmCalculateServiceCommissions(vCurData);
		// Calculate totals
		TotalSum = CalculateTotalServices();
	EndIf;
EndProcedure // ServicesAgentCommissionOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesCommissionSumOnChangeAtServer(pCurrentRow)
	vCurData = Object.Services.FindByID(pCurrentRow);
	If vCurData <> Undefined Then
		If Not vCurData.IsManual Then
			vCurData.IsManualPrice = True;
			vCurData.CommissionIsChanged = True;
		EndIf;
		vCurData.VATCommissionSum = cmCalculateVATSum(vCurData.VATRate, vCurData.CommissionSum, vCurData.AccountingDate);
		// Calculate totals
		TotalSum = CalculateTotalServices();
	EndIf;
EndProcedure // ServicesCommissionSumOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicesVATRateOnChangeAtServer(pCurrentRow)
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
		// Calculate totals
		TotalSum = CalculateTotalServices();
	EndIf;
EndProcedure // ServicesVATRateOnChangeAtServer

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
	ThisForm.Modified = True;
	// Calculate totals
	TotalSum = CalculateTotalServices(, False, False, True, True);
	// Fill grid
	FillGridAtServer();
EndProcedure // DecorationTotalSumClickAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCloseAtServer()
	If ValueIsFilled(CurrentUser) Then
		SessionParameters.CurrentUser = CurrentUser;
		// Unlock all locked reservation objects
		If ValueIsFilled(Object.Reservation) Then
			UnlockDataForEdit(Object.Reservation, ThisForm.UUID);
		EndIf;
		If GuestsToCheckInList.Count() > 0 Then
			vNum = 1;
			While vNum <= GuestsInGroup.Count() Do
				If vNum < GuestsToCheckInList.Count() Then
					vReservation = GuestsToCheckInList.Get(vNum).Value;
					UnlockDataForEdit(vReservation, ThisForm.UUID);
				EndIf;
				vNum = vNum + 1;
			EndDo;
		EndIf;
	EndIf;
EndProcedure // OnCloseAtServer

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
	vTemplate = Object.AccommodationTemplate;
	If ValueIsFilled(vTemplate) Then
		Object.NumberOfAdults = vTemplate.NumberOfAdults;
		Object.NumberOfTeenagers = vTemplate.NumberOfTeenagers;
		Object.NumberOfChildren = vTemplate.NumberOfChildren;
		Object.NumberOfInfants = vTemplate.NumberOfInfants;
	Else
		Object.NumberOfAdults = 0;
		Object.NumberOfTeenagers = 0;
		Object.NumberOfChildren = 0;
		Object.NumberOfInfants = 0;
	EndIf;
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

// ------------------------------------------------------------------------------------------------
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
	// Build group collapsed title
	vTitle = NStr("en='Room rate: '; ru='Тариф: '; de='Tarif: '") + TrimAll(vObj.RoomRate) + 
			 ?(ValueIsFilled(vObj.ServicePackage) And vObj.ServicePackage.IsMealBoardTerm, ", " + TrimAll(vObj.ServicePackage), "") + 
			 ?(IsBlankString(TServicePackagesPresentation), "", ", " + TrimAll(TServicePackagesPresentation)) + 
			 ?(IsManualRoomPrice = 0, "", ?(ValueIsFilled(vObj.RoomTypeUpgrade), NStr("en=', price for '; ru=', цена для '; de=', Preis für '") + TrimAll(vObj.RoomTypeUpgrade.Code), ", " + PricePresentation + ?(IsManualRoomPrice = 1, NStr("en=' per room'; ru=' за номер'; de=' pro Zimmer'"), NStr("en=' per guest'; ru=' за гостя'; de=' pro Gast'"))));
	Items.GroupRoomRate.CollapsedRepresentationTitle = vTitle;
	If ValueIsFilled(vObj.RoomRate) And Not IsBlankString(vObj.RoomRate.Remarks) Then
		Items.RoomRateRemarks.Visible = True;
	Else
		Items.RoomRateRemarks.Visible = False;
	EndIf;
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
	TotalSum = CalculateTotalServices();
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetChargingRuleOwnerByFolioAtServer(pThisDocRef, pFolio, rIsTransfer)
	If ValueIsFilled(pFolio) Then
		vHotel = pFolio.Hotel;
		vParentDoc = pFolio.ParentDoc;
		If pThisDocRef <> vParentDoc Then
			rIsTransfer = True;
		EndIf;
		If ValueIsFilled(vParentDoc) And 
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
	vNum = 0;
	While vNum < vRatesList.Count() Do
		vRoomRate = vRatesList.Get(vNum).Value;
		If StrFind(lower(vRoomRate.Description), lower(TrimAll(pText))) = 0 Then
			vRatesList.Delete(vNum);
		Else
			vNum = vNum + 1;
		EndIf;
	EndDo;
	Return vRatesList;
EndFunction // GetListOfRoomRatesAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetNewDocumentFolioAtServer(pFolioData)
	vFolioObj = Documents.Folio.CreateDocument();
	vFolioObj.pmFillAttributesWithDefaultValues();
	FillPropertyValues(vFolioObj, pFolioData);
	vFolioObj.Write(DocumentWriteMode.Write);
	Return vFolioObj.Ref;
EndFunction // GetNewDocumentFolioAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetFolioFromReservation(pOwner)
	If pOwner.ChargingRules.Count() > 0 Then
		Return pOwner.ChargingRules.Get(0).ChargingFolio;
	Else
		Return Undefined;
	Endif;
EndFunction // GetFolioFromReservation

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetFolioFromResourceReservation(pOwner)
	Return pOwner.ChargingFolio;
EndFunction // GetFolioFromResourceReservation

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
	vTerms = vQry.Execute().Unload();
	Items.ServicePackage.ChoiceList.LoadValues(vTerms.UnloadColumn("Ref"));
EndProcedure // FillServicePackageChoiceList

// -----------------------------------------------------------------------------
&AtServer
Procedure FillTasksPresentation()
	TTasks = "";
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
			vTaskRemarks = TrimAll(vTasksRow.Remarks);
			If Left(vTaskRemarks, 1) = "•" Then
				TTasks = TTasks + vTaskRemarks + Chars.LF;
			Else
				TTasks = TTasks + "• " + vTaskRemarks + Chars.LF;
			EndIf;
		EndDo;
	ElsIf ValueIsFilled(Object.Reservation) Then
		vTasks = cmGetMessagesForObject(Object.Reservation);
		For Each vTasksRow In vTasks Do
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
	ShowClosedTasksAvailability();
EndProcedure // FillTasksPresentation

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionCancelAtServer(pCurRow)
	vDocObj = pCurRow.Ref.GetObject();
	vDocObj.IsCanceled = True;
	vDocObj.IsProcessed = False;
	vDocObj.Write(DocumentWriteMode.Write);
EndProcedure // ActionCancelAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SetChargingRuleValueType()
	vCurRow = Object.ChargingRules.FindByID(Items.ChargingRules.CurrentRow);
	If vCurRow <> Undefined Then
		If ValueIsFilled(vCurRow.ChargingRule) Then
			Items.ChargingRulesChargingRuleValue.ChooseType = False;
			If vCurRow.ChargingRule = Enums.ChargingRuleTypes.AllButOne Or
			   vCurRow.ChargingRule = Enums.ChargingRuleTypes.One Then
				If TypeOf(vCurRow.ChargingRuleValue) <> Type("CatalogRef.Services") Then
					vCurRow.ChargingRuleValue = Catalogs.Services.EmptyRef();
				EndIf;
			ElsIf vCurRow.ChargingRule = Enums.ChargingRuleTypes.InServiceGroup Or
			      vCurRow.ChargingRule = Enums.ChargingRuleTypes.NotInServiceGroup Then
				If TypeOf(vCurRow.ChargingRuleValue) <> Type("CatalogRef.ServiceGroups") Then
					vCurRow.ChargingRuleValue = Catalogs.ServiceGroups.EmptyRef();
				EndIf;
			ElsIf vCurRow.ChargingRule = Enums.ChargingRuleTypes.RestOfRoomRevenuePrice Or
			      vCurRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenueAmount Or
			      vCurRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePrice Or
			      vCurRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePriceByRoomType Or
			      vCurRow.ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePricePercent Then
				If TypeOf(vCurRow.ChargingRuleValue) <> Type("Number") Then
					vCurRow.ChargingRuleValue = 0;
				EndIf;
			Else
				vCurRow.ChargingRuleValue = Undefined;
			EndIf;
		Else
			Items.ChargingRulesChargingRuleValue.ChooseType = True;
			vCurRow.ChargingRuleValue = Undefined;
		EndIf;
	EndIf;
EndProcedure // SetChargingRuleValueType

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
			vAccountingDatesList.Add(BegOfDay(Object.CheckInDate) + (vServicePackageRow.AccountingDayNumber - 1) * 24 * 3600);
		ElsIf ValueIsFilled(vServicePackageRow.QuantityCalculationRule) Then
			vCurDate = BegOfDay(Object.CheckInDate);
			While vCurDate <= BegOfDay(Object.CheckOutDate) Do
				// Check calendar day type
				If ValueIsFilled(vServicePackageRow.CalendarDayType) Then
					vRoomRate = Object.RoomRate;
					vPriceCalculationDate = Object.PriceCalculationDate;
					If Object.RoomRates.Count() > 0 Then
						vRoomRatesRow = vObj.RoomRates.Find(vCurDate, "AccountingDate");
						If vRoomRatesRow <> Undefined Then
							If ValueIsFilled(vRoomRatesRow.RoomRate) Then
								vRoomRate = vRoomRatesRow.RoomRate;
								If ValueIsFilled(vRoomRatesRow.PriceCalculationDate) Then
									vPriceCalculationDate = vRoomRatesRow.PriceCalculationDate;
								EndIf;
							EndIf;
						EndIf;
					EndIf;
					vCalendarDayType = cmGetCalendarDayType(vRoomRate, vCurDate, Object.CheckInDate, Object.CheckOutDate, , ?(ValueIsFilled(Object.RoomTypeUpgrade), Object.RoomTypeUpgrade, Object.RoomType), vPriceCalculationDate);
					If vCalendarDayType <> vServicePackageRow.CalendarDayType Then
						// Go to the next date
						vCurDate = vCurDate + 24 * 3600;
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
				vCurDate = vCurDate + 24 * 3600;
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
						vRoomRatesRow = vObj.RoomRates.Find(vCurDate, "AccountingDate");
						If vRoomRatesRow <> Undefined Then
							If ValueIsFilled(vRoomRatesRow.RoomRate) Then
								vRoomRate = vRoomRatesRow.RoomRate;
								If ValueIsFilled(vRoomRatesRow.PriceCalculationDate) Then
									vPriceCalculationDate = vRoomRatesRow.PriceCalculationDate;
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
			vCurRow.IsInPrice = vServicePackageRow.IsInPrice;
			vCurRow.IsManual = True;
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
&AtServerNoContext
Function GetCurrencyExchangeRateAtServer(pHotel, pFolioCurrency, pExchangeRateDate) 
	Return cmGetCurrencyExchangeRate(pHotel, pFolioCurrency, pExchangeRateDate);
EndFunction // GetCurrencyExchangeRateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure GuestGroupOpeningAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmCreateGuestGroup();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // GuestGroupOpeningAtServer

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
&AtServer
Procedure FillGridAtServer()
	// Main table
	vPlan = new ValueTable();
	vPlan.Columns.Add("Resources",,NStr("en = 'Resource'; de = 'Ressourcen'; ru = 'Измерение'"));
	vPlan.Columns.Add("ResourceName");
	vPlan.Columns.Add("Sort");
    vPlan.Columns.Add("Total",,NStr("en = 'Total'; de = 'Total'; ru = 'Итого'"));
	// Get all periods
	vRoomRates = Object.RoomRates.Unload();
	vPeriods = vRoomRates.Copy(,"AccountingDate");
    // Add periods services
	vPeriodsServices = Object.Services.Unload(,"AccountingDate");
	For Each vId In vPeriodsServices Do
		If ValueIsFilled(vId.AccountingDate) Then
			vRowPeriod = vPeriods.Add();
			vRowPeriod.AccountingDate = vId.AccountingDate;
		EndIf;	
    EndDo;
    
    vRoomRates.Columns.Add("Price");
    vRoomRates.Columns.Add("Service");
    
    vCurDate = BegOfDay(Object.CheckInDate);
	While vCurDate <= BegOfDay(Object.CheckOutDate) Do
    	vColumnName = "Column_"+Format(vCurDate,"DF=yyyyMMdd");
		If vPlan.Columns.Find(vColumnName) = Undefined Then
			vPlan.Columns.Add(vColumnName,,Format(vCurDate,"DF='dd MMM'"));
        EndIf;	
        If vPeriods.Find(vCurDate) =  Undefined Then
            vRowPeriod = vPeriods.Add();
            vRowPeriod.AccountingDate = vCurDate;
        EndIf; 
		vCurDate = vCurDate + 24*3600;
	EndDo;
    
    vPeriods.GroupBy("AccountingDate");
    vPeriods.Sort("AccountingDate");

	// Fill
	vPrevRoomRates = New Structure("Room, RoomType, RoomRate, AccommodationTemplate, Adults, Children, Discount, Price");
	For Each vRowPeriod In vPeriods Do
		vCurDate = vRowPeriod.AccountingDate;
		// Add columns
		vColumnName = "Column_"+Format(vCurDate,"DF=yyyyMMdd");
		If vPlan.Columns.Find(vColumnName) = Undefined Then
			vPlan.Columns.Add(vColumnName,,Format(vCurDate,"DF='dd MMM'"));
		EndIf;	
		vCurRoomRatesRow = vRoomRates.Find(vCurDate, "AccountingDate");
		// Fill rows
		// Room	
		FillRowPan(vPlan, "Room", NStr("en = 'Room'; de = 'Zimmer'; ru = 'Номер'"),	vColumnName, 1, vPrevRoomRates.Room, 	?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.Room), 	   Object.Room);
		// Room type
		FillRowPan(vPlan, "RoomType", NStr("en = 'Room type'; de = 'Zimmertyp'; ru = 'Тип номера'"), vColumnName, 2, vPrevRoomRates.RoomType, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.RoomType), Object.RoomType);
		// Room rate
		FillRowPan(vPlan, "RoomRate", NStr("en = 'Room rate'; de = 'Tarif'; ru = 'Тариф'"), vColumnName, 3, vPrevRoomRates.RoomRate, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.RoomRate), Object.RoomRate);
		// Accommodation template
		FillRowPan(vPlan, "AccommodationTemplate", NStr("en = 'Accommodation template'; de = 'Unterkunft Vorlage'; ru = 'Шаблон размещения'"), vColumnName, 4, vPrevRoomRates.AccommodationTemplate, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.AccommodationTemplate), Object.AccommodationTemplate);
		// Adults
		FillRowPan(vPlan, "Adults", NStr("en = 'Adults'; de = 'Erwachsene'; ru = 'Взрослых'"), vColumnName, 5, vPrevRoomRates.Adults, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.NumberOfAdults), Object.NumberOfAdults);
		// Children
		FillRowPan(vPlan, "Children", NStr("en = 'Children'; de = 'Kinder'; ru = 'Детей'"), vColumnName, 6, vPrevRoomRates.Children, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.NumberOfTeenagers+vCurRoomRatesRow.NumberOfTeenagers+vCurRoomRatesRow.NumberOfInfants), Object.NumberOfChildren+Object.NumberOfInfants+Object.NumberOfTeenagers);
		// Discount
		FillRowPan(vPlan, "Discount", NStr("en = 'Discount %'; de = 'Preisnachlass %'; ru = 'Скидка %'"), vColumnName, 7, vPrevRoomRates.Discount, ?(vCurRoomRatesRow = Undefined, Undefined, vCurRoomRatesRow.Discount), Object.Discount);
	EndDo;
        
    If vPlan.Count() > 0 Then
        // Add prices
        vServicesTotals = New ValueTable;
        // Get totals
        FillPricesAndServices(Object, vPlan, vServicesTotals);
        // Totals by days
        vAccountingDateTotals = vServicesTotals.Copy();
		For Each vServicesTotalsRow In vAccountingDateTotals Do
			vService = vServicesTotalsRow.Service;
			If ValueIsFilled(vService) And TypeOf(vService) = Type("CatalogRef.Services") And  
			   ValueIsFilled(vService.QuantityCalculationRule) Then
				vAccountingDateMove = cmGetAccountingDateMove(vService.QuantityCalculationRule, False, Object, True);
				If vAccountingDateMove <> 0 Then
			        vServicesTotalsRow.AccountingDate = vServicesTotalsRow.AccountingDate - 24*3600;
				EndIf;
			EndIf;
		EndDo;
        vAccountingDateTotals.GroupBy("AccountingDate","Amount");
        vAccountingDateTotals.Sort("AccountingDate");
        
        vTotal = vServicesTotals.Total("Amount"); 
        
        // Add items to the form
        vParentGroup = Items.GroupGrid;
        vAccommadationPlanItem = Items.Find("AccommadationPlan");
        If Not vAccommadationPlanItem = Undefined Then
            Items.Delete(vAccommadationPlanItem);
            vDeleteArr = New Array;
            vDeleteArr.Add("AccommadationPlan");
            ThisForm.ChangeAttributes(,vDeleteArr);
        EndIf; 
        vArrTypes = New Array;
        vArrTypes.Add(Type("ValueTable"));
        vTypeDescription = New TypeDescription(vArrTypes);
        vArrAttributes = New Array;
        vTabName = "AccommadationPlan"; 
        vTabTitle = "AccommadationPlan";
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
        
        ThisForm.ChangeAttributes(vArrAttributes);      
        vTabForm = Items.Add(vTabTitle, Type("FormTable"), vParentGroup);
        vTabForm.DataPath = vTabName;
        vTabForm.Representation = TableRepresentation.List;
        vTabForm.CommandBarLocation = FormItemCommandBarLabelLocation.None;
        vTabForm.ChangeRowSet = False;    
        vTabForm.Footer = True;
        vTabForm.ChangeRowOrder = False;
        vTabForm.ChangeRowSet = False;
        
        vArrColumns = New Array;
        For Each vColumn In vPlan.Columns Do 
            If vColumn.Name = "Sort" Or vColumn.Name = "ResourceName" Then
                Continue;
            EndIf;	
            vNewItem = Items.Add(vColumn.Name, Type("FormField"), vTabForm);
            vNewItem.DataPath = vTabName + "." + vColumn.Name;
            vNewItem.FooterHorizontalAlign = ItemHorizontalLocation.Right;
            vNewItem.ShowInFooter = True;
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
                vStrDate = StrReplace(vColumn.Name, "Column_", "");
                vAccDate = Date(vStrDate);
                vRowTotal = vAccountingDateTotals.Find(vAccDate);
                If Not vRowTotal = Undefined Then
                    vNewItem.FooterText = cmFormatSum(vRowTotal.Amount, Object.ReportingCurrency, "NZ=0.00");
                EndIf; 
            EndIf; 
        EndDo;
        
        //  Add conditional appearance
        FillConditionalAppearance(vArrColumns, vServicesTotals);

        ThisForm.ValueToFormAttribute(vPlan, vTabName);
    EndIf;
    
EndProcedure

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
        vStrFilter.Name = "AccommadationPlan.ResourceName";
        vStrFilter.ComparisonType = DataCompositionComparisonType.Equal;
        vStrFilter.Value = String(vRow.Service);
        
        tcCommonFunctionOnClientServer.cmAddConditionalAppearance(ThisForm.ConditionalAppearance, vParams, vFilters, vArrColumns);
    EndDo;   
    
    vArrResource = New ValueList;
    vArrResource.Add("Room");
    vArrResource.Add("RoomType");
    vArrResource.Add("RoomRate");
    vArrResource.Add("AccommodationTemplate");
    vArrResource.Add("Adults");
    vArrResource.Add("Children");
    vArrResource.Add("Discount");
    vArrResource.Add("Price");
    
    // Set parameters
    vParams = New Structure;
    vParams.Insert("Font", New Font(,,True));
    
    // Set filter field
    vFilters = New ValueTable;
    vFilters.Columns.Add("Name");
    vFilters.Columns.Add("ComparisonType");
    vFilters.Columns.Add("Value");
    
    vStrFilter = vFilters.Add();
    vStrFilter.Name = "AccommadationPlan.ResourceName";
    vStrFilter.ComparisonType = DataCompositionComparisonType.InList;
    vStrFilter.Value = vArrResource;
    
    // Format fields
    vFields = New Array;
    vFields.Add("Resources");
    
    tcCommonFunctionOnClientServer.cmAddConditionalAppearance(ThisForm.ConditionalAppearance, vParams, vFilters, vFields);

EndProcedure // FillAccommodationPlan()

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure FillRowPan(pTabValue, pAttributeName, pAttributeDescription, pColumnName, pSort, pPrevValue, pCurValue, pStaticValue)
	vCurRow = pTabValue.Find(pAttributeName);
	If vCurRow = Undefined Then
		vCurRow = pTabValue.Add();
	EndIf;
	vCurRow.ResourceName = pAttributeName;
	vCurRow.Resources = pAttributeDescription;
	vCurRow.Sort = pSort;
	If pCurValue = Undefined Then
		If pPrevValue = Undefined Then
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
Procedure FillPricesAndServices(pObject, pPlan, pPrices = Undefined)
    pPrices = New  ValueTable();
    pPrices.Columns.Add("Amount");
    pPrices.Columns.Add("Service");
    pPrices.Columns.Add("Sort");
    pPrices.Columns.Add("AccountingDate");
    pPrices.Columns.Add("Quantity");
 	
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
        vNewRow = pPrices.Add();
        If vRow.IsInPrice Then
            vNewRow.Service = "Price";
            vNewRow.Sort = 0;
	        vNewRow.AccountingDate = vRow.AccountingDate;
        Else	
			vService = vRow.Service;
            vNewRow.Service = vService;
            vNewRow.Sort = 1;
            vNewRow.AccountingDate = vRow.AccountingDate;
			If ValueIsFilled(vService) And 
			   ValueIsFilled(vService.QuantityCalculationRule) Then
				vAccountingDateMove = cmGetAccountingDateMove(vService.QuantityCalculationRule, False, pObject, True);
				If vAccountingDateMove > 0 Then
		        	vNewRow.AccountingDate = vNewRow.AccountingDate + 24*3600;
				EndIf;
			EndIf;
        EndIf; 
        vNewRow.Quantity = vRow.Quantity;
        vNewRow.Amount = vRow.Sum;
    EndDo;
    pPrices.GroupBy("AccountingDate, Service, Sort", "Quantity, Amount");
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
    pPrices.Sort("Sort");
    vSort = 7;
    vCurService = Undefined;
    For Each vResultRow In pPrices Do
        vColumnName = "Column_"+Format(vResultRow.AccountingDate,"DF=yyyyMMdd");
        If pPlan.Columns.Find(vColumnName) = Undefined Then
            pPlan.Columns.Add(vColumnName,,Format(vResultRow.AccountingDate,"DF='dd MMM'"));
        EndIf;	
        vService = vResultRow.Service;
        If vService <> vCurService Then
            vSort  = vSort + 1;
        EndIf; 
        If vService = "Price" Then
            vDesc = NStr("en = 'Room price'; de = 'Preis für Übernachtung'; ru = 'Цена за проживание'");
            FillRowPan(pPlan, String(vService), vDesc, vColumnName, vSort, Undefined, cmFormatSum(vResultRow.Amount,pObject.ReportingCurrency, "NZ=0.00"), Undefined);
        Else   
            If IsBlankString(vService.DescriptionTranslations) Then
                vDesc = vService.Description;
            Else 
                vDesc = Nstr(vService.DescriptionTranslations);
                If IsBlankString(vDesc) Then
                    vDesc = vService.Description;
                EndIf;
            EndIf; 
            vAmount = String(vResultRow.Quantity)+ String(vService.Unit)+" = "+cmFormatSum(vResultRow.Amount,pObject.ReportingCurrency, "NZ=0.00");
            FillRowPan(pPlan, String(vService), vDesc, vColumnName, vSort, Undefined, vAmount, Undefined);
        EndIf; 
        
        vCurService = vService;
    EndDo;
    // Fill totals
    vPrceTotals = pPrices.Copy();
    vPrceTotals.GroupBy("Service","Amount");
    For Each vRowTotals In vPrceTotals Do
        vRow = pPlan.Find(String(vRowTotals.Service));
        If Not vRow = Undefined Then
            vRow.Total = cmFormatSum(vRowTotals.Amount, pObject.ReportingCurrency,"NZ=0.00");      	
        EndIf; 
    EndDo; 
EndProcedure

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
Function ShowClosedTasksAvailability()
	If ValueIsFilled(Object.Ref) Then
		Items.ShowClosedTasks.Visible = CheckClosedTasksAtServer(Object.Ref);
	Else
		Items.ShowClosedTasks.Visible = False;
	EndIf;
EndFunction // ShowClosedTasksAvailability

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckClosedTasksAtServer(pDocRef)
	vResult = False;
	If ValueIsFilled(pDocRef) Then
		vClosedMessages = cmGetMessagesForObject(pDocRef, True, , , , True);
		If vClosedMessages.Count() > 0 Then
			vResult = True;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // CheckClosedTasksAtServer

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

#EndRegion



