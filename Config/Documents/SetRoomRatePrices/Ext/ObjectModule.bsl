
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure Filling(pBase)
	// Fill attributes with default values
	pmFillAttributesWithDefaultValues();
	// Fill from the base
	If ValueIsFilled(pBase) Then
		If TypeOf(pBase) = Type("CatalogRef.RoomRates") Then
			If ValueIsFilled(pBase.Hotel) Then
				Hotel = pBase.Hotel;
			EndIf;
			RoomRate = pBase;
			If ValueIsFilled(Hotel) Then
				SetNewNumber(Catalogs.Hotels.pmGetPrefix(Hotel));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // Filling

// -----------------------------------------------------------------------------
Procedure OnSetNewNumber(pStandardProcessing, pPrefix)
	vPrefix = "";
	If ValueIsFilled(Hotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(Hotel);
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then
		vPrefix = Catalogs.Hotels.pmGetPrefix(SessionParameters.CurrentHotel);
	EndIf;
	If vPrefix <> "" Then
		pPrefix = vPrefix;
	EndIf;
EndProcedure // OnSetNewNumber

// -----------------------------------------------------------------------------
Procedure Posting(pCancel, pMode)
	Var vMessage, vAttributeInErr;
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Check that posting is possible
	If pmCheckDocumentAttributes(vMessage, vAttributeInErr) Then
		Raise NStr(vMessage);
	EndIf;
	
	// Get lists of active room rates and calendar day types
	vRoomRates = pmGetListOfActiveRoomRates();
	vCalendarDayTypes = pmGetListOfActiveCalendarDayTypes();
	vPriceTags = pmGetListOfActivePriceTags();
	
	vAllRoomTypesCache = New ValueTable();
	vAllRoomTypesCache.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
	vAllRoomTypesCache.Columns.Add("RoomClass", cmGetCatalogTypeDescription("RoomTypeClasses"));
	vAllRoomTypesCache.Columns.Add("RoomTypes");
	
	vAllClientTypesCache = New ValueTable();
	vAllClientTypesCache.Columns.Add("ClientType", cmGetCatalogTypeDescription("ClientTypes"));
	vAllClientTypesCache.Columns.Add("ClientTypes");
	
	vAllAccommodationTypesCache = New ValueTable();
	vAllAccommodationTypesCache.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
	vAllAccommodationTypesCache.Columns.Add("AccommodationTypes");
	
	// Get accommodation service from room rate
	vAccommodationService = Catalogs.Services.EmptyRef();
	vVATRate = Catalogs.VATRates.EmptyRef();
	vQuantityCalculationRule = Catalogs.QuantityCalculationRules.EmptyRef();
	If Not RoomRate.IsFolder Then
		vAccommodationService = RoomRate.AccommodationService;
		If ValueIsFilled(vAccommodationService) Then
			vSrvAttrs = vAccommodationService.GetObject().pmGetServicePrices(Hotel, Date, Catalogs.ClientTypes.EmptyRef());
			For Each vSrvAttrsRow In vSrvAttrs Do
				vVATRate = vSrvAttrsRow.VATRate;
				Break;
			EndDo;
		EndIf;
	EndIf;
	If ValueIsFilled(vAccommodationService) And ValueIsFilled(vAccommodationService.QuantityCalculationRule) Then
		vQuantityCalculationRule = vAccommodationService.QuantityCalculationRule;
	EndIf;
	If ValueIsFilled(RoomRate) And Not RoomRate.IsFolder And ValueIsFilled(RoomRate.QuantityCalculationRule) Then
		vQuantityCalculationRule = RoomRate.QuantityCalculationRule;
	EndIf;
	
	// Get old accommodation service
	vOldAccommodationService = Catalogs.Services.EmptyRef();
	vOldVATRate = Catalogs.VATRates.EmptyRef();
	vOldQuantityCalculationRule = Catalogs.QuantityCalculationRules.EmptyRef();
	For Each vPrcRow In Prices Do
		If ValueIsFilled(vPrcRow.Service) And vPrcRow.IsRoomRevenue And vPrcRow.IsInPrice Then
			vOldAccommodationService = vPrcRow.Service;
			vOldVATRate = vPrcRow.VATRate;
			vOldQuantityCalculationRule = vPrcRow.QuantityCalculationRule;
			Break;
		EndIf;
	EndDo;
	
	// Update accommodation service if neccessary
	If ValueIsFilled(vAccommodationService) And ValueIsFilled(vOldAccommodationService) And 
	   vAccommodationService <> vOldAccommodationService Then
		For Each vPrcRow In Prices Do
			If ValueIsFilled(vPrcRow.Service) And vPrcRow.IsRoomRevenue And vPrcRow.IsInPrice Then
				vPrcRow.Service = vAccommodationService;
			EndIf;
		EndDo;
		
		For Each vAccTypFormulasRow In Formulas Do
			If vOldAccommodationService = vAccTypFormulasRow.Service Then
				vAccTypFormulasRow.Service = vAccommodationService;
			EndIf;
		EndDo;
		
		For Each vDayTypFormulasRow In FormulasForDayTypesAndPricetags Do
			If vOldAccommodationService = vDayTypFormulasRow.Service Then
				vDayTypFormulasRow.Service = vAccommodationService;
			EndIf;
		EndDo;
	EndIf;
	
	// Update accommodation service VAT rate
	If ValueIsFilled(vAccommodationService) And ValueIsFilled(vVATRate) And ValueIsFilled(vOldVATRate) And 
	   vVATRate <> vOldVATRate Then
		For Each vPrcRow In Prices Do
			If vPrcRow.Service = vAccommodationService Then
				vPrcRow.VATRate = vVATRate;
			EndIf;
		EndDo;
	EndIf;
	
	// Update quantity calculation rule
	If ValueIsFilled(vAccommodationService) And ValueIsFilled(vQuantityCalculationRule) And vQuantityCalculationRule <> vOldQuantityCalculationRule Then
		For Each vPrcRow In Prices Do
			If vPrcRow.Service = vAccommodationService Then
				vPrcRow.QuantityCalculationRule = vQuantityCalculationRule;
			EndIf;
		EndDo;
	EndIf;
	
	// Build list of room types available in the accommodation type formulas
	vRoomTypesForPrices = New ValueList();
	If Not ValueIsFilled(vAccommodationService) Then
		For Each vPrcRow In Prices Do
			If ValueIsFilled(vPrcRow.Service) And vPrcRow.IsRoomRevenue And vPrcRow.IsInPrice Then
				vAccommodationService = vPrcRow.Service;
				Break;
			EndIf;
		EndDo;
	EndIf;
	If ValueIsFilled(vAccommodationService) Then
		For Each vAccTypFormulasRow In Formulas Do
			If vAccommodationService = vAccTypFormulasRow.Service And vAccTypFormulasRow.MasterAccType = vAccTypFormulasRow.AccommodationType Then
				If ValueIsFilled(vAccTypFormulasRow.RoomType) Then
					If vAccTypFormulasRow.RoomType.IsFolder Then
						vFolderRoomTypes = cmGetAllRoomTypes(Hotel, vAccTypFormulasRow.RoomType, vAccTypFormulasRow.RoomClass).UnloadColumn("RoomType");
						For Each vFolderRoomType In vFolderRoomTypes Do
							If vRoomTypesForPrices.FindByValue(vFolderRoomType) = Undefined Then
								vRoomTypesForPrices.Add(vFolderRoomType);
							EndIf;
						EndDo;
					Else
						If vRoomTypesForPrices.FindByValue(vAccTypFormulasRow.RoomType) = Undefined Then
							vRoomTypesForPrices.Add(vAccTypFormulasRow.RoomType);
						EndIf;
					EndIf;
				ElsIf ValueIsFilled(vAccTypFormulasRow.RoomClass) Then
					vRoomClassRoomTypes = cmGetAllRoomTypes(Hotel, , vAccTypFormulasRow.RoomClass).UnloadColumn("RoomType");
					For Each vRoomClassRoomType In vRoomClassRoomTypes Do
						If vRoomTypesForPrices.FindByValue(vRoomClassRoomType) = Undefined Then
							vRoomTypesForPrices.Add(vRoomClassRoomType);
						EndIf;
					EndDo;
				Else
					vRoomTypesForPrices.Clear();
					vRoomTypesForPrices.LoadValues(cmGetAllRoomTypes(Hotel).UnloadColumn("RoomType"));
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// Build working table with prices
	vPrices = Prices.Unload();
	
	// Split prices rows with empty room type according to the room types for prices list
	If vRoomTypesForPrices.Count() > 0 Then
		For Each vPricesRow In vPrices Do
			If Not ValueIsFilled(vPricesRow.RoomType) Then
				vFirstRoomTypeIsAssigned = False;
				For Each vRoomTypesForPricesItem In vRoomTypesForPrices Do
					vCurRoomType = vRoomTypesForPricesItem.Value;
					If Not ValueIsFilled(vPricesRow.RoomClass) Or vPricesRow.RoomClass = vCurRoomType.RoomClass Then
						If Not vFirstRoomTypeIsAssigned Then
							vFirstRoomTypeIsAssigned = True;
							vPricesRow.RoomType = vCurRoomType;
						Else
							vNewPricesRow = vPrices.Insert(vPrices.IndexOf(vPricesRow)+1);
							FillPropertyValues(vNewPricesRow, vPricesRow, , "LineNumber");
							vNewPricesRow.RoomType = vCurRoomType;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	// Get list of prices with valid sorting
	vPrices = pmSortPrices(True, vPrices);
	
	vEarlyCheckInService = Catalogs.Services.EmptyRef();
	vLateCheckOutService = Catalogs.Services.EmptyRef();
	
	// Add row for each combination of parameters
	i = 0;
	For Each vRoomRatesRow In vRoomRates Do
		vRoomRate = vRoomRatesRow.RoomRate;
		If ValueIsFilled(vRoomRate.BasedOnRoomRate) Then
			Continue;
		EndIf;
		
		// Early check-in / late check-out services
		vEarlyCheckInService = Catalogs.Services.EmptyRef();
		vEarlyCheckInServicePS = Undefined;
		vEarlyCheckInServiceVATRate = Undefined;
		If Not vRoomRate.IsFolder Then
			vEarlyCheckInService = vRoomRate.EarlyCheckInService;
			If ValueIsFilled(vEarlyCheckInService) Then
				vEarlyCheckInServicePS = vEarlyCheckInService.PaymentSection;
				If ValueIsFilled(vEarlyCheckInServicePS) And ValueIsFilled(vEarlyCheckInServicePS.VATRate) Then
					vEarlyCheckInServiceVATRate = vEarlyCheckInServicePS.VATRate;
				EndIf;
			EndIf;
		EndIf;
			
		vLateCheckOutService = Catalogs.Services.EmptyRef();
		vLateCheckOutServicePS = Undefined;
		vLateCheckOutServiceVATRate = Undefined;
		If Not vRoomRate.IsFolder Then
			vLateCheckOutService = vRoomRate.LateCheckOutService;
			If ValueIsFilled(vLateCheckOutService) Then
				vLateCheckOutServicePS = vLateCheckOutService.PaymentSection;
				If ValueIsFilled(vLateCheckOutServicePS) And ValueIsFilled(vLateCheckOutServicePS.VATRate) Then
					vLateCheckOutServiceVATRate = vLateCheckOutServicePS.VATRate;
				EndIf;
			EndIf;
		EndIf;
		
		For Each vPriceTagsRow In vPriceTags Do
			// Check based on price tag parameter
			vEffectivePriceTag = vPriceTagsRow.PriceTag;
			vPriceTag = vEffectivePriceTag;
			
			// Do for each calendar day type
			For Each vCalendarDayTypesRow In vCalendarDayTypes Do
				vCalendarDayType = vCalendarDayTypesRow.CalendarDayType;
				
				// Post document to the room rates information register
				vRec = RegisterRecords.RoomRates.Add();
				vRec.Period = Date;
				vRec.IsFormula = False;
				
				vRec.Hotel = Hotel;
				vRec.RoomRate = vRoomRate;
				vRec.CalendarDayType = vCalendarDayType;
				vRec.PriceTag = vPriceTag;
				
				vRec.SetRoomRatePrices = Ref;
				vRec.SetRoomRateFormulas = Undefined;
				
				// Check room rate
				If ValueIsFilled(vRoomRate) And Not vRoomRate.IsFolder And vRoomRate.UsePricesFromCalendar Then
					Continue;
				EndIf;
				
				// Post document to the room rate prices information register
				For Each vPricesRow In vPrices Do
					// Get lists of active room types and accommodation types for this row
					vClientTypes = pmGetListOfActiveClientTypes(vPricesRow.ClientType, vAllClientTypesCache);
					vRoomTypes = pmGetListOfActiveRoomTypes(vPricesRow.RoomType, vPricesRow.RoomClass, vAllRoomTypesCache);
					vAccommodationTypes = pmGetListOfActiveAccommodationTypes(vPricesRow.AccommodationType, vAllAccommodationTypesCache);
					For Each vClientTypesRow In vClientTypes Do
						vClientType = vClientTypesRow.ClientType;
						
						For Each vRoomTypesRow In vRoomTypes Do
							vRoomType = vRoomTypesRow.RoomType;
							vRoomClass = vRoomTypesRow.RoomClass;
							
							For Each vAccommodationTypesRow In vAccommodationTypes Do
								vAccommodationType = vAccommodationTypesRow.AccommodationType;
								
								// Check that current service fits to the room rate service group
								If ValueIsFilled(vPricesRow.Service) Then
									If cmIsServiceInServiceGroup(vPricesRow.Service, vRoomRate.RoomRateServiceGroup) Then
										// Check permitted accommodation types for the given room type
										If ValueIsFilled(vRoomType) Then
											If vRoomType.AccommodationTypesAllowed.Count() > 0 Then
												If vRoomType.AccommodationTypesAllowed.Find(vAccommodationType) = Undefined Then
													Continue;
												EndIf;
											EndIf;
										EndIf;
										
										// Add detailed record to the register
										i = i + 1;
										
										vPriceRec = RegisterRecords.RoomRatePrices.Add();
										vPriceRec.SortCode = i;
										vPriceRec.SetRoomRatePrices = Ref;
										
										FillPropertyValues(vPriceRec, ThisObject, , "RoomRate, CalendarDayType");
										vPriceRec.RoomRate = vRoomRate;
										vPriceRec.CalendarDayType = vCalendarDayType;
										If ValueIsFilled(vRoomRate) And ValueIsFilled(vRoomRate.AccommodationService) And vPriceRec.Service = vRoomRate.AccommodationService Then
											vPriceRec.IsRoomRevenue = True;
											vPriceRec.IsInPrice = True;
										EndIf;
										
										FillPropertyValues(vPriceRec, vPricesRow, , "ClientType, RoomType, AccommodationType");
										vPriceRec.ClientType = vClientType;
										vPriceRec.RoomType = vRoomType;
										vPriceRec.AccommodationType = vAccommodationType;
										
										// Price tag
										vPriceRec.PriceTag = vPriceTag;
										
										// Apply formulas by day types and price tags
										If FormulasForDayTypesAndPricetags.Count() > 0 Then
											vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, vAccommodationType));
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, vEffectivePriceTag, vRoomClass, Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, vRoomClass, Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, vEffectivePriceTag, vRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, vRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, Catalogs.PriceTags.EmptyRef(), vRoomClass, Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), vRoomClass, Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, Catalogs.PriceTags.EmptyRef(), vRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), vRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, vEffectivePriceTag, vRoomClass, Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, vRoomClass, Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, vEffectivePriceTag, vRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, vRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffectivePriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, Catalogs.PriceTags.EmptyRef(), vRoomClass, Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), vRoomClass, Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, Catalogs.PriceTags.EmptyRef(), vRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), vRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = FormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											
											// Check for client type
											vFound = False;
											For Each vDTPTFormulasRow In vDTPTFormulas Do
												If vClientType = vDTPTFormulasRow.ClientType Then
													vFound = True;
													If vDTPTFormulasRow.BracketsConstant <> 0 Or vDTPTFormulasRow.Multiplier <> 0 Or vDTPTFormulasRow.Constant <> 0 Then
														vPriceRec.Price = Round((vPriceRec.Price + vDTPTFormulasRow.BracketsConstant)*vDTPTFormulasRow.Multiplier + vDTPTFormulasRow.Constant, 2);
													Else
														vPriceRec.Price = vPriceRec.Price - Round(vPriceRec.Price*(vDTPTFormulasRow.Discount/100), 2);
													EndIf;
													Break;
												EndIf;
											EndDo;
											If Not vFound Then
												For Each vDTPTFormulasRow In vDTPTFormulas Do
													If Not ValueIsFilled(vDTPTFormulasRow.ClientType) Then
														vFound = True;
														If vDTPTFormulasRow.BracketsConstant <> 0 Or vDTPTFormulasRow.Multiplier <> 0 Or vDTPTFormulasRow.Constant <> 0 Then
															vPriceRec.Price = Round((vPriceRec.Price + vDTPTFormulasRow.BracketsConstant)*vDTPTFormulasRow.Multiplier + vDTPTFormulasRow.Constant, 2);
														Else
															vPriceRec.Price = vPriceRec.Price - Round(vPriceRec.Price*(vDTPTFormulasRow.Discount/100), 2);
														EndIf;
														Break;
													EndIf;
												EndDo;
											EndIf;
										EndIf;
										
										// Apply room rate discounts
										If vRoomRate.Discount <> 0 Then
											If cmIsServiceInServiceGroup(vPricesRow.Service, vRoomRate.DiscountServiceGroup) Then
												vPriceRec.Price = vPriceRec.Price - Round(vPriceRec.Price * vRoomRate.Discount / 100, 2);
											EndIf;
										EndIf;
										
										// Apply price tag discounts
										If ValueIsFilled(vEffectivePriceTag) And vEffectivePriceTag.Discount <> 0 Then
											If cmIsServiceInServiceGroup(vPricesRow.Service, vRoomRate.DiscountServiceGroup) Then
												vPriceRec.Price = vPriceRec.Price - Round(vPriceRec.Price * vEffectivePriceTag.Discount / 100, 2);
											EndIf;
										EndIf;
										
										// Apply calendar day type discounts
										If vCalendarDayType.Discount <> 0 Then
											If cmIsServiceInServiceGroup(vPricesRow.Service, vRoomRate.DiscountServiceGroup) Then
												vPriceRec.Price = vPriceRec.Price - Round(vPriceRec.Price * vCalendarDayType.Discount / 100, 2);
											EndIf;
										EndIf;
										
										// Apply base room rate formulas
										vCurRoomRate = vRoomRate;
										vBaseRoomRate = vCurRoomRate.BasedOnRoomRate;
										While ValueIsFilled(vBaseRoomRate) Do
											If vCurRoomRate.Formulas.Count() > 0 Then
												vCurRoomRateFormulas = vCurRoomRate.Formulas.Unload();
												vCurRoomRateFormulas.Sort("ClientType, DateValidFrom Desc, Hotel Desc, RoomType Desc, Service Desc, AccommodationType Desc");
												For Each vFormulaRow In vCurRoomRateFormulas Do
													If Date >= vFormulaRow.DateValidFrom And 
													   (vPriceRec.ClientType = vFormulaRow.ClientType Or ValueIsFilled(vPriceRec.ClientType) And ValueIsFilled(vFormulaRow.ClientType) And vFormulaRow.ClientType.IsFolder And vPriceRec.ClientType.BelongsToItem(vFormulaRow.ClientType)) And 
													   (vPriceRec.Hotel = vFormulaRow.Hotel Or Not ValueIsFilled(vFormulaRow.Hotel) Or ValueIsFilled(vFormulaRow.Hotel) And vFormulaRow.Hotel.IsFolder And vPriceRec.Hotel.BelongsToItem(vFormulaRow.Hotel)) And 
													   (Not ValueIsFilled(vFormulaRow.RoomClass) And (vRoomType = vFormulaRow.RoomType Or Not ValueIsFilled(vFormulaRow.RoomType) Or ValueIsFilled(vFormulaRow.RoomType) And vFormulaRow.RoomType.IsFolder And vRoomType.BelongsToItem(vFormulaRow.RoomType)) Or
													    ValueIsFilled(vFormulaRow.RoomClass) And vRoomClass = vFormulaRow.RoomClass) And 
													   (vPriceRec.Service = vFormulaRow.Service Or Not ValueIsFilled(vFormulaRow.Service) Or ValueIsFilled(vFormulaRow.Service) And vFormulaRow.Service.IsFolder And vPriceRec.Service.BelongsToItem(vFormulaRow.Service)) And 
													   (vPriceRec.AccommodationType = vFormulaRow.AccommodationType Or Not ValueIsFilled(vFormulaRow.AccommodationType) Or ValueIsFilled(vFormulaRow.AccommodationType) And vFormulaRow.AccommodationType.IsFolder And vPriceRec.AccommodationType.BelongsToItem(vFormulaRow.AccommodationType)) Then
														// Recalculate price
														vPriceRec.Price = Round((vPriceRec.Price + vFormulaRow.BracketsConstant)*vFormulaRow.Multiplier + vFormulaRow.Constant, 2);
														If ValueIsFilled(vFormulaRow.ReplaceWithService) Then
															vPriceRec.Service = vFormulaRow.ReplaceWithService;
														EndIf;
														Break;
													EndIf;
												EndDo;
											EndIf;
											vCurRoomRate = vBaseRoomRate;
											vBaseRoomRate = vBaseRoomRate.BasedOnRoomRate;
										EndDo;
										
										// Apply room rate price rounding rule
										If vRoomRate.RoundPrice Then
											If Not ValueIsFilled(vRoomRate.RoundPriceServiceGroup) Or 
											   ValueIsFilled(vRoomRate.RoundPriceServiceGroup) And cmIsServiceInServiceGroup(vPriceRec.Service, vRoomRate.RoundPriceServiceGroup) Then
												vPriceRec.Price = Round(vPriceRec.Price, vRoomRate.RoundPriceDigits);
											EndIf;
										EndIf;
										
										If vPricesRow.IsInPrice And vPricesRow.IsRoomRevenue Then
											// Process Is per person flag
											If vPricesRow.IsPricePerPerson And vAccommodationType.NumberOfPersons4Reservation > 1 Then
												vPriceRec.Price = Round(vPriceRec.Price * vAccommodationType.NumberOfPersons4Reservation, 2);
												vPriceRec.IsPricePerPerson = False;
											EndIf;
											
											// Early check-in service
											If ValueIsFilled(vEarlyCheckInService) Then
												i = i + 1;
												
												vEarlyCheckInRec = RegisterRecords.RoomRatePrices.Add();
												vEarlyCheckInRec.SortCode = i;
												
												FillPropertyValues(vEarlyCheckInRec, vPriceRec, , "SortCode");
												
												vEarlyCheckInRec.Service = vEarlyCheckInService;
												vEarlyCheckInRec.QuantityCalculationRule = vEarlyCheckInService.QuantityCalculationRule;
												
												vEarlyCheckInRec.IsInPrice = False;
												vEarlyCheckInRec.IsRoomRevenue = vEarlyCheckInService.IsRoomRevenue;
												vEarlyCheckInRec.IsPricePerPerson = False;
												
												If ValueIsFilled(vEarlyCheckInServiceVATRate) Then
													vEarlyCheckInRec.VATRate = vEarlyCheckInServiceVATRate;
												EndIf;
											EndIf;
											
											// Late check-out service
											If ValueIsFilled(vLateCheckOutService) Then
												i = i + 1;
												
												vLateCheckOutRec = RegisterRecords.RoomRatePrices.Add();
												vLateCheckOutRec.SortCode = i;
												
												FillPropertyValues(vLateCheckOutRec, vPriceRec, , "SortCode");
												
												vLateCheckOutRec.Service = vLateCheckOutService;
												vLateCheckOutRec.QuantityCalculationRule = vLateCheckOutService.QuantityCalculationRule;
												
												vLateCheckOutRec.IsInPrice = False;
												vLateCheckOutRec.IsRoomRevenue = vLateCheckOutService.IsRoomRevenue;
												vLateCheckOutRec.IsPricePerPerson = False;
												
												If ValueIsFilled(vLateCheckOutServiceVATRate) Then
													vLateCheckOutRec.VATRate = vLateCheckOutServiceVATRate;
												EndIf;
											EndIf;
										EndIf;
									EndIf;
								EndIf;
							EndDo; // by accommodation types
						EndDo; // by room types
					EndDo; // by client types
				EndDo; // by price rows
			EndDo; // by calendar day types
		EndDo; // by price tags
	EndDo; // by room rates
	
	// Write register records if necessary
	RegisterRecords.RoomRates.Write();
	RegisterRecords.RoomRates.Write = False;
	If i > 0 Then
		RegisterRecords.RoomRatePrices.Write();
		RegisterRecords.RoomRatePrices.Write = False;
	EndIf;
	
	If Modified() Then
		Write(DocumentWriteMode.Write);
	EndIf;
