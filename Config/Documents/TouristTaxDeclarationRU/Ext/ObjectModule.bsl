
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Post to tourist tax register
	PostToTouristTax();	
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	If pWriteMode = DocumentWriteMode.Posting Then
		// Check document attributes
		pCancel	= pmCheckDocumentAttributes(vMessage, vAttributeInErr);
		If pCancel Then
			WriteLogEvent(NStr("en = 'Document.DataValidation'; de = 'Document.DataValidation'; ru = 'Документ.КонтрольДанных'"), EventLogLevel.Warning, Metadata(), Ref, cmNStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Raise cmNStr(vMessage);
		Else
			// Fill tax total
			vTaxAmountToBePaid = Round(Reservations.Total("TaxAmountToBePaid"), 0, 1);
			If TaxAmountToBePaid <> vTaxAmountToBePaid Then
				TaxAmountToBePaid = vTaxAmountToBePaid;
			EndIf;
		EndIf;
	Else
		If Ref.Posted And pWriteMode = DocumentWriteMode.UndoPosting Or Not Ref.DeletionMark And Ref.Posted And DeletionMark Then
			If ValueIsFilled(Hotel) Then
				If ValueIsFilled(Hotel.EditProhibitedDate) And 
					BegOfDay(Hotel.EditProhibitedDate) >= BegOfDay(Date) Then
					pCancel = True;
				EndIf;
			EndIf;
			If ValueIsFilled(Company) Then
				If ValueIsFilled(Company.EditProhibitedDate) And 
					BegOfDay(Company.EditProhibitedDate) >= BegOfDay(Date) Then
					pCancel = True;
				EndIf;
			EndIf;
			vHasRightsToEditInvoice = cmHasRightsToEditInvoice(Company, Date, ExternalCode);
			If Not vHasRightsToEditInvoice Then
				pCancel = True;
			EndIf;  
			If pCancel Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights to edit document!'; de = 'Sie haben keine Rechte des Dokuments zu ändern!'; ru = 'Нет прав изменять документ!'"), MessageStatus.Attention);
			EndIf;
		EndIf;
		If Not Ref.DeletionMark And DeletionMark Then
			// User activity history   
			vEventDescription = NStr("en = 'Set document deletion mark'; de = 'Erstellung der Löschmarkierung'; ru = 'Установка отметки удаления'");    
			InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vEventDescription, Hotel);
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	// User activity history   
	vEventDescription = NStr("en = 'Document deletion'; de = 'Unmittelbare Löschung'; ru = 'Непосредственное удаление'");    
	InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vEventDescription, Hotel);
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Company) And Not IsBlankString(Company.Prefix) Then
		vPrefix = TrimAll(Company.Prefix);
	ElsIf ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		If ValueIsFilled(SessionParameters.CurrentHotel.Company) And Not IsBlankString(SessionParameters.CurrentHotel.Company.Prefix) Then
			vPrefix = TrimAll(SessionParameters.CurrentHotel.Company.Prefix);
		Else
			vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
		EndIf;
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	Date = CurrentSessionDate();
	Author = SessionParameters.CurrentUser;
	ExternalCode = "";
EndProcedure // OnCopy

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
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Das Attribut <Hotel> sollte ausgefüllt werden!!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Company) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Фирма> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Company> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Das Attribut <Kompanie> sollte ausgefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Company", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Currency) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Валюта> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Currency> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Das Attribut <Währung> sollte ausgefüllt werden!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "AccountingCurrency", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(DateFrom) Or 
	   Not ValueIsFilled(DateTo) Or 
	   ValueIsFilled(DateFrom) And ValueIsFilled(DateTo) And DateTo < DateFrom Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Неправильный период документа!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "Document period is wrong!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "Der Dokumentzeitraum ist falsch!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "DateFrom", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	Author = SessionParameters.CurrentUser;
EndProcedure // pmFillAuthorAndDate

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill author and document date
	pmFillAuthorAndDate();
	// Fill from session parameters
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(Currency) Then
			Currency = Hotel.BaseCurrency;
		EndIf;
		If Not ValueIsFilled(Company) Then
			Company = Hotel.Company;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure PostToTouristTax()
	RegisterRecords.TouristTaxToBePaid.Clear();

	For Each vReservationsRow In Reservations Do
		If ValueIsFilled(vReservationsRow.Reservation) Then
			vDoc = vReservationsRow.Reservation;
			If TypeOf(vDoc) = Type("DocumentRef.Accommodation") Then
				vDocReservation = vDoc.Reservation;
				If ValueIsFilled(vDocReservation) And vDocReservation.RoomQuantity = 1 And vDocReservation.CheckInDate < vDoc.CheckOutDate And vDocReservation.CheckOutDate > vDoc.CheckInDate Then
					vDoc = vDocReservation;
				EndIf;
			EndIf;
			
			If vReservationsRow.TaxAmountToBePaid <> 0 Or ValueIsFilled(vReservationsRow.TouristicTaxExemptionReason) Then
				vTTRcd = RegisterRecords.TouristTaxToBePaid.AddExpense();

				vTTRcd.Period = EndOfDay(DateTo);
				vTTRcd.Recorder = Ref;

				vTTRcd.Reservation = vDoc;
				vTTRcd.Hotel = Hotel;
				vTTRcd.Company = Company;

				vTTRcd.TaxAmount = vReservationsRow.TaxAmountToBePaid;
				If ValueIsFilled(vReservationsRow.TouristicTaxExemptionReason) Then
					vTTRcd.Exemption = 1;
				Else
					vTTRcd.Exemption = 0;
				EndIf;

				vTTRcd.RateAmount = vReservationsRow.RateAmount;
				vTTRcd.DurationInDays = vReservationsRow.DurationInDays;
				vTTRcd.TouristTaxRate = vReservationsRow.TouristTaxRate;
				vTTRcd.MinAmountPerDay = vReservationsRow.MinAmountPerDay;
			EndIf;
		EndIf;
	EndDo;
	
	RegisterRecords.TouristTaxToBePaid.Write = False;
	RegisterRecords.TouristTaxToBePaid.Write(True);
