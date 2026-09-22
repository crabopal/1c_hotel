// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet, pTemplate = Undefined, pIsPersonal = False, pTypeOfPrint = "1") Export    	
	pSpreadsheet.Clear();
		
	vTemplate = ThisObject.GetTemplate("Form7");
	If pTemplate <> Undefined Then
		vTemplate = pTemplate;
	EndIf;
	If ValueIsFilled(ObjectPrintingForm) Then
		vLanguage = ObjectPrintingForm.Language; 		
	EndIf;
	If Not ValueIsFilled(vLanguage) Then
		vLanguage = SessionParameters.CurrentLanguage;
	EndIf;  	 
 	
	vArray = New Array;
    vArray2 = New Array;   
	
	// Print guest form
	If ValueIsFilled(CheckOutDate) Then
		PrintGuestFormsForCheckOutDate(pSpreadsheet, vTemplate, pTypeOfPrint, vArray, vArray2);
	ElsIf Not ValueIsFilled(GuestGroup) Then 		
		If pIsPersonal Then 			
			PrintGuestForm(pSpreadsheet, vTemplate, pTypeOfPrint, vArray, vArray2);  					
		Else
			PrintGuestFormsForRoom(pSpreadsheet, vTemplate, pTypeOfPrint, vArray, vArray2);
		EndIf;
	Else
		PrintGuestFormsForGuestGroup(pSpreadsheet, vTemplate, pTypeOfPrint, vArray, vArray2);
	EndIf;  
	
	If pTypeOfPrint = "1" Or  pTypeOfPrint = "3"  Then
		vArrayCount = vArray.Count(); 		
	ElsIf pTypeOfPrint = "2" Then
		vArrayCount = vArray2.Count(); 		
	EndIf;   
	vShitCount = Int(vArrayCount/4);   
	If vArrayCount%4 > 0 Then
		vShitCount = vShitCount+1; 
	EndIf;

	vIndex = 0; 
	vPutPageBreak = False;
	vJoin = False;

	For j = 0 to vShitCount-1 Do   
		If pTypeOfPrint = "1" Or pTypeOfPrint = "3" Then
			For i = 0 To 3 Do   
			    vIndex = j*4+i;
				If vIndex >= vArrayCount Then
					Continue;
				EndIf;
				If Print2On1Page Then
					vPutPageBreak = False;
					If (vIndex + 1)/2 <> Int((vIndex + 1)/2) Then
						vPutPageBreak = True;
					Else
						vPutPageBreak = False;
					EndIf;
				Else
					vPutPageBreak = False;
					If (vIndex)/4 = Int((vIndex)/4) Then
						vPutPageBreak = True;
					Else
						vPutPageBreak = False;
					EndIf;
					vJoin = False;
					If (vIndex + 1)/2 = Int((vIndex + 1)/2) Then
						vJoin = True;
					Else
						vJoin = False;
					EndIf;
				EndIf;
                If vPutPageBreak Then
					pSpreadsheet.PutHorizontalPageBreak();
				EndIf; 		
				If vJoin Then
					pSpreadsheet.Join(vArray[vIndex]); 
				Else
					pSpreadsheet.Put(vArray[vIndex]);
				EndIf;     
			EndDo;  
		EndIf; 
		If pTypeOfPrint = "3" Then
			pSpreadsheet.PutHorizontalPageBreak();  
        EndIf;
		If pTypeOfPrint = "2" Or pTypeOfPrint = "3" Then
		    For i = 0 To 3 Do   
			    vIndex = j*4+i;
				If vIndex >= vArrayCount Then
					Continue;
				EndIf;
				If Print2On1Page Then
					vPutPageBreak = False;
					If (vIndex + 1)/2 <> Int((vIndex + 1)/2) Then
						vPutPageBreak = True;
					Else
						vPutPageBreak = False;
					EndIf;
				Else
					vPutPageBreak = False;
					If (vIndex)/4 = Int((vIndex)/4) Then
						vPutPageBreak = True;
					Else
						vPutPageBreak = False;
					EndIf;
					vJoin = False;
					If (vIndex + 1)/2 = Int((vIndex + 1)/2) Then
						vJoin = True;
					Else
						vJoin = False;
					EndIf;
				EndIf;
                If vPutPageBreak Then
					pSpreadsheet.PutHorizontalPageBreak();
				EndIf; 		
				If vJoin Then
					pSpreadsheet.Join(vArray2[vIndex]); 
				Else
					pSpreadsheet.Put(vArray2[vIndex]);
				EndIf;     
			EndDo;    
		EndIf;
	EndDo;   	
