
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Check hotel
	If Not ValueIsFilled(SelHotel) Then
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	// Initialize period
	SelPeriod = EndOfDay(CurrentSessionDate());
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	RefreshDisplay();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Check service registration schedule
	CheckServiceRegistrationSchedule();
	// Open registration form
	If Items.SelServiceGroup.Enabled = False Then
		AttachIdleHandler("OpenServiceRegistration", 1, True);
	EndIf;	
EndProcedure //OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Subsystem.Accounts.Changed" Then
		// Filter
		ApplyFilter();
	EndIf;
EndProcedure //NotificationProcessing

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
		// Get clients attached to the card
		rCardRef = Undefined;
		rCardType = Undefined;
		GetClientsByCard(vEventData.DeviceData, rCardRef, rCardType);
		vClientsValue = New ValueList();
		For Each ClientsRow In Clients Do
			vClientsValue.Add(ClientsRow,TrimAll(ClientsRow.Client) + NStr("en=', Service: ';ru=', Услуга: ';de=', Dienstleistung: '") + TrimAll(ClientsRow.Service));	
		EndDo;
		// Register service
		If ValueIsFilled(rCardType) And rCardType.DoServiceRegistrationWithoutChargesControl Then
			DoSpecialServiceRegistration(rCardRef, SelService);
		Else
			If Clients.Count() > 0 Then
				vClientsRow = Clients.Get(0);
				If Clients.Count() > 1 Then
					vClientsValue.ShowChooseItem(New NotifyDescription("ShowChoose",ThisForm),NStr("en='Choose service...';ru='Выберите услугу...';de='Wählen Sie die Dienstleistung...'"));
					If vClientsRow = Undefined Then
						Return;
					EndIf;
				Else
					DoServiceRegistration(vClientsRow, vClientsRow.Service, True);
				EndIf;
			EndIf;
		EndIf;
	ElsIf vEventData.DeviceType = "BarCodeScaner" Then
		// Parse scan data
		vCouponData = CellcmParseCouponBarCode(vEventData.DeviceData);
		// Get clients attached to the coupon
		GetClientsByCoupon(vCouponData);
		// Register service
		If Clients.Count() > 0 Then
			vClientsRow = Clients.Get(0);
			DoServiceRegistration(vClientsRow, vCouponData.Service, False);
		EndIf;
	EndIf;
EndProcedure //ExternalEvent


#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodOnChange(pItem)
	// Filter
	ApplyFilter();
EndProcedure //SelPeriodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelResourceOnChange(pItem)
	// Filter
	ApplyFilter();
EndProcedure // SelResourceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	// Filter
	ApplyFilter();
EndProcedure // SelGuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(pItem)
	// Filter
	ApplyFilter();
EndProcedure // SelRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFolioNumberOnChange(pItem)
	// Convert folio number to the full representation with prefix
	vFolioNumber = TrimAll(SelFolioNumber);
	If StrLen(TrimAll(SelFolioNumber)) < 12 Then
		vFolioNumber = CallcmGetDocumentNumberFromPresentation(vFolioNumber);
	EndIf;
	// Reset all other filters and restore folio number
	ResetFilter();
	SelFolioNumber = vFolioNumber;
	// Filter
	ApplyFilter();
EndProcedure //SelFolioNumberOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelServiceOnChange(pItem)
	ThisForm.Modified = False;
	// Filter
	ApplyFilter();
EndProcedure //SelServiceOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientStrOnChange(pItem)
	// Clear SelClient if description is not equal to the text entered
	If ValueIsFilled(SelClient) Then
		If TrimAll(SelClient) <> TrimAll(SelClientStr) Then
			SelClient = PredefinedValue("Catalog.Clients.EmptyRef");
		EndIf;
	EndIf;
	RefreshDisplay();
	// Filter
	ApplyFilter();
EndProcedure // SelClientStrOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientStrStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vFullName = ParseClientFullName(SelClientStr);
	OpenForm("Catalog.Clients.ChoiceForm", New Structure("ChoiceMode, SelLastName, SelFirstName, SelSecondName", True, vFullName.LastName, vFullName.FirstName, vFullName.SecondName), pItem);
EndProcedure //SelClientStrStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientStrOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If ValueIsFilled(SelClient) Then
		OpenForm("Catalog.Clients.Form.tcItemForm",New Structure("Basis",SelClient));
	EndIf;
EndProcedure //SelClientStrOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientStrChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	If ValueIsFilled(pSelectedValue) Then
		SelClientStr = TrimAll(pSelectedValue);
		SelClient = pSelectedValue;
	Else
		SelClientStr = "";
		SelClient = PredefinedValue("Catalog.Clients.EmptyRef");
	EndIf;
EndProcedure //SelClientStrChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	// Filter
	ApplyFilter();
EndProcedure //SelHotelOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelBoardPlaceOnChange(pItem)
	// Filter
	ApplyFilter();
EndProcedure //SelBoardPlaceOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelServiceGroupOnChange(pItem)
	ThisForm.Modified = False;
	// Filter
	ApplyFilter();
EndProcedure //SelServiceGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonResetSearchFilter(pCommand)
	// Reset all filters
	ResetFilter();
	// Filter
	ApplyFilter();
