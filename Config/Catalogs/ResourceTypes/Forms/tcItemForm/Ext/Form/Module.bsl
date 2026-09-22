
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	cmSetFormItemsStandarts(Items, Catalogs.ResourceTypes.GetTemplate("Template"));
	If Not ValueIsFilled(Object.Hotel) Then
		Object.Hotel = SessionParameters.CurrentHotel;
	EndIf;
	// Check user rights to edit resource
	If Not cmCheckUserPermissions("HavePermissionToManageResources") Then
		ReadOnly = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionTranslationsOpening(Item, StandardProcessing)
	StandardProcessing = false;
	OpenForm("Catalog.Languages.Form.tcEditForm",New Structure("Text",Object.DescriptionTranslations),Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionInsertAutoTextResourceReservationDescription(pCommand)
	vKWList = New Valuelist();

	vKWList.Add("&EventActivity", NStr("en = 'Activity'; de = 'Aktivität'; ru = 'Действие'"));               
	vKWList.Add("&GuestGroupCode", NStr("en = 'Guest group'; de = 'Gästegrupp'; ru = 'Группа гостей'"));
	vKWList.Add("&GuestGroupDescription", NStr("en = 'Guest group description'; de = 'Beschreibung der Gästegruppe'; ru = 'Наименование группы гостей'"));
	vKWList.Add("&RoomQuotas", NStr("en = 'Allotment'; de = 'Zimmernquot'; ru = 'Квота номеров'"));
	vKWList.Add("&NumberOfPersons", NStr("en = 'Number of persons'; de = 'Personenanzahl'; ru = 'Количество человек'"));
	vKWList.Add("&Client", NStr("en = 'Client'; de = 'Kunde'; ru = 'Клиент'")); 
	vKWList.Add("&Customer", NStr("en = 'Customer'; de = 'Firme'; ru = 'Контрагент'"));
	vKWList.Add("&DateTimeFrom", NStr("en = 'Reservation time from'; de = 'Zeit des Reservierungsbeginns'; ru = 'Время начала брони'"));
	vKWList.Add("&DateTimeTo", NStr("en = 'Reservation time to'; de = 'Zeit des Reservierungsendes'; ru = 'Время окончания брони'"));
		
	ShowChooseFromMenu(New NotifyDescription("AfterChooseInsertAutoText", ThisForm), vKWList, Items.ActionInsertAutoTextResourceReservationDescription);   
EndProcedure // ActionInsertAutoTextResourceReservationDescription 

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterChooseInsertAutoText(pItem, pExtraParams) Export 
	If pItem <> Undefined Then
		Object.ResourceReservationDescriptionTemplate = Object.ResourceReservationDescriptionTemplate + " " + TrimAll(pItem.Value); 	
	EndIf;
EndProcedure // AfterChooseInsertAutoText

#EndRegion

