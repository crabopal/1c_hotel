
#Region Public

// -----------------------------------------------------------------------------
Function GetGuestGroupTotals(pGuestGroup) Export 
	vRes = New Structure;
	vRes.Insert("TotalRooms", 0);
	vRes.Insert("Sales", 0);
	
	If ValueIsFilled(pGuestGroup) Then
		vGuestGroupObj = pGuestGroup.GetObject();
		vSales 		 = 0;
		vTotalRooms  = 0;
		
		vRITotals 	 = vGuestGroupObj.pmGetRoomInventoryTotals();
		
		vSalesTotals = vGuestGroupObj.pmGetSalesTotals();
		vRes.Sales = vSalesTotals.Total("Sales") + vSalesTotals.Total("SalesForecast");
		
		If vRITotals.Count() > 0 Then
			vRITotalsRow 	= vRITotals.Get(0);
			vRes.TotalRooms	= vRITotalsRow.RoomsReserved;
		EndIf;
		
	EndIf;
	Return vRes;
EndFunction

// -----------------------------------------------------------------------------
//  Description: ConvertPhoneNumber
//
// Parameters:
//  pPhoneNumber - String - PhoneNumber
// 
// Returns:
//   - String
//
Function ConvertPhoneNumber(pPhoneNumber) Export
	
	vOnlyNumber = "";
	For vInd = 1 To StrLen(pPhoneNumber) Do
		If StrOccurrenceCount("1234567890", Mid(pPhoneNumber, vInd, 1)) > 0 Then
			vOnlyNumber = vOnlyNumber + Mid(pPhoneNumber, vInd, 1);
		EndIf;
	EndDo;
	
	Return vOnlyNumber;
	
EndFunction // ConvertPhoneNumber()

// -----------------------------------------------------------------------------
// Description: GetClientsByPhoneNumber
// Parameters: pPhoneNumber
// Return value: Structure, fild (Client,Customer,Room,Workstation)
Function GetClientsByPhoneNumber(pPhoneNumber) Export
	
	vStruct = New Structure();
	vStruct.Insert("Client",	Undefined);
	vStruct.Insert("Customer", 	Undefined);
	vStruct.Insert("Room",		Undefined);
	vStruct.Insert("Workstation", Undefined);
	
	vStrPhone		= ConvertPhoneNumber(TrimAll(pPhoneNumber));			   
	
	vPhoneRigth = vStrPhone;
	
	If StrLen(vStrPhone) > 6 Then
		vPhoneRigth = Right(vStrPhone, 6);
	EndIf;
	
	vQuery = New Query();
	vQuery.SetParameter("qPhoneNumber", vStrPhone);
	vQuery.SetParameter("qPhoneRigth", vPhoneRigth);
	
	vQuery.Text = "SELECT TOP 1
	              |	PhoneNumbers.Room AS Room
	              |FROM
	              |	Catalog.PhoneNumbers AS PhoneNumbers
	              |WHERE
	              |	NOT PhoneNumbers.DeletionMark
	              |	AND (PhoneNumbers.PhoneNumber = &qPhoneNumber
	              |			OR PhoneNumbers.PhoneNumber LIKE ""%"" + &qPhoneRigth)
	              |	AND PhoneNumbers.IsFolder = FALSE
	              |
	              |ORDER BY
	              |	PhoneNumbers.PhoneNumber";
	
	vRes = vQuery.Execute();
	If Not vRes.IsEmpty() Then
		
		vSel = vRes.Select();
		vSel.Next();
		
		vStruct.Room = vSel.Room;
		
		
	ElsIf StrLen(vStrPhone) >= 6 Then
		
		vQuery.Text = "SELECT TOP 1
		              |	Clients.Ref AS Client,
		              |	Clients.CreateDate AS CreateDate
		              |FROM
		              |	Catalog.Clients AS Clients
		              |WHERE
		              |	Clients.IsFolder = FALSE
		              |	AND (Clients.Phone = &qPhoneNumber
		              |			OR Clients.Phone LIKE ""%"" + &qPhoneRigth)
		              |	AND Clients.DeletionMark = FALSE
		              |
		              |ORDER BY
		              |	Clients.Description,
		              |	Clients.CreateDate";
		
		vRes = vQuery.Execute();
		
		If Not vRes.IsEmpty() Then
			
			vSel = vRes.Select();
			vSel.Next();
			
			vStruct.Client = vSel.Client;
		Else
			vQuery.Text = "SELECT TOP 1
			              |	Customers.Ref AS Customer,
			              |	Customers.CreateDate AS CreateDate
			              |FROM
			              |	Catalog.Customers AS Customers
			              |WHERE
			              |	Customers.IsFolder = FALSE
			              |	AND (Customers.Phone = &qPhoneNumber
			              |			OR Customers.Phone LIKE ""%"" + &qPhoneRigth)
			              |	AND Customers.DeletionMark = FALSE
			              |
			              |ORDER BY
			              |	Customers.Description,
			              |	Customers.CreateDate";
			
			vRes = vQuery.Execute();
			If Not vRes.IsEmpty() Then
				
				vSel = vRes.Select();
				vSel.Next();
				
				vStruct.Customer = vSel.Customer;
			EndIf;   
		EndIf;
	Else
		vQuery.Text = "SELECT TOP 1
		              |	Workstations.Ref AS Workstation
		              |FROM
		              |	Catalog.Workstations AS Workstations
		              |WHERE
		              |	NOT Workstations.DeletionMark
		              |	AND (Workstations.PhoneNumberInternal = &qPhoneNumber
		              |			OR Workstations.PhoneNumberInternal LIKE ""%"" + &qPhoneRigth)
		              |	AND Workstations.IsFolder = FALSE
		              |
		              |ORDER BY
		              |	Workstations.PhoneNumber";
		
		vRes = vQuery.Execute();
		If Not vRes.IsEmpty() Then
			vSel = vRes.Select();
			vSel.Next();
			
			vStruct.Workstations = vSel.Workstation;
		EndIf;   
	EndIf;
	
	Return vStruct;		   
	