EndProcedure // Posting

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode, pPostingMode)
	If DataExchange.Load Then
		Return;
	EndIf;
	vSystemUpdateMode = False;
	If AdditionalProperties.Property("SystemUpdateMode", vSystemUpdateMode) Then
		If TypeOf(vSystemUpdateMode) = Type("Boolean") And vSystemUpdateMode Then
			Return;
		EndIf;
	EndIf;
	If Not SessionParameters.UpdateInProgress Then
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
			pCancel = True;
			vMessage = "en='You do not have rights to manage prices!'; de='Sie haben keine Rechte zum Bearbeiten von Preisen!'; ru='Нет прав на управление услугами и ценами!'";
			WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
			tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
		Else
			If RatesManagement.IsRoomRateInUse(Date, RoomRate,CalendarDayType, PriceTag) Then
				pCancel = True;
				If pWriteMode = DocumentWriteMode.UndoPosting Then
					vMessage = "en = 'You cannot delete the document, because there are already reservations using this room rate with price calculation date later than the document date.'; 
					           |de = 'Sie können das Dokument nicht löschen, da es bereits Reservierungen mit diesem Zimmerpreis gibt, deren Preisberechnungsdatum nach dem Dokumentdatum liegt.'; 
							   |ru = 'Нельзя удалять документ, т.к. уже есть бронирования использующие этот тариф с датой получения цен позже даты документа.'";
				Else
					vMessage = "en = 'It is not possible to save the document with the date %1 because there are reservations dated later. Save the document with the current time.'; 
					           |de = 'Es ist nicht möglich, das Dokument mit dem Datum %1 zu speichern, da später datierte Reservierungen vorliegen. Speichern Sie das Dokument mit der aktuellen Uhrzeit.'; 
							   |ru = 'Нельзя сохранить документ датой %1 т.к. уже есть бронирования позже этой даты. Сохраните документ текущим временем.'";
					vMessage = StrTemplate(vMessage, Date);
				EndIf;
				WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
				tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
			Else
				If pWriteMode = DocumentWriteMode.Posting Then
					If ValueIsFilled(RoomRate) And Not RoomRate.IsFolder Then
						If Not ValueIsFilled(RoomRate.PriceTagType) Then
							If ValueIsFilled(PriceTag) Then
								PriceTag = Catalogs.PriceTags.EmptyRef();
							EndIf;
						EndIf;
					Endif;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		pCancel = True;
		vMessage = "en='You do not have rights to manage prices!'; de='Sie haben keine Rechte zum Bearbeiten von Preisen!'; ru='Нет прав на управление услугами и ценами!'";
		WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
		tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
		Return;
	EndIf;
	If SessionParameters.UpdateInProgress = False And RatesManagement.IsRoomRateInUse(Date, RoomRate,CalendarDayType, PriceTag) Then
		pCancel = True;
		vMessage = "en = 'You cannot delete the document, because there are already reservations using this room rate with price calculation date later than the document date.'; de = 'Sie können das Dokument nicht löschen, da es bereits Reservierungen mit diesem Zimmerpreis gibt, deren Preisberechnungsdatum nach dem Dokumentdatum liegt.'; ru = 'Нельзя удалять документ, т.к. уже есть бронирования использующие этот тариф с датой получения цен позже даты документа.'";
		WriteLogEvent(NStr("en='Document.DataValidation';ru='Документ.КонтрольДанных';de='Document.DataValidation'"), EventLogLevel.Warning, Metadata(), Ref, NStr(vMessage));
		tcCommonFunctionOnClientServer.TextMessage(NStr(vMessage), MessageStatus.Attention);
		Return;
	EndIf;
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure OnCopy(pCopiedObject)
	Author = SessionParameters.CurrentUser;
	RoomRatesApproved = False;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)  
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmFillAuthorAndDate() Export
	Date = CurrentSessionDate();
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
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmWriteToSetRoomRatePricesChangeHistory(pPeriod, pUser) Export
	// Get channges description
	vChanges = cmGetObjectChanges(ThisObject);
	If Not IsBlankString(vChanges) Then
		// Do movement on current date
		vHistoryRec = InformationRegisters.SetRoomRatePricesChangeHistory.CreateRecordManager();
		
		vHistoryRec.Period = pPeriod;
		vHistoryRec.SetRoomRatePrices = Ref;
		
		FillPropertyValues(vHistoryRec, ThisObject);
		vHistoryRec.Changes = vChanges;
		
		vHistoryRec.User = pUser;
		
		// Store tabular parts
		vPrices = New ValueStorage(Prices.Unload());
		vHistoryRec.Prices = vPrices;
		vFormulas = New ValueStorage(Formulas.Unload());
		vHistoryRec.Formulas = vFormulas;
		vFormulasForDayTypesAndPricetags = New ValueStorage(FormulasForDayTypesAndPricetags.Unload());
		vHistoryRec.FormulasForDayTypesAndPricetags = vFormulasForDayTypesAndPricetags;
		
		// Write record
		vHistoryRec.Write(True);   
		
		// User activity history
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(Ref, vChanges, Hotel, pUser, pPeriod);
	EndIf;
