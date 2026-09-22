// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	WindowOptionsKey = ThisForm.UUID;
	If Parameters.Property("Owner") Then
		Owner = Parameters.Owner;	
	EndIf;
	If Parameters.Property("CheckInDate") Then
		CheckInDate = Parameters.CheckInDate;
		DateFrom = Parameters.CheckInDate;
		TimeFrom = Parameters.CheckInDate;
	EndIf;
	If Parameters.Property("CheckOutDate") Then
		CheckOutDate = Parameters.CheckOutDate;
		DateTo = Parameters.CheckOutDate;
		TimeTo = Parameters.CheckOutDate;
	EndIf;
	If Parameters.Property("RefList") Then
		RefList = Parameters.RefList;	
	EndIf;
	If Parameters.Property("RefListCount") Then
		RefListCount = Parameters.RefListCount;	
	EndIf;
	If Parameters.Property("ObjGroupRef") Then
		ObjGroupRef = Parameters.ObjGroupRef;	
	EndIf;
	If Parameters.Property("SelHotel") Then
		SelHotel = Parameters.SelHotel;	
	EndIf;
	If Parameters.Property("SelContract") Then
		SelContract = Parameters.SelContract;	
	EndIf;
	ChargingRuleFolioDescription = ?(ValueIsFilled(SelHotel), SelHotel.AdditionalServicesFolioCondition, SessionParameters.CurrentHotel.AdditionalServicesFolioCondition);
	If RefListCount > 0 Then
		ChangeMethod = False;
		NumberOfDocumentsToProcess = RefListCount;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Список документов пуст'; en='The list of documents is empty'; de='Die Dokumentliste ist leer'"));
		pCancel = True;
	EndIf;
	vNotAttributes = NotAttributes();
	For Each vRequisite In Metadata.Documents.Reservation.Attributes Do
		If vNotAttributes.Find(vRequisite.Name) = Undefined Then
			vAttribute = ExtraAttribute.Add();
			vAttribute.Name = vRequisite.Name;
			vAttribute.Type = vRequisite.Type;
			vAttribute.Presentation = vRequisite.Synonym;
			ExtraAttributeCheckName.Add(vRequisite.Name, , True);
		EndIf;
	EndDo;
	If vNotAttributes.Find("DoChargingToDate") = Undefined Then
		vAttribute = ExtraAttribute.Add();
		vAttribute.Name = "DoChargingToDate";
		vAttribute.Type = cmGetDateTypeDescription();
		vAttribute.Presentation = NStr("en='Do charging to date'; ru='Выполнять начисление услуг до даты'; de='Dienstleistungen bis Datum berechnen'");
		ExtraAttributeCheckName.Add("DoChargingToDate", , True);
	EndIf;
	ExtraAttribute.Sort("Name");
	ReservationStatusOnChangeAtServer();
	// Meal board terms
	vTerms = cmGetAllMealBoardTerms(SelHotel);
	If vTerms.Count() > 0 Then
		Items.ServicePackage.ChoiceList.LoadValues(vTerms.UnloadColumn("Ref"));
		Items.CheckServicePackage.Visible = True;
		Items.ServicePackage.Visible = True;
	Else
		Items.CheckServicePackage.Visible = False;
		Items.ServicePackage.Visible = False;
		CheckServicePackage = False;
	EndIf;
	// Beds setup availability
	vUseBedsSetup = GetBedsSetupFunctionalOption();
	Items.CheckBedsSetup.Visible = vUseBedsSetup;
	Items.BedsSetup.Visible = vUseBedsSetup;
	// Custom fields
	AddCustomFields();
	NumberExtra = New ValueList();
	NumberExtra.Add("1");
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure AddCustomFields()
	// Get list of custom fields
	vCustFields = cmGetListOfReservationCustomFields();
	// Create custom fields form attributes
	vCustAttrArray = New Array();
	vBooleanTypeDescription = cmGetBooleanTypeDescription();
	For Each vCustFieldsRow In vCustFields Do
		If Not vCustFieldsRow.IsFolder Then
			vCustAttrArray.Add(New FormAttribute("Check" + TrimAll(vCustFieldsRow.Code), vBooleanTypeDescription));
			vCustAttrArray.Add(New FormAttribute(TrimAll(vCustFieldsRow.Code), vCustFieldsRow.ValueType));
		EndIf;
	EndDo;		
	ChangeAttributes(vCustAttrArray);
	// Create form items
	For Each vCustFieldsRow In vCustFields Do
		If Not vCustFieldsRow.IsFolder Then
			vGroup = Items.Add("Group" + TrimAll(vCustFieldsRow.Code), Type("FormGroup"), Items.GroupBody);
			vGroup.Type = FormGroupType.UsualGroup;
			vGroup.Representation = UsualGroupRepresentation.None;
			vGroup.Behavior = UsualGroupBehavior.Usual;
			vGroup.ControlRepresentation = UsualGroupControlRepresentation.TitleHyperlink;
			vGroup.Group = ChildFormItemsGroup.HorizontalIfPossible;
			vGroup.United = False;
			vGroup.ShowTitle = False;
			
			vCheckField = Items.Add("Check" + TrimAll(vCustFieldsRow.Code), Type("FormField"), vGroup);
			vCheckField.DataPath = "Check" + TrimAll(vCustFieldsRow.Code);
			vCheckField.Type = FormFieldType.CheckBoxField;
			vCheckField.TitleLocation = FormItemTitleLocation.None;
			
			vField = Items.Add(TrimAll(vCustFieldsRow.Code), Type("FormField"), vGroup);
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
			CustomFieldsList.Add(vCustFieldsRow.Ref, TrimAll(vCustFieldsRow.Code));
		EndIf;
	EndDo;
EndProcedure // AddCustomFields

