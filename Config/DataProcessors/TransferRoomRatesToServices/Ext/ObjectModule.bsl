#Region Public

// Transfers room rates to services.
// The service is found and created by the room rate reference UUID.
//
Procedure pmExecute() Export
	
	vContext = New Structure;
	vContext.Insert("CodeLength", Metadata.Catalogs.Services.CodeLength);
	vContext.Insert("UsedCodes", New Map);
	vContext.Insert("NextNumber", 0);
	vContext.Insert("Created", 0);
	vContext.Insert("Updated", 0);
	vContext.Insert("Errors", 0);
	vContext.Insert("Messages", New Array);
	
	vRates = RoomRatesToTransfer();
	vGroupFilter = SelectedRoomRateGroups(vRates);
	If GroupFilterIsFilled() And vGroupFilter.Count() = 0 Then
		Result = NStr("en='The specified room rate groups were not found.'; ru='Указанные группы тарифов не найдены.'; de='Die angegebenen Tarifgruppen wurden nicht gefunden.'");
		Return;
	EndIf;
	vSelected = New Map;
	For Each vRow In vRates Do
		If RoomRateMatchesHotel(vRow) And RoomRateMatchesGroups(vRow, vRates, vGroupFilter) Then
			vSelected.Insert(vRow.Ref, True);
		EndIf;
	EndDo;
	AddParentRoomRates(vRates, vSelected);
	If vSelected.Count() = 0 Then
		Result = NStr("en='No room rates found.'; ru='Тарифы не найдены.'; de='Keine Tarife gefunden.'");
		Return;
	EndIf;
	
	LoadUsedServiceCodes(vContext);
	
	vPending = New Array;
	For Each vItem In vSelected Do
		vRow = vRates.Find(vItem.Key, "Ref");
		If vRow <> Undefined Then
			vPending.Add(vRow);
		EndIf;
	EndDo;
	
	vWritten = New Map;
	vFailed = New Map;
	While vPending.Count() > 0 Do
		vNext = New Array;
		vProgress = False;
		For Each vRow In vPending Do
			If vFailed.Get(vRow.Parent) <> Undefined Then
				RegisterError(vContext, vRow, NStr("en='Parent room rate was not transferred.'; ru='Группа тарифа не перенесена.'; de='Die Tarifgruppe wurde nicht übertragen.'"));
				vFailed.Insert(vRow.Ref, True);
				vProgress = True;
			ElsIf ParentIsReady(vRow, vSelected, vWritten) Then
				If WriteService(vRow, vContext) Then
					vWritten.Insert(vRow.Ref, True);
				Else
					vFailed.Insert(vRow.Ref, True);
				EndIf;
				vProgress = True;
			Else
				vNext.Add(vRow);
			EndIf;
		EndDo;
		If Not vProgress Then
			For Each vRow In vNext Do
				RegisterError(vContext, vRow, NStr("en='Parent room rate was not transferred.'; ru='Группа тарифа не перенесена.'; de='Die Tarifgruppe wurde nicht übertragen.'"));
			EndDo;
			Break;
		EndIf;
		vPending = vNext;
	EndDo;
	
	vSummary = StrTemplate(
		NStr("en='Created: %1, updated: %2, errors: %3'; ru='Создано: %1, обновлено: %2, ошибок: %3'; de='Erstellt: %1, aktualisiert: %2, Fehler: %3'"),
		vContext.Created,
		vContext.Updated,
		vContext.Errors);
	vContext.Messages.Insert(0, vSummary);
	
	vText = "";
	For Each vLine In vContext.Messages Do
		vText = vText + vLine + Chars.LF;
	EndDo;
	Result = vText;
	