EndProcedure //ButtonResetSearchFilter

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionRefresh(pCommand)
	// Filter
	ApplyFilter();
EndProcedure //ActionRefresh

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionShowDetailedList(pCommand)
	If Items.FormActionShowDetailedList.Check = True Then
		Items.FormActionShowDetailedList.Check = False;
		SelShowClientsList = Not SelShowClientsList;
	Else
		Items.FormActionShowDetailedList.Check = True;
		SelShowClientsList = Not SelShowClientsList;		
	EndIf;
	RefreshDisplay();
	// Filter
	ApplyFilter();
EndProcedure //ActionShowDetailedList

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionShowListByDates(pCommand)
	 If Items.FormActionShowListByDates.Check = True Then
		Items.FormActionShowListByDates.Check = False;
		SelShowListByDates = Not SelShowListByDates;
	Else
		Items.FormActionShowListByDates.Check = True;
		SelShowListByDates = Not SelShowListByDates;		
	EndIf;
	RefreshDisplay();
	// Filter
	ApplyFilter();
EndProcedure //ActionShowListByDates

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenDocuments(pCommand)
	OpenForm("Document.ServiceRegistration.Form.tcListForm");
EndProcedure //OpenDocuments

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonChargeAndPay(pCommand)
	// APDEX
	vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
	vUUID = New UUID;
	APDEXPerformanceSystemOnClientServer.StartManualTimeIntervalMeasurement(vKeyOperation, vUUID);

	If ValueIsFilled(SelClient) Or ValueIsFilled(SelRoom) Then
		vDocument = QueryDocument();	
		If vDocument <> Undefined Then  
			vParametersStructure = New Structure("ObjectRef", vDocument);
			OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisForm, ThisForm.UUID);
			// APDEX
			APDEXPerformanceSystemOnClient.FinishManualTimeIntervalMeasurementNotGlobal(vUUID);
		ElsIf ValueIsFilled(SelClient) Then
			vParametersStructure = New Structure("ObjectRef", SelClient);
			OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisForm, ThisForm.UUID);
			// APDEX
			APDEXPerformanceSystemOnClient.FinishManualTimeIntervalMeasurementNotGlobal(vUUID);
		Else
			ShowMessageBox(,NStr("en='Client was not found!'; ru='Клиент не найден!'; de='Client wurde nicht gefunden!'"));
		EndIf;
	Else
		ShowMessageBox(, NStr("en='Please choose client or room!'; ru='Не выбраны ни клиент ни номер!'; de='Weder Kunde, noch Zimmer sind gewählt!'"));
	EndIf;
EndProcedure //ButtonChargeAndPay

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonRunReport(pCommand)
	pReportRef = GetReportRefAtServer();
	vManagedReportForm = Undefined;
	
	vReportObj = tcOnServer.cmGetAtributeAsArray(pReportRef);
	
	vParam = New Structure;
	vParam.Insert("ReportRef", 		pReportRef);
	vParam.Insert("Hotel", 			SelHotel);
	vParam.Insert("BoardPlace",		SelBoardPlace);
	vParam.Insert("Service",		SelService);
	vParam.Insert("ServiceGroup", 	SelServiceGroup);
	vParam.Insert("Room", 			SelRoom);
	vParam.Insert("PeriodFrom", 	BegOfDay(SelPeriod));
	vParam.Insert("PeriodTo", 		EndOfDay(SelPeriod));
	
	vParams = New Structure("FillingValues, GenerateOnOpen", vParam, True);

	If vReportObj.IsExternal Then
		vURL = GetURL(vReportObj.Report, "ExternalProcessingStorage"); 
		vName = ConnectExternalReport(vURL, StrReplace(tcOnServer.cmGetAttributeByRef(vReportObj.Report,"FileName"),".erf",""));
		
		OpenForm("ExternalReport." + vName + ".Form", vParams);
	Else	
		If vReportObj.Report = Undefined Then
			Raise Nstr("en = 'You must fill the handler in the report settings'; de = 'Sie müssen den Handler in den Berichteinstellungen ausfüllen'; ru = 'Необходимо заполнить обработчик в настройках отчета'");
		Else
			OpenForm("Report." + vReportObj.Report + ".Form", vParams);
		EndIf; 
	EndIf;	

EndProcedure //ButtonRunReport

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckServiceRegistrationSchedule()
	vCheckIdleHandler = CheckStartIdleHandler();
	If vCheckIdleHandler <> Undefined Then
		If vCheckIdleHandler Then
			AttachIdleHandler("CheckServiceRegistrationSchedule", 60);
		ElsIf Not CheckStartIdleHandler() And vCheckIdleHandler <> Undefined Then
			DetachIdleHandler("CheckServiceRegistrationSchedule");
		EndIf;
	EndIf;
	// Apply filter
	ApplyFilter();
EndProcedure //SetServiceRegistrationSchedule