EndFunction // GetClientsByPhoneNumber

// -----------------------------------------------------------------------------
// Description: GetIDCurrentWorkstation
// Parameters: 
// Return value: UUID Current workstation
Function GetIDCurrentWorkstation() Export
			
	Return TrimAll(SessionParameters.CurrentWorkstation.UUID());
	
EndFunction // GetIDCurrentWorkstation()

// -----------------------------------------------------------------------------
// Description: Save History Calls in Information Register
// Parameters:  pPhoneNumberFrom, pPhoneNumberTo, pDuration, pDateFrom, pDateTo, pRoute, pFile,pID
// Return value:  None
Procedure SaveHistoryCalls(pPhoneNumberFrom, pPhoneNumberTo, pDuration, pDateFrom, pDateTo, pRoute, pFile, pID) Export
	If pRoute = 0 Then
		// 0 - Incoming 1 - Outgoing
		vData = GetClientsByPhoneNumber(pPhoneNumberFrom);
	ElsIf  pRoute = 1 Then
		vData = GetClientsByPhoneNumber(pPhoneNumberTo);
		//  1 - Outgoing
	Else
		//	2 - Missed    
		vData = Undefined;
		Return;
	EndIf;
	
	vUser = GetCurrentUser();
	
	// Check record in Register
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HistorySimpleCalls.ID AS ID
		|FROM
		|	InformationRegister.HistorySimpleCalls AS HistorySimpleCalls
		|WHERE
		|	HistorySimpleCalls.ID = &qID";
	
	Query.SetParameter("qID", pID);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		vRecord =  InformationRegisters.HistorySimpleCalls.CreateRecordManager();
		
		vRecord.ID					= pID;
		vRecord.PhoneNumberFrom		= TrimAll(pPhoneNumberFrom);
		vRecord.PhoneNumberTo		= TrimAll(pPhoneNumberTo);
		
		vRecord.DateFrom			= pDateFrom;
		vRecord.DateTo				= pDateTo;
		                              // Convert 123 sec in 2.03 min
		vRecord.Duration			= Int(Round(pDuration / 60, 2)) + (pDuration - Int(Round(pDuration / 60, 2)) * 60) / 100;
		vRecord.Route				= ?(vRecord.Duration = 0, 2, pRoute);
		vRecord.File				= pFile;
		
		vRecord.Client				= vData.Client;
		vRecord.Customer			= vData.Customer;
		vRecord.Room				= vData.Room;
		vRecord.User 				= vUser;
		vRecord.Missed 				= ?(vRecord.Duration > 0, False, True);
		vRecord.Workstation 		= SessionParameters.CurrentWorkstation;
		
		vRecord.Hotel				= SessionParameters.CurrentHotel;

		vRecord.Write();
	Else
		vRecord =  InformationRegisters.HistorySimpleCalls.CreateRecordManager();
		vRecord.ID					= pID;
		vRecord.Read();
		vRecord.ID					= pID;
		vRecord.PhoneNumberFrom		= TrimAll(pPhoneNumberFrom);
		vRecord.PhoneNumberTo		= TrimAll(pPhoneNumberTo);
		
		vRecord.DateFrom			= pDateFrom;
		vRecord.DateTo				= pDateTo;
		                              // Convert 123 sec in 2.03 min
		vRecord.Duration			= Int(Round(pDuration / 60, 2)) + (pDuration - Int(Round(pDuration / 60, 2)) * 60) / 100;
		vRecord.Route				= ?(vRecord.Duration = 0, 2, pRoute);
		vRecord.File				= pFile;
		
		vRecord.Client				= vData.Client;
		vRecord.Customer			= vData.Customer;
		vRecord.Room				= vData.Room;
		vRecord.User 				= vUser;
		vRecord.Missed 				= ?(vRecord.Duration > 0, False, True);
		vRecord.Workstation 		= SessionParameters.CurrentWorkstation;

		vRecord.Hotel				= SessionParameters.CurrentHotel;
		
		vRecord.Write();
	EndIf;
	
