
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	PackageList.Clear();
	
	// Read parameters
	Hotel = Parameters.Hotel;
	CheckInDate = Parameters.CheckInDate;
	CheckOutDate = Parameters.CheckOutDate;
	MealBoardsAreUsed = Parameters.MealBoardsAreUsed;
	vSelectedPackages = Parameters.SelectedPackages;
	
	For Each vSelectedPackagesItem In vSelectedPackages Do
		vSPStruct = vSelectedPackagesItem.Value;
		If ValueIsFilled(vSPStruct.ServicePackage) Then
			vPackagesListRow = PackageList.Add();
			vPackagesListRow.LineNumber = PackageList.IndexOf(vPackagesListRow) + 1;
			FillPropertyValues(vPackagesListRow, vSPStruct);
		EndIf;
	EndDo;

	vAllowedServicePackagesList = cmGetAllowedServicePackages(Hotel, BegOfDay(CheckInDate), BegOfDay(CheckOutDate), , MealBoardsAreUsed, True);
	For Each vAllowedServicePackagesListItem In vAllowedServicePackagesList Do
		vSP = vAllowedServicePackagesListItem.Value;
		If PackageList.FindRows(New Structure("ServicePackage", vSP)).Count() = 0 Then
			vPackagesListRow = PackageList.Add();
			vPackagesListRow.LineNumber = PackageList.IndexOf(vPackagesListRow) + 1;
			vPackagesListRow.ServicePackage = vSP;
		EndIf;
	EndDo;
	
	// Icons
	For Each vPackagesListRow In PackageList Do
		If ValueIsFilled(vPackagesListRow.ServicePackage) Then
			If Not vPackagesListRow.ServicePackage.IsPerPerson Then
				vPackagesListRow.IsPerPersonIcon = 1;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormTableItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AddServicePackagePeriodCommand(pCommand)
	vCurData = Items.PackageList.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.ServicePackage) Then
			If tcOnServer.cmGetAttributeByRef(vCurData.ServicePackage, "PeriodChangeIsForbidden") Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Period change is forbidden for this service package!'; ru='Для данного пакета услуг изменение периода запрещено!'; de='Bei diesem Leistungspaket ist ein Periodenwechsel verboten!'"));
				Return;
			EndIf;
		EndIf;
		vNewData = PackageList.Insert(PackageList.IndexOf(vCurData) + 1);
		vNewData.ServicePackage = vCurData.ServicePackage;
		vNewData.Quantity = vCurData.Quantity;
		vNewData.IsPerPersonIcon = vCurData.IsPerPersonIcon;
	EndIf;
EndProcedure // AddServicePackagePeriodCommand

// --------------------------------------------------------------------------------
&AtClient
Procedure DeleteServicePackagePeriodCommand(pCommand)
	vCurRow = Items.PackageList.CurrentRow;
	If vCurRow <> Undefined Then
		vCurData = PackageList.FindByID(vCurRow);
		If vCurData <> Undefined Then
			vDelIsAllowed = False;
			vSP = vCurData.ServicePackage;
			For Each vPackageListRow In PackageList Do
				If vPackageListRow.GetID() <> vCurRow And vSP = vPackageListRow.ServicePackage Then
					vDelIsAllowed = True;
					Break;
				EndIf;
			EndDo;
			If vDelIsAllowed Then
				vIndex = PackageList.IndexOf(vCurData);
				PackageList.Delete(vIndex);
				// Renumerate other lines
				For vInt = vIndex To (PackageList.Count() - 1) Do
					vRow = PackageList.Get(vInt);
					vRow.LineNumber = vInt + 1;
				EndDo;
			Else
				vCurData.Quantity = 0;
				vCurData.DateFrom = '00010101';
				vCurData.DateTo = '00010101';
			EndIf;
		EndIf;
	EndIf;
EndProcedure // DeleteServicePackagePeriodCommand

