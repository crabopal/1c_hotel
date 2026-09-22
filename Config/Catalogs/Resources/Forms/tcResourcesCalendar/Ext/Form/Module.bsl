
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);

	// Initialization
	OnOpenMode = True;
	PeriodCalendar = CurrentSessionDate();
	Hotel = SessionParameters.CurrentHotel;
	Items.TodayPeriod.Title = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");
	
	// Open parameters
	If Parameters.Property("SelGuestGroup") And ValueIsFilled(Parameters.SelGuestGroup) Then
		GuestGroup = Parameters.SelGuestGroup;
		Hotel = GuestGroup.Owner;
	EndIf;
	If Parameters.Property("SelDateFrom") And ValueIsFilled(Parameters.SelDateFrom) Then
		PeriodCalendar = Parameters.SelDateFrom;
	EndIf;
	
	// Restore some settings
	ResourcesAreVertical = False;
	vResourcesAreVertical = SystemSettingsStorage.Load("tcResourcesCalendar_ResourcesAreVertical", SessionParameters.CurrentUser);
	If vResourcesAreVertical <> Undefined And TypeOf(vResourcesAreVertical) = Type("Boolean") Then
		ResourcesAreVertical = vResourcesAreVertical;
	EndIf;
	
	ResourcePlannerScale = 2;
	vResourcePlannerScale = SystemSettingsStorage.Load("tcResourcesCalendar_ResourcePlannerScale", SessionParameters.CurrentUser);
	If vResourcePlannerScale <> Undefined And TypeOf(vResourcePlannerScale) = Type("Number") Then
		ResourcePlannerScale = vResourcePlannerScale;
	EndIf;

	ResourcePlanner.FixDimensionsHeader = True;
	ResourcePlanner.FixTimeScaleHeader = True;
	ResourcePlanner.ItemsBehaviorWhenSpaceInsufficient = PlannerItemsBehaviorWhenSpaceInsufficient.ShowAllItems;
	
	SelAskForResourcesFilterByDefault = True;
	If ValueisFilled(Hotel) Then
		SelAskForResourcesFilterByDefault = Hotel.AskForResourcesFilterByDefault;
	EndIf;
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	If SelAskForResourcesFilterByDefault Then
		OnOpenMode = False;
	EndIf;
	
	// Set defaults group title
	SetDefaultsGroupTitle();
	
	// Fill list of all resource reservation statuses
	GetAllResourceReservationStatuses();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If OnOpenMode Then
		AttachIdleHandler("ShowPlanner", 1, True);
	Else
		UpdatePlanner();
	EndIf;
	If tcOnClient.IsHomePageWindow(ThisObject) Then
		vPrefix = NStr("en = 'Resources calendar: '; de = 'Ressourcenkalender: '; ru = 'Календарь ресурсов: '");
		tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "System.Hotel.Changed" And pParameter <> Hotel Then
		If ValueIsFilled(pParameter) Then
			Hotel = pParameter;
			Items.PeriodCalendar.Refresh();
			UpdatePlanner();
			If tcOnClient.IsHomePageWindow(ThisObject) Then
				vPrefix = NStr("en = 'Resources calendar: '; de = 'Ressourcenkalender: '; ru = 'Календарь ресурсов: '");
				tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
			EndIf;
		EndIf;
	ElsIf pEventName = "Document.ResourceReservation.Write" Then
		Items.PeriodCalendar.Refresh();
		UpdatePlanner();
	ElsIf pEventName = "SetGroupAndDateInResourcesCalendar" And TypeOf(pParameter) = Type("Structure") And 
	      pParameter.Property("SelGuestGroup") And ValueIsFilled(pParameter.SelGuestGroup) And 
		  pParameter.Property("SelDateFrom") And ValueIsFilled(pParameter.SelDateFrom) Then
		GuestGroup = pParameter.SelGuestGroup;
		Hotel = tcOnServer.cmGetAttributeByRef(GuestGroup, "Owner");
		PeriodCalendar = pParameter.SelDateFrom;
		Items.PeriodCalendar.Refresh();
		UpdatePlanner();
		If tcOnClient.IsHomePageWindow(ThisObject) Then
			vPrefix = NStr("en = 'Resources calendar: '; de = 'Ressourcenkalender: '; ru = 'Календарь ресурсов: '");
			tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
		EndIf;
		// Set defaults group title
		SetDefaultsGroupTitle();
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerScaleOnChange(pItem)
	Items.GroupPeriod.Hide();
	PrepareResourcePlanner();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PeriodCalendarOnActivateDate(pItem)
	Items.GroupPeriod.Hide();
	PrepareResourcePlanner();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourceStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure();
	vFilter	= New Structure();	
	vParams.Insert("ChoiseMode", True);
	If ValueIsFilled(Hotel) Then
		vFilter.Insert("Hotel", Hotel);
	EndIf;
	If ValueIsFilled(ResourceType) Then
		vFilter.Insert("Owner", ResourceType);		
	EndIf;
	vParams.Insert("Filter", vFilter);
	OpenForm("Catalog.Resources.ChoiceForm", vParams, pItem); 
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourceTypeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure();
	vFilter	= New Structure();	
	vParams.Insert("ChoiseMode", True);
	If ValueIsFilled(Hotel) Then
		vFilter.Insert("Hotel", Hotel);
	EndIf;
	vParams.Insert("Filter", vFilter);
	OpenForm("Catalog.ResourceTypes.ChoiceForm", vParams, pItem);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourceTypeOnChange(pItem)
	Items.PeriodCalendar.Refresh();
	UpdatePlanner();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourceOnChange(pItem)
	Items.PeriodCalendar.Refresh();
	UpdatePlanner();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(pItem)
	GuestGroup = Undefined;
	Items.PeriodCalendar.Refresh();
	UpdatePlanner();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupOnChange(pItem)
	SetDefaultsGroupTitle();
