
#Region EventHandlers

// -----------------------------------------------------------------------------
// Get all RegisterRecords of the base document and make a strono RegisterRecords.
// "storno" movement is a movement with the same parameters and amounts but with opposite sign,
// i.e. if the base movement was Reciept 100 USD, the storno movement will be Reciept -100 USD.
// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	vCharges = New ValueList();
	If ValueIsFilled(ParentCharge) And ValueIsFilled(Hotel) And 
	   ParentCharge.IsMergedToRoomRevenue And Not ValueIsFilled(ParentCharge.RoomRevenueCharge) Then
		vRoomRateDocs = cmGetRoomRateTransactions(ParentCharge);
		If vRoomRateDocs.Count() = 0 Then
			vCharges.Add(ParentCharge);
		Else
			For Each vRoomRateDocsRow In vRoomRateDocs Do
				If TypeOf(vRoomRateDocsRow.Ref) = Type("DocumentRef.Charge") Then
					vStorno = Undefined;
					vChargeIsCanceled = cmIfChargeIsCanceled(vRoomRateDocsRow.Ref, vStorno);
					If vRoomRateDocsRow.Ref <> ParentCharge And vChargeIsCanceled And vStorno <> Ref Then
						Continue;
					EndIf;
					vCharges.Add(vRoomRateDocsRow.Ref);
				EndIf;
			EndDo;
		EndIf;
	Else
		vCharges.Add(ParentCharge);
	EndIf;
	
	// Change folio in the parent charge document
	For Each vChargesItem In vCharges Do
		vParentCharge = vChargesItem.Value;
		
		// Mark bounded charge as deleted
		If ValueIsFilled(vParentCharge.BoundCharge) And Not vParentCharge.IsFixedCharge Then
			vParentChargeObj = vParentCharge.GetObject();
			If vParentChargeObj.Posted Then
				vParentChargeObj.Write(DocumentWriteMode.UndoPosting);
			EndIf;
			If Not vParentChargeObj.DeletionMark Then
				vParentChargeObj.SetDeletionMark(True);
			EndIf;
			Return;
		EndIf;
		
		// Check if parent charge is posted
		vParentChargeObj = Undefined;
		vParentChargeIsMarkedForDeletion = False;
		If ValueIsFilled(vParentCharge) And vParentCharge.DeletionMark Then
			vParentChargeObj = vParentCharge.GetObject();
			vParentChargeObj.SetDeletionMark(False);
			vParentChargeObj.Write(DocumentWriteMode.Posting);
			vParentChargeIsMarkedForDeletion = True;
		EndIf;
		
		// Accounts
		StornoAccounts(vParentCharge);
		
		// Accumulating discount resources
		StornoAccumulatingDiscountResources(vParentCharge);
		
		// Current accounts receivable
		StornoCurrentAccountsReceivable(vParentCharge);
		
		// Sales
		StornoSales(vParentCharge);
		
		// Hotel product sales
		StornoHotelProductSales(vParentCharge);
		
		// Hotel product log
		StornoHotelProductLog(vParentCharge);
		
		// Payment services
		StornoPaymentServices(vParentCharge);
		
		// Service registration
		StornoServiceRegistration(vParentCharge);
		
		// FO postings
		StornoFOPostings(vParentCharge);
		
		// Mark parent charge as deleted if necessary
		If vParentChargeIsMarkedForDeletion And vParentChargeObj <> Undefined Then
			vParentChargeObj.SetDeletionMark(True);
		EndIf;
		
		// Mark bound resource reservaion document as deleted
		If ValueIsFilled(vParentCharge) Then
			If vParentCharge.IsAdditional And ValueIsFilled(vParentCharge.Service) And ValueIsFilled(vParentCharge.Service.Resource) And 
			   ValueIsFilled(vParentCharge.ParentDoc) And TypeOf(vParentCharge.ParentDoc) = Type("DocumentRef.ResourceReservation") And 
			   Not vParentCharge.ParentDoc.DoCharging And vParentCharge.ParentDoc.Posted Then
				vParentCharge.ParentDoc.GetObject().SetDeletionMark(True);
			EndIf;
		EndIf;   
		
		// Post to labeled goods
		StornoLabeledGoods(vParentCharge);
	EndDo;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure UndoPosting(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	pmUndoPosting(pCancel);
EndProcedure // UndoPosting

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Posted Then
		// Check if this storno is in closed day
		If ValueIsFilled(Hotel) And Hotel.DoNotEditClosedDateDocs Then
			vChargeIsInClosedDay = cmIfChargeIsInClosedDay(Ref);
			If vChargeIsInClosedDay Then
				pCancel = True;
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='This storno is in closed day! Storno is read only.';ru='Сторно в закрытом дне! Редактирование такого сторно запрещено.';de='Storno im abgeschlossenen Tag! Die Bearbeitung eines solchen Stornos ist verboten.'"), MessageStatus.Attention);
				Return;
			EndIf;
		EndIf;
		pmUndoPosting(pCancel);
	EndIf;
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("DocumentRef.Charge") Then
			ParentDoc = pBase.ParentDoc;
			ParentCharge = pBase;
			If ValueIsFilled(ParentCharge.Hotel) Then
				If Hotel <> ParentCharge.Hotel Then
					Hotel = ParentCharge.Hotel;
					SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		// Update service attribute if neccessary
		If ValueIsFilled(ParentCharge) Then
			If Service <> ParentCharge.Service Then
				Service = ParentCharge.Service;
			EndIf;
			If Price <> ParentCharge.Price Then
				Price = ParentCharge.Price;
			EndIf;
			If Unit <> ParentCharge.Unit Then
				Unit = ParentCharge.Unit;
			EndIf;
			If Quantity <> -ParentCharge.Quantity Then
				Quantity = -ParentCharge.Quantity;
			EndIf;
			If Sum <> -ParentCharge.Sum Then
				Sum = -ParentCharge.Sum;
			EndIf;
			If DiscountSum <> -ParentCharge.DiscountSum Then
				DiscountSum = -ParentCharge.DiscountSum;
			EndIf;
			If CommissionSum <> -ParentCharge.CommissionSum Then
				CommissionSum = -ParentCharge.CommissionSum;
			EndIf;
			If IsRoomRevenue <> ParentCharge.IsRoomRevenue Then
				IsRoomRevenue = ParentCharge.IsRoomRevenue;
			EndIf;
			If IsInPrice <> ParentCharge.IsInPrice Then
				IsInPrice = ParentCharge.IsInPrice;
			EndIf;
			If IsResourceRevenue <> ParentCharge.IsResourceRevenue Then
				IsResourceRevenue = ParentCharge.IsResourceRevenue;
			EndIf;
			If IsAdditional <> ParentCharge.IsAdditional Then
				IsAdditional = ParentCharge.IsAdditional;
			EndIf;
			If IsManual <> ParentCharge.IsManual Then
				IsManual = ParentCharge.IsManual;
			EndIf;
			If IsSplit <> ParentCharge.IsSplit Then
				IsSplit = ParentCharge.IsSplit;
			EndIf;
			If IsFixedCharge <> ParentCharge.IsFixedCharge Then
				IsFixedCharge = ParentCharge.IsFixedCharge;
			EndIf;
		EndIf;
		// Check document attributes
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise NStr(vMessage);
		EndIf;
	EndIf;
	// Check if this storno is in closed day
	If ValueIsFilled(Hotel) And Hotel.DoNotEditClosedDateDocs And 
	  (pWriteMode = DocumentWriteMode.Posting And Not Posted Or 
	   pWriteMode = DocumentWriteMode.UndoPosting And Posted Or 
	   pWriteMode = DocumentWriteMode.Posting And ValueIsFilled(Ref) And Ref.ParentCharge <> ParentCharge) Then
		vChargeIsInClosedDay = cmIfChargeIsInClosedDay(ThisObject);
		If vChargeIsInClosedDay Then
			pCancel = True;
			If IsNew() Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Day is closed! You can not post sorno to this day.';ru='День закрыт! Проводить сторно этой датой запрещено.';de='Der Tag ist geschlossen! Ein Storno zu diesem Datum ist verboten.'"), MessageStatus.Attention);
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='This storno is in closed day! Storno is read only.';ru='Сторно в закрытом дне! Редактирование такого сторно запрещено.';de='Storno im abgeschlossenen Tag! Die Bearbeitung eines solchen Stornos ist verboten.'"), MessageStatus.Attention);
			EndIf;
			Return;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// Write log event
	If Not DeletionMark Then
		// User activity history   
		vEventDescription = StrTemplate(NStr("en = 'Storno charge: %1, %2, %3'; 
											 |de = 'Stornierung der Berechnung: %1, %2, %3'; 
											 |ru = 'Сторно начисления: %1, %2, %3'"), TrimAll(ParentCharge), cmFormatSum(Sum, ParentCharge.FolioCurrency), TrimAll(Ref));  
		vParentDoc = Ref;
		If ValueIsFilled(ParentDoc) Then
			vParentDoc = ParentDoc;
		EndIf;	
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(vParentDoc, vEventDescription, Hotel);
	EndIf; 
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function pmCheckDocumentAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	vMsgTextDe = "";
	If AdditionalProperties.Property("InfoBaseUpdateMode") And AdditionalProperties.InfoBaseUpdateMode Then
		Return vHasErrors;
	EndIf;
	// Check that charge is choosen
	If Not ValueIsFilled(ParentCharge) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Начисление> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Parent charge> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Parent charge> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "ParentCharge", pAttributeInErr);
	Else
		If ValueIsFilled(ParentCharge.Folio) Then
			If ParentCharge.Folio.DeletionMark Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "<Лицевой счет> помечен на удаление!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "<Folio> is marked for deletion!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "<Folio> is marked for deletion!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "ParentCharge", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	// Check that there is no other storno for the charge choosen
	If ValueIsFilled(ParentCharge) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Storno.Ref
		|FROM
		|	Document.Storno AS Storno
		|WHERE
		|	Storno.Posted
		|	AND Storno.ParentCharge = &qParentCharge
		|	AND Storno.Ref <> &qStorno";
		vQry.SetParameter("qParentCharge", ParentCharge);
		vQry.SetParameter("qStorno", Ref);
		vQryRes = vQry.Execute().Unload();
		If vQryRes.Count() > 0 Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "По выбранному начислению уже есть сторно!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "There is another storno operation for the charge choosen!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "There is another storno operation for the charge choosen!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "ParentCharge", pAttributeInErr);
		EndIf;			
	EndIf;
	If Not Posted Then
		// Check user rights to do storno
		vEmployee = SessionParameters.CurrentUser;
		If ValueIsFilled(vEmployee) And ValueIsFilled(vEmployee.PermissionGroup) And ValueIsFilled(ParentCharge) And ValueIsFilled(ParentCharge.Folio) Then
			vPermissionGroup = vEmployee.PermissionGroup;
			vFolio = ParentCharge.Folio;
			For Each vPrmRow In vPermissionGroup.FolioOperationsAllowed Do
				If IsBlankString(vPrmRow.FolioType) Or 
				   Not IsBlankString(vPrmRow.FolioType) And TrimR(vPrmRow.FolioType) = Left(TrimR(vFolio.Description), StrLen(TrimR(vPrmRow.FolioType))) Then
					If vPrmRow.StornoForbidden Then
						vHasErrors = True;
						vMsgTextRu = vMsgTextRu + "Нет прав на сторнирование услуг по фолио с типом " + TrimAll(vFolio.Description) + "!" + Chars.LF;
						vMsgTextEn = vMsgTextEn + "You do not have rights to storno charges in folio type " + TrimAll(vFolio.Description) + "!" + Chars.LF;
						vMsgTextDe = vMsgTextDe + "Sie haben keine Rechte für Storno in Folio-typ " + TrimAll(vFolio.Description) + " nutzen!" + Chars.LF;
						pAttributeInErr = ?(pAttributeInErr = "", "Folio", pAttributeInErr);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // CheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	Hotel = SessionParameters.CurrentHotel;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmUndoPosting(pCancel)
	vCharges = New ValueList();
	If ValueIsFilled(ParentCharge) And ValueIsFilled(Hotel) And 
	   ParentCharge.IsMergedToRoomRevenue And Not ValueIsFilled(ParentCharge.RoomRevenueCharge) Then
		vRoomRateDocs = cmGetRoomRateTransactions(ParentCharge);
		If vRoomRateDocs.Count() = 0 Then
			vCharges.Add(ParentCharge);
		Else
			For Each vRoomRateDocsRow In vRoomRateDocs Do
				If TypeOf(vRoomRateDocsRow.Ref) = Type("DocumentRef.Charge") And 
				  (vRoomRateDocsRow.Ref = ParentCharge OR vRoomRateDocsRow.Ref <> ParentCharge AND NOT cmIfChargeIsCanceled(vRoomRateDocsRow.Ref)) Then
					vCharges.Add(vRoomRateDocsRow.Ref);
				EndIf;
			EndDo;
		EndIf;
	Else
		vCharges.Add(ParentCharge);
	EndIf;
	
	For Each vChargesItem In vCharges Do
		vParentCharge = vChargesItem.Value;

		// Repost charge
		If ValueIsFilled(vParentCharge) And ValueIsFilled(vParentCharge.BoundCharge) And Not vParentCharge.IsFixedCharge Then
			vChargeObj = vParentCharge.GetObject();
			If vChargeObj.DeletionMark Then
				vChargeObj.SetDeletionMark(False);
			EndIf;
			If Not vChargeObj.Posted Then
				vChargeObj.Write(DocumentWriteMode.Posting);
			EndIf;
		EndIf;

		// Repost parent resource reservation
		If ValueIsFilled(vParentCharge) Then
			If vParentCharge.IsAdditional And ValueIsFilled(vParentCharge.Service) And ValueIsFilled(vParentCharge.Service.Resource) And 
			   ValueIsFilled(vParentCharge.ParentDoc) And TypeOf(vParentCharge.ParentDoc) = Type("DocumentRef.ResourceReservation") And 
			   Not vParentCharge.ParentDoc.DoCharging And Not vParentCharge.ParentDoc.Posted Then
				vParentDocObj = vParentCharge.ParentDoc.GetObject();
				If vParentCharge.ParentDoc.DeletionMark Then
					vParentDocObj.SetDeletionMark(False);
				EndIf;
				vParentDocObj.Write(DocumentWriteMode.Posting);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // pmUndoPosting

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure StornoAccounts(pParentCharge)
	vParentMovements = AccumulationRegisters.Accounts.SelectByRecorder(pParentCharge);
	While vParentMovements.Next() Do
		vStornoMovements = RegisterRecords.Accounts.Add();
		FillPropertyValues(vStornoMovements, vParentMovements);
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) > BegOfDay(Date) Then
			vStornoMovements.Period = pParentCharge.Date
		Else
			vStornoMovements.Period = Date;
		EndIf;
		vStornoMovements.Author = Author;
		vStornoMovements.Sum = -vParentMovements.Sum;
		vStornoMovements.VATSum = -vParentMovements.VATSum;
		vStornoMovements.Quantity = -vParentMovements.Quantity;
		vStornoMovements.ChequeServiceQuantity = -vParentMovements.ChequeServiceQuantity;
		vStornoMovements.Remarks = NStr("en='Storno';ru='Сторно';de='Storno'") + 
		                           ?(IsBlankString(vParentMovements.Remarks), "", " - " + TrimAll(vParentMovements.Remarks));
	EndDo;
	RegisterRecords.Accounts.Write();
EndProcedure // StornoAccounts

// -----------------------------------------------------------------------------
Procedure StornoAccumulatingDiscountResources(pParentCharge)
	vParentMovements = AccumulationRegisters.AccumulatingDiscountResources.SelectByRecorder(pParentCharge);
	While vParentMovements.Next() Do
		vStornoMovements = RegisterRecords.AccumulatingDiscountResources.Add();
		FillPropertyValues(vStornoMovements, vParentMovements);
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) > BegOfDay(Date) Then
			vStornoMovements.Period = pParentCharge.Date
		Else
			vStornoMovements.Period = Date;
		EndIf;
		vStornoMovements.Resource = -vParentMovements.Resource;
		vStornoMovements.Bonus = -vParentMovements.Bonus;
	EndDo;
	RegisterRecords.AccumulatingDiscountResources.Write();