// -----------------------------------------------------------------------------
&AtServer
Function CheckStartIdleHandler()
	vWstn = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vWstn) Then
		If ValueIsFilled(vWstn.BoardPlace) Then
			SelBoardPlace = vWstn.BoardPlace;
		EndIf;
		If vWstn.ServiceRegistrationSchedule.Count() > 0 Then
			vCurTime = '00010101' + (CurrentSessionDate() - BegOfDay(CurrentSessionDate()));
			For Each vScheduleRow In vWstn.ServiceRegistrationSchedule Do
				If vScheduleRow.TimeFrom <= vCurTime And vScheduleRow.TimeTo > vCurTime Then
					If ValueIsFilled(vScheduleRow.Service) Then
						SelService = vScheduleRow.Service;
					EndIf;
					If ValueIsFilled(vScheduleRow.ServiceGroup) Then
						SelServiceGroup = vScheduleRow.ServiceGroup;
					EndIf;
					Break;
				EndIf;
			EndDo;
			If Not cmCheckUserPermissions("HavePermissionToEditPostedFolioTransactions") Then
				Items.SelServiceGroup.Enabled = False;
			Else
				Items.SelServiceGroup.Enabled = True;
			EndIf;
			Return True;
		Else
			Items.SelServiceGroup.Enabled = True;
			Return False;
		EndIf;
	Else
		Items.SelServiceGroup.Enabled = True;
		Return False;
	EndIf;
EndFunction //CheckStartIdleHandler

