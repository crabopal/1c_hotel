
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Object.DataProcessor = Catalogs.DataProcessors.EndOfDay;
	Hotel = SessionParameters.CurrentHotel;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	CurrentDate = Hotel.AccountingDate;
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.OpenSettings.Visible = False;
		Items.OpenSettings.Enabled = False;
	EndIf;
	OnOpenAtServer();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Status1Click(Item)
	If ValueIsFilled(Hotel) Then
		CheckBalancesForGuestsCheckingOutToday();
		CheckIfChangeDateIsPossible();
	Else                          
		vErr = NStr("en = 'Field ""Hotel"" is not filled.'; de = 'Das Feld ""Hotel"" ist nicht ausgefüllt.'; ru = 'Поле ""Отель"" не заполнено.'");
		tcCommonFunctionOnClientServer.UserMessage(vErr, , "Hotel");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Status2Click(Item)
	If ValueIsFilled(Hotel) Then
		CheckReservations();
		CheckIfChangeDateIsPossible();
	Else
		vErr = NStr("en = 'Field ""Hotel"" is not filled.'; de = 'Das Feld ""Hotel"" ist nicht ausgefüllt.'; ru = 'Поле ""Отель"" не заполнено.'");
		tcCommonFunctionOnClientServer.UserMessage(vErr, , "Hotel");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Status3Click(Item)
	If ValueIsFilled(Hotel) Then
		CheckZReport();
		CheckIfChangeDateIsPossible();
	Else
		vErr = NStr("en = 'Field ""Hotel"" is not filled.'; de = 'Das Feld ""Hotel"" ist nicht ausgefüllt.'; ru = 'Поле ""Отель"" не заполнено.'");
		tcCommonFunctionOnClientServer.UserMessage(vErr, , "Hotel");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Status4Click(Item)
	vReports = CheckReportFolder(Object.printBeforeReports);
	GenerateReports(vReports);
	Items.Status4.Picture = PictureLib.CheckMark;
	printBeforeReports = True;
	CheckIfChangeDateIsPossible();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Status5Click(Item)
	vReports = CheckReportFolder(Object.printAfterReports);
	GenerateReports(vReports);
	Items.Status5.Picture = PictureLib.CheckMark;	
	printAfterReports = True;
	CheckIfChangeDateIsPossible();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Status8Click(Item)
	ClearDPInfo("GroupCheck8_2");
	DataProcessorsList.Clear();
	DataProcessorsList = CheckDPFolder(Object.ExecutedBeforeDataProcessing);
	If RunDP() Then
		Items.Status8.Picture = PictureLib.CheckMark;	
		ExecutedBeforeDataProcessing = True;
	Else
		Items.Status8.Picture = PictureLib.Attention;
		ExecutedBeforeDataProcessing = False;
		CreateDPInfo("BeforeDPInfo", "GroupCheck8_2");
	EndIf;
	CheckIfChangeDateIsPossible();	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Status9Click(Item)
	ClearDPInfo("GroupCheck9_2");
	DataProcessorsList.Clear();
	DataProcessorsList = CheckDPFolder(Object.ExecutedAfterDataProcessing);
	If RunDP() Then
		Items.Status9.Picture = PictureLib.CheckMark;	
		ExecutedAfterDataProcessing = True;
	Else
		Items.Status9.Picture = PictureLib.Attention;
		ExecutedAfterDataProcessing = False;
		CreateDPInfo("AfterDPInfo", "GroupCheck9_2"); 
	EndIf;
	CheckIfChangeDateIsPossible();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearDPInfo(pItems)
	While Items[pItems].ChildItems.Count() > 0 Do
		Items.Delete(Items[pItems].ChildItems[0]);
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeDate(Item)
	// APDEX
	vKeyOperation = "CloseOfPeriod.Posting";
	vTimeFrom = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation, New UUID);
	
	// EndOfDay
	ChangeDateAtServer();
	// Refresh desktop form if opened
	Notify("Desktop.Refresh");
	// Set application caption
	tcOnClient.ChangeApplicationCaption(tcOnServer.cmGetSessionParametersAttribute("CurrentHotel"));
	// Check operation result
	If ValueIsFilled(CloseOfPeriod) Then
		Items.Status6.Picture = PictureLib.CheckMark;
		// Proceed with after end of day reports and procedures     
		If Not Object.ConfirmAfterEndOfDayAutomations Then     
			vKeyOperationAP = "CloseOfPeriod.ExecutedAfterDataProcessing";
			vTimeFromAP = APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperationAP, New UUID);
			If Not ExecutedAfterDataProcessing Then
				Status9Click(Items.Status9);
			EndIf;
			If Not printAfterReports Then
				Status5Click(Items.Status5);
			EndIf;   
			APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperationAP, vTimeFromAP);
		EndIf; 
		// User message
		ShowMessageBox(, NStr("en = 'Day is closed!'; de = 'Der Tag ist geschlossen!'; ru = 'День закрыт!'"));
	EndIf;
	CheckIfChangeDateIsPossible();   
	APDEXPerformanceSystemOnClientServer.FinishTimeIntervalMeasurement(vKeyOperation, vTimeFrom);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Report1Click(Item)
	vReports = CheckReportFolder(Object.BalancesReport);
	GenerateReports(vReports);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Report2Click(Item)
	vReports = CheckReportFolder(Object.ReservationsReport);
	GenerateReports(vReports);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Status7Click(Item)
	If ValueIsFilled(Hotel) Then
		CheckAccommodations();
		CheckIfChangeDateIsPossible();
	Else
		vErr = NStr("en = 'Field ""Hotel"" is not filled.'; de = 'Das Feld ""Hotel"" ist nicht ausgefüllt.'; ru = 'Поле ""Отель"" не заполнено.'");
		tcCommonFunctionOnClientServer.UserMessage(vErr, , "Hotel");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Report7Click(Item)
	vReports = CheckReportFolder(Object.AccommodationsReport);
	GenerateReports(vReports);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenSettings(Command)
	If tcOnServer.cmIsInRole("Administrator") Then
		OpenForm("DataProcessor.EndOfDay.Form.Settings", New Structure("DataProcessor", Object.DataProcessor), ThisObject, , , , New NotifyDescription("closeSettings", ThisObject));
	Else   
		vErr = NStr("en = 'The setting is available only to the administrator!'; 
					|de = 'Die Einstellung steht nur dem Administrator zur Verfügung!'; 
					|ru = 'Настройка доступна только администратору!'");
		tcCommonFunctionOnClientServer.UserMessage(vErr);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RunChecks(pCommand)
	If Not ValueIsFilled(Hotel) Then
		vErr = NStr("en = 'Field ""Hotel"" is not filled.'; de = 'Das Feld ""Hotel"" ist nicht ausgefüllt.'; ru = 'Поле ""Отель"" не заполнено.'");
		tcCommonFunctionOnClientServer.UserMessage(vErr, , "Hotel");
		Return;
	EndIf;
	If Not checkBalances And Object.checkBalances Then
		CheckBalancesForGuestsCheckingOutToday();
	EndIf;
	If Not checkReservations And Object.checkReservations Then
		CheckReservations();
	EndIf;	
	If Not checkAccommodations And Object.checkAccommodations Then
		CheckAccommodations();
	EndIf;	
	If Not checkZReport And Object.checkZReport Then
		CheckZReport();
	EndIf;
	If Not checkZReport Or Not checkBalances Then
		Return;
	EndIf;
	If Not Object.ConfirmBeforeEndOfDayAutomations Then
		If Not ExecutedBeforeDataProcessing Then
			Status8Click(Items.Status8);
		EndIf;
		If Not printBeforeReports Then
			Status4Click(Items.Status4);
		EndIf;
	EndIf;
	CheckIfChangeDateIsPossible();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure AddCashRegister(pCashRegisters, pAmount, pIsOk)
	vItemName = "Item" + CheckNumber;        
	vItemType = "FormDecoration";
	vGroup = tcOnServer.cmCreateItem(ThisObject, Items.GroupCheck3_2, vItemName, "FormGroup", New Structure("Type, Group, ShowTitle", FormGroupType.UsualGroup, ChildFormItemsGroup.AlwaysHorizontal, False));
	tcOnServer.cmCreateItem(ThisObject, vGroup, vItemName + "Emp", vItemType, New Structure("Title, Width", "", 2));	
	tcOnServer.cmCreateItem(ThisObject, vGroup, vItemName + "Picture", vItemType, New Structure("Type, Picture", FormDecorationType.Picture, ?(pIsOk, PictureLib.CheckMark, PictureLib.Attention)));	
	tcOnServer.cmCreateItem(ThisObject, vGroup, vItemName, vItemType, New Structure("Title", String(pCashRegisters) + ?(IsBlankString(pAmount), "", " - " + pAmount)));	
	CheckNumber = CheckNumber + 1;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearCheck()
	vItemCount = Items.GroupCheck3_2.ChildItems.Count();
	For vInd = 1 To vItemCount Do                           
		Items.Delete(Items.GroupCheck3_2.ChildItems[0]);
	EndDo;	
	CheckNumber = 0;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckBalancesForGuestsCheckingOutToday()	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	AccountsBalance.Folio AS Folio,
	|	AccountsBalance.SumBalance AS SumBalance,
	|	AccountsBalance.Folio.Client AS FolioClient
	|FROM
	|	AccumulationRegister.Accounts.Balance(&qEndOfTime, ) AS AccountsBalance
	|WHERE
	|	(&qCheckIndividualsBalancesOnly
	|				AND AccountsBalance.SumBalance > 0
	|			OR NOT &qCheckIndividualsBalancesOnly
	|				AND AccountsBalance.SumBalance <> 0)
	|	AND AccountsBalance.Hotel = &qHotel
	|	AND AccountsBalance.Folio.DateTimeTo BETWEEN &qDateFrom AND &qDateTo
	|	AND (NOT &qCheckIndividualsBalancesOnly
	|			OR &qCheckIndividualsBalancesOnly
	|				AND ISNULL(AccountsBalance.Folio.Customer.IsIndividual, TRUE))
	|
	|ORDER BY
	|	AccountsBalance.Folio.Room,
	|	AccountsBalance.Folio.DateTimeFrom,
	|	AccountsBalance.Folio.Client";
	
	Query.SetParameter("qHotel", Hotel);	
	Query.SetParameter("qDateFrom", BegOfDay(CurrentDate));
	Query.SetParameter("qDateTo", EndOfDay(CurrentDate));
	Query.SetParameter("qEndOfTime", '39991231235959');
	vCheckIndividualsBalancesOnly = True;
	If Object.alsoCheckCustomerBalances Then
		vCheckIndividualsBalancesOnly = False;
	EndIf;
	Query.SetParameter("qCheckIndividualsBalancesOnly", vCheckIndividualsBalancesOnly);
	QueryResult = Query.Execute();
	
	isError = False;	
	SelectionDetailRecords = QueryResult.Unload();
	If SelectionDetailRecords.Count() <> 0 Then
		isError = True;	
		Items.Status1.Picture = PictureLib.Attention;	
		checkBalances = False;
		If ValueIsFilled(Object.BalancesReport) Then
			Items.Report1.Visible = True;
		Else
			Items.Report1.Visible = False;
		EndIf;
	Else
		Items.Status1.Picture = PictureLib.CheckMark;	
		checkBalances = True;
		Items.Report1.Visible = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckReservations()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Reservations.Ref AS Ref,
	|	Reservations.Date AS Date,
	|	Reservations.Hotel AS Hotel,
	|	Reservations.ReservationStatus AS ReservationStatus
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.Posted
	|	AND Reservations.ReservationStatus.IsActive
	|	AND Reservations.Hotel = &qHotel
	|	AND Reservations.CheckInDate < &qCheckInDate";
	Query.SetParameter("qCheckInDate", EndOfDay(CurrentDate));
	Query.SetParameter("qHotel", Hotel);
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Unload();	
	If SelectionDetailRecords.Count() <> 0 Then
		If Object.checkReservationsIsMandatory Then
			Items.Status2.Picture = PictureLib.Attention;
			checkReservations = False;
		Else
			Items.Status2.Picture = PictureLib.InformationSmall;
			checkReservations = True;
		EndIf;
		If ValueIsFilled(Object.ReservationsReport) Then
			Items.Report2.Visible = True;
		Else
			Items.Report2.Visible = False;
		EndIf;
	Else		
		Items.Status2.Picture = PictureLib.CheckMark;
		checkReservations = True;
		Items.Report2.Visible = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckAccommodations()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Accommodations.Ref AS Ref,
	|	Accommodations.Date AS Date,
	|	Accommodations.Hotel AS Hotel,
	|	Accommodations.AccommodationStatus AS AccommodationStatus
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND Accommodations.AccommodationStatus.IsCheckOut
	|	AND Accommodations.Hotel = &qHotel
	|	AND Accommodations.CheckOutDate < &qCheckOutDate";
	Query.SetParameter("qCheckOutDate", EndOfDay(CurrentDate));
	Query.SetParameter("qHotel", Hotel);
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Unload();	
	If SelectionDetailRecords.Count() <> 0 Then
		If Object.checkAccommodationsIsMandatory Then
			Items.Status7.Picture = PictureLib.Attention;
			checkAccommodations = False;
		Else
			Items.Status7.Picture = PictureLib.InformationSmall;
			checkAccommodations = True;
		EndIf;
		If ValueIsFilled(Object.AccommodationsReport) Then
			Items.Report7.Visible = True;
		Else
			Items.Report7.Visible = False;
		EndIf;
	Else		
		Items.Status7.Picture = PictureLib.CheckMark;
		checkAccommodations = True;
		Items.Report7.Visible = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
// Description: Returns list of all active cash registers
// Parameters: Company
// Return value: Value list of cash registers
// -----------------------------------------------------------------------------
&AtServer
Function GetListOfCashRegisters(pCompany = Undefined)
	vList = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegisters.Ref AS CashRegister
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	NOT CashRegisters.DeletionMark
	|	AND CashRegisters.Hotel = &qHotel
	|	AND NOT CashRegisters.AutoCloseCashRegisterDay
	|
	|ORDER BY
	|	CashRegisters.SortCode";
	vQry.SetParameter("qHotel", Hotel);
	vQryResult = vQry.Execute().Unload();
	For Each vRow In vQryResult Do
		If ValueIsFilled(vRow.CashRegister) Then
			If ValueIsFilled(pCompany) Then
				If vRow.CashRegister.Owner <> pCompany Then
					Continue;
				EndIf;
			EndIf;
			vList.Add(vRow.CashRegister);
		EndIf;
	EndDo;
	// Add cash registers that are used by an agent contract
	If vList.Count() = 0 And ValueIsFilled(pCompany) And ValueIsFilled(pCompany.CompanyToUseCashRegistersFrom) Then
		For Each vRow In vQryResult Do
			vCashRegister = vRow.CashRegister;
			If ValueIsFilled(vCashRegister) And pCompany.CompanyToUseCashRegistersFrom = vCashRegister.Owner Then
				If Not vCashRegister.AutoCloseCashRegisterDay Then
					vList.Add(vCashRegister);
				EndIf;
			EndIf;
		EndDo;
	EndIf;	
	Return vList;
EndFunction // GetListOfCashRegisters

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckZReport()
	ClearCheck();	
	
	vAllowedCashRegisters = GetListOfCashRegisters();
	vDoCheckTimestamp = CurrentSessionDate();
	If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.NewAccountingDateCutOffTimeForPOS) Then
		vCutOffTime = BegOfDay(CurrentSessionDate()) + (Hotel.NewAccountingDateCutOffTimeForPOS - BegOfDay(Hotel.NewAccountingDateCutOffTimeForPOS));
		If vDoCheckTimestamp > vCutOffTime Then
			vDoCheckTimestamp = vCutOffTime;
		EndIf;
	EndIf;
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CashRegistersBalance.CashRegister AS CashRegister,
	|	CashRegistersBalance.Currency AS Currency,
	|	CashRegistersBalance.SumBalance AS SumBalance
	|FROM
	|	AccumulationRegister.CashRegisterDailyReceipts.Balance(&qPeriodTo, CashRegister IN (&qAllowedCashRegisters)) AS CashRegistersBalance
	|
	|ORDER BY
	|	CashRegistersBalance.Currency.SortCode,
	|	CashRegistersBalance.CashRegister.SortCode";
	vQry.SetParameter("qPeriodTo", vDoCheckTimestamp);
	vQry.SetParameter("qAllowedCashRegisters", vAllowedCashRegisters);
	vResult = vQry.Execute().Unload();
	
	// Do output
	vCashRegistersWithOpenShift = New ValueList();
	isError = False;	
	If vResult.Count() > 0 Then
		For Each vResultRow In vResult Do
			If vCashRegistersWithOpenShift.FindByValue(vResultRow.CashRegister) = Undefined Then
				vCashRegistersWithOpenShift.Add(vResultRow.CashRegister);
				vShiftAmount = "";
				If tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterXReport") Then
					vShiftAmount = cmFormatSum(vResultRow.SumBalance, vResultRow.Currency, "NZ=");
				EndIf;
				AddCashRegister(vResultRow.CashRegister, vShiftAmount, vResultRow.SumBalance = 0);
				If vResultRow.SumBalance <> 0 Then 
					isError = True;	
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Check orders connected created for the cash registers
	If ValueIsFilled(Hotel.AccountingDate) And EndOfDay(Hotel.AccountingDate + 24 * 3600) > vDoCheckTimestamp Then
		For Each vAllowedCashRegistersItem In vAllowedCashRegisters Do
			vCashRegisterObj = vAllowedCashRegistersItem.Value.GetObject();
			vLastEndOfShift = vCashRegisterObj.pmGetLastClosedCashRegisterDay(CurrentSessionDate());
			If ValueIsFilled(vLastEndOfShift) Then
				vStartOfCheckPeriod = vLastEndOfShift.Date;
				vEndOfCheckPeriod = vDoCheckTimestamp;
				If vEndOfCheckPeriod > vStartOfCheckPeriod Then
					vOrdersCount = GetOrdersCountForThePeriod(vCashRegisterObj.Ref, vStartOfCheckPeriod, vEndOfCheckPeriod);
					If vOrdersCount > 0 Then
						If vCashRegistersWithOpenShift.FindByValue(vCashRegisterObj.Ref) = Undefined Then
							vCashRegistersWithOpenShift.Add(vCashRegisterObj.Ref);
							AddCashRegister(vCashRegisterObj.Ref, "", False);
							isError = True;	
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Show status of the check
	If isError then
		Items.Status3.Picture = PictureLib.Attention;
		checkZReport = False;
	Else		
		Items.Status3.Picture = PictureLib.CheckMark;	
		checkZReport = True;
	EndIf;
