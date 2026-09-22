
#Region Public

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet, pTemplate = Undefined) Export
	vParameters = New Structure;
	vParameters.Insert("mHotelName");

	vParameters.Insert("mCompanyName");
	vParameters.Insert("mCompanyTIN");
	vParameters.Insert("mCompanyKPP");
	vParameters.Insert("mCompanyOKPOCode");
	vParameters.Insert("mCompanyOKDP");
	vParameters.Insert("mCompanyDepartment");
	vParameters.Insert("mCompanyAddress");
	vParameters.Insert("mDebetAccount");
	vParameters.Insert("mCreditAccount");
	vParameters.Insert("mReason");
	vParameters.Insert("mSupplement");
	vParameters.Insert("mDirectorPosition");
	vParameters.Insert("mDirectorPositionInDative");  
	
	vParameters.Insert("mDirectorName");  
	vParameters.Insert("mDirectorInDative");

	vParameters.Insert("mCashierName");
	vParameters.Insert("mAccountantGeneralName");
	
	vParameters.Insert("mCashRegisterName");
	vParameters.Insert("mKKMManufactureNumber");
	vParameters.Insert("mKKMRegistrationNumber");

	vParameters.Insert("mGuestName"); 
	vParameters.Insert("mGuestNameHeader");

	vParameters.Insert("mGuestAddress1");
	vParameters.Insert("mGuestAddress2");
	vParameters.Insert("mGuestIDType");
	vParameters.Insert("mGuestIDSeries");
	vParameters.Insert("mGuestIDNumber");
	vParameters.Insert("mGuestIDIssued");
	vParameters.Insert("mRoom");
	vParameters.Insert("mCheckInDate");
	vParameters.Insert("mCheckOutDate");
	
	vParameters.Insert("mSum");
	vParameters.Insert("mSumInWords");
	vParameters.Insert("mReturnRemarks");
	vParameters.Insert("mReturnNumber");
	vParameters.Insert("mPaymentNumber");
	vParameters.Insert("mDate");
	vParameters.Insert("mAuthor");
	vParameters.Insert("mCurrency");
	
	vParameters.Insert("mQuantity");
	
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Fill parameters
	vHotel = Undefined;
	If ValueIsFilled(Document) Then
		If ValueIsFilled(Document.Hotel) Then
			vHotel = Document.Hotel;
		EndIf;
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	vCompany = Undefined;
	If ValueIsFilled(Document) Then
		If ValueIsFilled(Document.Company) Then
			vCompany = Document.Company;
		EndIf;
	ElsIf ValueIsFilled(vHotel) Then
		vCompany = vHotel.Company;
	EndIf;
	If ValueIsFilled(vCompany) Then
		// Hotel name
		vHotelName = TrimAll(vHotel.LegacyName);
		If IsBlankString(vHotelName) Then
			vHotelName = TrimAll(vHotel.Description);
		EndIf;
		vParameters.mHotelName = vHotelName;
		
		// Company name
		vCompanyName = TrimAll(vCompany.LegacyName);
		If IsBlankString(vCompanyName) Then
			vCompanyName = TrimAll(vCompany.Description);
		EndIf;
		vParameters.mCompanyName = vCompanyName;
		
		// Company parameters
		vParameters.mDirectorName = cmNStr(vCompany.Director, Catalogs.Languages.RU);   
		vParameters.mDirectorInDative = cmNStr(?(IsBlankString(vCompany.DirectorInDative), vCompany.Director, vCompany.DirectorInDative), Catalogs.Languages.RU);
		vParameters.mCompanyTIN = TrimAll(vCompany.TIN);
		vParameters.mCompanyKPP = TrimAll(vCompany.KPP);
		vParameters.mCompanyOKPOCode = TrimAll(vCompany.OKPO);
		vParameters.mCompanyOKDP = TrimAll(vCompany.OKDP);
		vParameters.mCompanyAddress = cmGetAddressPresentation(vCompany.LegacyAddress);
		vParameters.mCashierName = cmNStr(vCompany.CashierGeneral, Catalogs.Languages.RU);
		If ValueIsFilled(SessionParameters.CurrentUser) And vCompany.RKOShowCurrentManagerAsCashier Then
			vParameters.mCashierName = SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(Catalogs.Languages.RU);
		EndIf;
		vParameters.mAccountantGeneralName = cmNStr(vCompany.AccountantGeneral, Catalogs.Languages.RU);
		
		// Debet/credit account
		If IsBlankString(vCompany.RKODebetAccount) Then
			vParameters.mDebetAccount = "62.02";
		Else			
			vParameters.mDebetAccount = TrimAll(vCompany.RKODebetAccount);
		EndIf;
		If IsBlankString(vCompany.RKOCreditAccount) Then
			vParameters.mCreditAccount = "50.01";
		Else			
			vParameters.mCreditAccount = TrimAll(vCompany.RKOCreditAccount);
		EndIf;
		
		// Reason
		If IsBlankString(vCompany.RKOReason) Then
			vParameters.mReason = "";
		Else
			vParameters.mReason = TrimAll(vCompany.RKOReason);
		EndIf;
		
		// Supplement
		If IsBlankString(vCompany.RKOSupplement) Then
			vParameters.mSupplement = "";
		Else
			vParameters.mSupplement = TrimAll(vCompany.RKOSupplement);
		EndIf;
		
		// Director position
		If IsBlankString(vCompany.DirectorPosition) Then
			vParameters.mDirectorPosition = "";
		Else
			vParameters.mDirectorPosition = cmNStr(vCompany.DirectorPosition, Catalogs.Languages.RU);
		EndIf;
		
		// Director position in Dative
		If IsBlankString(vCompany.DirectorPositionInDative) Then
			vParameters.mDirectorPositionInDative = "";
		Else
			vParameters.mDirectorPositionInDative = cmNStr(vCompany.DirectorPositionInDative, Catalogs.Languages.RU);
		EndIf;

		// Forms date
		If vCompany.RKODoNotFillDate Then
			vParameters.mDate = "";
		Else
			vParameters.mDate = Format(Document.Date, "L=ru; DLF=DD");
		EndIf;
	Else
		// Hotel name
		vParameters.mHotelName = "";
		// Company name
		vParameters.mCompanyName = "";
	
		// Company parameters
		vParameters.mDirectorName = "";
		vParameters.mCompanyTIN = "";
		vParameters.mCompanyKPP = "";
		vParameters.mCompanyOKPOCode = "";
		vParameters.mCompanyAddress = "";
		vParameters.mCashierName = "";
		vParameters.mAccountantGeneralName = "";
		
		// Debet account, reason, supplement and director position
		vParameters.mDebetAccount = "62.02";
		vParameters.mReason = "";
		vParameters.mSupplement = "Заявление";
		vParameters.mDirectorPosition = "";
		
		// Forms date
		vParameters.mDate = Format(Document.Date, "L=ru; DLF=DD");
	EndIf;
	If ValueIsFilled(Document.CashRegister) Then
		vParameters.mCashRegisterName = Document.CashRegister.Description;
		vParameters.mKKMManufactureNumber = Document.CashRegister.ManufactureNumber;
		vParameters.mKKMRegistrationNumber = Document.CashRegister.RegistrationNumber;
	Else
		vParameters.mCashRegisterName = "";
		vParameters.mKKMManufactureNumber= "";
		vParameters.mKKMRegistrationNumber= "";
	EndIf;
	
	// Guest name
	vParameters.mGuestName = "                                                            "; // 60 blanks
	
	// Guest address
	vParameters.mGuestAddress1 = "";
	vParameters.mGuestAddress2 = "";
	
	// Guest identity document data
	vParameters.mGuestIDType = "";
	vParameters.mGuestIDSeries = "";
	vParameters.mGuestIDNumber = "";
	vParameters.mGuestIDIssued = "";
	
	// For the folio based payment and return
	vGuest = Catalogs.Clients.EmptyRef();
	vHotelProduct = Catalogs.HotelProducts.EmptyRef();
	If TypeOf(Document) <> Type("DocumentRef.CustomerPayment") Then
		// Guest
		If ValueIsFilled(Document.Payer) And TypeOf(Document.Payer) = Type("CatalogRef.Clients") Then
			vGuest = Document.Payer;
		EndIf;
		If ValueIsFilled(Document.ParentDoc) Then
			If TypeOf(Document.ParentDoc) = Type("DocumentRef.Accommodation") Or 
			   TypeOf(Document.ParentDoc) = Type("DocumentRef.Reservation") Then
				If Not ValueIsFilled(vGuest) Then
					vGuest = Document.ParentDoc.Guest;
				EndIf;
				vHotelProduct = Document.ParentDoc.HotelProduct;
			ElsIf TypeOf(Document.ParentDoc) = Type("DocumentRef.ResourceReservation") Then
				If Not ValueIsFilled(vGuest) Then
					vGuest = Document.ParentDoc.Client;
				EndIf;
			EndIf;
		EndIf;
			
		If ValueIsFilled(vGuest) Then
			// Guest name
			vParameters.mGuestName = TrimAll(vGuest.LastName) + " " + 
											TrimAll(vGuest.FirstName) + " " + 
											TrimAll(vGuest.SecondName); 
			vParameters.mGuestNameHeader = vParameters.mGuestName;								
			If Not IsBlankString(vParameters.mGuestName) Then  
				vSex = vGuest.Sex;  
				vSexPR = Undefined;
				If vSex = Enums.Sex.Male Then
					vSexPR = "GN=Masculine";
				ElsIf vSex = Enums.Sex.Female Then	 
					vSexPR = "GN=Feminine";    
				EndIf;	
				vGuestListDecl =  GetStringDeclensions(vParameters.mGuestName, vSexPR, "CS=Genitive");	
				If vGuestListDecl.Count() > 0 Then
					vParameters.mGuestNameHeader = vGuestListDecl[0];    
				EndIf;	
			EndIf;									
											
			If ValueIsFilled(vHotelProduct) Then
				vParameters.mGuestName = TrimAll(vParameters.mGuestName) + ", " + 
										 TrimAll(vHotelProduct.Description);
			EndIf;
			
			// Guest address
			vGuestAddress = cmParseAddress(vGuest.Address);
			
			vParameters.mGuestAddress1 = cmGetAddressPresentation(" " + vGuestAddress.PostCode + ", " + vGuestAddress.Region);
			vParameters.mGuestAddress2 = cmGetAddressPresentation(" " + vGuestAddress.Area + ", " + vGuestAddress.City + ", " + 
																		 vGuestAddress.Street + ", " + vGuestAddress.House + ", " + vGuestAddress.Flat);
			
			// Guest identity document data
			vParameters.mGuestIDType = TrimAll(vGuest.IdentityDocumentType);
			vParameters.mGuestIDSeries = TrimAll(vGuest.IdentityDocumentSeries);
			vParameters.mGuestIDNumber = TrimAll(vGuest.IdentityDocumentNumber);
			vParameters.mGuestIDIssued = Format(vGuest.IdentityDocumentIssueDate, "DF=dd.MM.yyyy") + " " + 
			                                    TrimAll(vGuest.IdentityDocumentIssuedBy);
		EndIf;
	
		// Room
		vParameters.mRoom = Document.Folio.Room;
			
		// Guest check in and check out dates
		vParameters.mCheckInDate = Format(Document.Folio.DateTimeFrom, "DF='dd.MM.yyyy HH:mm'");
		vParameters.mCheckOutDate = Format(Document.Folio.DateTimeTo, "DF='dd.MM.yyyy HH:mm'");
	EndIf;
	
	// Return sum
	vSum = Document.Sum;
	If vSum < 0 Then
		vSum = -vSum;
	EndIf;
	
	vParameters.mSum = Format(vSum, "ND=17; NFD=2");
	vParameters.mSumInWords = cmSumInWords(vSum, Document.PaymentCurrency, SessionParameters.CurrentLanguage);
	vParameters.mCurrency = TrimAll(Document.PaymentCurrency);
	vParameters.mAuthor = Document.Author;
	vParameters.mReturnNumber = cmGetDocumentNumberPresentation(Document.Number);
	vParameters.mReturnRemarks = TrimAll(Document.Remarks);
	vParameters.mPaymentNumber = "";
	If TypeOf(Document) = Type("DocumentRef.Return") And ValueIsFilled(Document.Payment) Then
		vParameters.mPaymentNumber = cmGetDocumentNumberPresentation(Document.Payment.Number);
	EndIf;
	
	vParameters.mQuantity = "";
	
	// 1. Application
	vTemplate = ThisObject.GetTemplate("Application");
	If pTemplate <> Undefined Then
		vTemplate = pTemplate;
	EndIf;
	vHeader = vTemplate.GetArea("Application");
	FillPropertyValues(vHeader.Parameters, vParameters);
	vHeader.Parameters.mDate = Format(Document.Date, "DF=dd.MM.yyyy");
	pSpreadsheet.Put(vHeader);
	vApplicationHeight = pSpreadsheet.TableHeight;
	vApplicationWidth = pSpreadsheet.TableWidth;
	
	// Create new rows format and set columns width
	vArea = pSpreadsheet.Area(1, , vApplicationHeight);
	vArea.CreateFormatOfRows();
	For i = 1 To vTemplate.TableWidth Do
		pSpreadsheet.Area(1, i).ColumnWidth = vTemplate.Area(1, i).ColumnWidth;
	EndDo;
	
	// Return if base country is not Russia
	If ValueIsFilled(vHotel) And ValueIsFilled(vHotel.Citizenship) And vHotel.Citizenship.Code <> 643 Then
		Return;
	EndIf;
	
	// 2. KM3
	pSpreadsheet.PutHorizontalPageBreak();
	vTemplate = ThisObject.GetTemplate("KM3");
	If pTemplate <> Undefined Then
		vTemplate = pTemplate;
	EndIf;
	vHeader = vTemplate.GetArea("KM3");
	FillPropertyValues(vHeader.Parameters, vParameters);
	pSpreadsheet.Put(vHeader);
	vKM3Height = pSpreadsheet.TableHeight;
	
	// Create new rows format and set columns width
	vArea = pSpreadsheet.Area(vApplicationHeight+1, , vKM3Height);
	vArea.CreateFormatOfRows();
	For i = 1 To vTemplate.TableWidth Do
		pSpreadsheet.Area(vApplicationHeight + 1, i).ColumnWidth = vTemplate.Area(1, i).ColumnWidth;
	EndDo;
	                                    
	// Stop printing if new cash rules (2017) are used
	//If ValueIsFilled(Document) And ValueIsFilled(Document.CashRegister) And Document.CashRegister.CashReturnDirectlyFromCashBoxIsAllowed Or
	//   cmCheckUserPermissions("HavePermissionToReturnCashDirectlyFromCashBox") Then
	//	// Set print area
	//	pSpreadsheet.PrintArea = pSpreadsheet.Area(, 1, , vApplicationWidth);
	//	Return;
	//EndIf;
	
	// 3. RKO - if doc type is "Return"
	If (TypeOf(Document) = Type("DocumentRef.Return") Or TypeOf(Document) = Type("DocumentRef.CustomerPayment")) And Document.CashRegister.DoNotPrintRKO = False Then
		pSpreadsheet.PutHorizontalPageBreak();
		vTemplate = ThisObject.GetTemplate("RKO");
		If pTemplate <> Undefined Then
			vTemplate = pTemplate;
		EndIf;
		vHeader = vTemplate.GetArea("RKO");
		FillPropertyValues(vHeader.Parameters, vParameters);
		pSpreadsheet.Put(vHeader);
		vRKOHeight = pSpreadsheet.TableHeight;
		
		// Create new rows format and set columns width
		vArea = pSpreadsheet.Area(vKM3Height + 1, , vRKOHeight);
		vArea.CreateFormatOfRows();
		For i = 1 To vTemplate.TableWidth Do
			pSpreadsheet.Area(vKM3Height + 1, i).ColumnWidth = vTemplate.Area(1, i).ColumnWidth;
		EndDo;
	EndIf;
	
	// 4. 8-Г - if doc type is "Return" and Cash register has Print8G flag is on
	If ValueIsFilled(Document.CashRegister) And Document.CashRegister.Print8G And ValueIsFilled(Document.PaymentMethod) And Document.PaymentMethod.BookByCashRegister And Not Document.PaymentMethod.PrintCheque And 
	   (TypeOf(Document) = Type("DocumentRef.Return") Or TypeOf(Document) = Type("DocumentRef.CustomerPayment")) Then
		pSpreadsheet.PutHorizontalPageBreak();
		vTemplate = ThisObject.GetTemplate("G8");
		If pTemplate <> Undefined Then
			vTemplate = pTemplate;
		EndIf;
		vHeader = vTemplate.GetArea("G8");
		FillPropertyValues(vHeader.Parameters, vParameters);
		pSpreadsheet.Put(vHeader);
		vG8Height = pSpreadsheet.TableHeight;
		
		// Create new rows format and set columns width
		vArea = pSpreadsheet.Area(vRKOHeight + 1, , vG8Height);
		vArea.CreateFormatOfRows();
		For i = 1 To vTemplate.TableWidth Do
			pSpreadsheet.Area(vRKOHeight + 1, i).ColumnWidth = vTemplate.Area(1, i).ColumnWidth;
		EndDo;
	EndIf;
	
	// Set print area
	pSpreadsheet.PrintArea = pSpreadsheet.Area(, 1, , vApplicationWidth);
EndProcedure // pmGenerate

#EndRegion
