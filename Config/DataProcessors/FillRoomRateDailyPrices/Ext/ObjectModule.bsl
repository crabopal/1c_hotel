
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
		If ValueIsFilled(Hotel) Then
			RoomRate = Hotel.RoomRate;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = CurrentSessionDate();
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = CurrentSessionDate() + 24*3600*30;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Do processing
	pmDoFill(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Procedure pmDoFill(pIsInteractive = False) Export
	// Log processing start
	WriteLogEvent(NStr("en='DataProcessor.FillRoomRateDailyPrices';ru='Обработка.ЗаполнениеЦенТарифовПоДням';de='DataProcessor.FillRoomRateDailyPrices'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	
	If Hotel.UseRoomRateDailyPrices = False Then
		vMessage = NStr("en = 'Hotel not using room rate daily prices'; ru = 'В отеле не включено использование регистра Цены по тарифам по дням'; de = 'Hotel verwendet keine Zimmerpreis-Tagespreise'");
		WriteLogEvent(NStr("en='DataProcessor.FillRoomRateDailyPrices';ru='Обработка.ЗаполнениеЦенТарифовПоДням';de='DataProcessor.FillRoomRateDailyPrices'"), EventLogLevel.Error, ThisObject.Metadata(), Undefined, vMessage);
		Raise vMessage; 
	EndIf;
	
	// Check parameters
	If Not ValueIsFilled(PeriodFrom) Then
		vMessage = NStr("ru='Не указано начало периода!';
		                |de='Der Beginn des Zeitraums ist nicht angegeben!'; 
						|en='Period from is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.FillRoomRateDailyPrices';ru='Обработка.ЗаполнениеЦенТарифовПоДням';de='DataProcessor.FillRoomRateDailyPrices'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		vMessage = NStr("ru='Не указано окончание периода!';
		                |de='Das Ende des Zeitraums ist nicht angegeben!';
						|en='Period to is not set!'");
		WriteLogEvent(NStr("en='DataProcessor.FillRoomRateDailyPrices';ru='Обработка.ЗаполнениеЦенТарифовПоДням';de='DataProcessor.FillRoomRateDailyPrices'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	
	vCurrentSessionDate = CurrentSessionDate();
	
	// Get all hotel room types and all accommodation types
	vAllRoomTypes = cmGetAllRoomTypes(Hotel, RoomType);
	vAllAccommodationTypes = cmGetAllAccommodationTypes(, Hotel);
	vAllClientTypes = cmGetAllClientTypes(Hotel);
	vAllClientTypesRow = vAllClientTypes.Add();
	vAllClientTypesRow.ClientType = Catalogs.ClientTypes.EmptyRef();
	
	// Caches
	vRoomTypeRoomTypesCache = Undefined;

	// Recordset used to delete records from prices cache
	vRoomRateDailyPricesToDeleteRecordSet = InformationRegisters.RoomRateDailyPrices.CreateRecordSet();
	
	// Write records to the room rate daily prices information register
	vRoomRates = GetListOfActiveRoomRates();
	For Each vRoomRatesRow In vRoomRates Do
		vCurRoomRate = vRoomRatesRow.RoomRate;
		
		// Get room rate formulas
		If Not ValueIsFilled(vCurRoomRate.BasedOnRoomRate) Then
			vUsePricesFromCalendar = vCurRoomRate.UsePricesFromCalendar;
			
			// Get active calendar day types
			vCalendarDayTypes = cmGetCalendarDayTypes(vCurRoomRate, PeriodFrom, PeriodTo, RoomType, Hotel, vCurrentSessionDate);
			vCalendarDayTypesTable = vCalendarDayTypes.Copy(, "CalendarDayType");
			vCalendarDayTypesTable.GroupBy("CalendarDayType", );
			vCalendarDayTypesList = New ValueList();
			vCalendarDayTypesList.LoadValues(vCalendarDayTypesTable.UnloadColumn("CalendarDayType"));
			If vCalendarDayTypesList.FindByValue(Catalogs.CalendarDayTypes.EmptyRef()) = Undefined Then
				vCalendarDayTypesList.Add(Catalogs.CalendarDayTypes.EmptyRef());
			EndIf;
			
			// Get active set room rate prices for the given room rate, current session time and all calendar day types
			vSetRoomRatePrices = GetActiveSetRoomRatePrices(?(ValueIsFilled(vCurRoomRate.BasedOnRoomRate), vCurRoomRate.BasedOnRoomRate, vCurRoomRate), vCalendarDayTypesList, vCurrentSessionDate, Hotel);

			// Do for each day in the current room rate calendar
			vCurDate = BegOfDay(PeriodFrom);
			While vCurDate <= BegOfDay(PeriodTo) Do   
				
				// Room rate service packages
				vServicePackages = vCurRoomRate.GetObject().pmGetRoomRateServicePackagesList(, True);
				vServicePackagesCache = New ValueTable();
				vServicePackagesCache.Columns.Add("ServicePackage");
				vServicePackagesCache.Columns.Add("Services");
				For Each vServicePackagesItem In vServicePackages Do
					vCurServicePackage = vServicePackagesItem.Value;
					vServicePackagesCacheRow = vServicePackagesCache.Add();
					vServicePackagesCacheRow.ServicePackage = vCurServicePackage;
					vServicePackagesCacheRow.Services = Catalogs.ServicePackages.GetServices(vCurServicePackage, vCurDate, vCurrentSessionDate);
					vServicePackagesCacheRow.Services.Indexes.Add("ClientType, IsInPrice, AccountingDayNumber, AccountingDate");
				EndDo;
				
				// Create record set object
				If Not ValueIsFilled(RoomType) Then
					vRoomRateDailyPricesRecordSet = InformationRegisters.RoomRateDailyPrices.CreateRecordSet();

					// Set filter to clear all price cache records for the given room rate and given date
					If ValueIsFilled(Hotel) Then
						vRoomRateDailyPricesToDeleteRecordSet.Filter.Reset();
						vRoomRateDailyPricesToDeleteRecordSet.Filter.RoomRate.Set(vCurRoomRate);
						vRoomRateDailyPricesToDeleteRecordSet.Filter.Hotel.Set(Hotel);
						vRoomRateDailyPricesToDeleteRecordSet.Filter.Period.Set(vCurDate);
						
						// Clear all records by given filters
						vRoomRateDailyPricesToDeleteRecordSet.Write(True);
					EndIf;
					
					// Set filter
					vRoomRateDailyPricesRecordSet.Filter.Reset();
					vRoomRateDailyPricesRecordSet.Filter.RoomRate.Set(vCurRoomRate);
					vRoomRateDailyPricesRecordSet.Filter.Period.Set(vCurDate);
					If ValueIsFilled(Hotel) Then
						vRoomRateDailyPricesRecordSet.Filter.Hotel.Set(Hotel);
					EndIf;
				EndIf;
			
				// Do for each hotel room type
				For Each vAllRoomTypesRow In vAllRoomTypes Do
					vCurRoomType = vAllRoomTypesRow.RoomType;
					vCurRoomClass = vAllRoomTypesRow.RoomClass;
					vCurHotel = vCurRoomType.Owner;

					// Set filter to clear all price cache records for the given room rate, room type and given date
					If ValueIsFilled(RoomType) Or Not ValueIsFilled(Hotel) Then
						vRoomRateDailyPricesToDeleteRecordSet.Filter.Reset();
						vRoomRateDailyPricesToDeleteRecordSet.Filter.RoomRate.Set(vCurRoomRate);
						vRoomRateDailyPricesToDeleteRecordSet.Filter.Hotel.Set(vCurHotel);
						vRoomRateDailyPricesToDeleteRecordSet.Filter.RoomType.Set(vCurRoomType);
						vRoomRateDailyPricesToDeleteRecordSet.Filter.Period.Set(vCurDate);
						
						// Clear all records by given filters
						vRoomRateDailyPricesToDeleteRecordSet.Write(True);
					EndIf;
					
					// Create record set object
					If ValueIsFilled(RoomType) Then
						vRoomRateDailyPricesRecordSet = InformationRegisters.RoomRateDailyPrices.CreateRecordSet();
						
						// Set filter
						vRoomRateDailyPricesRecordSet.Filter.Reset();
						vRoomRateDailyPricesRecordSet.Filter.RoomRate.Set(vCurRoomRate);
						vRoomRateDailyPricesRecordSet.Filter.Period.Set(vCurDate);
						vRoomRateDailyPricesRecordSet.Filter.RoomType.Set(vCurRoomType);
						vRoomRateDailyPricesRecordSet.Filter.Hotel.Set(vCurHotel);
					EndIf;
					
					// Get calendar day type valid for the given room rate and date
					vCurCalendarDayType = Undefined;
					vCalendarDayTypesRows = vCalendarDayTypes.FindRows(New Structure("AccountingDate, RoomType", vCurDate, vCurRoomType));
					If vCalendarDayTypesRows.Count() > 0 Then
						vCurCalendarDayType = vCalendarDayTypesRows.Get(0).CalendarDayType;
					EndIf;
					If ValueIsFilled(vCurCalendarDayType) Or vCurRoomRate.UsePricesFromCalendar Then
						#IF CLIENT THEN
							Status(NStr("en='Processing room rate: '; ru='Заполнение по тарифу: '; de='Füllen einer Tariff: '") + TrimAll(vCurRoomRate) + NStr("en=', room type: '; ru=', типу номера: '; de=', Zimmertyp: '") + TrimAll(vCurRoomType) + NStr("en=', day type: '; ru=', типу дня: '; de=', Datumtyp: '") + TrimAll(vCurCalendarDayType) + NStr("en=', date: '; ru=', дате: '; de=', Datum: '") + Format(vCurDate, "DF=dd.MM.yyyy") + "...");
						#ENDIF
						
						vPrevSetRoomRatePrices = Undefined;  
						vFormulasForDayTypesAndPricetags = Undefined;  
						vPrices = Undefined;
						
						vSetRoomRatePricesFilterRows = vSetRoomRatePrices.FindRows(New Structure("CalendarDayType", vCurCalendarDayType));
						For Each vSetRoomRatePricesRow In vSetRoomRatePricesFilterRows Do   
							vCurSetRoomRatePrices = vSetRoomRatePricesRow.SetRoomRatePrices;
							
							vCurPriceTag = vSetRoomRatePricesRow.PriceTag;
							vEffPriceTag = vCurPriceTag;
							If ValueIsFilled(vCurRoomRate.BasedOnRoomRate) And ValueIsFilled(vCurRoomRate.BasedOnPriceTag) Then
								vEffPriceTag = vCurRoomRate.BasedOnPriceTag;
							EndIf; 
							
							If vCurSetRoomRatePrices <> vPrevSetRoomRatePrices Then
								vPrevSetRoomRatePrices = vCurSetRoomRatePrices;  

								vPrices = GetDocumentPrices(vCurSetRoomRatePrices);
								vDocPrices = vPrices.Copy();
								vFormulas = vCurSetRoomRatePrices.Formulas.Unload();    
								vFormulasForDayTypesAndPricetags = vCurSetRoomRatePrices.FormulasForDayTypesAndPricetags.Unload(); 
								vFormulasForDayTypesAndPricetags.Indexes.Add("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType");
								
								// Build list of room types available in the accommodation type formulas
								vRoomTypesForPrices = New ValueList();
								vAccommodationService = Catalogs.Services.EmptyRef();
								If Not vCurSetRoomRatePrices.RoomRate.IsFolder Then
									vAccommodationService = vCurSetRoomRatePrices.RoomRate.AccommodationService;
								EndIf;
								If Not ValueIsFilled(vAccommodationService) Then
									For Each vPrcRow In vPrices Do
										If ValueIsFilled(vPrcRow.Service) And vPrcRow.IsRoomRevenue And vPrcRow.IsInPrice Then
											vAccommodationService = vPrcRow.Service;
											Break;
										EndIf;
									EndDo;
								EndIf;
								If ValueIsFilled(vAccommodationService) Then
									For Each vAccTypFormulasRow In vFormulas Do
										If vAccommodationService = vAccTypFormulasRow.Service And vAccTypFormulasRow.MasterAccType = vAccTypFormulasRow.AccommodationType Then
											If ValueIsFilled(vAccTypFormulasRow.RoomType) Then
												If vAccTypFormulasRow.RoomType.IsFolder Then
													vFolderRoomTypes = GetListOfActiveRoomTypes(vAccTypFormulasRow.RoomType, vAccTypFormulasRow.RoomClass, vRoomTypeRoomTypesCache);
													For Each vFolderRoomTypesRow In vFolderRoomTypes Do
														If vRoomTypesForPrices.FindByValue(vFolderRoomTypesRow.RoomType) = Undefined Then
															vRoomTypesForPrices.Add(vFolderRoomTypesRow.RoomType);
														EndIf;
													EndDo;
												Else
													If vRoomTypesForPrices.FindByValue(vAccTypFormulasRow.RoomType) = Undefined Then
														vRoomTypesForPrices.Add(vAccTypFormulasRow.RoomType);
													EndIf;
												EndIf;
											ElsIf ValueIsFilled(vAccTypFormulasRow.RoomClass) Then
												vRoomClassRoomTypes = GetListOfActiveRoomTypes(Catalogs.RoomTypes.EmptyRef(), vAccTypFormulasRow.RoomClass, vRoomTypeRoomTypesCache);
												For Each vRoomClassRoomTypesRow In vRoomClassRoomTypes Do
													If vRoomTypesForPrices.FindByValue(vRoomClassRoomTypesRow.RoomType) = Undefined Then
														vRoomTypesForPrices.Add(vRoomClassRoomTypesRow.RoomType);
													EndIf;
												EndDo;
											Else
												vRoomTypesForPrices.Clear();
												vRoomTypesForPrices.LoadValues(GetListOfActiveRoomTypes(Catalogs.RoomTypes.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vRoomTypeRoomTypesCache).UnloadColumn("RoomType"));
												Break;
											EndIf;
										EndIf;
									EndDo;
								EndIf;
								
								// Get document price rows
								If vUsePricesFromCalendar Then
									vPrices = GetEffectivePrices(vCurRoomRate, vCurSetRoomRatePrices, vCurrentSessionDate, vCurDate);
								Else
									// Split prices rows with empty room type according to the room types for prices list
									If vRoomTypesForPrices.Count() > 0 Then
										For Each vPricesRow In vPrices Do
											If Not ValueIsFilled(vPricesRow.RoomType) Then
												vFirstRoomTypeIsAssigned = False;
												For Each vRoomTypesForPricesItem In vRoomTypesForPrices Do
													vWrkRoomType = vRoomTypesForPricesItem.Value;
													If Not ValueIsFilled(vPricesRow.RoomClass) Or vPricesRow.RoomClass = vWrkRoomType.RoomClass Then
														If Not vFirstRoomTypeIsAssigned Then
															vFirstRoomTypeIsAssigned = True;
															vPricesRow.RoomType = vWrkRoomType;
														Else
															vNewPricesRow = vPrices.Insert(vPrices.IndexOf(vPricesRow)+1);
															FillPropertyValues(vNewPricesRow, vPricesRow, , "LineNumber");
															vNewPricesRow.RoomType = vWrkRoomType;
														EndIf;
													EndIf;
												EndDo;
											EndIf;
										EndDo;
									EndIf;
									
									// Sort prices
									vPrices = PostprocessPrices(vPrices, vDocPrices, vFormulas);
								EndIf;
								
								// Add index
								vPrices.Indexes.Add("ClientType, IsInPrice");
							EndIf;
							
							// Do  for each hotel accommodation type
							For Each vAllAccommodationTypesRow In vAllAccommodationTypes Do
								vCurAccommodationType = vAllAccommodationTypesRow.AccommodationType;
								
								// Check permitted accommodation types for the given room type
								If vCurRoomType.AccommodationTypesAllowed.Count() > 0 Then
									If vCurRoomType.AccommodationTypesAllowed.Find(vCurAccommodationType) = Undefined Then
										Continue;
									EndIf;
								EndIf;
								
								// Do for each hotel client type
								For Each vAllClientTypesRow In vAllClientTypes Do
									vCurClientType = vAllClientTypesRow.ClientType;
									
									// Initialize day price and currency
									vDayPrice = 0;
									vDayPriceCurrency = Catalogs.Currencies.EmptyRef();
									
									// Calculate day price
									vPricesWereFound = False;
									vClientTypePrices = vPrices.FindRows(New Structure("ClientType, IsInPrice", vCurClientType, True));
									If vClientTypePrices.Count() = 0 Then
										If ValueIsFilled(vCurClientType) And ValueIsFilled(vCurClientType.Parent) Then
											vClientTypePrices = vPrices.FindRows(New Structure("ClientType, IsInPrice", vCurClientType.Parent, True));
										EndIf;
									EndIf;
									For Each vPricesRow In vClientTypePrices Do
										vPricesRoomType = vPricesRow.RoomType;
										vPricesRoomClass = vPricesRow.RoomClass;
										vPricesAccommodationType = vPricesRow.AccommodationType;
										
										// Get list of active room types and check if current room type is in this list
										If ValueIsFilled(vPricesRoomType) Then
											If Not vPricesRow.RoomTypeIsFolder Then
												If vPricesRoomType <> vCurRoomType Then
													Continue;
												EndIf;
											Else
												vRoomTypes = GetListOfActiveRoomTypes(vPricesRoomType, vPricesRoomClass, vRoomTypeRoomTypesCache);
												If vRoomTypes.Find(vCurRoomType, "RoomType") = Undefined Then
													Continue;
												EndIf;
											EndIf;
										ElsIf ValueIsFilled(vPricesRoomClass) Then
											If vPricesRoomClass <> vCurRoomClass Then
												Continue;
											EndIf;
										EndIf;
										
										// Get list of active accommodation types and check if current accommodation type is in this list
										If ValueIsFilled(vPricesAccommodationType) Then
											If Not vPricesRow.AccommodationTypeIsFolder Then
												If vPricesAccommodationType <> vCurAccommodationType Then
													Continue;
												EndIf;
											Else
												vAccommodationTypes = GetListOfActiveAccommodationTypes(vPricesAccommodationType);
												If vAccommodationTypes.Find(vCurAccommodationType, "AccommodationType") = Undefined Then
													Continue;
												EndIf;
											EndIf;
										EndIf;
										
										// Check that current service fits to the room rate service group
										If ValueIsFilled(vPricesRow.Service) Then
											If Not cmIsServiceInServiceGroup(vPricesRow.Service, vCurRoomRate.RoomRateServiceGroup) Then
												Continue;
											EndIf;
										EndIf;
										
										vPrice = vPricesRow.Price;
										vCurrency = vPricesRow.Currency;
										
										// Fill day price currency 
										If Not ValueIsFilled(vDayPriceCurrency) Then
											vDayPriceCurrency = vCurrency;
										EndIf;
										
										// Apply formulas by day types and price tags
										If vFormulasForDayTypesAndPricetags.Count() > 0 Then
											vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, vCurAccommodationType));
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, vEffPriceTag, vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, vEffPriceTag, vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", vPricesRow.Service, Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, vEffPriceTag, vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, vEffPriceTag, vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), vEffPriceTag, Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), vCurAccommodationType));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), vCurCalendarDayType, Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), vCurRoomType, Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), vCurRoomClass, Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											If vDTPTFormulas.Count() = 0 Then
												vDTPTFormulas = vFormulasForDayTypesAndPricetags.FindRows(New Structure("Service, CalendarDayType, PriceTag, RoomClass, RoomType, AccommodationType", Catalogs.Services.EmptyRef(), Catalogs.CalendarDayTypes.EmptyRef(), Catalogs.PriceTags.EmptyRef(), Catalogs.RoomTypeClasses.EmptyRef(), Catalogs.RoomTypes.EmptyRef(), Catalogs.AccommodationTypes.EmptyRef()));
											EndIf;
											
											vFound = False;
											For Each vDTPTFormulasRow In vDTPTFormulas Do
												If vCurClientType = vDTPTFormulasRow.ClientType Then
													vFound = True;
													If vDTPTFormulasRow.BracketsConstant <> 0 Or vDTPTFormulasRow.Multiplier <> 0 Or vDTPTFormulasRow.Constant <> 0 Then
														vPrice = Round((vPrice + vDTPTFormulasRow.BracketsConstant) * vDTPTFormulasRow.Multiplier + vDTPTFormulasRow.Constant, 2);
													Else
														vPrice = vPrice - Round(vPrice * (vDTPTFormulasRow.Discount / 100), 2);
													EndIf;
													Break;
												EndIf;
											EndDo;
											If Not vFound Then
												For Each vDTPTFormulasRow In vDTPTFormulas Do
													If Not ValueIsFilled(vDTPTFormulasRow.ClientType) Then
														vFound = True;
														If vDTPTFormulasRow.BracketsConstant <> 0 Or vDTPTFormulasRow.Multiplier <> 0 Or vDTPTFormulasRow.Constant <> 0 Then
															vPrice = Round((vPrice + vDTPTFormulasRow.BracketsConstant) * vDTPTFormulasRow.Multiplier + vDTPTFormulasRow.Constant, 2);
														Else
															vPrice = vPrice - Round(vPrice * (vDTPTFormulasRow.Discount / 100), 2);
														EndIf;
														Break;
													EndIf;
												EndDo;
											EndIf;
										EndIf;
										
										// Apply room rate discounts
										If vCurRoomRate.Discount <> 0 Then
											If cmIsServiceInServiceGroup(vPricesRow.Service, vCurRoomRate.DiscountServiceGroup) Then
												vPrice = vPrice - Round(vPrice * vCurRoomRate.Discount / 100, 2);
											EndIf;
										EndIf;
										
										// Apply price tag discounts
										If ValueIsFilled(vEffPriceTag) And vEffPriceTag.Discount <> 0 Then
											If cmIsServiceInServiceGroup(vPricesRow.Service, vCurRoomRate.DiscountServiceGroup) Then
												vPrice = vPrice - Round(vPrice * vEffPriceTag.Discount / 100, 2);
											EndIf;
										EndIf;
										
										// Apply calendar day type discounts
										If vCurCalendarDayType.Discount <> 0 Then
											If cmIsServiceInServiceGroup(vPricesRow.Service, vCurRoomRate.DiscountServiceGroup) Then
												vPrice = vPrice - Round(vPrice * vCurCalendarDayType.Discount / 100, 2);
											EndIf;
										EndIf;
										
										// Convert currencies if necessary
										If vDayPriceCurrency <> vCurrency Then
											vPrice = cmConvertCurrencies(vPrice, vCurrency, , vDayPriceCurrency, , vCurDate, vCurHotel);
										EndIf;
										
										// Apply room rate price rounding rule
										If vCurRoomRate.RoundPrice  And (Not ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) Or ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) And cmIsServiceInServiceGroup(vPricesRow.Service, vCurRoomRate.RoundPriceServiceGroup)) Then
											vPrice = Round(vPrice, vCurRoomRate.RoundPriceDigits);
										EndIf;
											
										// Process Is per person flag
										If vPricesRow.IsRoomRevenue Then
											If vPricesRow.IsPricePerPerson And vCurAccommodationType.NumberOfPersons4Reservation > 1 Then
												vPrice = Round(vPrice * vCurAccommodationType.NumberOfPersons4Reservation, 2);
											EndIf;
										Endif;
										
										vDayPrice = vDayPrice + vPrice;
										
										// We've found some price records
										If vPricesRow.IsRoomRevenue Then
											vPricesWereFound = True;
										EndIf;
									EndDo; // by price rows
									
									// Take room rate service package prices into account
									If ValueIsFilled(vDayPriceCurrency) Then
										For Each vServicePackagesItem In vServicePackages Do
											vCurServicePackage = vServicePackagesItem.Value;
											
											// Check service package is valid period
											If vCurDate < vCurServicePackage.DateValidFrom Or ValueIsFilled(vCurServicePackage.DateValidTo) And vCurDate > vCurServicePackage.DateValidTo Then
												Continue;
											EndIf;
											
											// Get service package services
											vCurServicePackageServices = New Array();
											vCurServicePackageServicesByDate = New Array();
											vServicePackagesCacheRow = vServicePackagesCache.Find(vCurServicePackage, "ServicePackage");
											If vServicePackagesCacheRow <> Undefined Then
												vCurServicePackageServices = vServicePackagesCacheRow.Services.FindRows(New Structure("ClientType, IsInPrice, AccountingDayNumber, AccountingDate", vCurClientType, True, 0, '00010101'));
												vCurServicePackageServicesByDate = vServicePackagesCacheRow.Services.FindRows(New Structure("ClientType, AccountingDayNumber, AccountingDate", vCurClientType, True, 0, vCurDate));
											EndIf;
											
											For Each vSPRow In vCurServicePackageServices Do
												// Check current calendar day type
												If ValueIsFilled(vSPRow.CalendarDayType) And vCurCalendarDayType <> vSPRow.CalendarDayType Then
													Continue;
												EndIf;
												
												// Check current room type
												If ValueIsFilled(vSPRow.RoomType) And vCurRoomType <> vSPRow.RoomType Then
													Continue;
												EndIf;
												If ValueIsFilled(vSPRow.RoomClass) And vCurRoomClass <> vSPRow.RoomClass Then
													Continue;
												EndIf;
												
												// Check current accommodation type
												If ValueIsFilled(vSPRow.AccommodationType) And vCurAccommodationType <> vSPRow.AccommodationType Then
													Continue;
												EndIf;
												
												vPrice = vSPRow.Price * ?(vSPRow.Quantity > 0, vSPRow.Quantity, 1);
												vCurrency = vSPRow.Currency;
												
												// Convert currencies if necessary
												If vDayPriceCurrency <> vCurrency Then
													vPrice = cmConvertCurrencies(vPrice, vCurrency, , vDayPriceCurrency, , vCurDate, vCurHotel);
												EndIf;
												
												// Apply room rate price rounding rule
												If vCurRoomRate.RoundPrice And (Not ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) Or ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) And cmIsServiceInServiceGroup(vSPRow.Service, vCurRoomRate.RoundPriceServiceGroup)) Then
													vPrice = Round(vPrice, vCurRoomRate.RoundPriceDigits);
												EndIf;
												
												vDayPrice = vDayPrice + vPrice;
											EndDo; // by service package services

											For Each vSPRow In vCurServicePackageServicesByDate Do
												// Check current room type
												If ValueIsFilled(vSPRow.RoomType) And vCurRoomType <> vSPRow.RoomType Then
													Continue;
												EndIf;
												If ValueIsFilled(vSPRow.RoomClass) And vCurRoomClass <> vSPRow.RoomClass Then
													Continue;
												EndIf;
												
												// Check current accommodation type
												If ValueIsFilled(vSPRow.AccommodationType) And vCurAccommodationType <> vSPRow.AccommodationType Then
													Continue;
												EndIf;
												
												vPrice = vSPRow.Price * ?(vSPRow.Quantity > 0, vSPRow.Quantity, 1);
												vCurrency = vSPRow.Currency;
												
												// Convert currencies if necessary
												If vDayPriceCurrency <> vCurrency Then
													vPrice = cmConvertCurrencies(vPrice, vCurrency, , vDayPriceCurrency, , vCurDate, vCurHotel);
												EndIf;
												
												// Apply room rate price rounding rule
												If vCurRoomRate.RoundPrice And (Not ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) Or ValueIsFilled(vCurRoomRate.RoundPriceServiceGroup) And cmIsServiceInServiceGroup(vSPRow.Service, vCurRoomRate.RoundPriceServiceGroup)) Then
													vPrice = Round(vPrice, vCurRoomRate.RoundPriceDigits);
												EndIf;
												
												vDayPrice = vDayPrice + vPrice;
											EndDo; // by service package services for this accounting date
										EndDo; // by service packages
									EndIf;
											
									// Add detailed record to the register
									If ValueIsFilled(vDayPriceCurrency) And vPricesWereFound Then
										vDayPriceRec = vRoomRateDailyPricesRecordSet.Add();
										vDayPriceRec.Period = vCurDate;
										
										vDayPriceRec.Hotel = vCurHotel;
										vDayPriceRec.RoomRate = vCurRoomRate;
										vDayPriceRec.ClientType = vCurClientType;
										vDayPriceRec.PriceTag = vCurPriceTag;
										vDayPriceRec.RoomType = vCurRoomType;
										vDayPriceRec.AccommodationType = vCurAccommodationType;
										
										vDayPriceRec.Price = vDayPrice;
										vDayPriceRec.Currency = vDayPriceCurrency;
										vDayPriceRec.CalendarDayType = vCurCalendarDayType;
										
										vDayPriceRec.Timestamp = CurrentSessionDate();
									EndIf;
								EndDo; // by client types
							EndDo; // by accommodation types
						EndDo; // by set room rate prices document
					Else
						vWarningMessage = NStr("en='No calendar day type found: ';ru='Не найден тип дня календаря: ';de='No calendar day type found: '") + vCurRoomRate + " - " + Format(vCurDate, "DF=dd.MM.yyyy");
						WriteLogEvent(NStr("en='DataProcessor.FillRoomRateDailyPrices';ru='Обработка.ЗаполнениеЦенТарифовПоДням';de='DataProcessor.FillRoomRateDailyPrices'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vWarningMessage);
						If pIsInteractive Then
							tcCommonFunctionOnClientServer.TextMessage(vWarningMessage, MessageStatus.Attention);
						EndIf;
					EndIf;
					
					// Write records to the database
					If ValueIsFilled(RoomType) Then
						vRoomRateDailyPricesRecordSet.Write(True);
					EndIf;
				EndDo; // by room types
				
				// Write records to the database
				If Not ValueIsFilled(RoomType) Then
					vRoomRateDailyPricesRecordSet.Write(True);
				EndIf;
				
				vCurDate = vCurDate + (24*3600);
			EndDo; // by days
		Else
			// Clear all records for formulas rate
			vRoomRateDailyPricesToDeleteRecordSet.Filter.Reset();
			vRoomRateDailyPricesToDeleteRecordSet.Filter.RoomRate.Set(vCurRoomRate);
			If ValueIsFilled(Hotel) Then
				vRoomRateDailyPricesToDeleteRecordSet.Filter.Hotel.Set(Hotel);
			EndIf;
			
			// Clear all records by given filters
			vRoomRateDailyPricesToDeleteRecordSet.Write(True);
		EndIf;
	EndDo; // by room rates
	
	// Log end of processing
	WriteLogEvent(NStr("en='DataProcessor.FillRoomRateDailyPrices';ru='Обработка.ЗаполнениеЦенТарифовПоДням';de='DataProcessor.FillRoomRateDailyPrices'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
EndProcedure // pmDoFill     

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetListOfActiveRoomRates()
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
EndFunction // GetListOfActiveRoomRates

// -----------------------------------------------------------------------------
Function GetActiveSetRoomRatePrices(pRoomRate, pCalendarDayTypesList, pPeriod, pHotel)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomRatesSliceLast.SetRoomRatePrices AS SetRoomRatePrices,
	|	RoomRatesSliceLast.Hotel AS Hotel,
	|	RoomRatesSliceLast.RoomRate AS RoomRate,
	|	RoomRatesSliceLast.CalendarDayType AS CalendarDayType,
	|	RoomRatesSliceLast.PriceTag AS PriceTag
	|FROM
	|	InformationRegister.RoomRates.SliceLast(
	|			&qPeriod,
	|			RoomRate = &qRoomRate
	|				AND CalendarDayType IN (&qCalendarDayTypesList)
	|				AND Hotel = &qHotel
	|				AND NOT IsFormula) AS RoomRatesSliceLast
	|
	|ORDER BY
	|	RoomRatesSliceLast.RoomRate.SortCode,
	|	RoomRatesSliceLast.CalendarDayType.SortCode";
	vQry.SetParameter("qRoomRate", pRoomRate);
	vQry.SetParameter("qCalendarDayTypesList", pCalendarDayTypesList);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qPeriod", ?(ValueIsFilled(pPeriod), pPeriod, '39991231'));
	
	Return vQry.Execute().Unload();
EndFunction // GetActiveSetRoomRatePrices

// -----------------------------------------------------------------------------
Function GetListOfActiveRoomTypes(pRoomType = Undefined, pRoomClass = Undefined, pRoomTypeRoomTypesCache)
	If pRoomTypeRoomTypesCache = Undefined Then
		pRoomTypeRoomTypesCache = New ValueTable();
		pRoomTypeRoomTypesCache.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
		pRoomTypeRoomTypesCache.Columns.Add("RoomClass", cmGetCatalogTypeDescription("RoomTypeClasses"));
		pRoomTypeRoomTypesCache.Columns.Add("RoomTypes");
	EndIf;
	vRoomTypeRoomTypesCacheRows = pRoomTypeRoomTypesCache.FindRows(New Structure("RoomType, RoomClass", pRoomType, pRoomClass));
	If vRoomTypeRoomTypesCacheRows.Count() = 0 Then
		vRoomTypes = New ValueTable();
		If ValueIsFilled(pRoomType) Then
			If pRoomType.IsFolder Then
				vRoomTypes = cmGetAllRoomTypes(Hotel, pRoomType, pRoomClass);
			Else
				vRoomTypes.Columns.Add("RoomType", cmGetCatalogTypeDescription("RoomTypes"));
				vRoomTypes.Columns.Add("RoomClass", cmGetCatalogTypeDescription("RoomTypeClasses"));
				vRoomTypes.Columns.Add("IsVirtual", cmGetBooleanTypeDescription());
				
				vRow = vRoomTypes.Add();
				vRow.RoomType = pRoomType;
				vRow.RoomClass = pRoomType.RoomClass;
				vRow.IsVirtual = pRoomType.IsVirtual;
			EndIf;
		ElsIf ValueIsFilled(pRoomClass) Then
			vRoomTypes = cmGetAllRoomTypes(Hotel, , pRoomClass);
		Else
			vRoomTypes = cmGetAllRoomTypes(Hotel);
		EndIf;

		vRoomTypeRoomTypesCacheRow = pRoomTypeRoomTypesCache.Add();
		vRoomTypeRoomTypesCacheRow.RoomType = pRoomType;
		vRoomTypeRoomTypesCacheRow.RoomClass = pRoomClass;
		vRoomTypeRoomTypesCacheRow.RoomTypes = vRoomTypes;
	Else
		vRoomTypeRoomTypesCacheRow = vRoomTypeRoomTypesCacheRows.Get(0);
		vRoomTypes = vRoomTypeRoomTypesCacheRow.RoomTypes;
	EndIf;
	Return vRoomTypes;
EndFunction // GetListOfActiveRoomTypes

// -----------------------------------------------------------------------------
Function GetListOfActiveAccommodationTypes(pAccommodationType)
	vAccommodationTypes = New ValueTable();
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
	Return vAccommodationTypes;
EndFunction // GetListOfActiveAccommodationTypes

// -----------------------------------------------------------------------------
Function GetEffectivePrices(pRoomRate, pSetRoomRatePrices, pPriceCalculationDate, pAccountingDate)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	AccommodationTypeFormulas.Ref.RoomRate AS RoomRate,
	|	AccommodationTypeFormulas.Ref.Hotel AS Hotel,
	|	AccommodationTypeFormulas.Ref AS SetRoomRatePrices,
	|	AccommodationTypeFormulas.Ref.CalendarDayType AS CalendarDayType,
	|	AccommodationTypeFormulas.Ref.PriceTag AS PriceTag,
	|	AccommodationTypeFormulas.ClientType AS ClientType,
	|	AccommodationTypeFormulas.Service AS Service,
	|	AccommodationTypeFormulas.RoomClass AS RoomClass,
	|	AccommodationTypeFormulas.RoomType AS RoomType,
	|	AccommodationTypeFormulas.AccommodationType AS AccommodationType,
	|	AccommodationTypeFormulas.Multiplier AS Multiplier,
	|	AccommodationTypeFormulas.BracketsConstant AS BracketsConstant,
	|	AccommodationTypeFormulas.Constant AS Constant,
	|	AccommodationTypeFormulas.LineNumber AS LineNumber,
	|	AccommodationTypeFormulas.LineNumber AS SortCode
	|INTO RateAccommodationTypeFormulas
	|FROM
	|	Document.SetRoomRatePrices.Formulas AS AccommodationTypeFormulas
	|WHERE
	|	AccommodationTypeFormulas.Ref = &qOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RateServices.Ref AS Service,
	|	RateServices.QuantityCalculationRule AS QuantityCalculationRule,
	|	RateServices.QuantityCalculationRule.QuantityCalculationRuleType AS QuantityCalculationRuleType,
	|	RateServices.IsRoomRevenue AS IsRoomRevenue,
	|	RateServices.IsInPrice AS IsInPrice,
	|	RateServices.ChargePerPerson AS ChargePerPerson,
	|	RateServices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
	|	RateServices.Unit AS Unit,
	|	RateServices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
	|INTO RateServices
	|FROM
	|	Catalog.Services AS RateServices
	|WHERE
	|	RateServices.Ref = &qAccommodationService
	|	AND NOT RateServices.IsFolder
	|	AND NOT RateServices.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RateServices.Service AS Service,
	|	RateServices.QuantityCalculationRule AS QuantityCalculationRule,
	|	RateServices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
	|	RateServices.IsRoomRevenue AS IsRoomRevenue,
	|	RateServices.IsInPrice AS IsInPrice,
	|	RateServices.ChargePerPerson AS ChargePerPerson,
	|	RateServices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
	|	RateServices.Unit AS Unit,
	|	RateServices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly,
	|	RoomTypePricesByDates.RoomType AS RoomType,
	|	RoomTypePricesByDates.AccountingDate AS AccountingDate,
	|	RoomTypePricesByDates.CalendarDayType AS CalendarDayType,
	|	RoomTypePricesByDates.PriceTag AS PriceTag,
	|	RoomTypePricesByDates.RoomPrice AS Price,
	|	RoomTypePricesByDates.RoomPriceCurrency AS Currency
	|INTO RoomTypePricesByDates
	|FROM
	|	(SELECT DISTINCT
	|		DaysByRoomTypes.RoomType AS RoomType,
	|		DaysByRoomTypes.AccountingDate AS AccountingDate,
	|		DaysByRoomTypes.CalendarDayType AS CalendarDayType,
	|		DaysByRoomTypes.PriceTag AS PriceTag,
	|		DaysByRoomTypes.RoomPrice AS RoomPrice,
	|		DaysByRoomTypes.RoomPriceCurrency AS RoomPriceCurrency
	|	FROM
	|		(SELECT
	|			RoomTypes.Ref AS RoomType,
	|			CalendarDays.AccountingDate AS AccountingDate,
	|			CASE
	|				WHEN CalendarDaysByRoomTypes.CalendarDayType IS NULL
	|					THEN CalendarDays.CalendarDayType
	|				WHEN CalendarDaysByRoomTypes.CalendarDayType = VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|					THEN CalendarDays.CalendarDayType
	|				ELSE CalendarDaysByRoomTypes.CalendarDayType
	|			END AS CalendarDayType,
	|			CASE
	|				WHEN CalendarDaysByRoomTypes.PriceTag IS NULL
	|					THEN CalendarDays.PriceTag
	|				WHEN CalendarDaysByRoomTypes.PriceTag = VALUE(Catalog.PriceTags.EmptyRef)
	|					THEN CalendarDays.PriceTag
	|				ELSE CalendarDaysByRoomTypes.PriceTag
	|			END AS PriceTag,
	|			CASE
	|				WHEN CalendarDaysByRoomTypes.RoomPrice IS NULL
	|					THEN CalendarDays.RoomPrice
	|				WHEN CalendarDaysByRoomTypes.RoomPrice = 0
	|					THEN CalendarDays.RoomPrice
	|				ELSE CalendarDaysByRoomTypes.RoomPrice
	|			END AS RoomPrice,
	|			CASE
	|				WHEN CalendarDaysByRoomTypes.RoomPriceCurrency IS NULL
	|					THEN CalendarDays.RoomPriceCurrency
	|				WHEN CalendarDaysByRoomTypes.RoomPriceCurrency = VALUE(Catalog.Currencies.EmptyRef)
	|					THEN CalendarDays.RoomPriceCurrency
	|				ELSE CalendarDaysByRoomTypes.RoomPriceCurrency
	|			END AS RoomPriceCurrency
	|		FROM
	|			InformationRegister.CalendarDays.SliceLast(
	|					&qPriceCalculationDate,
	|					Calendar = &qCalendar
	|						AND AccountingDate = &qAccountingDate) AS CalendarDays
	|				LEFT JOIN Catalog.RoomTypes AS RoomTypes
	|				ON (RoomTypes.Owner = &qHotel)
	|					AND (NOT RoomTypes.IsFolder)
	|					AND (NOT RoomTypes.DeletionMark)
	|				LEFT JOIN InformationRegister.CalendarDaysByRoomTypes.SliceLast(
	|						&qPriceCalculationDate,
	|						AccountingDate = &qAccountingDate
	|							AND Calendar = &qCalendar) AS CalendarDaysByRoomTypes
	|				ON CalendarDays.AccountingDate = CalendarDaysByRoomTypes.AccountingDate
	|					AND (RoomTypes.Ref = CalendarDaysByRoomTypes.RoomType)) AS DaysByRoomTypes) AS RoomTypePricesByDates
	|		LEFT JOIN RateServices AS RateServices
	|		ON (TRUE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RawRoomRatePrices.AccountingDate AS AccountingDate,
	|	RateAccommodationTypeFormulas.RoomRate AS RoomRate,
	|	CASE
	|		WHEN RawRoomRatePrices.CalendarDayType <> VALUE(Catalog.CalendarDayTypes.EmptyRef)
	|			THEN RawRoomRatePrices.CalendarDayType
	|		ELSE RateAccommodationTypeFormulas.CalendarDayType
	|	END AS CalendarDayType,
	|	CASE
	|		WHEN RawRoomRatePrices.PriceTag <> VALUE(Catalog.PriceTags.EmptyRef)
	|			THEN RawRoomRatePrices.PriceTag
	|		ELSE RateAccommodationTypeFormulas.PriceTag
	|	END AS PriceTag,
	|	RateAccommodationTypeFormulas.ClientType AS ClientType,
	|	RawRoomRatePrices.RoomType AS RoomType,
	|	CASE
	|		WHEN RawRoomRatePrices.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|			THEN 99999999
	|		ELSE RawRoomRatePrices.RoomType.SortCode
	|	END AS RoomTypeSortCode,
	|	RawRoomRatePrices.RoomType.IsFolder AS RoomTypeIsFolder,
	|	RawRoomRatePrices.RoomType.RoomClass AS RoomClass,
	|	CASE
	|		WHEN RawRoomRatePrices.RoomType.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef)
	|			THEN 99999999
	|		ELSE RawRoomRatePrices.RoomType.RoomClass.SortCode
	|	END AS RoomClassSortCode,
	|	RateAccommodationTypeFormulas.AccommodationType AS AccommodationType,
	|	CASE
	|		WHEN RateAccommodationTypeFormulas.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef)
	|			THEN 99999999
	|		ELSE RateAccommodationTypeFormulas.AccommodationType.SortCode
	|	END AS AccommodationTypeSortCode,
	|	RateAccommodationTypeFormulas.AccommodationType.IsFolder AS AccommodationTypeIsFolder,
	|	RateAccommodationTypeFormulas.SetRoomRatePrices AS SetRoomRatePrices,
	|	RateAccommodationTypeFormulas.SortCode AS SortCode,
	|	RateAccommodationTypeFormulas.LineNumber AS LineNumber,
	|	RateAccommodationTypeFormulas.Hotel AS Hotel,
	|	RawRoomRatePrices.Service AS Service,
	|	CASE
	|		WHEN RawRoomRatePrices.Service = VALUE(Catalog.Services.EmptyRef)
	|			THEN 99999999
	|		ELSE RawRoomRatePrices.Service.SortCode
	|	END AS ServiceSortCode,
	|	(RawRoomRatePrices.Price + ISNULL(RateAccommodationTypeFormulas.BracketsConstant, 0)) * ISNULL(RateAccommodationTypeFormulas.Multiplier, 0) + ISNULL(RateAccommodationTypeFormulas.Constant, 0) AS Price,
	|	RawRoomRatePrices.Currency AS Currency,
	|	0 AS MinimumQuantity,
	|	ISNULL(ServicePrices.VATRate, RateAccommodationTypeFormulas.Hotel.Company.VATRate) AS VATRate,
	|	RawRoomRatePrices.QuantityCalculationRule AS QuantityCalculationRule,
	|	RawRoomRatePrices.QuantityCalculationRuleType AS QuantityCalculationRuleType,
	|	RawRoomRatePrices.IsRoomRevenue AS IsRoomRevenue,
	|	RawRoomRatePrices.IsInPrice AS IsInPrice,
	|	RawRoomRatePrices.ChargePerPerson AS IsPricePerPerson,
	|	RawRoomRatePrices.ChargeToEachGuestSeparately AS ChargeToEachGuestSeparately,
	|	RawRoomRatePrices.Unit AS Unit,
	|	RawRoomRatePrices.RoomRevenueAmountsOnly AS RoomRevenueAmountsOnly
	|FROM
	|	RoomTypePricesByDates AS RawRoomRatePrices
	|		LEFT JOIN RateAccommodationTypeFormulas AS RateAccommodationTypeFormulas
	|		ON (RawRoomRatePrices.Service = RateAccommodationTypeFormulas.Service
	|				OR RateAccommodationTypeFormulas.Service = VALUE(Catalog.Services.EmptyRef))
	|			AND (RawRoomRatePrices.RoomType = RateAccommodationTypeFormulas.RoomType
	|					AND RateAccommodationTypeFormulas.RoomType <> VALUE(Catalog.RoomTypes.EmptyRef)
	|				OR RawRoomRatePrices.RoomType.RoomClass = RateAccommodationTypeFormulas.RoomClass
	|					AND RateAccommodationTypeFormulas.RoomClass <> VALUE(Catalog.RoomTypeClasses.EmptyRef)
	|				OR RateAccommodationTypeFormulas.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|					AND RateAccommodationTypeFormulas.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef))
	|		LEFT JOIN InformationRegister.ServicePrices.SliceLast(
	|				&qPriceCalculationDate,
	|				Service = &qAccommodationService
	|					AND Hotel = &qHotel) AS ServicePrices
	|		ON RawRoomRatePrices.Service = ServicePrices.Service
	|			AND (RateAccommodationTypeFormulas.ClientType = ServicePrices.ClientType)
	|
	|ORDER BY
	|	RateAccommodationTypeFormulas.SortCode";
	vQry.SetParameter("qRoomRate", pRoomRate);
	vQry.SetParameter("qCalendar", pRoomRate.Calendar);
	vQry.SetParameter("qAccommodationService", pRoomRate.AccommodationService);
	vQry.SetParameter("qOrder", pSetRoomRatePrices);
	vQry.SetParameter("qHotel", pSetRoomRatePrices.Hotel);
	vQry.SetParameter("qPriceCalculationDate", pPriceCalculationDate);
	vQry.SetParameter("qAccountingDate", pAccountingDate);
	vPrices = vQry.Execute().Unload();
	Return vPrices;
EndFunction // GetEffectivePrices

// -----------------------------------------------------------------------------
Function GetDocumentPrices(pPricesDoc)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SetRoomRatePricesPrices.Ref AS Ref,
	|	SetRoomRatePricesPrices.LineNumber AS LineNumber,
	|	SetRoomRatePricesPrices.ClientType AS ClientType,
	|	SetRoomRatePricesPrices.Service AS Service,
	|	CASE
	|		WHEN SetRoomRatePricesPrices.Service = VALUE(Catalog.Services.EmptyRef)
	|			THEN 99999999
	|		ELSE SetRoomRatePricesPrices.Service.SortCode
	|	END AS ServiceSortCode,
	|	SetRoomRatePricesPrices.RoomClass AS RoomClass,
	|	CASE
	|		WHEN SetRoomRatePricesPrices.RoomClass = VALUE(Catalog.RoomTypeClasses.EmptyRef)
	|			THEN 99999999
	|		ELSE SetRoomRatePricesPrices.RoomClass.SortCode
	|	END AS RoomClassSortCode,
	|	SetRoomRatePricesPrices.RoomType AS RoomType,
	|	CASE
	|		WHEN SetRoomRatePricesPrices.RoomType = VALUE(Catalog.RoomTypes.EmptyRef)
	|			THEN 99999999
	|		ELSE SetRoomRatePricesPrices.RoomType.SortCode
	|	END AS RoomTypeSortCode,
	|	SetRoomRatePricesPrices.RoomType.IsFolder AS RoomTypeIsFolder,
	|	SetRoomRatePricesPrices.AccommodationType AS AccommodationType,
	|	CASE
	|		WHEN SetRoomRatePricesPrices.AccommodationType = VALUE(Catalog.AccommodationTypes.EmptyRef)
	|			THEN 99999999
	|		ELSE SetRoomRatePricesPrices.AccommodationType.SortCode
	|	END AS AccommodationTypeSortCode,
	|	SetRoomRatePricesPrices.AccommodationType.IsFolder AS AccommodationTypeIsFolder,
	|	SetRoomRatePricesPrices.Price AS Price,
	|	SetRoomRatePricesPrices.Currency AS Currency,
	|	SetRoomRatePricesPrices.MinimumQuantity AS MinimumQuantity,
	|	SetRoomRatePricesPrices.VATRate AS VATRate,
	|	SetRoomRatePricesPrices.QuantityCalculationRule AS QuantityCalculationRule,
	|	SetRoomRatePricesPrices.IsRoomRevenue AS IsRoomRevenue,
	|	SetRoomRatePricesPrices.IsInPrice AS IsInPrice,
	|	SetRoomRatePricesPrices.IsPricePerPerson AS IsPricePerPerson
	|FROM
	|	Document.SetRoomRatePrices.Prices AS SetRoomRatePricesPrices
	|WHERE
	|	SetRoomRatePricesPrices.Ref = &qRef
	|
	|ORDER BY
	|	IsRoomRevenue DESC,
	|	IsInPrice DESC,
	|	ServiceSortCode,
	|	RoomClassSortCode,
	|	RoomTypeSortCode,
	|	AccommodationTypeSortCode";
	vQry.SetParameter("qRef", pPricesDoc);
	vPrices = vQry.Execute().Unload();
	Return vPrices;
EndFunction // GetDocumentPrices

// -----------------------------------------------------------------------------
Function PostprocessPrices(pPrices, Val pDocPrices, Val pFormulas) 
	// Create working value table and add sort columns to it
	vPrices = pPrices;
	// Process accommodation type formulas
	If pFormulas.Count() > 0 Then
		j = 0;
		vPricesCount = vPrices.Count();
		While j < vPricesCount Do
			vRow = vPrices.Get(j);
			vRowClientType = vRow.ClientType;
			vRowRoomType = vRow.RoomType;
			vRowRoomClass = vRow.RoomClass;
			vRowAccommodationType = vRow.AccommodationType;
			vFormulasHasRowsByClientType = ?(pFormulas.Find(vRowClientType, "ClientType") = Undefined, False, True);
			If ValueIsFilled(vRowAccommodationType) And Not vRowAccommodationType.IsFolder Then
				i = pFormulas.Count() - 1;
				While i >= 0 Do
					vFormulaRow = pFormulas.Get(i);
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
						vPricesRows = pDocPrices.FindRows(New Structure("Service, RoomClass, RoomType, AccommodationType, ClientType", vRow.Service, vRow.RoomClass, vRow.RoomType, vFormulaRow.AccommodationType, vRow.ClientType));
						If vPricesRows.Count() > 0 Then
							vSkipRow = True;
						EndIf;
						If Not vSkipRow Then
							vPricesRow = vPrices.Add();
							FillPropertyValues(vPricesRow, vRow, , "LineNumber");
							
							vPricesRow.Price = Round((vPricesRow.Price + vFormulaRow.BracketsConstant) * vFormulaRow.Multiplier + vFormulaRow.Constant, 2);
							
							vFormulaRowAccommodationType = vFormulaRow.AccommodationType;
							vPricesRow.AccommodationType = vFormulaRowAccommodationType; 
							If ValueIsFilled(vFormulaRowAccommodationType) Then
								vPricesRow.AccommodationTypeSortCode = vFormulaRowAccommodationType.SortCode;
								vPricesRow.AccommodationTypeIsFolder = vFormulaRowAccommodationType.IsFolder;
							Else
								vPricesRow.AccommodationTypeSortCode = cmGetMaxSortCodeValue();
								vPricesRow.AccommodationTypeIsFolder = False;
							EndIf;
							
							If Not ValueIsFilled(vRowRoomType) And Not ValueIsFilled(vRowRoomClass) And ValueIsFilled(vFormulaRow.RoomType) And Not ValueIsFilled(vFormulaRow.RoomClass) Then
								vFormulaRowRoomType = vFormulaRow.RoomType;
								vPricesRow.RoomType = vFormulaRowRoomType;
								If ValueIsFilled(vFormulaRowRoomType) Then
									vPricesRow.RoomTypeSortCode = vFormulaRowRoomType.SortCode;
									vPricesRow.RoomTypeIsFolder = vFormulaRowRoomType.IsFolder;
								Else
									vPricesRow.RoomTypeSortCode = cmGetMaxSortCodeValue();
									vPricesRow.RoomTypeIsFolder = False;
								EndIf;
							EndIf;	
						EndIf;
					EndIf;
					i = i - 1;
				EndDo;
			EndIf;
			j = j + 1;
		EndDo;			
	EndIf;
	// Sort by sort columns
	vPrices.Sort("IsRoomRevenue Desc, IsInPrice Desc, ServiceSortCode, RoomClassSortCode, RoomTypeSortCode, AccommodationTypeSortCode");
	// Return resulting table
	Return vPrices;
EndFunction // PostprocessPrices

#EndRegion