// -----------------------------------------------------------------------------
&AtServer
Procedure ApplyFilter()
	// Build filter description
	BuildFilterDescription();
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT " + 
	?(SelShowListByDates, "ServiceRegistrationBalanceAndTurnovers.AccountingDate AS AccountingDate, ", "") + 
	?(SelShowClientsList, "ServiceRegistrationBalanceAndTurnovers.Client AS Client, ", "") + 
	?(SelShowClientsList, "ServiceRegistrationBalanceAndTurnovers.Room AS Room, ", "") +  
	?(SelShowClientsList, "ServiceRegistrationBalanceAndTurnovers.Resource AS Resource, ", "") + 
	?(SelShowClientsList, "ServiceRegistrationBalanceAndTurnovers.Folio.DateTimeFrom AS CheckInDate, ", "") + 
	?(SelShowClientsList, "ServiceRegistrationBalanceAndTurnovers.Folio.DateTimeTo AS CheckOutDate, ", "") + "
	|	ServiceRegistrationBalanceAndTurnovers.Service AS Service,
	|	ServiceRegistrationBalanceAndTurnovers.FolioCurrency AS FolioCurrency,
	|	ServiceRegistrationBalanceAndTurnovers.Hotel AS Hotel,
	|	CASE
	|		WHEN Hotel.CloseServiceRegistration THEN
	|			ISNULL(ServiceRegistrationBalanceAndTurnovers.SumReceipt, 0) - ISNULL(ServiceRegistrationBalanceAndTurnovers.SumExpense, 0)
	|		ELSE
	|			ServiceRegistrationBalanceAndTurnovers.SumClosingBalance
	|	END AS SumBalance,
	|	CASE
	|		WHEN Hotel.CloseServiceRegistration THEN
	|			ISNULL(ServiceRegistrationBalanceAndTurnovers.QuantityReceipt, 0) - ISNULL(ServiceRegistrationBalanceAndTurnovers.QuantityExpense, 0)
	|		ELSE
	|			ServiceRegistrationBalanceAndTurnovers.QuantityClosingBalance 
	|	END AS QuantityBalance,
	|	ServiceRegistrationBalanceAndTurnovers.SumReceipt AS SumReceipt,
	|	ServiceRegistrationBalanceAndTurnovers.QuantityReceipt AS QuantityReceipt,
	|	ServiceRegistrationBalanceAndTurnovers.SumExpense AS SumExpense,
	|	ServiceRegistrationBalanceAndTurnovers.QuantityExpense AS QuantityExpense
	|FROM
	|	AccumulationRegister.ServiceRegistration.BalanceAndTurnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			RegisterRecordsAndPeriodBoundaries,
	|			((Client = &qClient AND NOT &qClientIsEmpty)
	|				OR (Client.Description LIKE &qClientStr AND NOT &qClientStrIsEmpty)
	|				OR (&qClientIsEmpty AND &qClientStrIsEmpty))
	|				AND (Folio.Number = &qFolioNumber
	|					OR &qFolioNumberIsEmpty)
	|				AND (GuestGroup = &qGuestGroup
	|					OR &qGuestGroupIsEmpty)
	|				AND (Room IN HIERARCHY (&qRoom)
	|					OR &qRoomIsEmpty)
	|				AND (Resource IN HIERARCHY (&qResource)
	|					OR &qResourceIsEmpty)
	|				AND (Service IN HIERARCHY (&qService)
	|					OR &qServiceIsEmpty)
	|				AND (Service IN (&qServicesList)
	|					OR (NOT &qUseServicesList))
	|				AND Hotel = &qHotel
	|				AND BoardPlace = &qBoardPlace
	|				AND (ISNULL(Hotel.CloseServiceRegistration, FALSE) OR NOT ISNULL(Hotel.CloseServiceRegistration, FALSE) AND (Folio.DateTimeTo > &qBegOfYesterday OR Folio.DateTimeTo = &qEmptyDate))) AS ServiceRegistrationBalanceAndTurnovers
	|ORDER BY " + 
	?(SelShowListByDates, "AccountingDate, ", "") + 
	?(SelShowClientsList, "Client.Description, ", "") + 
	?(SelShowClientsList, "Room.SortCode, ", "") + 
	?(SelShowClientsList, "Resource.SortCode, ", "") + "
	|	FolioCurrency.SortCode,
	|	Service.SortCode,
	|	Service.Description";
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qBoardPlace", SelBoardPlace);
	vQry.SetParameter("qClient", SelClient);
	vQry.SetParameter("qClientIsEmpty", Not ValueIsFilled(SelClient));
	vQry.SetParameter("qClientStr", UPPER(TrimR(SelClientStr)) + "%");
	vQry.SetParameter("qClientStrIsEmpty", IsBlankString(SelClientStr));
	vQry.SetParameter("qFolioNumber", SelFolioNumber);
	vQry.SetParameter("qFolioNumberIsEmpty", IsBlankString(SelFolioNumber));
	vQry.SetParameter("qGuestGroup", SelGuestGroup);
	vQry.SetParameter("qGuestGroupIsEmpty", Not ValueIsFilled(SelGuestGroup));
	vQry.SetParameter("qRoom", SelRoom);
	vQry.SetParameter("qRoomIsEmpty", Not ValueIsFilled(SelRoom));
	vQry.SetParameter("qResource", SelResource);
	vQry.SetParameter("qResourceIsEmpty", Not ValueIsFilled(SelResource));
	If ValueIsFilled(SelServiceGroup) Then
		vQry.SetParameter("qService", Undefined);
		vQry.SetParameter("qServiceIsEmpty", True);
	Else
		vQry.SetParameter("qService", SelService);
		vQry.SetParameter("qServiceIsEmpty", Not ValueIsFilled(SelService));
	EndIf;
	vQry.SetParameter("qBegOfYesterday", BegOfDay(CurrentSessionDate()) - 24*3600);
	If ValueIsFilled(SelHotel) And SelHotel.CloseServiceRegistration Then
		vQry.SetParameter("qPeriodFrom", ?(ValueIsFilled(SelPeriod), BegOfDay(SelPeriod), '00010101'));
	Else
		vQry.SetParameter("qPeriodFrom", '00010101');
	EndIf;
	vQry.SetParameter("qPeriodTo", ?(ValueIsFilled(SelPeriod), EndOfDay(SelPeriod), '00010101'));
	vQry.SetParameter("qEmptyDate", '00010101');
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(SelServiceGroup) Then
		If Not SelServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(SelServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qServicesList", vServicesList);
	RegistrationBalanceAndTurnovers.Load(vQry.Execute().Unload());
EndProcedure //ApplyFilter

// -----------------------------------------------------------------------------
&AtServer
Procedure ResetFilter()
	// Reset filter to default values
	SelPeriod = EndOfDay(CurrentSessionDate());
	SelClient = Catalogs.Clients.EmptyRef();
	SelClientStr = "";
	SelGuestGroup = Catalogs.Clients.EmptyRef();
	//SelGuestGroupDescription = "";
	SelHotel = SessionParameters.CurrentHotel;
	SelRoom = Catalogs.Rooms.EmptyRef();
	SelResource = Catalogs.Resources.EmptyRef();
	SelService = Catalogs.Services.EmptyRef();
	SelServiceGroup = Catalogs.ServiceGroups.EmptyRef();
	SelFolioNumber = "";
EndProcedure //ResetFilter

// -----------------------------------------------------------------------------
&AtServer
Procedure BuildFilterDescription()
	vTSearchResult = Items.GroupSearchMode.Title + ": ";
	If ValueIsFilled(SelBoardPlace) Then
		vTSearchResult = vTSearchResult + NStr("en='Board place: ';ru='Место питания: ';de='Essenort: '") + SelBoardPlace.Description + "; ";
	EndIf;
	If ValueIsFilled(SelService) Then
		vTSearchResult = vTSearchResult + NStr("en='Service: ';ru='Услуга: ';de='Dienstleistung: '") + SelService.Description + "; ";
	EndIf;
	If ValueIsFilled(SelServiceGroup) Then
		vTSearchResult = vTSearchResult + NStr("en='Service group: ';ru='Набор услуг: ';de='Dienstleistungen: '") + SelServiceGroup.Description + "; ";
	EndIf;
	If ValueIsFilled(SelClient) Then
		vTSearchResult = vTSearchResult + NStr("en='Client: ';ru='Клиент: ';de='Kunde: '") + SelClient.Description + "; ";
	ElsIf Not IsBlankString(SelClientStr) Then
		vTSearchResult = vTSearchResult + NStr("en='Last name: ';ru='Фамилия: ';de='Familienname: '") + SelClientStr + "; ";
	EndIf;
	If ValueIsFilled(SelGuestGroup) Then
		vTSearchResult = vTSearchResult + NStr("en='Guest group: ';ru='Группа гостей: ';de='Gästegruppe: '") + SelGuestGroup.Description + "; ";
	EndIf;
	If ValueIsFilled(SelRoom) Then
		vTSearchResult = vTSearchResult + NStr("en='Room: ';ru='Номер: ';de='Zimmer: '") + SelRoom.Description + "; ";
	EndIf;
	If ValueIsFilled(SelResource) Then
		vTSearchResult = vTSearchResult + NStr("en='Resource: ';ru='Ресурс: ';de='Ressource: '") + SelResource.Description + "; ";
	EndIf;
	If Not IsBlankString(SelFolioNumber) Then
		vTSearchResult = vTSearchResult + NStr("en='Folio number: ';ru='Номер фолио: ';de='Folio-Nummer: '") + SelFolioNumber + "; ";
	EndIf;
	If ValueIsFilled(SelHotel) Then
		vTSearchResult = vTSearchResult + NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + SelHotel.Description + "; ";
	EndIf;
	Items.GroupSearchMode.CollapsedRepresentationTitle = vTSearchResult;
EndProcedure //BuildFilterDescription

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenServiceRegistration()
	ButtonServiceRegistrationClick(Items.ButtonServiceRegistration);
EndProcedure //OpenServiceRegistration

// -----------------------------------------------------------------------------
&AtServer
Function QueryDocument()
	vQry = New Query();
	If ValueIsFilled(SelClient) Then
		vQry.Text = 
		"SELECT
		|	Accommodation.Ref AS Ref
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	NOT Accommodation.DeletionMark
		|	AND Accommodation.Hotel = &qHotel
		|	AND Accommodation.CheckInDate <= &qDate
		|	AND Accommodation.CheckOutDate >= &qDate
		|	AND Accommodation.Guest = &qGuest";
		vQry.SetParameter("qDate", CurrentSessionDate());
		vQry.SetParameter("qGuest", SelClient);
		vQry.SetParameter("qHotel", SelHotel);
	ElsIf ValueIsFilled(SelRoom) Then
		vQry.Text = 
		"SELECT
		|	Accommodation.Ref AS Ref
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	NOT Accommodation.DeletionMark
		|	AND Accommodation.Room = &qRoom
		|	AND Accommodation.Hotel = &qHotel
		|	AND Accommodation.CheckInDate <= &qDate
		|	AND Accommodation.CheckOutDate >= &qDate";
		vQry.SetParameter("qDate", CurrentSessionDate());
		vQry.SetParameter("qRoom", SelRoom);
		vQry.SetParameter("qHotel", SelHotel);
	EndIf;
	vResult = vQry.Execute().Unload();
	If vResult.Count() > 0 Then
		Return vResult[0].Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction //QueryDocument

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction //ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function GetReportRefAtServer()
	If Not cmCheckUserRightsToOpenReport(Catalogs.Reports.ServicesRegistration) Then
		Raise NStr("en='You do not have rights to run report: ';ru='Нет прав на формирование отчета: ';de='Sie haben keine Rechte, einen Bericht zu erstellen:'") + cmNStr(Catalogs.Reports.ServicesRegistration.Description) + "!";
	EndIf;
	vRepObj = Catalogs.Reports.ServicesRegistration;
	Return vRepObj;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function CallcmGetDocumentNumberFromPresentation (pFolioNumber)
	Return cmGetDocumentNumberFromPresentation(pFolioNumber, SelHotel);
EndFunction //CallcmGetDocumentNumberFromPresentation

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonServiceRegistrationClick(pControl)
	vSevice = PredefinedValue("Catalog.Services.EmptyRef");
	vCurRow = Items.BalanceAndTurnoversList.CurrentData;
	If vCurRow <> Undefined Then
		vService = vCurRow.Service;
	EndIf;
	vParameter = new Structure("SelPeriod,SelBoardPlace,SelService,SelServiceGroup,SelRoom,SelResource,SelHotel",
								?(ValueIsFilled(SelPeriod), EndOfDay(SelPeriod), '00010101'), SelBoardPlace, 
								?(ValueIsFilled(SelService), SelService, ?(ValueIsFilled(SelServiceGroup), Undefined, vService)),
								SelServiceGroup,
								SelRoom,
								SelResource,
								SelHotel);
	OpenForm("Document.ServiceRegistration.Form.tcServiceControlForm", vParameter);
	// Close this form for better performance
	ThisForm.Close();
EndProcedure //ButtonServiceRegistrationClick

// -----------------------------------------------------------------------------
&AtServer
Function ParseClientFullName(pText)
	vLastName = "";
	vFirstName = "";
	vSecondName = "";
	cmParseClientFullName(pText, vLastName, vFirstName, vSecondName);
	Return new Structure("LastName,FirstName,SecondName", vLastName, vFirstName, vSecondName);
EndFunction //ParseClientFullName

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	// Set client open putton appearance
	If ValueIsFilled(SelClient) Then
		Items.SelClientStr.OpenButton = True;
	Else
		Items.SelClientStr.OpenButton = False;
	EndIf;
	// Set check for the list details level
	Items.FormActionShowDetailedList.Check = SelShowClientsList;
	Items.FormActionShowListByDates.Check = SelShowListByDates;
	// Set list columns appearance
	If SelShowClientsList Then
		If Not Items.RegistrationBalanceAndTurnoversClient.Visible Then
			Items.RegistrationBalanceAndTurnoversClient.Visible = True;
		EndIf;
		If Not Items.RegistrationBalanceAndTurnoversRoom.Visible Then
			Items.RegistrationBalanceAndTurnoversRoom.Visible = True;
		EndIf;
		If Not Items.RegistrationBalanceAndTurnoversCheckInDate.Visible Then
			Items.RegistrationBalanceAndTurnoversCheckInDate.Visible = True;
		EndIf;
		If Not Items.RegistrationBalanceAndTurnoversCheckOutDate.Visible Then
			Items.RegistrationBalanceAndTurnoversCheckOutDate.Visible = True;
		EndIf;
	Else
		If Items.RegistrationBalanceAndTurnoversClient.Visible Then
			Items.RegistrationBalanceAndTurnoversClient.Visible = False;
		EndIf;
		If Items.RegistrationBalanceAndTurnoversRoom.Visible Then
			Items.RegistrationBalanceAndTurnoversRoom.Visible = False;
		EndIf;
		If Items.RegistrationBalanceAndTurnoversCheckInDate.Visible Then
			Items.RegistrationBalanceAndTurnoversCheckInDate.Visible = False;
		EndIf;
		If Items.RegistrationBalanceAndTurnoversCheckOutDate.Visible Then
			Items.RegistrationBalanceAndTurnoversCheckOutDate.Visible = False;
		EndIf;
	EndIf;
	If SelShowListByDates Then
		If Not Items.RegistrationBalanceAndTurnoversAccountingDate.Visible Then
			Items.RegistrationBalanceAndTurnoversAccountingDate.Visible = True;
		EndIf;
	Else
		If Items.RegistrationBalanceAndTurnoversAccountingDate.Visible Then
			Items.RegistrationBalanceAndTurnoversAccountingDate.Visible = False;
		EndIf;
	EndIf;
EndProcedure //RefreshDisplay

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowChoose(pSelectedElement,pListParameters) Export
	DoServiceRegistration(pSelectedElement.Value, pSelectedElement.Value.Service, True);	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function CellcmParseCouponBarCode (pScanData)
	Return cmParseCouponBarCode(pScanData,SelHotel);
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure GetClientsByCoupon(pCouponData)
	// Get clients list
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServiceRegistrationBalance.Service AS Service,
	|	ServiceRegistrationBalance.Client AS Client,
	|	ServiceRegistrationBalance.GuestGroup AS GuestGroup,
	|	ServiceRegistrationBalance.Room AS Room,
	|	ServiceRegistrationBalance.Resource AS Resource,
	|	ServiceRegistrationBalance.Folio AS Folio,
	|	ServiceRegistrationBalance.FolioCurrency AS FolioCurrency,
	|	ServiceRegistrationBalance.QuantityBalance AS AvailableQuantity,
	|	ServiceRegistrationBalance.SumBalance AS AvailableSum
	|FROM
	|	AccumulationRegister.ServiceRegistration.Balance(
	|			&qPeriod,
	|			Client = &qClient
	|				AND Folio = &qFolio
	|				AND GuestGroup = &qGuestGroup
	|				AND Hotel = &qHotel
	|				AND BoardPlace = &qBoardPlace
	|				AND Resource = &qResource
	|				AND Room = &qRoom
	|				AND Service = &qService) AS ServiceRegistrationBalance";
	vQry.SetParameter("qPeriod", ?(ValueIsFilled(pCouponData.AccountingDate), EndOfDay(pCouponData.AccountingDate), '00010101'));
	vQry.SetParameter("qClient", pCouponData.Client);
	vQry.SetParameter("qFolio", pCouponData.Folio);
	vQry.SetParameter("qGuestGroup", pCouponData.GuestGroup);
	vQry.SetParameter("qHotel", SelHotel);
	vQry.SetParameter("qBoardPlace", SelBoardPlace);
	vQry.SetParameter("qResource", pCouponData.Resource);
	vQry.SetParameter("qRoom", pCouponData.Room);
	vQry.SetParameter("qService", pCouponData.Service);
	Clients.Load(vQry.Execute().Unload());
	If Clients.Count() = 0 Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Coupon is already used!';ru='Талон уже был использован!';de='Der Coupon ist schon verbraucht!'"));
	EndIf;
EndProcedure //GetClientsByCoupon

// -----------------------------------------------------------------------------
&AtServer
Procedure GetClientsByCard(pCardId, rCardRef = Undefined, rCardType = Undefined)
	rCardRef = Undefined;
	rCardType = Undefined;
	If Not IsBlankString(pCardId) Then
		rCardRef = cmGetClientIdentificationCardById(cmGetCardIdentifier(pCardId));
		If ValueIsFilled(rCardRef) Then
			rCardType = rCardRef.IdentificationCardType;
			If Not rCardRef.IsBlocked Then
				If Not ValueIsFilled(rCardType) Or ValueIsFilled(rCardType) And Not rCardType.DoServiceRegistrationWithoutChargesControl Then
					If ValueIsFilled(rCardRef.Room) Then
						If ValueIsFilled(SelService) Or ValueIsFilled(SelServiceGroup) Then
							// Get clients list
							FillClientsValueTable(rCardRef, SelService, SelServiceGroup);
							If Clients.Count() = 0 Then
								tcCommonFunctionOnClientServer.UserMessage(NStr("en='Client does not have services prepaid!';ru='У клиента нет начисленных услуг!';de='Bei dem Kunden gibt es keine berechneten Dienstleistungen!'"));
							EndIf;
						Else
							tcCommonFunctionOnClientServer.UserMessage(NStr("en='Please fill service or service group in the filter fields!';ru='Укажите услугу или набор услуг в полях отбора!';de='Geben Sie die Dienstleistung oder das Dienstleistungsangebot in den Auswahlfeldern an!'"));
						EndIf;
					Else
						tcCommonFunctionOnClientServer.UserMessage(NStr("en='Room is not defined for the card!';ru='У карты не указан номер комнаты!';de='Bei der Karte ist keine Zimmernummer angegeben!'"));
					EndIf;
				Else
					SelRoom = Undefined;
					SelResource = Undefined;
					SelClient = Undefined;
					SelClientStr = TrimAll(TrimAll(rCardType.Description) + " " + TrimAll(rCardRef.Description));
				EndIf;
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en='Card is BLOCKED!';ru='Карта ЗАБЛОКИРОВАНА!';de='Die Karte ist BLOCKIERT!'") + Chars.LF + 
				             TrimAll(rCardRef.BlockReason));
			EndIf;
		Else
			tcCommonFunctionOnClientServer.UserMessage(NStr("en='This card is not registered in the program!';ru='Карта в программе не зарегистрирована!';de='Die Karte ist nicht im Programm registriert!'"));
		EndIf;
	Else
		tcCommonFunctionOnClientServer.UserMessage(NStr("en='Nothing is written on the card!';ru='На карте ничего не записано!';de='Auf der Karte ist nichts geschrieben!'"));
	EndIf;	