// -----------------------------------------------------------------------------
&AtServer
Function NotAttributes()
	vNotAttributes = New Array();
	vNotAttributes.Add("ParentDoc");
	vNotAttributes.Add("Hotel");
	vNotAttributes.Add("Customer");
	vNotAttributes.Add("Contract");
	vNotAttributes.Add("ReservationStatus");
	vNotAttributes.Add("AccommodationType");
	vNotAttributes.Add("RoomQuantity");
	vNotAttributes.Add("Room");
	vNotAttributes.Add("NumberOfBedsPerRoom");
	vNotAttributes.Add("NumberOfPersonsPerRoom");
	vNotAttributes.Add("NumberOfPersons");
	vNotAttributes.Add("NumberOfRooms");
	vNotAttributes.Add("NumberOfBeds");
	vNotAttributes.Add("NumberOfAdditionalBeds");
	vNotAttributes.Add("Guest");
	vNotAttributes.Add("GuestFullName");
	vNotAttributes.Add("RoomRate");
	vNotAttributes.Add("RoomRateType");
	vNotAttributes.Add("RoomRateServiceGroup");
	vNotAttributes.Add("DoCharging");
	vNotAttributes.Add("Agent");
	vNotAttributes.Add("AgentCommission");
	vNotAttributes.Add("AgentCommissionType");
	vNotAttributes.Add("AgentCommissionServiceGroup");
	vNotAttributes.Add("ReportingCurrency");
	vNotAttributes.Add("ReportingCurrencyExchangeRate");
	vNotAttributes.Add("PricePresentation");
	vNotAttributes.Add("ExternalCode");
	vNotAttributes.Add("Author");
	vNotAttributes.Add("AuthorOfAnnulation");
	vNotAttributes.Add("DateOfAnnulation");
	vNotAttributes.Add("AnnulationReason");
	vNotAttributes.Add("SortCode");
	vNotAttributes.Add("GuestAge");
	vNotAttributes.Add("GuestCitizenship");
	vNotAttributes.Add("NumberOfAdults");
	vNotAttributes.Add("NumberOfTeenagers");
	vNotAttributes.Add("NumberOfChildren");
	vNotAttributes.Add("NumberOfInfants");
	vNotAttributes.Add("RoomPropertiesDescriptions");
	vNotAttributes.Add("RoomPropertiesCodes");
	vNotAttributes.Add("AccommodationTemplate");
	vNotAttributes.Add("CheckInDate");
	vNotAttributes.Add("CheckOutDate");
	vNotAttributes.Add("Duration");
	vNotAttributes.Add("BoardPlace");
	vNotAttributes.Add("GuaranteeTypes");
	vNotAttributes.Add("ServicePackage");
	vNotAttributes.Add("SourceOfBusiness");
	vNotAttributes.Add("MarketingCode");
	vNotAttributes.Add("ClientType");
	vNotAttributes.Add("DiscountType");
	vNotAttributes.Add("TripPurpose");
	vNotAttributes.Add("RoomPrice");
	vNotAttributes.Add("GuestPrice");
	vNotAttributes.Add("BedsSetup");
	Return vNotAttributes;