EndProcedure // pmGenerate

// -----------------------------------------------------------------------------
Function pmGetHouse(pHouseStr) Export
	vHouse = "";
	For i = 1 To StrLen(pHouseStr) Do
		vChar = Mid(pHouseStr, i, 1);
		If IsBlankString(vChar) Or Not cmIsNumber(vChar) Then
			Break;
		Else
			vHouse = vHouse + vChar;
		EndIf;
	EndDo;
	Return vHouse;
EndFunction // pmGetHouse

// -----------------------------------------------------------------------------
Function pmGetBuilding(pHouseStr) Export
	vBuilding = "";
	vHouse = pmGetHouse(pHouseStr);
	If TrimAll(vHouse) <> TrimAll(pHouseStr) Then
		vBuilding = TrimAll(Mid(pHouseStr, StrLen(vHouse) + 1));
		If StrLen(vBuilding) > 1 Then
			If Left(vBuilding, 1) = "/" Or 
			   Left(vBuilding, 1) = "\" Or
			   UPPER(Left(vBuilding, 1)) = "К" Then
				vBuilding = TrimAll(Mid(vBuilding, 2));
			EndIf;
		EndIf;
	EndIf;
	Return vBuilding;
EndFunction // pmGetBuilding

// -----------------------------------------------------------------------------
Procedure SetParameters(pGuestForm, pDocument)
	If ValueIsFilled(pDocument.Guest) Then
		vGuest = pDocument.Guest;
		// Guest names
		pGuestForm.Parameters.mGuestLastName = Upper(TrimAll(vGuest.LastName));
		pGuestForm.Parameters.mGuestFirstName = Upper(TrimAll(vGuest.FirstName));
		pGuestForm.Parameters.mGuestSecondName = Upper(TrimAll(vGuest.SecondName));
		// Guest birth date
		vGuestDateOfBirth = Upper(Format(vGuest.DateOfBirth, "L=ru_RU; DLF=DD"));
		If vGuestDateOfBirth <> "" Then
			vGuestDateOfBirth = Left(vGuestDateOfBirth, StrLen(vGuestDateOfBirth) - 3);
		EndIf;
		pGuestForm.Parameters.mGuestDateOfBirth = vGuestDateOfBirth;
		// Guest place of birth
		vPlaceOfBirth = cmParseAddress(vGuest.PlaceOfBirth);
		// Guest birth place
		pGuestForm.Parameters.mGuestBirthPlaceCountry = Upper(TrimAll(vPlaceOfBirth.Country));
		pGuestForm.Parameters.mGuestBirthPlaceRegion = Upper(TrimAll(vPlaceOfBirth.Region));
		pGuestForm.Parameters.mGuestBirthPlaceArea = Upper(TrimAll(vPlaceOfBirth.Area));
		vCity = Upper(TrimAll(vPlaceOfBirth.City));
		If Find(vCity, "Г.") > 0 Then
			pGuestForm.Parameters.mGuestBirthPlaceCity = vCity;
			pGuestForm.Parameters.mGuestBirthPlaceTown = "";
		ElsIf Right(vCity, 2) = " Г" Then
			pGuestForm.Parameters.mGuestBirthPlaceCity = vCity;
			pGuestForm.Parameters.mGuestBirthPlaceTown = "";
		ElsIf Left(vCity, 2) = "Г " Then
			pGuestForm.Parameters.mGuestBirthPlaceCity = vCity;
			pGuestForm.Parameters.mGuestBirthPlaceTown = "";
		Else
			pGuestForm.Parameters.mGuestBirthPlaceCity = "";
			pGuestForm.Parameters.mGuestBirthPlaceTown = vCity;
		EndIf;
		pGuestForm.Parameters.mGuestCitizenship = Upper(String(vGuest.Citizenship));
		pGuestForm.Parameters.mGuestSex = Left(vGuest.Sex,3);
		// Guest address
		vGuestAddress = cmParseAddress(vGuest.Address);
		vGuestAddress.Street = StrReplace(vGuestAddress.Street, " ул.", "");
		vGuestAddress.Street = StrReplace(vGuestAddress.Street, " ул", "");
		pGuestForm.Parameters.mGuestRegionRegistration  = Upper(String(vGuestAddress.Region));
		pGuestForm.Parameters.mGuestAreaRegistration = Upper(String(vGuestAddress.Area)); 	
		pGuestForm.Parameters.mGuestCountry = Upper(String(vGuestAddress.Country));
		pGuestForm.Parameters.mGuestRegion  = Upper(String(vGuestAddress.Region));
		pGuestForm.Parameters.mGuestArea = Upper(String(vGuestAddress.Area));
		vCity = Upper(TrimAll(vGuestAddress.City)); 
		If Find(vCity, "Г.") > 0 Then
			pGuestForm.Parameters.mGuestCityRegistration = vCity;
			pGuestForm.Parameters.mGuestTownRegistration = ""; 
			pGuestForm.Parameters.mGuestCity = vCity;
			pGuestForm.Parameters.mGuestTown = "";
		ElsIf Right(vCity, 2) = " Г" Then
			pGuestForm.Parameters.mGuestCityRegistration = vCity;
			pGuestForm.Parameters.mGuestTownRegistration = "";
			pGuestForm.Parameters.mGuestCity = vCity;
			pGuestForm.Parameters.mGuestTown = "";
		ElsIf Left(vCity, 2) = "Г " Then
			pGuestForm.Parameters.mGuestCityRegistration = vCity;
			pGuestForm.Parameters.mGuestTownRegistration = "";   
			pGuestForm.Parameters.mGuestCity = vCity;
			pGuestForm.Parameters.mGuestTown = "";
		Else
			pGuestForm.Parameters.mGuestCityRegistration = "";
			pGuestForm.Parameters.mGuestTownRegistration = vCity;  
			pGuestForm.Parameters.mGuestCity = "";
			pGuestForm.Parameters.mGuestTown = vCity;
		EndIf;
		pGuestForm.Parameters.mGuestStreetRegistration = Upper(String(vGuestAddress.Street));    
		pGuestForm.Parameters.mGuestStreet = Upper(String(vGuestAddress.Street));
		vAddressFullHouse = Upper(vGuestAddress.House);
		vAddressHouse = pmGetHouse(vAddressFullHouse);
		vAddressBuilding = pmGetBuilding(vAddressFullHouse);
		pGuestForm.Parameters.mGuestHouseRegistration = vAddressHouse;
		pGuestForm.Parameters.mGuestBuildRegistration = vAddressBuilding;
		pGuestForm.Parameters.mGuestAptRegistration = Upper(vGuestAddress.Flat);   
		pGuestForm.Parameters.mGuestHouse = vAddressHouse;
		pGuestForm.Parameters.mGuestBuild = vAddressBuilding;
		pGuestForm.Parameters.mGuestApt = Upper(vGuestAddress.Flat);    
		
		// Regestration date
		vDateFromRegistration = Upper(Format(vGuest.AddressRegistrationDate, "L=ru_RU; DLF=DD"));
		If vDateFromRegistration <> "" Then
			vDateFromRegistration = Left(vDateFromRegistration, StrLen(vDateFromRegistration) - 3);
		EndIf;
		pGuestForm.Parameters.mDateFromRegistration = vDateFromRegistration;

		// Guest identity document data
		pGuestForm.Parameters.mGuestIDType = Upper(TrimAll(vGuest.IdentityDocumentType));
		pGuestForm.Parameters.mGuestIDIssueDate = StrReplace(Upper(Format(vGuest.IdentityDocumentIssueDate, "L=ru_RU; DLF=DD")), "Г.", "г.");
		
		pGuestForm.Parameters.mGuestIDSeries = TrimAll(vGuest.IdentityDocumentSeries);
		pGuestForm.Parameters.mGuestIDNumber = TrimAll(vGuest.IdentityDocumentNumber);
		pGuestForm.Parameters.mGuestIDUnitCode = TrimAll(vGuest.IdentityDocumentUnitCode);
		vPos = 30;
		If StrLen(TrimAll(vGuest.IdentityDocumentIssuedBy)) > 30 Then
			While vPos > 1 Do
				If Mid(TrimAll(vGuest.IdentityDocumentIssuedBy), vPos, 1) = " " Then
					Break;
				Else
					vPos = vPos - 1;
				EndIf;
			EndDo;
		EndIf;
		pGuestForm.Parameters.mGuestIDIssuedBy = TrimAll(Left(TrimAll(vGuest.IdentityDocumentIssuedBy), vPos));
		pGuestForm.Parameters.mGuestIDIssuedBy2 = TrimAll(Mid(TrimAll(vGuest.IdentityDocumentIssuedBy), vPos + 1));   
	Else
		// Guest names
		pGuestForm.Parameters.mGuestLastName = "";
		pGuestForm.Parameters.mGuestFirstName = "";
		pGuestForm.Parameters.mGuestSecondName = "";
		// Guest birth date
		pGuestForm.Parameters.mGuestDateOfBirth = "";
		// Guest address
		pGuestForm.Parameters.mGuestCitizenship = "";    
		pGuestForm.Parameters.mGuestSex = "";
		pGuestForm.Parameters.mGuestCountry = "";
		// Guest place of birth
		pGuestForm.Parameters.mGuestBirthPlaceCountry = "";
		pGuestForm.Parameters.mGuestBirthPlaceRegion = "";
		pGuestForm.Parameters.mGuestBirthPlaceArea = "";
		pGuestForm.Parameters.mGuestBirthPlaceCity = "";
		// Guest identity document data
		pGuestForm.Parameters.mGuestIDType = "";
		pGuestForm.Parameters.mGuestIDSeries = "";
		pGuestForm.Parameters.mGuestIDNumber = "";
		pGuestForm.Parameters.mGuestIDIssuedBy = "";
		pGuestForm.Parameters.mGuestIDIssuedBy2 = "";
		pGuestForm.Parameters.mGuestIDUnitCode = "";
		pGuestForm.Parameters.mGuestIDIssueDate = "";
		pGuestForm.Parameters.mGuestRegionRegistration  = "";
		pGuestForm.Parameters.mGuestAreaRegistration = "";	
		pGuestForm.Parameters.mGuestRegion  ="";
		pGuestForm.Parameters.mGuestArea ="";
		pGuestForm.Parameters.mGuestCityRegistration = "";	
		pGuestForm.Parameters.mGuestTownRegistration = ""; 
		pGuestForm.Parameters.mGuestCity ="";
		pGuestForm.Parameters.mGuestTown = "";
		pGuestForm.Parameters.mGuestStreetRegistration ="";   
		pGuestForm.Parameters.mGuestStreet = "";
		pGuestForm.Parameters.mGuestHouseRegistration = "";
		pGuestForm.Parameters.mGuestBuildRegistration ="";
		pGuestForm.Parameters.mGuestAptRegistration = "";   
		pGuestForm.Parameters.mGuestHouse = "";
		pGuestForm.Parameters.mGuestBuild = "";
		pGuestForm.Parameters.mGuestApt = "";  
		pGuestForm.Parameters.mDateFromRegistration = "";
	EndIf;   