EndProcedure // pmWriteToSetRoomRatePricesChangeHistory

// -----------------------------------------------------------------------------
Function pmGetPreviousObjectState(pPeriod) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	*
	|FROM
	|	InformationRegister.SetRoomRatePricesChangeHistory.SliceLast(&qPeriod, SetRoomRatePrices = &qDoc) AS SetRoomRatePricesChangeHistory";
	vQry.SetParameter("qPeriod", pPeriod);
	vQry.SetParameter("qDoc", Ref);
	vStates = vQry.Execute().Unload();
	If vStates.Count() > 0 Then
		Return vStates.Get(0);
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetPreviousObjectState

// -----------------------------------------------------------------------------
Procedure pmRestoreAttributesFromHistory(pHistoryRec) Export
	FillPropertyValues(ThisObject, pHistoryRec, , "Number, Date, Author");
	If Not IsBlankString(pHistoryRec.Number) Then
		Number = pHistoryRec.Number;
	EndIf;
	If ValueIsFilled(pHistoryRec.Date) Then
		Date = pHistoryRec.Date;
	EndIf;
	If ValueIsFilled(pHistoryRec.Author) Then
		Author = pHistoryRec.Author;
	EndIf;
	// Restore tabular parts
	vPrices = pHistoryRec.Prices.Get();
	If vPrices <> Undefined Then
		Prices.Load(vPrices);
	Else
		Prices.Clear();
	EndIf;
	vFormulas = pHistoryRec.Formulas.Get();
	If vFormulas <> Undefined Then
		Formulas.Load(vFormulas);
	Else
		Formulas.Clear();
	EndIf;
	vFormulasForDayTypesAndPricetags = pHistoryRec.FormulasForDayTypesAndPricetags.Get();
	If vFormulasForDayTypesAndPricetags <> Undefined Then
		FormulasForDayTypesAndPricetags.Load(vFormulasForDayTypesAndPricetags);
	Else
		FormulasForDayTypesAndPricetags.Clear();
	EndIf;
