
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	cmSetSpreadsheetProtection(Items.OperationsSpreadsheet);
	FillPropertyValues(ThisForm, Parameters, "SelHotel, SelRoom, SelRoomSection, SelEmployee, SelOperationSchedule, SelObjectPrintForm, SelShowDuration, SelShowNotAssigned, SelGroupBy");
	If Not ValueIsFilled(SelObjectPrintForm) Then
		SelObjectPrintForm = Catalogs.ObjectPrintingForms.OperationSchedulePrintOperationsByEmployees;
		SelShowDuration = False;
		SelShowNotAssigned = False;
		SelGroupBy = "";
	EndIf;
	If ValueIsFilled(SelObjectPrintForm) And ValueIsFilled(SelObjectPrintForm.Parameter) Then
		If Find(SelObjectPrintForm.Parameter, "SHOW_REMARKS") > 0 Then
			SelShowRemarks = True;
		EndIf; 
		If Find(SelObjectPrintForm.Parameter, "GROUP_BY_ROOM") > 0 Then
			SelGroupByRoom = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Generate print form
	rDoPrint = Undefined;
	GenerateAtServer(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		pCancel = True;
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure GeneratePrintForm(pCommand)
	rDoPrint = Undefined;
	GenerateAtServer(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
EndProcedure // GeneratePrintForm

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	OperationsSpreadsheet.Print(PrintDialogUseMode.DontUse);
	ThisForm.Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	OperationsSpreadsheet.Print(PrintDialogUseMode.Use);
	ThisForm.Close();
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
Procedure GenerateAtServer(rDoPrint = Undefined)
	If SelObjectPrintForm = Catalogs.ObjectPrintingForms.OperationSchedulePrintOperationsByEmployees Then
		PrintByEmployees(rDoPrint);
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.OperationSchedulePrintOperationsByEmployeesShort Then
		PrintByEmployeesShort(rDoPrint);
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.OperationSchedulePrintOperationsByOperations Then
		PrintByOperations(rDoPrint);
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.OperationSchedulePrintOperationsByRooms Then
		PrintByOperations(rDoPrint);
	ElsIf SelObjectPrintForm = Catalogs.ObjectPrintingForms.OperationSchedulePrintEmployees Then
		PrintEmployees(rDoPrint);
	EndIf;
EndProcedure // GenerateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintByEmployees(rDoPrint = Undefined)
	// Basic checks
	If Not ValueIsFilled(SelOperationSchedule) Then
		Raise NStr("ru='План работ не записан!';de='Arbeitsplan ist nicht gespeichert!';en='Operations plan is not saved!'");
	EndIf;
	SelHotel = SelOperationSchedule.Hotel;
	If Not ValueIsFilled(SelHotel) Then
		Raise NStr("ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!';en='Hotel should be filled!'");
	EndIf;
	
	// Parameters
	vShowOneGuestOnly = False;
	If ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
		If Find(SelObjectPrintForm.Parameter, "SHOW_ONE_GUEST_PER_ROOM_ONLY") > 0 Then
			vShowOneGuestOnly = True;
		EndIf;
	EndIf;
	
	vShowBirthDate = False;
	If ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
		If Find(SelObjectPrintForm.Parameter, "SHOW_GUEST_DATE_OF_BIRTH") > 0 Then
			vShowBirthDate = True;
		EndIf;
	EndIf;        
	vShowDiscountType = False;
	If ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
		If Find(SelObjectPrintForm.Parameter, "SHOW_DISCOUNT_TYPE") > 0 Then
			vShowDiscountType = True;
		EndIf;
	EndIf;
	
	// Choose template
	vSpreadsheet = OperationsSpreadsheet;
	vSpreadsheet.Clear();
	vOprObj = SelOperationSchedule.GetObject();
	vTemplate = vOprObj.GetTemplate("OperationsByEmployees");
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
	vHotel = SelHotel;
	vHotelObj = vHotel.GetObject();
	mHotelPrintName = vHotelObj.pmGetHotelPrintName(SessionParameters.CurrentLanguage);
	mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(SessionParameters.CurrentLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SessionParameters.CurrentLanguage) + vHotelFax);
	// Document date and number
	mDocNumber = cmGetDocumentNumberPresentation(SelOperationSchedule.Number);
	mDocDate = cmGetDocumentDatePresentation(SelOperationSchedule.Date);
	// Set parameters and put report section
	vHeaderRow.Parameters.mHotelPrintName = mHotelPrintName;
	vHeaderRow.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeaderRow.Parameters.mHotelPhones = mHotelPhones;
	vHeaderRow.Parameters.mDocNumber = mDocNumber;
	vHeaderRow.Parameters.mDocDate = mDocDate;
	
	// Get template areas
	If SelShowDuration Then
		vEmployeeFooterRow = vTemplate.GetArea("EmployeeFooter");
		vRow = vTemplate.GetArea("Row");
		vRow1 = vTemplate.GetArea("Row1");
		vBirthdateRow = vTemplate.GetArea("BirthdateRow");
		vBirthdateRow1 = vTemplate.GetArea("BirthdateRow1");
		vRemarksRow = vTemplate.GetArea("Remarks");
	Else
		vEmployeeFooterRow = vTemplate.GetArea("EmployeeFooter|WithoutDuration");
		vRow = vTemplate.GetArea("Row|WithoutDuration");
		vRow1 = vTemplate.GetArea("Row1|WithoutDuration");
		vBirthdateRow = vTemplate.GetArea("BirthdateRow|WithoutDuration");
		vBirthdateRow1 = vTemplate.GetArea("BirthdateRow1|WithoutDuration");
		vRemarksRow = vTemplate.GetArea("Remarks|WithoutDuration");
	EndIf;
		If SelShowDuration Then
		vSignatureRow = vTemplate.GetArea("Signature");
	Else
		vSignatureRow = vTemplate.GetArea("Signature|WithoutDuration");
	EndIf;
	mAuthor = "";
	If ValueIsFilled(SelOperationSchedule.Author) Then
		mAuthor = SelOperationSchedule.Author.GetObject().pmGetEmployeeDescription(SessionParameters.CurrentLanguage);
	EndIf;
	vSignatureRow.Parameters.mAuthor = mAuthor;
	
	// Today
	vToday = Format(SelOperationSchedule.Date, "DF=dd.MM");
	
	// Get all operations
	vOperations = SelOperationSchedule.Operations.Unload();
	
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
			If Not ValueIsFilled(vOprRow.Operation) Then
				vOprRow.Employee = vCurEmployee;
				vOprRow.EmployeeSortCode = vCurEmployeeSortCode;
				vOprRow.Operation = vCurOperation;
				vOprRow.OperationSortCode = vCurOperationSortCode;
			EndIf;
		EndIf;
	EndDo;
	
	// Group by operations according to the print type
	vOperations.Sort("EmployeeSortCode, Employee, HotelSortCode, RoomSortCode, Room, OperationSortCode");
	
	// Print operations
	vEmpCount = 0;
	vEmpDuration = 0;
	vNumberOfGuests = 0;
	
	vCurEmployee = Undefined;
	vCurOperation = Undefined;
	vCurRoom = Undefined;
	vExtraGuest = False;   
	vPrevRow = Undefined;
	For Each vOprRow In vOperations Do
		If (Not ValueIsFilled(vOprRow.Operation) Or Not ValueIsFilled(vOprRow.Employee)) And Not SelShowNotAssigned Then
			Continue;	
		EndIf;
		If ValueIsFilled(SelRoom) Then
			If Not vOprRow.Room.BelongsToItem(SelRoom) Then
				Continue;
			EndIf;
		EndIf;
		If ValueIsFilled(SelRoomSection) Then
			If vOprRow.Room.RoomSection <> SelRoomSection Then
				Continue;
			EndIf;
		EndIf;
		If ValueIsFilled(SelEmployee) Then
			If vOprRow.Employee <> SelEmployee Then
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
			vHeaderRow.Parameters.mEmployee = mEmployee;
			// Initialize employee totals
			vEmpCount = 0;
			vEmpDuration = 0;
			// Put header
			vSpreadsheet.Put(vHeaderRow);
			
			// Reset current room
			vCurRoom = Undefined;
		EndIf;	
		// Fill row parameters
		If vCurRoom <> vOprRow.Room Or vCurRoom = vOprRow.Room And vCurOperation <> vOprRow.Operation Then
			vExtraGuest = False;
			vNumberOfGuests = 0;
			vRoomRows = vOperations.FindRows(New Structure("Room", vOprRow.Room));
			For Each vRoomRow In vRoomRows Do
				If vRoomRow.NumberOfGuests > 0 Then
					vNumberOfGuests = vRoomRow.NumberOfGuests;
					Break;
				EndIf;
			EndDo;
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
			vCurOperation = Undefined;
		Else
			If vShowOneGuestOnly And (vCurOperation = vOprRow.Operation Or Not ValueIsFilled(vOprRow.Operation)) Then
				Continue;
			EndIf;
			vExtraGuest = True;
			mRoom = "";
			mRoomStatus = "";
			mIsCheckInWaiting = "";
		EndIf;   
		mOperationRemarks = TrimAll(vOprRow.OperationRemarks);
		// Citizenship
		If ValueIsFilled(vOprRow.Citizenship) And ValueIsFilled(SelOperationSchedule.Hotel) And 
		   vOprRow.Citizenship <> SelOperationSchedule.Hotel.Citizenship Then
			mOperationRemarks = "(" + TrimAll(vOprRow.Citizenship.ISOCode) + ") " + mOperationRemarks ;
		EndIf;
		// Check date of birth
		vIsBirthdate = False;
		vCommaPos = Find(mOperationRemarks, ", ");
		If vCommaPos > 0 Then
			vBirthdate = Left(Mid(mOperationRemarks, vCommaPos + 2), 5);
			If vToday = vBirthdate Then
				vIsBirthdate = True;
			EndIf;
		EndIf;
		// Remove date of birth
		If Not vShowBirthDate And Mid(vBirthdate, 3, 1) = "." Then
			If vCommaPos > 0 Then
				mOperationRemarks = TrimAll(Left(mOperationRemarks, vCommaPos - 1));
			EndIf;
		EndIf;
		// Fill guest loyalty program attributes 
		If vShowDiscountType Then   
			mClientType = "";
			If ValueIsFilled(vOprRow.Guest) Then
				vGuest = vOprRow.Guest;	
				If ValueIsFilled(vGuest.DiscountCard) Then 
					mClientType	= ?(ValueIsFilled(vGuest.DiscountCard.DiscountType), vGuest.DiscountCard.DiscountType.Code, "");	
				ElsIf ValueIsFilled(vGuest.DiscountType) Then	
					mClientType	= ?(ValueIsFilled(vGuest.DiscountType), vGuest.DiscountType.Code, "");
				EndIf;	
			EndIf;
		Else	
			mClientType = ?(ValueIsFilled(vOprRow.ClientType), vOprRow.ClientType.Code, "");
			mDiscountCard = "";
			mVIP = "";
			mRank = "";
			If ValueIsFilled(vOprRow.Guest) Then
				vGuest = vOprRow.Guest; 
				If vGuest.IsInWhiteList Then
					mVIP = "VIP";
				EndIf;
				If ValueIsFilled(vGuest.DiscountCard) Then
					mDiscountCard = TrimAll(vGuest.DiscountCard); 	
				EndIf;
				If ValueIsFilled(vGuest.MilitaryRank) Then
					mRank = TrimAll(vGuest.MilitaryRank.Code); 	
				EndIf;
			EndIf;
				mClientType = mClientType + 
				              ?(IsBlankString(mVIP), "", Chars.LF + mVIP) 
							  + ?(IsBlankString(mDiscountCard), "", Chars.LF + mDiscountCard) 
							  + ?(IsBlankString(mRank), "", Chars.LF + mRank);  
		EndIf;			  
		// Period
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
		If ValueIsFilled(vOprRow.Operation) And vOprRow.Operation <> vCurOperation Then
			vCurOperation = vOprRow.Operation;
			
			mDuration = cmFormatDurationInHours(vOprRow.Duration/60);
			
			vEmpCount = vEmpCount + 1;
			vEmpDuration = vEmpDuration + vOprRow.Duration;
		Else
			mDuration = "";
		EndIf;
		mStayDay = vOprRow.StayDay;
		If vNumberOfGuests > 0 Then
			mNumberOfGuests = Format(vNumberOfGuests, "ND=10; NFD=0; NZ=; NG=") + NStr("en=' prs.'; ru=' чел.'; de=' prs.'");
		Else
			mNumberOfGuests = "";
		EndIf;    
		If SelGroupByRoom And vPrevRow <> Undefined And vPrevRow.Room = vOprRow.Room Then
			mRoom = "";	 
			mRoomStatus = "";  
			If vOprRow.Guest = vPrevRow.Guest Then
				mOperationRemarks = "";
				mPeriod = ""; 
				mNumberOfGuests = ""; 
				mClientType = "";   
				mStayDay = "";
				mDuration = "";
				mIsCheckInWaiting = ""; 
			EndIf;	
		EndIf;	
		vPrevRow = vOprRow;	

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
		If SelShowRemarks And ValueIsFilled(vOprRow.Employee) Then
			If vOperations.IndexOf(vOprRow) + 1 = vOperations.Count() Or vOperations.IndexOf(vOprRow) + 1 < vOperations.Count() And (vCurRoom <> vOperations[vOperations.IndexOf(vOprRow) + 1].Room Or vCurEmployee <> vOperations[vOperations.IndexOf(vOprRow) + 1].Employee) Then  
				vHousekeepingRemarks = "";
				vTasksRemarks = "";
				vRoomRows = vOperations.FindRows(New Structure("Room", vOprRow.Room));
				i = 0;
				For Each vRoomRow In vRoomRows Do    
					If IsBlankString(vHousekeepingRemarks) Then
						vHousekeepingRemarks = ?(IsBlankString(vRoomRow.Remarks), "", TrimAll(vRoomRow.Remarks));
					Else
						vHousekeepingRemarks = vHousekeepingRemarks + ?(IsBlankString(vRoomRow.Remarks), "", Chars.LF + TrimAll(vRoomRow.Remarks));
					EndIf;	
					vShowCurrentBedsSetup = True;
					If ValueIsFilled(vRoomRow.ParentDoc) And (TypeOf(vRoomRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vRoomRow.ParentDoc) = Type("DocumentRef.Reservation")) Then
						vParentDocRemarks = TrimAll(vRoomRow.ParentDoc.HousekeepingRemarks);
						If Not IsBlankString(vParentDocRemarks) Then
							If IsBlankString(vHousekeepingRemarks) Then
								vHousekeepingRemarks = vParentDocRemarks;
							Else
								If StrFind(vHousekeepingRemarks, vParentDocRemarks) = 0 Then
									vHousekeepingRemarks = vHousekeepingRemarks + Chars.LF + vParentDocRemarks;
								EndIf;
							EndIf;
						EndIf;
						If i = 0 And ValueIsFilled(vRoomRow.ParentDoc.BedsSetup) And vOprRow.Room.BedsSetup <> vRoomRow.ParentDoc.BedsSetup Then
							vShowCurrentBedsSetup = False;
							If ValueIsFilled(vOprRow.Room.BedsSetup) Then
								vHousekeepingRemarks = vHousekeepingRemarks + ?(IsBlankString(vHousekeepingRemarks), "", Chars.LF) + NStr("en='Beds in room: '; ru='Кровати в номере: '; de='Betten in Zimmer: '") + TrimAll(vOprRow.Room.BedsSetup) + NStr("en=', requested: '; ru=', требуются: '; de=', ersuchten: '") + TrimAll(vRoomRow.ParentDoc.BedsSetup);
							Else
								vHousekeepingRemarks = vHousekeepingRemarks + ?(IsBlankString(vHousekeepingRemarks), "", Chars.LF) + NStr("en='Beds requested: '; ru='Требуются кровати: '; de='Betten ersuchten: '") + TrimAll(vRoomRow.ParentDoc.BedsSetup);
							EndIf;
						EndIf;
					EndIf;
					If i = 0 And ValueIsFilled(vOprRow.Room.BedsSetup) And vShowCurrentBedsSetup Then
						vHousekeepingRemarks = vHousekeepingRemarks + ?(IsBlankString(vHousekeepingRemarks), "", Chars.LF) + NStr("en='Beds in room: '; ru='Кровати в номере: '; de='Betten in Zimmer: '") + TrimAll(vOprRow.Room.BedsSetup);
					EndIf;
					i = i + 1;
				EndDo;
				If ValueIsFilled(TrimAll(vHousekeepingRemarks)) Then
					vRemarksRow.Parameters.mRemarks = vHousekeepingRemarks;
					vSpreadsheet.Put(vRemarksRow);
				EndIf;
				vRoomRows = vOperations.FindRows(New Structure("Room, RoomType, IsManual", vOprRow.Room, vOprRow.Room.RoomType, False));
				For Each vRoomRow In vRoomRows Do    
					If ValueIsFilled(vRoomRow.ParentDoc) Then
						vTasks = cmGetMessagesForObject(vRoomRow.ParentDoc, , , , , , , , True);
						For Each vTasksRow In vTasks Do
							If vTasksRow.ForEmployee = vOprRow.Employee Or vTasksRow.ForEmployee = Catalogs.Employees.EmptyRef() Then 
								vTasksRemarks = vTasksRemarks + ?(ValueIsFilled(vTasksRemarks), ", " + vTasksRow.Remarks, vTasksRow.Remarks); 
							EndIf;
						EndDo;
					EndIf;
				EndDo;
				vTasks = cmGetMessagesForObject(vOprRow.Room, , , , , , , , True);
				For Each vTasksRow In vTasks Do
					If vTasksRow.ForEmployee = vOprRow.Employee Or vTasksRow.ForEmployee = Catalogs.Employees.EmptyRef() Then 
						vTasksRemarks = vTasksRemarks + ?(ValueIsFilled(vTasksRemarks), ", " + vTasksRow.Remarks, vTasksRow.Remarks); 
					EndIf;
				EndDo;
				If ValueIsFilled(TrimAll(vTasksRemarks)) Then
					vRemarksRow.Parameters.mRemarks = "• " + vTasksRemarks + " •";
					vSpreadsheet.Put(vRemarksRow);
				EndIf;
			EndIf;
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
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Operations schedule';ru='План работ';de='Arbeitsplan'")) + " " + mDocDate;
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, SessionParameters.CurrentLanguage, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintByEmployees

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintByEmployeesShort(rDoPrint = Undefined)
	// Basic checks
	If Not ValueIsFilled(SelOperationSchedule) Then
		Raise NStr("ru='План работ не записан!';de='Arbeitsplan ist nicht gespeichert!';en='Operations plan is not saved!'");
	EndIf;
	SelHotel = SelOperationSchedule.Hotel;
	If Not ValueIsFilled(SelHotel) Then
		Raise NStr("ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!';en='Hotel should be filled!'");
	EndIf;
		
	// Choose template
	vSpreadsheet = OperationsSpreadsheet;
	vSpreadsheet.PageOrientation = PageOrientation.Landscape;
	vSpreadsheet.Clear();
	
	vOprObj = SelOperationSchedule.GetObject();
	vTemplate = vOprObj.GetTemplate("OperationsByEmployeesShort");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	mDocDate = cmGetDocumentDatePresentation(SelOperationSchedule.Date);
	vEmptyRow = vTemplate.GetArea("EmptyRow");	
	vOperations = SelOperationSchedule.Operations.Unload();
	vOperationsArr = vOperations.FindRows(New Structure("Operation", Catalogs.Operations.EmptyRef()));
	For Each vOperationArr In vOperationsArr Do
		vOperations.Delete(vOperationArr);	
	EndDo;
	vEmployees = SelOperationSchedule.Operations.Unload(,"Employee, EmployeeSortCode");
	vEmployees.GroupBy("Employee, EmployeeSortCode");
	
	vEmptyEmployees = vEmployees.FindRows(New Structure("Employee", Catalogs.Employees.EmptyRef()));
	For Each vEmptyEmployee In vEmptyEmployees Do
		vEmployees.Delete(vEmptyEmployee);	
	EndDo;
	 	
	vOperations.Sort("EmployeeSortCode, Employee, HotelSortCode, RoomSortCode, Room, OperationSortCode");
	vEmployees.Sort("EmployeeSortCode, Employee"); 

	vCountEmployees = vEmployees.Count();
	vUseCountEmployees = 0;
	While vCountEmployees - 1 >= vUseCountEmployees Do  
		vUseNumber = vCountEmployees - vUseCountEmployees - 1;
		If vUseNumber > 7 Then
			vUseNumber = 7;	
		EndIf;
		vUseEmployeesMap = New Map();
		vHeaderEmployeeRow = vTemplate.GetArea("EmployeeRow");
		For vNumber = 0 To vUseNumber Do
			vEmployee = vEmployees.Get(vUseCountEmployees);
			vOperationArr = vOperations.FindRows(New Structure("Employee", vEmployee.Employee));
			vUseEmployeesMap.Insert(TrimAll(vNumber + 1), vOperationArr); 
			vUseCountEmployees = vUseCountEmployees + 1;
			vHeaderEmployeeRow.Parameters["mEmployee_" + TrimAll(vNumber + 1)] = TrimAll(vEmployee.Employee) + Chars.LF + TrimAll(vOperationArr.Count()) + NStr("en=' oper. ';ru=' работ. ';de=' Arbeiten. '");
		EndDo;
		vHeaderEmployeeRow.Parameters.mDate = mDocDate;
		vSpreadsheet.Put(vHeaderEmployeeRow);
		vMaxCount = 0;
		For Each vUseEmployeeMap In vUseEmployeesMap Do
			vUseEmployeeMapCount = vUseEmployeeMap.Value.Count();
			If vMaxCount < vUseEmployeeMapCount Then
				vMaxCount = vUseEmployeeMapCount; 	
			EndIf;
		EndDo;
		For vNumber = 0 To vMaxCount - 1 Do
			vOperationRow = vTemplate.GetArea("OperationRow");
			For Each vUseEmployeeMap In vUseEmployeesMap Do
				If vUseEmployeeMap.Value.Count() > vNumber Then   
					vOperation = vUseEmployeeMap.Value.Get(vNumber);
					vOperationRepresentation = TrimAll(vOperation.Room.Description) + " " + TrimAll(vOperation.Operation.Code);
					If SelShowRemarks Then
						If (vUseEmployeeMap.Value.Count() > vNumber + 1 And vOperation.Room <> vUseEmployeeMap.Value[vNumber + 1].Room) Or vUseEmployeeMap.Value.Count() = vNumber + 1 Then 
							vHousekeepingRemarks = "";
							vTasksRemarks = "";
							vRoomRows = vOperations.FindRows(New Structure("Room", vOperation.Room));
							i = 0;
							For Each vRoomRow In vRoomRows Do
								vShowCurrentBedsSetup = True;
								If ValueIsFilled(vRoomRow.ParentDoc) And (TypeOf(vRoomRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vRoomRow.ParentDoc) = Type("DocumentRef.Reservation")) Then
									vParentDocRemarks = TrimAll(vRoomRow.ParentDoc.HousekeepingRemarks);
									If Not IsBlankString(vParentDocRemarks) Then
										If IsBlankString(vHousekeepingRemarks) Then
											vHousekeepingRemarks = vParentDocRemarks;
										Else
											If StrFind(vHousekeepingRemarks, vParentDocRemarks) = 0 Then
												vHousekeepingRemarks = vHousekeepingRemarks + Chars.LF + vParentDocRemarks;
											EndIf;
										EndIf;
									EndIf;
									If i = 0 And ValueIsFilled(vRoomRow.ParentDoc.BedsSetup) And vOperation.Room.BedsSetup <> vRoomRow.ParentDoc.BedsSetup Then
										vShowCurrentBedsSetup = False;
										If ValueIsFilled(vOperation.Room.BedsSetup) Then
											vHousekeepingRemarks = vHousekeepingRemarks + ?(IsBlankString(vHousekeepingRemarks), "", Chars.LF) + NStr("en='Beds in room: '; ru='Кровати в номере: '; de='Betten in Zimmer: '") + TrimAll(vOperation.Room.BedsSetup) + NStr("en=', requested: '; ru=', требуются: '; de=', ersuchten: '") + TrimAll(vRoomRow.ParentDoc.BedsSetup);
										Else
											vHousekeepingRemarks = vHousekeepingRemarks + ?(IsBlankString(vHousekeepingRemarks), "", Chars.LF) + NStr("en='Beds requested: '; ru='Требуются кровати: '; de='Betten ersuchten: '") + TrimAll(vRoomRow.ParentDoc.BedsSetup);
										EndIf;
									EndIf;
								EndIf;
								If i = 0 And ValueIsFilled(vOperation.Room.BedsSetup) And vShowCurrentBedsSetup Then
									vHousekeepingRemarks = vHousekeepingRemarks + ?(IsBlankString(vHousekeepingRemarks), "", Chars.LF) + NStr("en='Beds in room: '; ru='Кровати в номере: '; de='Betten in Zimmer: '") + TrimAll(vOperation.Room.BedsSetup);
								EndIf;
								i = i + 1;
							EndDo;
							If ValueIsFilled(TrimAll(vHousekeepingRemarks)) Then
								vOperationRepresentation = vOperationRepresentation + Chars.LF + vHousekeepingRemarks;
							EndIf;
							vRoomRows = vOperations.FindRows(New Structure("Room, RoomType, IsManual", vOperation.Room, vOperation.Room.RoomType, False));
							For Each vRoomRow In vRoomRows Do
								If ValueIsFilled(vRoomRow.ParentDoc) Then
									vTasks = cmGetMessagesForObject(vRoomRow.ParentDoc, , , , , , , , True);
									For Each vTasksRow In vTasks Do
										If vTasksRow.ForEmployee = vOperation.Employee Or vTasksRow.ForEmployee = Catalogs.Employees.EmptyRef() Then 
											vTasksRemarks = vTasksRemarks + ?(ValueIsFilled(vTasksRemarks), ", " + vTasksRow.Remarks, vTasksRow.Remarks); 
										EndIf;
									EndDo;
								EndIf;
							EndDo;
							vTasks = cmGetMessagesForObject(vOperation.Room, , , , , , , , True);
							For Each vTasksRow In vTasks Do
								If vTasksRow.ForEmployee = vOperation.Employee Or vTasksRow.ForEmployee = Catalogs.Employees.EmptyRef() Then 
									vTasksRemarks = vTasksRemarks + ?(ValueIsFilled(vTasksRemarks), ", " + vTasksRow.Remarks, vTasksRow.Remarks); 
								EndIf;
							EndDo;
							If ValueIsFilled(TrimAll(vTasksRemarks)) Then
								vOperationRepresentation = vOperationRepresentation + Chars.LF + "• " + vTasksRemarks + " •";
							EndIf;		
						EndIf;
					EndIf;
					vOperationRow.Parameters["mOperation_" + vUseEmployeeMap.Key] = vOperationRepresentation;
					If vOperation.IsNew Then 
						vOperationRow.Area("R1C" + vUseEmployeeMap.Key).BackColor = New Color(182, 239, 248);
					Else
						vOperationRow.Area("R1C" + vUseEmployeeMap.Key).BackColor = New Color();	
					EndIf;
				EndIf;		
			EndDo;
			If vSpreadsheet.CheckPut(vOperationRow) Then 
				vSpreadsheet.Put(vOperationRow);
			Else
				vSpreadsheet.PutHorizontalPageBreak();
				vSpreadsheet.Put(vHeaderEmployeeRow);
				vSpreadsheet.Put(vOperationRow);
			EndIf;
		EndDo;
		While vSpreadsheet.CheckPut(vEmptyRow) Do
			vSpreadsheet.Put(vEmptyRow);
		EndDo;
		vSpreadsheet.PutHorizontalPageBreak();
	EndDo;
		
	// Header
	vHeaderRow = vTemplate.GetArea("Header");
	vSpreadsheet.Put(vHeaderRow);
	
	// Get template areas
	vRow = vTemplate.GetArea("Row");	
	// Get all employees
	vEmployees = SelOperationSchedule.Employees.Unload();
	
	// Print employees
	For Each vEmpRow In vEmployees Do
		// Fill row parameters
		mEmployee = TrimAll(vEmpRow.Employee);
		mDepartment = TrimAll(vEmpRow.Department);
		mHours = cmFormatDurationInHours(vEmpRow.Hours);
		mDuration = cmFormatDurationInHours(vEmpRow.Duration);
		mRoomSpace = Format(vEmpRow.RoomSpace, "ND=8; NFD=2");
		mCheckOutCleaningCount = Format(vEmpRow.CheckOutCleaningCount, "ND=6; NFD=0");
		mRegularCleaningCount = Format(vEmpRow.RegularCleaningCount, "ND=6; NFD=0");
		mVacantRoomCleaningCount = Format(vEmpRow.VacantRoomCleaningCount, "ND=6; NFD=0");
		mRepairEndCleaningCount = Format(vEmpRow.RepairEndCleaningCount, "ND=6; NFD=0");
		mOtherOperationsCount = Format(vEmpRow.OtherOperationsCount, "ND=6; NFD=0");
		// Set parameters
		vRow.Parameters.mEmployee = mEmployee;
		vRow.Parameters.mDepartment = mDepartment;
		vRow.Parameters.mHours = mHours;
		vRow.Parameters.mDuration = mDuration;
		vRow.Parameters.mRoomSpace = mRoomSpace;
		vRow.Parameters.mCheckOutCleaningCount = mCheckOutCleaningCount;
		vRow.Parameters.mRegularCleaningCount = mRegularCleaningCount;
		vRow.Parameters.mVacantRoomCleaningCount = mVacantRoomCleaningCount;
		vRow.Parameters.mRepairEndCleaningCount = mRepairEndCleaningCount;
		vRow.Parameters.mOtherOperationsCount = mOtherOperationsCount;
		// Put row
		vSpreadsheet.Put(vRow);
	EndDo;
	
	// Footer
	vFooterRow = vTemplate.GetArea("Footer");
	// Fill parameters
	mTotalHours = cmFormatDurationInHours(vEmployees.Total("Hours"));
	mTotalDuration = cmFormatDurationInHours(vEmployees.Total("Duration"));
	mTotalRoomSpace = Format(vEmployees.Total("RoomSpace"), "ND=8; NFD=2");
	mTotalCheckOutCleaningCount = Format(vEmployees.Total("CheckOutCleaningCount"), "ND=6; NFD=0");
	mTotalRegularCleaningCount = Format(vEmployees.Total("RegularCleaningCount"), "ND=6; NFD=0");
	mTotalVacantRoomCleaningCount = Format(vEmployees.Total("VacantRoomCleaningCount"), "ND=6; NFD=0");
	mTotalRepairEndCleaningCount = Format(vEmployees.Total("RepairEndCleaningCount"), "ND=6; NFD=0");
	mTotalOtherOperationsCount = Format(vEmployees.Total("OtherOperationsCount"), "ND=6; NFD=0");
	// Set parameters
	vFooterRow.Parameters.mTotalHours = mTotalHours;
	vFooterRow.Parameters.mTotalDuration = mTotalDuration;
	vFooterRow.Parameters.mTotalRoomSpace = mTotalRoomSpace;
	vFooterRow.Parameters.mTotalCheckOutCleaningCount = mTotalCheckOutCleaningCount;
	vFooterRow.Parameters.mTotalRegularCleaningCount = mTotalRegularCleaningCount;
	vFooterRow.Parameters.mTotalVacantRoomCleaningCount = mTotalVacantRoomCleaningCount;
	vFooterRow.Parameters.mTotalRepairEndCleaningCount = mTotalRepairEndCleaningCount;
	vFooterRow.Parameters.mTotalOtherOperationsCount = mTotalOtherOperationsCount;
	// Put footer
	vSpreadsheet.Put(vFooterRow);
	
	vSpreadsheet.Header.CenterText = TrimAll(SelHotel);
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Landscape, True, , True);
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
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Operations schedule';ru='План работ';de='Arbeitsplan'")) + " " + mDocDate;
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, SessionParameters.CurrentLanguage, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintByEmployeesShort

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintByOperations(rDoPrint = Undefined)
	// Basic checks
	If Not ValueIsFilled(SelOperationSchedule) Then
		Raise NStr("ru='План работ не записан!';de='Arbeitsplan ist nicht gespeichert!';en='Operations plan is not saved!'");
	EndIf;
	SelHotel = SelOperationSchedule.Hotel;
	If Not ValueIsFilled(SelHotel) Then
		Raise NStr("ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!';en='Hotel should be filled!'");
	EndIf;
	
	// Parameters
	vShowOneGuestOnly = False;
	If ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
		If Find(SelObjectPrintForm.Parameter, "SHOW_ONE_GUEST_PER_ROOM_ONLY") > 0 Then
			vShowOneGuestOnly = True;
		EndIf;
	EndIf;
	
	vShowBirthDate = False;
	If ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
		If Find(SelObjectPrintForm.Parameter, "SHOW_GUEST_DATE_OF_BIRTH") > 0 Then
			vShowBirthDate = True;
		EndIf;
	EndIf;
	
	vGroupByParent = False;
	If ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
		If Find(SelObjectPrintForm.Parameter, "GROUP_BY_PARENT") > 0 Then
			vGroupByParent = True;
		EndIf;
	EndIf;
	
	vUseColorRoomStatus = False;
	If ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
		If Find(SelObjectPrintForm.Parameter, "USE_COLOR_ROOM_STATUS") > 0 Then
			vUseColorRoomStatus = True;
		EndIf;
	EndIf;
	
	vShowDiscountType = False;
	If ValueIsFilled(SelObjectPrintForm) And Not IsBlankString(SelObjectPrintForm.Parameter) Then
		If Find(SelObjectPrintForm.Parameter, "SHOW_DISCOUNT_TYPE") > 0 Then
			vShowDiscountType = True;
		EndIf;
	EndIf;
	
	// Choose template
	vSpreadsheet = OperationsSpreadsheet;
	vSpreadsheet.Clear();
	vOprObj = SelOperationSchedule.GetObject();
	vTemplate = vOprObj.GetTemplate("OperationsByRooms");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Today
	vToday = Format(SelOperationSchedule.Date, "DF=dd.MM");
	
	// Header
	If SelShowDuration Then
		vHeaderRow = vTemplate.GetArea("Header");
	Else
		vHeaderRow = vTemplate.GetArea("Header|WithoutDuration");
	EndIf;
	// Hotel
	vHotel = SelHotel;
	vHotelObj = vHotel.GetObject();
	mHotelPrintName = vHotelObj.pmGetHotelPrintName(SessionParameters.CurrentLanguage);
	mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(SessionParameters.CurrentLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SessionParameters.CurrentLanguage) + vHotelFax);
	// Document date and number
	mDocNumber = cmGetDocumentNumberPresentation(SelOperationSchedule.Number);
	mDocDate = cmGetDocumentDatePresentation(SelOperationSchedule.Date);
	// Set parameters and put report section
	vHeaderRow.Parameters.mHotelPrintName = mHotelPrintName;
	vHeaderRow.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeaderRow.Parameters.mHotelPhones = mHotelPhones;
	vHeaderRow.Parameters.mDocNumber = mDocNumber;
	vHeaderRow.Parameters.mDocDate = mDocDate;
	vHeaderRow.Parameters.mFloor = "";
	vHeaderRow.Parameters.mFilterDescription = GetFilterDescription();
	
	If Not vGroupByParent Then
		vSpreadsheet.Put(vHeaderRow);
	EndIf;
	
	// Get template areas
	If SelShowDuration Then
		vOperationRow = vTemplate.GetArea("Operation");
		vOperationFooterRow = vTemplate.GetArea("OperationFooter");
		vRow = vTemplate.GetArea("Row");
		vRow1 = vTemplate.GetArea("Row1");
		vBirthdateRow = vTemplate.GetArea("BirthdateRow");
		vBirthdateRow1 = vTemplate.GetArea("BirthdateRow1");
		vRemarksRow = vTemplate.GetArea("Remarks");
	Else
		vOperationRow = vTemplate.GetArea("Operation|WithoutDuration");
		vOperationFooterRow = vTemplate.GetArea("OperationFooter|WithoutDuration");
		vRow = vTemplate.GetArea("Row|WithoutDuration");
		vRow1 = vTemplate.GetArea("Row1|WithoutDuration");
		vBirthdateRow = vTemplate.GetArea("BirthdateRow|WithoutDuration");
		vBirthdateRow1 = vTemplate.GetArea("BirthdateRow1|WithoutDuration");
		vRemarksRow = vTemplate.GetArea("Remarks|WithoutDuration");
	EndIf;
	
	vRoomStatusIndexRow = Undefined;
	For vIndexNumber = 1 To vRow.TableWidth Do
		vIndexRow = "C" + Format(vIndexNumber, "NFD=0; NZ=; NG=");
		If vRow.Area(vIndexRow).Parameter <> "mRoomStatus" Then
			Continue;
		EndIf;
		
		vRoomStatusIndexRow = vIndexRow;
		Break;
	EndDo;
	
	vRoomStatusBirthdateIndexRow = Undefined;
	For vIndexNumber = 1 To vBirthdateRow.TableWidth Do
		vIndexRow = "C" + Format(vIndexNumber, "NFD=0; NZ=; NG=");
		If vRow.Area(vIndexRow).Parameter <> "mRoomStatus" Then
			Continue;
		EndIf;
		
		vRoomStatusBirthdateIndexRow = vIndexRow;
		Break;
	EndDo;
	
	If SelShowDuration Then
		vSignatureRow = vTemplate.GetArea("Signature");
	Else
		vSignatureRow = vTemplate.GetArea("Signature|WithoutDuration");
	EndIf;
	mAuthor = "";
	If ValueIsFilled(SelOperationSchedule.Author) Then
		mAuthor = SelOperationSchedule.Author.GetObject().pmGetEmployeeDescription(SessionParameters.CurrentLanguage);
	EndIf;
	vSignatureRow.Parameters.mAuthor = mAuthor;
	
	// Get all operations
	vOperations = SelOperationSchedule.Operations.Unload();
	vOperations.Columns.Add("ExtraGuest", cmGetBooleanTypeDescription());
	vOperations.Columns.Add("RoomParent", cmGetCatalogTypeDescription("Rooms"));
	vOperations.Columns.Add("RoomParentSortCode", cmGetNumberTypeDescription(8, 0));
	
	// Group by operations according to the print type
	If Not IsBlankString(SelGroupBy) Then
		If SelGroupBy = "ByOperations" Then
			// Fill employee and operation for sorting reasons
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
					If Not ValueIsFilled(vOprRow.Operation) Then
						vOprRow.Employee = vCurEmployee;
						vOprRow.EmployeeSortCode = vCurEmployeeSortCode;
						vOprRow.Operation = vCurOperation;
						vOprRow.OperationSortCode = vCurOperationSortCode;
						vOprRow.ExtraGuest = True;
					EndIf;
				EndIf;
			EndDo;
			vOperations.Sort("OperationSortCode, Operation, HotelSortCode, RoomSortCode, Room, EmployeeSortCode, Employee, IsManual, ExtraGuest");
		ElsIf SelGroupBy = "ByRooms" Then
			If vGroupByParent Then
				For Each vOprRow In vOperations Do
					vRoom = vOprRow.Room;
					If Not ValueIsFilled(vRoom) Then
						Continue;
					EndIf;
					
					vRoomParent = vRoom.Parent;
					
					If ValueIsFilled(vRoomParent) Then
						vOprRow.RoomParent = vRoomParent;
						vOprRow.RoomParentSortCode = vRoomParent.SortCode;
					Else
						vOprRow.RoomParent = vRoomParent;
						vOprRow.RoomParentSortCode = -1;
					EndIf;
				EndDo;
			EndIf;
			
			vOperationsArr = vOperations.FindRows(New Structure("Operation, OperationSortCode", Catalogs.Operations.EmptyRef(), 0));
			For Each vOprRow In vOperationsArr Do
				vOprRow.OperationSortCode = 999999;
			EndDo;
			
			vOperations.Sort("HotelSortCode, RoomParentSortCode, RoomSortCode, OperationSortCode, IsManual");
		EndIf;
	EndIf;
	
	// Print operations
	vTotalCount = 0;
	vTotalDuration = 0;
	vOprCount = 0;
	vOprDuration = 0;
	vEmpCount = 0;
	vEmpDuration = 0;
	vTotalCountByParent = 0;
	vTotalDurationByParent = 0;
	
	vCurRoomParent = Undefined;
	vCurEmployee = Undefined;
	vCurOperation = Undefined;
	vCurRoom = Undefined;
	vExtraGuest = False;
	vNumberOfGuests = 0;
	For Each vOprRow In vOperations Do
		If Not ValueIsFilled(vOprRow.Operation) Then
			If SelGroupBy = "ByOperations" Then
				Continue;
			EndIf;
		EndIf;
		If ValueIsFilled(SelRoom) Then
			If Not vOprRow.Room.BelongsToItem(SelRoom) Then
				Continue;
			EndIf;
		EndIf;
		If ValueIsFilled(SelRoomSection) Then
			If vOprRow.Room.RoomSection <> SelRoomSection Then
				Continue;
			EndIf;
		EndIf;
		If ValueIsFilled(SelEmployee) Then
			If vOprRow.Employee <> SelEmployee Then
				Continue;
			EndIf;
		EndIf;
		If SelGroupBy = "ByOperations" And vOprRow.Operation <> vCurOperation Then
			// Print totals for the previous operation
			If vCurOperation <> Undefined Then
				// Set parameters
				vOperationFooterRow.Parameters.mOprCount = vOprCount;
				If SelShowDuration Then
					vOperationFooterRow.Parameters.mOprDuration = cmFormatDurationInHours(vOprDuration/60);
				EndIf;
				// Put operation footer area
				vSpreadsheet.Put(vOperationFooterRow);
			EndIf;
			// Print operation header
			vCurOperation = vOprRow.Operation;
			// Fill client area parameters
			mOperation = "";
			If ValueIsFilled(vCurOperation) Then
				mOperation = TrimAll(vCurOperation);
			EndIf;
			// Set parameters
			vOperationRow.Parameters.mOperation = mOperation;
			// Put operation area
			vSpreadsheet.Put(vOperationRow);
			// Initialize operation totals
			vOprCount = 0;
			vOprDuration = 0;
			
			vCurRoom = Undefined;
		ElsIf SelGroupBy = "ByRooms" And vOprRow.RoomParent <> vCurRoomParent And vGroupByParent Then
			If vCurRoomParent <> Undefined Then
				// Footer
				If SelShowDuration Then
					vFooterRow = vTemplate.GetArea("Footer");
				Else
					vFooterRow = vTemplate.GetArea("Footer|WithoutDuration");
				EndIf;
				// Fill parameters
				mTotalCount = vTotalCountByParent;
				mTotalDuration = cmFormatDurationInHours(vTotalDurationByParent/60);
				// Set parameters
				vFooterRow.Parameters.mTotalCount = mTotalCount;
				If SelShowDuration Then
					vFooterRow.Parameters.mTotalDuration = mTotalDuration;
				EndIf;
				// Put footer
				vSpreadsheet.Put(vFooterRow);
				
				// Signature
				vSpreadsheet.Put(vSignatureRow);
				
				vSpreadsheet.PutHorizontalPageBreak();
			EndIf;
			vCurRoomParent = vOprRow.RoomParent;
			vHeaderRow.Parameters.mFloor = "- " + TrimAll(vCurRoomParent);
			vSpreadsheet.Put(vHeaderRow);
			vTotalCountByParent = 0;
			vTotalDurationByParent = 0;
		EndIf;
		
		// Fill row parameters
		If vCurRoom <> vOprRow.Room Or (vCurOperation <> vOprRow.Operation And ValueIsFilled(vOprRow.Operation)) Or (vCurEmployee <> vOprRow.Employee And ValueIsFilled(vOprRow.Employee)) Then
			vExtraGuest = False;
			vNumberOfGuests = 0;
			vRoomRows = vOperations.FindRows(New Structure("Room", vOprRow.Room));
			For Each vRoomRow In vRoomRows Do
				If vRoomRow.NumberOfGuests > 0 Then
					vNumberOfGuests = vRoomRow.NumberOfGuests;
					Break;
				EndIf;
			EndDo;
			If Not SelGroupByRoom Or (SelGroupByRoom And vCurRoom <> vOprRow.Room) Then
				mRoom = TrimAll(vOprRow.Room) + ?(ValueIsFilled(vOprRow.RoomType), " " + TrimAll(vOprRow.RoomType.Code), "");
				If vOprRow.IsCheckInWaiting And vOprRow.ExpectedNumberOfGuests > 0 Then
					mIsCheckInWaiting = Format(vOprRow.ExpectedNumberOfGuests, "ND=10; NFD=0; NZ=; NG=") + NStr("en=' prs.'; ru=' чел.'; de=' prs.'");
				Else
					mIsCheckInWaiting = vOprRow.IsCheckInWaiting;
				EndIf;
				mRoomStatus = TrimAll(vOprRow.RoomStatus);
				If ValueIsFilled(vOprRow.RoomStatus) Then
					mRoomStatusCode = TrimAll(vOprRow.RoomStatus.Code);
				Else
					mRoomStatusCode = "";
				EndIf;
				mRoomStatusChangeTime = Format(vOprRow.RoomStatusChangeTime, "DF='dd.MM HH:mm'");
				mRoomStatusChangeAuthor = vOprRow.RoomStatusChangeAuthor;
			Else
				mRoom = "";
				mIsCheckInWaiting = "";
				mRoomStatus = "";
				mRoomStatusCode = "";
				mRoomStatusChangeTime = "";
				mRoomStatusChangeAuthor = "";
			EndIf;
			vCurRoom = vOprRow.Room;
			vCurEmployee = vOprRow.Employee;
			vCurOperation = Undefined;
		Else
			If vShowOneGuestOnly And (vCurOperation = vOprRow.Operation Or Not ValueIsFilled(vOprRow.Operation)) And (vCurEmployee = vOprRow.Employee Or Not ValueIsFilled(vOprRow.Employee)) Then
				Continue;
			EndIf;
			vExtraGuest = True;
			mRoom = "";
			mIsCheckInWaiting = "";
			mRoomStatus = "";
			mRoomStatusCode = "";
			mRoomStatusChangeTime = "";
			mRoomStatusChangeAuthor = "";
		EndIf;
		
		mOperationRemarks = TrimAll(vOprRow.OperationRemarks);
		// Citizenship
		If ValueIsFilled(vOprRow.Citizenship) And ValueIsFilled(SelOperationSchedule.Hotel) And 
		   vOprRow.Citizenship <> SelOperationSchedule.Hotel.Citizenship Then
			mOperationRemarks = "(" + TrimAll(vOprRow.Citizenship.ISOCode) + ") " + mOperationRemarks;
		EndIf;
		// Check date of birth
		vIsBirthdate = False;
		vCommaPos = Find(mOperationRemarks, ", ");
		If vCommaPos > 0 Then
			vBirthdate = Left(Mid(mOperationRemarks, vCommaPos + 2), 5);
			If vToday = vBirthdate Then
				vIsBirthdate = True;
			EndIf;
		EndIf;
		// Remove date of birth
		If Not vShowBirthDate And Mid(vBirthdate, 3, 1) = "." Then
			If vCommaPos > 0 Then
				mOperationRemarks = TrimAll(Left(mOperationRemarks, vCommaPos - 1) + Mid(mOperationRemarks, vCommaPos + 10));
			EndIf;
		EndIf;
		// Fill guest loyalty program attributes    
		If vShowDiscountType Then   
			mClientType = "";
			If ValueIsFilled(vOprRow.Guest) Then
				vGuest = vOprRow.Guest;	
				If ValueIsFilled(vGuest.DiscountCard) Then 
					mClientType	= ?(ValueIsFilled(vGuest.DiscountCard.DiscountType), vGuest.DiscountCard.DiscountType.Code, "");	
				ElsIf ValueIsFilled(vGuest.DiscountType) Then	
					mClientType	= ?(ValueIsFilled(vGuest.DiscountType), vGuest.DiscountType.Code, "");
				EndIf;	
			EndIf;
		Else	
			mClientType = ?(ValueIsFilled(vOprRow.ClientType), vOprRow.ClientType.Code, "");
			mDiscountCard = "";
			mVIP = "";
			mRank = "";
			If ValueIsFilled(vOprRow.Guest) Then
				vGuest = vOprRow.Guest; 
				If vGuest.IsInWhiteList Then
					mVIP = "VIP";
				EndIf;
				If ValueIsFilled(vGuest.DiscountCard) Then
					mDiscountCard = TrimAll(vGuest.DiscountCard); 	
				EndIf;
				If ValueIsFilled(vGuest.MilitaryRank) Then
					mRank = TrimAll(vGuest.MilitaryRank.Code); 	
				EndIf;
			EndIf;
			mClientType = mClientType + 
			              ?(IsBlankString(mVIP), "", Chars.LF + mVIP) + 
						  ?(IsBlankString(mDiscountCard), "", Chars.LF + mDiscountCard) +
						  ?(IsBlankString(mRank), "", Chars.LF + mRank);
						  
		EndIf;			  
		// Period
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
		
		mStayDay = vOprRow.StayDay;
		If vNumberOfGuests > 0 Then
			mNumberOfGuests = Format(vNumberOfGuests, "ND=10; NFD=0; NZ=; NG=") + NStr("en=' prs.'; ru=' чел.'; de=' prs.'");
		Else
			mNumberOfGuests = "";
		EndIf;
		mCustomer = vOprRow.Customer;
		
		mOperation = TrimAll(vOprRow.Operation);
		If ValueIsFilled(vOprRow.Operation) And vOprRow.Operation <> vCurOperation Then
			vCurOperation = vOprRow.Operation;
			
			mDuration = cmFormatDurationInHours(vOprRow.Duration/60);
			
			vOprCount = vOprCount + 1;
			vEmpCount = vEmpCount + 1;
			vTotalCount = vTotalCount + 1;
			vTotalCountByParent = vTotalCountByParent +1;
			
			vOprDuration = vOprDuration + vOprRow.Duration;
			vEmpDuration = vEmpDuration + vOprRow.Duration;
			vTotalDuration = vTotalDuration + vOprRow.Duration;
			vTotalDurationByParent = vTotalDurationByParent + vOprRow.Duration;
		Else
			mDuration = "";
			mClientType = "";
		EndIf;
		mEmployee = TrimAll(vOprRow.Employee);
		// Set parameters
		If Not vIsBirthdate Then
			vPrtRow = vRow;
			vPrtRow1 = vRow1;
			vPrtRoomStatusIndexRow = vRoomStatusIndexRow;
		Else
			vPrtRow = vBirthdateRow;
			vPrtRow1 = vBirthdateRow1;
			vPrtRoomStatusIndexRow = vRoomStatusBirthdateIndexRow;
		EndIf;
		If Not vExtraGuest Then
			vPrtRow.Parameters.mRoom = mRoom;
			vPrtRow.Parameters.mRoomStatusCode = mRoomStatusCode;
			vPrtRow.Parameters.mRoomStatus = mRoomStatus;
			vPrtRow.Parameters.mOperation = mOperation;
			vPrtRow.Parameters.mOperationRemarks = mOperationRemarks;
			vPrtRow.Parameters.mPeriod = mPeriod;
			vPrtRow.Parameters.mEmployee = mEmployee;
			vPrtRow.Parameters.mNumberOfGuests = mNumberOfGuests;
			vPrtRow.Parameters.mStayDay = mStayDay;
			vPrtRow.Parameters.mCustomer = mCustomer;
			vPrtRow.Parameters.mRoomStatusChangeTime = mRoomStatusChangeTime;
			vPrtRow.Parameters.mRoomStatusChangeAuthor = mRoomStatusChangeAuthor;
			vPrtRow.Parameters.mClientType = mClientType;
			vPrtRow.Parameters.mIsCheckInWaiting = mIsCheckInWaiting;
			If SelShowDuration Then
				vPrtRow.Parameters.mDuration = mDuration;
			EndIf;
			
			If vUseColorRoomStatus And vPrtRoomStatusIndexRow <> Undefined Then
				vRoomStatus = vOprRow.RoomStatus;
				If ValueIsFilled(vOprRow.RoomStatus) Then
					vColorHexString = vRoomStatus.ColorHexString;
					If Not IsBlankString(vColorHexString) Then
						vPrtRow.Area(vPrtRoomStatusIndexRow).BackColor = tcOnServer.HexToColor(vColorHexString);
					Else
						vPrtRow.Area(vPrtRoomStatusIndexRow).BackColor = New Color();
					EndIf;
				Else
					vPrtRow.Area(vPrtRoomStatusIndexRow).BackColor = New Color();
				EndIf;
			EndIf;
			
			// Put row
			vSpreadsheet.Put(vPrtRow);
		Else
			vPrtRow1.Parameters.mOperationRemarks = mOperationRemarks;
			vPrtRow1.Parameters.mPeriod = mPeriod;
			vPrtRow1.Parameters.mStayDay = mStayDay;
			vPrtRow1.Parameters.mCustomer = mCustomer;
			vPrtRow1.Parameters.mClientType = mClientType;
			If SelShowDuration Then
				vPrtRow1.Parameters.mDuration = mDuration;
			EndIf;
			
			If vUseColorRoomStatus And vPrtRoomStatusIndexRow <> Undefined Then
				vRoomStatus = vOprRow.RoomStatus;
				If ValueIsFilled(vOprRow.RoomStatus) Then
					vColorHexString = vRoomStatus.ColorHexString;
					If Not IsBlankString(vColorHexString) Then
						vPrtRow1.Area(vPrtRoomStatusIndexRow).BackColor = tcOnServer.HexToColor(vColorHexString);
					Else
						vPrtRow1.Area(vPrtRoomStatusIndexRow).BackColor = New Color();
					EndIf;
				Else
					vPrtRow1.Area(vPrtRoomStatusIndexRow).BackColor = New Color();
				EndIf;
			EndIf;
			
			// Put row
			vSpreadsheet.Put(vPrtRow1);
		EndIf;
		If SelShowRemarks Then
			If vOperations.IndexOf(vOprRow) + 1 = vOperations.Count() Or vOperations.IndexOf(vOprRow) + 1 < vOperations.Count() And vCurRoom <> vOperations[vOperations.IndexOf(vOprRow) + 1].Room Then  
				vHousekeepingRemarks = "";
				vTasksRemarks = "";
				vRoomRows = vOperations.FindRows(New Structure("Room", vOprRow.Room));
				i = 0;
				For Each vRoomRow In vRoomRows Do
					vShowCurrentBedsSetup = True;
					If ValueIsFilled(vRoomRow.ParentDoc) And (TypeOf(vRoomRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vRoomRow.ParentDoc) = Type("DocumentRef.Reservation")) Then
						vParentDocRemarks = TrimAll(vRoomRow.ParentDoc.HousekeepingRemarks);
						If Not IsBlankString(vParentDocRemarks) Then
							If IsBlankString(vHousekeepingRemarks) Then
								vHousekeepingRemarks = vParentDocRemarks;
							Else
								If StrFind(vHousekeepingRemarks, vParentDocRemarks) = 0 Then
									vHousekeepingRemarks = vHousekeepingRemarks + Chars.LF + vParentDocRemarks;
								EndIf;
							EndIf;
						EndIf;
						If i = 0 And ValueIsFilled(vRoomRow.ParentDoc.BedsSetup) And vOprRow.Room.BedsSetup <> vRoomRow.ParentDoc.BedsSetup Then
							vShowCurrentBedsSetup = False;
							If ValueIsFilled(vOprRow.Room.BedsSetup) Then
								vHousekeepingRemarks = vHousekeepingRemarks + ?(IsBlankString(vHousekeepingRemarks), "", Chars.LF) + NStr("en='Beds in room: '; ru='Кровати в номере: '; de='Betten in Zimmer: '") + TrimAll(vOprRow.Room.BedsSetup) + NStr("en=', requested: '; ru=', требуются: '; de=', ersuchten: '") + TrimAll(vRoomRow.ParentDoc.BedsSetup);
							Else
								vHousekeepingRemarks = vHousekeepingRemarks + ?(IsBlankString(vHousekeepingRemarks), "", Chars.LF) + NStr("en='Beds requested: '; ru='Требуются кровати: '; de='Betten ersuchten: '") + TrimAll(vRoomRow.ParentDoc.BedsSetup);
							EndIf;
						EndIf;
					EndIf;
					If i = 0 And ValueIsFilled(vOprRow.Room.BedsSetup) And vShowCurrentBedsSetup Then
						vHousekeepingRemarks = vHousekeepingRemarks + ?(IsBlankString(vHousekeepingRemarks), "", Chars.LF) + NStr("en='Beds in room: '; ru='Кровати в номере: '; de='Betten in Zimmer: '") + TrimAll(vOprRow.Room.BedsSetup);
					EndIf;
					i = i + 1;
				EndDo;
				If ValueIsFilled(TrimAll(vHousekeepingRemarks)) Then
					vRemarksRow.Parameters.mRemarks = vHousekeepingRemarks;
					vSpreadsheet.Put(vRemarksRow);
				EndIf;
				vRoomRows = vOperations.FindRows(New Structure("Room, RoomType, IsManual", vOprRow.Room, vOprRow.Room.RoomType, False));
				For Each vRoomRow In vRoomRows Do
					If ValueIsFilled(vRoomRow.ParentDoc) Then
						vTasks = cmGetMessagesForObject(vRoomRow.ParentDoc, , , , , , , , True);
						For Each vTasksRow In vTasks Do
							vTasksRemarks = vTasksRemarks + ?(ValueIsFilled(vTasksRemarks), ", " + vTasksRow.Remarks, vTasksRow.Remarks); 
						EndDo;
					EndIf;
				EndDo;
				vTasks = cmGetMessagesForObject(vOprRow.Room, , , , , , , , True);
				For Each vTasksRow In vTasks Do 
					vTasksRemarks = vTasksRemarks + ?(ValueIsFilled(vTasksRemarks), ", " + vTasksRow.Remarks, vTasksRow.Remarks); 
				EndDo;
				If ValueIsFilled(TrimAll(vTasksRemarks)) Then
					vRemarksRow.Parameters.mRemarks = "• " + vTasksRemarks + " •";
					vSpreadsheet.Put(vRemarksRow);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	// Print totals for the previous operation
	If SelGroupBy = "ByOperations" And vCurOperation <> Undefined Then
		// Set parameters
		vOperationFooterRow.Parameters.mOprCount = vOprCount;
		If SelShowDuration Then
			vOperationFooterRow.Parameters.mOprDuration = cmFormatDurationInHours(vOprDuration/60);
		EndIf;
		// Put operation footer area
		vSpreadsheet.Put(vOperationFooterRow);
	EndIf;
	
	
	// Footer
	If SelShowDuration Then
		vFooterRow = vTemplate.GetArea("Footer");
	Else
		vFooterRow = vTemplate.GetArea("Footer|WithoutDuration");
	EndIf;
	If Not vGroupByParent Then
		// Fill parameters
		mTotalCount = vTotalCount;
		mTotalDuration = cmFormatDurationInHours(vTotalDuration/60);
	Else
		// Fill parameters
		mTotalCount = vTotalCountByParent;
		mTotalDuration = cmFormatDurationInHours(vTotalDurationByParent/60);
	EndIf;
	// Set parameters
	vFooterRow.Parameters.mTotalCount = mTotalCount;
	If SelShowDuration Then
		vFooterRow.Parameters.mTotalDuration = mTotalDuration;
	EndIf;
	// Put footer
	vSpreadsheet.Put(vFooterRow);
	
	// Signature
	vSpreadsheet.Put(vSignatureRow);

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Landscape, True, , True);
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
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Operations schedule';ru='План работ';de='Arbeitsplan'")) + " " + mDocDate;
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, SessionParameters.CurrentLanguage, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintByOperations

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintEmployees(rDoPrint = Undefined)
	// Basic checks
	If Not ValueIsFilled(SelOperationSchedule) Then
		Raise NStr("ru='План работ не записан!';de='Arbeitsplan ist nicht gespeichert!';en='Operations plan is not saved!'");
	EndIf;
	SelHotel = SelOperationSchedule.Hotel;
	If Not ValueIsFilled(SelHotel) Then
		Raise NStr("ru='Не задана гостиница!';de='Das Hotel ist nicht angegeben!';en='Hotel should be filled!'");
	EndIf;
	
	// Choose template
	vSpreadsheet = OperationsSpreadsheet;
	vSpreadsheet.Clear();
	vOprObj = SelOperationSchedule.GetObject();
	vTemplate = vOprObj.GetTemplate("Employees");
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Header
	vHeaderRow = vTemplate.GetArea("Header");
	// Hotel
	vHotel = SelHotel;
	vHotelObj = vHotel.GetObject();
	mHotelPrintName = vHotelObj.pmGetHotelPrintName(SessionParameters.CurrentLanguage);
	mHotelPostAddressPresentation = vHotelObj.pmGetHotelPostAddressPresentation(SessionParameters.CurrentLanguage);
	vHotelPhones = TrimAll(vHotel.Phones);
	vHotelFax = TrimAll(vHotel.Fax);
	mHotelPhones = vHotelPhones + ?(IsBlankString(vHotelFax), "", cmNStr("en=', fax ';de=', fax ';ru=', факс '", SessionParameters.CurrentLanguage) + vHotelFax);
	// Document date and number
	mDocNumber = cmGetDocumentNumberPresentation(SelOperationSchedule.Number);
	mDocDate = cmGetDocumentDatePresentation(SelOperationSchedule.Date);
	// Set parameters and put report section
	vHeaderRow.Parameters.mHotelPrintName = mHotelPrintName;
	vHeaderRow.Parameters.mHotelPostAddressPresentation = mHotelPostAddressPresentation;
	vHeaderRow.Parameters.mHotelPhones = mHotelPhones;
	vHeaderRow.Parameters.mDocNumber = mDocNumber;
	vHeaderRow.Parameters.mDocDate = mDocDate;
	vSpreadsheet.Put(vHeaderRow);
	
	// Get template areas
	vRow = vTemplate.GetArea("Row");
	vSignatureRow = vTemplate.GetArea("Signature");
	mAuthor = "";
	If ValueIsFilled(SelOperationSchedule.Author) Then
		mAuthor = SelOperationSchedule.Author.GetObject().pmGetEmployeeDescription(SessionParameters.CurrentLanguage);
	EndIf;
	vSignatureRow.Parameters.mAuthor = mAuthor;
	
	// Get all employees
	vEmployees = SelOperationSchedule.Employees.Unload();
	
	// Print employees
	For Each vEmpRow In vEmployees Do
		// Fill row parameters
		mEmployee = TrimAll(vEmpRow.Employee);
		mDepartment = TrimAll(vEmpRow.Department);
		mHours = cmFormatDurationInHours(vEmpRow.Hours);
		mDuration = cmFormatDurationInHours(vEmpRow.Duration);
		mRoomSpace = Format(vEmpRow.RoomSpace, "ND=8; NFD=2");
		mCheckOutCleaningCount = Format(vEmpRow.CheckOutCleaningCount, "ND=6; NFD=0");
		mRegularCleaningCount = Format(vEmpRow.RegularCleaningCount, "ND=6; NFD=0");
		mVacantRoomCleaningCount = Format(vEmpRow.VacantRoomCleaningCount, "ND=6; NFD=0");
		mRepairEndCleaningCount = Format(vEmpRow.RepairEndCleaningCount, "ND=6; NFD=0");
		mOtherOperationsCount = Format(vEmpRow.OtherOperationsCount, "ND=6; NFD=0");
		// Set parameters
		vRow.Parameters.mEmployee = mEmployee;
		vRow.Parameters.mDepartment = mDepartment;
		vRow.Parameters.mHours = mHours;
		vRow.Parameters.mDuration = mDuration;
		vRow.Parameters.mRoomSpace = mRoomSpace;
		vRow.Parameters.mCheckOutCleaningCount = mCheckOutCleaningCount;
		vRow.Parameters.mRegularCleaningCount = mRegularCleaningCount;
		vRow.Parameters.mVacantRoomCleaningCount = mVacantRoomCleaningCount;
		vRow.Parameters.mRepairEndCleaningCount = mRepairEndCleaningCount;
		vRow.Parameters.mOtherOperationsCount = mOtherOperationsCount;
		// Put row
		vSpreadsheet.Put(vRow);
	EndDo;
	
	// Footer
	vFooterRow = vTemplate.GetArea("Footer");
	// Fill parameters
	mTotalHours = cmFormatDurationInHours(vEmployees.Total("Hours"));
	mTotalDuration = cmFormatDurationInHours(vEmployees.Total("Duration"));
	mTotalRoomSpace = Format(vEmployees.Total("RoomSpace"), "ND=8; NFD=2");
	mTotalCheckOutCleaningCount = Format(vEmployees.Total("CheckOutCleaningCount"), "ND=6; NFD=0");
	mTotalRegularCleaningCount = Format(vEmployees.Total("RegularCleaningCount"), "ND=6; NFD=0");
	mTotalVacantRoomCleaningCount = Format(vEmployees.Total("VacantRoomCleaningCount"), "ND=6; NFD=0");
	mTotalRepairEndCleaningCount = Format(vEmployees.Total("RepairEndCleaningCount"), "ND=6; NFD=0");
	mTotalOtherOperationsCount = Format(vEmployees.Total("OtherOperationsCount"), "ND=6; NFD=0");
	// Set parameters
	vFooterRow.Parameters.mTotalHours = mTotalHours;
	vFooterRow.Parameters.mTotalDuration = mTotalDuration;
	vFooterRow.Parameters.mTotalRoomSpace = mTotalRoomSpace;
	vFooterRow.Parameters.mTotalCheckOutCleaningCount = mTotalCheckOutCleaningCount;
	vFooterRow.Parameters.mTotalRegularCleaningCount = mTotalRegularCleaningCount;
	vFooterRow.Parameters.mTotalVacantRoomCleaningCount = mTotalVacantRoomCleaningCount;
	vFooterRow.Parameters.mTotalRepairEndCleaningCount = mTotalRepairEndCleaningCount;
	vFooterRow.Parameters.mTotalOtherOperationsCount = mTotalOtherOperationsCount;
	// Put footer
	vSpreadsheet.Put(vFooterRow);
	
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
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Employee operation totals';ru='Итоги по работам сотрудников';de='Ergebnisse nach Arbeiten der Mitarbeiter'")) + " " + mDocDate;
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, SessionParameters.CurrentLanguage, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PrintEmployees

// -----------------------------------------------------------------------------
&AtServer
Function GetFilterDescription()
	vParamPresentation = "";
	If ValueIsFilled(SelRoom) Then
		If SelRoom.IsFolder Then
			vParamPresentation = vParamPresentation + NStr("en='Rooms folder ';ru='Группа номеров ';de='Gruppe Zimmer '") + 
			                     TrimAll(SelRoom.Description) + 
			                     ";" + Chars.LF;
		EndIf;
	EndIf;
	If ValueIsFilled(SelRoomSection) Then
		vParamPresentation = vParamPresentation + NStr("en='Room section ';ru='Секция номеров ';de='Sektion der Zimmer '") + 
							 TrimAll(SelRoomSection.Description) + 
							 ";" + Chars.LF;
	EndIf;
	If ValueIsFilled(SelEmployee) Then
		vParamPresentation = vParamPresentation + NStr("en='Employee ';ru='Сотрудник ';de='Mitarbeiter '") + 
							 TrimAll(SelEmployee.Description) + 
							 ";" + Chars.LF;
	EndIf;
	Return vParamPresentation;
EndFunction // GetFilterDescription

#EndRegion