EndProcedure // GuestGroupOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure PeriodCalendarOnPeriodOutput(pItem, pPeriodAppearance)
	vColors = GetColorsForCalendar(pPeriodAppearance.BeginOfPeriod, pPeriodAppearance.EndOfPeriod, Hotel, ResourceType, Resource);
	For Each vDate In pPeriodAppearance.Dates Do
		For Each vColor In vColors Do 
			If vDate.Date >= BegOfDay(vColor.DateTimeFrom) And vDate.Date <= EndOfDay(vColor.DateTimeTo) Then
				vDate.BackColor = vColor.Color;	
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerBeforeStartQuickEdit(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerBeforeStartEdit(pItem, pNewItem, pStandardProcessing)
	pStandardProcessing = True;
EndProcedure // ResourcePlannerBeforeStartEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerSelection(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If pItem.SelectedItems.Count() > 0 Then 
		vResourceReservationRef = pItem.SelectedItems[0].Value;
		OpenForm("Document.ResourceReservation.ObjectForm", New Structure("Key", vResourceReservationRef), ThisObject, vResourceReservationRef);
	EndIf;	
EndProcedure // ResourcePlannerSelection

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerBeforeCreate(pItem, pBegin, pEnd, pValues, pText, pStandardProcessing)
	pStandardProcessing = False;
	// This is one click over empty period
	If ResourcePlannerScale = 2 And (pEnd - pBegin) = 3600 Then
		Return;
	ElsIf ResourcePlannerScale = 1 And (pEnd - pBegin) = (6 * 3600) Then
		Return;
	ElsIf ResourcePlannerScale = 0 And (pEnd - pBegin) = (24 * 3600) Then
		Return;
	EndIf;
	If pBegin + 3600 <= pEnd And (pValues.Count() > 0 And ValueIsFilled(pValues["Resources"]) Or ResourcePlannerScale = 0) Then
		vResource = pValues["Resources"];
		If Not ValueIsFilled(vResource) And ValueIsFilled(Resource) Then
			vResource = Resource;
		EndIf;	
		Params = New Structure("DateTimeFrom, DateTimeTo, Hotel, Resource, FillingValues, GuestGroup, EventActivity");
		Params.DateTimeFrom = pBegin;
		Params.DateTimeTo = pEnd;
		Params.Hotel = Hotel;
		Params.Resource = vResource;
		Params.GuestGroup = GuestGroup;
		Params.FillingValues = New Structure("NotDefaultValues", True);
		// Check if event activities are filled
		If EventActivitiesAvailableAtServer() Then
			OpenForm("Catalog.EventActivities.ChoiceForm", , ThisObject, , , , New NotifyDescription("OpenNewResourceReservationForm", ThisObject), FormWindowOpeningMode.LockWholeInterface);
		Else
			OpenForm("Document.ResourceReservation.ObjectForm", Params, ThisObject);
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerCommandGenerateProcessing(pItem, pParameters, pCommands, pDefaultCommand)
	#If Not ThickClientOrdinaryApplication Then
		//vCode = 
		vNum = 0;
		For Each vCommand In pCommands Do
			If vCommand.Command = PlannerStandardCommand.DeleteItems Then
				pCommands.Delete(vNum);		
			EndIf;
			If vCommand.Command = PlannerStandardCommand.CreateItem Then
				pCommands.Delete(vNum);		
			EndIf;
			vNum = vNum + 1;
		EndDo;
		If pParameters.Items <> Undefined And pParameters.Items.Count() > 0 Then
			vNewCommand = New PlannerCommandDescription(New NotifyDescription("CopyResourceAction", ThisObject, New Structure("DocRef", pParameters.Items[0].Value)),
														NStr("ru='Копировать';en='Copy';de='Kopieren'"));
			vNewCommand.Picture = PictureLib.Copy;
			pCommands.Add(vNewCommand);
		
			vNewCommand = New PlannerCommandDescription(New NotifyDescription("CopyResourceToTheNewGroupAction", ThisObject, New Structure("DocRef", pParameters.Items[0].Value)),
														NStr("ru='Копировать в новую группу';en='Copy to the new group';de='In die neue Gruppe kopieren'"));
			vNewCommand.Picture = PictureLib.CloneObject;
			pCommands.Add(vNewCommand);
		
			pCommands.Add(New PlannerCommandDescription(Undefined,""));
			vNewCommand = New PlannerCommandDescription(New NotifyDescription(), NStr("en = 'Open:'; de = 'Öffnen:'; ru = 'Открыть:'"));
			vNewCommand.Picture = PictureLib.Empty;
			vNewCommand.Enabled = False;
			pCommands.Add(vNewCommand);
				
			vNewCommand = New PlannerCommandDescription(New NotifyDescription("FindChargingFolioAction", ThisObject, New Structure("DocRef", pParameters.Items[0].Value)),
														NStr("en='Folios list';ru='Список лицевых счетов';de='Liste der Personenkonten'"));
			vNewCommand.Picture = PictureLib.Calculator;
			pCommands.Add(vNewCommand);
		
			vNewCommand = New PlannerCommandDescription(New NotifyDescription("GuestGroupReservationsAction", ThisObject, New Structure("DocRef", pParameters.Items[0].Value)),
														NStr("en = 'Guest group room reservations list'; de = 'Liste für Ressourcen nach Gruppen'; ru = 'Список брони номеров по группе'"));
			vNewCommand.Picture = PictureLib.DocumentJournal;
			pCommands.Add(vNewCommand);
			
			vNewCommand = New PlannerCommandDescription(New NotifyDescription("ResourceReservationsAction", ThisObject, New Structure("DocRef", pParameters.Items[0].Value)),
														NStr("en = 'Guest group resource list'; de = 'Liste für Zimmerreservierung nach Gruppen'; ru = 'Список ресурсов по группе'"));
			vNewCommand.Picture = PictureLib.PaperClip;
			pCommands.Add(vNewCommand);
		
			vNewCommand = New PlannerCommandDescription(New NotifyDescription("GuestGroupItemAction", ThisObject, New Structure("DocRef", pParameters.Items[0].Value)),
														NStr("en = 'Group details'; de = 'Gruppenkarte'; ru = 'Карточка группы'"));
			vNewCommand.Picture = PictureLib.Catalog;
			pCommands.Add(vNewCommand);
			
			vNewCommand = New PlannerCommandDescription(New NotifyDescription("GuestGroupAllotmentItemAction", ThisObject, New Structure("DocRef", pParameters.Items[0].Value)),
														NStr("en = 'Group allotment details'; de = 'Gruppenallotmentkarte'; ru = 'Карточка квоты группы'"));
			vNewCommand.Picture = PictureLib.ReportAdditionalFields;
			pCommands.Add(vNewCommand);
			
			pCommands.Add(New PlannerCommandDescription(Undefined,""));
			vNewCommand = New PlannerCommandDescription(New NotifyDescription(),
													NStr("en = 'Change status to:'; de = 'Status ändern zu:'; ru = 'Изменить статус на:'"));
			vNewCommand.Picture = PictureLib.Empty;
			vNewCommand.Enabled = False;
			pCommands.Add(vNewCommand);
		
			If Statuses.Count() > 0 Then
				For Each vStatusesRow In Statuses Do
					If vStatusesRow.ResourceReservationStatus = tcOnServer.cmGetAttributeByRef(pParameters.Items[0].Value, "ResourceReservationStatus") Then
						Continue;
					EndIf;
					vNewCommand = New PlannerCommandDescription(New NotifyDescription("ChangeStatusAction", ThisObject, New Structure("DocRef, StatusRef", pParameters.Items[0].Value,vStatusesRow.ResourceReservationStatus)),		
															TrimAll(vStatusesRow.Description));
					If vStatusesRow.IsActive Then
						If vStatusesRow.ServicesAreDelivered Then
							vNewCommand.Picture = PictureLib.Pin;
						ElsIf vStatusesRow.DoCharging Then
							vNewCommand.Picture = PictureLib.AccumulationRegister;
						ElsIf vStatusesRow.IsGuaranteed Then
							vNewCommand.Picture = PictureLib.CheckMark;
						Else
							vNewCommand.Picture = PictureLib.IsActive;
						EndIf;
					Else
						vNewCommand.Picture = PictureLib.IsNotActive;
					EndIf;
				
					pCommands.Add(vNewCommand);
				EndDo;
			EndIf;
		EndIf;
		//Execute(vCode);
	#EndIf
EndProcedure // ResourcePlannerCommandGenerateProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure GetGuaranteeType(pItem, pExtraParams) Export
	vGuaranteeType = pItem.Value;
	If vGuaranteeType = Undefined Then
		ShowMessageBox(, "ru='Вид гарантии должен быть выбран!';en='Guarantee type should be filled!';de='Art der Garantie sollte ausgefüllt werden!'");
		Return;
	Else
		ChangeStatus(pExtraParams.DocRef, pExtraParams.StatusRef, vGuaranteeType);
		// Refresh form
		UpdatePlanner();
	EndIf;		
EndProcedure // LoadSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerBeforeDelete(pItem, pCancel)
	pCancel = True;
EndProcedure // ResourcePlannerBeforeDelete

// -----------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerDimensionItemClick(pItem, pDimensionItem, pDimensionValues, pStandardProcessing)
	pStandardProcessing = False;
	For Each vDimension In ResourcePlanner.Dimensions Do
		For Each vDimensionItem In vDimension.Items Do
			If vDimensionItem = pDimensionItem Then
				vDimensionItem.BackColor = WebColors.Cream;
			Else
				vDimensionItem.BackColor = WebColors.White;
			EndIf;
		EndDo;
	EndDo;
EndProcedure // ResourcePlannerDimensionItemClick

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
EndProcedure // HotelClearing

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerOnEditEnd(pItem, pNewItem, pCancelEdit)
	pCancelEdit = True;
EndProcedure // ResourcePlannerOnEditEnd

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure NextPeriod(pCommand)
	If ResourcePlannerScale = 0 Then
		PeriodCalendar 	= AddMonth(PeriodCalendar, 1);
	ElsIf ResourcePlannerScale = 1 Then
		PeriodCalendar	= BegOfDay(PeriodCalendar) + 7 * 24 * 3600;
	ElsIf ResourcePlannerScale = 2 Then
		PeriodCalendar	= BegOfDay(PeriodCalendar) + 1 * 24 * 3600;
	EndIf;
	UpdatePlanner();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PrevPeriod(pCommand)
	If ResourcePlannerScale = 0 Then
		PeriodCalendar 	= AddMonth(PeriodCalendar, -1);
	ElsIf ResourcePlannerScale = 1 Then
		PeriodCalendar	= BegOfDay(PeriodCalendar) - 7 * 24 * 3600;
	ElsIf ResourcePlannerScale = 2 Then
		PeriodCalendar	= BegOfDay(PeriodCalendar) - 1 * 24 * 3600;
	EndIf;
	UpdatePlanner();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure TodayPeriod(pCommand)
	PeriodCalendar = CurrentDate();
	UpdatePlanner();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RefreshPlanner(pCommand)
	Items.PeriodCalendar.Refresh();
	UpdatePlanner();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcesAreVerticalOnChange(pItem)
	Items.GroupPeriod.Hide();
	UpdatePlanner();
EndProcedure // ResourcesAreVerticalOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenResourceReservationsList(pCommand)
	OpenForm("Document.ResourceReservation.ListForm", New Structure("SelHotel, SelDate, SelResourceType, SelResource", Hotel, PeriodCalendar, ResourceType, Resource), ThisObject);
EndProcedure // OpenResourceReservationsList

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintPlanner(pCommand)
	vPeriodFrom	= BegOfDay(PeriodCalendar);		
	If ResourcePlannerScale = 0 Then
		vPeriodTo = EndOfDay(vPeriodFrom) + 31 * 24 * 3600;
	ElsIf ResourcePlannerScale = 1 Then
		vPeriodFrom = BegOfDay(vPeriodFrom);
		vPeriodTo = EndOfDay(vPeriodFrom + 24 * 60 * 60 * 6);
	Else
		vPeriodTo = EndOfDay(vPeriodFrom);
	EndIf; 
	
	vResourceWidth = 0;
	vResourceHeight = 0;
	GetResourceHeight(vResourceWidth, vResourceHeight);
	
	vParams = New Structure("Hotel, GuestGroup, Resource, ResourceType, IsOneMonthScale, IsOneWeekScale, PeriodFrom, PeriodTo, ResourceWidth, ResourceHeight", Hotel, GuestGroup, Resource, ResourceType, ResourcePlannerScale = 0, ResourcePlannerScale = 1, vPeriodFrom, vPeriodTo, vResourceWidth, vResourceHeight);
	OpenForm("Catalog.Resources.Form.tcPrintResourcesCalendar", vParams, ThisObject);
EndProcedure // PrintPlanner

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenNewResourceReservationForm(pUserChoice, pExtraParams) Export
	If ValueIsFilled(pUserChoice) And TypeOf(pUserChoice) = Type("CatalogRef.EventActivities") Then
		Params.EventActivity = pUserChoice;
	EndIf;
	OpenForm("Document.ResourceReservation.ObjectForm", Params, ThisObject);
EndProcedure // OpenNewResourceReservationForm

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure GetAllResourceReservationStatuses()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ResourceReservationStatuses.Ref AS ResourceReservationStatus,
	|	ResourceReservationStatuses.Code AS Code,
	|	ResourceReservationStatuses.Description AS Description,
	|	ResourceReservationStatuses.SortCode AS SortCode,
	|	ResourceReservationStatuses.IsActive AS IsActive,
	|	ResourceReservationStatuses.IsGuaranteed AS IsGuaranteed,
	|	ResourceReservationStatuses.DoCharging AS DoCharging,
	|	ResourceReservationStatuses.ServicesAreDelivered AS ServicesAreDelivered
	|FROM
	|	Catalog.ResourceReservationStatuses AS ResourceReservationStatuses
	|WHERE
	|	NOT ResourceReservationStatuses.DeletionMark
	|	AND NOT ResourceReservationStatuses.IsFolder
	|	AND (ResourceReservationStatuses.Hotel = &qHotel
	|			OR ResourceReservationStatuses.Hotel = &qEmptyHotel)
	|
	|ORDER BY
	|	SortCode";
	vQry.SetParameter("qHotel", SessionParameters.CurrentHotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
 	Statuses.Load(vQry.Execute().Unload());
EndProcedure // GetAllResourceReservationStatuses

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowPlanner() 
	OnOpenMode = False;
	UpdatePlanner();
EndProcedure // ShowPlanner

// --------------------------------------------------------------------------------
&AtServer
Procedure PrepareResourcePlanner()
	vPeriodFrom	= BegOfDay(PeriodCalendar);		
	vScale = 1;
	
	If ResourcesAreVertical Then
		ResourcePlanner.AutoMinColumnWidth = True;
		ResourcePlanner.MinColumnWidth = 0;
	Else
		ResourcePlanner.AutoMinColumnWidth = False;
		ResourcePlanner.MinColumnWidth = 15;
	EndIf;
	
	// Time scale items
	If ResourcePlannerScale = 0 Then
		vTS0 = ResourcePlanner.TimeScale.Items.Get(0);
		vTS0.TextColor = WebColors.DarkSlateGray;
		While ResourcePlanner.TimeScale.Items.Count() <> 1 Do
			ResourcePlanner.TimeScale.Items.Delete(ResourcePlanner.TimeScale.Items.Get(1));
		EndDo;		
	Else
		vTS0 = ResourcePlanner.TimeScale.Items.Get(0);	
		If ResourcePlanner.TimeScale.Items.Count() = 1 Then
			vTS1 = ResourcePlanner.TimeScale.Items.Add();
		Else
			vTS1 = ResourcePlanner.TimeScale.Items.Get(1);
		EndIf;
		vTS0.TextColor = WebColors.DarkSlateGray;
		vTS1.TextColor = WebColors.DarkSlateGray;	
	EndIf;
	
	If ResourcePlannerScale = 0 Then
		vPeriodFrom	= BegOfDay(vPeriodFrom);
		vPeriodTo = EndOfDay(vPeriodFrom) + ((EndOfMonth(vPeriodFrom) - BegOfMonth(vPeriodFrom))/(24*3600) - 1) * (24*3600);
		ResourcePlanner.BeginOfRepresentationPeriod = vPeriodFrom;
		ResourcePlanner.EndOfRepresentationPeriod = vPeriodTo;
		ResourcePlanner.PeriodicVariantUnit = TimeScaleUnitType.Day;
		vScale = (vPeriodTo - vPeriodFrom) / (24 * 3600) + 1;
		
		vTS0.Unit = TimeScaleUnitType.Day;
		vTS0.Repetition = 1;
		vTS0.Format = "DF='dd.MM.yy ddd'";
		
		ResourcePlanner.TimeScale.Location 	= ResourcePlannerTimeScalePositionMonth;
		ResourcePlanner.ShowCurrentDate 	= False;
	ElsIf ResourcePlannerScale = 1 Then
		vPeriodFrom = BegOfDay(vPeriodFrom);
		vPeriodTo = EndOfDay(vPeriodFrom + 6 * (24*3600));
		ResourcePlanner.BeginOfRepresentationPeriod = vPeriodFrom;
		ResourcePlanner.EndOfRepresentationPeriod 	= vPeriodTo;
		ResourcePlanner.PeriodicVariantUnit = TimeScaleUnitType.Day;
		vScale = (vPeriodTo - vPeriodFrom) / (24 * 60);
		
		// Reverse time scales
		vTS0.Unit = TimeScaleUnitType.Day;
		vTS0.Repetition = 1;
		vTS0.Format = "DF='ddd dd'";
		
		vTS1.Unit = TimeScaleUnitType.Hour;
		vTS1.Repetition = 6;
		vTS1.Format = "DF=HH:mm";
		
		ResourcePlanner.TimeScale.Location = ResourcePlannerTimeScalePositionWeek;
		ResourcePlanner.ShowCurrentDate = True;
	ElsIf ResourcePlannerScale = 2 Then
		vPeriodTo = EndOfDay(vPeriodFrom);
		ResourcePlanner.BeginOfRepresentationPeriod = vPeriodFrom;
		ResourcePlanner.EndOfRepresentationPeriod = vPeriodTo;
		ResourcePlanner.PeriodicVariantUnit= TimeScaleUnitType.Hour;
		vScale = 24;
		
		vTS0.Unit = TimeScaleUnitType.Day;
		vTS0.Repetition = 1;
		vTS0.Format = "DF='ddd dd'";
		
		vTS1.Unit = TimeScaleUnitType.Hour;
		vTS1.Repetition = 1;
		vTS1.Format = "DF=HH:mm";

		ResourcePlanner.TimeScale.Location = ResourcePlannerTimeScalePositionDay;
		ResourcePlanner.ShowCurrentDate = True;
	EndIf;	
	ResourcePlanner.PeriodicVariantRepetition = vScale;		
		
	ResourcePlanner.CurrentRepresentationPeriods.Clear();
	ResourcePlanner.CurrentRepresentationPeriods.Add(vPeriodFrom, vPeriodTo);
	ResourcePlanner.AlignItemBoundariesByTimeScale = False;
	
	ResourcePlanner.BackgroundIntervals.Clear();
	If ResourcePlannerScale = 0  Or  ResourcePlannerScale = 1 Then
		vCurPer = EndOfWeek(vPeriodFrom) - 2 * 24 * 3600 + 1; // Beg of saturday
		While vCurPer < vPeriodTo Do
			vWeekEnd = ResourcePlanner.BackgroundIntervals.Add(vCurPer, EndOfWeek(vCurPer));
			vWeekEnd.Color = WebColors.SeaShell;
			vCurPer = vCurPer + 7 * 24 * 3600;
		EndDo;
		If ResourcePlannerScale = 0 Then
			vCurrentDate = ResourcePlanner.BackgroundIntervals.Add(BegOfDay(CurrentSessionDate()), EndOfDay(CurrentSessionDate()));
			vCurrentDate.Color = WebColors.LightYellow;	
		EndIf;
	EndIf;
	
	// Clear planner
	ResourcePlanner.Items.Clear();
	ResourcePlanner.ItemsTimeRepresentation = PlannerItemsTimeRepresentation.DontDisplay;
	ResourcePlanner.Dimensions.Clear();
	
	vDimension = ResourcePlanner.Dimensions.Add("Resources");
	vDimension.Text = NStr("en = 'Resources__________'; ru = 'Ресурсы_____________'; de = 'Ressource__________'");
	
	vPresentationText = "";
	If ResourcePlannerScale = 0 Then
		If Month(vPeriodFrom) <> Month(vPeriodTo) Then
			If Year(vPeriodFrom) <> Year(vPeriodTo) Then
				vPresentationText = Format(vPeriodFrom,"DF='MMMM yyyy'") + " - " + Format(vPeriodTo, "DF='MMMM yyyy'");
			Else
				vPresentationText = Format(vPeriodFrom,"DF=MMMM") + " - " + Format(vPeriodTo, "DF='MMMM yyyy'");	
			EndIf;
		Else
			vPresentationText = Format(vPeriodTo, "DF='MMMM yyyy'"); 
		EndIf;
	ElsIf ResourcePlannerScale = 1 Then
		vPresentationText = Format(vPeriodFrom, "DF='dd.MM.yyyy'") + " - " + Format(vPeriodTo, "DF='dd.MM.yyyy'"); 
	Else
		vPresentationText = Format(vPeriodFrom, "DF='dd MMMM yyyy ddd'"); 
	EndIf;
	Items.GroupPeriod.Title = vPresentationText;
	
	If Not Items.DecorationHowToFilter.Visible Then
		FillResourcePlanner();
	EndIf;
EndProcedure // PrepareResourcePlanner

// -----------------------------------------------------------------------------
&AtServer
Procedure AddResourceMaximumNumberOfPersonsAndPrice(pResourceDescription, pResource)
	// Add maximum number of persons for the resource
	If pResource.ShowNumberOfPersonsPerResource And pResource.NumberOfPersonsPerResource > 0 Then
		pResourceDescription = pResourceDescription + ", " + 
		                       Format(pResource.NumberOfPersonsPerResource, "ND=6; NFD=0; NZ=; NG=") + 
		                       NStr("en=' prs.';ru=' чел.';de=' prs.'");
	EndIf;
	// Add resource price
	If pResource.ShowPrice And ValueIsFilled(PeriodCalendar) Then
		vPrices = cmGetResourcePrices(Hotel, BegOfDay(PeriodCalendar), EndOfDay(PeriodCalendar), Catalogs.ClientTypes.EmptyRef(), pResource.Owner, pResource, Undefined);
		For Each vPricesRow In vPrices Do
			If vPricesRow.Price <> Null And vPricesRow.Price > 0 Then
				pResourceDescription = pResourceDescription + ", " + 
				                       cmFormatSum(vPricesRow.Price, vPricesRow.Currency);
				Break;
			Else
				Break;
			EndIf;
		EndDo;
	EndIf;
EndProcedure // AddResourceMaximumNumberOfPersonsAndPrice 

// --------------------------------------------------------------------------------
&AtServer
Procedure FillResourcePlanner()
	vDimension = ResourcePlanner.Dimensions.Find("Resources");
	ResourcesCount = 0;
	If OnOpenMode Then
		vResources = New ValueTable();
		vWorkingTimes = New ValueTable();
	Else
		vResources = GetResources(Hotel, ResourceType, Resource);
		ResourcesCount = vResources.Count();
		vWorkingTimes = GetWorkingTimes(ResourcePlanner.BeginOfRepresentationPeriod, ResourcePlanner.EndOfRepresentationPeriod, Hotel, ResourceType, Resource);
	EndIf;
	
	vChildResources = GetChildResources(Hotel, ResourceType);
	vIsChildResources = vChildResources.Count() > 0;
	
	For Each vResourceRow In vResources Do
		itemRes = vDimension.Items.Find(vResourceRow.Resource);
		If itemRes = Undefined Then
			itemRes = vDimension.Items.Add(vResourceRow.Resource);
			itemRes.TextColor = WebColors.Black;
			itemRes.BackColor = WebColors.White;
			itemRes.Value = vResourceRow.Resource;
			itemRes.Text = TrimAll(vResourceRow.Resource);
			AddResourceMaximumNumberOfPersonsAndPrice(itemRes.Text, vResourceRow.Resource);
			
			If vIsChildResources Then
				vSubResources = vChildResources.FindRows(New Structure("ResourceParent", vResourceRow.Resource));
				If vSubResources.Count() > 0 Then
					For Each vSubResourceRow In vSubResources Do
						vSubItem = itemRes.Items.Add(vSubResourceRow.Resource);
						vNotWorkingPeriods = GetNotWorkingPeriods(vWorkingTimes, vSubResourceRow.Resource);
						vDims = New Map;
						vDims.Insert("Resources", vSubResourceRow.Resource);
						For Each vPeriodRow In vNotWorkingPeriods Do
							vNotWorkingPeriod = ResourcePlanner.BackgroundIntervals.Add(vPeriodRow.PeriodFrom, vPeriodRow.PeriodTo);
							vNotWorkingPeriod.Color = WebColors.WhiteSmoke;
							vNotWorkingPeriod.DimensionValues = New FixedMap(vDims);
						EndDo;
					EndDo;
					itemRes.ShowItemsAreaOnlyForSubordinates = True;
				EndIf;
			EndIf;
		EndIf;
		
		If Not vResourceRow.Resource.RoundTheClockOperation Then
			vNotWorkingPeriods = GetNotWorkingPeriods(vWorkingTimes, vResourceRow.Resource);
			vDims = New Map;
			vDims.Insert("Resources", vResourceRow.Resource);
			For Each vPeriodRow In vNotWorkingPeriods Do
				vNotWorkingPeriod = ResourcePlanner.BackgroundIntervals.Add(vPeriodRow.PeriodFrom, vPeriodRow.PeriodTo);
				vNotWorkingPeriod.Color = WebColors.WhiteSmoke;
				vNotWorkingPeriod.DimensionValues = New FixedMap(vDims);
			EndDo;
		EndIf;
	EndDo;
	
	If vResources.Count() > 0 Then
		vResourceReservations = GetResourceReservations(ResourcePlanner.BeginOfRepresentationPeriod, ResourcePlanner.EndOfRepresentationPeriod, Hotel, ResourceType, Resource);
		Items.PeriodCalendar.SelectedDates.Clear();
		For Each vResourceReservationRow In vResourceReservations Do
			SetResource(vResourceReservationRow);
			
			If vIsChildResources Then
				vSubResources = vChildResources.FindRows(New Structure("ResourceParent", vResourceReservationRow.Resource));
				For Each vSubResourceRow In vSubResources Do
					vResourceReservationRow.ResourceParent = vResourceReservationRow.Resource;
					vResourceReservationRow.Resource = vSubResourceRow.Resource;
					SetResource(vResourceReservationRow);
				EndDo;
			EndIf;
		EndDo;
	EndIf;

	If ResourcesAreVertical Then
		vEffectiveRowsCount = Int(ResourcesCount + 3 + vChildResources.Count());
		vMaxRowsCount = 30;
		
		If vEffectiveRowsCount > vMaxRowsCount Then
			Items.ResourcePlanner.VerticalStretch = True;
			Items.ResourcePlanner.Height = 9;
			ResourcePlanner.AutoMinRowHeight = False;
			ResourcePlanner.MinRowHeight = 2;
		Else
			Items.ResourcePlanner.VerticalStretch = False;
			Items.ResourcePlanner.Height = vEffectiveRowsCount;
			ResourcePlanner.AutoMinRowHeight = True;
			ResourcePlanner.MinRowHeight = 0;
		EndIf;
	Else
		Items.ResourcePlanner.VerticalStretch = True;
		Items.ResourcePlanner.Height = 9;
		If ResourcePlannerScale = 0 Then
			ResourcePlanner.AutoMinRowHeight = False;
			ResourcePlanner.MinRowHeight = 4;
		Else
			ResourcePlanner.AutoMinRowHeight = True;
			ResourcePlanner.MinRowHeight = 0;
		EndIf;
	EndIf;

	// Save some settings
	SystemSettingsStorage.Save("tcResourcesCalendar_ResourcesAreVertical", SessionParameters.CurrentUser, ResourcesAreVertical);
	SystemSettingsStorage.Save("tcResourcesCalendar_ResourcePlannerScale", SessionParameters.CurrentUser, ResourcePlannerScale);
EndProcedure // FillResourcePlanner

// --------------------------------------------------------------------------------
&AtServer
Procedure SetResource(pResourceReservationRow)
	If (ResourcePlannerScale = 0 Or ResourcePlannerScale = 1) And 
	   (pResourceReservationRow.IsPreparationTime Or pResourceReservationRow.IsDisassembleTime) Then
		Return;
	Else
		vItem = ResourcePlanner.Items.Add(pResourceReservationRow.DateTimeFrom, pResourceReservationRow.DateTimeTo);
	EndIf;
	vDims = New Map;
	vDims.Insert("Resources", pResourceReservationRow.Resource);
	vResourcePresentation = GetPresentationForResourceReservation(pResourceReservationRow, ResourcesAreVertical);
	vItem.DimensionValues = New FixedMap(vDims);
	vItem.ToolTip = "" + vResourcePresentation.Text;
	vItem.Text = "" + vResourcePresentation.Text;
	vItem.BackColor = vResourcePresentation.Color;
	vItem.BorderColor = vResourcePresentation.BorderColor; 
	vItem.Value = pResourceReservationRow.ResourceReservation;
EndProcedure // SetResource

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdatePlanner()
	If Not ResourcesAreVertical Then
		ResourcePlannerTimeScalePositionMonth = TimeScalePosition.Left; 
		ResourcePlannerTimeScalePositionWeek = TimeScalePosition.Left; 
		ResourcePlannerTimeScalePositionDay = TimeScalePosition.Left; 
	Else
		ResourcePlannerTimeScalePositionMonth = TimeScalePosition.Top;
		ResourcePlannerTimeScalePositionWeek = TimeScalePosition.Top;
		ResourcePlannerTimeScalePositionDay = TimeScalePosition.Top;
	EndIf;
	If SelAskForResourcesFilterByDefault Then
		If ValueIsFilled(Hotel) Then
			If ValueIsFilled(ResourceType) Or ValueIsFilled(Resource) Then
				Items.DecorationHowToFilter.Visible = False;
			Else
				Items.DecorationHowToFilter.Visible = True;
			Endif;
		Else
			Items.DecorationHowToFilter.Visible = True;
		EndIf;
	Else
		If ValueIsFilled(Hotel) Then
			Items.DecorationHowToFilter.Visible = False;
		Else
			Items.DecorationHowToFilter.Visible = True;
		EndIf;
	EndIf;
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	// Show planner	
	PrepareResourcePlanner();
EndProcedure // UpdatePlanner

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetChildResources(pHotel, pResourceType)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Resources.Ref AS Resource,
	|	Resources.Parent AS ResourceParent
	|FROM
	|	Catalog.Resources AS Resources
	|WHERE
	|	NOT Resources.DeletionMark
	|	AND (Resources.Hotel IN HIERARCHY (&qHotel)
	|			OR Resources.Hotel = &qEmptyHotel)
	|	AND (Resources.Owner IN HIERARCHY (&qResourceType)
	|			OR &qResourceTypeIsEmpty)
	|	AND NOT Resources.Parent = &qEmptyResource";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qResourceType", pResourceType);
	vQry.SetParameter("qResourceTypeIsEmpty", Not ValueIsFilled(pResourceType));
	vQry.SetParameter("qEmptyResource", Catalogs.Resources.EmptyRef());
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	Return vQry.Execute().Unload();
EndFunction // GetResources

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetResources(pHotel, pResourceType, pResource)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Resources.Parent AS ResourceParent,
	|	Resources.Ref AS Resource,
	|	Resources.Owner.SortCode AS ResourceTypeSortCode,
	|	Resources.Parent.SortCode AS ResourceParentSortCode,
	|	Resources.SortCode AS ResourceSortCode
	|FROM
	|	Catalog.Resources AS Resources
	|WHERE
	|	NOT Resources.DeletionMark
	|	AND (Resources.Hotel IN HIERARCHY (&qHotel)
	|			OR Resources.Hotel = &qEmptyHotel)
	|	AND (Resources.Owner IN HIERARCHY (&qResourceType)
	|			OR &qResourceTypeIsEmpty)
	|	AND (Resources.Ref IN HIERARCHY (&qResource)
	|			OR &qResourceIsEmpty)
	|	AND CASE
	|			WHEN &qResourceIsEmpty
	|				THEN Resources.Parent = &qEmptyResource
	|			ELSE NOT Resources.Ref IN
	|						(SELECT
	|							ResourceParents.Parent
	|						FROM
	|							Catalog.Resources AS ResourceParents
	|						WHERE
	|							NOT ResourceParents.DeletionMark
	|							AND (ResourceParents.Hotel IN HIERARCHY (&qHotel)
	|								OR ResourceParents.Hotel = &qEmptyHotel)
	|							AND (ResourceParents.Owner IN HIERARCHY (&qResourceType)
	|								OR &qResourceTypeIsEmpty)
	|							AND ResourceParents.Parent <> &qEmptyResource)
	|		END
	|
	|ORDER BY
	|	ResourceTypeSortCode,
	|	ResourceParentSortCode,
	|	ResourceSortCode";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qResourceType", pResourceType);
	vQry.SetParameter("qResourceTypeIsEmpty", Not ValueIsFilled(pResourceType));
	vQry.SetParameter("qResource", pResource);
	vQry.SetParameter("qResourceIsEmpty", Not ValueIsFilled(pResource));
	vQry.SetParameter("qEmptyResource", Catalogs.Resources.EmptyRef());
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	Return vQry.Execute().Unload();
EndFunction // GetResources

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetResourceReservations(pPeriodFrom, pPeriodTo, pHotel, pResourceType, pResource)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ResourceReservations.Resource.Parent AS ResourceParent,
	|	ResourceReservations.Resource AS Resource,
	|	ResourceReservations.ResourceType AS ResourceType,
	|	ResourceReservations.Resource.Parent.SortCode AS ResourceParentSortCode,
	|	ResourceReservations.Resource.SortCode AS ResourceSortCode,
	|	ResourceReservations.ResourceType.SortCode AS ResourceTypeSortCode,
	|	ResourceReservations.Recorder AS ResourceReservation,
	|	ResourceReservations.Hotel AS Hotel,
	|	ResourceReservations.Customer AS Customer,
	|	ResourceReservations.Contract AS Contract,
	|	ResourceReservations.Agent AS Agent,
	|	ResourceReservations.GuestGroup AS GuestGroup,
	|	ResourceReservations.ResourceReservationStatus AS ResourceReservationStatus,
	|	CASE
	|		WHEN ResourceReservations.DateTimeFrom < &qPeriodFrom
	|			THEN &qPeriodFrom
	|		ELSE ResourceReservations.DateTimeFrom
	|	END AS DateTimeFrom,
	|	ResourceReservations.Duration AS Duration,
	|	CASE
	|		WHEN ResourceReservations.DateTimeTo > &qPeriodTo
	|			THEN &qPeriodTo
	|		ELSE ResourceReservations.DateTimeTo
	|	END AS DateTimeTo,
	|	ResourceReservations.NumberOfPersons AS NumberOfPersons,
	|	ResourceReservations.Client AS Client,
	|	ResourceReservations.Company AS Company,
	|	ResourceReservations.ChargingFolio AS ChargingFolio,
	|	ResourceReservations.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	ResourceReservations.MarketingCode AS MarketingCode,
	|	ResourceReservations.SourceOfBusiness AS SourceOfBusiness,
	|	ResourceReservations.DiscountCard AS DiscountCard,
	|	ResourceReservations.DiscountType AS DiscountType,
	|	ResourceReservations.Discount AS Discount,
	|	ResourceReservations.CreditCard AS CreditCard,
	|	ResourceReservations.CustomerType AS CustomerType,
	|	ResourceReservations.ClientType AS ClientType,
	|	ResourceReservations.Recorder.ContactPerson AS ContactPerson,
	|	ResourceReservations.Recorder.Remarks AS Remarks,
	|	ResourceReservations.Period AS PointInTime,
	|	ResourceReservations.Recorder.ResourceTableConfiguration AS ResourceTableConfiguration,
	|	ResourceReservations.EventActivity AS EventActivity,
	|	ResourceReservations.IsPreparationTime AS IsPreparationTime,
	|	ResourceReservations.IsDisassembleTime AS IsDisassembleTime
	|FROM
	|	InformationRegister.ResourceReservationHistory AS ResourceReservations
	|WHERE
	|	NOT ResourceReservations.Resource.DeletionMark
	|	AND ISNULL(ResourceReservations.ResourceReservationStatus.IsActive, FALSE)
	|	AND (ResourceReservations.Resource.Hotel IN HIERARCHY (&qHotel)
	|			OR ResourceReservations.Resource.Hotel = &qEmptyHotel)
	|	AND (ResourceReservations.ResourceType IN HIERARCHY (&qResourceType)
	|			OR &qResourceTypeIsEmpty)
	|	AND (ResourceReservations.Resource IN HIERARCHY (&qResource)
	|			OR &qResourceIsEmpty)
	|	AND ResourceReservations.DateTimeFrom < &qPeriodTo
	|	AND ResourceReservations.DateTimeTo > &qPeriodFrom
	|
	|ORDER BY
	|	ResourceTypeSortCode,
	|	ResourceParentSortCode,
	|	ResourceSortCode,
	|	DateTimeFrom,
	|	DateTimeTo";
	vQry.SetParameter("qHotel", 				pHotel);
	vQry.SetParameter("qHotelIsEmpty", 			Not ValueIsFilled(pHotel));
	vQry.SetParameter("qResourceType", 			pResourceType);
	vQry.SetParameter("qResourceTypeIsEmpty", 	Not ValueIsFilled(pResourceType));
	vQry.SetParameter("qResource", 				pResource);
	vQry.SetParameter("qResourceIsEmpty", 		Not ValueIsFilled(pResource));
	vQry.SetParameter("qPeriodFrom", 			pPeriodFrom);
	vQry.SetParameter("qPeriodTo", 				pPeriodTo);
	vQry.SetParameter("qEmptyResource", 		Catalogs.Resources.EmptyRef());
	vQry.SetParameter("qEmptyHotel", 			Catalogs.Hotels.EmptyRef());
	Return vQry.Execute().Unload();
