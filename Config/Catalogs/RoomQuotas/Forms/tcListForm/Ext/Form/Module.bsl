// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Filter by hotel
	If Not Parameters.Filter.Property("Hotel") Then		  
		SelHotel = SessionParameters.CurrentHotel; 
	Else
		SelHotel = Parameters.Filter.Hotel;		
		Parameters.Filter.Delete("Hotel");
	EndIf;  
	SelHotelOnChangeAtServer();
	// Filter by customer and contract
	vAgent = SessionParameters.CurrentUser.Customer;
	If ValueIsFilled(vAgent) Then
		Parameters.Filter.Insert("Customer", vAgent);
	Else	
		If Parameters.Filter.Property("Customer") And ValueIsFilled(Parameters.Filter.Customer) Then
			vCustArray = New Array;
			vCustArray.Add(Parameters.Filter.Customer);		
			vCustArray.Add(Catalogs.Customers.EmptyRef());
			Parameters.Filter.Insert("Customer", vCustArray);
		EndIf;	
		If Parameters.Filter.Property("Contract") And ValueIsFilled(Parameters.Filter.Contract) Then		
			vContrArray = New Array;
			vContrArray.Add(Parameters.Filter.Contract);		
			vContrArray.Add(Catalogs.Contracts.EmptyRef());
			Parameters.Filter.Insert("Contract", vContrArray);
		EndIf;	
	EndIf;
	If Parameters.Property("AllotmentBusinessType") And ValueIsFilled(Parameters.AllotmentBusinessType) Then
		SelAllotmentBusinessType = Parameters.AllotmentBusinessType;
		Items.ContactPerson.Visible = True;
		Items.SelAllotmentBusinessType.Visible = False;
		Items.AllotmentBusinessType.Visible = False;
		Items.SelShowIsDueOnly.Visible = True;
		Items.FormOpenFolios.Visible = True;
		ThisObject.Title = NStr("en='Business blocks'; ru='Бизнес-блоки'; de='Geschäftsblöcke'");
		ThisObject.AutoTitle = False;
		Items.SelAllotmentType.ListChoiceMode = True;
		Items.SelAllotmentType.ChoiceList.Clear();
		Items.SelAllotmentType.ChoiceList.Add(Enums.AllotmentTypes.Definite);
		Items.SelAllotmentType.ChoiceList.Add(Enums.AllotmentTypes.DefiniteNotGuaranteed);
		Items.SelAllotmentType.ChoiceList.Add(Enums.AllotmentTypes.Tentative);
		Items.SelAllotmentType.ChoiceList.Add(Enums.AllotmentTypes.Reserved);
		Items.SelAllotmentType.ChoiceList.Add(Enums.AllotmentTypes.Cancelled);
		// Check hotel list of allowed busines-block statuses
		If ValueIsFilled(SelHotel) And SelHotel.BusinessBlockStatusesAllowed.Count() > 0 Then
			s = 0;
			While s < Items.SelAllotmentType.ChoiceList.Count() Do
				vStatus = Items.SelAllotmentType.ChoiceList.Get(s).Value;
				If SelHotel.BusinessBlockStatusesAllowed.Find(vStatus, "Status") = Undefined Then
					Items.SelAllotmentType.ChoiceList.Delete(s);
				Else
					s = s + 1;
				EndIf;
			EndDo;
		EndIf;
	Else
		Items.ContactPerson.Visible = False;
		Items.AllotmentBusinessType.Visible = True;
		Items.SelShowIsDueOnly.Visible = False;
		Items.DateOfDef.Visible = False;
		Items.IsDue.Visible = False;
		Items.FormOpenFolios.Visible = False;
		Items.DateOfAnnulation.Visible = False;
		Items.AuthorOfAnnulation.Visible = False;
		Items.AnnulationReason.Visible = False;
		Items.ReservationManager.Visible = False;
		Items.MICEManager.Visible = False;
		Items.RevenueManager.Visible = False;
		Items.RoomNights.Visible = False;
		Items.BudgetAmount.Visible = False;
		Items.BudgetCurrency.Visible = False;
		Items.SelShowCancelledAndDeleted.Title = NStr("en='Show marked for deletion'; ru='Показать помеченные на удаление'; de='Zum Löschen markierte anzeigen'");
		Items.SelAllotmentType.ListChoiceMode = True;
		Items.SelAllotmentType.ChoiceList.Clear();
		Items.SelAllotmentType.ChoiceList.Add(Enums.AllotmentTypes.Definite);
		Items.SelAllotmentType.ChoiceList.Add(Enums.AllotmentTypes.Tentative);
		Items.SelAllotmentType.ChoiceList.Add(Enums.AllotmentTypes.DoNotChangeAvailability);
	EndIf;
	List.Parameters.SetParameterValue("qAllotmentBusinessType", SelAllotmentBusinessType);   
	List.Parameters.SetParameterValue("qAllotmentType", SelAllotmentType);   
	List.Parameters.SetParameterValue("qToday", BegOfDay(CurrentSessionDate()));   
	List.Parameters.SetParameterValue("qEmptyDate", '00010101'); 
	List.Parameters.SetParameterValue("qIsDueOnly", SelShowIsDueOnly);   
	List.Parameters.SetParameterValue("qShowCancelledAndDeleted", SelShowCancelledAndDeleted);   
	List.Parameters.SetParameterValue("qDateFrom", SelDateFrom);
	List.Parameters.SetParameterValue("qDateTo", ?(ValueIsFilled(SelDateTo), EndOfDay(SelDateTo), '39991231235959'));
	// Choice mode
	If Parameters.Property("ChoiceMode") Then
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenFolios(Command)
	vRef = Items.List.CurrentRow;
	If Not vRef = Undefined Then
		// APDEX
		vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		vParametersStructure = New Structure("ObjectRef", vRef);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisForm, ThisForm.UUID);
	EndIf;