EndFunction // NotAttributes

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackagesStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vSelectedPackages = New ValueList();
	For Each vSPRow In ServicePackages Do
		If ValueIsFilled(vSPRow.ServicePackage) Then
			vSelectedPackages.Add(New Structure("ServicePackage, Quantity, DateFrom, DateTo", vSPRow.ServicePackage, vSPRow.Quantity, vSPRow.DateFrom, vSPRow.DateTo));
		EndIf;
	EndDo;
	OpenForm("Catalog.ServicePackages.Form.tcChoiceFormWithPeriod", New Structure("Hotel, SelectedPackages, CheckInDate, CheckOutDate, MealBoardsAreUsed", Owner, vSelectedPackages, DateFrom, DateTo, Items.ServicePackage.Visible), ThisForm, , , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // ServicePackagesStartChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveServicePackagesListAtServer(pServicePackagesList)
	ServicePackages.Clear();
	If pServicePackagesList.Count() > 0 Then
		For Each vSPItem In pServicePackagesList Do
			If vSPItem.Check Then
				vSPRow = ServicePackages.Add();
				FillPropertyValues(vSPRow, vSPItem.Value);
			EndIf;
		EndDo;
		CheckServicePackages = True;
	EndIf;
	// Fill service packages presentation
	FillServicePackagesPresentation();
EndProcedure // SaveServicePackagesListAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillServicePackagesPresentation()
	// Service packages
	TServicePackagesPresentation = "";
	For Each vServicePackageRow In ServicePackages Do
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
&AtClient
Procedure RoomPriceOnChange(pItem)
	If ValueIsFilled(RoomPrice) Then
		CheckRoomPrice = True;
	Else
		CheckRoomPrice = False;	
	EndIf;
EndProcedure // RoomPriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestPriceOnChange(pItem)
	If ValueIsFilled(GuestPrice) Then
		CheckGuestPrice = True;
	Else
		CheckGuestPrice = False;	
	EndIf;
EndProcedure // GuestPriceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomRateOnChange(pItem)
	If ValueIsFilled(RoomRate) Then
		CheckRoomRate = True;
	Else
		CheckRoomRate = False;	
	EndIf;
EndProcedure // RoomRateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(pItem)
	If ValueIsFilled(DiscountType) Then
		CheckDiscountType = True;
	Else
		CheckDiscountType = False;	
	EndIf;
EndProcedure // DiscountTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure MarketingCodeOnChange(pItem)
	If ValueIsFilled(MarketingCode) Then
		CheckMarketingCode = True;
	Else
		CheckMarketingCode = False;	
	EndIf;
EndProcedure // MarketingCodeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SourceOfBusinessOnChange(pItem)
	If ValueIsFilled(SourceOfBusiness) Then
		CheckSourceOfBusiness = True;
	Else
		CheckSourceOfBusiness = False;	
	EndIf;
EndProcedure // SourceOfBusinessOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TripPurposeOnChange(pItem)
	If ValueIsFilled(TripPurpose) Then
		CheckTripPurpose = True;
	Else
		CheckTripPurpose = False;	
	EndIf;
EndProcedure // TripPurposeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BoardPlaceOnChange(pItem)
	If ValueIsFilled(BoardPlace) Then
		CheckBoardPlace = True;
	Else
		CheckBoardPlace = False;	
	EndIf;
EndProcedure // BoardPlaceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestOnChange(pItem)
	If ValueIsFilled(Guest) Then
		CheckGuest = True;
	Else
		CheckGuest = False;	
	EndIf;
EndProcedure // GuestOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(Guest) Then
		vSelLastName = tcOnServer.cmGetAttributeByRef(Guest, "LastName");
		vSelFirstName = tcOnServer.cmGetAttributeByRef(Guest, "FirstName");
		vSelSecondName = tcOnServer.cmGetAttributeByRef(Guest, "SecondName");
	Else
		vSelLastName = "";
		vSelFirstName = "";
		vSelSecondName = "";	
	EndIf;
	vParams = New Structure("ChoiceMode, SelLastName, SelFirstName, SelSecondName", True, vSelLastName, vSelFirstName, vSelSecondName);
	OpenForm("Catalog.Clients.ChoiceForm", vParams, pItem, UUID);  
EndProcedure // GuestStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	If ValueIsFilled(ClientType) Then
		CheckClientType = True;
	Else
		CheckClientType = False;	
	EndIf;
EndProcedure // ClientTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AgentCommissionOnChange(pItem)
	If ValueIsFilled(AgentCommission) Then
		CheckAgentCommission = True;
	Else
		CheckAgentCommission = False;	
	EndIf;
EndProcedure // AgentCommissionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ReservationStatusOnChange(pItem)
	If ValueIsFilled(ReservationStatus) Then
		CheckReservationStatus = True;
	Else
		CheckReservationStatus = False;
		AnnulationReason = Undefined;
		Items.AnnulationReason.Visible = False;
	EndIf;
	vIsNeedToOpenForm = ReservationStatusOnChangeAtServer();
	If vIsNeedToOpenForm Then
		OpenForm("Catalog.UsualActionReasons.ChoiceForm", , ThisForm, , , , New NotifyDescription("CheckCloseOfUsualActionReasons",ThisForm));
	Else
		AnnulationReason = Undefined;
		Items.AnnulationReason.Visible = False;
	EndIf;
EndProcedure // ReservationStatusOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckCloseOfUsualActionReasons(pResult, pExtraParams) Export 
	If Not ValueIsFilled(AnnulationReason) And Not ValueIsFilled(pResult) Then
		ReservationStatus = Undefined;
		CheckReservationStatus = False;
		ShowMessageBox(, NStr("en='Annulation reason should be filled!'; ru='Причина аннуляции должна быть указана!'; de='Stornogrund gefüllt werden sollten!'"));
	EndIf;			
EndProcedure // CheckCloseOfUsualActionReasons

// -----------------------------------------------------------------------------
&AtServer
Function ReservationStatusOnChangeAtServer()
	// Update services
	If ValueIsFilled(ReservationStatus) Then
		// Guarantee type
		If ValueIsFilled(ReservationStatus.GuaranteeType) Then
			GuaranteeType = ReservationStatus.GuaranteeType;
		EndIf;
		// Ask for annulation reason
		If ReservationStatus.IsAnnulation Then
			If Not ValueIsFilled(AnnulationReason) Then
				Return True;
			EndIf;
		Else
			AnnulationReason = Undefined;
			Items.AnnulationReason.Visible = False;
		EndIf;
		CheckReservationStatus = True;
	Else
		CheckReservationStatus = False;
	EndIf;
	// Refill status choice list
	FillReservationStatusListChoice();
	// Return
	Return False;
EndFunction // ReservationStatusOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillReservationStatusListChoice()
	vRef = ObjGroupRef.ClientDoc;
	If TypeOf(vRef) <> Type("DocumentRef.Reservation") Then 
		vRef = Undefined;
	EndIf;
	vTransitionsAllowed = New ValueList();
	If ValueIsFilled(ReservationStatus) Then
		vTransitionsAllowed.LoadValues(ReservationStatus.TransitionsAllowed.UnloadColumn("ReservationStatus"));
	EndIf;
	Items.ReservationStatus.ChoiceList.Clear();
	vReservationStatusesArray = New Array;
	If ValueIsFilled(tcOnServer.cmGetCurrentUserAttribute("Customer")) And ValueIsFilled(vRef) Then
		vReservationStatusesArray.Add(tcOnServer.cmGetCurrentHotelAttribute("NewReservationStatus"));
		vReservationStatusesArray.Add(GetReservationAnnulationStatus(vRef));
	Else
		vReservationStatusesArray = GetAllReservationStatuses();
		i = 0;
		While i < vReservationStatusesArray.Count() Do
			vReservationStatus = vReservationStatusesArray.Get(i);
			If vReservationStatus.IsCheckIn Then
				vReservationStatusesArray.Delete(i);
			ElsIf vReservationStatus.DoNotCreateReservationsInBlock Then
				vReservationStatusesArray.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
	EndIf;
	If vTransitionsAllowed.Count() > 0 Then
		For Each vReservationStatus In vReservationStatusesArray Do
			If vTransitionsAllowed.FindByValue(vReservationStatus) <> Undefined Then
				Items.ReservationStatus.ChoiceList.Add(vReservationStatus, , , GetReservationStatusIcon(vReservationStatus));
			EndIf;
		EndDo;
	Else
		For Each vReservationStatus In vReservationStatusesArray Do
			Items.ReservationStatus.ChoiceList.Add(vReservationStatus, , , GetReservationStatusIcon(vReservationStatus));
		EndDo;
	EndIf;
	If ValueIsFilled(ReservationStatus) And Items.ReservationStatus.ChoiceList.FindByValue(ReservationStatus) = Undefined Then
		Items.ReservationStatus.ChoiceList.Add(ReservationStatus, , , GetReservationStatusIcon(ReservationStatus));
	EndIf;
EndProcedure // FillReservationStatusListChoice

// -----------------------------------------------------------------------------
&AtServer
Function GetReservationAnnulationStatus(pRef)
	Return cmGetReservationAnnulationStatus(pRef);
EndFunction // GetReservationAnnulationStatus

// -----------------------------------------------------------------------------
&AtServer
Function GetAllReservationStatuses()
	vReservationStatusesArray = New Array;
	vResStses = cmGetAllReservationStatuses();
	For Each vResSts In vResStses Do
		// Fill choice array
		vReservationStatusesArray.Add(vResSts.ReservationStatus);
	EndDo;
	// Return
	Return vReservationStatusesArray;
EndFunction // GetAllReservationStatuses

// -----------------------------------------------------------------------------
&AtServer
Function GetReservationStatusIcon(pReservationStatus)
	vPicture = PictureLib.Empty;
	If ValueIsFilled(pReservationStatus) Then
		If pReservationStatus.IsActive Then
			If pReservationStatus.IsGuaranteed Then
				vPicture = PictureLib.IsGuaranteed;
			Else
				vPicture = PictureLib.IsActive;
			EndIf;
		ElsIf pReservationStatus.IsCheckIn Then
			vPicture = PictureLib.IsCheckIn;
		ElsIf pReservationStatus.IsNoShow Then
			vPicture = PictureLib.IsNoShow;
		ElsIf pReservationStatus.IsPreliminary Then
			vPicture = PictureLib.IsPreliminary;
		ElsIf pReservationStatus.IsInWaitingList Then
			vPicture = PictureLib.Waiting;
		Else
			vPicture = PictureLib.IsNotActive;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // GetReservationStatusIcon

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckDateOnChange(pItem)
	If TypeOf(ObjStatus) = Type("CatalogRef.ReservationStatuses") And 
		Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditReservations") Then
		CheckDate = False;
		ShowMessageBox(,"en = 'You have no rights'; de = 'Sie haben keine Rechte'; ru = 'Нет прав'");
	ElsIf TypeOf(ObjStatus) = Type("CatalogRef.AccommodationStatuses") Then
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditAccommodations") Then
			CheckDate = False;
			ShowMessageBox(,"en = 'You have no rights'; de = 'Sie haben keine Rechte'; ru = 'Нет прав'");
		EndIf;
	EndIf;
	If (BegOfDay(DateFrom) + (TimeFrom - BegOfDay(TimeFrom))) >= (BegOfDay(DateTo) + (TimeTo - BegOfDay(TimeTo)))  Then
		CheckDate = False;
		ShowMessageBox(,NStr("en = 'Check-out time should be longer than check in time'; de = 'Räumungszeit soll länger dauern'; ru = 'Время выселения должно быть больше времени заселения'"));
	EndIf;
EndProcedure 

// -----------------------------------------------------------------------------
&AtClient
Procedure DateFromOnChange(pItem)
	If ValueIsFilled(DateFrom) And ValueIsFilled(TimeFrom) And ValueIsFilled(DateTo) And ValueIsFilled(TimeTo) Then
		CheckDate = True;
		CheckDateOnChange(Items.CheckDate);
	Else
		CheckDate = False;	
	EndIf;
EndProcedure // DateFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TimeFromOnChange(pItem)
	If ValueIsFilled(DateFrom) And ValueIsFilled(TimeFrom) And ValueIsFilled(DateTo) And ValueIsFilled(TimeTo) Then
		CheckDate = True;
		CheckDateOnChange(Items.CheckDate);
	Else
		CheckDate = False;	
	EndIf;
EndProcedure // TimeFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure DateToOnChange(pItem)
	If ValueIsFilled(DateFrom) And ValueIsFilled(TimeFrom) And ValueIsFilled(DateTo) And ValueIsFilled(TimeTo) Then
		CheckDate = True;
		CheckDateOnChange(Items.CheckDate);
	Else
		CheckDate = False;	
	EndIf;
EndProcedure // DateToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure TimeToOnChange(pItem)
	If ValueIsFilled(DateFrom) And ValueIsFilled(TimeFrom) And ValueIsFilled(DateTo) And ValueIsFilled(TimeTo) Then
		CheckDate = True;
		CheckDateOnChange(Items.CheckDate);
	Else
		CheckDate = False;	
	EndIf;
EndProcedure // TimeToOnChange

#Region Background_job

// -----------------------------------------------------------------------------
&AtClient
Procedure StartProlongedOperation(pFunctionName, pOperationName, pOperationParametrs = Undefined)	
	BlockForm_ShowProgressBar();
	Items.BackgroundOperationProgress.Title	= NStr("en = 'Background operation in progress, you can continue to work in other forms  - '; ru = 'Выполняется фоновая операция, можете продолжать работать в других формах  - '; de = 'Die Hintergrundoperation läuft, Sie können weiterhin in anderen Formen arbeiten - '") + NStr(pOperationName);
	vBackgroundJob = StartBackgroundJob(pOperationName, pFunctionName, pOperationParametrs);
	CurrentBackgroundJobUUID = vBackgroundJob.UUID;
	AttachIdleHandler("Attachable_CheckBackgroundJobs",1,False);
EndProcedure // StartProlongedOperation

// -----------------------------------------------------------------------------
&AtServer                               
Function StartBackgroundJob(pOperationName, pProcedureName, pProcedureParametrs = Undefined, pTempStorageAddress = Undefined)
	ListOfMessages.Clear();
	Return AsyncCalls.StartBackgroundJobWithRecordInRegister(ObjGroupRef, pOperationName, pProcedureName, pProcedureParametrs, , , pTempStorageAddress);	
EndFunction // StartBackgroundJob

// -----------------------------------------------------------------------------
&AtClient
Procedure Attachable_CheckBackgroundJobs()
	vBackgroundJob 				= CheckBackgroundJobStatus(CurrentBackgroundJobUUID);            
	BackgroundOperationProgress = vBackgroundJob.Progress; 
	
	For each msg in vBackgroundJob.Messages Do
		If ListOfMessages.FindByValue(msg) = Undefined then
			ListOfMessages.Add(msg);
			tcCommonFunctionOnClientServer.TextMessage(msg);
		EndIf;
	EndDo;
	
	If vBackgroundJob.Status = "Error" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Error in background job: '; ru = 'Ошибка выполнения фонового задания: '; de = 'Fehler beim Ausführen des Hintergrundjobs: '") + vBackgroundJob.Error);
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Canceled" Then 
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Background job - canceled.'; ru = 'Фоновое задание - отменено.'; de = 'Hintergrundjob - abgebrochen.'"));
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		UnlockForm_HideProgressBar();
	ElsIf vBackgroundJob.Status = "Completed" Then
		DetachIdleHandler("Attachable_CheckBackgroundJobs");
		tcOnServer.Wait(1);
		UnlockForm_HideProgressBar();
		Notify("Document.Reservation.Write", ObjGroupRef);
	EndIf;
EndProcedure // Attachable_CheckBackgroundJobs

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction // CheckBackgroundJobStatus
#EndRegion

#Region Background_Operations

// -----------------------------------------------------------------------------
&AtClient
Procedure BlockForm_ShowProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = True;
	ThisForm.ReadOnly = True;
	Items.FormActionExecute.Enabled = False;
EndProcedure	

// -----------------------------------------------------------------------------
&AtClient
Procedure UnlockForm_HideProgressBar()
	BackgroundOperationProgress = 0;
	Items.BackgroundOperationProgress.Visible = False;
	ThisForm.ReadOnly = False;
	Items.FormActionExecute.Enabled = True;
EndProcedure

#EndRegion

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionExecute(pCommand)
	vRefList = New ValueList();
	For Each vRef In RefList Do
		If ChangeMethod Then
			vRefList.Add(vRef.Value, vRef.Presentation);
		Else
			If vRef.Check Then
				vRefList.Add(vRef.Value, vRef.Presentation);
			EndIf;
		EndIf;
	EndDo;
	vCheckAttribute = GetCheckAttribute();
	vValueAttribute = GetValueAttribute();
	If vValueAttribute = Undefined Then
		Return;	
	EndIf;
	vOperationParametrs = New Array;
	vOperationParametrs.Add(vRefList);
	vOperationParametrs.Add(vCheckAttribute);
	vOperationParametrs.Add(vValueAttribute);
	vOperationParametrs.Add(CustomFieldsList);
	
	StartProlongedOperation("ProlongedOperations.GuestGroups_SetAllAttributes", "en = 'Update document attributes'; ru = 'Изменение реквизитов документов'; de = 'Ändern der Details von Dokumenten'", vOperationParametrs);
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetCheckAttribute()
	vCheckAll = New Structure();
	vCheckAll.Insert("RoomPrice",?(CheckRoomPrice, True, False));
	vCheckAll.Insert("GuestPrice",?(CheckGuestPrice, True, False));
	vCheckAll.Insert("RoomRate",?(ValueIsFilled(RoomRate) And CheckRoomRate, True, False));
	vCheckAll.Insert("ServicePackage",?(CheckServicePackage, True, False));
	vCheckAll.Insert("ServicePackages",?(CheckServicePackages, True, False));
	vCheckAll.Insert("DiscountType",?(CheckDiscountType, True, False));
	vCheckAll.Insert("MarketingCode",?(CheckMarketingCode, True, False));
	vCheckAll.Insert("SourceOfBusiness",?(CheckSourceOfBusiness, True, False));
	vCheckAll.Insert("TripPurpose",?(CheckTripPurpose, True, False));
	vCheckAll.Insert("BoardPlace",?(CheckBoardPlace, True, False));
	vCheckAll.Insert("Guest",?(CheckGuest, True, False));
	vCheckAll.Insert("ClientType",?(CheckClientType, True, False));
	vCheckAll.Insert("AgentCommission",?(CheckAgentCommission, True, False));
	vCheckAll.Insert("ReservationStatus",?(ValueIsFilled(ReservationStatus) And CheckReservationStatus, True, False));
	vCheckAll.Insert("GuaranteeTypes",?(CheckGuaranteeTypes, True, False));
	vCheckAll.Insert("Date",?(CheckDate, True, False));
	vCheckAll.Insert("FixedCharges",?(CheckFixedCharges, ValueIsFilled(FixedChargesCopyFrom), False));
	vCheckAll.Insert("ChargingRules",?(CheckChargingRules, ValueIsFilled(ChargingRuleValue), False));
	vCheckAll.Insert("BedsSetup",?(CheckBedsSetup, True, False));
	For Each vRow In CustomFieldsList Do
		vCheckAll.Insert("Check" + TrimAll(vRow.Value.Code), ?(ThisObject["Check" + TrimAll(vRow.Value.Code)], True, False));	
	EndDo;
	vCheckAll.Insert("Extra",?(CheckExtra, True, False));
	Return vCheckAll;
EndFunction // GetCheckAttribute

// -----------------------------------------------------------------------------
&AtServer
Function GetValueAttribute()
	vServicePackagesList = New ValueList();
	For Each vServicePackagesRow In ServicePackages Do
		vServicePackagesList.Add(New Structure("ServicePackage, Quantity, DateFrom, DateTo", vServicePackagesRow.ServicePackage, vServicePackagesRow.Quantity, vServicePackagesRow.DateFrom, vServicePackagesRow.DateTo));
	EndDo;
	vExtraArray = New Array();
	vCheckValueIsFilled = True;
	For Each vNumber In NumberExtra Do
		If Not ValueIsFilled(ThisForm["NameAttributes" + vNumber.Value]) Then
			vCheckValueIsFilled = False;
			Break;
		Else
			vExtraArray.Add(New Structure("Name, Value",ThisForm["NameAttributes" + vNumber.Value], ThisForm["ArbitraryAttribute" + vNumber.Value]));
		EndIf;
	EndDo;
	If Not vCheckValueIsFilled And CheckExtra Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не все дополнительные поля заполнены';en='Not all additional fields are filled in';de='Nicht alle zusätzlichen Felder sind ausgefüllt'"));
		Return Undefined;
	EndIf;
	vValueAll = New Structure();
	vValueAll.Insert("RoomPrice", RoomPrice);
	vValueAll.Insert("GuestPrice", GuestPrice);
	vValueAll.Insert("RoomRate", New Structure("RoomRate, AccountingDate", RoomRate, RoomRateAccountingDate));
	vValueAll.Insert("ServicePackage", ServicePackage);
	vValueAll.Insert("ServicePackages", New Structure("TermsAreUsed, ServicePackages, ModificationMode", Items.ServicePackage.Visible, vServicePackagesList, ServicePackagesModificationMode));
	vValueAll.Insert("DiscountType", ?(ValueIsFilled(DiscountType), DiscountType, PredefinedValue("Catalog.DiscountTypes.EmptyRef")));
	vValueAll.Insert("MarketingCode", MarketingCode);
	vValueAll.Insert("SourceOfBusiness", SourceOfBusiness);
	vValueAll.Insert("TripPurpose", TripPurpose);
	vValueAll.Insert("BoardPlace", New Structure("BoardPlace, AccountingDate", BoardPlace, BoardPlaceAccountingDate));
	vValueAll.Insert("Guest", Guest);
	vValueAll.Insert("ClientType", ClientType);
	vValueAll.Insert("AgentCommission", AgentCommission);
	vValueAll.Insert("ReservationStatus", ReservationStatus);
	vValueAll.Insert("GuaranteeTypes", GuaranteeType);
	vValueAll.Insert("Date", New Structure("CheckInDate, CheckOutDate", (BegOfDay(DateFrom) + (TimeFrom - BegOfDay(TimeFrom))), (BegOfDay(DateTo) + (TimeTo - BegOfDay(TimeTo)))));
	vValueAll.Insert("FixedCharges", New Structure("FixedChargesCopyFrom, ModificationMode", FixedChargesCopyFrom, FixedChargesModificationMode));
	vValueAll.Insert("ChargingRules", New Structure("ChargingRule, ChargingRuleValue, ValidFromDate, ValidToDate, FolioDescription, ChargingRuleFolio", ChargingRule, ChargingRuleValue, ChargingRuleValidFromDate, ChargingRuleValidToDate, ChargingRuleFolioDescription, ChargingRuleFolio));
	vValueAll.Insert("BedsSetup", BedsSetup);
	For Each vRow In CustomFieldsList Do
		vValueAll.Insert(TrimAll(vRow.Value.Code), ThisObject[TrimAll(vRow.Value.Code)]);	
	EndDo;
	vValueAll.Insert("Extra", vExtraArray);
	vValueAll.Insert("AnnulationReason", AnnulationReason);
	Return vValueAll;
EndFunction // GetValueAttribute

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckReservationStatusOnChange(pItem)
	If Not ValueIsFilled(ReservationStatus)Then
		CheckReservationStatus = False;	
	EndIf;
EndProcedure // CheckReservationStatusOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckRoomRateOnChange(pItem)
	If Not ValueIsFilled(RoomRate)Then
		CheckRoomRate = False;	
	EndIf;
EndProcedure // CheckReservationStatusOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckFixedChargesOnChange(pItem)
	If Not ValueIsFilled(FixedChargesCopyFrom) Then
		CheckFixedCharges = False;	
	EndIf;
EndProcedure // CheckFixedChargesOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FixedChargesCopyFromOnChange(pItem)
	If Not ValueIsFilled(FixedChargesCopyFrom) Then
		CheckFixedCharges = False;	
	EndIf;
EndProcedure // FixedChargesCopyFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure GuaranteeTypesOnChange(pItem)
	If ValueIsFilled(GuaranteeType) Then
		CheckGuaranteeTypes = True;
	Else
		CheckGuaranteeTypes = False;	
	EndIf;
	GuaranteeTypeOnChangeAtServer();
EndProcedure // GuaranteeTypesOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure GuaranteeTypeOnChangeAtServer()
	vDoSearch = False;
	vIsGuaranteed = True;
	vIsFullyPaid = False;
	If ValueIsFilled(GuaranteeType) Then
		If ValueIsFilled(ReservationStatus) And ReservationStatus.IsGuaranteed Then
			If GuaranteeType.IsFullyPaid And Not ReservationStatus.IsFullyPaid Then
				vDoSearch = True;
				vIsGuaranteed = True;
				vIsFullyPaid = True;
			ElsIf Not GuaranteeType.IsFullyPaid And ReservationStatus.IsFullyPaid Then
				vDoSearch = True;
				vIsGuaranteed = True;
				vIsFullyPaid = False;
			EndIf;
		Else
			If GuaranteeType.IsFullyPaid Then
				vDoSearch = True;
				vIsGuaranteed = True;
				vIsFullyPaid = True;
			Else
				vDoSearch = True;
				vIsGuaranteed = True;
				vIsFullyPaid = False;
			EndIf;
		EndIf;
	EndIf;
	If vDoSearch Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ReservationStatuses.Ref AS Ref
		|FROM
		|	Catalog.ReservationStatuses AS ReservationStatuses
		|WHERE
		|	ReservationStatuses.IsGuaranteed = &qIsGuaranteed
		|	AND ReservationStatuses.IsFullyPaid = &qIsFullyPaid
		|	AND (ReservationStatuses.IsActive
		|			OR ReservationStatuses.IsPreliminary)
		|	AND NOT ReservationStatuses.DeletionMark
		|	AND NOT ReservationStatuses.IsFolder
		|
		|ORDER BY
		|	ReservationStatuses.SortCode,
		|	ReservationStatuses.Code";
		vQry.SetParameter("qIsGuaranteed", vIsGuaranteed);
		vQry.SetParameter("qIsFullyPaid", vIsFullyPaid);
		vStatuses = vQry.Execute().Unload();
		If vStatuses.Count() > 0 Then
			ReservationStatus = vStatuses.Get(0).Ref;
			ReservationStatusOnChangeAtServer();
		EndIf;
	EndIf;
EndProcedure // GuaranteeTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckExtraOnChange(pItem)
	For Each vNumber In NumberExtra Do
		If Not ValueIsFilled(ThisForm["NameAttributes" + vNumber.Value]) Then
			CheckRoomRate = False;
			Break;
		EndIf;
	EndDo;
EndProcedure // CheckExtraOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceProcessing(pSelectedValue, pChoiceSource)
	If TypeOf(pSelectedValue) = Type("CatalogRef.UsualActionReasons") Then
		If ValueIsFilled(pSelectedValue) Then
			AnnulationReason = pSelectedValue;
			Items.AnnulationReason.Visible = True;
		EndIf;
		If Not ValueIsFilled(AnnulationReason) Then
			ReservationStatus = Undefined;
			CheckReservationStatus = False;
			ShowMessageBox(, NStr("en='Annulation reason should be filled!'; ru='Причина аннуляции должна быть указана!'; de='Stornogrund gefüllt werden sollten!'"));
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AnnulationReasonOnChange(pItem)
		If Not ValueIsFilled(AnnulationReason) Then
			ReservationStatus = Undefined;
			CheckReservationStatus = False;
			ShowMessageBox(, NStr("en='Annulation reason should be filled!'; ru='Причина аннуляции должна быть указана!'; de='Stornogrund gefüllt werden sollten!'"));
		EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackageOnChange(pItem)
	If ValueIsFilled(ServicePackage) Then
		CheckServicePackage = True;	
	Else
		CheckServicePackage = False;	
	EndIf;
EndProcedure // ServicePackageOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ServicePackagesClearing(pItem, pStandardProcessing)
	ServicePackagesClearingAtServer(pStandardProcessing);
	RefreshDataRepresentation();
	CheckServicePackages = False;
EndProcedure // ServicePackagesClearing

// -----------------------------------------------------------------------------
&AtServer
Procedure ServicePackagesClearingAtServer(pStandardProcessing)
	ServicePackages.Clear();
	// Fill service packages presentation
	FillServicePackagesPresentation();
EndProcedure // ServicePackagesClearingAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AddExtraAttributes(pCommand)
	AddExtraAttributesAtServer();
EndProcedure // AddExtraAttributes

// -----------------------------------------------------------------------------
&AtServer
Procedure AddExtraAttributesAtServer()
	vQuantity = 0;
	For Each vRequisite In ExtraAttribute Do
		vCheckName = ExtraAttributeCheckName.FindByValue(vRequisite.Name);
		If vCheckName.Check Then 
			vQuantity = vQuantity + 1;
		EndIf;
	EndDo;
	If vQuantity = 0 Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Количество полей не может быть больше чем количество атрибутов';en='The number of fields cannot be greater than the number of attributes';de='Die Anzahl der Felder darf nicht größer sein als die Anzahl der Attribute'"));
		Return;
	EndIf;
	vCheckValueIsFilled = True;
	vLastNumberAttributes = 0;
	For Each vNumber In NumberExtra Do
		If Not ValueIsFilled(ThisForm["NameAttributes" + vNumber.Value]) Then
			vCheckValueIsFilled = False;
			Break;
		EndIf;
		vLastNumberAttributes = vLastNumberAttributes + 1;
	EndDo;
	If Not vCheckValueIsFilled Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не все дополнительные поля заполнены';en='Not all additional fields are filled in';de='Nicht alle zusätzlichen Felder sind ausgefüllt'"));
		Return;
	EndIf;
	vNewFormGroup = Items.Add("GroupExtraAttributes" + TrimAll(vLastNumberAttributes + 1), Type("FormGroup"), Items.GroupExtra);
	vNewFormGroup.Type = FormGroupType.UsualGroup;
	vNewFormGroup.Representation = UsualGroupRepresentation.None;
	vNewFormGroup.ShowTitle = False;
	vNewFormGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
	
	vAddAttributes = New Array();
	vNewNameAttributes = New FormAttribute("NameAttributes" + TrimAll(vLastNumberAttributes + 1), New TypeDescription("String"));
	vAddAttributes.Add(vNewNameAttributes); 
	vNewArbitraryAttribute = New FormAttribute("ArbitraryAttribute" + TrimAll(vLastNumberAttributes + 1), New TypeDescription(""));
	vAddAttributes.Add(vNewArbitraryAttribute);
	ThisForm.ChangeAttributes(vAddAttributes);
	
	vNewItems = Items.Add("NameAttributes" + TrimAll(vLastNumberAttributes + 1), Type("FormField"), vNewFormGroup);
	vNewItems.Type = FormFieldType.InputField;
	vNewItems.DataPath = "NameAttributes" + TrimAll(vLastNumberAttributes + 1);
	vNewItems.TitleLocation = FormItemTitleLocation.None;
	vNewItems.DropListButton = True;
	vNewItems.ListChoiceMode =  True;
	vNewItems.SetAction("StartChoice", "NameAttributesStartChoice");
	vNewItems.SetAction("OnChange", "AttributesToChangeOnChange");
	vNewItems = Items.Add("ArbitraryAttribute" + TrimAll(vLastNumberAttributes + 1), Type("FormField"), vNewFormGroup);
	vNewItems.Type = FormFieldType.InputField;
	vNewItems.DataPath = "ArbitraryAttribute" + TrimAll(vLastNumberAttributes + 1);
	vNewItems.Enabled = False;
	vNewItems.TitleLocation = FormItemTitleLocation.None;
	NumberExtra.Add(TrimAll(vLastNumberAttributes + 1));
EndProcedure // AddExtraAttributesAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure NameAttributesStartChoice(pItem, pChoiceData, pStandardProcessing)
	vName = StrReplace(pItem.Name, "NameAttributes","");
	vValue = ThisForm["NameAttributes" + vName];  
	Items[pItem.Name].ChoiceList.Clear();	
	For Each vRequisite In ExtraAttribute Do
		vCheckName = ExtraAttributeCheckName.FindByValue(vRequisite.Name);
		If vCheckName.Check Or vCheckName.Value = vValue Then 
			Items[pItem.Name].ChoiceList.Add(vRequisite.Name,vRequisite.Presentation);
		EndIf;
	EndDo;
	ThisForm["NameAttributes" + vName] = vValue;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AttributesToChangeOnChange(pItem)
	For Each vNameItem In ExtraAttributeCheckName Do
		vNameItem.Check = True;
		For Each vNumber In NumberExtra Do
			If vNameItem.Value = ThisForm["NameAttributes" + vNumber] Then  
				vNameItem.Check = False;
				Break;
			EndIf;				
		EndDo;
	EndDo;
	vName = StrReplace(pItem.Name, "NameAttributes","");
	If ValueIsFilled(ThisForm["NameAttributes" + vName]) Then
		CheckExtra = True;
		Items["ArbitraryAttribute" + vName].Enabled = True;
	Else
		CheckExtra = False;
		Items["ArbitraryAttribute" + vName].Enabled = False;
		Return;
	EndIf;
	vFindValueTable = ExtraAttribute.FindRows(new Structure("Name",ThisForm["NameAttributes" + vName]));
	Items["ArbitraryAttribute" + vName].TypeRestriction = vFindValueTable[0].Type;
EndProcedure // AttributesToChangeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeMethodOnChange(pItem)
	If ChangeMethod Then
		NumberOfDocumentsToProcess = RefList.Count();
	Else
		NumberOfDocumentsToProcess = RefListCount;
	EndIf;
EndProcedure // ChangeMethodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BeforeClose(pCancel, pExit, pMessageText, pStandardProcessing)
	If Not pExit Then
		If Items.BackgroundOperationProgress.Visible Then
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure // BeforeClose

// -----------------------------------------------------------------------------
&AtClient
Procedure RemoveExtraAttributes(pCommand)
	RemoveExtraAttributesAtServer();
EndProcedure // RemoveExtraAttributes

// -----------------------------------------------------------------------------
&AtServer
Procedure RemoveExtraAttributesAtServer()
	If NumberExtra.Count() > 1 Then 
		vLastNumberAttributes = NumberExtra.Get(NumberExtra.Count() - 1); 	
		Items.Delete(Items["NameAttributes" + TrimAll(vLastNumberAttributes)]);
		Items.Delete(Items["ArbitraryAttribute" + TrimAll(vLastNumberAttributes)]);
		Items.Delete(Items["GroupExtraAttributes" + TrimAll(vLastNumberAttributes)]);
		vAddAttributes = New Array();
		vAddAttributes.Add("NameAttributes" + TrimAll(vLastNumberAttributes)); 
		vAddAttributes.Add("ArbitraryAttribute" + TrimAll(vLastNumberAttributes));
		ThisForm.ChangeAttributes(,vAddAttributes);
		NumberExtra.Delete(vLastNumberAttributes);
	EndIf;
EndProcedure // RemoveExtraAttributesAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "ServicePackages.Changed" And pParameter <> Undefined And pSource = ThisForm Then
		SaveServicePackagesListAtServer(pParameter);
		RefreshDataRepresentation();
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRuleOnChange(pItem)
	SetChargingRuleValueType();
EndProcedure // ChargingRuleOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRuleValueOnChange(pItem)
	CheckChargingRules = ValueIsFilled(ChargingRuleValue);
EndProcedure // ChargingRuleValueOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SetChargingRuleValueType()
	Items.ChargingRuleValue.Enabled = False;
	Items.ChargingRuleValue.Title = NStr("en='Rule condition'; ru='Условие правила'; de='Regelbedingung'");
	If ValueIsFilled(ChargingRule) Then
		Items.ChargingRuleValue.ChooseType = False;
		If ChargingRule = Enums.ChargingRuleTypes.AllButOne Or
		   ChargingRule = Enums.ChargingRuleTypes.One Then
			If TypeOf(ChargingRuleValue) <> Type("CatalogRef.Services") Then
				ChargingRuleValue = Catalogs.Services.EmptyRef();
			EndIf;
			Items.ChargingRuleValue.Enabled = True;
			Items.ChargingRuleValue.Title = NStr("en='Service'; ru='Услуга'; de='Service'");
		ElsIf ChargingRule = Enums.ChargingRuleTypes.InServiceGroup Or
		      ChargingRule = Enums.ChargingRuleTypes.NotInServiceGroup Then
			If TypeOf(ChargingRuleValue) <> Type("CatalogRef.ServiceGroups") Then
				ChargingRuleValue = Catalogs.ServiceGroups.EmptyRef();
			EndIf;
			Items.ChargingRuleValue.Enabled = True;
			Items.ChargingRuleValue.Title = NStr("en='Service group'; ru='Набор услуг'; de='Service group'");
		ElsIf ChargingRule = Enums.ChargingRuleTypes.RestOfRoomRevenuePrice Or
		      ChargingRule = Enums.ChargingRuleTypes.RoomRevenueAmount Or
		      ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePrice Or 			     
		      ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePricePercent Then
			If TypeOf(ChargingRuleValue) <> Type("Number") Then
				ChargingRuleValue = 0;
			EndIf;
			If ChargingRule = Enums.ChargingRuleTypes.RestOfRoomRevenuePrice Then
				ChargingRuleValue = 0;
			Else
				Items.ChargingRuleValue.Enabled = True;
			EndIf;
			Items.ChargingRuleValue.Title = NStr("en='Amount'; ru='Сумма'; de='Betrag'");
		ElsIf ChargingRule = Enums.ChargingRuleTypes.RoomRevenuePriceByRoomType Then
			If TypeOf(ChargingRuleValue) <> Type("CatalogRef.RoomTypes") Then
				ChargingRuleValue = Catalogs.RoomTypes.EmptyRef();;
			EndIf;
			Items.ChargingRuleValue.Enabled = True;
			Items.ChargingRuleValue.Title = NStr("en='Room type'; ru='Тип номера'; de='Zimmertyp'");
		Else
			ChargingRuleValue = Undefined;
		EndIf;
	Else
		Items.ChargingRuleValue.ChooseType = True;
		ChargingRuleValue = Undefined;
	EndIf;
EndProcedure // SetChargingRuleValueType

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetFolioByNumberPart(pText, pHotel, pCompany)
	If Not IsBlankString(pText) Then
		If StrLen(TrimAll(pText)) < 12 Then
			vFolioNumber = cmGetDocumentNumberFromPresentation(TrimAll(pText), pHotel, pCompany);
		Else
			vFolioNumber = TrimAll(pText);
		EndIf;
		Return cmFindFolioByNumber(vFolioNumber, pHotel);
	Else
		Return Undefined;
	EndIf;
EndFunction // GetFolioByNumberPart

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRuleFolioTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	vFolio = GetFolioByNumberPart(pText, Owner, Undefined); 
	If ValueIsFilled(vFolio) Then
		pStandardProcessing = False;
		If pChoiceData = Undefined Then
			pChoiceData = New ValueList();
		EndIf;
		pChoiceData.Add(vFolio);
	EndIf;
EndProcedure // ChargingRuleFolioTextEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRuleFolioOnChange(pItem)
	If ValueIsFilled(ChargingRuleFolio) Then
		Items.ChargingRuleFolioDescription.Enabled = False;
	Else
		Items.ChargingRuleFolioDescription.Enabled = True;
	EndIf;
EndProcedure // ChargingRuleFolioOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure BedsSetupOnChange(pItem)
	If ValueIsFilled(BedsSetup) Then
		CheckBedsSetup = True;
	Else
		CheckBedsSetup = False;	
	EndIf;
EndProcedure // BedsSetupOnChange

// -----------------------------------------------------------------------------
&AtServer
Function GetBedsSetupFunctionalOption()
	vUseBedsSetups = False;
	If ValueIsFilled(Owner) Then
		vUseBedsSetups = GetFunctionalOption("BedsSetups", New Structure("Hotel", Owner));
	EndIf;
	Return vUseBedsSetups;
EndFunction // GetBedsSetupFunctionalOption