EndProcedure // StornoAccumulatingDiscountResources

// -----------------------------------------------------------------------------
Procedure StornoCurrentAccountsReceivable(pParentCharge)
	vParentMovements = AccumulationRegisters.CurrentAccountsReceivable.SelectByRecorder(pParentCharge);
	While vParentMovements.Next() Do
		vStornoMovements = RegisterRecords.CurrentAccountsReceivable.Add();
		FillPropertyValues(vStornoMovements, vParentMovements);
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) > BegOfDay(Date) Then
			vStornoMovements.Period = pParentCharge.Date
		Else
			vStornoMovements.Period = Date;
		EndIf;
		vStornoMovements.Charge = pParentCharge;
		vStornoMovements.Sum = -vParentMovements.Sum;
		vStornoMovements.VATSum = -vParentMovements.VATSum;
		vStornoMovements.Quantity = -vParentMovements.Quantity;
		vStornoMovements.CommissionSum = -vParentMovements.CommissionSum;
	EndDo;
	RegisterRecords.CurrentAccountsReceivable.Write();
EndProcedure // StornoCurrentAccountsReceivable

// -----------------------------------------------------------------------------
Procedure StornoPaymentServices(pParentCharge)
	vParentMovements = AccumulationRegisters.PaymentServices.SelectByRecorder(pParentCharge);
	While vParentMovements.Next() Do
		vStornoMovements = RegisterRecords.PaymentServices.Add();
		FillPropertyValues(vStornoMovements, vParentMovements);
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) > BegOfDay(Date) Then
			vStornoMovements.Period = pParentCharge.Date
		Else
			vStornoMovements.Period = Date;
		EndIf;
		vStornoMovements.Sum = -vParentMovements.Sum;
	EndDo;
	RegisterRecords.PaymentServices.Write();
