
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill attributes
	Hotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) Then
		AccountingDate = Hotel.AccountingDate;
	Else
		AccountingDate = BegOfDay(CurrentSessionDate());
	EndIf; 
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	
	// Fill parameters based on workstation an current time
	SetServiceRegistrationSchedule();
	// Fill occupied rooms list parameters
	FillOccupiedRoomsParameters();
	// Calculate totals
	CalculateTotals();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Form appearance
	#IF NOT MobileClient THEN
		Items.OccupiedRooms.CommandBarLocation = FormItemCommandBarLabelLocation.Auto;
		Items.MealType.TitleLocation = FormItemTitleLocation.Left;
		Items.AccountingDate.TitleLocation = FormItemTitleLocation.Left;
	#ELSE
		Items.GroupExtraData1.Visible = False;
		Items.GroupExtraData2.Visible = False;
	#ENDIF
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AccountingDateOnChange(pItem)
	FillOccupiedRoomsParameters();
	CalculateTotals();
EndProcedure // AccountingDateOnChange

#EndRegion

#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure OccupiedRoomsSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;  
	#IF NOT MobileClient THEN
		DoRoomRegistration(Commands.DoRoomRegistration); 
	#ENDIF
EndProcedure // OccupiedRoomsSelection

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DoRegistration(pCommand)
	vCurData = Items.OccupiedRooms.CurrentData;
	If vCurData <> Undefined Then
		// Check if there are unchecked persons in the room
		vNumberOfPersons = vCurData.NumberOfAdults + vCurData.NumberOfTeenagers + vCurData.NumberOfChildren + vCurData.NumberOfInfants;
		vNumberOfPersons = ?(vNumberOfPersons = 0, vCurData.NumberOfPersons, vNumberOfPersons);
		If MealType = PredefinedValue("Enum.MealTypes.Breakfast") And vCurData.NumberOfBreakfasts >= vNumberOfPersons Then
			SendUserMessage(NStr("en='All clients are already registered!'; ru='Все клиенты уже зарегистрированы!'; de='Alle Kunden sind bereits registriert!'"));
			Return;
		ElsIf MealType = PredefinedValue("Enum.MealTypes.Lunch") And vCurData.NumberOfLunches >= vNumberOfPersons Then
			SendUserMessage(NStr("en='All clients are already registered!'; ru='Все клиенты уже зарегистрированы!'; de='Alle Kunden sind bereits registriert!'"));
			Return;
		ElsIf MealType = PredefinedValue("Enum.MealTypes.Dinner") And vCurData.NumberOfDinners >= vNumberOfPersons Then
			SendUserMessage(NStr("en='All clients are already registered!'; ru='Все клиенты уже зарегистрированы!'; de='Alle Kunden sind bereits registriert!'"));
			Return;
		EndIf;
		If ValueIsFilled(vCurData.Service) And TypeOf(vCurData.Service) = Type("CatalogRef.ServicePackages") Then
			// Check bed & breakfasts
			If tcOnServer.cmGetAttributeByRef(vCurData.Service, "IsBB") Then
				If MealType = PredefinedValue("Enum.MealTypes.Lunch") Or MealType = PredefinedValue("Enum.MealTypes.Dinner") Then
					SendUserMessage(NStr("en='Lunch or dinner is not allowed for BB guests!'; ru='Гости с пакетом Bed&Breakfast не допускаются на обед и ужин!'; de='Mittag- oder Abendessen ist für BB-Gäste nicht erlaubt!'"));
					Return;
				EndIf;
			EndIf;
			// Check halfboards
			If tcOnServer.cmGetAttributeByRef(vCurData.Service, "IsHB") Then
				vTotalRegistered = vCurData.NumberOfLunches + vCurData.NumberOfDinners;
				If MealType = PredefinedValue("Enum.MealTypes.Lunch") And (vTotalRegistered + 1) > vNumberOfPersons Then
					SendUserMessage(NStr("en='Either lunch or dinner is allowed for HB clients!'; ru='Гостям с пакетом полупансион разрешен либо обед либо ужин!'; de='Mittag- Oder Abendessen ist für HB-Gäste erlaubt!'"));
					Return;
				ElsIf MealType = PredefinedValue("Enum.MealTypes.Dinner") And (vTotalRegistered + 1) > vNumberOfPersons Then
					SendUserMessage(NStr("en='Either lunch or dinner is allowed for HB clients!'; ru='Гостям с пакетом полупансион разрешен либо обед либо ужин!'; de='Mittag- Oder Abendessen ist für HB-Gäste erlaubt!'"));
					Return;
				EndIf;
			EndIf;
		EndIf;
		// Do register
		DoRegistrationAtServer(False, vCurData);
		// Update row data
		Items.OccupiedRooms.Refresh();
	EndIf;