EndProcedure // OpenFolios

// --------------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	SelHotelOnChangeAtServer();
EndProcedure // SelHotelOnChange

// --------------------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()        
	vHotelArr = New Array; 
	vHotelArr.Add(Catalogs.Hotels.EmptyRef()); 
	vHotelArr.Add(SelHotel);
	List.Parameters.SetParameterValue("qHotels", vHotelArr);   
		
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");		
EndProcedure // SelHotelOnChangeAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure SelAllotmentBusinessTypeOnChangeAtServer()
	List.Parameters.SetParameterValue("qAllotmentBusinessType", SelAllotmentBusinessType);   
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelAllotmentBusinessTypeOnChange(pItem)
	SelAllotmentBusinessTypeOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelAllotmentTypeOnChangeAtServer()
	List.Parameters.SetParameterValue("qAllotmentType", SelAllotmentType);   
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelAllotmentTypeOnChange(pItem)
	SelAllotmentTypeOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelShowIsDueOnlyOnChangeAtServer()
	List.Parameters.SetParameterValue("qIsDueOnly", SelShowIsDueOnly);   
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelShowIsDueOnlyOnChange(pItem)
	SelShowIsDueOnlyOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelShowCancelledAndDeletedOnChangeAtServer()
	List.Parameters.SetParameterValue("qShowCancelledAndDeleted", SelShowCancelledAndDeleted);   
EndProcedure // SelShowCancelledAndDeletedOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure SelShowCancelledAndDeletedOnChange(pItem)
	SelShowCancelledAndDeletedOnChangeAtServer();