// --------------------------------------------------------------------------------
&AtClient
Procedure PackageListDateFromOnChange(pItem)
	vCurData = Items.PackageList.CurrentData;
	If vCurData <> Undefined Then
		vD = vCurData.DateFrom;
		If ValueIsFilled(vD) Then
			If ValueIsFilled(vCurData.DateTo) And vD > vCurData.DateTo Then
				vCurData.DateTo = '00010101';
			EndIf;
			If ValueIsFilled(CheckInDate) And vD < BegOfDay(CheckInDate) Then
				vCurData.DateFrom = BegOfDay(CheckInDate);
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Start of period is earlier then check-in date!'; ru='Начало периода раньше даты заселения!'; de='Der Beginn des Zeitraums ist früher als das Anreisedatum!'"));
			EndIf;
			If ValueIsFilled(CheckOutDate) And vD > BegOfDay(CheckOutDate) Then
				vCurData.DateFrom = BegOfDay(CheckOutDate);
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Start of period is later then check-out date!'; ru='Начало периода позже даты выезда!'; de='Der Beginn des Zeitraums liegt nach dem Abreisedatum!'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PackageListDateFromOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure PackageListDateToOnChange(pItem)
	vCurData = Items.PackageList.CurrentData;
	If vCurData <> Undefined Then
		vD = vCurData.DateTo;
		If ValueIsFilled(vD) Then
			If ValueIsFilled(vCurData.DateFrom) And vD < vCurData.DateFrom Then
				vCurData.DateFrom = '00010101';
			EndIf;
			If ValueIsFilled(CheckInDate) And vD < BegOfDay(CheckInDate) Then
				vCurData.DateTo = BegOfDay(CheckInDate);
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='End of period is earlier then check-in date!'; ru='Конец периода раньше даты заезда!'; de='Der Einde des Zeitraums ist früher als das Anreisedatum!'"));
			EndIf;
			If ValueIsFilled(CheckOutDate) And vD > BegOfDay(CheckOutDate) Then
				vCurData.DateTo = BegOfDay(CheckOutDate);
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='End of period is later then check-out date!'; ru='Конец периода позже даты выезда!'; de='Der Einde des Zeitraums liegt nach dem Abreisedatum!'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PackageListDateToOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure PackageListQuantityOnChange(pItem)
	vCurData = Items.PackageList.CurrentData;
	If vCurData <> Undefined Then
		If vCurData.Quantity = 0 Then
			vCurData.DateFrom = '00010101';
			vCurData.DateTo = '00010101';
		EndIf;
	EndIf;
EndProcedure // PackageListQuantityOnChange

// --------------------------------------------------------------------------------
&AtClient
Function PeriodChangeAvailability()
	vPeriodEditIsAllowed = True;
	vCurData = Items.PackageList.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.ServicePackage) Then
			If tcOnServer.cmGetAttributeByRef(vCurData.ServicePackage, "PeriodChangeIsForbidden") Then
				vPeriodEditIsAllowed = False;
			EndIf;
		EndIf;
	EndIf;
	Return vPeriodEditIsAllowed;
EndFunction // PeriodChangeAvailability

// --------------------------------------------------------------------------------
&AtClient
Procedure PackageListOnActivateRow(Item)
	vPeriodChangeIsAllowed = PeriodChangeAvailability();
	Items.PackageListDateFrom.ReadOnly = Not vPeriodChangeIsAllowed;
	Items.PackageListDateTo.ReadOnly = Not vPeriodChangeIsAllowed;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PackageListOnStartEdit(pItem, pNewRow, pClone)
	vCurData = Items.PackageList.CurrentData;
	If vCurData <> Undefined Then
		vCurData.LineNumber = PackageList.IndexOf(vCurData) + 1;
		// Renumerate other lines
		For vID = vCurData.LineNumber To (PackageList.Count() - 1) Do
			vRow = PackageList.Get(vID);
			vRow.LineNumber = vID + 1;
		EndDo;
	EndIf;