EndProcedure // DoRegistration

// --------------------------------------------------------------------------------
&AtClient
Procedure DoRoomRegistration(pCommand)
	vCurData = Items.OccupiedRooms.CurrentData;
	If vCurData <> Undefined Then
		// Check if there are unchecked persons in the room
		vLeftToRegister = 1;
		vNumberOfPersons = vCurData.NumberOfAdults + vCurData.NumberOfTeenagers + vCurData.NumberOfChildren + vCurData.NumberOfInfants;
		vNumberOfPersons = ?(vNumberOfPersons = 0, vCurData.NumberOfPersons, vNumberOfPersons);
		If MealType = PredefinedValue("Enum.MealTypes.Breakfast") Then
			If vCurData.NumberOfBreakfasts >= vNumberOfPersons Then
				SendUserMessage(NStr("en='All clients are already registered!'; ru='Все клиенты уже зарегистрированы!'; de='Alle Kunden sind bereits registriert!'"));
				Return;
			Else
				vLeftToRegister = vNumberOfPersons - vCurData.NumberOfBreakfasts;
			EndIf;
		ElsIf MealType = PredefinedValue("Enum.MealTypes.Lunch") Then
			If vCurData.NumberOfLunches >= vNumberOfPersons Then
				SendUserMessage(NStr("en='All clients are already registered!'; ru='Все клиенты уже зарегистрированы!'; de='Alle Kunden sind bereits registriert!'"));
				Return;
			Else
				vLeftToRegister = vNumberOfPersons - vCurData.NumberOfLunches;
			EndIf;
		ElsIf MealType = PredefinedValue("Enum.MealTypes.Dinner") Then
			If vCurData.NumberOfDinners >= vNumberOfPersons Then
				SendUserMessage(NStr("en='All clients are already registered!'; ru='Все клиенты уже зарегистрированы!'; de='Alle Kunden sind bereits registriert!'"));
				Return;
			Else
				vLeftToRegister = vNumberOfPersons - vCurData.NumberOfDinners;
			EndIf;
		EndIf;
		If vLeftToRegister = 0 Then
			Return;
		EndIf;
		If ValueIsFilled(vCurData.Service) And TypeOf(vCurData.Service) = Type("CatalogRef.ServicePackages") Then
			// Check bed & breakfasts
			If tcOnServer.cmGetAttributeByRef(vCurData.Service, "IsBB") Then
				If MealType = PredefinedValue("Enum.MealTypes.Lunch") Or MealType = PredefinedValue("Enum.MealTypes.Dinner") Then
					SendUserMessage(NStr("en='Lunch or dinner is not allowed for BB guests!'; ru='Гости с пакетом Bed&Breakfast не допускаются на обед и ужин!'; de='Mittag- oder Abendessen ist für BB-Gäste nicht erlaubt!'"));
					Return;
				EndIf;
			EndIf;
			// Check halfboards
			If tcOnServer.cmGetAttributeByRef(vCurData.Service, "IsHB") Then
				vTotalRegistered = vCurData.NumberOfLunches + vCurData.NumberOfDinners;
				If MealType = PredefinedValue("Enum.MealTypes.Lunch") And (vTotalRegistered + vLeftToRegister) > vNumberOfPersons Then
					SendUserMessage(NStr("en='Either lunch or dinner is allowed for HB clients!'; ru='Гостям с пакетом полупансион разрешен либо обед либо ужин!'; de='Mittag- Oder Abendessen ist für HB-Gäste erlaubt!'"));
					Return;
				ElsIf MealType = PredefinedValue("Enum.MealTypes.Dinner") And (vTotalRegistered + vLeftToRegister) > vNumberOfPersons Then
					SendUserMessage(NStr("en='Either lunch or dinner is allowed for HB clients!'; ru='Гостям с пакетом полупансион разрешен либо обед либо ужин!'; de='Mittag- Oder Abendessen ist für HB-Gäste erlaubt!'"));
					Return;
				EndIf;
			EndIf;
		EndIf;
		// Do register
		DoRegistrationAtServer(False, vCurData, vLeftToRegister);
		// Update row data
		Items.OccupiedRooms.Refresh();
	EndIf;