EndProcedure // SaveHistoryCalls

// -----------------------------------------------------------------------------
// Description: GetCurrentUser
// Parameters: 
// Return value: CurrentUser
Function GetCurrentUser() Export
	Return SessionParameters.CurrentUser;
EndFunction // GetCurrentUser()

// -----------------------------------------------------------------------------
// Description: GetNumberStr
// Parameters:  pPhoneNumber
// Return value: PhoneNumber as string
Function GetNumberStr(pPhoneNumber)
	
	vPhoneNumber = "";
	
	vStrLen = StrLen(pPhoneNumber);
	
	For vInd = 1 To vStrLen Do
		vSbl = Mid(pPhoneNumber, vInd, 1);
		If Find("0123456789", vSbl) > 0 Then
			vPhoneNumber = vPhoneNumber + vSbl;
		EndIf;
	EndDo;
	
	Return vPhoneNumber;
	
EndFunction  // GetNumberStr

// -----------------------------------------------------------------------------
// Description: GetParameters
// Parameters:  None
// Return value: Structure settings
Function GetParameters(pWorkstation = Undefined) Export
	SetPrivilegedMode(True);
	vWorkstation  = ?(pWorkstation = Undefined, SessionParameters.CurrentWorkstation, pWorkstation);
	vTrans = SystemSettingsStorage.Load("SimpleCalls", TrimAll(vWorkstation), , TrimAll(vWorkstation));
	If vTrans = Undefined Then
		vTrans = New Structure;
		vTrans.Insert("ShowWindowIncomingCall",			NStr("en = 'When a call'; de = 'Wenn ein Anruf'; ru = 'При поступлении звонка'"));
		vTrans.Insert("ShowWindowOutCall",				NStr("en = 'When a call'; de = 'Zu Beginn des Anrufs'; ru = 'При поступлении звонка'"));
		vTrans.Insert("SaveHistoryCalls",				NStr("en = 'Incoming and outgoing'; de = 'Eingehende und ausgehende'; ru = 'Входящие и исходящие'"));
		vTrans.Insert("UseAutomaticRedirection",		True);
		vTrans.Insert("UserPhoneNumber",				vWorkstation.PhoneNumberInternal);
		vTrans.Insert("GUID",							"");
		vTrans.Insert("ServerATC",						"127.0.0.1:10150");
		vTrans.Insert("Password",						"");
		vTrans.Insert("CloseWindows",					0);
	Else
		If Not vTrans.Property("CloseWindows") Then
			vTrans.Insert("CloseWindows", 0);
		EndIf; 
	EndIf;
	SetPrivilegedMode(False);
	Return  vTrans;
