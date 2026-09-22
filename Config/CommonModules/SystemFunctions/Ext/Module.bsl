
#Region Public

// -----------------------------------------------------------------------------
// Description: Returns temp file name 
// Parameters: Temp file extension
// Return value: Name of temp file that could be used
// -----------------------------------------------------------------------------
Function cmGetTempFileName(pExt) Export
	vTmpFileName = GetTempFileName(pExt);
	If Find(vTmpFileName, "\") > 0 Then
		vTmpFileName = StrReplace(vTmpFileName, "/", "\");
	EndIf;
	Return vTmpFileName;
EndFunction // cmGetTempFileName 

// -----------------------------------------------------------------------------
// Description: Returns directory where temp files are created
// Parameters: None
// Return value: Path to the temp files directory
// -----------------------------------------------------------------------------
Function cmTempFilesDir() Export
	vTmpDir = "";
	vTmpFileName = cmGetTempFileName("tmp");
	vTmpFile = New File(vTmpFileName);
	If tcCommonFunctionOnClientServer.cmExists(vTmpFile) Then
		DeleteFiles(vTmpFileName);
	EndIf;
	vTmpFileNameLen = StrLen(vTmpFileName);
	i = vTmpFileNameLen;
	While i > 0 Do
		vChar = Mid(vTmpFileName, i, 1);
		If vChar = "/" Or vChar = "\" Then
			Break;
		Else
			i = i - 1;
		EndIf;
	EndDo;
	If i > 0 Then
		vTmpDir = Left(vTmpFileName, i);
	Else
		vTmpDir = TempFilesDir();
	EndIf;
	Return vTmpDir;
EndFunction // cmTempFilesDir 

// -----------------------------------------------------------------------------
// Description: Returns value list with all workstations
// Parameters: None
// Return value: Value list
// -----------------------------------------------------------------------------
Function cmGetWorkstationsList(pFilterByAllowed = False) Export
	vList = New ValueList();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Workstations.Ref
	|FROM
	|	Catalog.Workstations AS Workstations
	|WHERE
	|	(NOT Workstations.DeletionMark)
	|	AND (NOT Workstations.IsFolder)
	|	AND (NOT &qFilterByAllowed OR &qFilterByAllowed AND NOT Workstations.DoNotShowAtStartup)
	|
	|ORDER BY
	|	Workstations.Description";
	vQry.SetParameter("qFilterByAllowed", pFilterByAllowed);
	
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		vList.Add(vQryResRow.Ref);
	EndDo;
	Return vList;
EndFunction // cmGetWorkstationsList

// -----------------------------------------------------------------------------
// Description: Procedure is used to replace one client with another one in all
//              documents, catalog items, information registers and so on/
// Parameters: Client to use instead of client specified as second parameter
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmMergeClients(pMainClient, pMergedClient) Export
	// Check parameters
	If Not ValueIsFilled(pMainClient) or Not ValueIsFilled(pMergedClient) Then
		Raise NStr("en='Both clients should be filled!';ru='Обе карточки клиентов должны быть указаны!';de='Beide Kundenkarten müssen angegeben sein!'");
	EndIf;
	If Not IsInRole("RightsToMergeCatalogItemsAndChangeHistory") Then
		Raise NStr("en='You do not have rights to merge clients!';ru='Нет прав на эту операцию!';de='Sie haben keine Rechte für diesen Vorgang!'");
	EndIf;
	// Find references to the second parameter client
	vRefsArray = New Array();
	vRefsArray.Add(pMergedClient);
	vRefs = FindByRef(vRefsArray);
	// Do in one transaction
	Try
		BeginTransaction(DataLockControlMode.Managed);
		// Save and clear hotel edit prohibited dates
		vEditProhibitedDates = New ValueTable();
		vEditProhibitedDates.Columns.Add("Hotel");
		vEditProhibitedDates.Columns.Add("EditProhibitedDate");
		vHotels = cmGetAllHotels();
		For Each vHotelsRow In vHotels Do
			If ValueIsFilled(vHotelsRow.Hotel.EditProhibitedDate) Then
				vEditProhibitedDatesRow = vEditProhibitedDates.Add();
				vEditProhibitedDatesRow.Hotel = vHotelsRow.Hotel;
				vEditProhibitedDatesRow.EditProhibitedDate = vHotelsRow.Hotel.EditProhibitedDate;
				
				vHotelObj = vHotelsRow.Hotel.GetObject();
				vHotelObj.EditProhibitedDate = '00010101';
				vHotelObj.Write();
			EndIf;
		EndDo;
		// First run (do not repost accommodations and some other documents, just rewrite them)
		For Each vRefsRow In vRefs Do
			vObjRef = vRefsRow.Get(1);
			vObjMetadata = vRefsRow.Get(2);
			If TypeOf(vObjRef) = Type("CatalogRef.CreditCards") Then
				vObj = vObjRef.GetObject();
				vObj.CardOwner = pMainClient;
				vObj.Write();
			ElsIf TypeOf(vObjRef) = Type("CatalogRef.DiscountCards") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write();
			ElsIf TypeOf(vObjRef) = Type("CatalogRef.GuestGroups") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write();
			ElsIf TypeOf(vObjRef) = Type("CatalogRef.IdentificationCards") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write();
			ElsIf TypeOf(vObjRef) = Type("CatalogRef.Employees") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write();
			ElsIf TypeOf(vObjRef) = Type("CatalogRef.HotelProducts") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write();
			ElsIf TypeOf(vObjRef) = Type("CatalogRef.ObjectTemplates") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write();
			ElsIf TypeOf(vObjRef) = Type("CatalogRef.PaymentMethods") Then
				vObj = vObjRef.GetObject();
				vObj.CardOwner = pMainClient;
				vObj.Write();
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Accommodation") Then
				vObj = vObjRef.GetObject();
				vObj.Guest = pMainClient;
				For Each vCRRow In vObj.ChargingRules Do
					If vCRRow.Owner = pMergedClient Then
						vCRRow.Owner = pMainClient;
					EndIf;
				EndDo;
				// Need to be reposted further
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Reservation") Then
				vObj = vObjRef.GetObject();
				vObj.Guest = pMainClient;
				For Each vCRRow In vObj.ChargingRules Do
					If vCRRow.Owner = pMergedClient Then
						vCRRow.Owner = pMainClient;
					EndIf;
				EndDo;
				// Need to be reposted further
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.ClientDataScans") Then
				vObj = vObjRef.GetObject();
				If vObj.Guest = pMergedClient Then
					vObj.Guest = pMainClient;
				EndIf;
				If vObj.LegalRepresentative = pMergedClient Then
					vObj.LegalRepresentative = pMainClient;
				EndIf;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.BonusesOperation") Then
				vObj = vObjRef.GetObject();
				vObj.Guest = pMainClient;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.BonusesPayment") Then
				vObj = vObjRef.GetObject();
				vObj.Guest = pMainClient;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Folio") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.ForeignerRegistryRecord") Then
				vObj = vObjRef.GetObject();
				If vObj.Guest = pMergedClient Then
					vObj.Guest = pMainClient;
				EndIf;
				If vObj.LegalRepresentative = pMergedClient Then
					vObj.LegalRepresentative = pMainClient;
				EndIf;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.ProformaInvoice") Then
				vObj = vObjRef.GetObject();
				For Each vSrvRow In vObj.Services Do
					If vSrvRow.Client = pMergedClient Then
						vSrvRow.Client = pMainClient;
					EndIf;
				EndDo;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.InputAccumulatingDiscountBalances") Then
				vObj = vObjRef.GetObject();
				For Each vBalRow In vObj.Balances Do
					If vBalRow.DiscountDimension = pMergedClient Then
						vBalRow.DiscountDimension = pMainClient;
					EndIf;
				EndDo;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.IssueHotelProducts") Then
				vObj = vObjRef.GetObject();
				For Each vSrvRow In vObj.HotelProducts Do
					If vSrvRow.Client = pMergedClient Then
						vSrvRow.Client = pMainClient;
					EndIf;
				EndDo;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Message") Then
				vObj = vObjRef.GetObject();
				If vObj.ByObject = pMergedClient Then
					vObj.ByObject = pMainClient;
					If vObj.Posted Then
						vObj.Write(DocumentWriteMode.Posting);
					Else
						vObj.Write(DocumentWriteMode.Write);
					EndIf;
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Order") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.OperationSchedule") Then
				vObj = vObjRef.GetObject();
				For Each vOprRow In vObj.Operations Do
					If vOprRow.Guest = pMergedClient Then
						vOprRow.Guest = pMainClient;
					EndIf;
				EndDo;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Payment") Then
				vObj = vObjRef.GetObject();
				vObj.Payer = pMainClient;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Preauthorisation") Then
				vObj = vObjRef.GetObject();
				vObj.Payer = pMainClient;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.RecordRoomService") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				// Need to be reposted further
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.ResourceReservation") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				// Need to be reposted further
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Return") Then
				vObj = vObjRef.GetObject();
				vObj.Payer = pMainClient;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.ServiceRegistration") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Settlement") Then
				vObj = vObjRef.GetObject();
				For Each vSrvRow In vObj.Services Do
					If vSrvRow.Client = pMergedClient Then
						vSrvRow.Client = pMainClient;
					EndIf;
				EndDo;
				// Need to be reposted further
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.CreditNote") Then
				vObj = vObjRef.GetObject();
				For Each vSrvRow In vObj.Services Do
					If vSrvRow.Client = pMergedClient Then
						vSrvRow.Client = pMainClient;
					EndIf;
				EndDo;
				// Need to be reposted further
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.DebitNote") Then
				vObj = vObjRef.GetObject();
				For Each vSrvRow In vObj.Services Do
					If vSrvRow.Client = pMergedClient Then
						vSrvRow.Client = pMainClient;
					EndIf;
				EndDo;
				// Need to be reposted further
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Charge") Then
				vObj = vObjRef.GetObject();
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Storno") Then
				vObj = vObjRef.GetObject();
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.DepositTransfer") Then
				vObj = vObjRef.GetObject();
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.ClientChangeHistory") Then
				vMgr = InformationRegisters.ClientChangeHistory.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Delete();
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.AccommodationChangeHistory") Then
				vMgr = InformationRegisters.AccommodationChangeHistory.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Guest = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.SMSDelivery") Then
				vObj = vObjRef.GetObject();
				For Each vRcvRow In vObj.Receivers Do
					If vRcvRow.Client = pMergedClient Then
						vRcvRow.Client = pMainClient;
					EndIf;
				EndDo;
				If vObj.Posted Then
					vObj.Write(DocumentWriteMode.Posting);
				Else
					vObj.Write(DocumentWriteMode.Write);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.ReservationChangeHistory") Then
				vMgr = InformationRegisters.ReservationChangeHistory.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Guest = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.ForeignerRegistryRecordChangeHistory") Then
				vMgr = InformationRegisters.ForeignerRegistryRecordChangeHistory.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Guest = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.ResourceReservationChangeHistory") Then
				vMgr = InformationRegisters.ResourceReservationChangeHistory.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Client = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.LostAndFound") Then
				vMgr = InformationRegisters.LostAndFound.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Guest = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.ClientsInformation") Then
				vMgr = InformationRegisters.ClientsInformation.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Client = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.ClientSocialNetworkLogins") Then
				vMgr = InformationRegisters.ClientSocialNetworkLogins.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Client = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.ClientVerificationCodes") Then
				vMgr = InformationRegisters.ClientVerificationCodes.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Client = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.GuestGroupAttachments") Then
				vMgr = InformationRegisters.GuestGroupAttachments.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Client = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.HistorySimpleCalls") Then
				vMgr = InformationRegisters.GuestGroupAttachments.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Client = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.ExternalSystemIntegrationData") Then
				vMgr = InformationRegisters.ExternalSystemIntegrationData.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					If vMgr.RefKey1 = pMergedClient Then
						vMgr.RefKey1 = pMainClient;
					EndIf;
					If vMgr.RefKey2 = pMergedClient Then
						vMgr.RefKey2 = pMainClient;
					EndIf;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.Messages") Then
				vMgr = InformationRegisters.Messages.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Object = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.LimitsAndSpecialConditions") Then
				vMgr = InformationRegisters.LimitsAndSpecialConditions.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Owner = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.SafetySystemEvents") Then
				vMgr = InformationRegisters.SafetySystemEvents.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Guest = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.SMSDelivery") Then
				vObj = vObjRef.GetObject();
				vRows = vObj.Receivers.FindRows(New Structure("Client", pMergedClient));
				For Each vRcvRow In vRows Do
					If vRcvRow.Client = pMergedClient Then
						vRcvRow.Client = pMainClient;
					EndIf;
				EndDo;
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.CloseOfCashRegisterDay") Then
				// Repost document at second step
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.CloseOfPeriod") Then
				// Repost document at second step
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.SafetySystemEvents") Then
				vMgr = InformationRegisters.SafetySystemEvents.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Guest = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("CatalogRef.Customers") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write();
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.SMSMessages") Then
				vMgr = InformationRegisters.SMSMessages.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Client = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.CustomerChangeHistory") Then
				vMgr = InformationRegisters.CustomerChangeHistory.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Client = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.ClientTags") Then
				vMgr = InformationRegisters.ClientTags.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Client = pMainClient;
					vMgr.Write(True);
				EndIf;   
			ElsIf TypeOf(vObjRef) = Type("InformationRegisterRecordKey.GuestsExportedToUMMS") Then
				vMgr = InformationRegisters.GuestsExportedToUMMS.CreateRecordManager();
				FillPropertyValues(vMgr, vObjRef);
				vMgr.Read();
				If vMgr.Selected() Then
					vMgr.Guest = pMainClient;
					vMgr.Write(True);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.CurrencyConversion") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.PersonalDataProcessingConsent") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.PersonalDataProcessingRefusal") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write(DocumentWriteMode.Write);
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.ClientFeedback") Then
				vObj = vObjRef.GetObject();
				vObj.Client = pMainClient;
				vObj.Write(DocumentWriteMode.Write);
			Else
				Raise NStr("en='No processing routine is defined for type ';ru='Не определен алгоритм обработки для типа ';de='Der Bearbeitungsalgorithmus für den Typ ist nicht festgelegt - '") + TrimAll(vObjRef) + "!";
			EndIf;
		EndDo;
		// Second run when we have to repost some documents
		For Each vRefsRow In vRefs Do
			vObjRef = vRefsRow.Get(1);
			vObjMetadata = vRefsRow.Get(2);
			If TypeOf(vObjRef) = Type("DocumentRef.Accommodation") Then
				If vObjRef.Posted Then
					vObj = vObjRef.GetObject();
					vObj.Write(DocumentWriteMode.Posting);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Reservation") Then
				If vObjRef.Posted Then
					vObj = vObjRef.GetObject();
					vObj.Write(DocumentWriteMode.Posting);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.RecordRoomService") Then
				If vObjRef.Posted Then
					vObj = vObjRef.GetObject();
					vObj.Write(DocumentWriteMode.Posting);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.ResourceReservation") Then
				If vObjRef.Posted Then
					vObj = vObjRef.GetObject();
					vObj.Write(DocumentWriteMode.Posting);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.Settlement") Then
				If vObjRef.Posted Then
					vObj = vObjRef.GetObject();
					vObj.Write(DocumentWriteMode.Posting);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.CreditNote") Then
				If vObjRef.Posted Then
					vObj = vObjRef.GetObject();
					vObj.Write(DocumentWriteMode.Posting);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.DebitNote") Then
				If vObjRef.Posted Then
					vObj = vObjRef.GetObject();
					vObj.Write(DocumentWriteMode.Posting);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.CloseOfCashRegisterDay") Then
				If vObjRef.Posted Then
					vObj = vObjRef.GetObject();
					vObj.Write(DocumentWriteMode.Posting);
				EndIf;
			ElsIf TypeOf(vObjRef) = Type("DocumentRef.CloseOfPeriod") Then
				If vObjRef.Posted Then
					vObj = vObjRef.GetObject();
					vObj.Write(DocumentWriteMode.Posting);
				EndIf;
			EndIf;
		EndDo;
		// Check references again
		vRefs = FindByRef(vRefsArray);
		If vRefs.Count() = 0 Then
			// Delete client if nothing is found
			pMergedClient.GetObject().Delete();
			pMergedClient = Undefined;
		Else
			Raise NStr("en='Failed to process all references to the client ';ru='Не удалось обработать все ссылки на клиента ';de='Es konnten nicht alle Links zum Kunden bearbeitet werden - '") + TrimAll(pMergedClient.FullName) + " (" + TrimAll(pMergedClient.Code) + ")!";
		EndIf;
		// Restore edit prohibited dates
		For Each vEditProhibitedDatesRow In vEditProhibitedDates Do
			vHotelObj = vEditProhibitedDatesRow.Hotel.GetObject();
			vHotelObj.EditProhibitedDate = vEditProhibitedDatesRow.EditProhibitedDate;
			vHotelObj.Write();
		EndDo;
		// Commit transaction		
		CommitTransaction();
	Except
		vErrorText = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Raise vErrorText;
	EndTry;