EndProcedure //GetClientsByCard

// -----------------------------------------------------------------------------
&AtServer
Procedure FillClientsValueTable(pCardRef, pService, pServiceGroup)
	vClients = New ValueTable();
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ServiceRegistrationBalance.Service AS Service,
	|	ServiceRegistrationBalance.Client AS Client,
	|	ServiceRegistrationBalance.GuestGroup AS GuestGroup,
	|	ServiceRegistrationBalance.Room AS Room,
	|	ServiceRegistrationBalance.Resource AS Resource,
	|	ServiceRegistrationBalance.Folio AS Folio,
	|	ServiceRegistrationBalance.FolioCurrency AS FolioCurrency,
	|	ServiceRegistrationBalance.SumBalance AS AvailableSum,
	|	ServiceRegistrationBalance.QuantityBalance AS AvailableQuantity
	|FROM
	|	AccumulationRegister.ServiceRegistration.Balance(
	|			&qPeriod,
	|			Hotel = &qHotel
	|				AND BoardPlace = &qBoardPlace
	|				AND (Service = &qService
	|					OR &qEmptyService)
	|				AND (Service IN (&qServicesList)
	|					OR NOT &qUseServicesList)
	|				AND (Room = &qRoom
	|						AND Room <> &qEmptyRoom
	|					OR Resource = &qResource
	|						AND Resource <> &qEmptyResource)
	|				AND (Client = &qClient
	|					OR &qClientIsEmpty)
	|				AND (GuestGroup = &qGuestGroup
	|					OR &qGuestGroupIsEmpty)
	|				AND Folio.DateTimeTo > &qBegOfYesterday) AS ServiceRegistrationBalance
	|
	|ORDER BY
	|	ServiceRegistrationBalance.Client.Description";
	vQry.SetParameter("qPeriod", ?(ValueIsFilled(SelPeriod), EndOfDay(SelPeriod), '00010101'));
	vQry.SetParameter("qBegOfYesterday", BegOfDay(CurrentSessionDate()) - 24*3600);
	vQry.SetParameter("qHotel", pCardRef.Room.Owner);
	vQry.SetParameter("qBoardPlace", SelBoardPlace);
	vQry.SetParameter("qService", pService);
	vQry.SetParameter("qEmptyService", Not ValueIsFilled(pService));
	vQry.SetParameter("qRoom", pCardRef.Room);
	vQry.SetParameter("qEmptyRoom", Catalogs.Rooms.EmptyRef());
	vQry.SetParameter("qResource", Catalogs.Resources.EmptyRef());
	vQry.SetParameter("qEmptyResource", Catalogs.Resources.EmptyRef());
	vQry.SetParameter("qClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qClientIsEmpty", True);
	vQry.SetParameter("qGuestGroup", pCardRef.GuestGroup);
	vQry.SetParameter("qGuestGroupIsEmpty", Not ValueIsFilled(pCardRef.GuestGroup));
	vUseServicesList = False;
	vServicesList = New ValueList();
	If ValueIsFilled(pServiceGroup) Then
		If Not pServiceGroup.IncludeAll Then
			vUseServicesList = True;
			vServicesList = cmGetServiceGroupServices(pServiceGroup);
		EndIf;
	EndIf;
	vQry.SetParameter("qUseServicesList", vUseServicesList);
	vQry.SetParameter("qServicesList", vServicesList);
	Clients.Load(vQry.Execute().Unload());
