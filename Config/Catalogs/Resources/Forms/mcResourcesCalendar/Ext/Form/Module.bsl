
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
	PeriodCalendar 	= CurrentSessionDate();
	Hotel			= SessionParameters.CurrentHotel;
	Items.TodayPeriod.Title = Format(CurrentSessionDate(), "DF=dd.MM.yyyy");
	
	Items.ResourcePlanner.VerticalStretch = True;
	ResourcePlanner.FixDimensionsHeader = True;
	ResourcePlanner.FixTimeScaleHeader = True;
	ResourcePlanner.ItemsBehaviorWhenSpaceInsufficient = PlannerItemsBehaviorWhenSpaceInsufficient.ShowAllItems;
	
	If ValueisFilled(Hotel) Then
		SelAskForResourcesFilterByDefault = Hotel.AskForResourcesFilterByDefault;
	EndIf;
	If SelAskForResourcesFilterByDefault Then
		OnOpenMode = False;
	Else
		Items.DecorationHowToFilter.Visible = False;
	EndIf;
	
	GetAllResourceReservationStatuses();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If ResourcePlannerTimeScalePositionMonth = Undefined Then
		ResourcePlannerTimeScalePositionMonth = TimeScalePosition.Top;
	EndIf;
	If ResourcePlannerTimeScalePositionWeek = Undefined Then
		ResourcePlannerTimeScalePositionWeek = TimeScalePosition.Left;
	EndIf;
	If ResourcePlannerTimeScalePositionDay = Undefined Then
		ResourcePlannerTimeScalePositionDay = TimeScalePosition.Left;
	EndIf;
	If OnOpenMode Then
		AttachIdleHandler("ShowPlanner", 1, True);
	Else
		UpdatePlanner();
	EndIf;
	If tcOnClient.IsHomePageWindow(ThisObject) Then
		vPrefix = NStr("en = 'Resources calendar: '; de = 'Ressourcenkalender: '; ru = 'Календарь ресурсов: '");
		tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
	EndIf;
	ScaleVisibleCheck();
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
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers
 
// --------------------------------------------------------------------------------
&AtClient
Procedure PeriodCalendarOnActivateDate(pItem)
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
	Items.PeriodCalendar.Refresh();
	UpdatePlanner();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PeriodCalendarOnPeriodOutput(pItem, pPeriodAppearance)
	vColors 	= GetColorsForCalendar(pPeriodAppearance.BeginOfPeriod, pPeriodAppearance.EndOfPeriod, Hotel, ResourceType, Resource);
	For Each vDate In pPeriodAppearance.Dates Do
		For Each vColor In vColors Do 
			If vDate.Date >= BegOfDay(vColor.DateTimeFrom) and vDate.Date <= EndOfDay(vColor.DateTimeTo) Then
				vDate.BackColor = vColor.Color;	
			EndIf;
		EndDo;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerBeforeStartQuickEdit(pItem, pStandardProcessing)
	pStandardProcessing = False;
	If pItem.SelectedItems.Count() > 0 Then 
		vResourceReservationRef = pItem.SelectedItems[0].Value;
		OpenForm("Document.ResourceReservation.ObjectForm", New Structure("Key", vResourceReservationRef), ThisObject, vResourceReservationRef);
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerBeforeStartEdit(pItem, pNewItem, pStandardProcessing)
	pStandardProcessing = False;
	If pItem.SelectedItems.Count() > 0 Then 
		vResourceReservationRef = pItem.SelectedItems[0].Value;
		OpenForm("Document.ResourceReservation.ObjectForm", New Structure("Key", vResourceReservationRef), ThisObject, vResourceReservationRef);
	EndIf;
EndProcedure // ResourcePlannerBeforeStartEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerBeforeCreate(pItem, pBegin, pEnd, pValues, pText, pStandardProcessing)
	pStandardProcessing = False;
	// This is one click over empty period
	If ResourcePlannerScale = 2 And (pEnd - pBegin) = 3600 Then
		Return;
	ElsIf ResourcePlannerScale = 1 And (pEnd - pBegin) = (3 * 3600) Then
		Return;
	ElsIf ResourcePlannerScale = 0 And (pEnd - pBegin) = (24 * 3600) Then
		Return;
	EndIf;
	If pBegin + 60 * 60 <= pEnd And (pValues.Count() > 0 And ValueIsFilled(pValues["Resources"]) Or ResourcePlannerScale = 0) Then
		vParams = New Structure("DateTimeFrom, DateTimeTo, Hotel, Resource, FillingValues, GuestGroup");
		vResource = pValues["Resources"];
		If Not ValueIsFilled(vResource) And ValueIsFilled(Resource) Then
			vResource = Resource;
		EndIf;	
		vParams.DateTimeFrom 	= pBegin;
		vParams.DateTimeTo 		= pEnd;
		vParams.Hotel 			= Hotel;
		vParams.Resource 		= vResource;
		vParams.GuestGroup 		= GuestGroup;
		vParams.FillingValues 	= New Structure("NotDefaultValues", True);
		OpenForm("Document.ResourceReservation.ObjectForm", vParams, ThisObject);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerOnEditEnd(pItem, pNewItem, pCancelEdit)
	pCancelEdit = True;