EndFunction // GetParameters()

// -----------------------------------------------------------------------------
// Description: GetCityCodes
// Parameters:  None
// Return value: ValueTable City codes
Function GetCityCodes() Export
	
	vCityCodes = New ValueTable;
	vCityCodes.Columns.Add("CityCode");
	vCityCodes.Columns.Add("City");
	
	vDoc = New SpreadsheetDocument;
	vTemplate = GetCommonTemplate("SimpleCalls_CityCodes");
	
	vDoc.Put(vTemplate.GetArea("Header"));
	
	For vInd = 1 To 2216 Do
		
		vStrNumber = Format(vInd, "NGS=; NG=");
		
		vStr = vCityCodes.Add();
		vStr.CityCode	= TrimAll(vDoc.Area("R" + vStrNumber + "C1").Text);
		vStr.City		= TrimAll(vDoc.Area("R"  + vStrNumber + "C2").Text);
		
	EndDo;
	
	vCityCodes.Indexes.Add("CityCode");
	
	Return vCityCodes;
	
EndFunction // GetCityCodes()

// -----------------------------------------------------------------------------
// Description: GetMobileCodes
// Parameters:  None
// Return value: ValueTable Mobile operators codes
Function GetMobileCodes() Export
	
	vMobileCodes = New ValueTable;
	vMobileCodes.Columns.Add("OperatorCode");
	vMobileCodes.Columns.Add("PhoneNumberFrom");
	vMobileCodes.Columns.Add("PhoneNumberTo");
	vMobileCodes.Columns.Add("Region");
	
	vDoc = New SpreadsheetDocument;
	vTemplate = GetCommonTemplate("SimpleCalls_CodesMobileOperators");
	
	vDoc.Put(vTemplate.GetArea("Header"));
	
	For vInd = 1 To 3464 Do
		
		vStrNumber = Format(vInd, "NGS=; NG=");
		
		vStr = vMobileCodes.Add();
		
		vStr.OperatorCode		= TrimAll(vDoc.Area("R" + vStrNumber + "C1").Text);
		vStr.PhoneNumberFrom	= TrimAll(vDoc.Area("R" + vStrNumber + "C2").Text);
		vStr.PhoneNumberTo		= TrimAll(vDoc.Area("R" + vStrNumber + "C3").Text);
		vStr.Region				= TrimAll(vDoc.Area("R" + vStrNumber + "C4").Text);
		
	EndDo;
	
	vMobileCodes.Indexes.Add("OperatorCode");
	
	Return vMobileCodes;
EndFunction // GetMobileCodes()

// -----------------------------------------------------------------------------
// Description: GetLatestCheckIn
// Parameters:  pGuest, pCustomer
// Return value: Document or Undefined
Function GetLatestCheckIn(pGuest = Undefined, pCustomer = Undefined) Export
	If Not ValueIsFilled(pGuest) Then
		pGuest = Catalogs.Clients.EmptyRef()
	EndIf;	
	
	If Not  ValueIsFilled(pCustomer) Then
		pCustomer = Catalogs.Customers.EmptyRef()
	EndIf;	
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	Accommodation.Ref AS Document,
	|	Accommodation.GuestGroup AS GuestGroup,
	|	Accommodation.CheckOutDate AS CheckOutDate,
	|	Accommodation.CheckInDate AS CheckInDate
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	(Accommodation.Guest = &qGuest
	|			OR &qGuest = VALUE(Catalog.Clients.EmptyRef))
	|	AND (Accommodation.Customer = &qCustomer
	|			OR &qCustomer = VALUE(Catalog.Customers.EmptyRef))
	|	AND Accommodation.AccommodationStatus.IsCheckOut
	|	AND Accommodation.Posted
	|	AND Accommodation.DeletionMark = FALSE
	|
	|ORDER BY
	|	Accommodation.PointInTime DESC";
	vQuery.SetParameter("qGuest", pGuest);
	vQuery.SetParameter("qCustomer", pCustomer);
	
	vQueryRes = vQuery.Execute();
	
	If vQueryRes.IsEmpty() Then
		Return Undefined;
	Else	
		vSel = vQueryRes.Select();
		While vSel.Next() Do
			vStruct = New Structure();
			vStruct.Insert("Document", vSel.Document); 
			vStruct.Insert("GuestGroup", vSel.GuestGroup);
			vStruct.Insert("CheckInDate", vSel.CheckInDate);
			vStruct.Insert("CheckOutDate", vSel.CheckOutDate);

			Return vStruct;		
		EndDo;
	EndIf;