EndProcedure // DoRoomRegistration

// --------------------------------------------------------------------------------
&AtClient
Procedure UndoRegistration(pCommand)
	vCurData = Items.OccupiedRooms.CurrentData;
	If vCurData <> Undefined Then
		// Check if there is something to undo
		If MealType = PredefinedValue("Enum.MealTypes.Breakfast") And vCurData.NumberOfBreakfasts = 0 Then
			SendUserMessage(NStr("en='Nothing to cancel!'; ru='Нечего отменять!'; de='Nichts zu Abbrechen!'"));
			Return;
		ElsIf MealType = PredefinedValue("Enum.MealTypes.Lunch") And vCurData.NumberOfLunches = 0 Then
			SendUserMessage(NStr("en='Nothing to cancel!'; ru='Нечего отменять!'; de='Nichts zu Abbrechen!'"));
			Return;
		ElsIf MealType = PredefinedValue("Enum.MealTypes.Dinner") And vCurData.NumberOfDinners = 0 Then
			SendUserMessage(NStr("en='Nothing to cancel!'; ru='Нечего отменять!'; de='Nichts zu Abbrechen!'"));
			Return;
		EndIf;
		// Do unregister
		DoRegistrationAtServer(True, vCurData);
		// Update row data
		Items.OccupiedRooms.Refresh();
	EndIf;
EndProcedure // UndoRegistration

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure SetServiceRegistrationSchedule()
	vWstn = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vWstn) Then
		If vWstn.ServiceRegistrationSchedule.Count() > 0 Then
			vCurTime = '00010101' + (CurrentSessionDate() - BegOfDay(CurrentSessionDate()));
			For Each vScheduleRow In vWstn.ServiceRegistrationSchedule Do
				If vScheduleRow.TimeFrom <= vCurTime And vScheduleRow.TimeTo > vCurTime Then
					If ValueIsFilled(vScheduleRow.ServiceGroup) Then
						ServiceGroup = vScheduleRow.ServiceGroup;
					EndIf;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If Hour(CurrentSessionDate()) < 12 Then
		MealType = Enums.MealTypes.Breakfast;
	ElsIf Hour(CurrentSessionDate()) < 17 Then
		MealType = Enums.MealTypes.Lunch;
	Else
		MealType = Enums.MealTypes.Dinner;
	EndIf;
EndProcedure // SetServiceRegistrationSchedule