EndProcedure // SetParameters

// -----------------------------------------------------------------------------
Procedure SetParameters2(pGuestForm, pDocument)
	If ValueIsFilled(pDocument.Guest) Then
		vGuest = pDocument.Guest;  	
		vGuestAddress = cmParseAddress(vGuest.Address);
		vGuestAddress.Street = StrReplace(vGuestAddress.Street, " ул.", "");
		vGuestAddress.Street = StrReplace(vGuestAddress.Street, " ул", "");
		pGuestForm.Parameters.mGuestCountry = Upper(String(vGuestAddress.Country));
		pGuestForm.Parameters.mGuestRegion  = Upper(String(vGuestAddress.Region));
		pGuestForm.Parameters.mGuestArea = Upper(String(vGuestAddress.Area));
		vCity = Upper(TrimAll(vGuestAddress.City)); 
		If Find(vCity, "Г.") > 0 Then
			pGuestForm.Parameters.mGuestCity = vCity;
			pGuestForm.Parameters.mGuestTown = "";
		ElsIf Right(vCity, 2) = " Г" Then
			pGuestForm.Parameters.mGuestCity = vCity;
			pGuestForm.Parameters.mGuestTown = "";
		ElsIf Left(vCity, 2) = "Г " Then
			pGuestForm.Parameters.mGuestCity = vCity;
			pGuestForm.Parameters.mGuestTown = "";
		Else
			pGuestForm.Parameters.mGuestCity = "";
			pGuestForm.Parameters.mGuestTown = vCity;
		EndIf;
		pGuestForm.Parameters.mGuestStreet = Upper(String(vGuestAddress.Street));
		vAddressFullHouse = Upper(vGuestAddress.House);
		vAddressHouse = pmGetHouse(vAddressFullHouse);
		vAddressBuilding = pmGetBuilding(vAddressFullHouse);
		pGuestForm.Parameters.mGuestHouse = vAddressHouse;
		pGuestForm.Parameters.mGuestBuild = vAddressBuilding;
		pGuestForm.Parameters.mGuestApt = Upper(vGuestAddress.Flat);  		
	Else
		pGuestForm.Parameters.mGuestCountry = "";
		pGuestForm.Parameters.mGuestRegion  = "";
		pGuestForm.Parameters.mGuestArea ="";
		pGuestForm.Parameters.mGuestCity = "";
		pGuestForm.Parameters.mGuestTown = "";
		pGuestForm.Parameters.mGuestStreet = "";
		pGuestForm.Parameters.mGuestHouse = "";
		pGuestForm.Parameters.mGuestBuild = "";
		pGuestForm.Parameters.mGuestApt = "";    		
	EndIf;  
	vCurrentDate = Upper(Format(CurrentSessionDate(), "L=ru_RU; DLF=DD"));
	If vCurrentDate <> "" Then
		vCurrentDate = Left(vCurrentDate, StrLen(vCurrentDate) - 3);
	EndIf;
	pGuestForm.Parameters.mCurrentDate = vCurrentDate;   