EndFunction //  LatestCheckIn()

// -----------------------------------------------------------------------------
// Description: GetReservation
// Parameters:  pGuest, pCustomer
// Return value: Document or Undefined
Function GetReservation(pGuest = Undefined, pCustomer = Undefined) Export

	If Not  ValueIsFilled(pGuest) Then
		pGuest = Catalogs.Clients.EmptyRef()
	EndIf;	
	
	If Not  ValueIsFilled(pCustomer) Then
		pCustomer = Catalogs.Customers.EmptyRef()
	EndIf;	

	Query = New Query;
	Query.Text = "SELECT TOP 1
	             |	Reservation.Ref AS Document,
	             |	Reservation.GuestGroup AS GuestGroup,
	             |	Reservation.CheckInDate AS CheckInDate,
	             |	Reservation.CheckOutDate AS CheckOutDate
	             |FROM
	             |	Document.Reservation AS Reservation
	             |WHERE
	             |	(Reservation.Guest = &qGuest
	             |			OR &qGuest = VALUE(Catalog.Clients.EmptyRef))
	             |	AND (Reservation.Customer = &qCustomer
	             |			OR &qCustomer = VALUE(Catalog.Customers.EmptyRef))
	             |	AND Reservation.ReservationStatus.IsActive
	             |	AND Reservation.Posted
	             |
	             |ORDER BY
	             |	Reservation.PointInTime DESC";
	Query.SetParameter("qGuest", pGuest);
	Query.SetParameter("qCustomer", pCustomer);
	
	vRes = Query.Execute();
	
	If vRes.IsEmpty() Then
		Return Undefined;
	Else	
		vSel = vRes.Select();
		While vSel.Next() Do    
			vStruct = New Structure();
			vStruct.Insert("Document", vSel.Document); 
			vStruct.Insert("GuestGroup", vSel.GuestGroup);
			vStruct.Insert("CheckInDate", vSel.CheckInDate);
			vStruct.Insert("CheckOutDate", vSel.CheckOutDate);

			Return vStruct;	
		EndDo;
	EndIf;
EndFunction //  GetReservation()

// -----------------------------------------------------------------------------
// Description: GetInvoice
// Parameters:   pCustomer
// Return value: Structure or Undefined
Function GetInvoice(pCustomer = Undefined) Export
	If Not ValueIsFilled(pCustomer) Then
		Return Undefined;
	EndIf;	
	
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Inv.Ref AS Document,
	|	ISNULL(InvoiceAccountsBalance.SumBalance, 0) AS SumBalance,
	|	Inv.Sum AS Sum
	|FROM
	|	AccumulationRegister.InvoiceAccounts.Balance AS InvoiceAccountsBalance
	|		LEFT JOIN Document.ProformaInvoice AS Inv
	|		ON InvoiceAccountsBalance.Invoice = Inv.Ref
	|WHERE
	|	Inv.AccountingCustomer = &qCustomer
	|
	|ORDER BY
	|	Inv.Date DESC,
	|	Inv.PointInTime DESC";
	vQry.SetParameter("qCustomer", pCustomer);

	vQueryResult = vQry.Execute();
	
	If vQueryResult.IsEmpty() Then
		Return Undefined;
	Else	
		vSel = vQueryResult.Select();
		While vSel.Next() Do
			vStruct = New Structure();
			vStruct.Insert("Document", vSel.Document);
			vStruct.Insert("SumBalance", vSel.SumBalance);   
			vStruct.Insert("Sum", vSel.Sum);
			Return vStruct;	
		EndDo;
	EndIf;