EndProcedure // StornoPaymentServices

// -----------------------------------------------------------------------------
Procedure StornoSales(pParentCharge)
	vParentMovements = AccumulationRegisters.Sales.SelectByRecorder(pParentCharge);
	While vParentMovements.Next() Do
		vStornoMovements = RegisterRecords.Sales.Add();
		
		FillPropertyValues(vStornoMovements, vParentMovements, , "RecordType, Recorder");
		
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) > BegOfDay(Date) Then
			vStornoMovements.Period = pParentCharge.Date;
			vStornoMovements.AccountingDate = BegOfDay(pParentCharge.Date);
		Else
			vStornoMovements.Period = Date;
			vStornoMovements.AccountingDate = BegOfDay(Date);
		EndIf;
		vStornoMovements.Author = Author;
		vStornoMovements.IsStorno = True;
		
		vStornoMovements.Sales = -vParentMovements.Sales;
		vStornoMovements.SalesWithoutVAT = -vParentMovements.SalesWithoutVAT;
		vStornoMovements.VATSum = -vParentMovements.VATSum;
		vStornoMovements.RoomRevenue = -vParentMovements.RoomRevenue;
		vStornoMovements.RoomRevenueWithoutVAT = -vParentMovements.RoomRevenueWithoutVAT;
		vStornoMovements.ExtraBedRevenue = -vParentMovements.ExtraBedRevenue;
		vStornoMovements.ExtraBedRevenueWithoutVAT = -vParentMovements.ExtraBedRevenueWithoutVAT;
		vStornoMovements.CommissionSum = -vParentMovements.CommissionSum;
		vStornoMovements.CommissionSumWithoutVAT = -vParentMovements.CommissionSumWithoutVAT;
		vStornoMovements.DiscountSum = -vParentMovements.DiscountSum;
		vStornoMovements.DiscountSumWithoutVAT = -vParentMovements.DiscountSumWithoutVAT;

		vStornoMovements.Quantity = -vParentMovements.Quantity;
		
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) < BegOfDay(Date) Then
			vStornoMovements.RoomsRented = 0;
			vStornoMovements.BedsRented = 0;
			vStornoMovements.AdditionalBedsRented = 0;
			vStornoMovements.GuestDays = 0;
			vStornoMovements.GuestsCheckedIn = 0;
			vStornoMovements.RoomsCheckedIn = 0;
			vStornoMovements.BedsCheckedIn = 0;
			vStornoMovements.AdditionalBedsCheckedIn = 0;
		Else
			vStornoMovements.RoomsRented = -vParentMovements.RoomsRented;
			vStornoMovements.BedsRented = -vParentMovements.BedsRented;
			vStornoMovements.AdditionalBedsRented = -vParentMovements.AdditionalBedsRented;
			vStornoMovements.GuestDays = -vParentMovements.GuestDays;
			vStornoMovements.GuestsCheckedIn = -vParentMovements.GuestsCheckedIn;
			vStornoMovements.RoomsCheckedIn = -vParentMovements.RoomsCheckedIn;
			vStornoMovements.BedsCheckedIn = -vParentMovements.BedsCheckedIn;
			vStornoMovements.AdditionalBedsCheckedIn = -vParentMovements.AdditionalBedsCheckedIn;
		EndIf;
		
		vStornoMovements.HoursRented = -vParentMovements.HoursRented;
		vStornoMovements.ResourceRevenue = -vParentMovements.ResourceRevenue;
		vStornoMovements.ResourceRevenueWithoutVAT = -vParentMovements.ResourceRevenueWithoutVAT;
	EndDo;
	RegisterRecords.Sales.Write();
