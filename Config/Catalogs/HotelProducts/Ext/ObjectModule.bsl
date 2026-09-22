 
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	// Clear product code and description
	If Not IsFolder Then
		Code = "";
		Description = "";
		ExternalCode = "";
		CreateDate = CurrentSessionDate();
		Author = SessionParameters.CurrentUser;
	EndIf;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not IsFolder Then
		// Deletion mark date and author
		If Not DeletionMark Then
			If ValueIsFilled(DeletionMarkDate) Then
				DeletionMarkDate = Undefined;
			EndIf;
			If ValueIsFilled(DeletionMarkAuthor) Then
				DeletionMarkAuthor = Catalogs.Employees.EmptyRef();
			EndIf;
		Else
			If Not ValueIsFilled(DeletionMarkDate) Then
				DeletionMarkDate = CurrentSessionDate();
			EndIf;
			If Not ValueIsFilled(DeletionMarkAuthor) Then
				DeletionMarkAuthor = SessionParameters.CurrentUser;
			EndIf;
		EndIf;
		// Create date
		If Not ValueIsFilled(CreateDate) Then
			CreateDate = CurrentSessionDate();
			Author = SessionParameters.CurrentUser;
		EndIf;
		// Payment date
		If Not ValueIsFilled(PaymentDate) Then
			vPaymentMethod = Undefined;
			PaymentDate = pmGetHotelProductPaymentDate(vPaymentMethod);
			If ValueIsFilled(vPaymentMethod) Then
				PaymentMethod = vPaymentMethod;
			EndIf;
		EndIf;
		// Client
		If Not FixedClient Then
			vClient = pmGetHotelProductClient();
			If ValueIsFilled(vClient) And vClient <> Client Then
				Client = vClient;
			EndIf;
		EndIf;
	Else
		If DeletionMark Then
			// Check user rights to edit form
			If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
				pCancel = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion  

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		If ValueIsFilled(RoomQuota) Then
			Hotel = RoomQuota.Hotel;
		Else
			Hotel = SessionParameters.CurrentHotel;
		EndIf;
	EndIf;
	If Not ValueIsFilled(Currency) Then
		If ValueIsFilled(Hotel) Then
			Currency = Hotel.FolioCurrency;
		EndIf;
	EndIf;
	If Not IsFolder Then
		If Not ValueIsFilled(CreateDate) Then
			CreateDate = CurrentSessionDate();
			Author = SessionParameters.CurrentUser;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmGetDefaultDescription() Export
	vDescription = ?(ValueIsFilled(RoomQuota), TrimAll(RoomQuota.Code) + " - ", "") 
					+ ?(ValueIsFilled(RoomType), TrimAll(RoomType.Code) + " ", "") 
					+ Format(CheckInDate, "DF='dd.MM.yy HH:mm'") + " - " 
					+ Format(CheckOutDate, "DF='dd.MM.yy HH:mm'");
	Return vDescription;
EndFunction // pmGetDefaultDescription

// -----------------------------------------------------------------------------
Function pmGetDefaultCode() Export
	vCode = ?(ValueIsFilled(RoomQuota), TrimAll(RoomQuota.Code) + "-", "") 
			+ ?(ValueIsFilled(RoomType), TrimAll(RoomType.Code) + "-", "") 
			+ Format(Year(CheckInDate) * 1000 + DayOfYear(CheckInDate), "ND=7; NFD=0; NZ=; NG=");
	Return vCode;
EndFunction // pmGetDefaultCode

// -----------------------------------------------------------------------------
Function pmCheckHotelProductAttributes(pMessage, pAttributeInErr) Export
	vHasErrors = False;
	pMessage = "";
	pAttributeInErr = "";
	vMsgTextRu = "";
	vMsgTextEn = "";
	If IsBlankString(Code) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Код> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Code> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Code", pAttributeInErr);
	EndIf;
	If IsBlankString(Description) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Наименование> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Description> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Description", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Гостиница> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If ValueIsFilled(CheckInDate) And ValueIsFilled(CheckOutDate) And
	   CheckOutDate <= CheckInDate Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Дата выезда> должен быть позже даты заезда!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Check-out date> attribute should be filled and after check-in date!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "CheckOutDate", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckHotelProductAttributes

// -----------------------------------------------------------------------------
// Calculates and returns duration for giving check in and check out dates
// -----------------------------------------------------------------------------
Function pmCalculateDuration() Export
	vDuration = 0;
	If ValueIsFilled(CheckInDate) And
	   ValueIsFilled(CheckOutDate) Then
		vReferenceHour = 0;
		vDurationCalculationRuleType = Undefined;
		vPeriodInHours = 24;   
		vOneHour = 3600;
		If ValueIsFilled(Parent) Then
			vDurationCalculationRuleType = Parent.DurationCalculationRuleType;
			vReferenceHour = Parent.ReferenceHour - BegOfDay(Parent.ReferenceHour);
		EndIf;
		If vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour And 
		   vReferenceHour = 0 Then
			vPerInSec = EndOfDay(CheckOutDate) - BegOfDay(CheckInDate);
			vDuration = Round(vPerInSec / vPeriodInHours / vOneHour, 0);
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			vPerInSec = (BegOfDay(CheckOutDate) + vReferenceHour) - (BegOfDay(CheckInDate) + vReferenceHour);
			vDuration = Round(vPerInSec / vPeriodInHours / vOneHour, 0);
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
			vPerInSec = EndOfDay(CheckOutDate) - BegOfDay(CheckInDate);
			vDuration = Round(vPerInSec / vPeriodInHours / vOneHour, 0);
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByNights Then
			vPerInSec = CheckOutDate - CheckInDate;
			vDuration = Round(vPerInSec / vPeriodInHours / vOneHour, 0);
		Else
			vPerInSec = CheckOutDate - CheckInDate;
			vDuration = Round(vPerInSec  /vPeriodInHours / vOneHour, 0);
		EndIf;
	EndIf;
	Return vDuration;
EndFunction // pmCalculateDuration

// -----------------------------------------------------------------------------
// Calculates and returns check out date based on giving duration and check in date
// -----------------------------------------------------------------------------
Function pmCalculateCheckOutDate() Export
	vCheckOutDate = CheckOutDate;
	If ValueIsFilled(CheckInDate) And Duration > 0 Then
		vReferenceHour = 0;
		vDurationCalculationRuleType = Undefined;
		vPeriodInHours = 24;  
		vOneHour = 3600;
		If ValueIsFilled(Parent) Then
			vDurationCalculationRuleType = Parent.DurationCalculationRuleType;
			vReferenceHour = Parent.ReferenceHour - BegOfDay(Parent.ReferenceHour);
		EndIf;
		If vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			If vReferenceHour = 0 Then
				vCheckOutDate = BegOfDay(CheckInDate) + vReferenceHour + Duration * vPeriodInHours * vOneHour - 1;
			Else
				vCheckOutDate = BegOfDay(CheckInDate) + vReferenceHour + Duration * vPeriodInHours * vOneHour;
			EndIf;
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
			vCheckOutDate = BegOfDay(CheckInDate) + Duration * vPeriodInHours * vOneHour - 3 * vOneHour;
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByNights Then
			vCheckInTime = CheckInDate - BegOfDay(CheckInDate);
			If vCheckInTime <= 9 * vOneHour Then // Breakfast check-in
				vCheckOutDate = BegOfDay(CheckInDate) + Duration * vPeriodInHours * vOneHour + 7 * vOneHour;
			ElsIf vCheckInTime <= 14 * vOneHour Then // Lunch check-in
				vCheckOutDate = BegOfDay(CheckInDate) + Duration * vPeriodInHours * vOneHour + 12 * vOneHour;
			ElsIf vCheckInTime <= 20 * vOneHour Then // Supper check-in
				vCheckOutDate = BegOfDay(CheckInDate) + Duration * vPeriodInHours * vOneHour + 18 * vOneHour;
			Else  // Late check-in
				vCheckOutDate = BegOfDay(CheckInDate) + Duration * vPeriodInHours * vOneHour + 21 * vOneHour;
			EndIf;
		Else
			vCheckOutDate = cm0SecondShift(CheckInDate + Duration * vPeriodInHours * vOneHour);
		EndIf;
	EndIf;
	Return vCheckOutDate;