EndProcedure // pmRestoreAttributesFromHistory

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
		vMsgTextDe = vMsgTextDe + "<Hotel> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "Hotel", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(RoomRate) Then
		vHasErrors = True; 
		vMsgTextRu = vMsgTextRu + "Реквизит <Тариф> должен быть заполнен!" + Chars.LF;
		vMsgTextEn = vMsgTextEn + "<Room rate> attribute should be filled!" + Chars.LF;
		vMsgTextDe = vMsgTextDe + "<Room rate> attribute should be filled!" + Chars.LF;
		pAttributeInErr = ?(pAttributeInErr = "", "RoomRate", pAttributeInErr);
	EndIf;
	If Not ValueIsFilled(CalendarDayType) Then
		If Not ValueIsFilled(RoomRate) Or ValueIsFilled(RoomRate) And RoomRate.IsFolder Or ValueIsFilled(RoomRate) And Not RoomRate.IsFolder And Not RoomRate.UsePricesFromCalendar Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "Реквизит <Тип дня календаря> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Calendar day type> attribute should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Calendar day type> attribute should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "CalendarDayType", pAttributeInErr);
		EndIf;
	EndIf;
	For Each vRow In Prices Do
		If Not ValueIsFilled(vRow.Service) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В строке " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " реквизит <Услуга> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Service> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Service> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Prices", pAttributeInErr);
		EndIf;
		If Not ValueIsFilled(vRow.Currency) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В строке " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " реквизит <Валюта> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<Currency> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<Currency> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Prices", pAttributeInErr);
		EndIf;
		If Not ValueIsFilled(vRow.VATRate) Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В строке " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " реквизит <Ставка НДС> должен быть заполнен!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "<VAT rate> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "<VAT rate> attribute in line number " + Format(vRow.LineNumber, "ND=5; NFD=0; NG=") + " should be filled!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Prices", pAttributeInErr);
		EndIf;
	EndDo;
	// Check duplicate rows
	If Prices.Count() > 0 Then
		vPrices = Prices.Unload();
		vPrices.GroupBy("ClientType, Service, RoomClass, RoomType, AccommodationType",);
		If Prices.Count() <> vPrices.Count() Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В таблице цен есть дубликаты строк!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "There are duplicate rows in the prices table!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Es gibt doppelte Zeilen in der Preistabelle!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Prices", pAttributeInErr);
		EndIf;
	EndIf;
	If Formulas.Count() > 0 Then
		vFormulas = Formulas.Unload();
		vFormulas.GroupBy("ClientType, Service, RoomClass, RoomType, AccommodationType",);
		If Formulas.Count() <> vFormulas.Count() Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В таблице формул по видам размещений есть дубликаты строк!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "There are duplicate rows in the accommodation types formulas table!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Es gibt doppelte Zeilen in der formeltabelle für Bettentypen!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "Formulas", pAttributeInErr);
		EndIf;
	EndIf;
	If FormulasForDayTypesAndPricetags.Count() > 0 Then
		vFfDtPts = FormulasForDayTypesAndPricetags.Unload();
		vFfDtPts.GroupBy("ClientType, CalendarDayType, PriceTag, AccommodationType, RoomClass, RoomType",);
		If FormulasForDayTypesAndPricetags.Count() <> vFfDtPts.Count() Then
			vHasErrors = True; 
			vMsgTextRu = vMsgTextRu + "В таблице формул по типам дней и признакам цен есть дубликаты строк!" + Chars.LF;
			vMsgTextEn = vMsgTextEn + "There are duplicate rows in the formulas table by day types and price tags!" + Chars.LF;
			vMsgTextDe = vMsgTextDe + "Es gibt doppelte Zeilen in der Tabelle der Formeln nach Tagetypen und Preiseigenschaften!" + Chars.LF;
			pAttributeInErr = ?(pAttributeInErr = "", "FormulasForDayTypesAndPricetags", pAttributeInErr);
		EndIf;
	EndIf;
	If ValueIsFilled(RoomRate) And Not RoomRate.IsFolder Then
		If ValueIsFilled(RoomRate.PriceTagType) Then
			If Not ValueIsFilled(PriceTag) Then
				vHasErrors = True; 
				vMsgTextRu = vMsgTextRu + "Для динамического тарифа должен быть указан признак цены!" + Chars.LF;
				vMsgTextEn = vMsgTextEn + "Price tag should be filled for the dynamic rate!" + Chars.LF;
				vMsgTextDe = vMsgTextDe + "Für einen dynamischen Tarif muss ein Preiszeichen angegeben werden!" + Chars.LF;
				pAttributeInErr = ?(pAttributeInErr = "", "PriceTag", pAttributeInErr);
			EndIf;
		EndIf;
	EndIf;
	If vHasErrors Then
		pMessage = "ru='" + TrimAll(vMsgTextRu) + "';" + "en='" + TrimAll(vMsgTextEn) + "';" + "de='" + TrimAll(vMsgTextDe) + "';";
	EndIf;
	Return vHasErrors;