EndProcedure // StornoSales

// -----------------------------------------------------------------------------
Procedure StornoHotelProductSales(pParentCharge)
	vParentMovements = AccumulationRegisters.HotelProductSales.SelectByRecorder(pParentCharge);
	While vParentMovements.Next() Do
		vStornoMovements = RegisterRecords.HotelProductSales.Add();
		
		FillPropertyValues(vStornoMovements, vParentMovements, , "RecordType, Recorder");
		
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) > BegOfDay(Date) Then
			vStornoMovements.Period = pParentCharge.Date;
			vStornoMovements.AccountingDate = BegOfDay(pParentCharge.Date);
		Else
			vStornoMovements.Period = Date;
			vStornoMovements.AccountingDate = BegOfDay(Date);
		EndIf;
		vStornoMovements.IsStorno = True;
		
		vStornoMovements.Sales = -vParentMovements.Sales;
		vStornoMovements.SalesWithoutVAT = -vParentMovements.SalesWithoutVAT;
		vStornoMovements.RoomRevenue = -vParentMovements.RoomRevenue;
		vStornoMovements.RoomRevenueWithoutVAT = -vParentMovements.RoomRevenueWithoutVAT;
		vStornoMovements.ExtraBedRevenue = -vParentMovements.ExtraBedRevenue;
		vStornoMovements.ExtraBedRevenueWithoutVAT = -vParentMovements.ExtraBedRevenueWithoutVAT;
		vStornoMovements.CommissionSum = -vParentMovements.CommissionSum;
		vStornoMovements.CommissionSumWithoutVAT = -vParentMovements.CommissionSumWithoutVAT;
		vStornoMovements.DiscountSum = -vParentMovements.DiscountSum;
		vStornoMovements.DiscountSumWithoutVAT = -vParentMovements.DiscountSumWithoutVAT;

		vStornoMovements.Quantity = -vParentMovements.Quantity;
		
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) < BegOfDay(Date) Then
			vStornoMovements.RoomsRented = 0;
			vStornoMovements.BedsRented = 0;
			vStornoMovements.AdditionalBedsRented = 0;
			vStornoMovements.GuestDays = 0;
			vStornoMovements.GuestsCheckedIn = 0;
			vStornoMovements.RoomsCheckedIn = 0;
			vStornoMovements.BedsCheckedIn = 0;
			vStornoMovements.AdditionalBedsCheckedIn = 0;
		Else
			vStornoMovements.RoomsRented = -vParentMovements.RoomsRented;
			vStornoMovements.BedsRented = -vParentMovements.BedsRented;
			vStornoMovements.AdditionalBedsRented = -vParentMovements.AdditionalBedsRented;
			vStornoMovements.GuestDays = -vParentMovements.GuestDays;
			vStornoMovements.GuestsCheckedIn = -vParentMovements.GuestsCheckedIn;
			vStornoMovements.RoomsCheckedIn = -vParentMovements.RoomsCheckedIn;
			vStornoMovements.BedsCheckedIn = -vParentMovements.BedsCheckedIn;
			vStornoMovements.AdditionalBedsCheckedIn = -vParentMovements.AdditionalBedsCheckedIn;
		EndIf;
	EndDo;
	RegisterRecords.HotelProductSales.Write();