EndProcedure // PostToTouristTax

// -----------------------------------------------------------------------------
Procedure pmFillReservations() Export
	If IsSubmitted Then
		CorrectionNumber = CorrectionNumber + 1;
		IsSubmitted = False;
	EndIf;
	Reservations.Clear();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation.GuestGroup
	|		ELSE Accommodations.GuestGroup
	|	END AS GuestGroup,
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation
	|		ELSE Accommodations.Ref
	|	END AS Reservation,
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation.TouristicTaxAccountingDate
	|		ELSE Accommodations.TouristicTaxAccountingDate
	|	END AS TouristicTaxDate,
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation.CheckInDate
	|		ELSE Accommodations.CheckInDate
	|	END AS CheckInDate,
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation.CheckOutDate
	|		ELSE Accommodations.CheckOutDate
	|	END AS CheckOutDate,
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation.DurationInDays
	|		ELSE Accommodations.DurationInDays
	|	END AS DurationInDays,
	|	CASE
	|		WHEN CASE
	|					WHEN Accommodations.Ref IS NULL
	|						THEN TouristTaxToBePaidBalance.Reservation.TouristicTaxExemptionReason
	|					ELSE Accommodations.TouristicTaxExemptionReason
	|				END = VALUE(Catalog.ResortFeeExemptionReasons.EmptyRef)
	|				AND NOT CASE
	|						WHEN Accommodations.Ref IS NULL
	|							THEN TouristTaxToBePaidBalance.Reservation.RoomRate.IsStateContract
	|						ELSE Accommodations.RoomRate.IsStateContract
	|					END
	|				AND (TouristTaxToBePaidBalance.Hotel.TouristTaxService <> VALUE(Catalog.Services.EmptyRef)
	|					OR CASE
	|						WHEN Accommodations.Ref IS NULL
	|							THEN TouristTaxToBePaidBalance.Reservation.RoomRate.TouristTaxService
	|						ELSE Accommodations.RoomRate.TouristTaxService
	|					END <> VALUE(Catalog.Services.EmptyRef)
	|					OR TouristTaxToBePaidBalance.Hotel.TouristTaxAddToRate
	|					OR CASE
	|						WHEN Accommodations.Ref IS NULL
	|							THEN TouristTaxToBePaidBalance.Reservation.RoomRate.TouristTaxAddToRate
	|						ELSE Accommodations.RoomRate.TouristTaxAddToRate
	|					END)
	|			THEN CASE
	|					WHEN Accommodations.Ref IS NULL
	|						THEN TouristTaxToBePaidBalance.Reservation.RateSumInBaseCurrency + TouristTaxToBePaidBalance.Reservation.TouristTaxSumInBaseCurrency
	|					ELSE Accommodations.RateSumInBaseCurrency + Accommodations.TouristTaxSumInBaseCurrency
	|				END
	|		ELSE CASE
	|				WHEN Accommodations.Ref IS NULL
	|					THEN TouristTaxToBePaidBalance.Reservation.RateSumInBaseCurrency
	|				ELSE Accommodations.RateSumInBaseCurrency
	|			END
	|	END AS RateAmount,
	|	CASE
	|		WHEN TouristTaxToBePaidBalance.Hotel.TouristTaxService = VALUE(Catalog.Services.EmptyRef)
	|				AND CASE
	|					WHEN Accommodations.Ref IS NULL
	|						THEN TouristTaxToBePaidBalance.Reservation.RoomRate.TouristTaxService
	|					ELSE Accommodations.RoomRate.TouristTaxService
	|				END = VALUE(Catalog.Services.EmptyRef)
	|				AND NOT TouristTaxToBePaidBalance.Hotel.TouristTaxAddToRate
	|				AND NOT CASE
	|						WHEN Accommodations.Ref IS NULL
	|							THEN TouristTaxToBePaidBalance.Reservation.RoomRate.TouristTaxAddToRate
	|						ELSE Accommodations.RoomRate.TouristTaxAddToRate
	|					END
	|			THEN CASE
	|					WHEN Accommodations.Ref IS NULL
	|						THEN TouristTaxToBePaidBalance.Reservation.RateSumInBaseCurrency - TouristTaxToBePaidBalance.Reservation.TouristTaxSumInBaseCurrency
	|					ELSE Accommodations.RateSumInBaseCurrency - Accommodations.TouristTaxSumInBaseCurrency
	|				END
	|		ELSE CASE
	|				WHEN Accommodations.Ref IS NULL
	|					THEN TouristTaxToBePaidBalance.Reservation.RateSumInBaseCurrency
	|				ELSE Accommodations.RateSumInBaseCurrency
	|			END
	|	END AS TaxBaseAmount,
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation.TouristTaxRate
	|		ELSE Accommodations.TouristTaxRate
	|	END AS TouristTaxRate,
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation.MinAmountPerDay
	|		ELSE Accommodations.MinAmountPerDay
	|	END AS MinAmountPerDay,
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation.TouristicTaxIsByMinAmount
	|		ELSE Accommodations.TouristicTaxIsByMinAmount
	|	END AS TouristicTaxIsByMinAmount,
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation.TouristTaxSumInBaseCurrency
	|		ELSE Accommodations.TouristTaxSumInBaseCurrency
	|	END AS TaxAmount,
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN CASE
	|					WHEN TouristTaxToBePaidBalance.Reservation.TouristicTaxExemptionReason <> VALUE(Catalog.ResortFeeExemptionReasons.EmptyRef)
	|						THEN 0
	|					ELSE TouristTaxToBePaidBalance.Reservation.TouristTaxSumInBaseCurrency
	|				END - TouristTaxToBePaidBalance.TaxAmountBalance
	|		ELSE CASE
	|				WHEN Accommodations.TouristicTaxExemptionReason <> VALUE(Catalog.ResortFeeExemptionReasons.EmptyRef)
	|					THEN 0
	|				ELSE Accommodations.TouristTaxSumInBaseCurrency
	|			END - TouristTaxToBePaidBalance.TaxAmountBalance
	|	END AS PaidTaxAmount,
	|	TouristTaxToBePaidBalance.TaxAmountBalance AS TaxAmountToBePaid,
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation.TouristicTaxExemptionReason
	|		ELSE Accommodations.TouristicTaxExemptionReason
	|	END AS TouristicTaxExemptionReason,
	|	TouristTaxToBePaidBalance.ExemptionBalance AS ExemptionBalance
	|FROM
	|	AccumulationRegister.TouristTaxToBePaid.Balance(
	|			&qPeriodTo,
	|			Hotel = &qHotel
	|				AND Company = &qCompany) AS TouristTaxToBePaidBalance
	|		LEFT JOIN Document.Accommodation AS Accommodations
	|		ON (Accommodations.Reservation = TouristTaxToBePaidBalance.Reservation)
	|			AND (Accommodations.Posted)
	|			AND (Accommodations.AccommodationStatus.IsActive)
	|			AND (Accommodations.TouristTaxSumInBaseCurrency <> 0)
	|WHERE
	|	CASE
	|			WHEN Accommodations.Ref IS NULL
	|				THEN TouristTaxToBePaidBalance.Reservation.TouristicTaxAccountingDate
	|			ELSE Accommodations.TouristicTaxAccountingDate
	|		END <= &qPeriodTo
	|	AND CASE
	|			WHEN &qRoomParent = VALUE(Catalog.Rooms.EmptyRef)
	|				THEN TRUE
	|			ELSE CASE
	|					WHEN Accommodations.Ref IS NULL
	|						THEN TouristTaxToBePaidBalance.Reservation.Room IN HIERARCHY (&qRoomParent)
	|					ELSE Accommodations.Room IN HIERARCHY (&qRoomParent)
	|				END
	|		END
	|	AND CASE
	|			WHEN &qRoomTypeParent = VALUE(Catalog.RoomTypes.EmptyRef)
	|				THEN TRUE
	|			ELSE CASE
	|					WHEN Accommodations.Ref IS NULL
	|						THEN TouristTaxToBePaidBalance.Reservation.RoomType IN HIERARCHY (&qRoomTypeParent)
	|					ELSE Accommodations.RoomType IN HIERARCHY (&qRoomTypeParent)
	|				END
	|		END
	|
	|ORDER BY
	|	CASE
	|		WHEN Accommodations.Ref IS NULL
	|			THEN TouristTaxToBePaidBalance.Reservation.SortCode
	|		ELSE Accommodations.SortCode
	|	END";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);
	vQry.SetParameter("qPeriodTo", EndOfDay(DateTo));
	vQry.SetParameter("qRoomParent", ?(RoomParent = Undefined, Catalogs.Rooms.EmptyRef(), RoomParent));
	vQry.SetParameter("qRoomTypeParent", ?(RoomTypeParent = Undefined,  Catalogs.RoomTypes.EmptyRef(), RoomTypeParent));
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		vReservationsRow = Reservations.Add();
		FillPropertyValues(vReservationsRow, vDocsRow);
	EndDo;
EndProcedure // pmFillReservations

#EndRegion
