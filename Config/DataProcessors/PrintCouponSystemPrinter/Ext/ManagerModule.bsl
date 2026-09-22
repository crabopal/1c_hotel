// -----------------------------------------------------------------------------
Procedure pmPrint(pSpreadsheet, pSelLanguage, pSelObjList, pRibbonPrinterConnectionParameters) Export
	pSpreadsheet.Clear();
	
	// Get coupone template	
	vCouponTemplate = GetTemplate("CouponTemplate");
	vCP = vCouponTemplate.GetArea("Coupon|V");
		
	vNumber = 0;
	// Do for each object in input list
	For Each vObjListItem In pSelObjList Do
		vNumber = vNumber + 1;
		vObj = vObjListItem.Value;
		
		// Print coupon header
		mHotelName = vObj.Hotel.GetObject().pmGetHotelPrintName(pSelLanguage);
		// Accounting date
		mAccountingDate = Format(vObj.Date, "DF=dd.MM.yyyy");
		// Service name
		mService = Upper(vObj.Service.GetObject().pmGetServiceDescription(pSelLanguage)) + "  ";
		// Quantity
		mQuantity = NStr("ru='Количество: ';en='Quantity: ';de='Anzahl'") + Format(vObj.Quantity, "ND=5; NFD=0; NZ=; NG=");
		// Client name
		If ValueIsFilled(vObj.Client) Then
			mClient = Upper(cmNStr("en='Name: '; de='Name: '; ru='Имя: '", pSelLanguage)) + TrimAll(vObj.Client.FullName);
		Else
			mClient = Upper(cmNStr("en='Name: '; de='Name: '; ru='Имя: '", pSelLanguage)) + "******";
		EndIf;
		// Room or resource
		mRoom = "";
		mGroupDescription = "";
		If ValueIsFilled(vObj.Resource) Then
			mRoom = Upper(cmNStr("en='Resource: '; de='Resource: '; ru='Ресурс: '", pSelLanguage)) + TrimAll(vObj.Resource);
			// Print guest group period and description
			If ValueIsFilled(vObj.GuestGroup) And 
			   ValueIsFilled(vObj.GuestGroup.CheckInDate) And 
			   ValueIsFilled(vObj.GuestGroup.CheckOutDate) Then
				mGroupDescription = Upper(cmNStr("en='Group: ';ru='Группа: ';de='Gruppe: '", pSelLanguage)) + 
							        Format(vObj.GuestGroup.Code, "ND=12; NFD=0; NG=") + ", " + 
							        Format(vObj.GuestGroup.CheckInDate, "DF='dd.MM HH:mm'") + " - " + 
							        Format(vObj.GuestGroup.CheckOutDate, "DF='dd.MM HH:mm'");
				// Description
				If Not IsBlankString(vObj.GuestGroup.Description) Then
					mGroupDescription = mGroupDescription + Chars.LF + TrimAll(vObj.GuestGroup.Description);
				EndIf;
			EndIf;
		ElsIf ValueIsFilled(vObj.Room) Then
			mRoom = Upper(cmNStr("en='Room: ';ru='Номер: ';de='Zimmer: '", pSelLanguage)) + TrimAll(vObj.Room);
		EndIf;
		
		// Add bar code with charge document number
		If ValueIsFilled(pRibbonPrinterConnectionParameters.BarCodeType) Then
			vBarCodeControl = vCP.Areas.BarCode;
			vWidth = vBarCodeControl.Width;
			vHeight = vBarCodeControl.Height;
			vParametersBarcode = New Structure("Barcode, Width, Height, CodeType, TextVisible, FontSize", vObj.CouponBarCode, vWidth, vHeight, 3, True, 12);
			vBarCodeControl.Picture = tcSystemBarcodePrinterDriver.pmGetPictureCode(vParametersBarcode);
		EndIf;
	
		// Set parameters
		vCP.Parameters.mHotelName = mHotelName;
		vCP.Parameters.mAccountingDate = mAccountingDate;
		vCP.Parameters.mService = mService;
		vCP.Parameters.mQuantity = mQuantity;
		vCP.Parameters.mClient = mClient;
		vCP.Parameters.mRoom = mRoom;
		vCP.Parameters.mGroupDescription = mGroupDescription;
		
		If vNumber % 2 = 0 Then
			pSpreadsheet.Join(vCP);
			Continue;
		EndIf;
		
		// Put coupon
		If pSpreadsheet.CheckPut(vCP) Then
			pSpreadsheet.Put(vCP);
		Else
			pSpreadsheet.PutHorizontalPageBreak();
			pSpreadsheet.Put(vCP);
			
		EndIf;
	EndDo;
	// Setup default attributes with black and white print mode
	cmSetDefaultPrintFormSettings(pSpreadsheet, PageOrientation.Portrait, True);
	
	// Check authorities
	cmSetSpreadsheetProtection(pSpreadsheet);
EndProcedure // pmPrintCancellation