EndProcedure // StornoHotelProductSales

// -----------------------------------------------------------------------------
Procedure StornoHotelProductLog(pParentCharge)
	vParentMovements = AccumulationRegisters.HotelProductLog.SelectByRecorder(pParentCharge);
	While vParentMovements.Next() Do
		vStornoMovements = RegisterRecords.HotelProductLog.AddReceipt();
		
		FillPropertyValues(vStornoMovements, vParentMovements, , "RecordType, Recorder");
		
		vStornoMovements.Sum = -vParentMovements.Sum;
	EndDo;
	RegisterRecords.HotelProductLog.Write();
EndProcedure // StornoHotelProductLog

// -----------------------------------------------------------------------------
Procedure StornoServiceRegistration(pParentCharge)
	vParentMovements = AccumulationRegisters.ServiceRegistration.SelectByRecorder(pParentCharge);
	While vParentMovements.Next() Do
		vStornoMovements = RegisterRecords.ServiceRegistration.Add();
		FillPropertyValues(vStornoMovements, vParentMovements);
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) > BegOfDay(Date) Then
			vStornoMovements.Period = pParentCharge.Date;
		Else
			vStornoMovements.Period = Date;
		EndIf;
		vStornoMovements.Author = Author;
		vStornoMovements.Sum = -vParentMovements.Sum;
		vStornoMovements.Quantity = -vParentMovements.Quantity;
		vStornoMovements.Remarks = NStr("en='Storno';ru='Сторно';de='Storno'") + 
		                           ?(IsBlankString(vParentMovements.Remarks), "", " - " + TrimAll(vParentMovements.Remarks));
	EndDo;
	RegisterRecords.ServiceRegistration.Write();