EndFunction // pmCheckDocumentAttributes

// -----------------------------------------------------------------------------
Function pmGetListOfActiveRoomRates() Export
	vRoomRates = New ValueTable();
	If ValueIsFilled(RoomRate) Then
		If RoomRate.IsFolder Then
			vRoomRates = cmGetAllRoomRates(Hotel, RoomRate);
		Else
			vRoomRates.Columns.Add("RoomRate", cmGetCatalogTypeDescription("RoomRates"));
			vRow = vRoomRates.Add();
			vRow.RoomRate = RoomRate;
		EndIf;
	Else
		vRoomRates = cmGetAllRoomRates(Hotel);
	EndIf;
	Return vRoomRates;
EndFunction // pmGetListOfActiveRoomRates

// -----------------------------------------------------------------------------
Function pmGetListOfActiveCalendarDayTypes() Export
	vCalendarDayTypes = New ValueTable();
	If ValueIsFilled(CalendarDayType) Then
		If CalendarDayType.IsFolder Then
			vCalendarDayTypes = cmGetAllCalendarDayTypes(CalendarDayType);
		Else
			vCalendarDayTypes.Columns.Add("CalendarDayType", cmGetCatalogTypeDescription("CalendarDayTypes"));
			vRow = vCalendarDayTypes.Add();
			vRow.CalendarDayType = CalendarDayType;
		EndIf;
	Else
		If ValueIsFilled(RoomRate) And Not RoomRate.IsFolder And RoomRate.UsePricesFromCalendar Then
			vCalendarDayTypes.Columns.Add("CalendarDayType", cmGetCatalogTypeDescription("CalendarDayTypes"));
			vRow = vCalendarDayTypes.Add();
			vRow.CalendarDayType = Catalogs.CalendarDayTypes.EmptyRef();
		Else
			vCalendarDayTypes = cmGetAllCalendarDayTypes();
		EndIf;
	EndIf;
	Return vCalendarDayTypes;