EndFunction // GetResourceReservations

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetColorsForCalendar(pPeriodFrom, pPeriodTo, pHotel, pResourceType, pResource)
	vResult 				= New Array;
	vResourceReservations 	= GetResourceReservations(pPeriodFrom, pPeriodTo, pHotel, pResourceType, pResource);
	For Each vResource In vResourceReservations Do
		vResult.Add(New Structure("DateTimeFrom, DateTimeTo, Color", vResource.DateTimeFrom, vResource.DateTimeTo, tcCommonFunctionOnClientServer.ColorConstructor(219, 215, 210)));
	EndDo;
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetPresentationForResourceReservation(pResourceReservationRow, pResourcesAreVertical)
	vResult = New Structure("Text, Comments, Color, BorderColor", "", "", tcCommonFunctionOnClientServer.ColorConstructor(), StyleColors.ResourceReservationBorderColor);	
	If ValueIsFilled(pResourceReservationRow.ResourceReservationStatus) Then
		If pResourceReservationRow.ResourceReservationStatus.IsGuaranteed Then
			vResult.BorderColor = StyleColors.GuaranteedResourceReservationBorderColor;
		EndIf;
	EndIf;
	If pResourceReservationRow.IsPreparationTime Or pResourceReservationRow.IsDisassembleTime Then
		vResult.Color = WebColors.Gray;
		vResult.Text = "";
		vResult.Comments = "";
	Else
		If ValueIsFilled(pResourceReservationRow.ResourceReservationStatus) Then
			If pResourceReservationRow.ResourceReservationStatus.Color <> Undefined Then
				vResourceReservationStatusColor = pResourceReservationRow.ResourceReservationStatus.Color.Get();
				If TypeOf(vResourceReservationStatusColor) = Type("Color") Then
					vResult.Color = vResourceReservationStatusColor;
				EndIf;
			EndIf;
			If pResourceReservationRow.ClientType.Color <> Undefined Then
				vClientTypeColor = pResourceReservationRow.ClientType.Color.Get();
				If TypeOf(vClientTypeColor) = Type("Color") Then
					vResult.Color = vClientTypeColor;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(pResourceReservationRow.Customer) Then
			If pResourceReservationRow.Customer.Color <> Undefined Then
				vCustomerColor = pResourceReservationRow.Customer.Color.Get();
				If TypeOf(vCustomerColor) = Type("Color") Then
					vResult.Color = vCustomerColor;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(pResourceReservationRow.Contract) Then
			If pResourceReservationRow.Contract.Color <> Undefined Then
				vContractColor = pResourceReservationRow.Contract.Color.Get();
				If TypeOf(vContractColor) = Type("Color") Then
					vResult.Color = vContractColor;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(pResourceReservationRow.GuestGroup) Then
			If pResourceReservationRow.GuestGroup.Color <> Undefined Then
				vGuestGroupColor = pResourceReservationRow.GuestGroup.Color.Get();
				If TypeOf(vGuestGroupColor) = Type("Color") Then
					vResult.Color = vGuestGroupColor;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(pResourceReservationRow.EventActivity) And TypeOf(pResourceReservationRow.EventActivity) = Type("CatalogRef.EventActivities") Then
			If pResourceReservationRow.EventActivity.Color <> Undefined Then
				vActivityColor = pResourceReservationRow.EventActivity.Color.Get();
				If TypeOf(vActivityColor) = Type("Color") Then
					vResult.Color = vActivityColor;
				EndIf;
			EndIf;
		EndIf;
		// Add comment with resource reservation messages
		vMessages = cmGetMessagesForObject(pResourceReservationRow.ResourceReservation);
		If vMessages.Count() > 0 Then
			vMessagesStr = cmGetMessagesPresentationForObject(vMessages, pResourceReservationRow.ResourceReservation);
			vResult.Comments = vMessagesStr;
		EndIf;
		vResult.Text = GetResourceReservationDescription(pResourceReservationRow, pResourcesAreVertical);
	EndIf;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetResourceReservationDescription(pResourceReservationRow, pResourcesAreVertical)
	vHotel = pResourceReservationRow.Hotel;
	vGuestGroup = pResourceReservationRow.GuestGroup;
	vDescription = "";
	vSkipEvent = False;
	vSkipCustomer = False;
	vSkipClient = False;
	If pResourcesAreVertical Then
		If ValueIsFilled(pResourceReservationRow.Customer) And ValueIsFilled(vHotel) And pResourceReservationRow.Customer <> vHotel.IndividualsCustomer Then
			vDescription = vDescription + TrimAll(pResourceReservationRow.Customer);
			vSkipCustomer = True;
		ElsIf ValueIsFilled(pResourceReservationRow.Client) Then
			vDescription = vDescription + TrimAll(pResourceReservationRow.Client);
			vSkipClient = True;
		ElsIf ValueIsFilled(vGuestGroup) And Not IsBlankString(vGuestGroup.Description) Then
			vDescription = vDescription + TrimAll(vGuestGroup.Description);
		ElsIf ValueIsFilled(pResourceReservationRow.EventActivity) Then
			vDescription = vDescription + TrimAll(pResourceReservationRow.EventActivity);
			vSkipEvent = True;
		EndIf;
		If Not IsBlankString(vDescription) Then
			If pResourceReservationRow.NumberOfPersons > 0 Then
				vDescription = vDescription + " (" + TrimAll(pResourceReservationRow.NumberOfPersons) + ")";
			EndIf;
			If ValueIsFilled(pResourceReservationRow.EventActivity) And Not vSkipEvent And TypeOf(pResourceReservationRow.EventActivity) = Type("CatalogRef.EventActivities") Then
				vDescription = vDescription + " - " + TrimAll(pResourceReservationRow.EventActivity.Code);
			EndIf;
		EndIf;
		If Not IsBlankString(vDescription) Then
			vDescription = vDescription + Chars.LF;
		EndIf;
		If ValueIsFilled(pResourceReservationRow.EventActivity) And Not vSkipEvent Then
			If BegOfDay(pResourceReservationRow.DateTimeFrom) <> BegOfDay(pResourceReservationRow.DateTimeTo) Then
				vDescription = vDescription + "[" + Format(pResourceReservationRow.DateTimeFrom, "DF='dd.MM HH:mm'") + "-" + Format(pResourceReservationRow.DateTimeTo, "DF='dd.MM HH:mm'") + "] ";
			Else
				vDescription = vDescription + "[" + Format(pResourceReservationRow.DateTimeFrom, "DF=HH:mm") + "-" + Format(pResourceReservationRow.DateTimeTo, "DF=HH:mm") + "] ";
			EndIf;
			vDescription = vDescription + TrimAll(pResourceReservationRow.EventActivity) + Chars.LF;
		Else
			If BegOfDay(pResourceReservationRow.DateTimeFrom) <> BegOfDay(pResourceReservationRow.DateTimeTo) Then
				vDescription = vDescription + "[" + Format(pResourceReservationRow.DateTimeFrom, "DF='dd.MM HH:mm'") + "-" + Format(pResourceReservationRow.DateTimeTo, "DF='dd.MM HH:mm'") + "]" + Chars.LF;
			Else
				vDescription = vDescription + "[" + Format(pResourceReservationRow.DateTimeFrom, "DF=HH:mm") + "-" + Format(pResourceReservationRow.DateTimeTo, "DF=HH:mm") + "]" + Chars.LF;
			EndIf;
		EndIf;
		If ValueIsFilled(pResourceReservationRow.Customer) Then
			If Not vSkipCustomer Then
				vDescription = vDescription + TrimAll(pResourceReservationRow.Customer) + Chars.LF;
			EndIf;
			If ValueIsFilled(pResourceReservationRow.Contract) Then
				vDescription = vDescription + TrimAll(pResourceReservationRow.Contract) + Chars.LF;
			EndIf;
		EndIf;
		If ValueIsFilled(pResourceReservationRow.Client) And Not vSkipClient Then
			vDescription = vDescription + TrimAll(pResourceReservationRow.Client) + Chars.LF;
		EndIf;
	Else
		If ValueIsFilled(pResourceReservationRow.Customer) And ValueIsFilled(vHotel) And pResourceReservationRow.Customer <> vHotel.IndividualsCustomer Then
			vDescription = vDescription + TrimAll(pResourceReservationRow.Customer);
			vSkipCustomer = True;
		ElsIf ValueIsFilled(pResourceReservationRow.Client) Then
			vDescription = vDescription + TrimAll(pResourceReservationRow.Client);
			vSkipClient = True;
		ElsIf ValueIsFilled(vGuestGroup) And Not IsBlankString(vGuestGroup.Description) Then
			vDescription = vDescription + TrimAll(vGuestGroup.Description);
		ElsIf ValueIsFilled(pResourceReservationRow.EventActivity) Then
			vDescription = vDescription + TrimAll(pResourceReservationRow.EventActivity);
			vSkipEvent = True;
		EndIf;
		If Not IsBlankString(vDescription) Then
			vDescription = vDescription + Chars.LF;
		EndIf;
		If ValueIsFilled(pResourceReservationRow.EventActivity) And Not vSkipEvent Then
			If BegOfDay(pResourceReservationRow.DateTimeFrom) <> BegOfDay(pResourceReservationRow.DateTimeTo) Then
				vDescription = vDescription + "[" + Format(pResourceReservationRow.DateTimeFrom, "DF='dd.MM HH:mm'") + "-" + Format(pResourceReservationRow.DateTimeTo, "DF='dd.MM HH:mm'") + "] ";
			Else
				vDescription = vDescription + "[" + Format(pResourceReservationRow.DateTimeFrom, "DF=HH:mm") + "-" + Format(pResourceReservationRow.DateTimeTo, "DF=HH:mm") + "] ";
			EndIf;
			vDescription = vDescription + TrimAll(pResourceReservationRow.EventActivity) + Chars.LF;
		Else
			If BegOfDay(pResourceReservationRow.DateTimeFrom) <> BegOfDay(pResourceReservationRow.DateTimeTo) Then
				vDescription = vDescription + "[" + Format(pResourceReservationRow.DateTimeFrom, "DF='dd.MM HH:mm'") + "-" + Format(pResourceReservationRow.DateTimeTo, "DF='dd.MM HH:mm'") + "]" + Chars.LF;
			Else
				vDescription = vDescription + "[" + Format(pResourceReservationRow.DateTimeFrom, "DF=HH:mm") + "-" + Format(pResourceReservationRow.DateTimeTo, "DF=HH:mm") + "]" + Chars.LF;
			EndIf;
		EndIf;
		If ValueIsFilled(pResourceReservationRow.Customer) Then
			If Not vSkipCustomer Then
				vDescription = vDescription + TrimAll(pResourceReservationRow.Customer) + Chars.LF;
			EndIf;
			If ValueIsFilled(pResourceReservationRow.Contract) Then
				vDescription = vDescription + TrimAll(pResourceReservationRow.Contract) + Chars.LF;
			EndIf;
		EndIf;
		If ValueIsFilled(pResourceReservationRow.Client) And Not vSkipClient Then
			vDescription = vDescription + TrimAll(pResourceReservationRow.Client) + Chars.LF;
		EndIf;
	EndIf;
	If pResourceReservationRow.NumberOfPersons > 0 Then
		vDescription = vDescription + NStr("en='Prs. ';ru='Чел. ';de='Prs. '") + TrimAll(pResourceReservationRow.NumberOfPersons) + Chars.LF;
	EndIf;
	If ValueIsFilled(vGuestGroup) Then
		vDescription = vDescription + NStr("en='Gr. '; ru='Гр. '; de='Gr. '") + TrimAll(vGuestGroup.Code) + ?(IsBlankString(vGuestGroup.Description), "", " - " + TrimAll(vGuestGroup.Description)) + Chars.LF;
	EndIf;
	If ValueIsFilled(pResourceReservationRow.ResourceReservationStatus) Then
		vDescription = vDescription + TrimAll(pResourceReservationRow.ResourceReservationStatus);
	EndIf;
	If ValueIsFilled(pResourceReservationRow.PlannedPaymentMethod) Then
		vDescription = vDescription + ", " + TrimAll(pResourceReservationRow.PlannedPaymentMethod.Code) + Chars.LF;
	Else
		vDescription = vDescription + Chars.LF;
	EndIf;
	If ValueIsFilled(pResourceReservationRow.ResourceTableConfiguration) Then
		vDescription = vDescription + TrimAll(pResourceReservationRow.ResourceTableConfiguration) + Chars.LF;
	EndIf;
	If Not IsBlankString(pResourceReservationRow.Remarks) Then
		vDescription = vDescription + TrimAll(pResourceReservationRow.Remarks);
	EndIf;
	Return TrimAll(vDescription);
EndFunction // GetResourceReservationDescription

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetWorkingTimes(pPeriodFrom, pPeriodTo, pHotel, pResourceType, pResource)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Resources.Ref AS Resource,
	|	Resources.SortCode AS ResourceSortCode,
	|	Resources.Description AS ResourceDescription,
	|	Resources.TimeFrom AS ResourceTimeFrom,
	|	Resources.TimeTo AS ResourceTimeTo,
	|	Resources.Calendar AS Calendar
	|INTO ResourcesWithCalendar
	|FROM
	|	Catalog.Resources AS Resources
	|WHERE
	|	NOT Resources.DeletionMark
	|	AND (Resources.Hotel IN HIERARCHY (&qHotel)
	|			OR Resources.Hotel = VALUE(Catalog.Hotels.EmptyRef))
	|	AND (Resources.Owner IN HIERARCHY (&qResourceType)
	|			OR &qResourceTypeIsEmpty)
	|	AND (Resources.Ref IN HIERARCHY (&qResource)
	|			OR &qResourceIsEmpty)
	|
	|GROUP BY
	|	Resources.Ref,
	|	Resources.SortCode,
	|	Resources.Description,
	|	Resources.TimeFrom,
	|	Resources.TimeTo,
	|	Resources.Calendar
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ResourcesWithCalendar.Resource AS Resource,
	|	CalendarDays.AccountingDate AS Period,
	|	CalendarDays.Calendar AS Calendar,
	|	CalendarDays.CalendarDayType AS CalendarDayType,
	|	CalendarDays.Timetable AS Timetable,
	|	CalendarDays.Timetable.WorkingHoursPerDay AS WorkingHoursPerDay,
	|	ISNULL(WorkingTimes.TimeFrom, ResourcesWithCalendar.ResourceTimeFrom) AS TimeFrom,
	|	ISNULL(WorkingTimes.TimeTo, ResourcesWithCalendar.ResourceTimeTo) AS TimeTo
	|FROM
	|	InformationRegister.CalendarDays.SliceLast(
	|			,
	|			Calendar IN
	|					(SELECT
	|						Resources.Calendar
	|					FROM
	|						ResourcesWithCalendar AS Resources)
	|				AND AccountingDate >= &qPeriodFrom
	|				AND AccountingDate < &qPeriodTo) AS CalendarDays
	|		LEFT JOIN ResourcesWithCalendar AS ResourcesWithCalendar
	|		ON CalendarDays.Calendar = ResourcesWithCalendar.Calendar
	|		LEFT JOIN Catalog.Timetables.WorkingTimes AS WorkingTimes
	|		ON CalendarDays.Timetable = WorkingTimes.Ref
	|
	|ORDER BY
	|	ResourcesWithCalendar.ResourceSortCode,
	|	ResourcesWithCalendar.ResourceDescription,
	|	CalendarDays.AccountingDate,
	|	TimeFrom";
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qResourceType", pResourceType);
	vQry.SetParameter("qResourceTypeIsEmpty", Not ValueIsFilled(pResourceType));
	vQry.SetParameter("qResource", pResource);
	vQry.SetParameter("qResourceIsEmpty", Not ValueIsFilled(pResource));
	Return vQry.Execute().Unload();
