
#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(PriceDate) Then
		PriceDate = BegOfDay(CurrentSessionDate());
	EndIf;
	If Not ValueIsFilled(VATRate) And ValueIsFilled(Hotel) Then
		vCompany = Hotel.Company;
		If ValueIsFilled(vCompany) Then
			VATRate = vCompany.VATRate;
		EndIf;
	EndIf;
	IsStockArticle = True;
	FillServiceItemsTabularSection = True;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmRun() Export
	Return TransferServiceItems();
EndFunction // pmRun

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function TransferServiceItems()
	vFuncLogName = NStr("en = 'DataProcessor.TransferServiceItemsToServices'; de = 'DataProcessor.TransferServiceItemsToServices'; ru = 'Обработка.ПереносПозицийМенюВУслуги'");
	WriteLogEvent(vFuncLogName, EventLogLevel.Information, Metadata(), Undefined, NStr("en = 'Start of processing'; de = 'Anfang der Ausführung'; ru = 'Начало выполнения'"));
	
	If Not ValueIsFilled(Hotel) Then
		vMessage = NStr("en = 'Hotel is not specified!'; de = 'Hotel ist nicht angegeben!'; ru = 'Не указана гостиница!'");
		WriteLogEvent(vFuncLogName, EventLogLevel.Warning, Metadata(), Undefined, vMessage);
		Return vMessage;
	EndIf;
	If Not ValueIsFilled(VATRate) Then
		vMessage = NStr("en = 'VAT rate is not specified!'; de = 'MwSt.-Satz ist nicht angegeben!'; ru = 'Не указана ставка НДС!'");
		WriteLogEvent(vFuncLogName, EventLogLevel.Warning, Metadata(), Undefined, vMessage);
		Return vMessage;
	EndIf;
	If Not ValueIsFilled(PriceDate) Then
		PriceDate = BegOfDay(CurrentSessionDate());
	EndIf;
	
	vDefaultCurrency = Hotel.BaseCurrency;
	vMap = New Map;
	vFoldersCreated = 0;
	vItemsCreated = 0;
	vPricesCreated = 0;
	vSkipped = 0;
	vErrors = New Array;
	
	vQuery = New Query;
	vQuery.Text =
	"SELECT
	|	ServiceItems.Ref AS Ref,
	|	ServiceItems.IsFolder AS IsFolder,
	|	ServiceItems.Parent AS Parent,
	|	ServiceItems.Code AS Code,
	|	ServiceItems.Description AS Description,
	|	ServiceItems.DeletionMark AS DeletionMark,
	|	ServiceItems.ExternalCode AS ExternalCode,
	|	ServiceItems.SortCode AS SortCode,
	|	ServiceItems.Hotel AS Hotel,
	|	ServiceItems.DescriptionTranslations AS DescriptionTranslations,
	|	ServiceItems.Unit AS Unit,
	|	ServiceItems.UnitTranslations AS UnitTranslations,
	|	ServiceItems.Remarks AS Remarks,
	|	ServiceItems.Price AS Price,
	|	ServiceItems.CostPrice AS CostPrice,
	|	ServiceItems.Currency AS Currency,
	|	ServiceItems.Quantity AS Quantity,
	|	ServiceItems.Output AS Output,
	|	ServiceItems.ItemCode AS ItemCode,
	|	ServiceItems.IsOutOfSale AS IsOutOfSale
	|FROM
	|	Catalog.ServiceItems AS ServiceItems
	|WHERE
	|	(&qTransferMarkedForDeletion
	|			OR NOT ServiceItems.DeletionMark)
	|	AND (&qTransferOutOfSale
	|			OR ServiceItems.IsFolder
	|			OR NOT ServiceItems.IsOutOfSale)
	|	AND (ServiceItems.Hotel = &qHotel
	|			OR ServiceItems.Hotel = VALUE(Catalog.Hotels.EmptyRef))";
	If ValueIsFilled(ServiceItemFolder) Then
		vQuery.Text = vQuery.Text + "
		|	AND ServiceItems.Ref IN HIERARCHY (&qFolder)";
		vQuery.SetParameter("qFolder", ServiceItemFolder);
	EndIf;
	vQuery.Text = vQuery.Text + "
	|
	|ORDER BY
	|	ServiceItems.Ref HIERARCHY";
	vQuery.SetParameter("qHotel", Hotel);
	vQuery.SetParameter("qTransferMarkedForDeletion", TransferMarkedForDeletion);
	vQuery.SetParameter("qTransferOutOfSale", TransferOutOfSale);
	
	vSelection = vQuery.Execute().Select();
	While vSelection.Next() Do
		Try
			vResult = TransferOneRow(vSelection, vMap, vDefaultCurrency);
			If vResult = "Skipped" Then
				vSkipped = vSkipped + 1;
			ElsIf vResult = "Folder" Then
				vFoldersCreated = vFoldersCreated + 1;
			ElsIf vResult = "Item" Then
				vItemsCreated = vItemsCreated + 1;
				vPricesCreated = vPricesCreated + 1;
			EndIf;
		Except
			vErrorText = TrimAll(vSelection.Description) + ": " + ErrorDescription();
			vErrors.Add(vErrorText);
			WriteLogEvent(vFuncLogName, EventLogLevel.Error, Metadata(), vSelection.Ref, vErrorText);
		EndTry;
	EndDo;
	
	vMessage = StrTemplate(
		NStr("en = 'Transfer completed. Folders created: %1, services created: %2, prices created: %3, skipped: %4.';
			|de = 'Übertragung abgeschlossen. Ordner erstellt: %1, Dienstleistungen erstellt: %2, Preise erstellt: %3, übersprungen: %4.';
			|ru = 'Перенос завершен. Создано папок: %1, услуг: %2, цен: %3, пропущено: %4.'"),
		vFoldersCreated, vItemsCreated, vPricesCreated, vSkipped);
	If vErrors.Count() > 0 Then
		vMessage = vMessage + Chars.LF + StrTemplate(
			NStr("en = 'Errors: %1'; de = 'Fehler: %1'; ru = 'Ошибок: %1'"), vErrors.Count());
		vShown = 0;
		For Each vErrorText In vErrors Do
			If vShown >= 20 Then
				Break;
			EndIf;
			vMessage = vMessage + Chars.LF + vErrorText;
			vShown = vShown + 1;
		EndDo;
	EndIf;
	
	WriteLogEvent(vFuncLogName, EventLogLevel.Information, Metadata(), Undefined, vMessage);
	Return vMessage;
EndFunction // TransferServiceItems

// -----------------------------------------------------------------------------
Function TransferOneRow(pRow, pMap, pDefaultCurrency)
	If IsBlankString(pRow.Description) Then
		Return "Skipped";
	EndIf;
	
	vParent = GetMappedParent(pRow, pMap);
	
	If pRow.IsFolder Then
		vExisting = FindExistingFolder(pRow.Description, vParent);
		If ValueIsFilled(vExisting) Then
			pMap.Insert(pRow.Ref, vExisting);
			Return "Skipped";
		EndIf;
		vObj = Catalogs.Services.CreateFolder();
	Else
		vExternalCode = GetExternalCode(pRow);
		If Not IsBlankString(vExternalCode) Then
			vExisting = Catalogs.Services.FindByAttribute("ExternalCode", vExternalCode);
			If ValueIsFilled(vExisting) And Not vExisting.IsFolder Then
				pMap.Insert(pRow.Ref, vExisting);
				Return "Skipped";
			EndIf;
		EndIf;
		vObj = Catalogs.Services.CreateItem();
	EndIf;
	
	vObj.DataExchange.Load = True;
	FillServiceCode(vObj, pRow.Code);
	vObj.Description = pRow.Description;
	vObj.Parent = vParent;
	vObj.SortCode = pRow.SortCode;
	If ValueIsFilled(pRow.Hotel) Then
		vObj.Hotel = pRow.Hotel;
	Else
		vObj.Hotel = Hotel;
	EndIf;
	If pRow.DeletionMark Then
		vObj.DeletionMark = True;
	EndIf;
	
	If Not pRow.IsFolder Then
		vObj.DescriptionTranslations = pRow.DescriptionTranslations;
		vObj.Unit = pRow.Unit;
		vObj.UnitTranslations = pRow.UnitTranslations;
		vObj.Remarks = pRow.Remarks;
		vObj.ExternalCode = GetExternalCode(pRow);
		vObj.ServiceType = ServiceType;
		vObj.PaymentSection = PaymentSection;
		vObj.IsStockArticle = IsStockArticle;
		vObj.CashRegisterItemCode = TrimAll(pRow.ItemCode);
		
		If FillServiceItemsTabularSection Then
			FillServiceItemsRow(vObj, pRow, pDefaultCurrency);
		EndIf;
	EndIf;
	
	vObj.Write();
	pMap.Insert(pRow.Ref, vObj.Ref);
	
	If Not pRow.IsFolder Then
		WriteServicePrice(vObj.Ref, pRow, pDefaultCurrency);
		Return "Item";
	EndIf;
	
	Return "Folder";
EndFunction // TransferOneRow

// -----------------------------------------------------------------------------
Function GetMappedParent(pRow, pMap)
	If ValueIsFilled(pRow.Parent) Then
		vMapped = pMap.Get(pRow.Parent);
		If vMapped <> Undefined Then
			Return vMapped;
		EndIf;
	EndIf;
	If ValueIsFilled(ServiceFolder) Then
		Return ServiceFolder;
	EndIf;
	Return Catalogs.Services.EmptyRef();
EndFunction // GetMappedParent

// -----------------------------------------------------------------------------
Function GetExternalCode(pRow)
	vExternalCode = TrimAll(pRow.ExternalCode);
	If IsBlankString(vExternalCode) Then
		vExternalCode = String(pRow.Ref.UUID());
	EndIf;
	Return vExternalCode;
EndFunction // GetExternalCode

// -----------------------------------------------------------------------------
Function FindExistingFolder(pDescription, pParent)
	vQuery = New Query;
	vQuery.Text =
	"SELECT TOP 1
	|	Services.Ref AS Ref
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	Services.IsFolder
	|	AND Services.Description = &qDescription
	|	AND Services.Parent = &qParent";
	vQuery.SetParameter("qDescription", pDescription);
	vQuery.SetParameter("qParent", pParent);
	vSelection = vQuery.Execute().Select();
	If vSelection.Next() Then
		Return vSelection.Ref;
	EndIf;
	Return Catalogs.Services.EmptyRef();
EndFunction // FindExistingFolder

// -----------------------------------------------------------------------------
Procedure FillServiceCode(pObj, pSourceCode)
	vCodeNumber = Format(pSourceCode, "ND=6; NZ=000000; NLZ=; NG=");
	If ValueIsFilled(CodePrefix) Then
		vCode = Left(TrimAll(CodePrefix) + vCodeNumber, 11);
	Else
		vCode = vCodeNumber;
	EndIf;
	vExisting = Catalogs.Services.FindByCode(vCode);
	If ValueIsFilled(vExisting) Then
		pObj.SetNewCode();
	Else
		pObj.Code = vCode;
	EndIf;
EndProcedure // FillServiceCode

// -----------------------------------------------------------------------------
Procedure FillServiceItemsRow(pObj, pRow, pDefaultCurrency)
	vTSRow = pObj.ServiceItems.Add();
	vTSRow.ServiceItem = pRow.Ref;
	vTSRow.Output = pRow.Output;
	vTSRow.Price = pRow.Price;
	If ValueIsFilled(pRow.Currency) Then
		vTSRow.Currency = pRow.Currency;
	Else
		vTSRow.Currency = pDefaultCurrency;
	EndIf;
	If pRow.Quantity = 0 Then
		vTSRow.Quantity = 1;
	Else
		vTSRow.Quantity = pRow.Quantity;
	EndIf;
	vTSRow.Unit = pRow.Unit;
	vTSRow.Sum = vTSRow.Price * vTSRow.Quantity;
	vTSRow.CostPrice = pRow.CostPrice;
	vTSRow.CostSum = vTSRow.CostPrice * vTSRow.Quantity;
EndProcedure // FillServiceItemsRow

// -----------------------------------------------------------------------------
Procedure WriteServicePrice(pService, pRow, pDefaultCurrency)
	vServicePrice = InformationRegisters.ServicePrices.CreateRecordManager();
	vServicePrice.Hotel = Hotel;
	vServicePrice.Period = PriceDate;
	vServicePrice.Service = pService;
	vServicePrice.Price = pRow.Price;
	If ValueIsFilled(pRow.Currency) Then
		vServicePrice.Currency = pRow.Currency;
	Else
		vServicePrice.Currency = pDefaultCurrency;
	EndIf;
	vServicePrice.VATRate = VATRate;
	vServicePrice.Write();
EndProcedure // WriteServicePrice

#EndRegion