EndProcedure // pmExecute

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function RoomRatesToTransfer()
	
	vQuery = New Query;
	vQuery.Text =
	"SELECT
	|	RoomRates.Ref AS Ref,
	|	RoomRates.Parent AS Parent,
	|	RoomRates.IsFolder AS IsFolder,
	|	RoomRates.Code AS Code,
	|	RoomRates.Description AS Description,
	|	RoomRates.DeletionMark AS DeletionMark,
	|	RoomRates.DescriptionTranslations AS DescriptionTranslations,
	|	RoomRates.SortCode AS SortCode,
	|	RoomRates.QuantityCalculationRule AS QuantityCalculationRule,
	|	RoomRates.Remarks AS Remarks,
	|	RoomRates.Hotel AS Hotel,
	|	RoomRates.IsOnlineRate AS IsOnlineRate,
	|	RoomRates.ServicesIncludedDescription AS ServicesIncludedDescription
	|FROM
	|	Catalog.RoomRates AS RoomRates";
	vRates = vQuery.Execute().Unload();
	vRates.Indexes.Add("Ref");
	Return vRates;
	
EndFunction // RoomRatesToTransfer

// -----------------------------------------------------------------------------
Function GroupFilterIsFilled()
	
	For Each vRow In RoomRateGroups Do
		If ValueIsFilled(vRow.RoomRateGroup) Then
			Return True;
		EndIf;
	EndDo;
	Return False;
	
EndFunction // GroupFilterIsFilled

// -----------------------------------------------------------------------------
Function SelectedRoomRateGroups(pRates)
	
	vGroups = New Map;
	For Each vRow In RoomRateGroups Do
		If Not ValueIsFilled(vRow.RoomRateGroup) Then
			Continue;
		EndIf;
		vRateRow = pRates.Find(vRow.RoomRateGroup, "Ref");
		If vRateRow <> Undefined And vRateRow.IsFolder Then
			vGroups.Insert(vRow.RoomRateGroup, True);
		EndIf;
	EndDo;
	Return vGroups;
	
EndFunction // SelectedRoomRateGroups

// -----------------------------------------------------------------------------
Function RoomRateMatchesGroups(pRow, pRates, pGroups)
	
	If pGroups.Count() = 0 Then
		Return True;
	EndIf;
	
	vRef = pRow.Ref;
	vGuard = 0;
	While ValueIsFilled(vRef) And vGuard < 100 Do
		If pGroups.Get(vRef) <> Undefined Then
			Return True;
		EndIf;
		vParentRow = pRates.Find(vRef, "Ref");
		If vParentRow = Undefined Then
			Return False;
		EndIf;
		vRef = vParentRow.Parent;
		vGuard = vGuard + 1;
	EndDo;
	Return False;
	
EndFunction // RoomRateMatchesGroups

// -----------------------------------------------------------------------------
Function RoomRateMatchesHotel(pRow)
	
	If Not ValueIsFilled(Hotel) Then
		Return True;
	EndIf;
	Return pRow.Hotel = Hotel Or Not ValueIsFilled(pRow.Hotel);
	
EndFunction // RoomRateMatchesHotel

// -----------------------------------------------------------------------------
Procedure AddParentRoomRates(pRates, pSelected)
	
	vQueue = New Array;
	For Each vItem In pSelected Do
		vQueue.Add(vItem.Key);
	EndDo;
	
	vIndex = 0;
	While vIndex < vQueue.Count() Do
		vRow = pRates.Find(vQueue[vIndex], "Ref");
		If vRow <> Undefined And ValueIsFilled(vRow.Parent) And pSelected.Get(vRow.Parent) = Undefined Then
			If pRates.Find(vRow.Parent, "Ref") <> Undefined Then
				pSelected.Insert(vRow.Parent, True);
				vQueue.Add(vRow.Parent);
			EndIf;
		EndIf;
		vIndex = vIndex + 1;
	EndDo;
	
EndProcedure // AddParentRoomRates

// -----------------------------------------------------------------------------
Function ParentIsReady(pRow, pSelected, pWritten)
	
	If Not ValueIsFilled(pRow.Parent) Then
		Return True;
	EndIf;
	If pSelected.Get(pRow.Parent) = Undefined Then
		Return True;
	EndIf;
	Return pWritten.Get(pRow.Parent) <> Undefined;
	
EndFunction // ParentIsReady

// -----------------------------------------------------------------------------
Procedure EnsureServicePrice(pService, pHotel)
	
	vQuery = New Query;
	vQuery.Text =
	"SELECT TOP 1
	|	ServicePrices.Service AS Service
	|FROM
	|	InformationRegister.ServicePrices AS ServicePrices
	|WHERE
	|	ServicePrices.Service = &Service";
	vQuery.SetParameter("Service", pService);
	If Not vQuery.Execute().IsEmpty() Then
		Return;
	EndIf;
	
	vHotel = pHotel;
	If Not ValueIsFilled(vHotel) Then
		vHotel = Hotel;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	
	vRecord = InformationRegisters.ServicePrices.CreateRecordManager();
	vRecord.Period = Date(2010, 1, 1);
	vRecord.Hotel = vHotel;
	vRecord.Service = pService;
	vRecord.ClientType = Catalogs.ClientTypes.EmptyRef();
	vRecord.Price = 0;
	If ValueIsFilled(vHotel) Then
		vRecord.Currency = vHotel.BaseCurrency;
		If ValueIsFilled(vHotel.Company) And ValueIsFilled(vHotel.Company.VATRate) Then
			vRecord.VATRate = vHotel.Company.VATRate;
		EndIf;
	EndIf;
	vRecord.Write();
	
EndProcedure // EnsureServicePrice

// -----------------------------------------------------------------------------
Procedure LoadUsedServiceCodes(pContext)
	
	vQuery = New Query;
	vQuery.Text =
	"SELECT
	|	Services.Ref AS Ref,
	|	Services.Code AS Code
	|FROM
	|	Catalog.Services AS Services";
	vSelection = vQuery.Execute().Select();
	While vSelection.Next() Do
		vCode = TrimAll(vSelection.Code);
		If Not IsBlankString(vCode) Then
			pContext.UsedCodes.Insert(vCode, vSelection.Ref);
			RememberNumericCode(pContext, vCode);
		EndIf;
	EndDo;
	
EndProcedure // LoadUsedServiceCodes