EndFunction // GetWorkingTimes

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetNotWorkingPeriods(pWorkingTimes, pResource)
	vResult = New ValueTable;
	vResult.Columns.Add("PeriodFrom");
	vResult.Columns.Add("PeriodTo");

	vDayWorkingTimes = pWorkingTimes.FindRows(New Structure("Resource", pResource));
	
	vCurPeriod = '00010101';
	vTimetableIsAvailablePerDate = False;
	For Each vDayWorkingTimesRow In vDayWorkingTimes Do
		If Not ValueIsFilled(vCurPeriod) Then
			vCurPeriod = BegOfDay(vDayWorkingTimesRow.Period);
		ElsIf BegOfDay(vCurPeriod) <> BegOfDay(vDayWorkingTimesRow.Period) Then
			If vTimetableIsAvailablePerDate And ValueIsFilled(vCurPeriod) And vCurPeriod < EndOfDay(vCurPeriod) Then
				vNewRow = vResult.Add();
				vNewRow.PeriodFrom = vCurPeriod;
				vNewRow.PeriodTo = EndOfDay(vCurPeriod);
			EndIf;

			vTimetableIsAvailablePerDate = False;
			vCurPeriod = BegOfDay(vDayWorkingTimesRow.Period);
		EndIf;
			
		If ValueIsFilled(vDayWorkingTimesRow.Timetable) And vDayWorkingTimesRow.WorkingHoursPerDay = 0 Then
			vNewRow = vResult.Add();
			vNewRow.PeriodFrom = BegOfDay(vCurPeriod);
			vNewRow.PeriodTo = EndOfDay(vCurPeriod);

			vTimetableIsAvailablePerDate = True;
			
			vCurPeriod = EndOfDay(vCurPeriod);
		ElsIf vDayWorkingTimesRow.TimeFrom < vDayWorkingTimesRow.TimeTo Then
			vStartOfCurWorkingPeriod 	= BegOfDay(vDayWorkingTimesRow.Period) + (vDayWorkingTimesRow.TimeFrom - BegOfDay(vDayWorkingTimesRow.TimeFrom));
			vEndOfCurWorkingPeriod 		= BegOfDay(vDayWorkingTimesRow.Period) + (vDayWorkingTimesRow.TimeTo - BegOfDay(vDayWorkingTimesRow.TimeTo));
			If vCurPeriod < vStartOfCurWorkingPeriod Then
				vNewRow = vResult.Add();
				vNewRow.PeriodFrom = vCurPeriod;
				vNewRow.PeriodTo = vStartOfCurWorkingPeriod - 1;

				vTimetableIsAvailablePerDate = True;
				
				vCurPeriod = vEndOfCurWorkingPeriod;
			EndIf;
		EndIf;
	EndDo;
	If vTimetableIsAvailablePerDate And ValueIsFilled(vCurPeriod) And vCurPeriod < EndOfDay(vCurPeriod) Then
		vNewRow = vResult.Add();
		vNewRow.PeriodFrom = vCurPeriod;
		vNewRow.PeriodTo = EndOfDay(vCurPeriod);
	EndIf;
	Return vResult;
EndFunction // GetNotWorkingPeriods

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyResourceAction(pExtraParams) Export
	If ValueIsFilled(pExtraParams.DocRef) Then
		vParametersStructure = New Structure("SelDocRef, UseNewGroup", pExtraParams.DocRef, False);
		OpenForm("Catalog.Resources.Form.tcCopyResources", vParametersStructure, ThisObject, UUID);
	EndIf;
EndProcedure // CopyResourceAction

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyResourceToTheNewGroupAction(pExtraParams) Export
	If ValueIsFilled(pExtraParams.DocRef) Then
		vParametersStructure = New Structure("SelDocRef, UseNewGroup", pExtraParams.DocRef, True);
		OpenForm("Catalog.Resources.Form.tcCopyResources", vParametersStructure, ThisObject, UUID);
	EndIf;
EndProcedure // CopyResourceToTheNewGroupAction

// -----------------------------------------------------------------------------
&AtClient
Procedure FindChargingFolioAction(pExtraParams) Export 
	If ValueIsFilled(pExtraParams.DocRef) Then
		// APDEX
		vKeyOperation = "CommonForm.tcFoliosForm.OpenForm";
		APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

		vParametersStructure = New Structure("ObjectRef", pExtraParams.DocRef);
		OpenForm("CommonForm.tcFoliosForm", New Structure("ParametersStructure", vParametersStructure), ThisObject, UUID);	
	EndIf;
