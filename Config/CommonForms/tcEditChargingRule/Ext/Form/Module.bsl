#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	EditMode = False;
	If Parameters.Property("EditMode") And TypeOf(Parameters.EditMode) = Type("Boolean") Then
		EditMode = Parameters.EditMode;
	EndIf;
	If EditMode Then
		Items.GroupLeftColumn.Visible = False;
		Items.SelChargingFolio.ReadOnly = True;
		Items.IsPersonal.ReadOnly = True;
		Items.IsTransfer.ReadOnly = True;
	EndIf;
	If IsInRole("Administrator") Then
		Items.IsMaster.ReadOnly = False;
	Else
		Items.IsMaster.ReadOnly = True;
	EndIf;
	If Parameters.Property("Parameters") Then
		vParameters = Parameters.Parameters;
		
		SelHotel = vParameters.SelHotel;
		SelCompany = vParameters.SelCompany;
		SelGuestGroup = vParameters.SelGuestGroup;
		SelRoom = vParameters.SelRoom;
		SelClient = Undefined; // Do not filter by room client by default
		SelCustomer = Undefined;
		SelContract = Undefined;
		SelAgent = Undefined;
		SelFolioDescription = "";
		SelFolioNumber = "";
		
		DftHotel = vParameters.SelHotel;
		DftCompany = vParameters.SelCompany;
		If Not ValueIsFilled(DftCompany) And ValueIsFilled(DftHotel) Then
			DftCompany = DftHotel.Company;
		EndIf;
		DftGuestGroup = vParameters.SelGuestGroup;
		DftRoom = vParameters.SelRoom;
		DftClient = vParameters.SelClient;
		DftObjectRef = vParameters.SelObjectRef;
		DftLineNumber = vParameters.SelLineNumber;
		DftCheckInDate = vParameters.SelCheckInDate;
		DftCheckOutDate = vParameters.SelCheckOutDate;
		
		SelChargingFolio = vParameters.SelChargingFolio;
		SelOwner = vParameters.SelOwner;
		SelChargingRule = vParameters.SelChargingRule;
		SelChargingRuleValue = vParameters.SelChargingRuleValue;
		SelValidFromDate = vParameters.SelValidFromDate;
		SelValidToDate = vParameters.SelValidToDate;
		SelIsMaster = vParameters.SelIsMaster;
		SelIsPersonal = vParameters.SelIsPersonal;
		SelIsTransfer = vParameters.SelIsTransfer;
		
		vClone = False;
		If Parameters.Property("SelClone") Then
			vClone = Parameters.SelClone; 	
		EndIf;
		If Not vClone Then 
			If Not ValueIsFilled(SelChargingRule) Then
				SelChargingRule = PredefinedValue("Enum.ChargingRuleTypes.InRate");
			EndIf;
		EndIf;
		SetChargingRuleValueType();
		If ValueIsFilled(SelChargingFolio) Then
			If ValueIsFilled(SelChargingFolio.Description) Then
				Items.SelChargingFolio.ToolTip = SelChargingFolio.Description;
				Items.SelChargingFolio.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
			Else
				Items.SelChargingFolio.ToolTip = "";
				Items.SelChargingFolio.ToolTipRepresentation = ToolTipRepresentation.None;
			EndIf;
		Else
			Items.SelChargingFolio.ToolTip = NStr("en='Select a folio from the list on the left or create a new one'; 
			                                      |ru='Выберите лицевой счет из списка слева или создайте новый'; 
												  |de='Wählen Sie ein Folio aus der Liste links aus oder erstellen Sie ein neues'");
			Items.SelChargingFolio.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		EndIf;
		If ValueIsFilled(SelChargingFolio) Then
			SelFolioPayer = SelChargingFolio.Customer;
		EndIf;
		If Not ValueIsFilled(DftObjectRef) Then
			Items.GroupFlags.Visible = False;
		EndIf;
		
		// Show default folios
		SelFolioStatus = 1;
		CheckIfFilterIsSet();
		ApplySearchConditionsAtServer();
	Else
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OwnerOnChange(pItem)
	If ValueIsFilled(SelOwner) Then
		If TypeOf(SelOwner) = Type("DocumentRef.Reservation") Or TypeOf(SelOwner) = Type("DocumentRef.Accommodation") Then
			SelChargingFolio = GetFolioFromReservation(SelOwner);
			SelIsTransfer = True;
		ElsIf TypeOf(SelOwner) = Type("DocumentRef.ResourceReservation") Then
			SelChargingFolio = GetFolioFromResourceReservation(SelOwner);
			SelIsTransfer = True;
		ElsIf TypeOf(SelOwner) = Type("CatalogRef.Customers") Or TypeOf(SelOwner) = Type("CatalogRef.Contracts") Or TypeOf(SelOwner) = Type("CatalogRef.Clients") Then
			SelChargingFolio = UpdateFolioByNewOwner(SelOwner, SelChargingFolio);
			SelIsTransfer = False;
		EndIf;
	EndIf;
	ChargingRulesChange();
EndProcedure // OwnerOnChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SelFolioPayerOnChangeAtServer()
	If ValueIsFilled(SelChargingFolio) Then
		If SelFolioPayer <> SelChargingFolio.Customer Then
			vFolioObj = SelChargingFolio.GetObject();
			vFolioObj.Customer = SelFolioPayer;
			vFolioObj.Contract = Undefined;
			vFolioObj.Write();
		EndIf;
	EndIf;
EndProcedure // SelFolioPayerOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFolioPayerOnChange(pItem)
	SelFolioPayerOnChangeAtServer();
	ChargingRulesChange();
EndProcedure // SelFolioPayerOnChange

// -----------------------------------------------------------------------------
&AtServerNoContext
Function UpdateFolioByNewOwner(pOwner, pFolio)
	vFolioObj = pFolio.GetObject();
	If TypeOf(pOwner) = Type("CatalogRef.Customers") Then
		vFolioObj.Customer = pOwner;
		vFolioObj.Contract = Undefined;
	ElsIf TypeOf(pOwner) = Type("CatalogRef.Contracts") Then
		vFolioObj.Customer = pOwner.Owner;
		vFolioObj.Contract = pOwner;
	Else
		vFolioObj.Client = pOwner;
	EndIf;
	vFolioObj.Write(DocumentWriteMode.Write);
	Return vFolioObj.Ref;
EndFunction // UpdateFolioByNewOwner

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRuleOnChange(pItem)
	SetChargingRuleValueType();
	ChargingRulesChange();
EndProcedure // ChargingRuleOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingFolioOnChange(pItem)
	ChargingRulesChange();
EndProcedure // ChargingFolioOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingFolioOpening(pItem, pStandardProcessing)
	If Not ValueIsFilled(SelChargingFolio) Then
		pStandardProcessing = False;
		vFolioDataStruct = New Structure("Hotel, Company, GuestGroup, Room, Client, DateTimeFrom, DateTimeTo, ParentDoc, LineNumber", DftHotel, DftCompany, DftGuestGroup, DftRoom, DftClient, DftCheckInDate, DftCheckOutDate, DftObjectRef, DftLineNumber);
		SelChargingFolio = GetNewDocumentFolioAtServer(vFolioDataStruct);
		OpenForm("Document.Folio.ObjectForm", New Structure("Key", SelChargingFolio), ThisForm, SelChargingFolio, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // ChargingFolioOpening

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingFolioCreating(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vFolioDataStruct = New Structure("Hotel, Company, GuestGroup, Room, Client, DateTimeFrom, DateTimeTo, ParentDoc, LineNumber", DftHotel, DftCompany, DftGuestGroup, DftRoom, DftClient, DftCheckInDate, DftCheckOutDate, DftObjectRef, DftLineNumber);
	ChargingFolio = GetNewDocumentFolioAtServer(vFolioDataStruct);
EndProcedure // ChargingFolioCreating

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRuleValueOnChange(pItem)
	ChargingRulesChange();
EndProcedure // ChargingRuleValueOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ValidFromDateOnChange(pItem)
	ChargingRulesChange();
EndProcedure // ValidFromDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ValidToDateOnChange(pItem)
	ChargingRulesChange();
EndProcedure // ValidToDateOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsMasterOnChange(pItem)
	ChargingRulesChange();	
EndProcedure // IsMasterOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsPersonalOnChange(pItem)
	ChargingRulesChange();
EndProcedure // IsPersonalOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure IsTransferOnChange(pItem)
	ChargingRulesChange();
EndProcedure // IsTransferOnChange

#EndRegion

#Region FormCommandsEventHandlers 

// -----------------------------------------------------------------------------
&AtClient
Procedure Save(pCommand)
	If Not ValueIsFilled(SelChargingFolio) Then
		ShowMessageBox(, NStr("en='Folio is not choosen or created!'; ru='Лицевой счет не выбран или не создан!'; de='Folio ist nicht ausgewählt oder erstellt!'"));
		Return;
	ElsIf Not ValueIsFilled(SelChargingRule) Then
		ShowMessageBox(, NStr("en='Charging rule is not choosen!'; ru='Не выбрано правило отбора услуг!'; de='Serviceauswahlregel nicht ausgewählt!'"));
		Return;
	EndIf;
	vParams = New Structure("Owner, ChargingRule, ChargingRuleValue, ChargingFolio, ValidFromDate, ValidToDate, IsMaster, IsPersonal, IsTransfer",
							 SelOwner, SelChargingRule, SelChargingRuleValue, SelChargingFolio, SelValidFromDate, SelValidToDate, SelIsMaster, SelIsPersonal, SelIsTransfer);
	Close(vParams);
EndProcedure // Save

#EndRegion

#Region Private

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
&AtServerNoContext
Function GetChargingRuleOwnerByFolioAtServer(pThisDocRef, pFolio, rIsTransfer, rFolioPayer)
	If ValueIsFilled(pFolio) Then
		vHotel = pFolio.Hotel;
		rFolioPayer = pFolio.Customer;
		vParentDoc = pFolio.ParentDoc;
		If pThisDocRef <> vParentDoc And ValueIsFilled(vParentDoc) And ValueIsFilled(pThisDocRef) Then
			rIsTransfer = True;
		EndIf;
		If rIsTransfer And ValueIsFilled(vParentDoc) And 
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
Function GetNewDocumentFolioAtServer(pFolioData)
	vFolioObj = Documents.Folio.CreateDocument();
	vFolioObj.pmFillAttributesWithDefaultValues();
	FillPropertyValues(vFolioObj, pFolioData);
	vFolioObj.Write(DocumentWriteMode.Write);
	Return vFolioObj.Ref;
EndFunction // GetNewDocumentFolioAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChargingRulesChange()
	If ValueIsFilled(SelChargingFolio) Then
		vIsTransfer = SelIsTransfer;
		SelOwner = GetChargingRuleOwnerByFolioAtServer(DftObjectRef, SelChargingFolio, vIsTransfer, SelFolioPayer);
		SelIsTransfer = vIsTransfer;
		vParentDoc = tcOnServer.cmGetAttributeByRef(SelChargingFolio, "ParentDoc");
		If Not ValueIsFilled(vParentDoc) And ValueIsFilled(DftObjectRef) And 
		  (TypeOf(DftObjectRef) = Type("DocumentRef.Accommodation") Or 
		   TypeOf(DftObjectRef) = Type("DocumentRef.Reservation") Or 
		   TypeOf(DftObjectRef) = Type("DocumentRef.ResourceReservation")) Then
			SelIsTransfer = True;
		EndIf;
		vFolioDescription = tcOnServer.cmGetAttributeByRef(SelChargingFolio, "Description");
		If ValueIsFilled(vFolioDescription) Then
			Items.SelChargingFolio.ToolTip = vFolioDescription;
			Items.SelChargingFolio.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		Else
			Items.SelChargingFolio.ToolTip = "";
			Items.SelChargingFolio.ToolTipRepresentation = ToolTipRepresentation.None;
		EndIf;
	Else
		Items.SelChargingFolio.ToolTip = NStr("en='Select a folio from the list on the left or create a new one'; 
		                                      |ru='Выберите лицевой счет из списка слева или создайте новый'; 
											  |de='Wählen Sie ein Folio aus der Liste links aus oder erstellen Sie ein neues'");
		Items.SelChargingFolio.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
	EndIf;	
EndProcedure // ChargingRulesChange

// -----------------------------------------------------------------------------
&AtServer
Procedure SetChargingRuleValueType()
	Items.ChargingRuleValue.Enabled = False;
	Items.ChargingRuleValue.Title = NStr("en='Rule condition'; ru='Условие правила'; de='Regelbedingung'");
	If ValueIsFilled(SelChargingRule) Then
		Items.ChargingRuleValue.ChooseType = False;
		If SelChargingRule = Enums.ChargingRuleTypes.AllButOne Or
		   SelChargingRule = Enums.ChargingRuleTypes.One Then
			If TypeOf(SelChargingRuleValue) <> Type("CatalogRef.Services") Then
				SelChargingRuleValue = Catalogs.Services.EmptyRef();
			EndIf;
			Items.ChargingRuleValue.Enabled = True;
			Items.ChargingRuleValue.Title = NStr("en='Service'; ru='Услуга'; de='Service'");
		ElsIf SelChargingRule = Enums.ChargingRuleTypes.InServiceGroup Or
		      SelChargingRule = Enums.ChargingRuleTypes.NotInServiceGroup Then
			If TypeOf(SelChargingRuleValue) <> Type("CatalogRef.ServiceGroups") Then
				SelChargingRuleValue = Catalogs.ServiceGroups.EmptyRef();
			EndIf;
			Items.ChargingRuleValue.Enabled = True;
			Items.ChargingRuleValue.Title = NStr("en='Service group'; ru='Набор услуг'; de='Service group'");
		ElsIf SelChargingRule = Enums.ChargingRuleTypes.RestOfRoomRevenuePrice Or
		      SelChargingRule = Enums.ChargingRuleTypes.RoomRevenueAmount Or
		      SelChargingRule = Enums.ChargingRuleTypes.RoomRevenuePrice Or 			     
		      SelChargingRule = Enums.ChargingRuleTypes.RoomRevenuePricePercent Then
			If TypeOf(SelChargingRuleValue) <> Type("Number") Then
				SelChargingRuleValue = 0;
			EndIf;
			If SelChargingRule = Enums.ChargingRuleTypes.RestOfRoomRevenuePrice Then
				SelChargingRuleValue = 0;
			Else
				Items.ChargingRuleValue.Enabled = True;
			EndIf;
			Items.ChargingRuleValue.Title = NStr("en='Amount'; ru='Сумма'; de='Betrag'");
		ElsIf SelChargingRule = Enums.ChargingRuleTypes.RoomRevenuePriceByRoomType Then
			If TypeOf(SelChargingRuleValue) <> Type("CatalogRef.RoomTypes") Then
				SelChargingRuleValue = Catalogs.RoomTypes.EmptyRef();;
			EndIf;
			Items.ChargingRuleValue.Enabled = True;
			Items.ChargingRuleValue.Title = NStr("en='Room type'; ru='Тип номера'; de='Zimmertyp'");
		Else
			SelChargingRuleValue = Undefined;
		EndIf;
	Else
		Items.ChargingRuleValue.ChooseType = True;
		SelChargingRuleValue = Undefined;
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
Procedure ChargingFolioTextEditEnd(pItem, pText, pChoiceData, pDataGetParameters, pStandardProcessing)
	vFolio = GetFolioByNumberPart(pText, SelHotel, SelCompany); 
	If ValueIsFilled(vFolio) Then
		pStandardProcessing = False;
		If pChoiceData = Undefined Then
			pChoiceData = New ValueList();
		EndIf;
		pChoiceData.Add(vFolio);
	EndIf;
EndProcedure // ChargingFolioTextEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectFolio(pCommand)
	vCurRef = Items.FoliosList.CurrentRow;
	If vCurRef <> Undefined Then
		SelChargingFolio = vCurRef;
		ChargingFolioOnChange(Items.SelChargingFolio);
	EndIf;
EndProcedure // SelectFolio

// -----------------------------------------------------------------------------
&AtClient
Procedure FoliosListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vCurRef = Items.FoliosList.CurrentRow;
	If vCurRef <> Undefined Then
		SelChargingFolio = vCurRef;
		ChargingFolioOnChange(Items.SelChargingFolio);
	EndIf;
EndProcedure // FoliosListSelection

#EndRegion

#Region FolioSearch

// -----------------------------------------------------------------------------
&AtServer
Procedure CheckIfFilterIsSet()
	If EditMode Then
		FilterIsSet = False;
	Else
		If Not ValueIsFilled(SelRoom) And  
		   Not ValueIsFilled(SelClient) And
		   Not ValueIsFilled(SelGuestGroup) And
		   Not ValueIsFilled(SelCustomer) And
		   Not ValueIsFilled(SelContract) And
		   Not ValueIsFilled(SelAgent) And
		   Not ValueIsFilled(SelCompany) And
		   IsBlankString(SelFolioNumber) And
		   IsBlankString(SelFolioDescription) Then
			FilterIsSet = False;
		Else
			FilterIsSet = True;
		EndIf;
	EndIf;
EndProcedure // CheckIfFilterIsSet

// -----------------------------------------------------------------------------
&AtServer
Procedure ApplySearchConditionsAtServer()
	// Check if there is something to show
	CheckIfFilterIsSet();
	// Set dynamic list parameters
	FoliosList.Parameters.SetParameterValue("qFilterIsSet", FilterIsSet);
	FoliosList.Parameters.SetParameterValue("qRoom", SelRoom);
	FoliosList.Parameters.SetParameterValue("qRoomIsEmpty", Not ValueIsFilled(SelRoom));
	FoliosList.Parameters.SetParameterValue("qGuestGroup", SelGuestGroup);
	FoliosList.Parameters.SetParameterValue("qGuestGroupIsEmpty", Not ValueIsFilled(SelGuestGroup));
	FoliosList.Parameters.SetParameterValue("qClient", SelClient);
	FoliosList.Parameters.SetParameterValue("qClientIsEmpty", Not ValueIsFilled(SelClient));
	FoliosList.Parameters.SetParameterValue("qCustomer", SelCustomer);
	FoliosList.Parameters.SetParameterValue("qCustomerIsEmpty", Not ValueIsFilled(SelCustomer));
	FoliosList.Parameters.SetParameterValue("qContract", SelContract);
	FoliosList.Parameters.SetParameterValue("qContractIsEmpty", Not ValueIsFilled(SelContract));
	FoliosList.Parameters.SetParameterValue("qAgent", SelAgent);
	FoliosList.Parameters.SetParameterValue("qAgentIsEmpty", Not ValueIsFilled(SelAgent));
	FoliosList.Parameters.SetParameterValue("qCompany", SelCompany);
	FoliosList.Parameters.SetParameterValue("qCompanyIsEmpty", Not ValueIsFilled(SelCompany));
	FoliosList.Parameters.SetParameterValue("qHotel", SelHotel);
	FoliosList.Parameters.SetParameterValue("qHotelIsEmpty", Not ValueIsFilled(SelHotel));
	FoliosList.Parameters.SetParameterValue("qFolioNumber", "%" + TrimAll(SelFolioNumber) + "%");
	FoliosList.Parameters.SetParameterValue("qFolioNumberIsEmpty", IsBlankString(SelFolioNumber));
	FoliosList.Parameters.SetParameterValue("qFolioDescription", "%" + TrimAll(SelFolioDescription) + "%");
	FoliosList.Parameters.SetParameterValue("qFolioDescriptionIsEmpty", IsBlankString(SelFolioDescription));
	FoliosList.Parameters.SetParameterValue("qFolioStatus", SelFolioStatus);
EndProcedure // ApplySearchConditionsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(pItem)
	If ValueIsFilled(SelRoom) Then
		If ValueIsFilled(SelClient) Then
			SelClient = Undefined;
		EndIf;
		If ValueIsFilled(SelGuestGroup) Then
			SelGuestGroup = Undefined;
		EndIf;
	EndIf;
	ApplySearchConditionsAtServer();
EndProcedure // SelRoomOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelGuestGroupOnChange(pItem)
	ApplySearchConditionsAtServer();
EndProcedure // SelGuestGroupOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelClientOnChange(pItem)
	ApplySearchConditionsAtServer();
EndProcedure // SelClientOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(pItem)
	ApplySearchConditionsAtServer();
EndProcedure // SelCustomerOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelContractOnChange(pItem)
	ApplySearchConditionsAtServer();
EndProcedure // SelContractOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelAgentOnChange(pItem)
	ApplySearchConditionsAtServer();
EndProcedure // SelAgentOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCompanyOnChange(pItem)
	ApplySearchConditionsAtServer();
EndProcedure // SelCompanyOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFolioNumberOnChange(pItem)
	If Not IsBlankString(SelFolioNumber) Then
		If ValueIsFilled(SelRoom) Then
			SelRoom = Undefined;
		EndIf;
		If ValueIsFilled(SelClient) Then
			SelClient = Undefined;
		EndIf;
		If ValueIsFilled(SelGuestGroup) Then
			SelGuestGroup = Undefined;
		EndIf;
		If ValueIsFilled(SelCustomer) Then
			SelCustomer = Undefined;
		EndIf;
		If ValueIsFilled(SelContract) Then
			SelContract = Undefined;
		EndIf;
		If ValueIsFilled(SelAgent) Then
			SelAgent = Undefined;
		EndIf;
		If Not IsBlankString(SelFolioDescription) Then
			SelFolioDescription = Undefined;
		EndIf;
	EndIf;
	ApplySearchConditionsAtServer();
EndProcedure // SelFolioNumberOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFolioDescriptionOnChange(pItem)
	ApplySearchConditionsAtServer();
EndProcedure // SelFolioDescriptionOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelFolioStatusOnChange(pItem)
	ApplySearchConditionsAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearFilter(pCommand)
	// Reset filters
	SelRoom = Undefined;
	SelGuestGroup = Undefined;
	SelClient = Undefined;
	SelCustomer = Undefined;
	SelContract = Undefined;
	SelAgent = Undefined;
	SelCompany = Undefined;
	SelFolioNumber = "";
	SelFolioDescription = "";
	SelFolioStatus = 1;
	// Apply filter
	ApplySearchConditionsAtServer();
EndProcedure // ClearFilter

// -----------------------------------------------------------------------------
&AtClient
Procedure CreateNewFolio(pCommand)
	vFolioDataStruct = New Structure("Hotel, Company, GuestGroup, Room, Client, DateTimeFrom, DateTimeTo, ParentDoc, LineNumber", DftHotel, DftCompany, DftGuestGroup, DftRoom, DftClient, DftCheckInDate, DftCheckOutDate, DftObjectRef, DftLineNumber);
	SelChargingFolio = GetNewDocumentFolioAtServer(vFolioDataStruct);
	OpenForm("Document.Folio.ObjectForm", New Structure("Key", SelChargingFolio), ThisForm, SelChargingFolio, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // CreateNewFolio

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Document.Folio.Edit" And pParameter = SelChargingFolio Then
		ChargingRulesChange();
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion
