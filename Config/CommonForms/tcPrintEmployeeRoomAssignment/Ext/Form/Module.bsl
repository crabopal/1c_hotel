
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	WorkingHours = 12;
	ThisForm.Height = 297;
	ThisForm.Width = 210;
	cmSetSpreadsheetProtection(Items.OperationsSpreadsheet);
	FillPropertyValues(ThisForm, Parameters, "Hotel, Room, RoomSection, HousekeepingDepartment, WorkingHours, Employee, EmployeeIndex");
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	SelObjectPrintForm = PredefinedValue("Catalog.ObjectPrintingForms.OperationSchedulePrintOperationsByEmployees");
	SelShowDuration = False;
	SelShowNotAssigned = False;
	// Draw print form
	rDoPrint = Undefined;
	PrintOperations(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		pCancel = True;
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	// Draw invoice form
	rDoPrint = Undefined;
	PrintOperations(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // OnReopen

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	OperationsSpreadsheet.Print(PrintDialogUseMode.DontUse);
	Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	OperationsSpreadsheet.Print(PrintDialogUseMode.Use);
	Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "Employee_operations";
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, OperationsSpreadsheet);
EndProcedure // SaveAsPDF

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintOperations(rDoPrint = Undefined)
	// Basic checks
	vHotel = Hotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!';en='Hotel should be filled!'"));
		Return;
	EndIf;
	
	// Choose template
	vSpreadsheet = OperationsSpreadsheet;
	vSpreadsheet.Clear();
	vTemplate = Documents.OperationSchedule.GetTemplate("OperationsByEmployees");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Header
	If SelShowDuration Then
		vHeaderRow = vTemplate.GetArea("Header");
	Else
		vHeaderRow = vTemplate.GetArea("Header|WithoutDuration");
	EndIf;
	// Hotel
	mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, SessionParameters.CurrentLanguage);
	mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, SessionParameters.CurrentLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SessionParameters.CurrentLanguage) + vHotelFax);
	// Document date and number
	mDocDate = cmGetDocumentDatePresentation(CurrentSessionDate());
	vDocNumber = 1;
	// Set parameters and put report section
	vHeaderRow.Parameters.mHotelPrintName = mHotelPrintName;
	vHeaderRow.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeaderRow.Parameters.mHotelPhones = mHotelPhones;
	vHeaderRow.Parameters.mDocDate = mDocDate;
	
	// Get template areas
	If SelShowDuration Then
		vEmployeeFooterRow = vTemplate.GetArea("EmployeeFooter");
		vRow = vTemplate.GetArea("Row");
		vRow1 = vTemplate.GetArea("Row1");
		vBirthdateRow = vTemplate.GetArea("BirthdateRow");
		vBirthdateRow1 = vTemplate.GetArea("BirthdateRow1");
	Else
		vEmployeeFooterRow = vTemplate.GetArea("EmployeeFooter|WithoutDuration");
		vRow = vTemplate.GetArea("Row|WithoutDuration");
		vRow1 = vTemplate.GetArea("Row1|WithoutDuration");
		vBirthdateRow = vTemplate.GetArea("BirthdateRow|WithoutDuration");
		vBirthdateRow1 = vTemplate.GetArea("BirthdateRow1|WithoutDuration");
	EndIf;
	If SelShowDuration Then
		vSignatureRow = vTemplate.GetArea("Signature");
	Else
		vSignatureRow = vTemplate.GetArea("Signature|WithoutDuration");
	EndIf;
	mAuthor = "";
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		mAuthor = SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(SessionParameters.CurrentLanguage);
	EndIf;
	vSignatureRow.Parameters.mAuthor = mAuthor;
	
	// Today
	vToday = Format(CurrentSessionDate(), "DF=dd.MM");
	
	// Get all operations
	vOperations = GetOperations();
	
	// Fill employee for sorting reasons
	vCurRoom = Undefined;
	vCurEmployee = Undefined;
	vCurEmployeeSortCode = Undefined;
	vCurOperation = Undefined;
	vCurOperationSortCode = Undefined;
	For Each vOprRow In vOperations Do
		If vOprRow.Room <> vCurRoom Then
			vCurRoom = vOprRow.Room;
			vCurEmployee = vOprRow.Employee;
			vCurEmployeeSortCode = vOprRow.EmployeeSortCode;
			vCurOperation = vOprRow.Operation;
			vCurOperationSortCode = vOprRow.OperationSortCode;
		Else
			vOprRow.Employee = vCurEmployee;
			vOprRow.EmployeeSortCode = vCurEmployeeSortCode;
			vOprRow.Operation = vCurOperation;
			vOprRow.OperationSortCode = vCurOperationSortCode;
		EndIf;
	EndDo;
	
	// Group by operations according to the print type
	vOperations.Sort("EmployeeSortCode, Employee, HotelSortCode, RoomSortCode, Room, OperationSortCode");
	
	// Print operations
	vEmpCount = 0;
	vEmpDuration = 0;
	
	vCurEmployee = Undefined;
	vCurOperation = Undefined;
	vCurRoom = Undefined;
	vRoomToSkip = Undefined;
	vExtraGuest = False;
	For Each vOprRow In vOperations Do
		If vOprRow.IsFinished Then
			Continue;
		EndIf;
		If ValueIsFilled(vOprRow.Operation) Then
			If SelShowNotAssigned Then
				If ValueIsFilled(vOprRow.Employee) Then
					vRoomToSkip = vOprRow.Room;
					Continue;
				EndIf;
			Else
				If Not ValueIsFilled(vOprRow.Employee) Then
					vRoomToSkip = vOprRow.Room;
					Continue;
				EndIf;
			EndIf;
		Else
			If vRoomToSkip = vOprRow.Room Then
				Continue;
			EndIf;
		EndIf;
		If vCurEmployee <> vOprRow.Employee Then
			// Print totals for the previous employee
			If vCurEmployee <> Undefined Then
				// Set parameters
				vEmployeeFooterRow.Parameters.mEmpCount = vEmpCount;
				If SelShowDuration Then
					vEmployeeFooterRow.Parameters.mEmpDuration = cmFormatDurationInHours(vEmpDuration/60);
				EndIf;
				// Put employee footer area
				vSpreadsheet.Put(vEmployeeFooterRow);
				// Put signature area
				vSpreadsheet.Put(vSignatureRow);
				// Put page break
				vSpreadsheet.PutHorizontalPageBreak();
			Endif;
			
			// Print employee header
			vCurEmployee = vOprRow.Employee;
			// Fill client area parameters
			mEmployee = TrimAll(vCurEmployee);
			// Set parameters
			If EmployeeIndex > 0 Then
				mDocNumber = Format(EmployeeIndex, "NFD=; NG=");
			Else
				mDocNumber = Format(vDocNumber, "NFD=; NG=");
			EndIf;
			vHeaderRow.Parameters.mDocNumber = mDocNumber;
			vHeaderRow.Parameters.mEmployee = mEmployee;
			// Initialize employee totals
			vEmpCount = 0;
			vEmpDuration = 0;
			// Put header
			vSpreadsheet.Put(vHeaderRow);
			
			vDocNumber = vDocNumber + 1;
		EndIf;
		// Fill row parameters
		If vCurRoom <> vOprRow.Room Then
			vExtraGuest = False;
			vCurRoom = vOprRow.Room;
			mRoom = TrimAll(TrimAll(vOprRow.Room) + ?(ValueIsFilled(vOprRow.RoomType), " " + TrimAll(vOprRow.RoomType.Code), ""));
			mOperation = TrimAll(vOprRow.Operation);
			If valueIsFilled(vOprRow.RoomStatus) Then
				mRoomStatus = TrimAll(vOprRow.RoomStatus);
			Else
				mRoomStatus = "";
			EndIf;
			If vOprRow.IsCheckInWaiting And vOprRow.ExpectedNumberOfGuests > 0 Then
				mIsCheckInWaiting = Format(vOprRow.ExpectedNumberOfGuests, "ND=10; NFD=0; NZ=; NG=") + NStr("en=' prs.'; ru=' чел.'; de=' prs.'");
			Else
				mIsCheckInWaiting = vOprRow.IsCheckInWaiting;
			EndIf;
		Else
			vExtraGuest = True;
			mRoom = "";
			mRoomStatus = "";
			mIsCheckInWaiting = "";
		EndIf;
		mOperationRemarks = ?(ValueIsFilled(vOprRow.Guest), TrimAll(vOprRow.Guest.FullName), "");
		// Check date of birth
		vIsBirthdate = False;
		vBirthdate = "";
		If TypeOf(vOprRow.GuestDateOfBirth) = Type("Date") And ValueIsFilled(vOprRow.GuestDateOfBirth) Then
			vBirthdate = Format(vOprRow.GuestDateOfBirth, "DF=dd.MM");
			mOperationRemarks = mOperationRemarks + ", " + NStr("en='b.d. '; ru='д.р. '; de='G.D. '") + Format(vOprRow.GuestDateOfBirth, "DF=dd.MM.yyyy");
		EndIf;
		If vToday = vBirthdate Then
			vIsBirthdate = True;
		EndIf;
		// Add citizenship
		If ValueIsFilled(vOprRow.GuestCitizenship) Then
			mOperationRemarks = mOperationRemarks + " (" + TrimAll(vOprRow.GuestCitizenship.ISOCode) + ")";
		EndIf;
		mPeriod = "";
		If ValueIsFilled(vOprRow.CheckInDate) Then
			If Not ValueIsFilled(vOprRow.CheckOutDate) Then
				mPeriod = mPeriod + NStr("en='From ';ru='С ';de='Ab '");
			EndIf;
			mPeriod = mPeriod + Format(vOprRow.CheckInDate, "DF='dd.MM HH:mm'");
			If ValueIsFilled(vOprRow.CheckOutDate) Then
				mPeriod = mPeriod + " - ";
			EndIf;
		EndIf;
		If ValueIsFilled(vOprRow.CheckOutDate) Then
			If Not ValueIsFilled(vOprRow.CheckInDate) Then
				mPeriod = mPeriod + NStr("en='Till ';ru='По ';de='Bis '");
			EndIf;
			mPeriod = mPeriod + Format(vOprRow.CheckOutDate, "DF='dd.MM HH:mm'");
		EndIf;
		If ValueIsFilled(vOprRow.Operation) Then
			mCount = 1;
			mDuration = cmFormatDurationInHours(vOprRow.Duration/60);
			
			vEmpCount = vEmpCount + 1;
			vEmpDuration = vEmpDuration + vOprRow.Duration;
		EndIf;
		mStayDay = vOprRow.StayDay;
		If vOprRow.NumberOfGuests > 0 Then
			mNumberOfGuests = Format(vOprRow.NumberOfGuests, "ND=10; NFD=0; NZ=; NG=") + NStr("en=' prs.'; ru=' чел.'; de=' prs.'");
		Else
			mNumberOfGuests = "";
		EndIf;
		mClientType = vOprRow.ClientType;
		// Set parameters
		If Not vIsBirthdate Then
			vPrtRow = vRow;
			vPrtRow1 = vRow1;
		Else
			vPrtRow = vBirthdateRow;
			vPrtRow1 = vBirthdateRow1;
		EndIf;
		If Not vExtraGuest Then
			vPrtRow.Parameters.mRoom = mRoom;
			vPrtRow.Parameters.mOperation = mOperation;
			vPrtRow.Parameters.mOperationRemarks = mOperationRemarks;
			vPrtRow.Parameters.mPeriod = mPeriod;
			vPrtRow.Parameters.mStayDay = mStayDay;
			vPrtRow.Parameters.mNumberOfGuests = mNumberOfGuests;
			vPrtRow.Parameters.mClientType = mClientType;
			vPrtRow.Parameters.mIsCheckInWaiting = mIsCheckInWaiting;
			vPrtRow.Parameters.mRoomStatus = mRoomStatus;
			If SelShowDuration Then
				vPrtRow.Parameters.mDuration = mDuration;
			EndIf;
			// Put row
			vSpreadsheet.Put(vPrtRow);
		Else
			vPrtRow1.Parameters.mOperationRemarks = mOperationRemarks;
			vPrtRow1.Parameters.mPeriod = mPeriod;
			vPrtRow1.Parameters.mStayDay = mStayDay;
			vPrtRow1.Parameters.mClientType = mClientType;
			If SelShowDuration Then
				vPrtRow1.Parameters.mDuration = mDuration;
			EndIf;
			// Put row
			vSpreadsheet.Put(vPrtRow1);
		EndIf;
	EndDo;
	// Print totals for the previous operation
	vEmployeeFooterRow.Parameters.mEmpCount = vEmpCount;
	If SelShowDuration Then
		vEmployeeFooterRow.Parameters.mEmpDuration = cmFormatDurationInHours(vEmpDuration/60);
	EndIf;
	// Put employee footer area
	vSpreadsheet.Put(vEmployeeFooterRow);
	// Signature
	vSpreadsheet.Put(vSignatureRow);

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", SelObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(OperationsSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = "Employee_operations";
						cmDoSpreadsheetOutput(OperationsSpreadsheet, vPrintSettings, vName, SessionParameters.CurrentLanguage, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintOperations

// -----------------------------------------------------------------------------
&AtServer
Function GetOperations() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	Operations.Hotel AS Hotel,
	|	Operations.Hotel.SortCode AS HotelSortCode,
	|	Operations.Room AS Room,
	|	Operations.Room.SortCode AS RoomSortCode,
	|	Operations.RoomType AS RoomType,
	|	Operations.RoomType.SortCode AS RoomTypeSortCode,
	|	Operations.Room.RoomStatus AS RoomStatus,
	|	Operations.Operation AS Operation,
	|	Operations.Operation.SortCode AS OperationSortCode,
	|	Operations.Employee AS Employee,
	|	Operations.Employee.SortCode AS EmployeeSortCode,
	|	Operations.Employee.Description AS EmployeeDescription,
	|	Operations.NumberOfPersons AS NumberOfGuests,
	|	Operations.Duration AS Duration,
	|	ISNULL(ExpectedCheckIn.ExpectedNumberOfGuests, 0) AS ExpectedNumberOfGuests,
	|	CASE
	|		WHEN Operations.OperationEndTime > &qEmptyDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsFinished,
	|	CASE
	|		WHEN ExpectedCheckIn.ExpectedNumberOfGuests IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS IsCheckInWaiting
	|INTO AllOperations
	|FROM
	|	Document.EmployeeOperation AS Operations
	|		LEFT JOIN (SELECT
	|			Reservations.Room AS Room,
	|			SUM(Reservations.NumberOfPersons) AS ExpectedNumberOfGuests
	|		FROM
	|			Document.Reservation AS Reservations
	|		WHERE
	|			Reservations.Posted
	|			AND Reservations.ReservationStatus.IsActive
	|			AND Reservations.CheckInDate >= &qPeriodFrom
	|			AND Reservations.CheckInDate <= &qPeriodTo
	|		
	|		GROUP BY
	|			Reservations.Room) AS ExpectedCheckIn
	|		ON (ExpectedCheckIn.Room = Operations.Room)
	|WHERE
	|	(Operations.Hotel = &qHotel
	|			OR &qIsEmptyHotel)
	|	AND (Operations.Room IN HIERARCHY (&qRoom)
	|			OR &qIsEmptyRoom)
	|	AND (Operations.Room.RoomSection IN HIERARCHY (&qRoomSection)
	|			OR &qIsEmptyRoomSection)
	|	AND (Operations.Employee.Department IN HIERARCHY (&qDepartment)
	|			OR &qIsEmptyDepartment)
	|	AND (Operations.Employee IN HIERARCHY (&qEmployee)
	|			OR &qIsEmptyEmployee)
	|	AND Operations.Posted
	|	AND (Operations.OperationEndTime = &qEmptyDate
	|			OR Operations.OperationEndTime <> &qEmptyDate
	|				AND Operations.OperationEndTime <= &qPeriodTo
	|				AND Operations.OperationEndTime >= &qPeriodFrom)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Accommodations.Ref AS Ref,
	|	Accommodations.Room AS Room,
	|	Accommodations.SortCode AS SortCode,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.Guest.Code AS GuestCode,
	|	Accommodations.Guest.DateOfBirth AS GuestDateOfBirth,
	|	Accommodations.Guest.Citizenship AS GuestCitizenship,
	|	Accommodations.CheckInDate AS CheckInDate,
	|	Accommodations.CheckOutDate AS CheckOutDate,
	|	DATEDIFF(Accommodations.CheckInDate, &qCurrentDate, DAY) AS StayDay,
	|	Accommodations.ClientType AS ClientType
	|INTO AllAccommodations
	|FROM
	|	Document.Accommodation AS Accommodations
	|		INNER JOIN AllOperations AS Operations
	|		ON Accommodations.Room = Operations.Room
	|WHERE
	|	Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.CheckInDate < &qPeriodTo
	|	AND Accommodations.CheckOutDate > &qPeriodFrom
	|	AND Accommodations.Guest <> VALUE(Catalog.Clients.EmptyRef)
	|	AND Accommodations.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WeightedAccommodations1.Room AS Room,
	|	MIN(WeightedAccommodations1.SortCode) AS MinSortCode
	|INTO WeightedAccommodations1
	|FROM
	|	AllAccommodations AS WeightedAccommodations1
	|
	|GROUP BY
	|	WeightedAccommodations1.Room
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WeightedAccommodations2.Room AS Room,
	|	WeightedAccommodations2.SortCode AS MinSortCode,
	|	MIN(WeightedAccommodations2.GuestCode) AS MinGuestCode
	|INTO WeightedAccommodations2
	|FROM
	|	AllAccommodations AS WeightedAccommodations2
	|		INNER JOIN WeightedAccommodations1 AS WeightedAccommodations1
	|		ON WeightedAccommodations2.Room = WeightedAccommodations1.Room
	|			AND WeightedAccommodations2.SortCode = WeightedAccommodations1.MinSortCode
	|
	|GROUP BY
	|	WeightedAccommodations2.Room,
	|	WeightedAccommodations2.SortCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Accommodations.Room AS Room,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.GuestCode AS GuestCode,
	|	Accommodations.GuestDateOfBirth AS GuestDateOfBirth,
	|	Accommodations.GuestCitizenship AS GuestCitizenship,
	|	Accommodations.CheckInDate AS CheckInDate,
	|	Accommodations.CheckOutDate AS CheckOutDate,
	|	Accommodations.StayDay AS StayDay,
	|	Accommodations.ClientType AS ClientType
	|INTO Accommodations
	|FROM
	|	AllAccommodations AS Accommodations
	|		INNER JOIN WeightedAccommodations2 AS WeightedAccommodations2
	|		ON Accommodations.Room = WeightedAccommodations2.Room
	|			AND Accommodations.SortCode = WeightedAccommodations2.MinSortCode
	|			AND Accommodations.GuestCode = WeightedAccommodations2.MinGuestCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Operations.Hotel AS Hotel,
	|	Operations.Hotel.SortCode AS HotelSortCode,
	|	Operations.Room AS Room,
	|	Operations.RoomSortCode AS RoomSortCode,
	|	Operations.RoomType AS RoomType,
	|	Operations.RoomTypeSortCode AS RoomTypeSortCode,
	|	Operations.RoomStatus AS RoomStatus,
	|	Operations.Operation AS Operation,
	|	Operations.OperationSortCode AS OperationSortCode,
	|	Operations.Employee AS Employee,
	|	Operations.EmployeeSortCode AS EmployeeSortCode,
	|	Operations.EmployeeDescription AS EmployeeDescription,
	|	Operations.NumberOfGuests AS NumberOfGuests,
	|	Operations.Duration AS Duration,
	|	Operations.ExpectedNumberOfGuests AS ExpectedNumberOfGuests,
	|	Operations.IsFinished AS IsFinished,
	|	Operations.IsCheckInWaiting AS IsCheckInWaiting,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.GuestDateOfBirth AS GuestDateOfBirth,
	|	Accommodations.GuestCitizenship AS GuestCitizenship,
	|	Accommodations.CheckInDate AS CheckInDate,
	|	Accommodations.CheckOutDate AS CheckOutDate,
	|	Accommodations.StayDay AS StayDay,
	|	Accommodations.ClientType AS ClientType
	|FROM
	|	AllOperations AS Operations
	|		LEFT JOIN Accommodations AS Accommodations
	|		ON (Accommodations.Room = Operations.Room)
	|
	|ORDER BY
	|	Operations.EmployeeSortCode,
	|	Operations.EmployeeDescription,
	|	Operations.RoomSortCode";
	vQry.SetParameter("qPeriodFrom", CurrentSessionDate() - WorkingHours*3600);
	vQry.SetParameter("qPeriodTo", CurrentSessionDate() + WorkingHours*3600);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qRoom", Room);
	vQry.SetParameter("qIsEmptyRoom", Not ValueIsFilled(Room));
    vQry.SetParameter("qRoomSection", RoomSection);
    vQry.SetParameter("qIsEmptyRoomSection", Not ValueIsFilled(RoomSection));
	vQry.SetParameter("qDepartment", HousekeepingDepartment);
	vQry.SetParameter("qIsEmptyDepartment", Not ValueIsFilled(HousekeepingDepartment));
	vQry.SetParameter("qEmployee", Employee);
	vQry.SetParameter("qIsEmptyEmployee", Not ValueIsFilled(Employee));
	Return vQry.Execute().Unload();
EndFunction // GetOperations

#EndRegion