EndProcedure // FindChargingFolioAction

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupReservationsAction(pExtraParams) Export
	If ValueIsFilled(pExtraParams.DocRef) Then
		vGuestGroupRef = tcOnServer.cmGetAttributeByRef(pExtraParams.DocRef,"GuestGroup");
		If ValueIsFilled(vGuestGroupRef) Then
			vParametersStructure = New Structure("SelGuestGroup", vGuestGroupRef);		
			#If Not MobileClient Then 
				// APDEX
				vKeyOperation = "Document.Reservation.Form.tcReservationListForm.OpenForm";
				APDEXPerformanceSystemOnClientServer.StartTimeIntervalMeasurement(vKeyOperation);

				OpenForm("Document.Reservation.Form.tcReservationListForm", vParametersStructure, ThisObject, UUID);
			#Else 
				OpenForm("Document.Reservation.Form.mcReservationListForm", vParametersStructure, ThisObject, UUID);	
			#EndIf
		EndIf;
	EndIf;
EndProcedure // GuestGroupReservationsAction

// -----------------------------------------------------------------------------
&AtClient
Procedure ResourceReservationsAction(pExtraParams) Export
	If ValueIsFilled(pExtraParams.DocRef) Then
		vGuestGroupRef = tcOnServer.cmGetAttributeByRef(pExtraParams.DocRef,"GuestGroup");
		If ValueIsFilled(vGuestGroupRef) Then
			vParametersStructure = New Structure("SelGuestGroup", vGuestGroupRef);
			OpenForm("Document.ResourceReservation.Form.tcReservationListForm", vParametersStructure, ThisObject, UUID);
		EndIf;
	EndIf;
