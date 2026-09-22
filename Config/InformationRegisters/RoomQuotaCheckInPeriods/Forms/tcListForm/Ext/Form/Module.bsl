
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("RoomQuota") Then	
		Items.SelRoomQuota.Visible = False;
		SelRoomQuota = Parameters.RoomQuota;
		SelRoomQuotaOnChangeAtServer();
	EndIf;	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodFromOnChange(Item)
	SelPeriodFromOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelPeriodToOnChange(Item)
	SelPeriodToOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(Item)
	SelHotelOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomQuotaOnChange(Item)
	SelRoomQuotaOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckInDateOnChange(Item)
	vCurData = Items.List.CurrentData;
	If vCurData <> Undefined Then
		vCurData.Duration = CalculateDuration(vCurData.RoomQuota.RoomRate, vCurData.CheckInDate, vCurData.CheckOutDate);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationOnChange(Item)
	vCurData = Items.List.CurrentData;
	If vCurData <> Undefined Then
		vCurData.CheckOutDate = CalculateCheckOutDate(vCurData.RoomQuota.RoomRate, vCurData.CheckInDate, vCurData.Duration, vCurData.CheckOutDate);
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelNumberOfDaysOnChange(Item)
	SelNumberOfDaysOnChangeAtServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure FillWizard(Command)
	If Items.List.CurrentData <> Undefined Then
		vParams = New Structure;	
		vParams.Insert("Hotel"        , Items.List.CurrentData.Hotel);
		vParams.Insert("RoomQuota"    , Items.List.CurrentData.RoomQuota);
		vParams.Insert("CheckInDate"  , Items.List.CurrentData.CheckInDate);
		vParams.Insert("Duration"     , Items.List.CurrentData.Duration);
		vParams.Insert("CheckOutDate" , Items.List.CurrentData.CheckOutDate);
		OpenForm("InformationRegister.RoomQuotaCheckInPeriods.Form.tcFillWizardForm", vParams, ThisObject);
	Else
		OpenForm("InformationRegister.RoomQuotaCheckInPeriods.Form.tcFillWizardForm", , ThisObject);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Create(Command)
OpenForm("InformationRegister.RoomQuotaCheckInPeriods.Form.tcRecordForm", 
			New Structure("CheckInDate, CheckOutDate, Duration, RoomQuota, Hotel", 
			SelPeriodFrom, SelPeriodTo, SelNumberOfDays, SelRoomQuota, SelHotel), ThisObject);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	vFilter =  List.Filter;
	vValue = New DataCompositionField(pAttribute);
	vDelList = New Array;
	For Each int In vFilter.Items Do
		If int.LeftValue = vValue Then
			vDelList.Add(int);			
		EndIf;	
	EndDo;
	For Each int In vDelList Do
		vFilter.Items.Delete(int);	
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined, pAddNew = False)
	vValue = pValue;	
	vComparisonType =  ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
	
	If ValueIsFilled(vValue) Then
		vFilter = List.Filter;
		vField = New DataCompositionField(pAttribute);
		
		If vFilter.Items.Count() = 0 Then	
			vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
			vFilterItem.LeftValue = vField;
			vFilterItem.ComparisonType = vComparisonType;
			vFilterItem.RightValue = vValue;
			vFilterItem.Use = True;
		Else
			If pAddNew Then
				vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
				vFilterItem.LeftValue      = vField;
				vFilterItem.ComparisonType = vComparisonType;
				vFilterItem.RightValue     = vValue;
				vFilterItem.Use            = True;
				
			Else
				// Find field
				vCancel = False;
				For Each int In  vFilter.Items Do
					If  int.LeftValue = vField  Then
						// Field delete
						vFilter.Items.Delete(int);	
						// Add a new
						vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
						vFilterItem.LeftValue      = vField;
						vFilterItem.ComparisonType = vComparisonType;
						vFilterItem.RightValue     = vValue;
						vFilterItem.Use            = True;
						vCancel                    = True;
						Break;
					EndIf;	
				EndDo;
				If Not vCancel Then
					// The field is not found, we add a new
					vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
					vFilterItem.LeftValue      = vField;
					vFilterItem.ComparisonType = vComparisonType;
					vFilterItem.RightValue     = vValue;
					vFilterItem.Use            = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelPeriodFromOnChangeAtServer()
	If ValueIsFilled(SelPeriodFrom) Then
		AttributeChangeAtServer("CheckInDate", BegOfDay(SelPeriodFrom), DataCompositionComparisonType.GreaterOrEqual);
	Else
		ClearingAttributeAtServer("CheckInDate");	
	EndIf;		
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelPeriodToOnChangeAtServer()
	If ValueIsFilled(SelPeriodTo) Then	
		AttributeChangeAtServer("CheckOutDate", EndOfDay(SelPeriodTo), DataCompositionComparisonType.LessOrEqual);
	Else
		ClearingAttributeAtServer("CheckOutDate");
	EndIf;		
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelHotelOnChangeAtServer()
	If ValueIsFilled(SelHotel) Then	
		AttributeChangeAtServer("Hotel", SelHotel);
	Else
		ClearingAttributeAtServer("Hotel");
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure SelRoomQuotaOnChangeAtServer()
	If ValueIsFilled(SelRoomQuota) Then	
		AttributeChangeAtServer("RoomQuota", SelRoomQuota);
	Else
		ClearingAttributeAtServer("RoomQuota");
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
// Calculates and returns duration for giving check in and check out dates
// -----------------------------------------------------------------------------
&AtServer
Function CalculateDuration(pRoomRate, pCheckInDate, pCheckOutDate)
	vDuration = 0;
	If ValueIsFilled(pCheckInDate) And
	   ValueIsFilled(pCheckOutDate) Then
		vReferenceHour = 0;
		vDurationCalculationRuleType = Undefined;
		vPeriodInHours = 24;
		If ValueIsFilled(pRoomRate) Then
			vDurationCalculationRuleType = pRoomRate.DurationCalculationRuleType;
			vReferenceHour = pRoomRate.ReferenceHour - BegOfDay(pRoomRate.ReferenceHour);
		EndIf;
		If vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour And 
		   vReferenceHour = 0 Then
			vPerInSec = EndOfDay(pCheckOutDate) - BegOfDay(pCheckInDate);
			vDuration = Round(vPerInSec / vPeriodInHours / 3600, 0);
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			vPerInSec = (BegOfDay(pCheckOutDate) + vReferenceHour) - (BegOfDay(pCheckInDate) + vReferenceHour);
			vDuration = Round(vPerInSec / vPeriodInHours / 3600, 0);
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
			vPerInSec = EndOfDay(pCheckOutDate) - BegOfDay(pCheckInDate);
			vDuration = Round(vPerInSec / vPeriodInHours / 3600, 0);
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByNights Then
			vPerInSec = pCheckOutDate - pCheckInDate;
			vDuration = Round(vPerInSec / vPeriodInHours / 3600, 0);
		Else
			vPerInSec = pCheckOutDate - pCheckInDate;
			vDuration = Round(vPerInSec / vPeriodInHours / 3600, 0);
		EndIf;
	EndIf;
	Return vDuration;