EndProcedure // CheckZReport

// -----------------------------------------------------------------------------
&AtServer
Function GetOrdersCountForThePeriod(pCashRegister, pPeriodFrom, pPeriodTo)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Order.Ref AS Ref
	|FROM
	|	Document.Order AS Order
	|WHERE
	|	Order.CashRegister = &qCashRegister
	|	AND Order.Hotel = &qHotel
	|	AND Order.Posted
	|	AND Order.Date > &qPeriodFrom
	|	AND Order.Date <= &qPeriodTo";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCashRegister", pCashRegister);
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vOrders = vQry.Execute().Unload();
	Return vOrders.Count();
EndFunction // GetOrdersCountForThePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure closeSettings(p1, p2) Export 
	OnOpenAtServer();	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure OnOpenAtServer()
	vObject = FormAttributeToValue("Object");
	cmLoadDataProcessorAttributes(vObject);
	ValueToFormAttribute(vObject, "Object");
	
	CurrentDate = Hotel.AccountingDate;
	Items.GroupCheck1.Visible =	Object.checkBalances;
	Items.GroupCheck2.Visible =	Object.checkReservations;
	Items.GroupCheck7.Visible =	Object.checkAccommodations;
	Items.GroupCheck3.Visible =	Object.checkZReport;
	Items.GroupCheck4.Visible =	ValueIsFilled(Object.printBeforeReports); 
	Items.GroupCheck5.Visible =	ValueIsFilled(Object.printAfterReports);
	Items.GroupCheck8.Visible =	ValueIsFilled(Object.ExecutedBeforeDataProcessing);
	Items.GroupCheck9.Visible =	ValueIsFilled(Object.ExecutedAfterDataProcessing);
	Items.GroupCheck5.Enabled = False;
	Items.GroupCheck9.Enabled =	False;

	checkBalances	     			= Not Items.GroupCheck1.Visible;
	checkReservations	 			= Not Items.GroupCheck2.Visible;
	checkAccommodations  			= Not Items.GroupCheck7.Visible;
	checkZReport	     			= Not Items.GroupCheck3.Visible;
	printBeforeReports	 			= Not Items.GroupCheck4.Visible;
	ExecutedBeforeDataProcessing 	= Not Items.GroupCheck8.Visible;
	printAfterReports	 			= Not Items.GroupCheck5.Visible;
	ExecutedAfterDataProcessing 	= Not Items.GroupCheck9.Visible;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckIfChangeDateIsPossible()
	If Not ValueIsFilled(Hotel) Then
		Items.ChangeDate.Enabled = False;
		Items.GroupCheck5.Enabled = False;
		Items.GroupCheck9.Enabled = False;
	Else
		If CurrentDate < BegOfDay(CurrentDate()) Then
			If Not checkZReport Or Not checkBalances 
				Or (Not checkReservations And Object.checkReservationsIsMandatory) 
				Or (Not checkAccommodations And Object.checkAccommodationsIsMandatory) 
				Or Not printBeforeReports Or Not ExecutedBeforeDataProcessing Then
				Items.ChangeDate.Enabled = False;
				Items.GroupCheck5.Enabled = False;
				Items.GroupCheck9.Enabled = False;
			Else
				If Not ValueIsFilled(CloseOfPeriod) Then
					Items.ChangeDate.Enabled = True;
					Items.GroupCheck1.Enabled =	True;
					Items.GroupCheck2.Enabled =	True;
					Items.GroupCheck7.Enabled =	True;
					Items.GroupCheck3.Enabled =	True;
					Items.GroupCheck4.Enabled =	True; 
					Items.GroupCheck8.Enabled =	True;
					Items.GroupCheck5.Enabled = False;
					Items.GroupCheck9.Enabled = False;
				Else
					Items.ChangeDate.Enabled = False;
					Items.GroupCheck1.Enabled =	False;
					Items.GroupCheck2.Enabled =	False;
					Items.GroupCheck7.Enabled =	False;
					Items.GroupCheck3.Enabled =	False;
					Items.GroupCheck4.Enabled =	False;
					Items.GroupCheck8.Enabled =	False;
					Items.GroupCheck5.Enabled = True;
					Items.GroupCheck9.Enabled = True;
				EndIf;
			EndIf;
		Else
			Items.ChangeDate.Enabled = False;
			Items.GroupCheck5.Enabled = True;
			Items.GroupCheck9.Enabled = True;
		EndIf;
	EndIf;