EndProcedure //FillClientsValueTable

// -----------------------------------------------------------------------------
&AtClient
Procedure DoServiceRegistration(pClientsRow, pService, pDoCheck = True)
	// Check all attributes first
	If pDoCheck Then
		If Not ValueIsFilled(pService) Then
			ShowMessageBox(,NStr("en='Please choose service!';ru='Не выбрана услуга!';de='Keine Dienstleistung ist gewählt!'"));
			Return;
		ElsIf Not ValueIsFilled(pClientsRow.Room) Then
			ShowMessageBox(,NStr("en='Please choose room!';ru='Выберите номер!';de=' Wählen Sie das Zimmer!'"));
			Return;
		ElsIf Not ValueIsFilled(pClientsRow.Client) Then
			ShowMessageBox(,NStr("en='Please choose client!';ru='Не выбран клиент!';de='Kein Kunde ist gewählt!'"));
			Return;
		ElsIf pClientsRow.AvailableQuantity <= 0 Then
			ShowMessageBox(,NStr("en='Client does not have services prepaid!';ru='У клиента нет начисленных услуг!';de='Bei dem Kunden gibt es keine berechneten Dienstleistungen!'"));
			Return;
		EndIf;
	EndIf;
	vClientStructure = New Structure("Room,Client,GuestGroup,Folio,FolioCurrency,Resource,AvailableSum,AvailableQuantity",
									 pClientsRow.Room,
									 pClientsRow.Client,
									 pClientsRow.GuestGroup,
									 pClientsRow.Folio,
									 pClientsRow.FolioCurrency,
									 pClientsRow.Resource,
									 pClientsRow.AvailableSum,
									 pClientsRow.AvailableQuantity);
	vServeceRegistrationRef = DoServiceRegistrationAtServer(vClientStructure, pService);
	// Do message box
	ShowMessageBox(,NStr("en='OK - Room ';de='OK - Zimmer ';ru='OK - Номер '") + TrimAll(pClientsRow.Room) + ", " + TrimAll(pClientsRow.Client), 2);
	// Sent accounts subsystem change notification
	Notify("Subsystem.Accounts.Changed", vServeceRegistrationRef, ThisForm);