EndFunction // CalculateDuration

// -----------------------------------------------------------------------------
// Calculates and returns check out date based on giving duration and check in date
// -----------------------------------------------------------------------------
&AtServer
Function CalculateCheckOutDate(pRoomRate, pCheckInDate, pDuration, pCheckOutDate)
	vCheckOutDate = pCheckOutDate;
	If ValueIsFilled(pCheckInDate) And pDuration > 0 Then
		vReferenceHour = 0;
		vDurationCalculationRuleType = Undefined;
		vPeriodInHours = 24;
		If ValueIsFilled(pRoomRate) Then
			vDurationCalculationRuleType = pRoomRate.DurationCalculationRuleType;
			vReferenceHour = pRoomRate.ReferenceHour - BegOfDay(pRoomRate.ReferenceHour);
		EndIf;
		If vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByReferenceHour Then
			If vReferenceHour = 0 Then
				vCheckOutDate = BegOfDay(pCheckInDate) + vReferenceHour + pDuration * vPeriodInHours * 3600 - 1;
			Else
				vCheckOutDate = BegOfDay(pCheckInDate) + vReferenceHour + pDuration * vPeriodInHours * 3600;
			EndIf;
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByDays Then
			vCheckOutDate = BegOfDay(pCheckInDate) + pDuration * vPeriodInHours * 3600 - 3 * 3600;
		ElsIf vDurationCalculationRuleType = Enums.DurationCalculationRuleTypes.ByNights Then
			vCheckInTime = pCheckInDate - BegOfDay(pCheckInDate);
			If vCheckInTime <= 9 * 3600 Then // Breakfast check-in
				vCheckOutDate = BegOfDay(pCheckInDate) + pDuration * vPeriodInHours * 3600 + 7 * 3600;
			ElsIf vCheckInTime <= 14 * 3600 Then // Lunch check-in
				vCheckOutDate = BegOfDay(pCheckInDate) + pDuration * vPeriodInHours * 3600 + 12 * 3600;
			ElsIf vCheckInTime <= 20 * 3600 Then // Supper check-in
				vCheckOutDate = BegOfDay(pCheckInDate) + pDuration * vPeriodInHours * 3600 + 18 * 3600;
			Else  // Late check-in
				vCheckOutDate = BegOfDay(pCheckInDate) + pDuration * vPeriodInHours * 3600 + 21 * 3600;
			EndIf;
		Else
			vCheckOutDate = cm0SecondShift(pCheckInDate + pDuration * vPeriodInHours * 3600);
		EndIf;
	EndIf;
	Return vCheckOutDate;
EndFunction // CalculateDateTo

// -----------------------------------------------------------------------------
&AtServer
Procedure SelNumberOfDaysOnChangeAtServer()
	If ValueIsFilled(SelPeriodFrom) Then
		SelPeriodTo = EndOfDay(SelPeriodFrom) + 24 * 3600 * (SelNumberOfDays - 1);
		SelPeriodToOnChangeAtServer();
	EndIf;
EndProcedure

#EndRegion    