EndFunction // pmCalculateDateTo

// -----------------------------------------------------------------------------
Function pmGetHotelProductDocuments() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Document,
	|	Accommodation.Customer AS Customer,
	|	Accommodation.Contract AS Contract,
	|	Accommodation.GuestGroup AS GuestGroup,
	|	Accommodation.CheckInDate AS CheckInDate,
	|	Accommodation.Duration AS Duration,
	|	Accommodation.CheckOutDate AS CheckOutDate,
	|	Accommodation.RoomType AS RoomType,
	|	Accommodation.Room AS Room,
	|	Accommodation.Guest AS Guest,
	|	Accommodation.PointInTime AS PointInTime,
	|	4 AS Priority
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.HotelProduct = &qHotelProduct
	|
	|UNION ALL
	|
	|SELECT
	|	Folio.Ref,
	|	Folio.Customer,
	|	Folio.Contract,
	|	Folio.GuestGroup,
	|	Folio.DateTimeFrom,
	|	0,
	|	Folio.DateTimeTo,
	|	Folio.Room.RoomType,
	|	Folio.Room,
	|	Folio.Client,
	|	Folio.PointInTime,
	|	3
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	Folio.HotelProduct = &qHotelProduct
	|
	|UNION ALL
	|
	|SELECT
	|	Reservation.Ref,
	|	Reservation.Customer,
	|	Reservation.Contract,
	|	Reservation.GuestGroup,
	|	Reservation.CheckInDate,
	|	Reservation.Duration,
	|	Reservation.CheckOutDate,
	|	Reservation.RoomType,
	|	Reservation.Room,
	|	Reservation.Guest,
	|	Reservation.PointInTime,
	|	2
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.Posted
	|	AND Reservation.HotelProduct = &qHotelProduct
	|	AND Reservation.ReservationStatus.IsActive
	|
	|UNION ALL
	|
	|SELECT
	|	Charge.Folio,
	|	Charge.Folio.Customer,
	|	Charge.Folio.Contract,
	|	Charge.Folio.GuestGroup,
	|	Charge.Folio.DateTimeFrom,
	|	0,
	|	Charge.Folio.DateTimeTo,
	|	Charge.Folio.Room.RoomType,
	|	Charge.Folio.Room,
	|	Charge.Folio.Client,
	|	Charge.PointInTime,
	|	1
	|FROM
	|	Document.Charge AS Charge
	|WHERE
	|	Charge.Posted
	|	AND Charge.HotelProduct = &qHotelProduct
	|	AND Charge.IsAdditional
	|
	|ORDER BY
	|	Priority,
	|	PointInTime";
	vQry.SetParameter("qHotelProduct", Ref);
	Return vQry.Execute().Unload();
EndFunction // pmGetHotelProductDocuments