EndProcedure // cmMergeClients 

// -----------------------------------------------------------------------------
// Description: Function is used to replace and return web color with its RGB 
//              equivalent
// Parameters: Color object of type WebColor
// Return value: RGB Color
// -----------------------------------------------------------------------------
Function cmGetRGB4WebColor(pWebColor) Export
	If pWebColor = WebColors.AliceBlue Then
		Return New Color(240, 248, 255);
	ElsIf pWebColor = WebColors.AntiqueWhite Then
		Return New Color(250, 235, 215);
	ElsIf pWebColor = WebColors.Aqua Then
		Return New Color(0, 255, 255);
	ElsIf pWebColor = WebColors.Aquamarine Then
		Return New Color(127, 255, 212);
	ElsIf pWebColor = WebColors.Azure Then
		Return New Color(240, 255, 255);
	ElsIf pWebColor = WebColors.Beige Then
		Return New Color(245, 245, 220);
	ElsIf pWebColor = WebColors.Bisque Then
		Return New Color(255, 228, 196);
	ElsIf pWebColor = WebColors.Black Then
		Return New Color(0, 0, 0);
	ElsIf pWebColor = WebColors.BlanchedAlmond Then
		Return New Color(255, 235, 205);
	ElsIf pWebColor = WebColors.Blue Then
		Return New Color(0, 0, 255);
	ElsIf pWebColor = WebColors.BlueViolet Then
		Return New Color(138, 43, 226);
	ElsIf pWebColor = WebColors.Brown Then
		Return New Color(165, 42, 42);
	ElsIf pWebColor = WebColors.BurlyWood Then
		Return New Color(222, 184, 135);
	ElsIf pWebColor = WebColors.CadetBlue Then
		Return New Color(95, 158, 160);
	ElsIf pWebColor = WebColors.Chartreuse Then
		Return New Color(127, 255, 0);
	ElsIf pWebColor = WebColors.Chocolate Then
		Return New Color(210, 105, 30);
	ElsIf pWebColor = WebColors.Coral Then
		Return New Color(255, 127, 80);
	ElsIf pWebColor = WebColors.CornFlowerBlue Then
		Return New Color(100, 149, 237);
	ElsIf pWebColor = WebColors.CornSilk Then
		Return New Color(255, 248, 220);
	ElsIf pWebColor = WebColors.Cream Then
		Return New Color(255, 251, 240);
	ElsIf pWebColor = WebColors.Crimson Then
		Return New Color(220, 20, 60);
	ElsIf pWebColor = WebColors.Cyan Then
		Return New Color(0, 255, 255);
	ElsIf pWebColor = WebColors.DarkBlue Then
		Return New Color(0, 0, 139);
	ElsIf pWebColor = WebColors.DarkCyan Then
		Return New Color(0, 139, 139);
	ElsIf pWebColor = WebColors.DarkGoldenRod Then
		Return New Color(184, 134, 11);
	ElsIf pWebColor = WebColors.DarkGray Then
		Return New Color(169, 169, 169);
	ElsIf pWebColor = WebColors.DarkGreen Then
		Return New Color(0, 100, 0);
	ElsIf pWebColor = WebColors.DarkKhaki Then
		Return New Color(189, 183, 107);
	ElsIf pWebColor = WebColors.DarkMagenta Then
		Return New Color(139, 0, 139);
	ElsIf pWebColor = WebColors.DarkOliveGreen Then
		Return New Color(85, 107, 47);
	ElsIf pWebColor = WebColors.DarkOrange Then
		Return New Color(255, 140, 0);
	ElsIf pWebColor = WebColors.DarkOrchid Then
		Return New Color(153, 50, 204);
	ElsIf pWebColor = WebColors.DarkRed Then
		Return New Color(139, 0, 0);
	ElsIf pWebColor = WebColors.DarkSalmon Then
		Return New Color(233, 150, 122);
	ElsIf pWebColor = WebColors.DarkSeaGreen Then
		Return New Color(143, 188, 139);
	ElsIf pWebColor = WebColors.DarkSlateBlue Then
		Return New Color(72, 61, 139);
	ElsIf pWebColor = WebColors.DarkSlateGray Then
		Return New Color(47, 79, 79);
	ElsIf pWebColor = WebColors.DarkTurquoise Then
		Return New Color(0, 206, 209);
	ElsIf pWebColor = WebColors.DarkViolet Then
		Return New Color(148, 0, 211);
	ElsIf pWebColor = WebColors.DeepPink Then
		Return New Color(255, 20, 147);
	ElsIf pWebColor = WebColors.DeepSkyBlue Then
		Return New Color(0, 191, 255);
	ElsIf pWebColor = WebColors.DimGray Then
		Return New Color(105, 105, 105);
	ElsIf pWebColor = WebColors.DodgerBlue Then
		Return New Color(30, 144, 255);
	ElsIf pWebColor = WebColors.FireBrick Then
		Return New Color(178, 34, 34);
	ElsIf pWebColor = WebColors.FloralWhite Then
		Return New Color(255, 250, 240);
	ElsIf pWebColor = WebColors.ForestGreen Then
		Return New Color(34, 139, 34);
	ElsIf pWebColor = WebColors.Fuchsia Then
		Return New Color(255, 0, 255);
	ElsIf pWebColor = WebColors.Gainsboro Then
		Return New Color(220, 220, 220);
	ElsIf pWebColor = WebColors.GhostWhite Then
		Return New Color(248, 248, 255);
	ElsIf pWebColor = WebColors.Gold Then
		Return New Color(255, 215, 0);
	ElsIf pWebColor = WebColors.Goldenrod Then
		Return New Color(218, 165, 32);
	ElsIf pWebColor = WebColors.Gray Then
		Return New Color(128, 128, 128);
	ElsIf pWebColor = WebColors.Green Then
		Return New Color(0, 128, 0);
	ElsIf pWebColor = WebColors.GreenYellow Then
		Return New Color(173, 255, 47);
	ElsIf pWebColor = WebColors.HoneyDew Then
		Return New Color(240, 255, 240);
	ElsIf pWebColor = WebColors.HotPink Then
		Return New Color(255, 105, 180);
	ElsIf pWebColor = WebColors.IndianRed Then
		Return New Color(205, 92, 92);
	ElsIf pWebColor = WebColors.Indigo Then
		Return New Color(75, 0, 130);
	ElsIf pWebColor = WebColors.Ivory Then
		Return New Color(255, 255, 240);
	ElsIf pWebColor = WebColors.Khaki Then
		Return New Color(240, 230, 140);
	ElsIf pWebColor = WebColors.Lavender Then
		Return New Color(230, 230, 250);
	ElsIf pWebColor = WebColors.LavenderBlush Then
		Return New Color(255, 240, 245);
	ElsIf pWebColor = WebColors.LawnGreen Then
		Return New Color(124, 252, 0);
	ElsIf pWebColor = WebColors.LemonChiffon Then
		Return New Color(255, 250, 205);
	ElsIf pWebColor = WebColors.LightBlue Then
		Return New Color(166, 202, 240);
	ElsIf pWebColor = WebColors.LightCoral Then
		Return New Color(240, 128, 128);
	ElsIf pWebColor = WebColors.LightCyan Then
		Return New Color(224, 255, 255);
	ElsIf pWebColor = WebColors.LightGoldenRod Then
		Return New Color(255, 236, 139);
	ElsIf pWebColor = WebColors.LightGoldenRodYellow Then
		Return New Color(250, 250, 210);
	ElsIf pWebColor = WebColors.LightGray Then
		Return New Color(192, 192, 192);
	ElsIf pWebColor = WebColors.LightGreen Then
		Return New Color(144, 238, 144);
	ElsIf pWebColor = WebColors.LightPink Then
		Return New Color(255, 182, 193);
	ElsIf pWebColor = WebColors.LightSalmon Then
		Return New Color(255, 160, 122);
	ElsIf pWebColor = WebColors.LightSeaGreen Then
		Return New Color(32, 178, 170);
	ElsIf pWebColor = WebColors.LightSkyBlue Then
		Return New Color(135, 206, 250);
	ElsIf pWebColor = WebColors.LightSlateBlue Then
		Return New Color(132, 112, 255);
	ElsIf pWebColor = WebColors.LightSlateGray Then
		Return New Color(119, 136, 153);
	ElsIf pWebColor = WebColors.LightSteelBlue Then
		Return New Color(176, 196, 222);
	ElsIf pWebColor = WebColors.LightYellow Then
		Return New Color(255, 255, 224);
	ElsIf pWebColor = WebColors.Lime Then
		Return New Color(0, 255, 0);
	ElsIf pWebColor = WebColors.LimeGreen Then
		Return New Color(50, 205, 50);
	ElsIf pWebColor = WebColors.Linen Then
		Return New Color(250, 240, 230);
	ElsIf pWebColor = WebColors.Magenta Then
		Return New Color(255, 0, 255);
	ElsIf pWebColor = WebColors.Maroon Then
		Return New Color(128, 0, 0);
	ElsIf pWebColor = WebColors.MediumAquaMarine Then
		Return New Color(102, 205, 170);
	ElsIf pWebColor = WebColors.MediumBlue Then
		Return New Color(0, 0, 205);
	ElsIf pWebColor = WebColors.MediumGray Then
		Return New Color(160, 160, 164);
	ElsIf pWebColor = WebColors.MediumGreen Then
		Return New Color(192, 220, 192);
	ElsIf pWebColor = WebColors.MediumOrchid Then
		Return New Color(186, 85, 211);
	ElsIf pWebColor = WebColors.MediumPurple Then
		Return New Color(147, 112, 219);
	ElsIf pWebColor = WebColors.MediumSeaGreen Then
		Return New Color(60, 179, 113);
	ElsIf pWebColor = WebColors.MediumSlateBlue Then
		Return New Color(123, 104, 238);
	ElsIf pWebColor = WebColors.MediumSpringGreen Then
		Return New Color(0, 250, 154);
	ElsIf pWebColor = WebColors.MediumTurquoise Then
		Return New Color(72, 209, 204);
	ElsIf pWebColor = WebColors.MediumVioletRed Then
		Return New Color(199, 21, 133);
	ElsIf pWebColor = WebColors.MidnightBlue Then
		Return New Color(25, 25, 112);
	ElsIf pWebColor = WebColors.MintCream Then
		Return New Color(245, 255, 250);
	ElsIf pWebColor = WebColors.MistyRose Then
		Return New Color(255, 228, 225);
	ElsIf pWebColor = WebColors.Moccasin Then
		Return New Color(255, 228, 181);
	ElsIf pWebColor = WebColors.NavajoWhite Then
		Return New Color(255, 222, 173);
	ElsIf pWebColor = WebColors.Navy Then
		Return New Color(0, 0, 128);
	ElsIf pWebColor = WebColors.OldLace Then
		Return New Color(253, 245, 230);
	ElsIf pWebColor = WebColors.Olive Then
		Return New Color(128, 128, 0);
	ElsIf pWebColor = WebColors.Olivedrab Then
		Return New Color(107, 142, 35);
	ElsIf pWebColor = WebColors.Orange Then
		Return New Color(255, 165, 0);
	ElsIf pWebColor = WebColors.OrangeRed Then
		Return New Color(255, 69, 0);
	ElsIf pWebColor = WebColors.Orchid Then
		Return New Color(218, 112, 214);
	ElsIf pWebColor = WebColors.PaleGoldenrod Then
		Return New Color(238, 232, 170);
	ElsIf pWebColor = WebColors.PaleGreen Then
		Return New Color(152, 251, 152);
	ElsIf pWebColor = WebColors.PaleTurquoise Then
		Return New Color(175, 238, 238);
	ElsIf pWebColor = WebColors.PaleVioletRed Then
		Return New Color(219, 112, 147);
	ElsIf pWebColor = WebColors.PapayaWhip Then
		Return New Color(255, 239, 213);
	ElsIf pWebColor = WebColors.PeachPuff Then
		Return New Color(255, 218, 185);
	ElsIf pWebColor = WebColors.Peru Then
		Return New Color(205, 133, 63);
	ElsIf pWebColor = WebColors.Pink Then
		Return New Color(255, 192, 203);
	ElsIf pWebColor = WebColors.Plum Then
		Return New Color(221, 160, 221);
	ElsIf pWebColor = WebColors.PowderBlue Then
		Return New Color(176, 224, 230);
	ElsIf pWebColor = WebColors.Purple Then
		Return New Color(128, 0, 128);
	ElsIf pWebColor = WebColors.Red Then
		Return New Color(255, 0, 0);
	ElsIf pWebColor = WebColors.RosyBrown Then
		Return New Color(188, 143, 143);
	ElsIf pWebColor = WebColors.RoyalBlue Then
		Return New Color(65, 105, 225);
	ElsIf pWebColor = WebColors.SaddleBrown Then
		Return New Color(139, 69, 19);
	ElsIf pWebColor = WebColors.Salmon Then
		Return New Color(250, 128, 114);
	ElsIf pWebColor = WebColors.SandyBrown Then
		Return New Color(244, 164, 96);
	ElsIf pWebColor = WebColors.Seagreen Then
		Return New Color(46, 139, 87);
	ElsIf pWebColor = WebColors.SeaShell Then
		Return New Color(255, 245, 238);
	ElsIf pWebColor = WebColors.Sienna Then
		Return New Color(160, 82, 45);
	ElsIf pWebColor = WebColors.Silver Then
		Return New Color(192, 192, 192);
	ElsIf pWebColor = WebColors.SkyBlue Then
		Return New Color(135, 206, 235);
	ElsIf pWebColor = WebColors.SlateBlue Then
		Return New Color(106, 90, 205);
	ElsIf pWebColor = WebColors.SlateGray Then
		Return New Color(112, 128, 144);
	ElsIf pWebColor = WebColors.Snow Then
		Return New Color(255, 250, 250);
	ElsIf pWebColor = WebColors.SpringGreen Then
		Return New Color(0, 255, 127);
	ElsIf pWebColor = WebColors.SteelBlue Then
		Return New Color(70, 130, 180);
	ElsIf pWebColor = WebColors.Tan Then
		Return New Color(210, 180, 140);
	ElsIf pWebColor = WebColors.Teal Then
		Return New Color(0, 128, 128);
	ElsIf pWebColor = WebColors.Thistle Then
		Return New Color(216, 191, 216);
	ElsIf pWebColor = WebColors.Tomato Then
		Return New Color(255, 99, 71);
	ElsIf pWebColor = WebColors.Turquoise Then
		Return New Color(64, 224, 208);
	ElsIf pWebColor = WebColors.Violet Then
		Return New Color(238, 130, 238);
	ElsIf pWebColor = WebColors.VioletRed Then
		Return New Color(208, 32, 144);
	ElsIf pWebColor = WebColors.Wheat Then
		Return New Color(245, 222, 179);
	ElsIf pWebColor = WebColors.White Then
		Return New Color(255, 255, 255);
	ElsIf pWebColor = WebColors.WhiteSmoke Then
		Return New Color(245, 245, 245);
	ElsIf pWebColor = WebColors.Yellow Then
		Return New Color(255, 255, 0);
	ElsIf pWebColor = WebColors.YellowGreen Then
		Return New Color(154, 205, 50);
	EndIf;
	Return pWebColor;
