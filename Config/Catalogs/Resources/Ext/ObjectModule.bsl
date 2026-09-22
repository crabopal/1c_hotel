#Region EventHandlers

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
	// Current hotel
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	// Use round-the-clock calendar by default
	If Not ValueIsFilled(Calendar) Then
		Calendar = Catalogs.Calendars.RoundTheClock;
		RoundTheClockOperation = True;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Function pmCheckResourceAttributes(pMessage, pAttributeInErr) Export
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
	If Not ValueIsFilled(Owner) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тип ресурса> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Resource type> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Owner", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(Calendar) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Календарь работы ресурса> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Resource working time calendar> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Calendar", pAttributeInErr);
	EndIf;
	If vHasErrors Then
		pMessage = "ru = '" + TrimAll(vMsgTextRu) + "';" + "en = '" + TrimAll(vMsgTextEn) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckResourceAttributes

// -----------------------------------------------------------------------------
Function pmGetResourceDescription(pLang) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(Description);
	Else
		If IsBlankString(DescriptionTranslations) Then
			vDescr = TrimAll(Description);
		Else
			vDescr = TrimAll(cmNStr(DescriptionTranslations, pLang));
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // pmGetResourceDescription

// -----------------------------------------------------------------------------
// Get resource characteristics
// Returns ValueTable 
// -----------------------------------------------------------------------------
Function pmGetResourceCharacteristics() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ResourceCharacteristics.Resource,
	|	ResourceCharacteristics.ResourceCharacteristic,
	|	ResourceCharacteristics.ResourceCharacteristicValue
	|FROM
	|	InformationRegister.ResourceCharacteristics AS ResourceCharacteristics
	|WHERE
	|	ResourceCharacteristics.Resource = &qResource AND
	|	ResourceCharacteristics.ResourceCharacteristic.DeletionMark = FALSE
	|ORDER BY
	|	ResourceCharacteristics.ResourceCharacteristic.Code";
	vQry.SetParameter("qResource", Ref);
	vChars = vQry.Execute().Unload();
	Return vChars;
EndFunction // pmGetResourceCharacteristics

// -----------------------------------------------------------------------------
// Get resource characteristic value
// Returns Value
// -----------------------------------------------------------------------------
Function pmGetResourceCharacteristicValue(pResourceCharacteristic) Export
	vCharValue = Undefined;
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	ResourceCharacteristics.ResourceCharacteristicValue
	|FROM
	|	InformationRegister.ResourceCharacteristics AS ResourceCharacteristics
	|WHERE
	|	ResourceCharacteristics.Resource = &qResource AND
	|	ResourceCharacteristics.ResourceCharacteristic = &qResourceCharacteristic
	|ORDER BY
	|	ResourceCharacteristics.ResourceCharacteristic.Code";
	vQry.SetParameter("qResource", Ref);
	vQry.SetParameter("qResourceCharacteristic", pResourceCharacteristic);
	vChars = vQry.Execute().Select();
	While vChars.Next() Do
		vCharValue = vChars.ResourceCharacteristicValue;
		Break;
	EndDo;
	Return vCharValue;
EndFunction // pmGetResourceCharacteristicValue

// -----------------------------------------------------------------------------
Procedure pmSaveResourceCharacteristicValue(pResourceCharacteristic, pResourceCharacteristicValue) Export
	vResourceCharsMgr = InformationRegisters.ResourceCharacteristics.CreateRecordManager();
	vResourceCharsMgr.Resource = Ref;
	vResourceCharsMgr.ResourceCharacteristic = pResourceCharacteristic;
	vResourceCharsMgr.Read();
	If vResourceCharsMgr.Selected() Then
		vResourceCharsMgr.Resource = Ref;
		vResourceCharsMgr.ResourceCharacteristic = pResourceCharacteristic;
		vResourceCharsMgr.ResourceCharacteristicValue = pResourceCharacteristicValue;
		vResourceCharsMgr.Write();
	EndIf;
EndProcedure // pmSaveResourceCharacteristicValue

// -----------------------------------------------------------------------------
// Get resource children
// Returns ValueTable
// -----------------------------------------------------------------------------
Function pmGetResourceChildren() Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Resources.Ref AS Resource
	|FROM
	|	Catalog.Resources AS Resources
	|WHERE
	|	Resources.Parent = &qResource
	|	AND (NOT Resources.DeletionMark)
	|ORDER BY
	|	Resources.SortCode";
	vQry.SetParameter("qResource", Ref);
	vChildren = vQry.Execute().Unload();
	Return vChildren;
EndFunction // pmGetResourceChildren

// -----------------------------------------------------------------------------
// Get resource default charging time
// Returns Structure with TimeFrom and TimeTo elements
// -----------------------------------------------------------------------------
Function pmGetResourceDefaultChargingTimes(pAccountingDate) Export
	// Check resource attributes
	If ValueIsFilled(TimeFrom) And ValueIsFilled(TimeTo) And TimeTo >= TimeFrom Then
		Return New Structure("TimeFrom, TimeTo", TimeFrom, TimeTo);
	EndIf;
	// Check calendar timetable
	If ValueIsFilled(Calendar) Then
		vCalendarObj = Calendar.GetObject();
		vDays = vCalendarObj.pmGetDays(BegOfDay(pAccountingDate), BegOfDay(pAccountingDate), , , Catalogs.RoomTypes.EmptyRef());
		If vDays.Count() > 0 Then
			vDaysRow = vDays.Get(0);
			vTimetable = vDaysRow.Timetable;
			If ValueIsFilled(vTimeTable) And vTimeTable.WorkingTimes.Count() > 0 Then
				vWorkingTimes = vTimeTable.WorkingTimes.Unload();
				vWorkingTimes.Sort("TimeFrom");
				vTimeFrom = vWorkingTimes.Get(0).TimeFrom;
				vTimeTo = vWorkingTimes.Get(vWorkingTimes.Count() - 1).TimeTo;
				If ValueIsFilled(vTimeFrom) And ValueIsFilled(vTimeTo) And vTimeTo >= vTimeFrom Then
					Return New Structure("TimeFrom, TimeTo", vTimeFrom, vTimeTo);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return New Structure("TimeFrom, TimeTo", '00010101', '00010101');
EndFunction // pmGetResourceDefaultChargingTimes

#EndRegion