// --------------------------------------------------------------------------------
&AtServer
Procedure FillOccupiedRoomsParameters()
	OccupiedRooms.Parameters.SetParameterValue("qHotel", Hotel);
	OccupiedRooms.Parameters.SetParameterValue("qAccountingDate", AccountingDate);
	If ValueIsFilled(AccountingDate) And ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) And Hotel.AccountingDate > AccountingDate Then
		OccupiedRooms.Parameters.SetParameterValue("qUseForecast", False);
	Else
		OccupiedRooms.Parameters.SetParameterValue("qUseForecast", True);
	EndIf;
	If ValueIsFilled(ServiceGroup) Then
		vServicesList = ServiceGroup.GetObject().pmGetServicesList();
		OccupiedRooms.Parameters.SetParameterValue("qUseMealServices", True);
	Else
		vServicesList = New ValueList();
		OccupiedRooms.Parameters.SetParameterValue("qUseMealServices", False);
	EndIf;
	OccupiedRooms.Parameters.SetParameterValue("qMealServices", vServicesList);
EndProcedure // FillOccupiedRoomsParameters

// --------------------------------------------------------------------------------
&AtServer 
Procedure CalculateTotals()
	// Reset totatls
	TotalRooms = 0;
	TotalPersons = 0;
	TotalAdults = 0;
	TotalTeenagers = 0;
	TotalChildren = 0;
	TotalInfants = 0;
	TotalKids = 0;
	TotalPersons = 0;
	TotalRoomsStr = "";
	TotalPersonsStr = "";
	TotalBreakfasts = 0;
	TotalLunches = 0;
	TotalDinners = 0;
	// Run query to get new ones
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	COUNT(Totals.Room) AS TotalRooms,
	|	SUM(Totals.NumberOfAdults) AS TotalAdults,
	|	SUM(Totals.NumberOfTeenagers) AS TotalTeenagers,
	|	SUM(Totals.NumberOfChildren) AS TotalChildren,
	|	SUM(Totals.NumberOfInfants) AS TotalInfants,
	|	SUM(Totals.NumberOfBreakfasts) AS TotalBreakfasts,
	|	SUM(Totals.NumberOfLunches) AS TotalLunches,
	|	SUM(Totals.NumberOfDinners) AS TotalDinners
	|FROM
	|	(SELECT
	|		Rooms.Hotel AS Hotel,
	|		Rooms.AccountingDate AS AccountingDate,
	|		Rooms.Client AS Client,
	|		Rooms.Service AS Service,
	|		Rooms.ParentDoc AS ParentDoc,
	|		Rooms.ParentDoc.Room AS Room,
	|		ISNULL(Rooms.ParentDoc.NumberOfAdults, 0) AS NumberOfAdults,
	|		ISNULL(Rooms.ParentDoc.NumberOfTeenagers, 0) AS NumberOfTeenagers,
	|		ISNULL(Rooms.ParentDoc.NumberOfChildren, 0) AS NumberOfChildren,
	|		ISNULL(Rooms.ParentDoc.NumberOfInfants, 0) AS NumberOfInfants,
	|		ISNULL(ServiceRegistrations.NumberOfBreakfasts, 0) AS NumberOfBreakfasts,
	|		ISNULL(ServiceRegistrations.NumberOfLunches, 0) AS NumberOfLunches,
	|		ISNULL(ServiceRegistrations.NumberOfDinners, 0) AS NumberOfDinners
	|	FROM
	|		(SELECT
	|			Services.Hotel AS Hotel,
	|			Services.AccountingDate AS AccountingDate,
	|			Services.Client AS Client,
	|			Services.ParentDoc AS ParentDoc,
	|			Services.Service AS Service
	|		FROM
	|			(SELECT
	|				SalesMovements.Hotel AS Hotel,
	|				SalesMovements.ServiceDate AS AccountingDate,
	|				SalesMovements.Client AS Client,
	|				SalesMovements.ParentDoc AS ParentDoc,
	|				CASE
	|					WHEN ISNULL(SalesMovements.ParentDoc.ServicePackage.IsMealBoardTerm, FALSE)
	|						THEN SalesMovements.ParentDoc.ServicePackage
	|					ELSE SalesMovements.Service
	|				END AS Service
	|			FROM
	|				AccumulationRegister.Sales AS SalesMovements
	|			WHERE
	|				SalesMovements.ServiceDate = &qAccountingDate
	|				AND SalesMovements.Hotel = &qHotel
	|				AND (&qUseMealServices
	|							AND SalesMovements.Service IN (&qMealServices)
	|						OR NOT &qUseMealServices
	|							AND SalesMovements.GuestDays <> 0)
	|			
	|			UNION ALL
	|			
	|			SELECT
	|				SalesForecastMovements.Hotel,
	|				SalesForecastMovements.ServiceDate,
	|				SalesForecastMovements.Client,
	|				SalesForecastMovements.ParentDoc,
	|				CASE
	|					WHEN ISNULL(SalesForecastMovements.ParentDoc.ServicePackage.IsMealBoardTerm, FALSE)
	|						THEN SalesForecastMovements.ParentDoc.ServicePackage
	|					ELSE SalesForecastMovements.Service
	|				END
	|			FROM
	|				AccumulationRegister.SalesForecast AS SalesForecastMovements
	|			WHERE
	|				SalesForecastMovements.ServiceDate = &qAccountingDate
	|				AND SalesForecastMovements.Hotel = &qHotel
	|				AND (&qUseMealServices
	|							AND SalesForecastMovements.Service IN (&qMealServices)
	|						OR NOT &qUseMealServices
	|							AND SalesForecastMovements.GuestDays <> 0)
	|				AND &qUseForecast) AS Services
	|		
	|		GROUP BY
	|			Services.Hotel,
	|			Services.AccountingDate,
	|			Services.Client,
	|			Services.ParentDoc,
	|			Services.Service) AS Rooms
	|			LEFT JOIN (SELECT
	|				Registrations.Hotel AS Hotel,
	|				Registrations.AccountingDate AS AccountingDate,
	|				Registrations.Client AS Client,
	|				Registrations.ParentDoc AS ParentDoc,
	|				SUM(CASE
	|						WHEN Registrations.MealType = VALUE(Enum.MealTypes.Breakfast)
	|							THEN Registrations.Quantity
	|						ELSE 0
	|					END) AS NumberOfBreakfasts,
	|				SUM(CASE
	|						WHEN Registrations.MealType = VALUE(Enum.MealTypes.Lunch)
	|							THEN Registrations.Quantity
	|						ELSE 0
	|					END) AS NumberOfLunches,
	|				SUM(CASE
	|						WHEN Registrations.MealType = VALUE(Enum.MealTypes.Dinner)
	|							THEN Registrations.Quantity
	|						ELSE 0
	|					END) AS NumberOfDinners
	|			FROM
	|				Document.ServiceRegistration AS Registrations
	|			WHERE
	|				Registrations.Posted
	|				AND Registrations.AccountingDate = &qAccountingDate
	|				AND Registrations.Hotel = &qHotel
	|			
	|			GROUP BY
	|				Registrations.Hotel,
	|				Registrations.AccountingDate,
	|				Registrations.Client,
	|				Registrations.ParentDoc) AS ServiceRegistrations
	|			ON (ServiceRegistrations.Hotel = Rooms.Hotel)
	|				AND (ServiceRegistrations.AccountingDate = Rooms.AccountingDate)
	|				AND (ServiceRegistrations.Client = Rooms.Client)
	|				AND (ServiceRegistrations.ParentDoc = Rooms.ParentDoc)) AS Totals";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qAccountingDate", AccountingDate);
	If ValueIsFilled(AccountingDate) And ValueIsFilled(Hotel) And ValueIsFilled(Hotel.AccountingDate) And Hotel.AccountingDate > AccountingDate Then
		vQry.SetParameter("qUseForecast", False);
	Else
		vQry.SetParameter("qUseForecast", True);
	EndIf;
	If ValueIsFilled(ServiceGroup) Then
		vServicesList = ServiceGroup.GetObject().pmGetServicesList();
		vQry.SetParameter("qUseMealServices", True);
	Else
		vServicesList = New ValueList();
		vQry.SetParameter("qUseMealServices", False);
	EndIf;
	vQry.SetParameter("qMealServices", vServicesList);
	vTotals = vQry.Execute().Unload();
	If vTotals.Count() > 0 Then
		vTotalsRow = vTotals.Get(0);
		
		TotalRooms = vTotalsRow.TotalRooms;
		TotalAdults = vTotalsRow.TotalAdults;
		TotalTeenagers = vTotalsRow.TotalTeenagers;
		TotalChildren = vTotalsRow.TotalChildren;
		TotalInfants = vTotalsRow.TotalInfants;
		TotalKids = TotalTeenagers + TotalChildren + TotalInfants;
		TotalPersons = TotalAdults + TotalKids;
		TotalBreakfasts = vTotalsRow.TotalBreakfasts;
		TotalLunches = vTotalsRow.TotalLunches;
		TotalDinners = vTotalsRow.TotalDinners;
		
		TotalRoomsStr = NStr("en='Rooms: '; ru='Номеров: '; de='Zimmer: '") + Format(TotalRooms, "NFD=0");
		TotalPersonsStr = NStr("en='Persons: '; ru='Человек: '; de='Personen: '") + Format(TotalPersons, "NFD=0") + NStr("en=', incl. kids: '; ru=', вкл. детей: '; de=', inkl. Kinder: '") + Format(TotalKids, "NFD=0");
	EndIf;