EndFunction // GetInvoice()

// -----------------------------------------------------------------------------
// Description: GetMainAccomodationByRoom
// Parameters:   pRoom
// Return value: Document or Undefined
Function GetMainAccomodationByRoom(pRoom = Undefined) Export
	If Not ValueIsFilled(pRoom) Then
		Return Undefined;
	EndIf;	
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.Ref AS Document,
	|	Docs.SortCode AS SortCode,
	|	Docs.AccommodationType AS AccommodationType,
	|	Docs.GuestGroup AS GuestGroup,
	|	Docs.CheckInDate AS CheckInDate,
	|	Docs.CheckOutDate AS CheckOutDate,
	|	Docs.Customer AS Customer,
	|	Docs.Guest AS Guest
	|FROM
	|	Document.Accommodation AS Docs
	|WHERE
	|	Docs.Room = &qRoom
	|	AND Docs.Posted
	|	AND Docs.AccommodationStatus.IsActive
	|	AND Docs.AccommodationStatus.IsInHouse
	|
	|ORDER BY
	|	Docs.Date,
	|	Docs.PointInTime";
	vQry.SetParameter("qRoom", pRoom);

	QueryResult = vQry.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	Else
		vSel = QueryResult.Select();
		While vSel.Next() Do
			If vSel.AccommodationType.Type = Enums.AccomodationTypes.Room Then
				vStruct = New Structure();
				vStruct.Insert("Document", vSel.Document); 
				vStruct.Insert("GuestGroup", vSel.GuestGroup);
				vStruct.Insert("CheckInDate", vSel.CheckInDate);
				vStruct.Insert("CheckOutDate", vSel.CheckOutDate);
				vStruct.Insert("Customer", vSel.Customer);
				vStruct.Insert("Guest", vSel.Guest);
				
				Return vStruct;	
			EndIf;
		EndDo;
		vSel.Reset();
		vSel.Next();  
		
		vStruct = New Structure();
		vStruct.Insert("Document", vSel.Document); 
		vStruct.Insert("GuestGroup", vSel.GuestGroup);
		vStruct.Insert("CheckInDate", vSel.CheckInDate);
		vStruct.Insert("CheckOutDate", vSel.CheckOutDate);
		vStruct.Insert("Customer", vSel.Customer);
		vStruct.Insert("Guest", vSel.Guest);
		
		Return vStruct;	
	EndIf;
EndFunction //  GetAccomodationByRoom()

// -----------------------------------------------------------------------------
Function GetAccomodationsByRoom(pRoom = Undefined) Export
	If Not ValueIsFilled(pRoom) Then
		Return Undefined;
	EndIf;	
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Docs.Ref AS Document,
	|	Docs.SortCode AS SortCode,
	|	Docs.AccommodationType AS AccommodationType
	|FROM
	|	Document.Accommodation AS Docs
	|WHERE
	|	Docs.Room = &qRoom
	|	AND Docs.Posted
	|	AND Docs.AccommodationStatus.IsActive
	|	AND Docs.AccommodationStatus.IsInHouse
	|
	|ORDER BY
	|	Docs.AccommodationType.SortCode,
	|	Docs.Date,
	|	Docs.PointInTime";
	vQry.SetParameter("qRoom", pRoom);

	Return vQry.Execute().Unload();
	
EndFunction // GetAccomodationByRoom()

// -----------------------------------------------------------------------------
// Description: CheckAnswer
// Parameters:   pID
// Return value: None
Function CheckAnswer(pID) Export
	// Check record in Register
	Query = New Query;
	Query.Text = 
	"SELECT
	|	HistorySimpleCalls.Workstation AS Workstation
	|FROM
	|	InformationRegister.HistorySimpleCalls AS HistorySimpleCalls
	|WHERE
	|	HistorySimpleCalls.ID = &qID
	|	AND NOT HistorySimpleCalls.Missed";
	
	Query.SetParameter("qID", pID);
	
	vRes = Query.Execute();
	
	If vRes.IsEmpty() Then
		Return  False;
	Else
		SelectionDetailRecords = vRes.Select();
		SelectionDetailRecords.Next();
		vWorkstation =  SelectionDetailRecords.Workstation;	
		
		If vWorkstation <> SessionParameters.CurrentWorkstation Then
			Return  True;
		Else 
			Return  False;
		EndIf;
	EndIf;	