EndProcedure // SelShowCancelledAndDeletedOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If Not pClone And Not pFolder Then
		pCancel = True;
		If CheckFilling() Then
			OpenForm("Catalog.RoomQuotas.ObjectForm", New Structure("SelHotel, Parent, AllotmentBusinessType", SelHotel, pParent, SelAllotmentBusinessType), ThisObject);
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowAvailability(pCommand)
	vCurData = Items.List.CurrentData;
	If vCurData <> Undefined And Not vCurData.IsFolder Then
		// APDEX
		vKeyOperation = "Catalog.RoomQuotas.Form.tcAllotmentVacantRooms.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		If ValueIsFilled(vCurData.PeriodFrom) And ValueIsFilled(vCurData.PeriodTo) And vCurData.PeriodTo >= vCurData.PeriodFrom Then
			OpenForm("Catalog.RoomQuotas.Form.tcAllotmentVacantRooms", New Structure("Hotel, Allotment, PeriodFrom, NumberOfDays, Mode", vCurData.Hotel, vCurData.Ref, vCurData.PeriodFrom, (vCurData.PeriodTo - vCurData.PeriodFrom) / (24 * 3600) + 1, 1), ThisObject, vCurData.Ref);
		Else
			OpenForm("Catalog.RoomQuotas.Form.tcAllotmentVacantRooms", New Structure("Hotel, Allotment, Mode", vCurData.Hotel, vCurData.Ref, 1), ThisObject, vCurData.Ref);
		EndIf;
	EndIf;
EndProcedure // ShowAvailability

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowAvailableRooms(pCommand)
	vCurData = Items.List.CurrentData;
	If vCurData <> Undefined And Not vCurData.IsFolder Then
		// APDEX
		vKeyOperation = "CommonForm.tcAvailableRoomsReport.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		// Open availability form
		OpenForm("CommonForm.tcAvailableRoomsReport", New Structure("Allotment", vCurData.Ref), ThisObject, vCurData.Ref);
	EndIf;
EndProcedure // ShowAvailableRooms

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowInHouse(pCommand)
	vCurData = Items.List.CurrentData;
	If vCurData <> Undefined Then
		// APDEX
		vKeyOperation = "Document.Accommodation.Form.tcAccommodationListForm.InHouseGuests.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Document.Accommodation.Form.tcAccommodationListForm", New Structure("Allotment, SelFilterStatus, SelShowAllGuests", vCurData.Ref, 0, 0), ThisObject, vCurData.Ref);
	EndIf;
EndProcedure // ShowInHouse

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowReservations(pCommand)
	vCurData = Items.List.CurrentData;
	If vCurData <> Undefined Then
		// APDEX
		vKeyOperation = "Document.Reservation.Form.tcReservationListForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		OpenForm("Document.Reservation.ListForm", New Structure("SelAllotment, SelDocPeriod, SelFilterStatus, SelShowAllGuests", vCurData.Ref, '00010101', "&ACTIVE", 0), ThisObject);
	EndIf;
EndProcedure // ShowReservations

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowResourceReservations(pCommand)
	vCurData = Items.List.CurrentData;
	If vCurData <> Undefined Then
		OpenForm("Document.ResourceReservation.ListForm", New Structure("SelAllotment, SelDocPeriod, SelFilterStatus", vCurData.Ref, '00010101', "&ACTIVE"), ThisObject);
	EndIf;
EndProcedure // ShowResourceReservations

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Allotment.Write" Then
		Items.List.Refresh();
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateFromOnChange(pItem)
	SelPeriodOnChangeAtServer();
EndProcedure // SelDateFromOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelDateToOnChange(pItem)
	SelPeriodOnChangeAtServer();
EndProcedure // SelDateToOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelPeriodOnChangeAtServer()
	List.Parameters.SetParameterValue("qDateFrom", SelDateFrom);
	List.Parameters.SetParameterValue("qDateTo", ?(ValueIsFilled(SelDateTo), EndOfDay(SelDateTo), '39991231235959'));
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = SelDateFrom;
	vChoosePeriodDialog.Period.EndDate = SelDateTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisForm));
EndProcedure // ChoosePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		SelDateFrom = pPeriod.StartDate;
		SelDateTo = pPeriod.EndDate;
		SelPeriodOnChangeAtServer();
	EndIf;  
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearPeriod(pCommand)
	SelDateFrom = '00010101';
	SelDateTo = '00010101';
	SelPeriodOnChangeAtServer();
EndProcedure // ClearPeriod