EndProcedure // SetParameters

// -----------------------------------------------------------------------------
Procedure PrintGuestFormsForGuestGroup(pSpreadsheet, vTemplate, pTypeOfPrint, vArray, vArray2)
	If ValueIsFilled(GuestGroup) Then 
		vAccommodations = GuestGroup.GetObject().pmGetAccommodations();

		vPutPageBreak = False;
		vJoin = False;
		
		vGuestForm = Undefined; 
		vGuestForm2 = Undefined;
		For Each vRow In vAccommodations Do 
			vCurDocument = vRow.Accommodation;
			If ValueIsFilled(vCurDocument) And ValueIsFilled(vCurDocument.AccommodationType) And 
			   Not vCurDocument.AccommodationType.DoNotIssueKeyCards Then
				If Print2On1Page Then
					vPutPageBreak = False;
					If (vAccommodations.IndexOf(vRow) + 1)/2 <> Int((vAccommodations.IndexOf(vRow) + 1)/2) Then
						vPutPageBreak = True;
					Else
						vPutPageBreak = False;
					EndIf;
					vGuestForm = vTemplate.GetArea("GuestForm"); 
					vGuestForm2 = vTemplate.GetArea("GuestForm2");
				Else
					vPutPageBreak = False;
					If (vAccommodations.IndexOf(vRow))/4 = Int((vAccommodations.IndexOf(vRow))/4) Then
						vPutPageBreak = True;
					Else
						vPutPageBreak = False;
					EndIf;
					vJoin = False;
					If (vAccommodations.IndexOf(vRow))/2 <> Int((vAccommodations.IndexOf(vRow))/2) Then
						vJoin = True;
						vGuestForm = vTemplate.GetArea("GuestForm|Right"); 
						vGuestForm2 = vTemplate.GetArea("GuestForm2|Right");
					Else
						vJoin = False;
						vGuestForm = vTemplate.GetArea("GuestForm|Left");
						vGuestForm2 = vTemplate.GetArea("GuestForm2|Left");    
					EndIf;
				EndIf;
				vDoPrint = True;
				If ValueIsFilled(RoomType) Then
					If RoomType.IsFolder Then
						If Not vCurDocument.RoomType.BelongsToItem(RoomType) Then
							vDoPrint = False;
						EndIf;
					Else
						If RoomType <> vCurDocument.RoomType Then
							vDoPrint = False;
						EndIf;
					EndIf;
				EndIf;
				If vDoPrint Then	
					If pTypeOfPrint = "1" Then
						SetParameters(vGuestForm,vCurDocument);
						vArray.Add(vGuestForm);
					ElsIf pTypeOfPrint = "2" Then
						SetParameters2(vGuestForm2, vCurDocument); 
						vArray2.Add(vGuestForm2);
					ElsIf pTypeOfPrint = "3" Then
						SetParameters(vGuestForm, vCurDocument);
						vArray.Add(vGuestForm);
						SetParameters2(vGuestForm2, vCurDocument); 
						vArray2.Add(vGuestForm2);   
					EndIf;   
				EndIf;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // PrintGuestFormsForGuestGroup