EndFunction	// CheckAnswer()

// -----------------------------------------------------------------------------
// Description: TimeOff
// Parameters:   pDateFrom,pTime
// Return value: True or False
Function TimeOff(pDateFrom, pTime) Export
	If pTime > 0 Then
		vDateTo = pDateFrom + pTime; 
		If CurrentSessionDate() > vDateTo Then
			Return True;
		EndIf;
	EndIf;	
	Return False;
EndFunction //  TimeOff()

// -----------------------------------------------------------------------------
// Description: SaveCall
// Parameters:   pID,pPhoneNumberFrom,pPhoneNumberTo, pMissed
// Return value: None
Procedure SaveCall(pID, pPhoneNumberFrom, pPhoneNumberTo, pMissed = True) Export
	vData = GetClientsByPhoneNumber(pPhoneNumberFrom);

	vUser = GetCurrentUser();
	
	// Check record in Register
	Query = New Query;
	Query.Text = 
	"SELECT
	|	HistorySimpleCalls.ID AS ID,
	|	HistorySimpleCalls.Missed AS Missed
	|FROM
	|	InformationRegister.HistorySimpleCalls AS HistorySimpleCalls
	|WHERE
	|	HistorySimpleCalls.ID = &qID";
	
	Query.SetParameter("qID", pID);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		vRecord =  InformationRegisters.HistorySimpleCalls.CreateRecordManager();
		
		vRecord.ID					= pID;
		vRecord.PhoneNumberFrom		= TrimAll(pPhoneNumberFrom);
		vRecord.PhoneNumberTo		= TrimAll(pPhoneNumberTo);
		vRecord.DateFrom			= CurrentSessionDate();
		vRecord.DateTo				= "";
		vRecord.Duration			= 0;
		vRecord.Route				= 2;
		vRecord.File				= "";
		vRecord.Client				= vData.Client;
		vRecord.Customer			= vData.Customer;
		vRecord.Room				= vData.Room;
		vRecord.User 				= Catalogs.Employees.EmptyRef();
		vRecord.Workstation 		= Catalogs.Workstations.EmptyRef();
		vRecord.Missed 				= pMissed;
		vRecord.Hotel				= SessionParameters.CurrentHotel;
		vRecord.Write();
	Else
		If  pMissed Then
			Return
		EndIf;
		vRecord =  InformationRegisters.HistorySimpleCalls.CreateRecordManager();
		vRecord.ID					= pID;
		vRecord.Read();
			
		vRecord.ID					= pID;
		vRecord.PhoneNumberFrom		= TrimAll(pPhoneNumberFrom);
		vRecord.PhoneNumberTo		= TrimAll(pPhoneNumberTo);
		vRecord.DateFrom			= CurrentSessionDate();
		vRecord.DateTo				= "";
		vRecord.Duration			= 0;
		vRecord.Route				= 0;
		vRecord.File				= "";
		vRecord.Client				= vData.Client;
		vRecord.Customer			= vData.Customer;
		vRecord.Room				= vData.Room;
		vRecord.User 				= vUser;
		vRecord.Workstation 		= SessionParameters.CurrentWorkstation;
		vRecord.Hotel				= SessionParameters.CurrentHotel;
		vRecord.Missed 				= pMissed;
		vRecord.Write();
	EndIf;
EndProcedure // SaveCall	