EndProcedure // CheckIfChangeDateIsPossible

// -----------------------------------------------------------------------------
&AtServer
Procedure CreateDPInfo(pName, pItems)
	For Each vItem In DataProcessorsList Do 
		vItemName = pName + vItem.GetID();   
		vItemType = "FormDecoration";
		vGroup = tcOnServer.cmCreateItem(ThisObject, Items[pItems], vItemName, "FormGroup", New Structure("Type, Group, ShowTitle", FormGroupType.UsualGroup, ChildFormItemsGroup.AlwaysHorizontal, False));
		tcOnServer.cmCreateItem(ThisObject, vGroup, vItemName + "Emp", vItemType, New Structure("Title, Width", "", 2));	
		tcOnServer.cmCreateItem(ThisObject, vGroup, vItemName + "Picture", vItemType, New Structure("Type,Picture", FormDecorationType.Picture, vItem.Picture));	
		tcOnServer.cmCreateItem(ThisObject, vGroup, vItemName, vItemType, New Structure("Title", vItem.Presentation));	
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckReportFolder(pReport)
	vReports = New Array;
	If pReport.IsFolder Then
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	Reports.Ref AS Ref
		|FROM
		|	Catalog.Reports AS Reports
		|WHERE
		|	NOT Reports.IsFolder
		|	AND NOT Reports.DeletionMark
		|	AND Reports.Ref IN HIERARCHY(&qRef)";
		vQuery.SetParameter("qRef",pReport);
		vQueryResult = vQuery.Execute();
		
		vSelectionDetailRecords = vQueryResult.Select();
		
		While vSelectionDetailRecords.Next() Do
			vReports.Add(vSelectionDetailRecords.Ref);
		EndDo;
	Else
		vReports.Add(pReport);
	EndIf;
	Return vReports; 