EndFunction // pmGetListOfActiveCalendarDayTypes

// -----------------------------------------------------------------------------
Function pmGetListOfActivePriceTags() Export
	vPriceTags = New ValueTable();
	If ValueIsFilled(PriceTag) Then
		If PriceTag.IsFolder Then
			vPriceTags = cmGetAllPriceTags(PriceTag);
		Else
			vPriceTags.Columns.Add("PriceTag", cmGetCatalogTypeDescription("PriceTags"));
			vRow = vPriceTags.Add();
			vRow.PriceTag = PriceTag;
		EndIf;
	Else
		vPriceTags.Columns.Add("PriceTag", cmGetCatalogTypeDescription("PriceTags"));
		vRow = vPriceTags.Add();
		vRow.PriceTag = PriceTag;
	EndIf;
	Return vPriceTags;
EndFunction // pmGetListOfActivePriceTags

// -----------------------------------------------------------------------------
Function pmGetListOfActiveClientTypes(pClientType, pClientTypes) Export
	vClientTypes = New ValueTable();
	vCacheRow = pClientTypes.Find(pClientType, "ClientType");
	If vCacheRow = Undefined Then
		If ValueIsFilled(pClientType) Then
			If pClientType.IsFolder Then
				vClientTypes = cmGetAllClientTypes(Hotel, pClientType);
			Else
				vClientTypes.Columns.Add("ClientType", cmGetCatalogTypeDescription("ClientTypes"));
				vRow = vClientTypes.Add();
				vRow.ClientType = pClientType;
			EndIf;
		Else
			vClientTypes.Columns.Add("ClientType", cmGetCatalogTypeDescription("ClientTypes"));
			vRow = vClientTypes.Add();
			vRow.ClientType = pClientType;
		EndIf;
		vCacheRow = pClientTypes.Add();
		vCacheRow.ClientType = pClientType;
		vCacheRow.ClientTypes = vClientTypes;
	Else
		vClientTypes = vCacheRow.ClientTypes;
	EndIf;
	Return vClientTypes;