EndProcedure //DoServiceRegistration

// -----------------------------------------------------------------------------
&AtServer
Function DoServiceRegistrationAtServer (pClientsRow, pService)
	// Create and post new document
	vSRObj = Documents.ServiceRegistration.CreateDocument();
	vSRObj.SetTime(AutoTimeMode.CurrentOrLast);
	vSRObj.Hotel = pClientsRow.Room.Owner;
	vSRObj.pmFillAttributesWithDefaultValues();
	vSRObj.AccountingDate = BegOfDay(CurrentSessionDate());
	vSRObj.BoardPlace = SelBoardPlace;
	vSRObj.Client = pClientsRow.Client;
	vSRObj.ClientType = pClientsRow.Client.ClientType;
	vSRObj.GuestGroup = pClientsRow.GuestGroup;
	vSRObj.Folio = pClientsRow.Folio;
	vSRObj.FolioCurrency = pClientsRow.FolioCurrency;
	vSRObj.Quantity = 1;
	vSRObj.Room = pClientsRow.Room;
	vSRObj.Resource = pClientsRow.Resource;
	vSRObj.Service = pService;
	vSRObj.Price = Round(pClientsRow.AvailableSum/pClientsRow.AvailableQuantity, 2);
	vSRObj.Sum = vSRObj.Price;
	// Post document
	vSRObj.Write(DocumentWriteMode.Posting);
	Return vSRObj.Ref;
