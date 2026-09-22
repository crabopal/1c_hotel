// --------------------------------------------------------------------------------
&AtServer
Procedure DoCopyAtServer()
	If Not ValueIsFilled(Period) Then
		tcCommonFunctionOnClientServer.TextMessage("en='Period is not specified!'; de='Periode ist nicht angegeben!'; ru='Период не указан!'");
		Return;
	EndIf;
	// Select price records to copy
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	TransferPrices.Period AS Period,
	|	TransferPrices.Hotel AS Hotel,
	|	TransferPrices.TransferType AS TransferType,
	|	TransferPrices.Destination AS Destination,
	|	TransferPrices.ClientType AS ClientType,
	|	TransferPrices.Service AS Service,
	|	TransferPrices.Price AS Price,
	|	TransferPrices.Currency AS Currency
	|FROM
	|	InformationRegister.TransferPrices AS TransferPrices
	|WHERE
	|	TransferPrices.Period = &qPeriod
	|	AND (NOT &qHotelIsEmpty
	|				AND TransferPrices.Hotel = &qHotel
	|			OR &qHotelIsEmpty)
	|	AND (NOT &qTransferTypeIsEmpty
	|				AND TransferPrices.TransferType = &qTransferType
	|			OR &qTransferTypeIsEmpty)
	|	AND (NOT &qDestinationIsEmpty
	|				AND TransferPrices.Destination = &qDestination
	|			OR &qDestinationIsEmpty)
	|	AND (NOT &qServiceIsEmpty
	|				AND TransferPrices.Service = &qService
	|			OR &qServiceIsEmpty)
	|	AND (NOT &qClientTypeIsEmpty
	|				AND TransferPrices.ClientType = &qClientType
	|			OR &qClientTypeIsEmpty)";
	vQry.SetParameter("qPeriod", Period);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(Hotel));
	vQry.SetParameter("qTransferType", TransferType);
	vQry.SetParameter("qTransferTypeIsEmpty", Not ValueIsFilled(TransferType));
	vQry.SetParameter("qDestination", Destination);
	vQry.SetParameter("qDestinationIsEmpty", IsBlankString(Destination));
	vQry.SetParameter("qService", Service);
	vQry.SetParameter("qServiceIsEmpty", Not ValueIsFilled(Service));
	vQry.SetParameter("qClientType", ClientType);
	vQry.SetParameter("qClientTypeIsEmpty", Not CopyRecordsWithEmptyClientTypeOnly);
	vPriceRecords = vQry.Execute().Unload();
	For Each vPriceRecordsRow In vPriceRecords Do
		vMgr = InformationRegisters.TransferPrices.CreateRecordManager();
		vMgr.Period = ?(ValueIsFilled(PeriodNew), PeriodNew, vPriceRecordsRow.Period);
		vMgr.Hotel = ?(ValueIsFilled(HotelNew), HotelNew, vPriceRecordsRow.Hotel);
		vMgr.TransferType = ?(ValueIsFilled(TransferTypeNew), TransferTypeNew, vPriceRecordsRow.TransferType);
		vMgr.Destination = ?(IsBlankString(DestinationNew), vPriceRecordsRow.Destination, DestinationNew);
		vMgr.ClientType = ?(UseEmptyClientTypeForNewPrices, Catalogs.ClientTypes.EmptyRef(), ?(ValueIsFilled(ClientTypeNew), ClientTypeNew, vPriceRecordsRow.ClientType));
		vMgr.Service = ?(ValueIsFilled(ServiceNew), ServiceNew, vPriceRecordsRow.Service);
		vMgr.Price = ?(DoNotChangePrice, vPriceRecordsRow.Price, PriceNew);
		vMgr.Currency = vPriceRecordsRow.Currency;
		vMgr.Write(True);
	EndDo;
EndProcedure // DoCopyAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure DoCopy(pCommand)
	DoCopyAtServer();
	Notify("TransferPrices.Change");
	ShowMessageBox(, NStr("en='Completed!'; ru='Выполнено!'; de='Getan!'"));
EndProcedure // DoCopy

// --------------------------------------------------------------------------------
&AtClient
Procedure DoNotChangePriceOnChange(pItem)
	If DoNotChangePrice Then
		PriceNew = 0;
	EndIf;
	Items.PriceNew.Enabled = Not DoNotChangePrice;
EndProcedure // DoNotChangePriceOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure CopyRecordsWithEmptyClientTypeOnlyOnChange(pItem)
	If CopyRecordsWithEmptyClientTypeOnly Then
		ClientType = Undefined;
		Items.ClientType.InputHint = NStr("en='<empty>'; ru='<пустой>'; de='<leer>'");
	Else
		Items.ClientType.InputHint = NStr("en='<any if empty>'; ru='<любой, если пусто>'; de='<beliebig wenn leer>'");
	EndIf;
EndProcedure // CopyRecordsWithEmptyClientTypeOnlyOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure UseEmptyClientTypeForNewPricesOnChange(pItem)
	If UseEmptyClientTypeForNewPrices Then
		ClientTypeNew = Undefined;
		Items.ClientTypeNew.InputHint = NStr("en='<empty>'; ru='<пустой>'; de='<leer>'");
	Else
		Items.ClientTypeNew.InputHint = NStr("en='<do not change if empty>'; ru='<не изменять, если пусто>'; de='<nicht ändern, wenn leer>'");
	EndIf;
EndProcedure // UseEmptyClientTypeForNewPricesOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientTypeNewOnChange(pItem)
	If ValueIsFilled(ClientTypeNew) Then
		UseEmptyClientTypeForNewPrices = False;
	EndIf;
EndProcedure // ClientTypeNewOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ClientTypeOnChange(pItem)
	If ValueIsFilled(ClientType) Then
		CopyRecordsWithEmptyClientTypeOnly = False;
	EndIf;
EndProcedure // ClientTypeOnChange