EndProcedure // ResourcePlannerOnEditEnd

// --------------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerCommandGenerateProcessing(pItem, pParameters, pCommands, pDefaultCommand)
	#IF NOT ThickClientOrdinaryApplication THEN
		vCode = 
		"vNum = 0;
		|For Each vCommand In pCommands Do
		|	If vCommand.Command = PlannerStandardCommand.DeleteItems Then
		|		pCommands.Delete(vNum);		
		|	EndIf;
		|	If vCommand.Command = PlannerStandardCommand.CreateItem Then
		|		pCommands.Delete(vNum);		
		|	EndIf;
		|	vNum = vNum + 1;
		|EndDo;
		|If pParameters.Items <> Undefined Then
		|	vNewCommand = New PlannerCommandDescription(New NotifyDescription(""CopyResourceAction"", ThisObject, New Structure(""DocRef"", pParameters.Items[0].Value)),
		|												NStr(""ru='Копировать';en='Copy';de='Kopieren'""));
		|	vNewCommand.Picture = PictureLib.Copy;
		|	pCommands.Add(vNewCommand);
		|
		|	pCommands.Add(New PlannerCommandDescription(Undefined,""""));
		|	vNewCommand = New PlannerCommandDescription(New NotifyDescription(),
		|												NStr(""en='Open:';ru='Открыть:';de='Öffnen:'""));
		|	vNewCommand.Picture = PictureLib.Empty;
		|	vNewCommand.Enabled = False;
		|	pCommands.Add(vNewCommand);
		|		
		|	vNewCommand = New PlannerCommandDescription(New NotifyDescription(""FindChargingFolioAction"", ThisObject, New Structure(""DocRef"", pParameters.Items[0].Value)),
		|												NStr(""en='Folios list';ru='Список лицевых счетов';de='Liste der Personenkonten'""));
		|	vNewCommand.Picture = PictureLib.Calculator;
		|	pCommands.Add(vNewCommand);
		|	
		|	vNewCommand = New PlannerCommandDescription(New NotifyDescription(""GuestGroupReservationsAction"", ThisObject, New Structure(""DocRef"", pParameters.Items[0].Value)),
		|												NStr(""en='Guest group room reservations list';ru='Список брони номеров по группе';de='Liste für Ressourcen nach Gruppen'""));
		|	vNewCommand.Picture = PictureLib.DocumentJournal;
		|	pCommands.Add(vNewCommand);
		|	
		|	vNewCommand = New PlannerCommandDescription(New NotifyDescription(""ResourceReservationsAction"", ThisObject, New Structure(""DocRef"", pParameters.Items[0].Value)),
		|												NStr(""en='Guest group resource list';ru='Список ресурсов по группе';de='Liste für Zimmerreservierung nach Gruppen'""));
		|	vNewCommand.Picture = PictureLib.PaperClip;
		|	pCommands.Add(vNewCommand);
		|	
		|	vNewCommand = New PlannerCommandDescription(New NotifyDescription(""GuestGroupItemAction"", ThisObject, New Structure(""DocRef"", pParameters.Items[0].Value)),
		|												NStr(""en='Group details';ru='Карточка группы';de='Gruppenkarte'""));
		|	vNewCommand.Picture = PictureLib.Catalog;
		|	pCommands.Add(vNewCommand);
		|	
		|	pCommands.Add(New PlannerCommandDescription(Undefined,""""));
		|	vNewCommand = New PlannerCommandDescription(New NotifyDescription(),
		|												NStr(""en='Change status to:';ru='Изменить статус на:';de='Status ändern zu:'""));
		|	vNewCommand.Picture = PictureLib.Empty;
		|	vNewCommand.Enabled = False;
		|	pCommands.Add(vNewCommand);
		|
		|	If Statuses.Count() > 0 Then
		|		For Each vStatusesRow In Statuses Do
		|			If vStatusesRow.ResourceReservationStatus = tcOnServer.cmGetAttributeByRef(pParameters.Items[0].Value, ""ResourceReservationStatus"") Then
		|				Continue;
		|			EndIf;
		|			vNewCommand = New PlannerCommandDescription(New NotifyDescription(""ChangeStatusAction"", ThisObject, New Structure(""DocRef, StatusRef"", pParameters.Items[0].Value,vStatusesRow.ResourceReservationStatus)),		
		|													TrimAll(vStatusesRow.Description));
		|			If vStatusesRow.IsActive Then
		|				If vStatusesRow.ServicesAreDelivered Then
		|					vNewCommand.Picture = PictureLib.Pin;
		|				ElsIf vStatusesRow.DoCharging Then
		|					vNewCommand.Picture = PictureLib.AccumulationRegister;
		|				ElsIf vStatusesRow.IsGuaranteed Then
		|					vNewCommand.Picture = PictureLib.CheckMark;
		|				Else
		|					vNewCommand.Picture = PictureLib.IsActive;
		|				EndIf;
		|			Else
		|				vNewCommand.Picture = PictureLib.IsNotActive;
		|			EndIf;
		|		
		|			pCommands.Add(vNewCommand);
		|		EndDo;
		|	EndIf;
		|EndIf;";
		Execute(vCode);
	#ENDIF
EndProcedure // ResourcePlannerCommandGenerateProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure ResourcePlannerBeforeDelete(pItem, pCancel)
	pCancel = True;
EndProcedure // ResourcePlannerBeforeDelete

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


#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure NextPeriod(pCommand)
	If ResourcePlannerScale = 0 Then
		PeriodCalendar 	= AddMonth(PeriodCalendar, 1);
	ElsIf ResourcePlannerScale = 1 Then
		PeriodCalendar	= BegOfDay(PeriodCalendar) + 7*24*3600;
	ElsIf ResourcePlannerScale = 2 Then
		PeriodCalendar	= BegOfDay(PeriodCalendar) + 1*24*3600;
	EndIf;
	UpdatePlanner();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure PrevPeriod(pCommand)
	If ResourcePlannerScale = 0 Then
		PeriodCalendar 	= AddMonth(PeriodCalendar, -1);
	ElsIf ResourcePlannerScale = 1 Then
		PeriodCalendar	= BegOfDay(PeriodCalendar) - 7*24*3600;
	ElsIf ResourcePlannerScale = 2 Then
		PeriodCalendar	= BegOfDay(PeriodCalendar) - 1*24*3600;
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
Procedure ChangeTimeScalePosition(pCommand)
	If ResourcePlannerScale = 0 Then
		If ResourcePlannerTimeScalePositionMonth = TimeScalePosition.Top Then
			ResourcePlannerTimeScalePositionMonth = TimeScalePosition.Left; 
		Else
			ResourcePlannerTimeScalePositionMonth = TimeScalePosition.Top;
		EndIf;
	ElsIf ResourcePlannerScale = 1 Then
		If ResourcePlannerTimeScalePositionWeek = TimeScalePosition.Top Then
			ResourcePlannerTimeScalePositionWeek = TimeScalePosition.Left; 
		Else
			ResourcePlannerTimeScalePositionWeek = TimeScalePosition.Top;
		EndIf;
	ElsIf ResourcePlannerScale = 2 Then
		If ResourcePlannerTimeScalePositionDay = TimeScalePosition.Top Then
			ResourcePlannerTimeScalePositionDay = TimeScalePosition.Left; 
		Else
			ResourcePlannerTimeScalePositionDay = TimeScalePosition.Top;
		EndIf;
	EndIf;
	UpdatePlanner();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenResourceReservationsList(pCommand)
	OpenForm("Document.ResourceReservation.ListForm", New Structure("SelHotel, SelDate, SelResourceType, SelResource", Hotel, PeriodCalendar, ResourceType, Resource), ThisObject);
EndProcedure // OpenResourceReservationsList

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowFiletGroup(pCommand) 
	Items.ShowFiletGroup.Check = Not Items.ShowFiletGroup.Check;
	If Items.ShowFiletGroup.Check Then
		Items.Pages.CurrentPage = Items.PageFilter;	
	Else
		Items.Pages.CurrentPage = Items.GroupPlanner;	
	EndIf;
EndProcedure // ShowFiletGroup

// --------------------------------------------------------------------------------
&AtClient
Procedure ScaleMonth(pCommand)
	ResourcePlannerScale = 0;
	PrepareResourcePlanner();
	ScaleVisibleCheck();
EndProcedure // ScaleMonth

// --------------------------------------------------------------------------------
&AtClient
Procedure ScaleWeek(pCommand)
	ResourcePlannerScale = 1;
	PrepareResourcePlanner();
	ScaleVisibleCheck();
EndProcedure // ScaleWeek

// --------------------------------------------------------------------------------
&AtClient
Procedure ScaleDay(pCommand)
	ResourcePlannerScale = 2;
	PrepareResourcePlanner();
	ScaleVisibleCheck();
EndProcedure // ScaleDay

// --------------------------------------------------------------------------------
&AtClient
Procedure ShowCalendar(pCommand)
	Items.FormShowCalendar.Check = Not Items.FormShowCalendar.Check;
	If Items.FormShowCalendar.Check Then
		Items.Pages.CurrentPage = Items.PageCalendar;	
	Else
		Items.Pages.CurrentPage = Items.GroupPlanner;	
	EndIf;	
EndProcedure // ShowCalendar

#EndRegion

#Region Private

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
	vScale 		= 1;
	
	// Time scale items
	If ResourcePlannerScale = 0 Then
		vTS0 = ResourcePlanner.TimeScale.Items.Get(0);
		vTS0.TextColor = WebColors.DimGray;
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
		vTS0.TextColor = WebColors.DimGray;
		vTS1.TextColor = WebColors.DimGray;	
	EndIf;
	
	If ResourcePlannerScale = 0 Then
		vPeriodFrom	= BegOfDay(vPeriodFrom);
		vPeriodTo	= EndOfDay(vPeriodFrom) + 31 * 24 * 3600;
		ResourcePlanner.BeginOfRepresentationPeriod = vPeriodFrom;
		ResourcePlanner.EndOfRepresentationPeriod 	= vPeriodTo;
		ResourcePlanner.PeriodicVariantUnit 		= TimeScaleUnitType.Day;
		vScale			= (vPeriodTo - vPeriodFrom) / (24 * 3600) + 1;
		vTS0.Unit		= TimeScaleUnitType.Day;
		vTS0.Repetition = 1;
		vTS0.Format 	= "DF='dd.MM'";
		ResourcePlanner.TimeScale.Location 	= ResourcePlannerTimeScalePositionMonth;
		ResourcePlanner.ShowCurrentDate 	= False;
	ElsIf ResourcePlannerScale = 1 Then
		vPeriodFrom		= BegOfWeek(vPeriodFrom);
		vPeriodTo		= EndOfDay(vPeriodFrom + 24 * 60 * 60 * 6);
		ResourcePlanner.BeginOfRepresentationPeriod = vPeriodFrom;
		ResourcePlanner.EndOfRepresentationPeriod 	= vPeriodTo;
		ResourcePlanner.PeriodicVariantUnit 		= TimeScaleUnitType.Hour;
		vScale			= (vPeriodTo - vPeriodFrom) / (24 * 60);
		
		// Reverse time scales
		If ResourcePlannerTimeScalePositionMonth = TimeScalePosition.Right Or ResourcePlannerTimeScalePositionMonth = TimeScalePosition.Bottom Then
			vTS1.Unit		= TimeScaleUnitType.Day;
			vTS1.Repetition = 1;
			vTS1.Format 	= "DF='ddd dd'";
			
			vTS0.Unit		= TimeScaleUnitType.Hour;
			vTS0.Repetition = 3;
			vTS0.Format 	= "DF=HH:mm";
		Else
			vTS0.Unit		= TimeScaleUnitType.Day;
			vTS0.Repetition = 1;
			vTS0.Format 	= "DF='ddd dd'";
			
			vTS1.Unit		= TimeScaleUnitType.Hour;
			vTS1.Repetition = 3;
			vTS1.Format 	= "DF=HH:mm";
		EndIf;
		ResourcePlanner.TimeScale.Location 	= ResourcePlannerTimeScalePositionWeek;
		ResourcePlanner.ShowCurrentDate 	= True;
	ElsIf ResourcePlannerScale = 2 Then
		vPeriodTo	= EndOfDay(vPeriodFrom);
		ResourcePlanner.BeginOfRepresentationPeriod = vPeriodFrom;
		ResourcePlanner.EndOfRepresentationPeriod 	= vPeriodTo;
		ResourcePlanner.PeriodicVariantUnit 		= TimeScaleUnitType.Hour;
		vScale			= 24;
		
		// Reverse time scales
		If ResourcePlannerTimeScalePositionMonth = TimeScalePosition.Right or ResourcePlannerTimeScalePositionMonth = TimeScalePosition.Bottom Then
			vTS1.Unit		= TimeScaleUnitType.Day;
			vTS1.Repetition = 1;
			vTS1.Format 	= "DF='ddd dd'";
			
			vTS0.Unit		= TimeScaleUnitType.Hour;
			vTS0.Repetition = 1;
			vTS0.Format 	= "DF=HH:mm";
		Else
			vTS0.Unit		= TimeScaleUnitType.Day;
			vTS0.Repetition = 1;
			vTS0.Format 	= "DF='ddd dd'";
			
			vTS1.Unit		= TimeScaleUnitType.Hour;
			vTS1.Repetition = 1;
			vTS1.Format 	= "DF=HH:mm";
		EndIf;
		ResourcePlanner.TimeScale.Location 	= ResourcePlannerTimeScalePositionDay;
		ResourcePlanner.ShowCurrentDate 	= True;
	EndIf;	
	ResourcePlanner.PeriodicVariantRepetition 	= vScale;		
		
	ResourcePlanner.CurrentRepresentationPeriods.Clear();
	ResourcePlanner.CurrentRepresentationPeriods.Add(vPeriodFrom, vPeriodTo);
	ResourcePlanner.AlignItemBoundariesByTimeScale = False;
	
	ResourcePlanner.BackgroundIntervals.Clear();
	If ResourcePlannerScale = 0  or  ResourcePlannerScale = 1 Then
		vCurPer = EndOfWeek(vPeriodFrom) - 2 * 24 * 3600 + 1; // Beg of saturday
		While vCurPer < vPeriodTo Do
			vWeekEnd 		= ResourcePlanner.BackgroundIntervals.Add(vCurPer,EndOfWeek(vCurPer));
			vWeekEnd.Color 	= WebColors.SeaShell;
			vCurPer 		= vCurPer + 7 * 24 * 3600;
		EndDo;
		If ResourcePlannerScale = 0 Then
			vCurrentDate 		= ResourcePlanner.BackgroundIntervals.Add(BegOfDay(CurrentSessionDate()), EndOfDay(CurrentSessionDate()));
			vCurrentDate.Color 	= WebColors.LightYellow;	
		EndIf;
	EndIf;
	
	// Clear planner
	ResourcePlanner.Items.Clear();
	ResourcePlanner.ItemsTimeRepresentation = PlannerItemsTimeRepresentation.DontDisplay;
	ResourcePlanner.Dimensions.Clear();
	
	vDimension = ResourcePlanner.Dimensions.Add("Resources");
	vDimension.Text 	= NStr("en = 'Resources'; ru = 'Ресурсы'; de = 'Ressource'");
	
	vPresentationText = "";
	If Month(vPeriodFrom) <> Month(vPeriodTo) Then
		If Year(vPeriodFrom) <> Year(vPeriodTo) Then
			vPresentationText = Format(vPeriodFrom,"DF='MMMM yyyy'") + "-" + Format(vPeriodTo, "DF='MMMM yyyy'");
		Else
			vPresentationText = Format(vPeriodFrom,"DF=MMMM") + "-" + Format(vPeriodTo, "DF='MMMM yyyy'");	
		EndIf;
	Else
		vPresentationText = Format(vPeriodTo, "DF='MMMM yyyy'"); 
	EndIf;
	Items.Text_CurrentPeriod.Title = vPresentationText;
	
	If Not Items.DecorationHowToFilter.Visible Then
		FillResourcePlanner();
	EndIf;
	Items.FormShowCalendar.Title = Format(PeriodCalendar, "DF=dd.MM.yyyy");
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
	If OnOpenMode Then
		vResources = New ValueTable();
		vWorkingTimes = New ValueTable();
	Else
		vResources = GetResources(Hotel, ResourceType, Resource);
		vWorkingTimes = GetWorkingTimes(ResourcePlanner.BeginOfRepresentationPeriod, ResourcePlanner.EndOfRepresentationPeriod, Hotel, ResourceType, Resource);
	EndIf;
	For Each vResourceRow In vResources Do
		itemRes = vDimension.Items.Find(vResourceRow.Resource);
		If itemRes = Undefined Then
			itemRes = vDimension.Items.Add(vResourceRow.Resource);
			itemRes.TextColor = WebColors.Black;
			itemRes.BackColor = WebColors.White;
			itemRes.Value = vResourceRow.Resource;
			itemRes.Text = TrimAll(vResourceRow.Resource);
			AddResourceMaximumNumberOfPersonsAndPrice(itemRes.Text, vResourceRow.Resource);
		EndIf;
		
		If Not vResourceRow.Resource.RoundTheClockOperation Then
			vNotWorkingPeriods = GetNotWorkingPeriods(vWorkingTimes, vResourceRow.Resource.Calendar);
			vDims = New Map;
			vDims.Insert("Resources", vResourceRow.Resource);
			For Each vPeriodRow In vNotWorkingPeriods Do
				vNotWorkingPeriod = ResourcePlanner.BackgroundIntervals.Add(vPeriodRow.PeriodFrom, vPeriodRow.PeriodTo);
				vNotWorkingPeriod.Color = WebColors.LightGray;
				vNotWorkingPeriod.DimensionValues = New FixedMap(vDims);
			EndDo;
		EndIf;
	EndDo;
	
	vResourceReservations 	= GetResourceReservations(ResourcePlanner.BeginOfRepresentationPeriod, ResourcePlanner.EndOfRepresentationPeriod, Hotel, ResourceType, Resource);
	Items.PeriodCalendar.SelectedDates.Clear();
	For Each vResourceReservationRow In vResourceReservations Do
		vItem = ResourcePlanner.Items.Add(vResourceReservationRow.DateTimeFrom, vResourceReservationRow.DateTimeTo);
		vDims = New Map;
		vDims.Insert("Resources", vResourceReservationRow.Resource);
		vResourcePresentation = GetPresentationForResourceReservation(vResourceReservationRow);
		vItem.DimensionValues = New FixedMap(vDims);
		vItem.ToolTip = "" + vResourcePresentation.Text;
		vItem.Text = "" + vResourcePresentation.Text;
		vItem.BackColor = vResourcePresentation.Color;
		vItem.BorderColor = vResourcePresentation.BorderColor; 
		vItem.Value = vResourceReservationRow.ResourceReservation;
	EndDo;	
EndProcedure // FillResourcePlanner

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdatePlanner()
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
	PrepareResourcePlanner();
EndProcedure // UpdatePlanner

// --------------------------------------------------------------------------------
&AtClient
Procedure ScaleVisibleCheck()
	If ResourcePlannerScale = 0 Then
		Items.FormScaleMonth.Check = True;
		Items.FormScaleWeek.Check = False;
		Items.FormScaleDay.Check = False;
	ElsIf ResourcePlannerScale = 1 Then
		Items.FormScaleMonth.Check = False;
		Items.FormScaleWeek.Check = True;
		Items.FormScaleDay.Check = False;
	ElsIf ResourcePlannerScale = 2 Then
		Items.FormScaleMonth.Check = False;
		Items.FormScaleWeek.Check = False;
		Items.FormScaleDay.Check = True;
	EndIf;
EndProcedure // ScaleVisibleCheck

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
	|	ResourceReservationStatuses.IsActive,
	|	ResourceReservationStatuses.IsGuaranteed,
	|	ResourceReservationStatuses.DoCharging,
	|	ResourceReservationStatuses.ServicesAreDelivered
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
	|	ResourceReservations.Resource AS ResourceSortCode,
	|	ResourceReservations.ResourceType.SortCode AS ResourceTypeSortCode,
	|	ResourceReservations.Recorder AS ResourceReservation,
	|	ResourceReservations.Hotel,
	|	ResourceReservations.Customer,
	|	ResourceReservations.Contract,
	|	ResourceReservations.Agent,
	|	ResourceReservations.GuestGroup,
	|	ResourceReservations.ResourceReservationStatus,
	|	CASE
	|		WHEN ResourceReservations.DateTimeFrom < &qPeriodFrom
	|			THEN &qPeriodFrom
	|		ELSE ResourceReservations.DateTimeFrom
	|	END AS DateTimeFrom,
	|	ResourceReservations.Duration,
	|	CASE
	|		WHEN ResourceReservations.DateTimeTo > &qPeriodTo
	|			THEN &qPeriodTo
	|		ELSE ResourceReservations.DateTimeTo
	|	END AS DateTimeTo,
	|	ResourceReservations.NumberOfPersons,
	|	ResourceReservations.Client,
	|	ResourceReservations.Company,
	|	ResourceReservations.ChargingFolio,
	|	ResourceReservations.PlannedPaymentMethod,
	|	ResourceReservations.MarketingCode,
	|	ResourceReservations.SourceOfBusiness,
	|	ResourceReservations.DiscountCard,
	|	ResourceReservations.DiscountType,
	|	ResourceReservations.Discount,
	|	ResourceReservations.CreditCard,
	|	ResourceReservations.CustomerType,
	|	ResourceReservations.ClientType,
	|	ResourceReservations.Recorder.ContactPerson AS ContactPerson,
	|	ResourceReservations.Recorder.Remarks AS Remarks,
	|	ResourceReservations.Period AS PointInTime,
	|	ResourceReservations.Recorder.ResourceTableConfiguration AS ResourceTableConfiguration
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
	|	PointInTime";
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
		vResult.Add(New Structure("DateTimeFrom, DateTimeTo, Color", vResource.DateTimeFrom, vResource.DateTimeTo, New Color(219, 215, 210)));
	EndDo;
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetPresentationForResourceReservation(pResourceReservationRow)
	vResult = New Structure("Text, Comments, Color, BorderColor", "", "", New Color, StyleColors.ResourceReservationBorderColor);	
	If ValueIsFilled(pResourceReservationRow.ResourceReservationStatus) Then
		If pResourceReservationRow.ResourceReservationStatus.IsGuaranteed Then
			vResult.BorderColor = StyleColors.GuaranteedResourceReservationBorderColor;
		EndIf;
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
	// Add comment with resource reservation messages
	vMessages = cmGetMessagesForObject(pResourceReservationRow.ResourceReservation);
	If vMessages.Count() > 0 Then
		vMessagesStr = cmGetMessagesPresentationForObject(vMessages, pResourceReservationRow.ResourceReservation);
		vResult.Comments = vMessagesStr;
	EndIf;
	vResult.Text = GetResourceReservationDescription(pResourceReservationRow);
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetResourceReservationDescription(pResourceReservationRow)
	vDescription = "";
	If BegOfDay(pResourceReservationRow.DateTimeFrom) <> BegOfDay(pResourceReservationRow.DateTimeTo) Then
		vDescription = vDescription + "[" + Format(pResourceReservationRow.DateTimeFrom, "DF='dd.MM HH:mm'") + "-" + Format(pResourceReservationRow.DateTimeTo, "DF='dd.MM HH:mm'") + "]"  + Chars.LF;
	Else
		vDescription = vDescription + "[" + Format(pResourceReservationRow.DateTimeFrom, "DF=HH:mm") + "-" + Format(pResourceReservationRow.DateTimeTo, "DF=HH:mm") + "]" + Chars.LF;
	EndIf;
	If ValueIsFilled(pResourceReservationRow.Customer) Then
		vDescription = vDescription + TrimAll(pResourceReservationRow.Customer) + Chars.LF;
	EndIf;
	If ValueIsFilled(pResourceReservationRow.Contract) Then
		vDescription = vDescription + TrimAll(pResourceReservationRow.Contract) + Chars.LF;
	EndIf;
	If ValueIsFilled(pResourceReservationRow.Client) Then
		vDescription = vDescription + TrimAll(pResourceReservationRow.Client) + Chars.LF;
	EndIf;
	If pResourceReservationRow.NumberOfPersons > 0 Then
		vDescription = vDescription + NStr("en='Prs. ';ru='Чел. ';de='Prs. '") + TrimAll(pResourceReservationRow.NumberOfPersons) + Chars.LF;
	EndIf;
	If ValueIsFilled(pResourceReservationRow.GuestGroup) Then
		vDescription = vDescription + NStr("en='Gr. '; ru='Гр. '; de='Gr. '") + TrimAll(pResourceReservationRow.GuestGroup.Code) + ?(IsBlankString(pResourceReservationRow.GuestGroup.Description), "", " - " + TrimAll(pResourceReservationRow.GuestGroup.Description)) + Chars.LF;
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
	|	CalendarDays.AccountingDate AS Period,
	|	CalendarDays.Calendar AS Calendar,
	|	CalendarDays.CalendarDayType AS CalendarDayType,
	|	CalendarDays.Timetable AS Timetable,
	|	ISNULL(WorkingTimes.TimeFrom, &qEmptyDate) AS TimeFrom,
	|	ISNULL(WorkingTimes.TimeTo, &qEmptyDate) AS TimeTo
	|FROM
	|	InformationRegister.CalendarDays.SliceLast(
	|			,
	|			Calendar IN
	|					(SELECT
	|						Resources.Calendar
	|					FROM
	|						Catalog.Resources AS Resources
	|					WHERE
	|						NOT Resources.DeletionMark
	|						AND Resources.Hotel IN HIERARCHY (&qHotel)
	|						AND (Resources.Owner IN HIERARCHY (&qResourceType)
	|							OR &qResourceTypeIsEmpty)
	|						AND (Resources.Ref IN HIERARCHY (&qResource)
	|							OR &qResourceIsEmpty)
	|					GROUP BY
	|						Resources.Calendar)
	|				AND AccountingDate >= &qPeriodFrom
	|				AND AccountingDate < &qPeriodTo) AS CalendarDays
	|		LEFT JOIN Catalog.Timetables.WorkingTimes AS WorkingTimes
	|		ON CalendarDays.Timetable = WorkingTimes.Ref
	|
	|ORDER BY
	|	CalendarDays.AccountingDate,
	|	Calendar,
	|	TimeFrom";
	vQry.SetParameter("qPeriodFrom", pPeriodFrom);
	vQry.SetParameter("qPeriodTo", pPeriodTo);
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qHotel", pHotel);
	//vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qResourceType", pResourceType);
	vQry.SetParameter("qResourceTypeIsEmpty", Not ValueIsFilled(pResourceType));
	vQry.SetParameter("qResource", pResource);
	vQry.SetParameter("qResourceIsEmpty", Not ValueIsFilled(pResource));
	Return vQry.Execute().Unload();
EndFunction // GetWorkingTimes

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetNotWorkingPeriods(pWorkingTimes, pCalendar)
	vResult = New ValueTable;
	vResult.Columns.Add("PeriodFrom");
	vResult.Columns.Add("PeriodTo");
	vDayWorkingTimes = pWorkingTimes.FindRows(New Structure("Calendar", pCalendar));
	For Each vDayWorkingTimesRow In vDayWorkingTimes Do
		If ValueIsFilled(vDayWorkingTimesRow.Timetable) Then
			vStartOfCurWorkingPeriod 	= BegOfDay(vDayWorkingTimesRow.Period) + (vDayWorkingTimesRow.TimeFrom - BegOfDay(vDayWorkingTimesRow.TimeFrom));
			vEndOfCurWorkingPeriod 		= BegOfDay(vDayWorkingTimesRow.Period) + (vDayWorkingTimesRow.TimeTo - BegOfDay(vDayWorkingTimesRow.TimeTo));
			If BegOfDay(vDayWorkingTimesRow.Period) < vStartOfCurWorkingPeriod Then
				vNewRow = vResult.Add();
				vNewRow.PeriodFrom 	= BegOfDay(vDayWorkingTimesRow.Period);
				vNewRow.PeriodTo 	= vStartOfCurWorkingPeriod - 1;
			EndIf;	
			If EndOfDay(vDayWorkingTimesRow.Period) > vEndOfCurWorkingPeriod Then
				vNewRow = vResult.Add();
				vNewRow.PeriodFrom 	= vEndOfCurWorkingPeriod + 1;
				vNewRow.PeriodTo 	= EndOfDay(vDayWorkingTimesRow.Period);
			EndIf;
		EndIf;
	EndDo;
	Return vResult;
EndFunction // GetNotWorkingPeriods

// -----------------------------------------------------------------------------
&AtClient
Procedure CopyResourceAction(pExtraParams) Export
	If ValueIsFilled(pExtraParams.DocRef) Then
		vParametersStructure = New Structure("SelDocRef", pExtraParams.DocRef);
		OpenForm("Catalog.Resources.Form.tcCopyResources", vParametersStructure, ThisObject, UUID);
	EndIf;
EndProcedure // GuestGroupItemAction

// -----------------------------------------------------------------------------
&AtClient
Procedure FindChargingFolioAction(pExtraParams) Export 
	If ValueIsFilled(pExtraParams.DocRef) Then
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
			#IF NOT MobileClient THEN 
				OpenForm("Document.Reservation.Form.tcReservationListForm", vParametersStructure, ThisObject, UUID);
			#ELSE
				OpenForm("Document.Reservation.Form.mcReservationListForm", vParametersStructure, ThisObject, UUID);	
			#ENDIF
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
			If (Not ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDocRef,"Author.Department")) And tcOnServer.cmGetAttributeByRef(vDocRef,"Author") <> tcOnServer.cmGetSessionParametersAttribute("CurrentUser") Or 
			   ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDocRef, "Author.Department")) And tcOnServer.cmGetAttributeByRef(vDocRef,"Author") <> tcOnServer.cmGetSessionParametersAttribute("CurrentUser") And 
			   ValueIsFilled(tcOnServer.cmGetSessionParametersAttribute("CurrentUser")) And ValueIsFilled(tcOnServer.cmGetSessionParametersAttribute("CurrentUser.Department")) And 
			   tcOnServer.cmGetAttributeByRef(vDocRef,"Author.Department") <> tcOnServer.cmGetSessionParametersAttribute("CurrentUser.Department")) Then
				ShowMessageBox(, NStr("en='You do not have rights to edit resource reservations!'; ru='Нет прав на редактирование брони ресурсов!'; de='Es gibt keine Rechte, die Ressourcenbuchungen zu editieren!'"));
				Return;
			EndIf;
		EndIf;
		If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditClosedForEditDocuments") Then
			If tcOnServer.cmGetAttributeByRef(vDocRef,"IsClosedForEdit") Then
				ShowMessageBox(, NStr("en='You do not have rights to change closed for edit document!';ru='Нет прав на изменение документа с включенным запретом редактирования!';de='Sie haben keine Rechte, das Dokument zu bearbeiten mit eingeschlossenem Bearbeitungsverbot!'"));
				Return;
			EndIf;
		EndIf;
		If ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDocRef, "ResourceReservationStatus")) And tcOnServer.cmGetAttributeByRef(vDocRef,"ResourceReservationStatus.ServicesAreDelivered") Then
			If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToEditCompletedResourceReservations") Then
				ShowMessageBox(, NStr("en='You do not have rights to edit completed resource reservations where services are delivered!'; ru='Нет прав на редактирование завершенной брони ресурсов по которой все услуги оказаны!'; de='Es gibt keine Rechte, die geschlossen Ressourcenbuchungen zu editieren!'"));
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
	vListSettings = new ValueList();
	For Each vListSettingsRow In vList Do
		vListSettings.Add(vListSettingsRow.Ref, vListSettingsRow.Description);
	EndDo;
	Return vListSettings; 
EndFunction // ListSettings

#EndRegion
