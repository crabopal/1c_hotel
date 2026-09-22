// -----------------------------------------------------------------------------
// Description: Returns value table with all hotel products
// Parameters: Hotel products folder to return products from, Maximum number of 
//             products to return, return items and folders or items only
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetAllHotelProducts(pHotelProductFolder = Undefined, pTop = 0, pShowFolders = False) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT " + ?(pTop = 0, "", "TOP " + pTop) + "
	|	HotelProducts.Ref AS HotelProduct
	|FROM
	|	Catalog.HotelProducts AS HotelProducts
	|WHERE 
	|	HotelProducts.DeletionMark = FALSE " + 
		?(Not pShowFolders, " AND HotelProducts.IsFolder = FALSE ", "") +
		?(ValueIsFilled(pHotelProductFolder), " AND HotelProducts.Ref IN HIERARCHY(&qHotelProductFolder) ", "") + "
	|ORDER BY HotelProducts.Code";
	vQry.SetParameter("qHotelProductFolder", pHotelProductFolder);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllHotelProducts

// -----------------------------------------------------------------------------
// Description: Returns value table with all hotel product folders
// Parameters: Hotel products folder to return folders from, Maximum number of 
//             product folders to return
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetAllHotelProductFolders(pHotelProductFolder = Undefined, pTop = 0) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT " + ?(pTop = 0, "", "TOP " + pTop) + "
	|	HotelProducts.Ref AS HotelProduct
	|FROM
	|	Catalog.HotelProducts AS HotelProducts
	|WHERE 
	|	HotelProducts.IsFolder = TRUE AND " +
		?(ValueIsFilled(pHotelProductFolder), "HotelProducts.Ref IN HIERARCHY(&qHotelProductFolder) AND ", "") + "
	|	HotelProducts.DeletionMark = FALSE
	|ORDER BY HotelProducts.Code";
	vQry.SetParameter("qHotelProductFolder", pHotelProductFolder);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllHotelProductFolders

// -----------------------------------------------------------------------------
// Description: Returns value table with all social group items
// Parameters: Social group folder to return items from, Maximum number of 
//             items to return
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetAllSocialGroups(pSocialGroupFolder = Undefined, pTop = 0) Export
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT " + ?(pTop = 0, "", "TOP " + pTop) + "
	|	SocialGroups.Ref AS SocialGroup
	|FROM
	|	Catalog.SocialGroups AS SocialGroups
	|WHERE 
	|	SocialGroups.IsFolder = FALSE AND " +
		?(ValueIsFilled(pSocialGroupFolder), "SocialGroups.Ref IN HIERARCHY(&qSocialGroupFolder) AND ", "") + "
	|	SocialGroups.DeletionMark = FALSE
	|ORDER BY SocialGroups.Code";
	vQry.SetParameter("qSocialGroupFolder", pSocialGroupFolder);
	vList = vQry.Execute().Unload();
	Return vList;
EndFunction // cmGetAllSocialGroups

// -----------------------------------------------------------------------------
// Description: Returns value table with hotel product items
// Parameters: Hotel product code, Hotel, Maximum number of 
//             products to return
// Return value: Value table
// -----------------------------------------------------------------------------
Function cmGetHotelProductsList(pCode, pHotel, pMaxNumber = 10, pShowDeleted = False) Export
	// Build and run query
	qGetList = New Query;
	qGetList.Text = 
	"SELECT DISTINCT TOP " + pMaxNumber + "
	|	HotelProducts.Code,
	|	HotelProducts.Description,
	|	HotelProducts.Ref
	|FROM
	|	Catalog.HotelProducts AS HotelProducts
	|WHERE
	|	HotelProducts.Hotel = &qHotel AND 
	|	HotelProducts.Code = &qCode AND 
	|	HotelProducts.IsFolder = False AND
	|	(NOT &qShowDeleted AND NOT HotelProducts.DeletionMark OR &qShowDeleted)
	|ORDER BY Description";
	qGetList.SetParameter("qHotel", pHotel);
	qGetList.SetParameter("qCode", TrimAll(pCode));
	qGetList.SetParameter("qShowDeleted", pShowDeleted);
	vList = qGetList.Execute().Unload();
	Return vList;