EndFunction

// -----------------------------------------------------------------------------
&AtServerNoContext
Function CheckDPFolder(pDP)
	vDPs = New ValueList();
	If pDP.IsFolder Then
		vQuery = New Query;
		vQuery.Text = 
		"SELECT
		|	DataProcessors.Ref AS Ref
		|FROM
		|	Catalog.DataProcessors AS DataProcessors
		|WHERE
		|	NOT DataProcessors.IsFolder
		|	AND NOT DataProcessors.DeletionMark
		|	AND DataProcessors.Ref IN HIERARCHY(&qRef)
		|
		|ORDER BY
		|	DataProcessors.SortCode,
		|	DataProcessors.Code";
		vQuery.SetParameter("qRef",pDP);
		vQueryResult = vQuery.Execute();
		
		vSelectionDetailRecords = vQueryResult.Select();
		
		While vSelectionDetailRecords.Next() Do
			vDPs.Add(vSelectionDetailRecords.Ref, TrimAll(vSelectionDetailRecords.Ref), False, PictureLib.Attention);
		EndDo;
	Else
		vDPs.Add(pDP, TrimAll(pDP), False, PictureLib.Attention);
	EndIf;
	Return vDPs; 
EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure GenerateReports(pReports)
	For Each vRow In pReports Do
		Try			
			OpenForm("Report." + tcOnServer.cmGetAttributeByRef(vRow, "Report") + ".Form.tcReportForm", New Structure("FillingValues, GenerateOnOpen, Parameters", New Structure("ReportRef", vRow), True, New Structure("PrinterName", Object.PrinterName)));
		Except
			tcCommonFunctionOnClientServer.TextMessage(NStr(vRow) + " - " + 
			        NStr("en='This report could not be executed in thin client mode yet!'; 
			             |ru='Этот отчет пока не может быть запущен в режиме тонкого клиента!'; 
			             |de='Dieser Bericht kann noch nicht in Thin-Client-Modus gestartet werden!'"), MessageStatus.Attention);
		EndTry;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Function RunDP()
	vResult = False;
	Try
		For Each vRow In DataProcessorsList Do
			vDPObj = tcOnServer.cmGetAtributeAsArray(vRow.Value);
			
			vPrinterName = New Structure("PrinterName", Object.PrinterName);
			
			vFormParams = New Structure;
			vFormParams.Insert("DataProcessor", vRow.Value);
			vFormParams.Insert("GenerateOnOpen", True);   
			vFormParams.Insert("Parameters", vPrinterName);
			
			If vDPObj.IsExternal Then
				vURL = GetURL(vDPObj.Processing, "ExternalProcessingStorage"); 
				vName = ConnectExternalDataProcessor(vURL, StrReplace(tcOnServer.cmGetAttributeByRef(vDPObj.Processing,"FileName"), ".epf",""));
				OpenForm("ExternalDataProcessor." + vName + ".Form", vFormParams, ThisObject, vRow.Value);
			Else
				If vDPObj.Processing = Undefined Then
					Raise TrimAll(vRow.Value) + Nstr("en = ' - You must fill the handler in the processing settings'; de = ' - Sie müssen den Handler in den Verarbeitungseinstellungen angeben'; ru = ' - Необходимо заполнить обработчик в настройках обработки'");
				Else
					OpenForm("DataProcessor." + vDPObj.Processing + ".Form", vFormParams, ThisObject, vRow.Value);
				EndIf;
			EndIf;
			vRow.Check = True;
			vRow.Picture = PictureLib.CheckMark;
		EndDo;
		vResult = True;
	Except
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription(), MessageStatus.Important);
		vResult = False;
	EndTry;
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	vUnsafeOperationProtectionDescription = New UnsafeOperationProtectionDescription;
	vUnsafeOperationProtectionDescription.UnsafeOperationWarnings = False;
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode, vUnsafeOperationProtectionDescription);
EndFunction 