EndFunction // cmGetRGB4WebColor

// -----------------------------------------------------------------------------
// Description: Function compares 2 objects and returns comparison result as 
//              human readable text
// Parameters: 2 objects to be compared
// Return value: String, comparison result
// -----------------------------------------------------------------------------
Function cmGetObjectChanges(pObj) Export
	vChanges = "";
	vAttributesToSkip = "SortCode";
	// Get previous object state
	vPrevStateRec = pObj.pmGetPreviousObjectState('39991231235959');
	If vPrevStateRec = Undefined Then
		vChanges = NStr("en='<New>';ru='<Новый>';de='<Neu>'");
		Return vChanges;
	EndIf;
	vPrevObj = Undefined;
	If TypeOf(pObj) = Type("DocumentObject.Accommodation") Then
		vPrevObj = Documents.Accommodation.CreateDocument();
	ElsIf TypeOf(pObj) = Type("DocumentObject.Reservation") Then
		vPrevObj = Documents.Reservation.CreateDocument();
	ElsIf TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
		vPrevObj = Documents.ResourceReservation.CreateDocument();
	ElsIf TypeOf(pObj) = Type("DocumentObject.ForeignerRegistryRecord") Then
		vPrevObj = Documents.ForeignerRegistryRecord.CreateDocument();
	ElsIf TypeOf(pObj) = Type("DocumentObject.SetRoomRatePrices") Then
		vPrevObj = Documents.SetRoomRatePrices.CreateDocument();
	ElsIf TypeOf(pObj) = Type("DocumentObject.SetRoomRateFormulas") Then
		vPrevObj = Documents.SetRoomRateFormulas.CreateDocument();
	ElsIf TypeOf(pObj) = Type("DocumentObject.SetPriceTagRanges") Then
		vPrevObj = Documents.SetPriceTagRanges.CreateDocument();
	ElsIf TypeOf(pObj) = Type("CatalogObject.Clients") Then
		vPrevObj = Catalogs.Clients.CreateItem();
	ElsIf TypeOf(pObj) = Type("CatalogObject.Customers") Then
		vPrevObj = Catalogs.Customers.CreateItem();
	ElsIf TypeOf(pObj) = Type("CatalogObject.Contracts") Then
		vPrevObj = Catalogs.Contracts.CreateItem();
	ElsIf TypeOf(pObj) = Type("CatalogObject.RoomRates") Then
		vPrevObj = Catalogs.RoomRates.CreateItem();
	EndIf;
	If vPrevObj = Undefined Then
		Raise NStr("en='Object changes calculation algorithm is missing for type: ';ru='Не определен алгоритм получения изменений объекта с типом: ';de='Der Algorithmus für die Einholung von Änderungen am Objekt des Typs ist nicht festgelegt: '") + String(TypeOf(pObj));
	EndIf;	
	vPrevObj.pmRestoreAttributesFromHistory(vPrevStateRec);
	// Get object metadata
	vObjMetadata = pObj.Metadata();
	// Compare code and description for catalog items
	If TypeOf(pObj) = Type("CatalogObject.Clients") Or
	   TypeOf(pObj) = Type("CatalogObject.RoomRates") Or 
	   TypeOf(pObj) = Type("CatalogObject.Customers") Or 
	   TypeOf(pObj) = Type("CatalogObject.Contracts") Then
		If pObj.Code <> vPrevObj.Code Then
			vChanges = vChanges + NStr("en='Code';ru='Код';de='Code'") + ": " + TrimAll(vPrevObj.Code) + " -> " + TrimAll(pObj.Code) + Chars.LF + Chars.LF;
		EndIf;
		If pObj.Description <> vPrevObj.Description Then
			vChanges = vChanges + NStr("en='Description';ru='Наименование';de='Bezeichnung'") + ": " + TrimAll(vPrevObj.Description) + " -> " + TrimAll(pObj.Description) + Chars.LF + Chars.LF;
		EndIf;
		If pObj.DeletionMark <> vPrevObj.DeletionMark Then
			vChanges = vChanges + NStr("en='Deletion mark';ru='Пометка удаления';de='Löschzeichen'") + ": " + TrimAll(vPrevObj.DeletionMark) + " -> " + TrimAll(pObj.DeletionMark) + Chars.LF + Chars.LF;
		EndIf;
	EndIf;
	// Compare number and date for documents
	If TypeOf(pObj) = Type("DocumentObject.Accommodation") Or
	   TypeOf(pObj) = Type("DocumentObject.Reservation") Or
	   TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Or
	   TypeOf(pObj) = Type("DocumentObject.ForeignerRegistryRecord") Or
	   TypeOf(pObj) = Type("DocumentObject.SetRoomRatePrices") Or
	   TypeOf(pObj) = Type("DocumentObject.SetRoomRateFormulas") Or
	   TypeOf(pObj) = Type("DocumentObject.SetPriceTagRanges") Then
		If pObj.Number <> vPrevObj.Number Then
			vChanges = vChanges + NStr("en='Document number';ru='Номер документа';de='Dokumentnummer'") + ": " + TrimAll(vPrevObj.Number) + " -> " + TrimAll(pObj.Number) + Chars.LF + Chars.LF;
		EndIf;
		If pObj.Date <> vPrevObj.Date Then
			vChanges = vChanges + NStr("en='Document date';ru='Дата документа';de='Datum des Dokuments'") + ": " + Format(vPrevObj.Date, "DF='dd.MM.yyyy HH:mm:ss'") + " -> " + Format(pObj.Date, "DF='dd.MM.yyyy HH:mm:ss'") + Chars.LF + Chars.LF;
		EndIf;
		If pObj.Posted <> vPrevObj.Posted Then
			vChanges = vChanges + NStr("en='Posted';ru='Проведен';de='Posted'") + ": " + TrimAll(vPrevObj.Posted) + " -> " + TrimAll(pObj.Posted) + Chars.LF + Chars.LF;
		EndIf;
		If pObj.DeletionMark <> vPrevObj.DeletionMark Then
			vChanges = vChanges + NStr("en='Deletion mark';ru='Пометка удаления';de='Löschzeichen'") + ": " + TrimAll(vPrevObj.DeletionMark) + " -> " + TrimAll(pObj.DeletionMark) + Chars.LF + Chars.LF;
		EndIf;
	EndIf;
	// Compare attributes
	For Each vAttr In vObjMetadata.Attributes Do
		If Find(vAttributesToSkip, vAttr.Name) = 0 Then
			If TypeOf(pObj[vAttr.Name]) <> Type("ValueStorage") Then
				If pObj[vAttr.Name] <> vPrevObj[vAttr.Name] Then
					vChanges = vChanges + vAttr.Synonym + ": " + TrimAll(String(vPrevObj[vAttr.Name])) + " -> " + TrimAll(String(pObj[vAttr.Name])) + Chars.LF + Chars.LF;
				EndIf;
			ElsIf pObj[vAttr.Name] = Undefined And vPrevObj[vAttr.Name] = Undefined Then
			ElsIf pObj[vAttr.Name] = Undefined And vPrevObj[vAttr.Name] <> Undefined Then
				vChanges = vChanges + vAttr.Synonym + ": " + String(vPrevObj[vAttr.Name]) + " -> " + Chars.LF + Chars.LF;
			ElsIf pObj[vAttr.Name] <> Undefined And vPrevObj[vAttr.Name] = Undefined Then
				vChanges = vChanges + vAttr.Synonym + ": " + " -> " + String(pObj[vAttr.Name]) + Chars.LF + Chars.LF;
			ElsIf pObj[vAttr.Name] <> Undefined And vPrevObj[vAttr.Name] <> Undefined Then
				Try
					vValue = pObj[vAttr.Name].Get();
					vPrevValue = vPrevObj[vAttr.Name].Get();
					If vValue <> vPrevValue Then
						vChanges = vChanges + vAttr.Synonym + ": " + String(vPrevValue) + " -> " + String(vValue) + Chars.LF + Chars.LF;
					EndIf;
				Except
				EndTry;
			EndIf;
		EndIf;
	EndDo;
	// Compare tabular parts
	For Each vTS In vObjMetadata.TabularSections Do 
		vChangesAreFound = False;
		If pObj[vTS.Name].Count() > 0 Then  
			If vTS.Name = "Services" Then
				For Each vTSRow In pObj[vTS.Name] Do
					vTSRowIndex = pObj[vTS.Name].IndexOf(vTSRow);
					vPrevTSRow = Undefined;
					If vTSRowIndex < vPrevObj[vTS.Name].Count() Then
						// Existing row
						vPrevTSRow = vPrevObj[vTS.Name].Get(vTSRowIndex);
						vRowChangesAreFound = False;
						vRowAmountChangesAreFound = False;
						vRowManualAmountChangesAreFound = False;
						For Each vTSAttr In vObjMetadata.TabularSections[vTS.Name].Attributes Do
							If vTSRow[vTSAttr.Name] <> vPrevTSRow[vTSAttr.Name] Then
								vRowChangesAreFound = True;
								If vTSAttr.Name = "Sum" Or vTSAttr.Name = "DiscountSum" Or vTSAttr.Name = "CommissionSum" Or vTSAttr.Name = "VATSum" Then
									vRowAmountChangesAreFound = True;
									If TypeOf(pObj) = Type("DocumentObject.Accommodation") Or
									   TypeOf(pObj) = Type("DocumentObject.Reservation") Or 
									   TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
										If vTSRow.IsManualPrice Or vTSRow.IsManual Then
											vRowManualAmountChangesAreFound = True;
										EndIf;
									Else
										Break;
									EndIf;
								EndIf;
								If vRowAmountChangesAreFound And vRowManualAmountChangesAreFound Then
									Break;
								EndIf;
							EndIf;
						EndDo;
						If vRowChangesAreFound Then
							If Not vChangesAreFound Then
								vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
								vChangesAreFound = True;
								If Not vRowAmountChangesAreFound And pObj[vTS.Name].Count() = vPrevObj[vTS.Name].Count() Then
									vChanges = vChanges + NStr("en='Services parameters have changed! Amounts are the same';ru='Изменились параметры услуг! Суммы не менялись';de='Service-Einstellungen haben sich geändert! Die Beträge änderten sich nicht'") + 
									                      Chars.LF;  
								ElsIf vRowAmountChangesAreFound And Not vRowManualAmountChangesAreFound Then
									vChanges = vChanges + NStr("en='Automatically calculated services have changed!';ru='Изменились автоматически рассчитанные услуги!';de='Die automatisch berechneten Dienste haben sich geändert!'") + 
									                      Chars.LF;  
								EndIf;
								If vRowManualAmountChangesAreFound Then
									vChanges = vChanges + NStr("en='Manually changed services are:';ru='Вручную измененые услуги:';de='Manuell geänderte Dienste sind:'") + 
									                      Chars.LF;  
								EndIf;
							EndIf;
							If TypeOf(pObj) = Type("DocumentObject.Accommodation") Or
							   TypeOf(pObj) = Type("DocumentObject.Reservation") Or 
							   TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then  
								If vRowManualAmountChangesAreFound Then
									If vTSRow.IsManualPrice Or vTSRow.IsManual Then  
										If TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
											vCurrency =  pObj.FolioCurrency;
										Else
											vCurrency =  vTSRow.FolioCurrency;   
										EndIf;
										vChanges = vChanges + NStr("en='Changed service N ';ru='Изменена услуга № ';de='Geändert Dienstleistung Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
										                      Format(vTSRow.AccountingDate, "DF=dd.MM.yyyy") + " - " + 
										                      TrimAll(vTSRow.Service) + ", " + 
															  NStr("en='price '; ru='цена '; de='Preis '") + Format(vTSRow.Price, "NFD=2; NG=") + " x " + 
															  Format(vTSRow.Quantity, "NFD=3; NG=") + " = " + 
															  cmFormatSum(vTSRow.Sum, vCurrency) + 
															  ?(vTSRow.DiscountSum <> 0, " - " + NStr("en='discount '; ru='скидка '; de='Rabatt '") + Format(vTSRow.Discount, "NFD=1; NG=") + "% " + Format(vTSRow.DiscountSum, "NFD=2; NG=") + " = " + 
															  cmFormatSum(vTSRow.Sum - vTSRow.DiscountSum, vCurrency), "") + ", " + 
															  NStr("en='VAT rate '; ru='ставка НДС '; de='Mw.St. '") + TrimAll(vTSRow.VATRate) + 
															  ?(vTSRow.CommissionSum <> 0, ", " + NStr("en='commission '; ru='комиссия '; de='Provision '") + cmFormatSum(vTSRow.CommissionSum, vCurrency) + " (" + vTSRow.AgentCommission + " " + TrimAll(vTSRow.AgentCommissionType) + ")", "") + 
															  Chars.LF;
									EndIf;
								EndIf;
							EndIf;
						EndIf;
					Else // New row
						If Not vChangesAreFound Then
							vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
							vChangesAreFound = True;
							vChanges = vChanges + NStr("en='New service rows were added!';ru='Добавились новые строки услуг!';de='Neue Servicezeilen wurden hinzugefügt!'") + 
							                      Chars.LF;  
						EndIf;
						If TypeOf(pObj) = Type("DocumentObject.Accommodation") Or
						   TypeOf(pObj) = Type("DocumentObject.Reservation") Or 
						   TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
						   If vTSRow.IsManualPrice Or vTSRow.IsManual Then   
							   If TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
								   vCurrency =  pObj.FolioCurrency;
							   Else
								   vCurrency =  vTSRow.FolioCurrency;   
							   EndIf;
								vChanges = vChanges + NStr("en='New manual service N ';ru='Новая ручная услуга № ';de='Neue manuell Dienstleistung Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
								                      Format(vTSRow.AccountingDate, "DF=dd.MM.yyyy") + " - " + 
								                      TrimAll(vTSRow.Service) + ", " + 
													  NStr("en='price '; ru='цена '; de='Preis '") + Format(vTSRow.Price, "NFD=2; NG=") + " x " + 
													  Format(vTSRow.Quantity, "NFD=3; NG=") + " = " + 
													  cmFormatSum(vTSRow.Sum, vCurrency) + 
													  ?(vTSRow.DiscountSum <> 0, " - " + NStr("en='discount '; ru='скидка '; de='Rabatt '") + Format(vTSRow.Discount, "NFD=1; NG=") + "% " + Format(vTSRow.DiscountSum, "NFD=2; NG=") + " = " + 
													  cmFormatSum(vTSRow.Sum - vTSRow.DiscountSum, vCurrency), "") + ", " + 
													  NStr("en='VAT rate '; ru='ставка НДС '; de='Mw.St. '") + TrimAll(vTSRow.VATRate) + 
													  ?(vTSRow.CommissionSum <> 0, ", " + NStr("en='commission '; ru='комиссия '; de='Provision '") + cmFormatSum(vTSRow.CommissionSum, vCurrency) + " (" + vTSRow.AgentCommission + " " + TrimAll(vTSRow.AgentCommissionType) + ")", "") + 
													  Chars.LF;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				// Deleted rows
				For Each vPrevTSRow In vPrevObj[vTS.Name] Do
					vPrevTSRowIndex = vPrevObj[vTS.Name].IndexOf(vPrevTSRow);
					If vPrevTSRowIndex >= pObj[vTS.Name].Count() Then
						If Not vChangesAreFound Then
							vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
							vChangesAreFound = True;
							vChanges = vChanges + NStr("en='Service rows were deleted!';ru='Удалены строки услуг!';de='Dienstzeilen wurden entfernt!'") + 
							                      Chars.LF;  
						EndIf;
						If TypeOf(pObj) = Type("DocumentObject.Accommodation") Or
						   TypeOf(pObj) = Type("DocumentObject.Reservation") Or 
						   TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
						   If vPrevTSRow.IsManualPrice Or vPrevTSRow.IsManual Then     
							   If TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
								   vCurrency =  pObj.FolioCurrency;
							   Else
								   vCurrency =  vTSRow.FolioCurrency;   
							   EndIf;
								vChanges = vChanges + NStr("en='Deleted service N ';ru='Удалена услуга № ';de='Entfernt Dienstleistung Nr. '") + Format(vPrevTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
								                      Format(vPrevTSRow.AccountingDate, "DF=dd.MM.yyyy") + " - " + 
								                      TrimAll(vPrevTSRow.Service) + ", " + 
													  NStr("en='price '; ru='цена '; de='Preis '") + Format(vPrevTSRow.Price, "NFD=2; NG=") + " x " + 
													  Format(vPrevTSRow.Quantity, "NFD=3; NG=") + " = " + 
													  cmFormatSum(vPrevTSRow.Sum, vCurrency) + 
													  ?(vPrevTSRow.DiscountSum <> 0, " - " + NStr("en='discount '; ru='скидка '; de='Rabatt '") + Format(vPrevTSRow.Discount, "NFD=1; NG=") + "% " + Format(vPrevTSRow.DiscountSum, "NFD=2; NG=") + " = " + 
													  cmFormatSum(vPrevTSRow.Sum - vPrevTSRow.DiscountSum, vCurrency), "") + ", " + 
													  NStr("en='VAT rate '; ru='ставка НДС '; de='Mw.St. '") + TrimAll(vPrevTSRow.VATRate) + 
													  ?(vPrevTSRow.CommissionSum <> 0, ", " + NStr("en='commission '; ru='комиссия '; de='Provision '") + cmFormatSum(vPrevTSRow.CommissionSum, vCurrency) + " (" + vPrevTSRow.AgentCommission + " " + TrimAll(vPrevTSRow.AgentCommissionType) + ")", "") + 
													  Chars.LF;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			ElsIf vTS.Name = "ServicePackages" Then
				vChangesAreFound = False;
				For Each vTSRow In pObj[vTS.Name] Do
					vTSRowIndex = pObj[vTS.Name].IndexOf(vTSRow);
					vPrevTSRow = Undefined;
					If vTSRowIndex < vPrevObj[vTS.Name].Count() Then
						// Existing row
						vPrevTSRow = vPrevObj[vTS.Name].Get(vTSRowIndex);
						vRowChangesAreFound = False;
						For Each vTSAttr In vObjMetadata.TabularSections[vTS.Name].Attributes Do
							If vTSRow[vTSAttr.Name] <> vPrevTSRow[vTSAttr.Name] Then
								vRowChangesAreFound = True;
								Break;
							EndIf;
						EndDo;
						If vRowChangesAreFound Then
							If Not vChangesAreFound Then
								vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
								vChangesAreFound = True;
							EndIf;
							If TypeOf(pObj) = Type("DocumentObject.Accommodation") Or
							   TypeOf(pObj) = Type("DocumentObject.Reservation") Or 
							   TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
								vChanges = vChanges + NStr("en='Changed package N ';ru='Изменен пакет № ';de='Geändert Paket Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
								                      TrimAll(vTSRow.ServicePackage) + ", " + 
													  NStr("en='q-ty '; ru='кол-во '; de='Menge '") + Format(vTSRow.Quantity, "NFD=3; NG=") + ", " + 
													  NStr("en='from '; ru='с '; de='von '") + Format(vTSRow.DateFrom, "DF=dd.MM.yyyy") + NStr("en=' to '; ru=' по '; de=' bis '") + Format(vTSRow.DateTo, "DF=dd.MM.yyyy") + 
													  Chars.LF;
							ElsIf TypeOf(pObj) = Type("CatalogObject.RoomRates") Then
								vChanges = vChanges + NStr("en='Changed package N ';ru='Изменен пакет № ';de='Geändert Paket Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
								                      TrimAll(vTSRow.ServicePackage) + ", " +  
													  ?(vTSRow.PacketPriceIsIncludedInRoomRate, NStr("en='is included in room price '; ru='включен в цену '; de='ist im Zimmerpreis inbegriffen '"), "") + 
													  Chars.LF;
							Else						
								vChanges = vChanges + NStr("en='Changed package N ';ru='Изменен пакет № ';de='Geändert Paket Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
								                      TrimAll(vTSRow.ServicePackage) + 
													  Chars.LF;  
							EndIf;
						EndIf;
					Else // New row
						If Not vChangesAreFound Then
							vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
							vChangesAreFound = True;
						EndIf;
						If TypeOf(pObj) = Type("DocumentObject.Accommodation") Or
						   TypeOf(pObj) = Type("DocumentObject.Reservation") Or 
						   TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
							vChanges = vChanges + NStr("en='New package N ';ru='Новый пакет № ';de='Neue Paket Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + ": " + 
							                      TrimAll(vTSRow.ServicePackage) + ", " + 
												  NStr("en='q-ty '; ru='кол-во '; de='Menge '") + Format(vTSRow.Quantity, "NFD=3; NG=") + ", " + 
												  NStr("en='from '; ru='с '; de='von '") + Format(vTSRow.DateFrom, "DF=dd.MM.yyyy") + NStr("en=' to '; ru=' по '; de=' bis '") + Format(vTSRow.DateTo, "DF=dd.MM.yyyy") + 
												  Chars.LF;
						Else
							vChanges = vChanges + NStr("en='New package N ';ru='Новый пакет № ';de='Neue Paket Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + ": " + 
							                      TrimAll(vTSRow.ServicePackage) + 
												  Chars.LF;
						EndIf;
					EndIf;
				EndDo;
				// Deleted rows
				For Each vPrevTSRow In vPrevObj[vTS.Name] Do
					vPrevTSRowIndex = vPrevObj[vTS.Name].IndexOf(vPrevTSRow);
					If vPrevTSRowIndex >= pObj[vTS.Name].Count() Then
						If Not vChangesAreFound Then
							vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
							vChangesAreFound = True;
						EndIf;
						If TypeOf(pObj) = Type("DocumentObject.Accommodation") Or
						   TypeOf(pObj) = Type("DocumentObject.Reservation") Or 
						   TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
							vChanges = vChanges + NStr("en='Deleted package N ';ru='Удален пакет № ';de='Entfernt Paket Nr. '") + Format(vPrevTSRowIndex + 1, "ND=10; NFD=0; NG=") + ": " + 
							                      TrimAll(vPrevTSRow.ServicePackage) + ", " + 
												  NStr("en='q-ty '; ru='кол-во '; de='Menge '") + Format(vPrevTSRow.Quantity, "NFD=3; NG=") + ", " + 
												  NStr("en='from '; ru='с '; de='von '") + Format(vPrevTSRow.DateFrom, "DF=dd.MM.yyyy") + NStr("en=' to '; ru=' по '; de=' bis '") + Format(vPrevTSRow.DateTo, "DF=dd.MM.yyyy") + 
												  Chars.LF;
						Else
							vChanges = vChanges + NStr("en='Deleted package N ';ru='Удален пакет № ';de='Entfernt Paket Nr. '") + Format(vPrevTSRowIndex + 1, "ND=10; NFD=0; NG=") + ": " + 
							                      TrimAll(vPrevTSRow.ServicePackage) + 
												  Chars.LF;
						EndIf;
					EndIf;
				EndDo;
			ElsIf vTS.Name = "RoomRates" And (TypeOf(pObj) = Type("DocumentObject.Accommodation") Or TypeOf(pObj) = Type("DocumentObject.Reservation")) Then
				vChangesAreFound = False;
				For Each vTSRow In pObj[vTS.Name] Do
					vTSRowIndex = pObj[vTS.Name].IndexOf(vTSRow);
					vPrevTSRow = Undefined;
					If vTSRowIndex < vPrevObj[vTS.Name].Count() Then
						// Existing row
						vPrevTSRow = vPrevObj[vTS.Name].Get(vTSRowIndex);
						vRowChangesAreFound = False;
						For Each vTSAttr In vObjMetadata.TabularSections[vTS.Name].Attributes Do
							If vTSRow[vTSAttr.Name] <> vPrevTSRow[vTSAttr.Name] Then
								vRowChangesAreFound = True;
								Break;
							EndIf;
						EndDo;
						If vRowChangesAreFound Then
							If Not vChangesAreFound Then
								vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
								vChangesAreFound = True;
							EndIf;
							vChanges = vChanges + NStr("en='Changed row N ';ru='Изменена строка № ';de='Geändert Reihe Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
							                      Format(vTSRow.AccountingDate + (vTSRow.ChangeTime - BegOfDay(vTSRow.ChangeTime)), "DF='dd.MM.yyyy HH:mm'") + " - " + 
							                      ?(ValueIsFilled(vTSRow.RoomType), NStr("en='room type '; ru='тип номера '; de='Zimmertyp '") + TrimAll(vTSRow.RoomType) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.Room), NStr("en='room '; ru='номер '; de='Zimmer '") + TrimAll(vTSRow.Room) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.AccommodationType), NStr("en='acc. type '; ru='вид размещ. '; de='Unterkunfttyp '") + TrimAll(vTSRow.AccommodationType) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.AccommodationTemplate), NStr("en='persons '; ru='чел. '; de='Personen '") + TrimAll(vTSRow.AccommodationTemplate) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.PriceCalculationDate), NStr("en='price calculation date '; ru='дата получения цен '; de='Preisberechnungdatum '") + Format(vTSRow.PriceCalculationDate, "DF='dd.MM.yyyy HH:mm:ss'") + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.RoomRate), NStr("en='rate '; ru='тариф '; de='Tarif '") + TrimAll(vTSRow.RoomRate) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.ClientType), NStr("en='client type '; ru='тип клиента '; de='Kundetyp '") + TrimAll(vTSRow.ClientType) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.ServicePackage), NStr("en='package '; ru='пакет '; de='Paket '") + TrimAll(vTSRow.ServicePackage) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.Discount), NStr("en='discount '; ru='скидка '; de='Rabatt '") + TrimAll(vTSRow.Discount) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.AgentCommission), NStr("en='agent commission '; ru='комиссия '; de='Provision '") + TrimAll(vTSRow.AgentCommission) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.SourceOfBusiness), NStr("en='source '; ru='источник '; de='Quelle '") + TrimAll(vTSRow.SourceOfBusiness) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.MarketingCode), NStr("en='market '; ru='сегмент '; de='Market '") + TrimAll(vTSRow.MarketingCode) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.BoardPlace), NStr("en='board place '; ru='место питания '; de='Verpflegungort '") + TrimAll(vTSRow.BoardPlace) + ", ", "") + 
							                      ?(vTSRow.DoNotChangeAvailability, NStr("en='do not change availability'; ru='не изменять доступность номеров'; de='Verfügbarkeit von Zimmern nicht ändern'") + ", ", "") + 
							                      ?(vTSRow.IsBookedOut, NStr("en='is booked out'; ru='вне отеля'; de='Außerhalb des Hotels ist'") + ", ", "");
							If Right(vChanges, 2) = ", " Then
								vChanges = Left(vChanges, StrLen(vChanges) - 2);
							EndIf;
							vChanges = vChanges + Chars.LF;
						EndIf;
					Else // New row
						If Not vChangesAreFound Then
							vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
							vChangesAreFound = True;
						EndIf;
						vChanges = vChanges + NStr("en='New row N ';ru='Новая строка № ';de='Neue Reihe Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
						                      Format(vTSRow.AccountingDate + (vTSRow.ChangeTime - BegOfDay(vTSRow.ChangeTime)), "DF='dd.MM.yyyy HH:mm'") + " - " + 
						                      ?(ValueIsFilled(vTSRow.RoomType), NStr("en='room type '; ru='тип номера '; de='Zimmertyp '") + TrimAll(vTSRow.RoomType) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.Room), NStr("en='room '; ru='номер '; de='Zimmer '") + TrimAll(vTSRow.Room) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.AccommodationType), NStr("en='acc. type '; ru='вид размещ. '; de='Unterkunfttyp '") + TrimAll(vTSRow.AccommodationType) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.AccommodationTemplate), NStr("en='persons '; ru='чел. '; de='Personen '") + TrimAll(vTSRow.AccommodationTemplate) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.PriceCalculationDate), NStr("en='price calculation date '; ru='дата получения цен '; de='Preisberechnungdatum '") + Format(vTSRow.PriceCalculationDate, "DF='dd.MM.yyyy HH:mm:ss'") + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.RoomRate), NStr("en='rate '; ru='тариф '; de='Tarif '") + TrimAll(vTSRow.RoomRate) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.ClientType), NStr("en='client type '; ru='тип клиента '; de='Kundetyp '") + TrimAll(vTSRow.ClientType) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.ServicePackage), NStr("en='package '; ru='пакет '; de='Paket '") + TrimAll(vTSRow.ServicePackage) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.Discount), NStr("en='discount '; ru='скидка '; de='Rabatt '") + TrimAll(vTSRow.Discount) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.AgentCommission), NStr("en='agent commission '; ru='комиссия '; de='Provision '") + TrimAll(vTSRow.AgentCommission) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.SourceOfBusiness), NStr("en='source '; ru='источник '; de='Quelle '") + TrimAll(vTSRow.SourceOfBusiness) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.MarketingCode), NStr("en='market '; ru='сегмент '; de='Market '") + TrimAll(vTSRow.MarketingCode) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.BoardPlace), NStr("en='board place '; ru='место питания '; de='Verpflegungort '") + TrimAll(vTSRow.BoardPlace) + ", ", "") + 
						                      ?(vTSRow.DoNotChangeAvailability, NStr("en='do not change availability'; ru='не изменять доступность номеров'; de='Verfügbarkeit von Zimmern nicht ändern'") + ", ", "") + 
						                      ?(vTSRow.IsBookedOut, NStr("en='is booked out'; ru='вне отеля'; de='Außerhalb des Hotels ist'") + ", ", "");
						If Right(vChanges, 2) = ", " Then
							vChanges = Left(vChanges, StrLen(vChanges) - 2);
						EndIf;
						vChanges = vChanges + Chars.LF;
					EndIf;
				EndDo;
				// Deleted rows
				For Each vPrevTSRow In vPrevObj[vTS.Name] Do
					vPrevTSRowIndex = vPrevObj[vTS.Name].IndexOf(vPrevTSRow);
					If vPrevTSRowIndex >= pObj[vTS.Name].Count() Then
						If Not vChangesAreFound Then
							vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
							vChangesAreFound = True;
						EndIf;
						vChanges = vChanges + NStr("en='Deleted row N ';ru='Удалена строка № ';de='Gelöscht Reihe Nr. '") + Format(vPrevTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
						                      Format(vPrevTSRow.AccountingDate + (vPrevTSRow.ChangeTime - BegOfDay(vPrevTSRow.ChangeTime)), "DF='dd.MM.yyyy HH:mm'") + " - " + 
						                      ?(ValueIsFilled(vPrevTSRow.RoomType), NStr("en='room type '; ru='тип номера '; de='Zimmertyp '") + TrimAll(vPrevTSRow.RoomType) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.Room), NStr("en='room '; ru='номер '; de='Zimmer '") + TrimAll(vPrevTSRow.Room) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.AccommodationType), NStr("en='acc. type '; ru='вид размещ. '; de='Unterkunfttyp '") + TrimAll(vPrevTSRow.AccommodationType) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.AccommodationTemplate), NStr("en='persons '; ru='чел. '; de='Personen '") + TrimAll(vPrevTSRow.AccommodationTemplate) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.PriceCalculationDate), NStr("en='price calculation date '; ru='дата получения цен '; de='Preisberechnungdatum '") + Format(vPrevTSRow.PriceCalculationDate, "DF='dd.MM.yyyy HH:mm:ss'") + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.RoomRate), NStr("en='rate '; ru='тариф '; de='Tarif '") + TrimAll(vPrevTSRow.RoomRate) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.ClientType), NStr("en='client type '; ru='тип клиента '; de='Kundetyp '") + TrimAll(vPrevTSRow.ClientType) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.ServicePackage), NStr("en='package '; ru='пакет '; de='Paket '") + TrimAll(vPrevTSRow.ServicePackage) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.Discount), NStr("en='discount '; ru='скидка '; de='Rabatt '") + TrimAll(vPrevTSRow.Discount) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.AgentCommission), NStr("en='agent commission '; ru='комиссия '; de='Provision '") + TrimAll(vPrevTSRow.AgentCommission) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.SourceOfBusiness), NStr("en='source '; ru='источник '; de='Quelle '") + TrimAll(vPrevTSRow.SourceOfBusiness) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.MarketingCode), NStr("en='market '; ru='сегмент '; de='Market '") + TrimAll(vPrevTSRow.MarketingCode) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.BoardPlace), NStr("en='board place '; ru='место питания '; de='Verpflegungort '") + TrimAll(vPrevTSRow.BoardPlace) + ", ", "") + 
						                      ?(vPrevTSRow.DoNotChangeAvailability, NStr("en='do not change availability'; ru='не изменять доступность номеров'; de='Verfügbarkeit von Zimmern nicht ändern'") + ", ", "") + 
						                      ?(vPrevTSRow.IsBookedOut, NStr("en='is booked out'; ru='вне отеля'; de='Außerhalb des Hotels ist'") + ", ", "");
						If Right(vChanges, 2) = ", " Then
							vChanges = Left(vChanges, StrLen(vChanges) - 2);
						EndIf;
						vChanges = vChanges + Chars.LF;
					EndIf;
				EndDo;
			ElsIf vTS.Name = "Prices" And (TypeOf(pObj) = Type("DocumentObject.Accommodation") Or TypeOf(pObj) = Type("DocumentObject.Reservation")) Then
				vChangesAreFound = False;
				For Each vTSRow In pObj[vTS.Name] Do
					vTSRowIndex = pObj[vTS.Name].IndexOf(vTSRow);
					vPrevTSRow = Undefined;
					If vTSRowIndex < vPrevObj[vTS.Name].Count() Then
						// Existing row
						vPrevTSRow = vPrevObj[vTS.Name].Get(vTSRowIndex);
						vRowChangesAreFound = False;
						For Each vTSAttr In vObjMetadata.TabularSections[vTS.Name].Attributes Do
							If vTSRow[vTSAttr.Name] <> vPrevTSRow[vTSAttr.Name] Then
								vRowChangesAreFound = True;
								Break;
							EndIf;
						EndDo;
						If vRowChangesAreFound Then
							If Not vChangesAreFound Then
								vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
								vChangesAreFound = True;
							EndIf;
							vChanges = vChanges + NStr("en='Changed row N ';ru='Изменена строка № ';de='Geändert Reihe Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
							                      NStr("en='Service '; ru='Услуга '; de='Dienstleistung '") + TrimAll(vTSRow.Service) + ", " + 
							                      NStr("en='Price '; ru='Цена '; de='Preis '") + cmFormatSum(vTSRow.Price, vTSRow.Currency) + " " + TrimAll(vTSRow.Unit) + ", " + 
							                      ?(ValueIsFilled(vTSRow.CalendarDayType), NStr("en='day type '; ru='тип дня '; de='Tagetyp '") + TrimAll(vTSRow.CalendarDayType) + ", ", "") + 
							                      ?(ValueIsFilled(vTSRow.Remarks), NStr("en='remarks '; ru='примечания '; de='Beschreibung '") + TrimAll(vTSRow.Remarks), "");
							If Right(vChanges, 2) = ", " Then
								vChanges = Left(vChanges, StrLen(vChanges) - 2);
							EndIf;
							vChanges = vChanges + Chars.LF;
						EndIf;
					Else // New row
						If Not vChangesAreFound Then
							vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
							vChangesAreFound = True;
						EndIf;
						vChanges = vChanges + NStr("en='New row N ';ru='Новая строка № ';de='Neue Reihe Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
						                      NStr("en='Service '; ru='Услуга '; de='Dienstleistung '") + TrimAll(vTSRow.Service) + ", " + 
						                      NStr("en='Price '; ru='Цена '; de='Preis '") + cmFormatSum(vTSRow.Price, vTSRow.Currency) + " " + TrimAll(vTSRow.Unit) + ", " + 
						                      ?(ValueIsFilled(vTSRow.CalendarDayType), NStr("en='day type '; ru='тип дня '; de='Tagetyp '") + TrimAll(vTSRow.CalendarDayType) + ", ", "") + 
						                      ?(ValueIsFilled(vTSRow.Remarks), NStr("en='remarks '; ru='примечания '; de='Beschreibung '") + TrimAll(vTSRow.Remarks), "");
						If Right(vChanges, 2) = ", " Then
							vChanges = Left(vChanges, StrLen(vChanges) - 2);
						EndIf;
						vChanges = vChanges + Chars.LF;
					EndIf;
				EndDo;
				// Deleted rows
				For Each vPrevTSRow In vPrevObj[vTS.Name] Do
					vPrevTSRowIndex = vPrevObj[vTS.Name].IndexOf(vPrevTSRow);
					If vPrevTSRowIndex >= pObj[vTS.Name].Count() Then
						If Not vChangesAreFound Then
							vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
							vChangesAreFound = True;
						EndIf;
						vChanges = vChanges + NStr("en='Deleted row N ';ru='Удалена строка № ';de='Gelöscht Reihe Nr. '") + Format(vPrevTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
						                      NStr("en='Service '; ru='Услуга '; de='Dienstleistung '") + TrimAll(vPrevTSRow.Service) + ", " + 
						                      NStr("en='Price '; ru='Цена '; de='Preis '") + cmFormatSum(vPrevTSRow.Price, vPrevTSRow.Currency) + " " + TrimAll(vPrevTSRow.Unit) + ", " + 
						                      ?(ValueIsFilled(vPrevTSRow.CalendarDayType), NStr("en='day type '; ru='тип дня '; de='Tagetyp '") + TrimAll(vPrevTSRow.CalendarDayType) + ", ", "") + 
						                      ?(ValueIsFilled(vPrevTSRow.Remarks), NStr("en='remarks '; ru='примечания '; de='Beschreibung '") + TrimAll(vPrevTSRow.Remarks), "");
						If Right(vChanges, 2) = ", " Then
							vChanges = Left(vChanges, StrLen(vChanges) - 2);
						EndIf;
						vChanges = vChanges + Chars.LF;
					EndIf;
				EndDo;
			Else
				For Each vTSRow In pObj[vTS.Name] Do
					vTSRowIndex = pObj[vTS.Name].IndexOf(vTSRow);
					vPrevTSRow = Undefined;
					If vTSRowIndex < vPrevObj[vTS.Name].Count() Then
						vPrevTSRow = vPrevObj[vTS.Name].Get(vTSRowIndex);
						vRowChangesAreFound = False;
						For Each vTSAttr In vObjMetadata.TabularSections[vTS.Name].Attributes Do
							If vTSRow[vTSAttr.Name] <> vPrevTSRow[vTSAttr.Name] Then
								vRowChangesAreFound = True;
								vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
								vChanges = vChanges + NStr("en='First changed row N ';ru='Первая измененная строка № ';de='Erste geänderte Zeile Nr. '") + Format(vTSRowIndex + 1, "ND=10; NFD=0; NG=") + ": " + vTSAttr.Synonym + ": " + TrimAll(String(vPrevTSRow[vTSAttr.Name])) + " -> " + TrimAll(String(vTSRow[vTSAttr.Name])) + Chars.LF;
								Break;
							EndIf;
						EndDo;
						If vRowChangesAreFound Then
							Break;
						ElsIf pObj[vTS.Name].Count() <> vPrevObj[vTS.Name].Count() Then
							vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
							vChanges = vChanges + NStr("en='Different number of rows...';ru='Разное кол-во строк...';de='Unterschiedliche Menge an Zeile...'") + Chars.LF + Chars.LF;
							Break;
						EndIf;
					Else
						If vPrevObj[vTS.Name].Count() = 0 Then
							vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
							vChanges = vChanges + NStr("en='New rows were added to the empty table...';ru='Новые строки добавлены в пустую таблицу...';de='Neue Zeilen wurden in die leere Tabelle hinzugefügt...'") + Chars.LF + Chars.LF;
						Else
							vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
							vChanges = vChanges + NStr("en='Different number of rows...';ru='Разное кол-во строк...';de='Unterschiedliche Menge an Zeile...'") + Chars.LF + Chars.LF;
						EndIf;
						Break;
					EndIf;
				EndDo;
			EndIf;
		ElsIf vPrevObj[vTS.Name].Count() > 0 Then
			// Deleted rows
			If vTS.Name = "ServicePackages" Then
				For Each vPrevTSRow In vPrevObj[vTS.Name] Do
					vPrevTSRowIndex = vPrevObj[vTS.Name].IndexOf(vPrevTSRow);
					If Not vChangesAreFound Then
						vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
						vChangesAreFound = True;
					EndIf;
					If TypeOf(pObj) = Type("DocumentObject.Accommodation") Or
					   TypeOf(pObj) = Type("DocumentObject.Reservation") Or 
					   TypeOf(pObj) = Type("DocumentObject.ResourceReservation") Then
						vChanges = vChanges + NStr("en='Deleted package N ';ru='Удален пакет № ';de='Entfernt Paket Nr. '") + Format(vPrevTSRowIndex + 1, "ND=10; NFD=0; NG=") + ": " + 
						                      TrimAll(vPrevTSRow.ServicePackage) + ", " + 
											  NStr("en='q-ty '; ru='кол-во '; de='Menge '") + Format(vPrevTSRow.Quantity, "NFD=3; NG=") + ", " + 
											  NStr("en='from '; ru='с '; de='von '") + Format(vPrevTSRow.DateFrom, "DF=dd.MM.yyyy") + NStr("en=' to '; ru=' по '; de=' bis '") + Format(vPrevTSRow.DateTo, "DF=dd.MM.yyyy") + 
											  Chars.LF;
					Else
						vChanges = vChanges + NStr("en='Deleted package N ';ru='Удален пакет № ';de='Entfernt Paket Nr. '") + Format(vPrevTSRowIndex + 1, "ND=10; NFD=0; NG=") + ": " + 
						                      TrimAll(vPrevTSRow.ServicePackage) + 
											  Chars.LF;
					EndIf;
				EndDo;
			ElsIf vTS.Name = "Prices" And (TypeOf(pObj) = Type("DocumentObject.Accommodation") Or TypeOf(pObj) = Type("DocumentObject.Reservation")) Then
				For Each vPrevTSRow In vPrevObj[vTS.Name] Do
					vPrevTSRowIndex = vPrevObj[vTS.Name].IndexOf(vPrevTSRow);
					If Not vChangesAreFound Then
						vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
						vChangesAreFound = True;
					EndIf;
					vChanges = vChanges + NStr("en='Deleted row N ';ru='Удалена строка № ';de='Gelöscht Reihe Nr. '") + Format(vPrevTSRowIndex + 1, "ND=10; NFD=0; NG=") + NStr("en=': '; ru=': '; de = ': '") + 
					                      NStr("en='Service '; ru='Услуга '; de='Dienstleistung '") + TrimAll(vPrevTSRow.Service) + ", " + 
					                      NStr("en='Price '; ru='Цена '; de='Preis '") + cmFormatSum(vPrevTSRow.Price, vPrevTSRow.Currency) + " " + TrimAll(vPrevTSRow.Unit) + ", " + 
					                      ?(ValueIsFilled(vPrevTSRow.CalendarDayType), NStr("en='day type '; ru='тип дня '; de='Tagetyp '") + TrimAll(vPrevTSRow.CalendarDayType) + ", ", "") + 
					                      ?(ValueIsFilled(vPrevTSRow.Remarks), NStr("en='remarks '; ru='примечания '; de='Beschreibung '") + TrimAll(vPrevTSRow.Remarks), "");
					If Right(vChanges, 2) = ", " Then
						vChanges = Left(vChanges, StrLen(vChanges) - 2);
					EndIf;
					vChanges = vChanges + Chars.LF;
				EndDo;
			Else
				vChanges = vChanges + Chars.LF + vTS.Synonym + Chars.LF + "--------------------------------------------------------" + Chars.LF;
				vChanges = vChanges + NStr("en='All rows were deleted...';ru='Все строки были удалены...';de='Alle Zeilen wurden gelöscht...'") + Chars.LF + Chars.LF;
			EndIf;
		EndIf;
	EndDo;
	Return TrimAll(vChanges);
EndFunction // cmCompareObjectsData

// -----------------------------------------------------------------------------
// Description: Function return AddIn 1CHotelSleep
// Parameters: None
// Return value: AddIn
// -----------------------------------------------------------------------------
Function cmGetAddIn1CHotelSleep() Export 
	vAddIn = Undefined;
	vSystemInfo = New SystemInfo;
	vOSVersion = vSystemInfo.OSVersion; 
	If StrFind(Upper(vOSVersion), " XP") = 0 And StrFind(Upper(vOSVersion), " 2003") = 0 Then
		Try
			vAddIn = New("AddIn.Native.1CHotelSleep");
		Except
			If cmGetPlatformVersionAsNumber(cmGetPlatformVersion(True)) >= cmGetPlatformVersionAsNumber("8.3.21.0") Then
				vAttachmentType = Undefined;
				vAttachResult = False;
				Execute("vAttachmentType = AddInAttachmentType.NotIsolated;");
				Execute("vAttachResult = AttachAddIn(""CommonTemplate.AddIn1CHotelSleep"", ""Native"", AddInType.Native, vAttachmentType);");
				If vAttachResult Then
					Try
						vAddIn = New("AddIn.Native.1CHotelSleep");
					Except
						vAddIn = Undefined;
					EndTry;
				EndIf;
			Else // Platform version prior to 8.3.21
				If AttachAddIn("CommonTemplate.AddIn1CHotelSleep", "Native", AddInType.Native) Then
					Try
						vAddIn = New("AddIn.Native.1CHotelSleep");
					Except
						vAddIn = Undefined;
					EndTry;
				EndIf;
			EndIf;
		EndTry;
	EndIf;
	Return vAddIn;
EndFunction // cmGetAddIn1CHotelSleep

// -----------------------------------------------------------------------------
// Description: Waits specified number of seconds
// Parameters: Number of seconds to wait
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmWait(pSeconds) Export
	vAddIn = cmGetAddIn1CHotelSleep();
	If vAddIn <> Undefined Then 
		vAddIn.Sleep(pSeconds);
		vAddIn = Undefined;	
	Else
		vKey = String(New UUID());
	    vName = "System.Wait";
	    
	    vParams = New Array();
	    vParams.Add(pSeconds);
	    vParams.Add(vKey);
	    vParams.Add(vName);
	    
	    vJob = BackgroundJobs.Execute("JobsScheduled.WaitForBackgroundJobToFinish", vParams, vKey, vName);
		Try
    		vJob.WaitForExecutionCompletion();
		Except
		EndTry;
	EndIf;
EndProcedure // cmWait

// -----------------------------------------------------------------------------
// Description: Returns user readable root error descripion
// Parameters: Error info object
// Return value: Error description string 
// -----------------------------------------------------------------------------
Function cmGetRootErrorDescription(pErrorInfo) Export
	vErrorInfo = pErrorInfo;
	If TypeOf(vErrorInfo) = Type("ErrorInfo") Then
		While vErrorInfo.Cause <> Undefined Do
			vErrorInfo = vErrorInfo.Cause;
		EndDo;
		Return vErrorInfo.Description;
	Else
		Return TrimAll(pErrorInfo);
	EndIf;
EndFunction // cmGetRootErrorDescription

// -----------------------------------------------------------------------------
// Description: Returns internet proxy object based on workstation settings
// Parameters: Internet connection settings catalog item reference, 
//             Boolean, true if proxy server is requested for a local address, 
//                      false for an internet address
//             Address as string to be checked across the list of addresses that should be bypassed
// Return value: Internet proxy object
// -----------------------------------------------------------------------------
Function cmGetInternetProxy(pSettings = Undefined, pIsLocal = False, pAddress = "") Export
	vSettings = Undefined;
	If ValueIsFilled(pSettings) Then
		vSettings = pSettings;
	ElsIf ValueIsFilled(SessionParameters.CurrentWorkstation) And ValueIsFilled(SessionParameters.CurrentWorkstation.InternetConnectionSettings) Then
		vSettings = SessionParameters.CurrentWorkstation.InternetConnectionSettings;
	EndIf;
	If Not ValueIsFilled(vSettings) Then
		Return Undefined;
	Else
		If pIsLocal And vSettings.BypassProxyOnLocal Then
			Return Undefined;
		Else
			vProxy = New InternetProxy();
			vProxy.User = TrimAll(vSettings.User);
			vProxy.Password = TrimAll(vSettings.Password);
			For Each vProtocolRow In vSettings.Protocols Do
				If Not IsBlankString(vProtocolRow.Protocol) And Not IsBlankString(vProtocolRow.Server) Then
					If vProtocolRow.Port > 0 Then
						vProxy.Set(TrimAll(vProtocolRow.Protocol), TrimAll(vProtocolRow.Server), TrimAll(vProtocolRow.Port));
					Else
						vProxy.Set(TrimAll(vProtocolRow.Protocol), TrimAll(vProtocolRow.Server));
					EndIf;
				EndIf;
			EndDo;
			// Check if input address is in the list of addresses that should be bypassed
			If Not IsBlankString(pAddress) Then
				For Each vAddress In vProxy.BypassProxyOnAddresses Do
					If Find(vAddress, TrimAll(pAddress)) > 0 Or Find(TrimAll(pAddress), vAddress) > 0 Then
						Return Undefined;
					EndIf;
				EndDo;
			EndIf;
			// Return proxy object
			Return vProxy;
		EndIf;
	EndIf;
EndFunction // cmGetInternetProxy

// -----------------------------------------------------------------------------
// Description: Returns program version as date string
// Parameters: None
// Return value: Program version as date string in YYMMDD format
// -----------------------------------------------------------------------------
Function cmGetProgramVersionAsDateString() Export
	// Current version number
	vVersion = Mid(TrimAll(Constants.ProgramVersionNumber.Get()), 1);
	// Change 1C:Hotel version number to date representation
	If vVersion = "8.2.1.1" Then
		vVersion = "100928";
	ElsIf vVersion = "8.2.1.2" Then
		vVersion = "101018";
	ElsIf vVersion = "8.2.1.3" Then
		vVersion = "101119";
	ElsIf vVersion = "8.2.1.4" Then
		vVersion = "101231";
	ElsIf vVersion = "8.2.1.5" Then
		vVersion = "110329";
	ElsIf vVersion = "8.2.1.6" Then
		vVersion = "110404";
	ElsIf vVersion = "8.2.1.7" Then
		vVersion = "110419";
	ElsIf vVersion = "8.2.1.8" Then
		vVersion = "110427";
	ElsIf vVersion = "8.2.1.9" Then
		vVersion = "110518";
	ElsIf vVersion = "8.2.1.10" Then
		vVersion = "110523";
	ElsIf vVersion = "8.2.1.11" Then
		vVersion = "110531";
	ElsIf vVersion = "8.2.1.12" Then
		vVersion = "110604";
	ElsIf vVersion = "8.2.2.1" Then
		vVersion = "110615";
	ElsIf vVersion = "8.2.2.2" Then
		vVersion = "111128";
	ElsIf vVersion = "8.2.2.3" Then
		vVersion = "111230";
	ElsIf vVersion = "8.2.2.4" Then
		vVersion = "120119";
	ElsIf vVersion = "8.2.2.5" Then
		vVersion = "120205";
	ElsIf vVersion = "8.2.2.6" Then
		vVersion = "120325";
	ElsIf vVersion = "8.2.2.7" Then
		vVersion = "120418";
	ElsIf vVersion = "8.2.2.8" Then
		vVersion = "120525";
	ElsIf vVersion = "8.2.2.9" Then
		vVersion = "120710";
	ElsIf vVersion = "8.2.2.10" Then
		vVersion = "120904";
	ElsIf vVersion = "8.2.2.11" Then
		vVersion = "120928";
	ElsIf vVersion = "8.2.2.12" Then
		vVersion = "121016";
	ElsIf vVersion = "8.2.2.13" Then
		vVersion = "121123";
	ElsIf vVersion = "8.2.2.14" Then
		vVersion = "121129";
	ElsIf vVersion = "8.2.2.15" Then
		vVersion = "121218";
	ElsIf vVersion = "8.2.2.16" Then
		vVersion = "130508";
	ElsIf vVersion = "8.2.2.17" Then
		vVersion = "130920";
	ElsIf vVersion = "8.2.2.19" Then
		vVersion = "131213";
	ElsIf vVersion = "8.2.2.20" Then
		vVersion = "131225";
	ElsIf vVersion = "8.2.2.21" Then
		vVersion = "140117";
	ElsIf vVersion = "8.2.2.22" Then
		vVersion = "140205";
	ElsIf vVersion = "8.2.2.23" Then
		vVersion = "140512";
	ElsIf vVersion = "8.2.2.24" Then
		vVersion = "140520";
	ElsIf vVersion = "8.2.2.25" Then
		vVersion = "140605";
	ElsIf vVersion = "8.2.2.26" Then
		vVersion = "140717";
	ElsIf vVersion = "8.2.2.27" Then
		vVersion = "140724";
	ElsIf vVersion = "8.2.2.28" Then
		vVersion = "140818";
	ElsIf vVersion = "8.2.2.29" Then
		vVersion = "140926";
	ElsIf vVersion = "8.2.2.30" Then
		vVersion = "141027";
	ElsIf vVersion = "8.2.2.31" Then
		vVersion = "141031";
	ElsIf vVersion = "8.2.2.32" Then
		vVersion = "141212";
	ElsIf vVersion = "8.2.2.33" Then
		vVersion = "141223";
	ElsIf vVersion = "8.2.2.34" Then
		vVersion = "150104";
	ElsIf vVersion = "8.2.2.35" Then
		vVersion = "150212";
	ElsIf vVersion = "8.2.2.36" Then
		vVersion = "150305";
	ElsIf vVersion = "8.2.2.37" Then
		vVersion = "150312";
	ElsIf vVersion = "8.2.2.38" Then
		vVersion = "150423";
	ElsIf vVersion = "8.2.2.39" Then
		vVersion = "150615";
	ElsIf vVersion = "8.2.2.40" Then
		vVersion = "150624";
	ElsIf vVersion = "8.2.2.41" Then
		vVersion = "150724";
	ElsIf vVersion = "8.2.2.42" Then
		vVersion = "150810";
	ElsIf vVersion = "8.2.2.43" Then
		vVersion = "150915";
	ElsIf vVersion = "8.2.2.44" Then
		vVersion = "150920";
	ElsIf vVersion = "8.2.2.45" Then
		vVersion = "160114";
	ElsIf vVersion = "8.3.1.1" Then
		vVersion = "160418";
	ElsIf vVersion = "8.3.1.2" Then
		vVersion = "160628";
	ElsIf vVersion = "8.3.1.3" Then
		vVersion = "160809";
	ElsIf vVersion = "8.3.1.4" Then
		vVersion = "161019";
	ElsIf vVersion = "8.3.1.5" Then
		vVersion = "170228";
	ElsIf vVersion = "8.3.1.6" Then
		vVersion = "170331";
	ElsIf vVersion = "8.3.1.7" Then
		vVersion = "170425";
	ElsIf vVersion = "8.3.1.8" Then
		vVersion = "170915";
	ElsIf vVersion = "8.3.1.9" Then
		vVersion = "171103";
	ElsIf vVersion = "8.3.1.10" Then
		vVersion = "180205";
	ElsIf vVersion = "8.3.1.11" Then
		vVersion = "180305";
	ElsIf vVersion = "8.3.1.12" Then
		vVersion = "180418";
	ElsIf vVersion = "8.3.1.13" Then
		vVersion = "180612";
	ElsIf vVersion = "8.3.1.14" Then
		vVersion = "180919";
	ElsIf vVersion = "8.3.1.15" Then
		vVersion = "181130";
	ElsIf vVersion = "8.3.1.16" Then
		vVersion = "190206";
	ElsIf vVersion = "8.3.1.17" Then
		vVersion = "190426";
	ElsIf vVersion = "8.3.1.18" Then
		vVersion = "190716";
	ElsIf vVersion = "8.4.1.1" Or vVersion = "9.0.1.1" Or vVersion = "9.0.1.2" Then
		vVersion = "190801";
	ElsIf vVersion = "9.0.1.3" Then
		vVersion = "191121";
	ElsIf vVersion = "9.0.1.4" Then
		vVersion = "191217";
	ElsIf vVersion = "9.0.1.5" Then
		vVersion = "200421";
	ElsIf vVersion = "9.0.1.6" Then
		vVersion = "200601";
	ElsIf vVersion = "9.0.2.1" Then
		vVersion = "200917";
	ElsIf vVersion = "9.0.2.2" Then
		vVersion = "201007";
	ElsIf vVersion = "9.0.2.3" Then
		vVersion = "201025";
	ElsIf vVersion = "9.0.2.4" Then
		vVersion = "201126";
	ElsIf vVersion = "9.0.2.5" Then
		vVersion = "201221";
	ElsIf vVersion = "9.0.2.6" Then
		vVersion = "210206";
	ElsIf vVersion = "9.0.2.7" Then
		vVersion = "210309";
	ElsIf vVersion = "9.0.2.8" Then
		vVersion = "210423";
	ElsIf vVersion = "9.0.2.9" Then
		vVersion = "210622";
	ElsIf vVersion = "9.0.3.1" Then
		vVersion = "211004";
	ElsIf vVersion = "9.0.3.2" Then
		vVersion = "211203";
	ElsIf vVersion = "9.0.3.3" Then
		vVersion = "220209";
	ElsIf vVersion = "9.0.3.4" Then
		vVersion = "220516";
	ElsIf vVersion = "9.0.4.1" Then
		vVersion = "220712";
	ElsIf vVersion = "9.0.4.2" Then
		vVersion = "220818";
	ElsIf vVersion = "9.0.4.3" Then
		vVersion = "221004";
	ElsIf vVersion = "9.0.4.4" Then
		vVersion = "221027";
	ElsIf vVersion = "9.0.4.5" Then
		vVersion = "230111";
	ElsIf vVersion = "9.0.4.6" Then
		vVersion = "230125";   
	ElsIf vVersion = "9.0.4.7" Then
		vVersion = "230125";	
	ElsIf vVersion = "9.1.1.1" Then
		vVersion = "230201";
	ElsIf vVersion = "9.1.1.2" Then
		vVersion = "230405";
	ElsIf vVersion = "9.1.1.3" Then
		vVersion = "230425";    
	ElsIf vVersion = "9.1.1.4" Then
		vVersion = "230526";
	ElsIf Left(vVersion, 6) = "9.1.2." Then
		vVersion = "231129";
	ElsIf Left(vVersion, 6) = "9.1.3." Then
		vVersion = "240112";   
	ElsIf Left(vVersion, 6) = "9.1.4." Then
		vVersion = "240131";
	ElsIf Left(vVersion, 6) = "9.2.1." Then
		vVersion = "240325";
	ElsIf Left(vVersion, 6) = "9.2.2." Then
		vVersion = "240902";
	ElsIf vVersion <= "9.2.3.32" Then
		vVersion = "241209";	
	ElsIf Left(vVersion, 6) = "9.2.3." Then
		vVersion = "250131";	 
	ElsIf Left(vVersion, 6) = "9.2.4." Then
		vVersion = "250403";
	ElsIf Left(vVersion, 6) = "9.2.5." Then
		vVersion = "250828";	
	ElsIf Left(vVersion, 6) = "9.2.6." Then
		vVersion = "260209";	
	Else
		vVersion = "N/A";
	EndIf;
	If StrLen(vVersion) = 8 Then
		vVersion = Right(vVersion, 6);
	EndIf;
	Return vVersion;
EndFunction // cmGetProgramVersionAsDateString

// -----------------------------------------------------------------------------
//  Writes record to Safety System Events information register
//
// Parameters:
//  pHotel				 - 	 - 
//  pEventType			 - 	 - 
//  pPeriod				 - 	 - 
//  pRoom				 - 	 - 
//  pCardType			 - 	 - 
//  pCardCode			 - 	 - 
//  pParentDoc			 - 	 - 
//  pClient				 - 	 - 
//  pEventDescription	 - 	 - 
//  pPeriodFrom			 - 	 - 
//  pPeriodTo			 - 	 - 
//  pNumberOfKeys		 - 	 - 
//
Procedure cmWriteSafetyEvent(pHotel, pEventType, pPeriod = '00010101', pRoom, pCardType, pCardCode, pParentDoc = Undefined, pClient = Undefined, pEventDescription, pPeriodFrom = '00010101', pPeriodTo = '00010101', pNumberOfKeys = 0) Export
	vRecMgr = InformationRegisters.SafetySystemEvents.CreateRecordManager();
	vRecMgr.Period = ?(ValueIsFilled(pPeriod), pPeriod, CurrentSessionDate());
	vRecMgr.Author = SessionParameters.CurrentUser;
	vRecMgr.Hotel = pHotel;
	vRecMgr.Room = pRoom;
	vRecMgr.EventType = pEventType;
	vRecMgr.CardType = pCardType;
	vRecMgr.CardCode = pCardCode;
	vRecMgr.ParentDoc = pParentDoc;
	vRecMgr.Guest = pClient;
	vRecMgr.EventDescription = pEventDescription;
	vRecMgr.PeriodFrom = pPeriodFrom;
	vRecMgr.PeriodTo = pPeriodTo;
	vRecMgr.NumberOfKeys = pNumberOfKeys;
	vRecMgr.Write();
EndProcedure // cmWriteSafetyEvent

// -----------------------------------------------------------------------------
// Description: Returns 1C platform version as string
// Parameters: None
// Return value: String "8.2" or "8.3"
// -----------------------------------------------------------------------------
Function cmGetPlatformVersion(pFull = False) Export
	vSI = New SystemInfo();
	If pFull Then
		vAppVersion = vSI.AppVersion;
	Else
		vAppVersion = Left(vSI.AppVersion, 3);
	EndIf;
	Return vAppVersion;
EndFunction // cmGetPlatformVersion

// -----------------------------------------------------------------------------
Function cmGetPlatformVersionAsNumber(pVersionAsString) Export
	vPV = 0;
	vVArr = StrSplit(pVersionAsString, ".", False);
	i = 0;
	While i < vVArr.Count() Do
		vV = Number(vVArr.Get(i));
		If i = 0 Then
			vPV = vV * 1000000000000;
		ElsIf i = 1 Then
			vPV = vPV + vV * 1000000000;
		ElsIf i = 2 Then
			vPV = vPV + vV * 1000000;
		Else
			vPV = vPV + vV;
		EndIf;
		i = i + 1;
	EndDo;
	Return vPV;
EndFunction // cmGetPlatformVersionAsNumber

// -----------------------------------------------------------------------------
// Description: Checks RFID reader event name
// Parameters: Event name
// Return value: Boolean
// -----------------------------------------------------------------------------
Function cmIsRFIDReaderExternalEvent(pStr) Export
	If pStr = "ironLogic Z-2" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmIsRFIDReaderExternalEvent

// -----------------------------------------------------------------------------
// Function - Gets the address bar in the format for the SKK
//
// Parameters:
//  pAddress - String -  string address
// 
// Returns:
//  String - formatted string address
//
Function cmParseAddressForSKK(Val pAddress) Export
	vAddress = "";	
	Try
		vAddressArr = cmParseAddress(pAddress);
		If vAddressArr.Country.IsEmpty() Then
			raise "Error";
		EndIf;	
		vRegion = New Structure("Code, Description","","");
		If Not IsBlankString(vAddressArr.Region) Then
			vReg = Catalogs.Regions.FindByDescription(TrimAll(vAddressArr.Region));
			vRegion.Code = TrimAll(vReg.Code);
			vRegion.Description = TrimAll(vAddressArr.Region); 
		EndIf;
		vLocality = "";
		vCity = "";
		If (Lower(Right(vAddressArr.City, 2)) = " г" Or Lower(Left(vAddressArr.City, 2)) = "г ") Or
			(Lower(Right(vAddressArr.City, 3)) = " г." Or Lower(Left(vAddressArr.City, 3)) = "г. ") Then
			vCity = TrimAll(vAddressArr.City);
		Else
			vLocality = TrimAll(vAddressArr.City);
		EndIf;   
		
	    vAddress = vAddress + 
					TrimAll(vAddressArr.Country.Code) + "," +       	//Country code
					TrimAll(vAddressArr.Country.Description) + "," +    //Country description
					TrimAll(vAddressArr.PostCode) + "," +       		//Post code
					TrimAll(vRegion.Code) + "," +       				//Region code
					TrimAll(vRegion.Description) +"," +       			//Region 
					TrimAll(vAddressArr.Area) +"," +       				//Area 
					TrimAll(vCity) +"," +       						//City 
					TrimAll(vLocality) + "," +      					//Locality
					TrimAll(vAddressArr.Street) + "," +       			//Street
					TrimAll("дом") + "," +       						//House type
					"," +                                               //Empty string
					TrimAll(vAddressArr.House) + "," +       			//House number
					"," +                                               //Empty string
					TrimAll("кв.") + "," +       						//Room type
					TrimAll("№"+vAddressArr.Flat);       				//Flat
	Except
	    vAddress = Upper(Nstr("en = 'Invalid address format'; ru = 'Неверный формат адреса'; de = 'Ungültiges Adressformat'"));
	
	EndTry;
	
	Return vAddress;
EndFunction //  cmParceAddressForSKK

// -----------------------------------------------------------------------------
// Description: Returns value table with all database employees
// Parameters: None
// Return value: Value table with employees
// -----------------------------------------------------------------------------
Function cmGetAllEmployees(pHotel = Undefined, pReturnDeleted = False) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Employees.Ref AS Employee
	|FROM
	|	Catalog.Employees AS Employees
	|WHERE
	|	(&qReturnDeleted
	|			OR NOT &qReturnDeleted
	|				AND NOT Employees.DeletionMark)
	|	AND NOT Employees.IsFolder
	|	AND (&qHotelIsEmpty
	|			OR NOT &qHotelIsEmpty
	|				AND (Employees.Hotel = &qHotel
	|					OR Employees.Hotel = &qEmptyHotel))
	|
	|ORDER BY
	|	Employees.SortCode,
	|	Employees.Description";
	vQry.SetParameter("qReturnDeleted", pReturnDeleted);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllEmployees

// -----------------------------------------------------------------------------
// Description: Returns employee reference by current user login UUID
// Parameters: Login UUID
// Return value: Reference to the employee catalog item or empty ref if not found
// -----------------------------------------------------------------------------
Function cmGetEmployeeByUserUUID(pUserUUID) Export
	vEmployee = Catalogs.Employees.EmptyRef();
	If pUserUUID = Undefined Then
		Return vEmployee;
	EndIf;
	vUserUUID = String(pUserUUID);
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	InfoBaseUsers.Employee AS Employee,
	|	InfoBaseUsers.UserName AS UserName
	|FROM
	|	InformationRegister.InfoBaseUsers AS InfoBaseUsers
	|WHERE
	|	InfoBaseUsers.UserUUID = &qUserUUID
	|
	|ORDER BY
	|	InfoBaseUsers.Employee.SortCode,
	|	InfoBaseUsers.Employee.Description";
	vQry.SetParameter("qUserUUID", vUserUUID);
	vEmployees = vQry.Execute().Unload();
	If vEmployees.Count() > 0 Then
		vEmployee = vEmployees.Get(0).Employee;
	Else
		vEmployee = Catalogs.Employees.FindByCode(vUserUUID, False);
	EndIf;
	Return vEmployee;
EndFunction // cmGetEmployeeByUserUUID

// -----------------------------------------------------------------------------
// Description: Returns employee reference by current user login UUID
// Parameters: Login UUID
// Return value: Reference to the employee catalog item or empty ref if not found
// -----------------------------------------------------------------------------
Function cmGetUserUUIDsByEmployee(pEmployee) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	InfoBaseUsers.UserUUID AS UserUUID,
	|	InfoBaseUsers.UserName AS UserName
	|FROM
	|	InformationRegister.InfoBaseUsers AS InfoBaseUsers
	|WHERE
	|	InfoBaseUsers.Employee = &qEmployee
	|
	|ORDER BY
	|	InfoBaseUsers.UserName,
	|	InfoBaseUsers.UserUUID";
	vQry.SetParameter("qEmployee", pEmployee);
	vEmployees = vQry.Execute().Unload();
	Return vEmployees;
EndFunction // cmGetUserUUIDsByEmployee

// -----------------------------------------------------------------------------
// Function returns employee by database username
//
// Parameters:
//  pUserName - String - data base username
// 
// Returns:
//  CatalogRef.Employees - Employee mapped to data base user 
//
Function cmGetEmployeeByUserName(pUserName) Export
	vEmployee = Catalogs.Employees.EmptyRef();
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	InfoBaseUsers.Employee AS Employee
	|FROM
	|	InformationRegister.InfoBaseUsers AS InfoBaseUsers
	|WHERE
	|	InfoBaseUsers.UserName = &qUserName";
	vQry.SetParameter("qUserName", pUserName);
	vEmployees = vQry.Execute().Select();
	If vEmployees.Next() Then
		vEmployee = vEmployees.Employee;
	EndIf;
	Return vEmployee;
EndFunction // cmGetEmployeeByUserName

// -----------------------------------------------------------------------------
// Description: Generates short employee code from it's full name
// Parameters: Employee full nmae
// Return value: Short code
// -----------------------------------------------------------------------------
Function cmGetEmployeeCode(pDescription) Export
	vCode = "";
	vDescr = StrReplace(TrimAll(pDescription), ".", " ");
	vDescr = StrReplace(TrimAll(pDescription), "  ", " ");
	vLastName = "";
	vFirstName = "";
	vSecondName = "";
	vSex = Undefined;
	cmParseClientFullName(vDescr, vLastName, vFirstName, vSecondName, vSex);
	If Not IsBlankString(vLastName) And Not IsBlankString(vFirstName) And Not IsBlankString(vSecondName) Then
		vCode = Upper(Left(vLastName, 1)) + Upper(Left(vFirstName, 1)) + Upper(Left(vSecondName, 1));
	ElsIf Not IsBlankString(vLastName) And Not IsBlankString(vFirstName) Then
		vCode = Upper(Left(vLastName, 2)) + Upper(Left(vFirstName, 1));
	ElsIf Not IsBlankString(vLastName) Then
		vCode = Upper(Left(vLastName, 3));
	Else
		vCode = String(New UUID);
	EndIf;
	Return vCode;
EndFunction // cmGetEmployeeCode

// -----------------------------------------------------------------------------
Function cmGetAuthCode(HTTPResponse) Export
	vResponseBody			=	HTTPResponse.GetBodyAsString();
	vResponseMap			=	Catalogs.DataConvertationRules.XMLtoMap(vResponseBody);
	vArrayPath				= 	New Array;
	vArrayPath.Add("div");
	vArrayPath.Add("div");
	vArrayPath.Add("h1");
	vArrayPath.Add("__TextValue");
	Return 	Catalogs.DataConvertationRules.GetMapValueByArrayPath(vResponseMap, vArrayPath);
EndFunction // cmGetAuthCode

// -----------------------------------------------------------------------------
Function cmGetDataProcessorByKey(pKey, pHotel = Undefined, pUseLike = False) Export
	vDPRef = Undefined;
	If Not IsBlankString(TrimAll(pKey)) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	DataProcessors.Ref AS Ref
		|FROM
		|	Catalog.DataProcessors AS DataProcessors
		|WHERE
		|	DataProcessors.Key " + ?(pUseLike, "LIKE ", "= ") + "&qKey
		|	AND (&qHotelIsUndefined OR NOT &qHotelIsUndefined AND DataProcessors.Hotel = &qHotel)
		|	AND NOT DataProcessors.DeletionMark
		|	AND NOT DataProcessors.IsFolder
		|
		|ORDER BY
		|	DataProcessors.SortCode,
		|	DataProcessors.Code";
		vQry.SetParameter("qKey", TrimAll(pKey) + ?(pUseLike, "%", ""));
		vQry.SetParameter("qHotelIsUndefined", ?(pHotel = Undefined, True, False));
		vQry.SetParameter("qHotel", pHotel);
		vDPs = vQry.Execute().Unload();
		If vDPs.Count() > 0 Then
			vDPRef = vDPs.Get(0).Ref;
		EndIf;
	EndIf;
	Return vDPRef;
EndFunction // cmGetDataProcessorByKey

#EndRegion