EndProcedure // PackageListOnStartEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure PackageListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	vCurData = Items.PackageList.CurrentData;
	If vCurData <> Undefined And pField <> Undefined Then
		If pField.Name = "PackageListServicePackage" Then
			If ValueIsFilled(vCurData.ServicePackage) Then
				pStandardProcessing = False;
				If vCurData.Quantity = 0 Then
					vCurData.Quantity = 1;
				Else
					vCurData.Quantity = 0;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PackageListSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowSelectedPackage(pCommand)
	vCurData = Items.PackageList.CurrentData;
	If vCurData <> Undefined Then
		If ValueIsFilled(vCurData.ServicePackage) Then
			ShowValue(, vCurData.ServicePackage);
		EndIf;
	EndIf;
EndProcedure // ShowSelectedPackage

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SelectionCommand(Command)
	// Check period intersection for service packages selected
	For Each vPackagesListRow1 In PackageList Do
		If ValueIsFilled(vPackagesListRow1.ServicePackage) Then
			vRowIndex1 = PackageList.IndexOf(vPackagesListRow1);
			For Each vPackagesListRow2 In PackageList Do
				vRowIndex2 = PackageList.IndexOf(vPackagesListRow2);
				If vRowIndex1 <> vRowIndex2 And vPackagesListRow1.ServicePackage = vPackagesListRow2.ServicePackage Then
					If vPackagesListRow1.DateFrom <= ?(ValueIsFilled(vPackagesListRow2.DateTo), vPackagesListRow2.DateTo, '39991231') And 
					   ?(ValueIsFilled(vPackagesListRow1.DateTo), vPackagesListRow1.DateTo, '39991231') >= vPackagesListRow2.DateFrom Then
						vMessage = NStr("en='The <&2> package action period in line N &1 overlaps with the period in line N &3! Action periods of the same packages must not overlap.';
						                |ru='В строке № &1 период действия пакета <&2> пересекается с периодом в строке № &3! Периоды действия одинаковых пакетов не должны пересекаться.'; 
										|de='In Zeile Nr. &1 überschneidet sich der Gültigkeitszeitraum des <&2> Pakets mit dem Zeitraum in Zeile Nr. &3! Die Gültigkeitszeiträume gleicher Pakete dürfen sich nicht überschneiden.'");
						vMessage = tcCommonFunctions.cmSetTextParameters(vMessage, String(vRowIndex2 + 1), TrimAll(vPackagesListRow2.ServicePackage), String(vRowIndex1 + 1));
						ShowMessageBox(, vMessage);
						Return;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	// Build return value list with service package structures
	vServicePackagesList = New ValueList();
	For Each vPackagesListRow In PackageList Do
		If ValueIsFilled(vPackagesListRow.ServicePackage) Then
			vSPStruct = New Structure("ServicePackage, Quantity, DateFrom, DateTo", vPackagesListRow.ServicePackage, vPackagesListRow.Quantity, vPackagesListRow.DateFrom, vPackagesListRow.DateTo);
			vServicePackagesList.Add(vSPStruct, , ?(vPackagesListRow.Quantity <> 0, True, False));
		EndIf;
	EndDo;
	Notify("ServicePackages.Changed", vServicePackagesList, FormOwner);
	Close();
EndProcedure // SelectionCommand

// --------------------------------------------------------------------------------
&AtClient
Procedure CancelCommand(Command)
	Notify("ServicePackages.Changed", Undefined, FormOwner);
	Close();
EndProcedure // CancelCommand

// --------------------------------------------------------------------------------
&AtClient
Procedure ClearAllSelectedPackages(pCommand)
	For Each vPackageListRow In PackageList Do
		vPackageListRow.Quantity = 0;
		vPackageListRow.DateFrom = '00010101';
		vPackageListRow.DateTo = '00010101';
	EndDo;
EndProcedure // ClearAllSelectedPackages

#EndRegion