EndFunction //DoServiceRegistrationAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DoSpecialServiceRegistration(pCardRef, pService)
	// Check all attributes first
	If Not ValueIsFilled(pService) Then
	ShowMessageBox(,NStr("en='Please choose service!';ru='Не выбрана услуга!';de='Keine Dienstleistung ist gewählt!'"));
		Return;
	EndIf;
	vServiceRegistrationRef = DoSpecialServiceRegistrationAtServer(pCardRef, pService);
	// Do message box
	ShowMessageBox(,NStr("en='OK - Card ';de='OK - Kart ';ru='OK - Карта '") + TrimAll(pCardRef.Description), 2);
	// Sent accounts subsystem change notification
	Notify("Subsystem.Accounts.Changed", vServiceRegistrationRef, ThisForm);
EndProcedure //DoSpecialServiceRegistration

// -----------------------------------------------------------------------------
&AtServer
Function DoSpecialServiceRegistrationAtServer (pCardRef, pService)
	// Create and post new document
	vSRObj = Documents.ServiceRegistration.CreateDocument();
	vSRObj.SetTime(AutoTimeMode.CurrentOrLast);
	vSRObj.Hotel = SessionParameters.CurrentHotel;
	vSRObj.pmFillAttributesWithDefaultValues();
	vSRObj.AccountingDate = BegOfDay(CurrentSessionDate());
	vSRObj.BoardPlace = SelBoardPlace;
	vSRObj.Client = pCardRef.Client;
	vSRObj.ClientType = ?(ValueIsFilled(pCardRef.Client), pCardRef.Client.ClientType, Undefined);
	vSRObj.GuestGroup = pCardRef.GuestGroup;
	vSRObj.Folio = pCardRef.Folio;
	vSRObj.FolioCurrency = ?(ValueIsFilled(pCardRef.Folio), pCardRef.Folio.FolioCurrency, vSRObj.Hotel.BaseCurrency);
	vSRObj.Quantity = 1;
	vSRObj.Room = pCardRef.Room;
	vSRObj.Resource = Undefined;
	vSRObj.Service = pService;
	vSRObj.Price = 0;
	vSRObj.Sum = 0;
	// Post document
	vSRObj.Write(DocumentWriteMode.Posting);
EndFunction //DoSpecialServiceRegistration


#EndRegion

