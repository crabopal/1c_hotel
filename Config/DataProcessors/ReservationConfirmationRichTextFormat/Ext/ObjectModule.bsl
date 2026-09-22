
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Any	 - Additional parameters
//
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	// [NONE SO FAR]
EndProcedure // pmLoadReportAttributes

//-----------------------------------------------------------------------------
Procedure pmPrintConfirmation(vSpreadsheet, SelReservation, SelReservations, SelServicesFilter, SelServiceGroup, SelShowConfirmationForCurrentReservationOnly, SelLanguage, SelObjectPrintForm, SelShowGuests = True, SelShowDetails = False, SelShowPaymentLink = False, SelHideRoomRateAndSum = False) Export
	vMaxColumn = 14;
	// Basic checks
	If Not ValueIsFilled(SelReservation.Hotel) Then
		Raise String(SelReservation.Ref) + " - " + NStr("ru='У документа должна быть указана гостиница!';de='Bei dem Dokument muss das Hotel angegeben sein!';en='Hotel attribute should be filled!'");
	EndIf;
	If Not ValueIsFilled(SelLanguage) Then
		SelLanguage = SessionParameters.CurrentLanguage;
	EndIf;
	
	// Some settings
	vShowReservationNumbersInConfirmation = cmCheckUserPermissions("ShowReservationNumbersInConfirmation");
	
	// Fill and check printing parameter
	vParameter = Upper(TrimAll(SelObjectPrintForm.Parameter));
	
	// Choose template
	vResObj = SelReservation.GetObject();
	vSpreadsheet.Clear();
	If ValueIsFilled(SelLanguage) Then
		If SelLanguage = Catalogs.Languages.EN Then
			vTemplate = ThisObject.GetTemplate("ReservationConfirmationEn");
		ElsIf SelLanguage = Catalogs.Languages.DE Then
			vTemplate = ThisObject.GetTemplate("ReservationConfirmationDe");
		ElsIf SelLanguage = Catalogs.Languages.RU Then
			vTemplate = ThisObject.GetTemplate("ReservationConfirmationRu");
		Else
			Raise String(SelReservation.Ref) + " - " + 
			NStr("ru = 'Не найден шаблон печатной формы подтверждения бронирования для языка " + SelLanguage.Code + "!'; 
			|de = 'No reservation confirmation print form template found for the " + SelLanguage.Code + " language!'; 
			|en = 'No reservation confirmation print form template found for the " + SelLanguage.Code + " language!'");
		EndIf;
	Else
		vTemplate = ThisObject.GetTemplate("ReservationConfirmationRu");
	EndIf;
	// Load external template if any
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	If vExtTemplate <> Undefined Then
		vTemplate = vExtTemplate;
	EndIf;
	
	// Load pictures
	vLogoIsSet = False;
	vLogo = New Picture;
	If ValueIsFilled(SelReservation.Hotel) Then
		If SelReservation.Hotel.Logo <> Undefined Then
			vLogo = SelReservation.Hotel.Logo.Get();
			If vLogo = Undefined Then
				vLogo = New Picture;
			Else
				vLogoIsSet = True;
			EndIf;
		EndIf;
	EndIf;                                                                                                      
	vHeaderParameters = New Structure;
	// Header
	vHeader = vTemplate.GetArea("Top");
	// Hotel
	vHotel = SelReservation.Hotel;
	mHotelPrintName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, SelLanguage);
	mHotelPostAddressPresentation = Catalogs.Hotels.pmGetHotelPostAddressPresentation(vHotel, SelLanguage);
	mHotelPhones = TrimAll(vHotel.Phones);
	mHotelEMail = TrimAll(vHotel.EMail);
	mHotelSite = TrimAll(vHotel.Site);
	// Customer
	mCustomerLegacyName = "";
	If ValueIsFilled(SelReservation.Customer) Then
		mCustomerLegacyName = TrimAll(SelReservation.Customer.LegacyName);
		If IsBlankString(mCustomerLegacyName) Then
			mCustomerLegacyName = TrimAll(SelReservation.Customer.Description);
		EndIf;
	EndIf;
	// Contract
	mContractDescription = "";
	If ValueIsFilled(SelReservation.Contract) Then
		mContractDescription = TrimAll(SelReservation.Contract.Description);
	EndIf;
	
	// Confirmation header text
	IsWaitingList = False;
	If ValueIsFilled(SelReservation) And ValueIsFilled(SelReservation.ReservationStatus) And SelReservation.ReservationStatus.IsInWaitingList Then
		IsWaitingList = True;
	EndIf;
	
	// Guest group code
	mGuestGroupCode = Format(SelReservation.GuestGroup.Code, "NG=");
	
	vHotelPrefix = Catalogs.Hotels.pmGetPrefix(vHotel);
	If Not IsBlankString(vHotelPrefix) And vHotel.ShowHotelPrefixBeforeGroupCode Then
		mGuestGroupCode = vHotelPrefix + mGuestGroupCode;
	EndIf;  
	If ValueIsFilled(SelReservation.GuestGroup.Status.DescriptionTranslations) Then 
		mGuestGroupStatus = cmNStr(SelReservation.GuestGroup.Status.DescriptionTranslations, SelLanguage); 
	Else
		mGuestGroupStatus = SelReservation.GuestGroup.Status;    
	EndIf;     
	// Set parameters and put report section
	vHeaderParameters.Insert("mHotelPrintName", mHotelPrintName);
	vHeaderParameters.Insert("mHotelPostAddressPresentation",  mHotelPostAddressPresentation);
	vHeaderParameters.Insert("mHotelPhones",  mHotelPhones);
	vHeaderParameters.Insert("mHotelEMail",  mHotelEMail);
	vHeaderParameters.Insert("mCustomerLegacyName",  mCustomerLegacyName);
	vHeaderParameters.Insert("mContractDescription",  mContractDescription);
	vHeaderParameters.Insert("mGuestGroupCode",  mGuestGroupCode);
	vHeaderParameters.Insert("mGuestGroupStatus", mGuestGroupStatus);
	vHeaderParameters.Insert("mHotelSite", mHotelSite);
	// Logo
	If vHeader.Drawings.Count() > 0 Then
		Try
			If vLogoIsSet Then
				vHeader.Drawings.Logo.Print = True;
				vHeader.Drawings.Logo.Picture = vLogo;
			Else
				vHeader.Drawings.Delete(vHeader.Drawings.Logo);
			EndIf;
		Except EndTry;
	EndIf;
	// Put top header		
	FillPropertyValues(vHeader.Parameters,vHeaderParameters);
	vSpreadsheet.Put(vHeader);
	If SelReservation.GuestGroup.Status.IsActive Then
		vSpreadsheet.Area("Status").TextColor = tcCommonFunctionOnClientServer.ColorConstructor(0, 128, 0);
	Else  
		vSpreadsheet.Area("Status").TextColor = tcCommonFunctionOnClientServer.ColorConstructor(255, 0, 0);   
	EndIf;       
	
	vReservations = SelReservation.GuestGroup.GetObject().pmGetReservations(True, ?(IsWaitingList, False, True), False, IsWaitingList, ?(SelShowConfirmationForCurrentReservationOnly, SelReservation, Undefined), ?(SelShowConfirmationForCurrentReservationOnly, Undefined, ?(SelReservations = Undefined, Undefined, ?(SelReservations.Count() > 0, SelReservations, Undefined))));
	vReservations.Sort("Number");
	
	vIsOneRoomRate = True; 
	vReservtionRoomRate = vReservations.Copy(); 
	vReservtionRoomRate.GroupBy("RoomRate");
	If vReservtionRoomRate.Count() > 1 Then  
		vIsOneRoomRate = False;
	EndIf;
	
	vRoomsTotal = 0;
	vGuestsTotal = 0;
	vRoomsList = New ValueList();
	For Each vResRow In vReservations Do
		vCurRes = vResRow.Reservation;
		If vRoomsList.FindByValue(vCurRes.Number) = Undefined Then
			vRoomsList.Add(vCurRes.Number);
			vRoomsTotal = vRoomsTotal + vCurRes.RoomQuantity;
		EndIf;
		vGuestsTotal = vGuestsTotal + vCurRes.NumberOfPersons;
	EndDo;		
	
	vTotalPaidSum = 0;
	vDocsList = New ValueList();
	For Each vResRow In vReservations Do
		If vDocsList.FindByValue(vResRow.Reservation) = Undefined Then
			vDocsList.Add(vResRow.Reservation);
		EndIf;
	EndDo;
	vGroupPayments = SelReservation.GuestGroup.GetObject().pmGetPaymentsTotals(vDocsList);
	For Each vGroupPaymentsRow In vGroupPayments Do
		vTotalPaidSum = vTotalPaidSum + Round(cmConvertCurrencies(vGroupPaymentsRow.Sum, vGroupPaymentsRow.Currency, , SelReservation.ReportingCurrency, , vGroupPaymentsRow.AccountingDate, SelReservation.Hotel), 2);
	EndDo;

	i = 0;
	While i < vReservations.Count() Do
		vResRow = vReservations.Get(i);
		vCurRes = vResRow.Reservation;
		If Not ValueIsFilled(vCurRes.AccommodationTemplate) And 
		   Not vCurRes.IsForFolioSplit And 
		   ValueIsFilled(vCurRes.AccommodationType) And vCurRes.AccommodationType.Type <> Enums.AccomodationTypes.Beds Then
			vReservations.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;  
	
	vTotalGroupAmount = 0; 
	vArrayOfAreas = New Array;
	vLineNumber = 0;
	vCurResNumber = "";
	For Each vResRow In vReservations Do
		If ValueIsFilled(vResRow.Status) And (Not IsWaitingList And (vResRow.Status.IsActive Or vResRow.Status.IsCheckIn Or vResRow.Status.IsPreliminary) Or IsWaitingList) Then
			vCurRes = vResRow.Reservation;
			If vCurResNumber <> vCurRes.Number Then
				vCurResNumber = vCurRes.Number;
			Else
				Continue;
			EndIf;
			
			// Get accommodation periods
			vAccommodationPeriods = vCurRes.GetObject().pmGetAccommodationPeriods();
			j = 0;
			While j < vAccommodationPeriods.Count() Do
				vAccPerRow = vAccommodationPeriods.Get(j);
				If (j + 1) < vAccommodationPeriods.Count() Then
					vNextAccPerRow = vAccommodationPeriods.Get(j + 1);
					If vAccPerRow.RoomType = vNextAccPerRow.RoomType And vAccPerRow.RoomRate = vNextAccPerRow.RoomRate Then
						vAccPerRow.CheckOutDate = vNextAccPerRow.CheckOutDate;
						vAccommodationPeriods.Delete(j + 1);
					Else
						j = j + 1;
					EndIf;
				Else
					Break;
				EndIf;
			EndDo;
			
			// Get dates
			vRoomRates = vCurRes.RoomRates.Unload();
			vPeriods = vRoomRates.Copy(, "AccountingDate");
			
			// Add periods services
			Services = GetReservationRoomServices(vCurRes);
			// Filter services by customer
			If SelServicesFilter > 0 Then
				i = 0;
				While i < Services.Count() Do
					vSrvRow = Services.Get(i);
					If SelServicesFilter = 1 Then
						If ValueIsFilled(vSrvRow.Folio.Customer) Then
							Services.Delete(i);
							Continue;
						EndIf;
					ElsIf SelServicesFilter = 2 Then
						If Not ValueIsFilled(vSrvRow.Folio.Customer) Then
							Services.Delete(i);
							Continue;
						EndIf;
					EndIf;
					i = i + 1;
				EndDo;
			EndIf;
			// Filter services by service group
			If ValueIsFilled(SelServiceGroup) Then
				i = 0;
				While i < Services.Count() Do
					vSrvRow = Services.Get(i);
					If Not cmIsServiceInServiceGroup(vSrvRow.Service, SelServiceGroup) Then
						Services.Delete(i);
						Continue;
					EndIf;
					i = i + 1;
				EndDo;
			EndIf; 
			
			For Each vId In Services Do
				If ValueIsFilled(vId.AccountingDate) Then
					If vPeriods.Find(vId.AccountingDate, "AccountingDate") = Undefined Then
						vRowPeriod = vPeriods.Add();
						vRowPeriod.AccountingDate = vId.AccountingDate;
					EndIf;
				EndIf;	
			EndDo;
			
			vCurDate = BegOfDay(vCurRes.CheckInDate);   		
			vPlan = New ValueTable();
			While vCurDate <= BegOfDay(vCurRes.CheckOutDate) Do
				vColumnName = "Column_" + Format(vCurDate, "DF=yyyyMMdd");
				If vPlan.Columns.Find(vColumnName) = Undefined Then
					vPlan.Columns.Add( vColumnName, New TypeDescription("Date"));
				EndIf;	  
				If vPlan.Columns.Find(vColumnName + "_Amount") = Undefined Then
					vPlan.Columns.Add( vColumnName + "_Amount", New TypeDescription("Number"));
				EndIf;
				If vPeriods.Find(vCurDate) = Undefined Then
					vRowPeriod = vPeriods.Add();
					vRowPeriod.AccountingDate = vCurDate;
				EndIf; 
				vCurDate = vCurDate + 24*3600;
			EndDo;
			
			vPeriods.GroupBy("AccountingDate");
			vPeriods.Sort("AccountingDate");
			
			vTotals = 0;
			vExtraServices = 0;
			vServicesTotals = New ValueTable;   
			
			FillPricesAndServices(vCurRes, vServicesTotals); 
			
			// Fill totals
			For Each vRowTotals In vServicesTotals Do
				If vRowTotals.Sort = 2 Then
					vTotals = vTotals + vRowTotals.Amount;   
				EndIf; 
				If  vRowTotals.Sort = 3 Then
					vExtraServices = vExtraServices + vRowTotals.Amount;  
					vTotals = vTotals + vRowTotals.Amount;                      
				EndIf; 
			EndDo; 
			vTotalGroupAmount = vTotalGroupAmount + vTotals;
			
			vRoomRowNumber = vTemplate.GetArea("RoomRowNumber"); 
			vLineNumber = vLineNumber + 1;
			vRoomRowNumberParameters = New Structure;
			vRoomRowNumberParameters.Insert("mRoomRowNumber", vLineNumber);
			FillPropertyValues(vRoomRowNumber.Parameters, vRoomRowNumberParameters);
			If vRoomsTotal > 1 Then
				vArrayOfAreas.Add(vRoomRowNumber);
			EndIf;
			
			vRoomTopParameters = New Structure;
			vRoomTop = vTemplate.GetArea("RoomTop"); 

			If SelHideRoomRateAndSum Then
				mTotalAmount = "";	
			Else	
				mTotalAmount = cmFormatSum(vTotals, vCurRes.ReportingCurrency, "NZ=0.00"); 
			EndIf;
			mDocNumber = vCurRes.Number;  
			
			vRoomTopParameters.Insert("mDocNumber", mDocNumber);
			vRoomTopParameters.Insert("mTotalAmount",  mTotalAmount);

			FillPropertyValues(vRoomTop.Parameters, vRoomTopParameters);
			vArrayOfAreas.Add(vRoomTop);   

			For Each vAccommodationPeriod In vAccommodationPeriods Do
				vRoomDataParameters = New Structure;
				vRoomData = vTemplate.GetArea("RoomData");
				
				If ValueIsFilled(vAccommodationPeriod.RoomType) AND Not IsBlankString(vAccommodationPeriod.RoomType.DescriptionTranslations) Then
					mRoomType = cmNStr(vAccommodationPeriod.RoomType.DescriptionTranslations, SelLanguage);
				Else
					mRoomType = vAccommodationPeriod.RoomType;
				EndIf;
				If vCurRes.RoomQuantity > 1 Then 
					mRoomType = Format(vCurRes.RoomQuantity)+ " x " + mRoomType;
				EndIf;
				If SelLanguage = Catalogs.Languages.RU Then
					vRoomDataParameters.Insert("mRoomQuantity", GetStringDeclensionsByNumber("номер", vCurRes.RoomQuantity, "", "L=ru_RU; NM=Cardinal", "CS=Nominative; NP=Number")[0]);
				Else
					If vCurRes.RoomQuantity > 1 Then
						vRoomDataParameters.Insert("mRoomQuantity", Format(vCurRes.RoomQuantity, "NFD=0; NG=") + NStr("en=' rooms'; ru=' номеров'; de=' Zimmer'", SelLanguage));
					Else
						vRoomDataParameters.Insert("mRoomQuantity", Format(vCurRes.RoomQuantity, "NFD=0; NG=") + NStr("en=' room'; ru=' номер'; de=' Zimmer'", SelLanguage));
					EndIf;
				EndIf;    
				mCheckInDate = vAccommodationPeriod.CheckInDate;  
				mCheckOutDate = vAccommodationPeriod.CheckOutDate; 
				If SelHideRoomRateAndSum Or Not ValueIsFilled(vAccommodationPeriod.RoomRate) Then
					mRoomRate = ""; 
				Else
					mRoomRate = cmNStr("en='Room rate ""'; ru='Тариф: ""'; de='Tarif: ""'", SelLanguage) + vAccommodationPeriod.RoomRate.GetObject().pmGetRoomRateDescription(SelLanguage) + """" + 
					            ?(ValueIsFilled(vAccommodationPeriod.ServicePackage), cmNStr("en=', Terms ""'; ru=', Питание: ""'; de=', Essen: ""'", SelLanguage) + Catalogs.ServicePackages.GetServicePackageDescription(vAccommodationPeriod.ServicePackage, SelLanguage) + """", "");
				EndIf;	

				vRoomDataParameters.Insert("mCheckInDate",  Format(mCheckInDate, "DF=dd.MM.yyyy"));
				vRoomDataParameters.Insert("mCheckOutDate",  Format(mCheckOutDate, "DF=dd.MM.yyyy"));
				
				vDuration = cmCalculateDuration(vAccommodationPeriod.RoomRate, vAccommodationPeriod.CheckInDate, vAccommodationPeriod.CheckOutDate);
				If SelLanguage = Catalogs.Languages.RU Then
					vDurationWord = GetStringDeclensionsByNumber("ночь", vDuration, "", "L=ru_RU; NM=Cardinal", "CS=Nominative; NP=Number")[0];
				Else
					If vDuration > 1 Then
						vDurationWord = Format(vDuration, "NFD=0; NG=") + NStr("en=' nights'; ru=' ночей'; de=' Nächte'", SelLanguage);
					Else
						vDurationWord = Format(vDuration, "NFD=0; NG=") + NStr("en=' night'; ru=' ночь'; de=' Nacht'", SelLanguage);
					EndIf;
				EndIf;
				vRoomDataParameters.Insert("mDuration", vDurationWord);
				
				vRoomDataParameters.Insert("mRoomType",  mRoomType);
				vRoomDataParameters.Insert("mRoomRate",  mRoomRate);

				FillPropertyValues(vRoomData.Parameters, vRoomDataParameters);
				vArrayOfAreas.Add(vRoomData);
			EndDo;
			
			vRoomBottomParameters = New Structure;
			vRoomBottom = vTemplate.GetArea("RoomBottom");
			
			mDefaultCheckInTime = '00010101120000';
			mDefaultCheckOutTime = '00010101120000';
			If ValueIsFilled(vCurRes.RoomRate) Then     
				If ValueIsFilled(vCurRes.RoomRate.DefaultCheckInTime) Then
					mDefaultCheckInTime = vCurRes.RoomRate.DefaultCheckInTime;
				Else  
					mDefaultCheckInTime = vCurRes.CheckInDate;
				Endif;	
				If ValueIsFilled(vCurRes.RoomRate.DefaultCheckOutTime) Then
					mDefaultCheckOutTime =  vCurRes.RoomRate.DefaultCheckOutTime;
				Else  
					mDefaultCheckOutTime = vCurRes.CheckOutDate;
				Endif;
			EndIf;     
			
			vRoomBottomParameters.Insert("mDefaultCheckInTime",   Format(mDefaultCheckInTime, "DF=HH:mm"));
			vRoomBottomParameters.Insert("mDefaultCheckOutTime",  Format(mDefaultCheckOutTime, "DF=HH:mm"));
			
			FillPropertyValues(vRoomBottom.Parameters, vRoomBottomParameters);
			vArrayOfAreas.Add(vRoomBottom);
			
			// All guests
			vRoomTemplateParameters = New Structure;
			vRoomTemplate = vTemplate.GetArea("RoomTemplate");
			If ValueIsFilled(vCurRes.AccommodationTemplate) Then
				If ValueIsFilled(vCurRes.AccommodationTemplate.DescriptionTranslations) Then
					mAccommodationTemplate = cmNStr(vCurRes.AccommodationTemplate.DescriptionTranslations,SelLanguage);
				Else 
					mAccommodationTemplate = vCurRes.AccommodationTemplate.Description;
				EndIf;  
			EndIf;
			If vCurRes.RoomQuantity > 1  Then
				mAccommodationTemplate = Format(vCurRes.RoomQuantity)+ " x " + mAccommodationTemplate;
			EndIf;
			vRoomTemplateParameters.Insert("mAccommodationTemplate", mAccommodationTemplate);
			FillPropertyValues(vRoomTemplate.Parameters,vRoomTemplateParameters);
			vArrayOfAreas.Add(vRoomTemplate);
			
			// Guests list
			If SelShowGuests Then  
				vOneRoomDocs = cmGetOneRoomReservations(vCurRes.Number, vCurRes.GuestGroup, vCurRes.CheckInDate, vCurRes.CheckOutDate);  
				For Each vDocRow In vOneRoomDocs Do
					vDoc = vDocRow.Ref;      		
					If ValueIsFilled(vDoc.Guest) And Not IsBlankString(vDoc.Guest.FullName) Then
						vGuestRowParameters = New Structure;
						vGuestRow = vTemplate.GetArea("RoomGuestRow"); 
						vGuestRowParameters.Insert("mGuestFullName", vDoc.Guest.FullName);
						FillPropertyValues(vGuestRow.Parameters, vGuestRowParameters);
						vArrayOfAreas.Add(vGuestRow);   
					EndIf;
				EndDo;   
			EndIf;   		
			
			// Price by days
			If SelShowDetails Then  
				vRowPlan = vPlan.Add(); 
				For Each vRowPeriod In vPeriods Do
					vCurDate = vRowPeriod.AccountingDate;
					vCurSum = 0;
					// Add columns
					vColumnName = "Column_" + Format(vCurDate, "DF=yyyyMMdd");
					If vPlan.Columns.Find(vColumnName) = Undefined Then
						vPlan.Columns.Add(vColumnName);
					EndIf;
					If vPlan.Columns.Find(vColumnName + "_Amount") = Undefined Then
						vPlan.Columns.Add(vColumnName + "_Amount");
					EndIf;	
					vRowServices = vServicesTotals.FindRows(New Structure("AccountingDate, Service", vCurDate, "RoomPrice")); 
					For Each vRow In vRowServices Do  
						vCurSum = vCurSum + vRow.Amount; 
					EndDo;
					vRowPlan[vColumnName] = vCurDate;  
					vRowPlan[vColumnName + "_Amount"] = vCurSum;      			   
				EndDo;      			
				
				vRoomDetailsTop = vTemplate.GetArea("RoomDetailsTop");  
				vRoomDetailsTopParameters = New Structure;
				mRoomPrice = 0;
				vRowServices = vServicesTotals.FindRows(New Structure("Service", "RoomPrice"));
				For Each vRow In vRowServices Do  
					mRoomPrice = mRoomPrice + vRow.Amount; 
				EndDo;
				vRoomDetailsTopParameters.Insert("mRoomPrice", cmFormatSum(mRoomPrice, vCurRes.ReportingCurrency, "NZ=' '"));
				FillPropertyValues(vRoomDetailsTop.Parameters,vRoomDetailsTopParameters);
				vArrayOfAreas.Add(vRoomDetailsTop);
				
				vCountAreas = Int(vPlan.Columns.Count()/(2*vMaxColumn));
				If vPlan.Columns.Count()%(2*vMaxColumn) > 0 Then
					vCountAreas = vCountAreas +1;
				EndIf;	
				i = 1;  
				j = 1;  
				vRoomDetails = vTemplate.GetArea("RoomDetails"); 
				vRoomDetailsParameters = New Structure;
				For Each vClomnRow In vPlan.Columns Do 
					If j = i * vMaxColumn + 1 And j <> 1 Then   
						FillPropertyValues(vRoomDetails.Parameters,vRoomDetailsParameters);
						vArrayOfAreas.Add(vRoomDetails);
						i = i + 1;
						vRoomDetails = vTemplate.GetArea("RoomDetails");
						vRoomDetailsParameters = New Structure;
					EndIf;
					If StrFind(vClomnRow.Name, "_Amount") Then 
						vRoomDetailsParameters.Insert("mPrice" + String(j-(i-1)*vMaxColumn), Format(vPlan.Get(0)[vClomnRow.Name], "NFD=2; NZ=' '"));
						j = j + 1;   			
					Else
						vLangCode = lower(TrimAll(SelLanguage.Code));
						vRoomDetailsParameters.Insert("mDay" + String(j-(i-1)*vMaxColumn),  Format(vPlan.Get(0)[vClomnRow.Name], "L=" + vLangCode + "; DF='ddd'"));
						vRoomDetailsParameters.Insert("mDate" + String(j-(i-1)*vMaxColumn),  Format(vPlan.Get(0)[vClomnRow.Name], "L=" + vLangCode + "; DF='dd MMM'"));
					EndIf;
				EndDo;
				FillPropertyValues(vRoomDetails.Parameters, vRoomDetailsParameters);
				vArrayOfAreas.Add(vRoomDetails);
			EndIf;   
			
			// Room rate services
			If ValueIsFilled(vCurRes.RoomRate) And Not IsBlankString(vCurRes.RoomRate.ServicesIncludedDescription) Then 
				vServicesIncludedDescriptionParameters = New Structure;
				vServicesIncludedDescription = vTemplate.GetArea("RoomServicesIncludedDescription");
				mServicesIncludedDescription = cmNStr(TrimAll(vCurRes.RoomRate.ServicesIncludedDescription), SelLanguage);
				vServicesIncludedDescriptionParameters.Insert("mServicesIncludedDescription", mServicesIncludedDescription);
				FillPropertyValues(vServicesIncludedDescription.Parameters,vServicesIncludedDescriptionParameters);
				vArrayOfAreas.Add(vServicesIncludedDescription);
			EndIf;
			
			// Extra services
			mExtraServicesDescription = "";	
			vServicesTotals.GroupBy("Service, Sort", "Amount, Quantity");
			vServicesTotals.Sort("Service");
			vRowServicesExtra = vServicesTotals.FindRows(New Structure("Sort", 3));
			For Each vRow In vRowServicesExtra Do  
				If Not IsBlankString(mExtraServicesDescription) Then  
					mExtraServicesDescription = mExtraServicesDescription + Chars.LF;
				EndIf;
				mExtraServicesDescription = mExtraServicesDescription + vRow.Service +" "+ cmFormatSum(vRow.Amount, vCurRes.ReportingCurrency, "NZ=' '"); 
			EndDo;
			If Not IsBlankString(mExtraServicesDescription) Then 
				vRoomExtraServices = vTemplate.GetArea("RoomExtraServices");
				vRoomExtraServicesParameters = New Structure;
				vRoomExtraServicesParameters.Insert("mExtraServices", cmFormatSum(vExtraServices, vCurRes.ReportingCurrency, "NZ=' '"));
				vRoomExtraServicesParameters.Insert("mExtraServicesDescription", mExtraServicesDescription);
				FillPropertyValues(vRoomExtraServices.Parameters,vRoomExtraServicesParameters);
				vArrayOfAreas.Add(vRoomExtraServices);
			EndIf;
			
			// Terms of use
			If Not vIsOneRoomRate Then  
				vRoomReservationConditions = vTemplate.GetArea("RoomReservationConditions");
				vRoomReservationConditionsParameters = New Structure;
				mReservationConditionsFromReservationStatus = "";    
				If ValueIsFilled(vCurRes.ReservationStatus) And Not IsBlankString(vCurRes.ReservationStatus.ReservationConditions) Then 
					mReservationConditionsFromReservationStatus = cmNstr(vCurRes.ReservationStatus.ReservationConditions, SelLanguage);   
				EndIf;
				mReservationConditions = ""; 
				If ValueIsFilled(vCurRes.RoomRate) And Not IsBlankString(vCurRes.RoomRate.ReservationConditions) Then 
					If Not IsBlankString(mReservationConditionsFromReservationStatus) Then  
						mReservationConditions = mReservationConditionsFromReservationStatus + Chars.LF +
						cmNstr(vCurRes.RoomRate.ReservationConditions, SelLanguage);
					Else 	
						mReservationConditions = cmNstr(vCurRes.RoomRate.ReservationConditions, SelLanguage);  
					EndIf;
				ElsIf Not IsBlankString(vCurRes.Hotel.ReservationConditions) Then 
					If Not IsBlankString(mReservationConditionsFromReservationStatus) Then  
						mReservationConditions = mReservationConditionsFromReservationStatus + Chars.LF +
						cmNstr(vCurRes.Hotel.ReservationConditions, SelLanguage);
					Else 	
						mReservationConditions = cmNstr(vCurRes.Hotel.ReservationConditions, SelLanguage);  
					EndIf;
				Else
					mReservationConditions = mReservationConditionsFromReservationStatus;	
				EndIf;
				If Not IsBlankString(vCurRes.ConfirmationReply) Then
					mReservationConditions = mReservationConditions + ?(IsBlankString(mReservationConditions), "", Chars.LF + Chars.LF) + 
					TrimAll(vCurRes.ConfirmationReply);
				EndIf;
				
				If Not IsBlankString(mReservationConditions) Then
					vRoomReservationConditionsParameters.Insert("mReservationConditions", mReservationConditions);
					FillPropertyValues(vRoomReservationConditions.Parameters, vRoomReservationConditionsParameters);
					vArrayOfAreas.Add(vRoomReservationConditions);
				EndIf;
			EndIf;   
			
			// Cancellation terms
			If Not vIsOneRoomRate Then  
				If ValueIsFilled(vCurRes.RoomRate) And ValueIsFilled(vCurRes.RoomRate.FeeTerms) Then 
					vRoomCancellationConditions = vTemplate.GetArea("RoomCancellationConditions");
					vRoomCancellationConditionsParameters = New Structure;
					If vCurRes.ReservationStatus.IsGuaranteed Then
						mCancellationConditions = cmNstr(vCurRes.Roomrate.FeeTerms.ConfirmationTextForGuaranteedReservation, SelLanguage);
					Else
						mCancellationConditions = cmNstr(vCurRes.Roomrate.FeeTerms.ConfirmationText,SelLanguage);
					EndIf;
					vRoomCancellationConditionsParameters.Insert("mCancellationConditions", mCancellationConditions);
					FillPropertyValues(vRoomCancellationConditions.Parameters,vRoomCancellationConditionsParameters);
					If Not IsBlankString(mCancellationConditions) Then
						vArrayOfAreas.Add(vRoomCancellationConditions);
					EndIf;
				EndIf;
			EndIf;  
		EndIf;
	EndDo; 
	
	If vRoomsTotal > 1 Then 
		vGroupTotalParameters = New Structure;
		vGroupTotal = vTemplate.GetArea("GroupTotal"); 
		vGroupTotalParameters.Insert("mRoomsTotal", Format(vRoomsTotal));
		vGroupTotalParameters.Insert("mGuestsTotal", Format(vGuestsTotal));   
		If SelHideRoomRateAndSum Then   
			vGroupTotalParameters.Insert("mTotalGroupAmount", "");
		Else	
			vGroupTotalParameters.Insert("mTotalGroupAmount",  cmFormatSum(vTotalGroupAmount, vCurRes.ReportingCurrency, "NZ=0.00")); 
		EndIf;
		FillPropertyValues(vGroupTotal.Parameters, vGroupTotalParameters);
		vSpreadsheet.Put(vGroupTotal);
	EndIf;
	
	// Get external system interactions
	vIntegration = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsGuestlink(SelReservation.Hotel);
	vOnlineModuleLink = "";
	If Not vIntegration = Undefined Then
		vOnlineModuleLink = vIntegration.HttpAddress;
	EndIf;	
	
	// Payment link
	If SelShowPaymentLink And vTemplate.Areas.Find("PaymentLinkRow") <> Undefined Then
		If Not IsBlankString(vOnlineModuleLink) And ValueIsFilled(SelReservation.Guest) Then
			vPaymentLinkRowParameters = New Structure;
			vPaymentLinkArea = vTemplate.GetArea("PaymentLinkRow");
			vPaymentLinkText = cmNStr("en='To pay for your reservation click on the link '; ru='Для оплаты брони перейдите по ссылке '; de='Um Ihre Reservierung zu bezahlen, klicken Sie auf den Link '", SelLanguage);
			
			SelExternalSystemInteraction = Undefined;
			vPaymentLink = Catalogs.ExternalSystemInteractions.GetReservationGuestURL(SelReservation, SelExternalSystemInteraction);
			
			vPaymentLinkRowParameters.Insert("mPaymentLinkText", vPaymentLinkText);
			vPaymentLinkRowParameters.Insert("mPaymentLink", vPaymentLink);  
			FillPropertyValues(vPaymentLinkArea.Parameters, vPaymentLinkRowParameters);
			vSpreadsheet.Put(vPaymentLinkArea);
		ElsIf lower(Left(TrimL(SelObjectPrintForm.FormText), 4)) = "http" Then
			vPaymentLinkRowParameters = New Structure;
			vPaymentLinkArea = vTemplate.GetArea("PaymentLinkRow");
			vPaymentLinkText = cmNStr("en='To pay for your reservation click on the link '; ru='Для оплаты брони перейдите по ссылке '; de='Um Ihre Reservierung zu bezahlen, klicken Sie auf den Link '", SelLanguage);
			vPaymentLink = TrimAll(SelObjectPrintForm.FormText);
			vPaymentLinkRowParameters.Insert("mPaymentLinkText", vPaymentLinkText);
			vPaymentLinkRowParameters.Insert("mPaymentLink", vPaymentLink);  
			FillPropertyValues(vPaymentLinkArea.Parameters, vPaymentLinkRowParameters);
			vSpreadsheet.Put(vPaymentLinkArea);
		EndIf;
	EndIf;
	
	For Each vRowArea In vArrayOfAreas Do
		vSpreadsheet.Put(vRowArea); 
	EndDo;
	
	// Show paid amount
	If StrFind(vParameter, "SHOW_TOTAL_PAID_AMOUNT") > 0 And Not SelHideRoomRateAndSum Then
		vGroupPaymentTotalsParameters = New Structure;
		vGroupPaymentTotals = vTemplate.GetArea("GroupPayments"); 
		vGroupPaymentTotalsParameters.Insert("mTotalPaidAmount", cmFormatSum(vTotalPaidSum, vCurRes.ReportingCurrency, "NZ=0.00")); 
		vGroupPaymentTotalsParameters.Insert("mTotalToBePaidAmount", cmFormatSum(vTotalGroupAmount - vTotalPaidSum, vCurRes.ReportingCurrency, "NZ=0.00")); 
		FillPropertyValues(vGroupPaymentTotals.Parameters, vGroupPaymentTotalsParameters);
		vSpreadsheet.Put(vGroupPaymentTotals);
	EndIf;
	
	// Use terms
	If vIsOneRoomRate Then  
		vLine = vTemplate.GetArea("Line");
		vSpreadsheet.Put(vLine);   
		
		vRoomReservationConditions = vTemplate.GetArea("RoomReservationConditions");
		vRoomReservationConditionsParameters = New Structure;
		mReservationConditionsFromReservationStatus = "";    
		If ValueIsFilled(SelReservation.ReservationStatus) And Not IsBlankString(SelReservation.ReservationStatus.ReservationConditions) Then 
			mReservationConditionsFromReservationStatus = cmNstr(SelReservation.ReservationStatus.ReservationConditions, SelLanguage);   
		EndIf;
		mReservationConditions = ""; 
		If ValueIsFilled(SelReservation.RoomRate) And Not IsBlankString(SelReservation.RoomRate.ReservationConditions) Then 
			If Not IsBlankString(mReservationConditionsFromReservationStatus) Then  
				mReservationConditions = mReservationConditionsFromReservationStatus + Chars.LF +
				cmNstr(SelReservation.RoomRate.ReservationConditions, SelLanguage);
			Else 	
				mReservationConditions = cmNstr(SelReservation.RoomRate.ReservationConditions, SelLanguage);  
			EndIf;
		ElsIf Not IsBlankString(SelReservation.Hotel.ReservationConditions) Then 
			If Not IsBlankString(mReservationConditionsFromReservationStatus) Then  
				mReservationConditions = mReservationConditionsFromReservationStatus + Chars.LF +
				cmNstr(SelReservation.Hotel.ReservationConditions, SelLanguage);
			Else 	
				mReservationConditions = cmNstr(SelReservation.Hotel.ReservationConditions, SelLanguage);  
			EndIf;
		Else
			mReservationConditions = mReservationConditionsFromReservationStatus;	
		EndIf;
		If Not IsBlankString(SelReservation.ConfirmationReply) Then
			mReservationConditions = mReservationConditions + ?(IsBlankString(mReservationConditions), "", Chars.LF + Chars.LF) + 
			TrimAll(SelReservation.ConfirmationReply);
		EndIf;
		
		If Not IsBlankString(mReservationConditions) Then
			vRoomReservationConditionsParameters.Insert("mReservationConditions", mReservationConditions);
			FillPropertyValues(vRoomReservationConditions.Parameters, vRoomReservationConditionsParameters);
			vSpreadsheet.Put(vRoomReservationConditions);
		EndIf;
	EndIf;   
	
	// Cancellation terms (one rate per group)	
	If vIsOneRoomRate Then   
		If ValueIsFilled(SelReservation.FeeTerms) Or (ValueIsFilled(SelReservation.RoomRate) And ValueIsFilled(SelReservation.Roomrate.FeeTerms)) Then
			vRoomCancellationConditions = vTemplate.GetArea("RoomCancellationConditions");
			vRoomCancellationConditionsParameters = New Structure; 
			If SelReservation.ReservationStatus.IsGuaranteed Then  
				If ValueIsFilled(SelReservation.FeeTerms) And Not IsBlankString(SelReservation.FeeTerms.ConfirmationTextForGuaranteedReservation) Then
					mCancellationConditions = cmNstr(SelReservation.FeeTerms.ConfirmationTextForGuaranteedReservation, SelLanguage); 
				Else
					mCancellationConditions = cmNstr(SelReservation.Roomrate.FeeTerms.ConfirmationTextForGuaranteedReservation, SelLanguage);
				EndIf;
			Else   
				If ValueIsFilled(SelReservation.FeeTerms) And Not IsBlankString(SelReservation.FeeTerms.ConfirmationText) Then
					mCancellationConditions = cmNstr(SelReservation.FeeTerms.ConfirmationText,SelLanguage);   
				Else
					mCancellationConditions = cmNstr(SelReservation.Roomrate.FeeTerms.ConfirmationText,SelLanguage);
				EndIf;
			EndIf;   
			If Not IsBlankString(mCancellationConditions) Then
				vRoomCancellationConditionsParameters.Insert("mCancellationConditions", mCancellationConditions);
				FillPropertyValues(vRoomCancellationConditions.Parameters,vRoomCancellationConditionsParameters);
				vSpreadsheet.Put(vRoomCancellationConditions); 
			EndIf;
		EndIf;
	EndIf;  
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);     	
EndProcedure // pmPrintConfirmation