EndProcedure // ResourceReservationsAction

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupItemAction(pExtraParams) Export
	If ValueIsFilled(pExtraParams.DocRef) Then
		vGuestGroupRef = tcOnServer.cmGetAttributeByRef(pExtraParams.DocRef,"GuestGroup");
		If ValueIsFilled(vGuestGroupRef) Then
			vParametersStructure = New Structure("Key", vGuestGroupRef);
			OpenForm("Catalog.GuestGroups.Form.tcItemForm", vParametersStructure, ThisObject, UUID);
		EndIf;
	EndIf;
EndProcedure // GuestGroupItemAction

// -----------------------------------------------------------------------------
&AtClient
Procedure GuestGroupAllotmentItemAction(pExtraParams) Export
	If ValueIsFilled(pExtraParams.DocRef) Then
		vGuestGroupRef = tcOnServer.cmGetAttributeByRef(pExtraParams.DocRef, "GuestGroup");
		If ValueIsFilled(vGuestGroupRef) Then
			vAllotmentRef = tcOnServer.cmGetAttributeByRef(vGuestGroupRef, "Allotment");
			If ValueIsFilled(vAllotmentRef) Then
				vParametersStructure = New Structure("Key", vAllotmentRef);
				OpenForm("Catalog.RoomQuotas.Form.tcItemForm", vParametersStructure, ThisObject, UUID);
			Else
				ShowMessageBox(, NStr("en='No allotment is defined for this group!'; de='Für diese Gruppe ist kein Allotment definiert!'; ru='Для этой группы квота не определена!'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure // GuestGroupAllotmentItemAction

// -----------------------------------------------------------------------------
&AtServer
Function GetGuaranteeTypesCount()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|	Catalog.GuaranteeTypes AS GuaranteeTypes
	|WHERE
	|	NOT GuaranteeTypes.DeletionMark";
	vElements = vQry.Execute().Unload();
	If vElements.Count() > 0 Then
		Return vElements.Get(0).Count;
	Else
		Return 0;
	EndIf;
EndFunction // cmGetGuaranteeTypesCount

// -----------------------------------------------------------------------------
&AtServer
Procedure ChangeStatus(pDocRef, pStatusRef, pGuaranteeType = Undefined)
		// Do change status
		vDocObj = pDocRef.GetObject();
		vDocObj.ResourceReservationStatus = pStatusRef;
		vDocObj.GuaranteeType = pGuaranteeType;
		vDocObj.DoCharging = pStatusRef.DoCharging;
		vDocObj.Write(DocumentWriteMode.Posting);
		vDocObj.pmWriteToResourceReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);		
EndProcedure // ChangeStatus

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeStatusAction(pExtraParams) Export
	vDocRef = pExtraParams.DocRef;
	vStatusRef = pExtraParams.StatusRef;
	If ValueIsFilled(vDocRef) And ValueIsFilled(vStatusRef) Then
		// Check user permissions to change status
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditResourceReservations") Then
			If (Not ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDocRef,"Author.Department")) And tcOnServer.cmGetAttributeByRef(vDocRef,"Author") <> tcOnServer.cmGetSessionParametersAttribute("CurrentUser") 
				Or ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDocRef,"Author.Department")) And tcOnServer.cmGetAttributeByRef(vDocRef,"Author") <> tcOnServer.cmGetSessionParametersAttribute("CurrentUser") 
				And ValueIsFilled(tcOnServer.cmGetSessionParametersAttribute("CurrentUser")) And ValueIsFilled(tcOnServer.cmGetSessionParametersAttribute("CurrentUser.Department")) 
				And tcOnServer.cmGetAttributeByRef(vDocRef,"Author.Department") <> tcOnServer.cmGetSessionParametersAttribute("CurrentUser.Department")) Then
				ShowMessageBox(,NStr("en='You do not have rights to edit resource reservations!'; ru='Нет прав на редактирование брони ресурсов!'; de='Es gibt keine Rechte, die Ressourcenbuchungen zu editieren!'"));
				Return;
			EndIf;
		EndIf;
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditClosedForEditDocuments") Then
			If tcOnServer.cmGetAttributeByRef(vDocRef,"IsClosedForEdit") Then
				ShowMessageBox(,NStr("en='You do not have rights to change closed for edit document!';ru='Нет прав на изменение документа с включенным запретом редактирования!';de='Sie haben keine Rechte, das Dokument zu bearbeiten mit eingeschlossenem Bearbeitungsverbot!'"));
				Return;
			EndIf;
		EndIf;
		If ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDocRef,"ResourceReservationStatus")) And tcOnServer.cmGetAttributeByRef(vDocRef,"ResourceReservationStatus.ServicesAreDelivered") Then
			If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCompletedResourceReservations") Then
				ShowMessageBox(,NStr("en='You do not have rights to edit completed resource reservations where services are delivered!'; ru='Нет прав на редактирование завершенной брони ресурсов по которой все услуги оказаны!'; de='Es gibt keine Rechte, die geschlossen Ressourcenbuchungen zu editieren!'"));
				Return;
			EndIf;
		EndIf;
		If tcOnServer.cmGetAttributeByRef(vStatusRef,"IsGuaranteed") And GetGuaranteeTypesCount() > 0 Then
			// Ask user to choose guarantee type
			vListSettings = GetGuaranteeTypesList ();
			If vListSettings.Count() > 0 Then
				vListSettings.ShowChooseItem(New NotifyDescription("GetGuaranteeType", ThisObject, New Structure("DocRef,StatusRef", vDocRef, vStatusRef)), NStr("en='';ru='';de=''"), vListSettings);
				Return;
			EndIf;
		EndIf;
		ChangeStatus(vDocRef, vStatusRef);
		// Refresh form
		UpdatePlanner();
		
	EndIf;
EndProcedure // EditInvoiceAction

// -----------------------------------------------------------------------------
&AtServer
Function GetGuaranteeTypesList()
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	GuaranteeTypes.Ref AS Ref,
	|	GuaranteeTypes.Description AS Description
	|FROM
	|	Catalog.GuaranteeTypes AS GuaranteeTypes
	|WHERE
	|	NOT GuaranteeTypes.DeletionMark";
	vList = vQry.Execute().Unload();
	vListSettings = New ValueList();
	For Each vListSettingsRow In vList Do
		vListSettings.Add(vListSettingsRow.Ref, vListSettingsRow.Description);
	EndDo;
	Return vListSettings; 
EndFunction // ListSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure GetResourceHeight(rResourceWidth, rResourceHeight)
	rResourceWidth = 18;
	If ResourcesCount > 0 Then
		// Get spreadsheet control width in logical units
		vLogicalWidth = GetClientDisplaysInformation().Get(0).Width;
		// Calculate resource width
		rResourceWidth = Int(vLogicalWidth / ResourcesCount / 7.8);
	EndIf;
	If rResourceWidth < 10 Then
		rResourceWidth = 18;
	EndIf;
	
	rResourceHeight = 18;
	If ResourcesCount > 0 Then
		// Get spreadsheet control width in logical units
		vLogicalHeight = GetClientDisplaysInformation().Get(0).Height;
		// Calculate resource width
		rResourceHeight = Int(vLogicalHeight / ResourcesCount / 1.8);
	EndIf;
	If rResourceHeight < 10 Then
		rResourceHeight = 18;
	EndIf;
EndProcedure // GetResourceHeight

// --------------------------------------------------------------------------------
&AtServerNoContext
Function EventActivitiesAvailableAtServer()
	vEventActivities = cmGetAllEventActivities();
	If vEventActivities.Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // EventActivitiesAvailableAtServer

// -----------------------------------------------------------------------------
Procedure SetDefaultsGroupTitle()
	vTitle = NStr("en='Group'; ru='Группа'; de='Gruppe'");
	If ValueIsFilled(GuestGroup) Then
		vTitle = vTitle + ": " + TrimAll(GuestGroup);
	EndIf;
	Items.GroupDefaults.Title = vTitle;
EndProcedure // SetDefaultsGroupTitle

#EndRegion