// -----------------------------------------------------------------------------
Procedure PrintGuestFormsForCheckOutDate(pSpreadsheet, vTemplate, pTypeOfPrint, vArray, vArray2)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Document
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Posted
	|	AND Accommodation.RoomType IN HIERARCHY(&qRoomType)
	|	AND (&qGuestGroupIsEmpty
	|			OR NOT &qGuestGroupIsEmpty
	|				AND Accommodation.GuestGroup = &qGuestGroup)
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsCheckIn
	|	AND NOT Accommodation.AccommodationType.DoNotIssueKeyCards
	|	AND Accommodation.CheckOutDate >= &qBegOfDate
	|	AND Accommodation.CheckOutDate <= &qEndOfDate
	|	AND Accommodation.Guest <> &qEmptyClient
	|	AND Accommodation.Guest.Citizenship = Accommodation.Hotel.Citizenship
	|	AND Accommodation.Hotel = &qHotel
	|
	|ORDER BY
	|	Accommodation.CheckOutDate,
	|	Accommodation.GuestGroup.Code,
	|	Accommodation.Room.SortCode,
	|	Accommodation.GuestFullName";
	vQry.SetParameter("qBegOfDate", BegOfDay(CheckOutDate));
	vQry.SetParameter("qEndOfDate", EndOfDay(CheckOutDate));
	vQry.SetParameter("qRoomType", RoomType);
	vQry.SetParameter("qGuestGroup", GuestGroup);
	vQry.SetParameter("qGuestGroupIsEmpty", Not ValueIsFilled(GuestGroup));
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qHotel", ?(ValueIsFilled(Document), Document.Hotel, SessionParameters.CurrentHotel));
	vDocs = vQry.Execute().Unload();
	vPutPageBreak = False;
	vJoin = False;      
	
	vGuestForm = Undefined; 
	vGuestForm2 = Undefined;  
	For Each vRow In vDocs Do
		If ValueIsFilled(vRow) And ValueIsFilled(vRow.AccommodationType) And 
		   Not vRow.AccommodationType.DoNotIssueKeyCards Then
			If Print2On1Page Then
				vPutPageBreak = False;
				If (vDocs.IndexOf(vRow) + 1)/2 <> Int((vDocs.IndexOf(vRow) + 1)/2) Then
					vPutPageBreak = True;
				Else
					vPutPageBreak = False;
				EndIf;
				vGuestForm = vTemplate.GetArea("GuestForm"); 
				vGuestForm2 = vTemplate.GetArea("GuestForm2");
			Else
				vPutPageBreak = False;
				If (vDocs.IndexOf(vRow))/4 = Int((vDocs.IndexOf(vRow))/4) Then
					vPutPageBreak = True;
				Else
					vPutPageBreak = False;
				EndIf;
				vJoin = False;
				If (vDocs.IndexOf(vRow))/2 <> Int((vDocs.IndexOf(vRow))/2) Then
					vJoin = True;
					vGuestForm = vTemplate.GetArea("GuestForm|Right"); 
					vGuestForm2 = vTemplate.GetArea("GuestForm2|Right");
				Else
					vJoin = False;
					vGuestForm = vTemplate.GetArea("GuestForm|Left");
					vGuestForm2 = vTemplate.GetArea("GuestForm2|Left");    
				EndIf;
			EndIf;
			vDoPrint = True;
			If ValueIsFilled(RoomType) Then
				If RoomType.IsFolder Then
					If Not vRow.RoomType.BelongsToItem(RoomType) Then
						vDoPrint = False;
					EndIf;
				Else
					If RoomType <> vRow.RoomType Then
						vDoPrint = False;
					EndIf;
				EndIf;
			EndIf;
			If vDoPrint Then	
				If pTypeOfPrint = "1" Then
					SetParameters(vGuestForm, vRow);
					vArray.Add(vGuestForm);
				ElsIf pTypeOfPrint = "2" Then
					SetParameters2(vGuestForm2,vRow); 
					vArray2.Add(vGuestForm2);
				ElsIf pTypeOfPrint = "3" Then
					SetParameters(vGuestForm,vRow);
					vArray.Add(vGuestForm);
					SetParameters2(vGuestForm2, vRow); 
					vArray2.Add(vGuestForm2);   
				EndIf;   
			EndIf;
		EndIf;
	EndDo;