#EndRegion

#Region Private

//-----------------------------------------------------------------------------
Procedure FillPricesAndServices(pObject, pPrices)
	pPrices = New ValueTable();
	pPrices.Columns.Add("Amount", cmGetSumTypeDescription());
	pPrices.Columns.Add("Service");
	pPrices.Columns.Add("AccommodationPlanAccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
	pPrices.Columns.Add("Sort", cmGetNumberTypeDescription(1, 0));
	pPrices.Columns.Add("AccountingDate", cmGetDateTypeDescription());
	pPrices.Columns.Add("Quantity", cmGetQuantityTypeDescription());
	
	// Add services from bound orders
	If ValueIsFilled(pObject.Ref) Then
		vOrders = Orders.cmGetOrdersByParentDoc(pObject.Ref);
		For Each vOrdersRow In vOrders Do
			If Not ValueIsFilled(vOrdersRow.Charge) And Not vOrdersRow.Ref.Status.IsOrderCancel Then
				vServicesRow = Services.Add();
				vServicesRow.AccountingDate = BegOfDay(vOrdersRow.Ref.OrderDateFrom);
				vServicesRow.IsInPrice = False;				
				vServicesRow.IsRoomRevenue = False;				
				vServicesRow.Quantity = vOrdersRow.Ref.Quantity;				
				vServicesRow.Sum = vOrdersRow.Ref.Sum;				
				vServicesRow.DiscountSum = 0;				
				vServicesRow.Service = vOrdersRow.Ref.Service;
				vServicesRow.AccommodationType = Catalogs.AccommodationTypes.EmptyRef();
				vServicesRow.IsManual = False;
			EndIf;
		EndDo;
	EndIf;
	
	// Process services
	For Each vRow In Services Do		
		vNewRow = pPrices.Add();
		If vRow.IsInPrice And vRow.IsRoomRevenue Then
			vNewRow.Service = "Price";
			vNewRow.Sort = 0;
			vNewRow.AccountingDate = vRow.AccountingDate;
			vNewRow.Quantity = vRow.Quantity;
			vNewRow.Amount = vRow.Sum - vRow.DiscountSum;
			
			vRoomRow = Undefined;
			vRoomRows = pPrices.FindRows(New Structure("Service, Sort, AccountingDate", "RoomPrice", 2, vRow.AccountingDate));
			If vRoomRows.Count() > 0 Then
				vRoomRow = vRoomRows.Get(0);
			Else
				vRoomRow = pPrices.Add();
				vRoomRow.Service = "RoomPrice";
				vRoomRow.Sort = 2;
				vRoomRow.AccountingDate = vRow.AccountingDate;
				vRoomRow.Quantity = vRow.Quantity;
			EndIf;
			vRoomRow.Amount = vRoomRow.Amount + vRow.Sum - vRow.DiscountSum;
		Else
			Service = vRow.Service;
			vNewRow.Service = Service;
			vNewRow.AccommodationPlanAccommodationType = vRow.AccommodationType;
			vNewRow.Sort = ?(vRow.IsInPrice, 1, 3);
			vNewRow.AccountingDate = vRow.AccountingDate;
			vWrkAccountingDate = vRow.AccountingDate;
			If ValueIsFilled(Service) And ValueIsFilled(Service.QuantityCalculationRule) Then
				vAccountingDateMove = cmGetAccountingDateMove(Service.QuantityCalculationRule, vRow.IsManual, pObject, False); 
				If vAccountingDateMove > 0 Then
					vNewRow.AccountingDate = vNewRow.AccountingDate + 24*3600;
				ElsIf vAccountingDateMove < 0 Then
					vWrkAccountingDate = vWrkAccountingDate - 24*3600;
				EndIf;
			EndIf;
			vNewRow.Quantity = vRow.Quantity;
			vNewRow.Amount = vRow.Sum - vRow.DiscountSum;
			
			If vRow.IsInPrice Then
				vRoomRow = Undefined;
				vRoomRows = pPrices.FindRows(New Structure("Service, Sort, AccountingDate", "RoomPrice", 2, vWrkAccountingDate));
				If vRoomRows.Count() > 0 Then
					vRoomRow = vRoomRows.Get(0);
				Else
					vRoomRow = pPrices.Add();
					vRoomRow.Service = "RoomPrice";
					vRoomRow.Sort = 2;
					vRoomRow.AccountingDate = vRow.AccountingDate;
					vRoomRow.Quantity = vRow.Quantity;
				EndIf;
				vRoomRow.Amount = vRoomRow.Amount + vRow.Sum - vRow.DiscountSum;
			EndIf;
		EndIf; 
	EndDo;
	
	pPrices.GroupBy("AccountingDate, Service, AccommodationPlanAccommodationType, Sort", "Quantity, Amount");
	If pPrices.Find("Price") = Undefined Then
		vCurDate = BegOfDay(pObject.CheckInDate);
		While vCurDate <= BegOfDay(pObject.CheckOutDate) Do
			vRowPrice = pPrices.Add();
			vRowPrice.AccountingDate = vCurDate;
			vRowPrice.Service = "Price";
			vRowPrice.Sort = 0;
			vRowPrice.Amount = 0;
			vCurDate = vCurDate + 24*3600;
		EndDo;
	EndIf; 
	If pPrices.Find("RoomPrice") = Undefined Then
		vCurDate = BegOfDay(pObject.CheckInDate);
		While vCurDate <= BegOfDay(pObject.CheckOutDate) Do
			vRowPrice = pPrices.Add();
			vRowPrice.AccountingDate = vCurDate;
			vRowPrice.Service = "RoomPrice";
			vRowPrice.Sort = 2;
			vRowPrice.Amount = 0;
			vCurDate = vCurDate + 24*3600;
		EndDo;
	EndIf; 
	pPrices.Sort("Sort, Service, AccommodationPlanAccommodationType");  	
EndProcedure

//-----------------------------------------------------------------------------
Function GetReservationRoomServices(pResRef)
	vServices = cmGetReservationServices(pResRef);
	vOneRoomReservations = cmGetOneRoomReservations(pResRef.Number, pResRef.GuestGroup, pResRef.CheckInDate, pResRef.CheckOutDate);
	For Each vResRow In vOneRoomReservations Do
		vResRef = vResRow.Ref;
		If vResRef <> pResRef Then
			vAddServices = cmGetReservationServices(vResRef);
			For Each vAddServicesRow In vAddServices Do
				vSrvRow = vServices.Add();
				FillPropertyValues(vSrvRow, vAddServicesRow); 
			EndDo;
		EndIf;
	EndDo;
	Return vServices;
EndFunction // GetReservationRoomServices

#EndRegion