// -----------------------------------------------------------------------------
Function WriteService(pRow, pContext)
	
	vTargetRef = Catalogs.Services.GetRef(pRow.Ref.UUID());
	vService = vTargetRef.GetObject();
	vIsNew = False;
	If vService = Undefined Then
		If pRow.IsFolder Then
			vService = Catalogs.Services.CreateFolder();
		Else
			vService = Catalogs.Services.CreateItem();
		EndIf;
		vService.SetNewObjectRef(vTargetRef);
		vIsNew = True;
	ElsIf vService.IsFolder <> pRow.IsFolder Then
		RegisterError(pContext, pRow, NStr("en='The service with this UUID has a different folder flag.'; ru='Услуга с этим UUID имеет другой признак группы.'; de='Die Dienstleistung mit dieser UUID hat ein anderes Gruppenkennzeichen.'"));
		Return False;
	EndIf;
	
	BeginTransaction();
	Try
		FillService(vService, pRow, vTargetRef, vIsNew, pContext);
		vService.Write();
		If vService.DeletionMark <> pRow.DeletionMark Then
			vService.SetDeletionMark(pRow.DeletionMark);
		EndIf;
		If Not pRow.IsFolder Then
			EnsureServicePrice(vService.Ref, vService.Hotel);
		EndIf;
		CommitTransaction();
	Except
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		RegisterError(pContext, pRow, BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	If vIsNew Then
		pContext.Created = pContext.Created + 1;
	Else
		pContext.Updated = pContext.Updated + 1;
	EndIf;
	Return True;
	
EndFunction // WriteService

// -----------------------------------------------------------------------------
Procedure FillService(pService, pRow, pTargetRef, pIsNew, pContext)
	
	pService.Description = pRow.Description;
	pService.SortCode = pRow.SortCode;
	pService.Hotel = pRow.Hotel;
	If ValueIsFilled(pRow.Parent) Then
		pService.Parent = Catalogs.Services.GetRef(pRow.Parent.UUID());
	Else
		pService.Parent = Catalogs.Services.EmptyRef();
	EndIf;
	
	If Not pRow.IsFolder Then
		pService.DescriptionTranslations = pRow.DescriptionTranslations;
		pService.QuantityCalculationRule = pRow.QuantityCalculationRule;
		pService.Remarks = pRow.Remarks;
		pService.OnlineAvaliable = pRow.IsOnlineRate;
		pService.Composition = pRow.ServicesIncludedDescription;
		If pIsNew Then
			pService.IsRoomRevenue = True;
		EndIf;
	EndIf;
	
	If pIsNew Then
		AssignCode(pService, pRow, pTargetRef, pContext);
	EndIf;
	
EndProcedure // FillService

// -----------------------------------------------------------------------------
Procedure AssignCode(pService, pRow, pTargetRef, pContext)
	
	vSourceCode = TrimAll(pRow.Code);
	If Not IsBlankString(vSourceCode)
		And StrLen(vSourceCode) <= pContext.CodeLength
		And Not CodeIsTaken(pContext, vSourceCode, pTargetRef) Then
		pService.Code = vSourceCode;
		pContext.UsedCodes.Insert(vSourceCode, pTargetRef);
		RememberNumericCode(pContext, vSourceCode);
		Return;
	EndIf;
	
	pService.SetNewCode();
	vAssignedCode = TrimAll(pService.Code);
	If IsBlankString(vAssignedCode) Or CodeIsTaken(pContext, vAssignedCode, pTargetRef) Then
		vAssignedCode = NextFreeCode(pContext);
		pService.Code = vAssignedCode;
	EndIf;
	pContext.UsedCodes.Insert(vAssignedCode, pTargetRef);
	RememberNumericCode(pContext, vAssignedCode);
	
EndProcedure // AssignCode

// -----------------------------------------------------------------------------
Function CodeIsTaken(pContext, pCode, pTargetRef)
	
	vOwner = pContext.UsedCodes.Get(pCode);
	Return vOwner <> Undefined And vOwner <> pTargetRef;
	
EndFunction // CodeIsTaken

// -----------------------------------------------------------------------------
Procedure RememberNumericCode(pContext, pCode)
	
	If Not IsNumericCode(pCode) Then
		Return;
	EndIf;
	vNumber = Number(pCode);
	If vNumber > pContext.NextNumber Then
		pContext.NextNumber = vNumber;
	EndIf;
	
EndProcedure // RememberNumericCode

// -----------------------------------------------------------------------------
Function NextFreeCode(pContext)
	
	vCode = "";
	While True Do
		pContext.NextNumber = pContext.NextNumber + 1;
		vCode = Format(pContext.NextNumber, "ND=" + Format(pContext.CodeLength, "NG=0") + "; NFD=0; NZ=; NLZ=; NG=");
		If pContext.UsedCodes.Get(vCode) = Undefined Then
			Break;
		EndIf;
	EndDo;
	Return vCode;
	
EndFunction // NextFreeCode

// -----------------------------------------------------------------------------
Function IsNumericCode(pCode)
	
	If IsBlankString(pCode) Then
		Return False;
	EndIf;
	vLength = StrLen(pCode);
	For vIndex = 1 To vLength Do
		vChar = Mid(pCode, vIndex, 1);
		If vChar < "0" Or vChar > "9" Then
			Return False;
		EndIf;
	EndDo;
	Return True;
	
EndFunction // IsNumericCode

// -----------------------------------------------------------------------------
Procedure RegisterError(pContext, pRow, pMessage)
	
	pContext.Errors = pContext.Errors + 1;
	If pContext.Errors <= 100 Then
		pContext.Messages.Add(StrTemplate(
			NStr("en='Room rate %1 (%2): %3'; ru='Тариф %1 (%2): %3'; de='Tarif %1 (%2): %3'"),
			TrimAll(pRow.Code),
			TrimAll(pRow.Description),
			pMessage));
	ElsIf pContext.Errors = 101 Then
		pContext.Messages.Add(NStr("en='Further errors are omitted.'; ru='Дальнейшие ошибки не выведены.'; de='Weitere Fehler werden nicht angezeigt.'"));
	EndIf;
	
EndProcedure // RegisterError

#EndRegion