// -----------------------------------------------------------------------------
// Description: GetRepresentationNumber
// Parameters:  pPhoneNumber, pRegion, pCityMobile
// Return value: None
Procedure GetRepresentationNumber(pPhoneNumber, pRegion = "", pCityMobile = "") Export
	
	vCityCodes		= tcSimpleCallsOnServer.GetCityCodes();
	vMobileCodes	= tcSimpleCallsOnServer.GetMobileCodes();
	
	vPresPhone = "";
	
	pCityMobile = Nstr("en = 'City'; ru = 'Городской'; de = 'City'");
	
	vPhoneAsNumber = GetNumberStr(pPhoneNumber);
	
	If StrLen(vPhoneAsNumber) >= 10 Then
		
		vCountryCode = "";
		If StrLen(vPhoneAsNumber) > 10 Then
			vCountryCode = Left(vPhoneAsNumber, StrLen(vPhoneAsNumber) - 10);
		Else
			vCountryCode = String(SessionParameters.CurrentHotel.Citizenship.CountryPhoneCode);
		EndIf;
			
		vPhoneWithCode = Right(vPhoneAsNumber, 10);
		
		If Left(vPhoneWithCode, 1) = "9" Then
			
			pCityMobile = Nstr("en = 'Mobile'; ru = 'Мобильный'; de = 'Handy'");
			
			vOperatorCode = Left(vPhoneWithCode, 3);
			vOperatorNumber = Mid(vPhoneWithCode, 4);
			
			vFilter = New Structure;
			vFilter.Insert("OperatorCode", vOperatorCode);
			
			vTab = vMobileCodes.Copy(vFilter);
			For Each vStr In vTab Do
				
				If vOperatorNumber >= vStr.PhoneNumberFrom И vOperatorNumber <= vStr.PhoneNumberTo Then
					
					pRegion = vStr.Region;
					Break;
				EndIf;
			EndDo;
			
			vPresPhone = TrimAll(vCountryCode + " (" + vOperatorCode + ") " + Left(vOperatorNumber, 3) + "-" + Mid(vOperatorNumber, 4, 2) + "-" + Right(vOperatorNumber, 2));
		Else
			vCityCode		= "";
			vPhoneIntoCity	= "";
			
			vFoundCityCode = False;
			
			For vInt = 1 To 6 Do
				
				vStrLenCodes = 8 - vInt;
				
				vCityCode = Left(vPhoneWithCode, vStrLenCodes);
				
				vFindStr = vCityCodes.Find(vCityCode, "CityCode");
				If Not vFindStr = Undefined Then
					
					vPhoneIntoCity	= Mid(vPhoneWithCode, vStrLenCodes + 1);
					pRegion	= vFindStr.City;
					
					vFoundCityCode = True;
					Break;
				EndIf;
			EndDo;
			
			If vFoundCityCode Then
				
				If StrLen(vCityCode) > 5 Then
					vPresPhone = "(" + vCityCode + ") " + TrimAll(vPhoneIntoCity);
				ElsIf  StrLen(vCityCode) = 5 Then
					vPresPhone = "(" + vCityCode + ") " + Left(vPhoneIntoCity, 1) + "-" + Mid(vPhoneIntoCity, 2, 2) + "-" + Right(vPhoneIntoCity, 2);
				ElsIf  StrLen(vCityCode) = 4 Then
					vPresPhone = "(" + vCityCode + ") " + Left(vPhoneIntoCity, 2) + "-" + Mid(vPhoneIntoCity, 3, 2) + "-" + Right(vPhoneIntoCity, 2);
				ElsIf  StrLen(vCityCode) = 3 Then
					vPresPhone = "(" + vCityCode + ") " + Left(vPhoneIntoCity, 3) + "-" + Mid(vPhoneIntoCity, 4, 2) + "-" + Right(vPhoneIntoCity, 2);
				ElsIf  StrLen(vCityCode) = 2 Then
					vPresPhone = "(" + vCityCode + ") " + Left(vPhoneIntoCity, 3) + "-" + Mid(vPhoneIntoCity, 4, 3) + "-" + Right(vPhoneIntoCity, 2);
				EndIf;
				
				vPresPhone = TrimAll(vCountryCode + " " + vPresPhone);
			Else
				vPresPhone = "";
			EndIf;
		EndIf;
	EndIf;
	
	If vPresPhone = "" Then
		vPresPhone = pPhoneNumber;
	Else 
		pPhoneNumber = vPresPhone;
	EndIf;
EndProcedure  // GetRepresentationNumber

#EndRegion
      