EndProcedure // StornoServiceRegistration

// -----------------------------------------------------------------------------
Procedure StornoFOPostings(pParentCharge)
	vParentMovements = AccountingRegisters.PostingsFO.SelectByRecorder(pParentCharge);
	While vParentMovements.Next() Do
		If vParentMovements.RecordType = AccountingRecordType.Debit Then
			vStornoMovements = RegisterRecords.PostingsFO.AddDebit();
		Else
			vStornoMovements = RegisterRecords.PostingsFO.AddCredit();
		EndIf;
		
		FillPropertyValues(vStornoMovements, vParentMovements, , "RecordType, Recorder");
		
		If vParentMovements.Account = ChartsOfAccounts.ChartOfAccountsFO.GuestLedger Then
			vStornoMovements.ExtDimensions.Folio = vParentMovements.ExtDimensions.Folio;
		EndIf;
		
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) > BegOfDay(Date) Then
			vStornoMovements.Period = BegOfDay(pParentCharge.Date);
			vStornoMovements.FODate = BegOfDay(pParentCharge.Date);
		Else
			vStornoMovements.Period = BegOfDay(Date);
			vStornoMovements.FODate = BegOfDay(Date);
		EndIf;
		vStornoMovements.Author = Author;
		
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) < BegOfDay(Date) And 
		   ValueIsFilled(vStornoMovements.Account) And ValueIsFilled(vStornoMovements.Account.ComplimentaryExpensesAccount) Then
			If vStornoMovements.Account.Type = vStornoMovements.Account.ComplimentaryExpensesAccount.Type Then
				vStornoMovements.Amount = -vStornoMovements.Amount;
				vStornoMovements.GrosAmount = -vStornoMovements.GrosAmount;
				vStornoMovements.DiscountAmount = -vStornoMovements.DiscountAmount;
				vStornoMovements.VATAmount = -vStornoMovements.VATAmount;
			Else
				If vStornoMovements.RecordType = AccountingRecordType.Credit Then
					vStornoMovements.RecordType = AccountingRecordType.Debit;
				Else
					vStornoMovements.RecordType = AccountingRecordType.Credit;
				EndIf;
				
				vStornoMovements.Amount = vStornoMovements.Amount;
				vStornoMovements.GrosAmount = vStornoMovements.GrosAmount;
				vStornoMovements.DiscountAmount = vStornoMovements.DiscountAmount;
				vStornoMovements.VATAmount = vStornoMovements.VATAmount;
			EndIf;

			vStornoMovements.Account = vStornoMovements.Account.ComplimentaryExpensesAccount;
			vStornoMovements.AccountGroup = vStornoMovements.Account.AccountGroup;
			vStornoMovements.AccountType = vStornoMovements.Account.AccountType;
		Else
			vStornoMovements.Amount = -vStornoMovements.Amount;
			vStornoMovements.GrosAmount = -vStornoMovements.GrosAmount;
			vStornoMovements.DiscountAmount = -vStornoMovements.DiscountAmount;
			vStornoMovements.VATAmount = -vStornoMovements.VATAmount;
		EndIf;
	EndDo;
	RegisterRecords.PostingsFO.Write();
EndProcedure // StornoFOPostings

// -----------------------------------------------------------------------------
Procedure StornoLabeledGoods(pParentCharge)      
	RegisterRecords.LabeledGoods.Clear();
	If ValueIsFilled(pParentCharge) And Not IsBlankString(pParentCharge.MarkingCode) Then
		Movement = RegisterRecords.LabeledGoods.Add();
		FillPropertyValues(Movement, pParentCharge);
		Movement.RecordType = AccumulationRecordType.Expense;
		If ValueIsFilled(pParentCharge) And BegOfDay(pParentCharge.Date) > BegOfDay(Date) Then
			Movement.Period = pParentCharge.Date
		Else
			Movement.Period = Date;
		EndIf;  
		
		RegisterRecords.LabeledGoods.Write = True;  
	EndIf;
EndProcedure // PostToPaymentServices

#EndRegion