// -----------------------------------------------------------------------------
Function pmGetHotelProductAmount() Export
	vAmount = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SalesTurnovers.HotelProduct AS HotelProduct,
	|	SUM(SalesTurnovers.Amount) AS Amount
	|FROM
	|	(SELECT
	|		HotelProductSalesTurnovers.HotelProduct AS HotelProduct,
	|		HotelProductSalesTurnovers.SalesTurnover AS Amount
	|	FROM
	|		AccumulationRegister.HotelProductSales.Turnovers(, , Period, HotelProduct = &qHotelProduct) AS HotelProductSalesTurnovers
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesForecastTurnovers.HotelProduct,
	|		SalesForecastTurnovers.SalesTurnover
	|	FROM
	|		AccumulationRegister.SalesForecast.Turnovers(&qForecastPeriodFrom, &qForecastPeriodTo, Period, HotelProduct = &qHotelProduct) AS SalesForecastTurnovers) AS SalesTurnovers
	|
	|GROUP BY
	|	SalesTurnovers.HotelProduct";
	vQry.SetParameter("qHotelProduct", Ref);
	vQry.SetParameter("qForecastPeriodFrom", tcOnServer.GetForecastStartDate(Hotel));
	vQry.SetParameter("qForecastPeriodTo", '39991231235959');
	vRes = vQry.Execute().Unload();
	For Each vResRow In vRes Do
		vAmount = vAmount + vResRow.Amount;
	EndDo;
	Return vAmount;
EndFunction // pmGetHotelProductAmount

// -----------------------------------------------------------------------------
Function pmGetHotelProductClient() Export
	vClient = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	HotelProductSalesTurnovers.HotelProduct AS HotelProduct,
	|	HotelProductSalesTurnovers.Client AS Client,
	|	HotelProductSalesTurnovers.SalesTurnover AS Amount
	|FROM
	|	AccumulationRegister.HotelProductSales.Turnovers(, , Period, HotelProduct = &qHotelProduct) AS HotelProductSalesTurnovers
	|
	|ORDER BY
	|	Amount DESC";
	vQry.SetParameter("qHotelProduct", Ref);
	vRes = vQry.Execute().Unload();
	For Each vResRow In vRes Do
		If ValueIsFilled(vResRow.Client) Then
			vClient = vResRow.Client;
		EndIf;
	EndDo;
	Return vClient;
EndFunction // pmGetHotelProductClient

// -----------------------------------------------------------------------------
Function pmGetHotelProductPaymentDate(rPaymentMethod) Export
	vPaymentDate = '00010101';
	rPaymentMethod = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	CASE
	|		WHEN HotelProductSales.Recorder.Folio IS NULL
	|			THEN HotelProductSales.Recorder.ParentCharge.Folio
	|		ELSE HotelProductSales.Recorder.Folio
	|	END AS Folio
	|INTO HotelProductFolios
	|FROM
	|	AccumulationRegister.HotelProductSales AS HotelProductSales
	|WHERE
	|	HotelProductSales.HotelProduct = &qHotelProduct
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DepositTransfers.FolioFrom AS Folio
	|INTO TransferFolios
	|FROM
	|	Document.DepositTransfer AS DepositTransfers
	|WHERE
	|	DepositTransfers.Posted
	|	AND DepositTransfers.FolioTo IN
	|			(SELECT
	|				HotelProductFolios.Folio
	|			FROM
	|				HotelProductFolios AS HotelProductFolios)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HotelProductFolios.Folio AS Folio
	|INTO BoundFolios
	|FROM
	|	HotelProductFolios AS HotelProductFolios
	|
	|UNION ALL
	|
	|SELECT
	|	TransferFolios.Folio
	|FROM
	|	TransferFolios AS TransferFolios
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Payments.Date AS PaymentDate,
	|	Payments.PaymentMethod AS PaymentMethod
	|FROM
	|	Document.Payment AS Payments
	|WHERE
	|	Payments.Posted
	|	AND Payments.Folio IN
	|			(SELECT
	|				BoundFolios.Folio
	|			FROM
	|				BoundFolios AS BoundFolios)
	|
	|ORDER BY
	|	PaymentDate DESC";
	vQry.SetParameter("qHotelProduct", Ref);
	vRes = vQry.Execute().Unload();
	For Each vResRow In vRes Do
		vPaymentDate = vResRow.PaymentDate;
		rPaymentMethod = vResRow.PaymentMethod;
		Break;
	EndDo;
	Return vPaymentDate;
EndFunction // pmGetHotelProductPaymentDate

#EndRegion