// -----------------------------------------------------------------------------
&AtServer
Procedure ChangeDateAtServer()      
	vDPObj = FormAttributeToValue("Object");
	SetObjectAndFormAttributeConformity(vDPObj, "Object");
	// Check if day was already closed
	vHotel = Hotel;
	If ValueIsFilled(vHotel.AccountingDate) And vHotel.AccountingDate >= BegOfDay(CurrentSessionDate()) Then
		CurrentDate = vHotel.AccountingDate;  
		
		vErr = NStr("en = 'Day was already closed at some other workstation!'; 
					|de = 'Der Tag ist an einem anderen Arbeitsplatz bereits geschlossen!'; 
					|ru = 'День уже закрыт на другом рабочем месте!'");
		
		tcCommonFunctionOnClientServer.UserMessage(vErr, vDPObj, "CurrentDate", , True);
		Return;
	EndIf;
	// Current hotel date
	vAccountingDate = Hotel.AccountingDate;
	// Get list of companies to close day for
	vCompanies = GetHotelCompanies(Hotel);
	// Create end of day documents for each company in the list
	vCloseOfDayObj = Undefined;
	vCompaniesRow = Undefined;
	Try
		BeginTransaction(DataLockControlMode.Managed);
		For Each vCompaniesRow In vCompanies Do
			vCloseOfDayObj = Documents.CloseOfPeriod.CreateDocument();
			vCloseOfDayObj.Fill(vCompaniesRow.Company);
			vCloseOfDayObj.Date = EndOfDay(vAccountingDate);
			vCloseOfDayObj.Hotel = Hotel;
			vCloseOfDayObj.SetTime(AutoTimeMode.DontUse);
			vCloseOfDayObj.Write(DocumentWriteMode.Write);
			vCloseOfDayObj.Date = EndOfDay(vAccountingDate);
			If vCompanies.IndexOf(vCompaniesRow) < (vCompanies.Count() - 1) Then
				vCloseOfDayObj.AdditionalProperties.Insert("SkipChangingDate", True);
			EndIf;
			vCloseOfDayObj.Write(DocumentWriteMode.Posting);
		EndDo;
		CommitTransaction();
	Except
		vErrorInfo = ErrorInfo();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		vCloseOfDayObj = Undefined;
		// Log error
		vErrorDescription = cmGetRootErrorDescription(vErrorInfo);
		WriteLogEvent(NStr("en='End of day'; ru='Закрытие дня'; de='Tagesabschluss'"), 
		              EventLogLevel.Error, , Hotel, 
					  NStr("en='Company: '; ru='Фирма: '; de='Kompanie: '") + ?(vCompaniesRow = Undefined, "N/A", TrimAll(vCompaniesRow.Company)) + ", " + 
					  Format(vAccountingDate, "DF=dd.MM.yyyy") + ", " + 
					  NStr("en='Error: '; ru='Ошибка: '; de='Fehler: '") + vErrorDescription);
		// Show message         
		vErr = NStr("en='An error occured while closing the day!'; 
		                |ru='При закрытии дня произошла ошибка!'; 
						|de='Beim Schließen des Tages ist ein Fehler aufgetreten!'") + Chars.LF 
						+ vErrorDescription + Chars.LF 
						+ NStr("en = 'Please wait a few minutes and try again. If the error persists, contact technical support.'; 
							   |de = 'Bitte warten Sie einige Minuten und versuchen Sie es erneut. Wenn der Fehler weiterhin besteht, wenden Sie sich an den technischen Support.'; 
							   |ru = 'Пожалуйста подождите несколько минут и попробуйте еще раз. Если ошибка повторится, обращайтесь в службу технической поддержки.'");
		tcCommonFunctionOnClientServer.UserMessage(vErr, vDPObj, "CurrentDate", , True);
	EndTry;
	// Fill references to new day and end of day document
	If vCloseOfDayObj <> Undefined Then
		CloseOfPeriod = vCloseOfDayObj.Ref;
		CurrentDate = Hotel.AccountingDate;
	EndIf;   
EndProcedure // ChangeDateAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetHotelCompanies(pHotel)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CurrentAccountsReceivableBalance.Company AS Company,
	|	CurrentAccountsReceivableBalance.SumBalance AS SumBalance,
	|	CurrentAccountsReceivableBalance.QuantityBalance AS QuantityBalance,
	|	CurrentAccountsReceivableBalance.CommissionSumBalance AS CommissionSumBalance
	|FROM
	|	AccumulationRegister.CurrentAccountsReceivable.Balance(
	|			,
	|			Hotel = &qHotel
	|				AND NOT Company.DeletionMark) AS CurrentAccountsReceivableBalance
	|
	|ORDER BY
	|	CurrentAccountsReceivableBalance.Company.SortCode,
	|	CurrentAccountsReceivableBalance.Company.Description";
	vQry.SetParameter("qHotel", pHotel);
	vCompanies = vQry.Execute().Unload();
	If ValueIsFilled(pHotel.Company) Then
		If vCompanies.Find(pHotel.Company, "Company") = Undefined Then
			vCompaniesRow = vCompanies.Add();
			vCompaniesRow.Company = pHotel.Company;
		EndIf;
	EndIf;
	Return vCompanies;
EndFunction // GetHotelCompanies

#EndRegion