EndProcedure // PrintGuestFormsForCheckOutDate

// -----------------------------------------------------------------------------
Procedure PrintGuestFormsForRoom(pSpreadsheet, vTemplate, pTypeOfPrint, vArray, vArray2)
	vAccommodations = New ValueList();
	vAccommodations.Add(Document);
	AddOneRoomAccommodations(vAccommodations);

	vPutPageBreak = False;
	vJoin = False;
 
	vGuestForm = Undefined; 
	vGuestForm2 = Undefined;  
	For Each vDocItem In vAccommodations Do
		If ValueIsFilled(vDocItem.Value) And ValueIsFilled(vDocItem.Value.AccommodationType) And 
		   Not vDocItem.Value.AccommodationType.DoNotIssueKeyCards Then
			If Print2On1Page Then
				vPutPageBreak = False;
				If (vAccommodations.IndexOf(vDocItem) + 1)/2 <> Int((vAccommodations.IndexOf(vDocItem) + 1)/2) Then
					vPutPageBreak = True;
				Else
					vPutPageBreak = False;
				EndIf;
				vGuestForm = vTemplate.GetArea("GuestForm"); 
				vGuestForm2 = vTemplate.GetArea("GuestForm2");
			Else
				vPutPageBreak = False;
				If (vAccommodations.IndexOf(vDocItem))/4 = Int((vAccommodations.IndexOf(vDocItem))/4) Then
					vPutPageBreak = True;
				Else
					vPutPageBreak = False;
				EndIf;
				vJoin = False;
				If (vAccommodations.IndexOf(vDocItem))/2 <> Int((vAccommodations.IndexOf(vDocItem))/2) Then
					vJoin = True;
					vGuestForm = vTemplate.GetArea("GuestForm|Right"); 
					vGuestForm2 = vTemplate.GetArea("GuestForm2|Right");
				Else
					vJoin = False;
					vGuestForm = vTemplate.GetArea("GuestForm|Left");
					vGuestForm2 = vTemplate.GetArea("GuestForm2|Left");    
				EndIf;
			EndIf;
			vDoPrint = True;
			If ValueIsFilled(RoomType) Then
				If RoomType.IsFolder Then
					If Not vDocItem.Value.RoomType.BelongsToItem(RoomType) Then
						vDoPrint = False;
					EndIf;
				Else
					If RoomType <> vDocItem.Value.RoomType Then
						vDoPrint = False;
					EndIf;
				EndIf;
			EndIf;
			If vDoPrint Then	
				If pTypeOfPrint = "1" Then
					SetParameters(vGuestForm, vDocItem.Value);
					vArray.Add(vGuestForm);
				ElsIf pTypeOfPrint = "2" Then
					SetParameters2(vGuestForm2, vDocItem.Value); 
					vArray2.Add(vGuestForm2);
				ElsIf pTypeOfPrint = "3" Then
					SetParameters(vGuestForm, vDocItem.Value);
					vArray.Add(vGuestForm);
					SetParameters2(vGuestForm2, vDocItem.Value); 
					vArray2.Add(vGuestForm2);   
				EndIf;   
			EndIf;
		EndIf;
	EndDo;