EndFunction // cmGetHotelProductsList

// -----------------------------------------------------------------------------
// Description: Processes text edit end event in the hotel product controls
// Parameters: Object, Form, Hotel product control, Text entered, Value to return, 
//             Standard processing flag 
// Return value: True if hotel product was changed, False if not
// -----------------------------------------------------------------------------
Function cmHotelProductTextEditEnd(pObject, pForm, pControl, pText, pValue, pStandardProcessing, pBaseObject = Undefined, rMessage = "") Export
	vIsChanged = False;
	pStandardProcessing = False;
	vText = Upper(TrimAll(pText));
	vTab = cmGetHotelProductsList(vText, ?(pObject <> Undefined, pObject.Hotel, SessionParameters.CurrentHotel), 10, True);
	If vTab.Count() > 0 Then
		vRow = vTab.Get(0);
		vHPRef = vRow.Ref;
		If TypeOf(pObject) = Type("DocumentObject.Accommodation") Or
		   TypeOf(pObject) = Type("DocumentObject.Reservation") Or
		   TypeOf(pObject) = Type("DocumentObject.Charge") Or
		   TypeOf(pObject) = Type("FormDataStructure") Or
		   TypeOf(pObject) = Type("Structure") Then
			If vHPRef.DeletionMark Then
				rMessage = NStr("en='This product was already deleted!'; de='Dieser Reisecheck/Kurkarte ist schon löschen!'; ru='Эта путевка/курсовка испорчена!'");
			Else
				rMessage = NStr("en='This product was already registered';ru='Эта путевка/курсовка уже зарегистрирована';de='Dieser Reisecheck/Kurkarte ist schon registriert'");
			EndIf;
			If TypeOf(pObject) <> Type("Structure") Then
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
			EndIf;
		EndIf;
		If TypeOf(pObject) = Type("DocumentObject.Accommodation") Or
		   TypeOf(pObject) = Type("DocumentObject.Reservation") Or
		   TypeOf(pObject) = Type("FormDataStructure") Or
		   TypeOf(pObject) = Type("Structure") Then
			If vHPRef.FixProductCost Then
				If vHPRef.Duration > 0 And vHPRef.Sum > 0 And 
				   (Not ValueIsFilled(vHPRef.CheckInDate) Or Not ValueIsFilled(vHPRef.CheckInDate)) Then
					vHPObj = vHPRef.GetObject();
					vReferenceHour = '00010101';
					If ValueIsFilled(pObject.RoomRate) Then
						vReferenceHour = pObject.RoomRate.ReferenceHour;
					EndIf;
					vHPObj.CheckInDate = BegOfDay(pObject.CheckInDate) + (vReferenceHour - BegOfDay(vReferenceHour));
					vHPObj.CheckOutDate = vHPObj.CheckInDate + vHPObj.Duration*24*3600;
					If vReferenceHour = '00010101' Then
						vHPObj.CheckOutDate = vHPObj.CheckOutDate - 1;
					EndIf;
					vHPObj.Write();
				EndIf;
			EndIf;
		EndIf;
		pValue = vHPRef;
		vIsChanged = True;
	Else
		Try
			// Try to find issued hotel product in the information register
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	IssuedHotelProducts.Recorder,
			|	IssuedHotelProducts.LineNumber,
			|	IssuedHotelProducts.Active,
			|	IssuedHotelProducts.ProductCode,
			|	IssuedHotelProducts.Hotel,
			|	IssuedHotelProducts.Company,
			|	IssuedHotelProducts.Customer,
			|	IssuedHotelProducts.Contract,
			|	IssuedHotelProducts.GuestGroup,
			|	IssuedHotelProducts.ParentDoc,
			|	IssuedHotelProducts.RoomQuota,
			|	IssuedHotelProducts.BillOfShipment,
			|	IssuedHotelProducts.VATRate,
			|	IssuedHotelProducts.FixProductPeriod,
			|	IssuedHotelProducts.FixPlannedPeriod,
			|	IssuedHotelProducts.FixProductCost,
			|	IssuedHotelProducts.HotelProductParent,
			|	IssuedHotelProducts.CheckInDate,
			|	IssuedHotelProducts.Duration,
			|	IssuedHotelProducts.CheckOutDate,
			|	IssuedHotelProducts.Price,
			|	IssuedHotelProducts.Currency
			|FROM
			|	InformationRegister.IssuedHotelProducts AS IssuedHotelProducts
			|WHERE
			|	IssuedHotelProducts.ProductCode = &qProductCode
			|	AND IssuedHotelProducts.Hotel = &qHotel
			|ORDER BY
			|	IssuedHotelProducts.Recorder.PointInTime DESC";
			vQry.SetParameter("qProductCode", vText);
			vQry.SetParameter("qHotel", pObject.Hotel);
			vIHPs = vQry.Execute().Unload();
			If vIHPs.Count() > 0 Then
				vIHPRow = vIHPs.Get(0);
				// Create and return new hotel product filled with data from the issued one
				vHPObj = Catalogs.HotelProducts.CreateItem();
				vHPObj.CreateDate = CurrentSessionDate();
				vHPObj.Author = SessionParameters.CurrentUser;
				vHPObj.Code = TrimAll(vIHPRow.ProductCode);
				vHPObj.Description = TrimAll(vHPObj.Code);
				FillPropertyValues(vHPObj, vIHPRow);
				vHPObj.Parent = vIHPRow.HotelProductParent;
				vHPObj.Sum = vIHPRow.Price;
				vHPObj.Write();
				pValue = vHPObj.Ref;
				vIsChanged = True;
			Else
				// If there are hotel product folders then ask user to choose one
				vHPFolder = Undefined;
				// Try to get hotel product type from the room rate
				If TypeOf(pObject) = Type("DocumentObject.Accommodation") Or
				   TypeOf(pObject) = Type("DocumentObject.Reservation") Or
				   TypeOf(pObject) = Type("FormDataStructure") Or
				   TypeOf(pObject) = Type("Structure") Then
					If ValueIsFilled(pObject.RoomRate) Then
						vHPFolder = pObject.RoomRate.HotelProductType;
					EndIf;
				EndIf;					
				#IF CLIENT THEN
					If Not ValueIsFilled(vHPFolder) Then
						vHPFolders = cmGetAllHotelProductFolders();
						If vHPFolders.Count() > 0 Then
							vHPFolder = Catalogs.HotelProducts.GetFolderChoiceForm().DoModal();
							If vHPFolder = Undefined Then
								Return vIsChanged;
							EndIf;
						EndIf;
					EndIf;
				#ENDIF
				// If there are social groups then ask user to choose one if necessary
				vSocialGroup = Undefined;
				#IF CLIENT THEN
					vSocialGroups = cmGetAllSocialGroups();
					If vSocialGroups.Count() > 0 Then
						vSocialGroup = Catalogs.SocialGroups.GetChoiceForm().DoModal();
						If vSocialGroup = Undefined Then
							Return vIsChanged;
						EndIf;
					EndIf;
				#ENDIF
				// Create and return new hotel product
				vHPObj = Catalogs.HotelProducts.CreateItem();
				vHPObj.CreateDate = CurrentSessionDate();
				vHPObj.Author = SessionParameters.CurrentUser;
				vHPObj.Code = Upper(TrimAll(pText));
				vHPObj.Description = Upper(TrimAll(pText));
				vHPObj.Hotel = ?(pObject <> Undefined, pObject.Hotel, SessionParameters.CurrentHotel);
				vHPObj.Currency = vHPObj.Hotel.FolioCurrency;
				vHPObj.SocialGroup = vSocialGroup;
				If ValueIsFilled(vHPFolder) Then
					vHPObj.Parent = vHPFolder;
					vHPObj.RoomQuota = vHPFolder.RoomQuota;
					vHPObj.FixProductCost = vHPFolder.FixProductCost;
					vHPObj.FixProductPeriod = vHPFolder.FixProductPeriod;
					vHPObj.FixPlannedPeriod = vHPFolder.FixPlannedPeriod;
				EndIf;
				If TypeOf(pObject) = Type("DocumentObject.Accommodation") Or
				   TypeOf(pObject) = Type("DocumentObject.Reservation") Or
				   TypeOf(pObject) = Type("Structure") Then
					vHPObj.Client = pObject.Guest;
					vHPObj.Duration = pObject.Duration;
					If vHPObj.FixProductCost Then
						vReferenceHour = '00010101';
						If ValueIsFilled(pObject.RoomRate) Then
							vReferenceHour = pObject.RoomRate.ReferenceHour;
						EndIf;
						vHPObj.CheckInDate = BegOfDay(pObject.CheckInDate) + (vReferenceHour - BegOfDay(vReferenceHour));
						vHPObj.CheckOutDate = vHPObj.CheckInDate + vHPObj.Duration*24*3600;
						If vReferenceHour = '00010101' Then
							vHPObj.CheckOutDate = vHPObj.CheckOutDate - 1;
						EndIf;
					Else
						vHPObj.CheckInDate = pObject.CheckInDate;
						vHPObj.CheckOutDate = pObject.CheckOutDate;
					EndIf;
					vHPObj.Sum = 0;
					For Each vSrvRow In pObject.Services Do
						If ValueIsFilled(vSrvRow.Service) And vSrvRow.Service.IsHotelProductService Then
							vHPObj.Sum = vHPObj.Sum + vSrvRow.Sum - vSrvRow.DiscountSum;
						EndIf;
					EndDo;
					// If document product is filled then copy it's parameters
					If pBaseObject <> Undefined And ValueIsFilled(pBaseObject.HotelProduct) And pBaseObject.HotelProduct.Parent = vHPObj.Parent And 
					   pBaseObject.RoomType = pObject.RoomType And pBaseObject.AccommodationType = pObject.AccommodationType And pBaseObject.Duration = pObject.Duration Then
						vBaseProduct = pBaseObject.HotelProduct;
						If vBaseProduct.FixProductPeriod Then
							vHPObj.FixProductPeriod = True;
							vHPObj.CheckInDate = vBaseProduct.CheckInDate;
							vHPObj.CheckOutDate = vBaseProduct.CheckOutDate;
						EndIf;
						If vBaseProduct.FixPlannedPeriod Then
							vHPObj.FixPlannedPeriod = True;
							vHPObj.CheckInDate = vBaseProduct.CheckInDate;
							vHPObj.CheckOutDate = vBaseProduct.CheckOutDate;
						EndIf;
						If vBaseProduct.FixProductCost Then
							vHPObj.FixProductCost = True;
							vHPObj.CheckInDate = vBaseProduct.CheckInDate;
							vHPObj.CheckOutDate = vBaseProduct.CheckOutDate;
							vHPObj.Sum = vBaseProduct.Sum;
							vHPObj.Currency = vBaseProduct.Currency;
						EndIf;
					EndIf;
				ElsIf TypeOf(pObject) = Type("DocumentObject.Folio") Then
					vHPObj.Client = pObject.Client;
				ElsIf TypeOf(pObject) = Type("DocumentObject.Charge") And ValueIsFilled(pObject.Folio) Then
					vHPObj.Client = pObject.Folio.Client;
				EndIf;
				vHPObj.Write();
				pValue = vHPObj.Ref;
				vIsChanged = True;
			EndIf;
		Except
		EndTry;
	EndIf;
	If vIsChanged And ValueIsFilled(pValue) Then
		If ValueIsFilled(pValue.Parent) Then
			If pValue.Parent.OpenNewProductForm Then
				vFrm = pValue.GetForm(, pControl);
				vFrm.Open();
			EndIf;
		EndIf;
	EndIf;
	Return vIsChanged;
EndFunction // cmHotelProductTextEditEnd