EndProcedure // CalculateTotals

// --------------------------------------------------------------------------------
&AtServer
Procedure SendUserMessage(pMessage, pField = Undefined)
	vUM = New UserMessage();
	If pField <> Undefined Then
		vUM.Field = pField;
	EndIf;
	vUM.Text = pMessage;
	vUM.Message();
EndProcedure // SendUserMessage

// --------------------------------------------------------------------------------
&AtServer
Procedure DoRegistrationAtServer(pIsUndo = False, Val pCurData, Val pNumClients = 1)
	// Check meal type
	If Not ValueIsFilled(MealType) Then
		SendUserMessage(NStr("en='Meal type has to be filled!'; ru='Не указан тип питания!'; de='Keine Angabe der Essentyp!'"), "MealType");
		Return;
	EndIf;
	// Check conditions
	vParentDoc = pCurData.ParentDoc;
	If Not pIsUndo And MealType <> Enums.MealTypes.Breakfast Then
		If TypeOf(vParentDoc) = Type("DocumentRef.Accommodation") And BegOfDay(vParentDoc.CheckOutDate) = BegOfDay(AccountingDate) Then
			SendUserMessage(NStr("en='Guests have check-out!'; ru='Гости на выезде!'; de='Gäste haben check-out !'"));
			Return;
		EndIf;
	EndIf;
	// Create and post new document
	vSRObj = Documents.ServiceRegistration.CreateDocument();
	vSRObj.SetTime(AutoTimeMode.CurrentOrLast);
	vSRObj.Hotel = Hotel;
	vSRObj.pmFillAttributesWithDefaultValues();
	vSRObj.MealType = MealType;
	vSRObj.Service = Undefined;
	vSRObj.AccountingDate = AccountingDate;
	vSRObj.Client = pCurData.Client;
	vSRObj.ClientType = pCurData.ClientType;
	vSRObj.GuestGroup = pCurData.GuestGroup;
	vSRObj.Folio = Undefined;
	vSRObj.FolioCurrency = Hotel.BaseCurrency;
	vSRObj.ParentDoc = vParentDoc;
	vSRObj.Quantity = ?(pIsUndo, -pNumClients, pNumClients);
	vSRObj.Unit = "";
	vSRObj.Room = pCurData.Room;
	vSRObj.Resource = pCurData.Resource;
	vSRObj.Price = 0;
	vSRObj.Sum = 0;
	// Post document
	vSRObj.Write(DocumentWriteMode.Posting);
	// Calculate totals
	CalculateTotals();
EndProcedure // DoRegistrationAtServer

#EndRegion