EndFunction // pmGetListOfActiveClientTypes

// -----------------------------------------------------------------------------
Function pmGetListOfActiveRoomTypes(pRoomType, pRoomClass, pRoomTypes) Export
	vRoomTypes = New ValueTable();
	vCacheRows = pRoomTypes.FindRows(New Structure("RoomClass, RoomType", pRoomClass, pRoomType));
	If vCacheRows.Count() = 0 Then
		If ValueIsFilled(pRoomType) Then
			If pRoomType.IsFolder Then
				vRoomTypes = cmGetAllRoomTypes(Hotel, pRoomType, pRoomClass);
			Else
				vRoomTypes.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
				vRoomTypes.Columns.Add("RoomClass", cmGetCatalogTypeDescription("RoomTypeClasses"));
				vRow = vRoomTypes.Add();
				vRow.RoomClass = pRoomType.RoomClass;
				vRow.RoomType = pRoomType;
			EndIf;
		Else
			vRoomTypes = cmGetAllRoomTypes(Hotel, , pRoomClass);
		EndIf;
		vCacheRow = pRoomTypes.Add();
		vCacheRow.RoomClass = pRoomClass;
		vCacheRow.RoomType = pRoomType;
		vCacheRow.RoomTypes = vRoomTypes;
	Else
		vRoomTypes = vCacheRows.Get(0).RoomTypes;
	EndIf;
	Return vRoomTypes;
EndFunction // pmGetListOfActiveRoomTypes

// -----------------------------------------------------------------------------
Function pmGetListOfActiveAccommodationTypes(pAccommodationType, pAccommodationTypes) Export
	vAccommodationTypes = New ValueTable();
	vCacheRow = pAccommodationTypes.Find(pAccommodationType, "AccommodationType");
	If vCacheRow = Undefined Then
		If ValueIsFilled(pAccommodationType) Then
			If pAccommodationType.IsFolder Then
				vAccommodationTypes = cmGetAllAccommodationTypes(pAccommodationType);
			Else
				vAccommodationTypes.Columns.Add("AccommodationType", cmGetCatalogTypeDescription("AccommodationTypes"));
				vRow = vAccommodationTypes.Add();
				vRow.AccommodationType = pAccommodationType;
			EndIf;
		Else
			vAccommodationTypes = cmGetAllAccommodationTypes();
		EndIf;
		vCacheRow = pAccommodationTypes.Add();
		vCacheRow.AccommodationType = pAccommodationType;
		vCacheRow.AccommodationTypes = vAccommodationTypes;
	Else
		vAccommodationTypes = vCacheRow.AccommodationTypes;
	EndIf;
	Return vAccommodationTypes;
EndFunction // pmGetListOfActiveAccommodationTypes