EndProcedure // PrintGuestFormsForRoom

// -----------------------------------------------------------------------------
Procedure PrintGuestForm(pSpreadsheet, vTemplate, pTypeOfPrint, vArray, vArray2)    
	If Print2On1Page Then
		vGuestForm = vTemplate.GetArea("GuestForm"); 
		vGuestForm2 = vTemplate.GetArea("GuestForm2");
	Else
		vGuestForm = vTemplate.GetArea("GuestForm|Left");
		vGuestForm2 = vTemplate.GetArea("GuestForm2|Left");    
	EndIf;  
	vDoPrint = True;
	If ValueIsFilled(RoomType) Then
		If RoomType.IsFolder Then
			If Not Document.RoomType.BelongsToItem(RoomType) Then
				vDoPrint = False;
			EndIf;
		Else
			If RoomType <> Document.RoomType Then
				vDoPrint = False;
			EndIf;
		EndIf;
	EndIf;
	If vDoPrint Then	
		If pTypeOfPrint = "1" Then
			SetParameters(vGuestForm,Document);
			vArray.Add(vGuestForm);
		ElsIf pTypeOfPrint = "2" Then
			SetParameters2(vGuestForm2, Document); 
			vArray2.Add(vGuestForm2);
		ElsIf pTypeOfPrint = "3" Then
			SetParameters(vGuestForm, Document);
			vArray.Add(vGuestForm);
			SetParameters2(vGuestForm2, Document); 
			vArray2.Add(vGuestForm2);   
		EndIf;   
	EndIf;         
EndProcedure // PrintGuestForm

// -----------------------------------------------------------------------------
Procedure AddOneRoomAccommodations(rDocsList)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.Ref <> &qDoc
	|	AND Accommodation.Room = &qRoom
	|	AND Accommodation.GuestGroup = &qGuestGroup
	|	AND Accommodation.CheckOutDate > &qCheckInDate
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qDoc", Document);
	vQry.SetParameter("qRoom", Document.Room);
	vQry.SetParameter("qGuestGroup", Document.GuestGroup);
	vQry.SetParameter("qCheckInDate", Document.CheckInDate);
	vQryRes = vQry.Execute().Unload();
	For Each vQryResRow In vQryRes Do
		rDocsList.Add(vQryResRow.Ref);
	EndDo;
EndProcedure // AddOneRoomAccommodations 