// -----------------------------------------------------------------------------
Function pmSortPrices(pPosting = False, pPrices = Undefined) Export
	// Create working value table and add sort columns to it
	If pPrices = Undefined Then
		vPrices = Prices.Unload();
	Else
		vPrices = pPrices;
	EndIf;
	// Process accommodation type formulas
	If pPosting Then
		If Formulas.Count() > 0 Then
			j = 0;
			vPricesCount = vPrices.Count();
			While j < vPricesCount Do
				vRow = vPrices.Get(j);
				vRowClientType = vRow.ClientType;
				vRowRoomType = vRow.RoomType;
				vRowRoomClass = vRow.RoomClass;
				vRowAccommodationType = vRow.AccommodationType;
				vFormulasHasRowsByClientType = ?(Formulas.Find(vRowClientType, "ClientType") = Undefined, False, True);
				If ValueIsFilled(vRowAccommodationType) And Not vRowAccommodationType.IsFolder Then
					i = Formulas.Count() - 1;
					While i >= 0 Do
						vFormulaRow = Formulas.Get(i);
						If vRowAccommodationType = vFormulaRow.MasterAccType And 
						  (vRowClientType = vFormulaRow.ClientType Or Not ValueIsFilled(vFormulaRow.ClientType) And Not vFormulasHasRowsByClientType) And
						  (vRowRoomType = vFormulaRow.RoomType And ValueIsFilled(vFormulaRow.RoomType) Or 
						   vRowRoomClass = vFormulaRow.RoomClass And ValueIsFilled(vFormulaRow.RoomClass) Or  
						   Not ValueIsFilled(vRowRoomType) And Not ValueIsFilled(vRowRoomClass) And ValueIsFilled(vFormulaRow.RoomType) And Not ValueIsFilled(vFormulaRow.RoomClass) Or 
						   Not ValueIsFilled(vRowRoomType) And Not ValueIsFilled(vRowRoomClass) And Not ValueIsFilled(vFormulaRow.RoomType) And Not ValueIsFilled(vFormulaRow.RoomClass) Or 
						   ValueIsFilled(vRowRoomType) And vRowRoomType.IsFolder And ValueIsFilled(vFormulaRow.RoomType) And vFormulaRow.RoomType.BelongsToItem(vRowRoomType) Or
						   ValueIsFilled(vRowRoomType) And Not vRowRoomType.IsFolder And ValueIsFilled(vFormulaRow.RoomClass) And vRowRoomType.RoomClass = vFormulaRow.RoomClass Or
						   ValueIsFilled(vRowRoomType) And Not ValueIsFilled(vFormulaRow.RoomType) And Not ValueIsFilled(vFormulaRow.RoomClass) Or 
						   ValueIsFilled(vRowRoomClass) And Not ValueIsFilled(vFormulaRow.RoomType) And Not ValueIsFilled(vFormulaRow.RoomClass)) And 
						  (Not ValueIsFilled(vFormulaRow.Service) And vRow.IsRoomRevenue Or 
						   ValueIsFilled(vFormulaRow.Service) And vFormulaRow.Service = vRow.Service) Then
							vSkipRow = False;
							vPricesRows = Prices.FindRows(New Structure("Service, RoomClass, RoomType, AccommodationType, ClientType", vRow.Service, vRow.RoomClass, vRow.RoomType, vFormulaRow.AccommodationType, vRow.ClientType));
							If vPricesRows.Count() > 0 Then
								vSkipRow = True;
							EndIf;
							If Not vSkipRow Then
								vPricesRow = vPrices.Add();
								FillPropertyValues(vPricesRow, vRow, , "LineNumber");
								vPricesRow.Price = Round((vPricesRow.Price + vFormulaRow.BracketsConstant) * vFormulaRow.Multiplier + vFormulaRow.Constant, 2);
								vPricesRow.AccommodationType = vFormulaRow.AccommodationType;  
								If Not ValueIsFilled(vRowRoomType) And Not ValueIsFilled(vRowRoomClass) And ValueIsFilled(vFormulaRow.RoomType) And Not ValueIsFilled(vFormulaRow.RoomClass) Then
									vPricesRow.RoomType = vFormulaRow.RoomType;
								EndIf;	
							EndIf;
						EndIf;
						i = i - 1;
					EndDo;
				EndIf;
				j = j + 1;
			EndDo;			
		EndIf;
	EndIf;
	// Add sorting columns
	vPrices.Columns.Add("RoomClassSortCode", cmGetSortCodeTypeDescription(), "Room class sort code", 10);
	vPrices.Columns.Add("RoomTypeSortCode", cmGetSortCodeTypeDescription(), "Room type sort code", 10);
	vPrices.Columns.Add("AccommodationTypeSortCode", cmGetSortCodeTypeDescription(), "Accommodation type sort code", 10);
	vPrices.Columns.Add("ServiceSortCode", cmGetSortCodeTypeDescription(), "Service sort code", 10);
	// Fill new columns
	For Each vRow In vPrices Do
		If ValueIsFilled(vRow.RoomClass) Then 
			vRow.RoomClassSortCode = vRow.RoomClass.SortCode;
		Else
			vRow.RoomClassSortCode = cmGetMaxSortCodeValue();
		EndIf;
		If ValueIsFilled(vRow.RoomType) Then
			If Not ValueIsFilled(vRow.RoomClass) Then
				vRow.RoomClassSortCode = vRow.RoomClass.SortCode;
			EndIf;
			vRow.RoomTypeSortCode = vRow.RoomType.SortCode;
		Else
			If Not ValueIsFilled(vRow.RoomClass) Then
				vRow.RoomClassSortCode = cmGetMaxSortCodeValue();
			EndIf;
			vRow.RoomTypeSortCode = cmGetMaxSortCodeValue();
		EndIf;
		If ValueIsFilled(vRow.AccommodationType) Then 
			vRow.AccommodationTypeSortCode = vRow.AccommodationType.SortCode;
		Else
			vRow.AccommodationTypeSortCode = cmGetMaxSortCodeValue();
		EndIf;
		If ValueIsFilled(vRow.Service) Then 
			vRow.ServiceSortCode = vRow.Service.SortCode;
		Else
			vRow.ServiceSortCode = cmGetMaxSortCodeValue();
		EndIf;
	EndDo;
	// Sort by sort columns
	If pPosting Then
		vPrices.Sort("IsRoomRevenue Desc, IsInPrice Desc, ServiceSortCode, RoomClassSortCode, RoomTypeSortCode, AccommodationTypeSortCode");
	Else
		vPrices.Sort("RoomClassSortCode, RoomTypeSortCode, AccommodationTypeSortCode, IsRoomRevenue Desc, IsInPrice Desc, ServiceSortCode");
	EndIf;
	// Return resulting table
	Return vPrices;
EndFunction // pmSortPrices

#EndRegion
