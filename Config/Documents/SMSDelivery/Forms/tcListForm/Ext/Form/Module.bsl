
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;

	SelHotel = SessionParameters.CurrentHotel;
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("Hotel") Then
			SelHotel = Parameters.Filter.Hotel;
		EndIf;
	EndIf;
	If ValueIsFilled(SelHotel) Then
		AttributeChangeAtServer("Hotel", SelHotel);
	Else
		ClearingAttributeAtServer("Hotel");
	EndIf;

	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
	If Not IsInRole("RightsToChooseHotel") Then
		Items.SelHotel.ReadOnly = True;
		Items.SelHotel.ChoiceButton = False;
		Items.SelHotel.ClearButton = False;
	EndIf;
	
	If Parameters.Filter.Property("ChoiceMode") Then		
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	EndIf;
	
	SetParametersDinamicList();
	
	If SessionParameters.CurrentLanguage = Catalogs.Languages.RU Then
		Items.TemplateTextRu.Visible = True;
		Items.TemplateTextEn.Visible = False;
		Items.TemplateTextDe.Visible = False;
	ElsIf SessionParameters.CurrentLanguage = Catalogs.Languages.EN Then
		Items.TemplateTextRu.Visible = False;
		Items.TemplateTextEn.Visible = True;
		Items.TemplateTextDe.Visible = False;	
	ElsIf SessionParameters.CurrentLanguage = Catalogs.Languages.DE Then
		Items.TemplateTextRu.Visible = False;
		Items.TemplateTextEn.Visible = False;
		Items.TemplateTextDe.Visible = True;
	EndIf;

	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "System.Hotel.Changed" Then
		If ValueIsFilled(pParameter) Then
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Hotel", pParameter,DataCompositionComparisonType.Equal, , True);
			If tcOnClient.IsHomePageWindow(ThisObject) Then
				vPrefix = NStr("en = 'Messages delivery: '; de = 'Versand von Mitteilungen: '; ru = 'Рассылки сообщений: '");
				tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
			EndIf;	
		EndIf;	
	EndIf;
EndProcedure // NotificationProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If tcOnClient.IsHomePageWindow(ThisObject) Then
		vPrefix = NStr("en = 'Messages delivery: '; de = 'Versand von Mitteilungen: '; ru = 'Рассылки сообщений: '");
		tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
	EndIf;	
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure TemplateSearchOnChange(pItem)
		// Reset filter
		List.Filter.Items.Clear();
		// Filter by accommodation or by room
		If ValueIsFilled(TemplateSearch) Then
			vFlt = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
			vFlt.LeftValue = new DataCompositionField("SMSTemplate");
			vFlt.ComparisonType = DataCompositionComparisonType.Equal;
			vFlt.RightValue = TemplateSearch;
			vFlt.Use = True;
		EndIf;
EndProcedure // TemplateSearchOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	If ValueIsFilled(SelHotel) Then
		AttributeChangeAtServer("Hotel", SelHotel, DataCompositionComparisonType.InHierarchy);
	Else
		ClearingAttributeAtServer("Hotel");
	EndIf;  
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(SelHotel, "BackgroundColorImportant");
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	If Not IsInRoleAtServer("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // SelHotelClearing

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure SetParametersDinamicList(pCommand="")
	vStatus = "All";
	
	If pCommand="New" Then
		vStatus = Enums.SMSDeliveryStatuses.New;
		Items.ShowAll.Check = False;
		Items.New.Check = True;
		Items.PartiallySent.Check = False;
		Items.Sent.Check = False;
	ElsIf pCommand="PartiallySent" Then
		vStatus = Enums.SMSDeliveryStatuses.PartiallySent;
		Items.ShowAll.Check = False;
		Items.New.Check = False;
		Items.PartiallySent.Check = True;
		Items.Sent.Check = False;
	ElsIf pCommand="Sent" Then	
		vStatus = Enums.SMSDeliveryStatuses.Sent;
		Items.ShowAll.Check = False;
		Items.New.Check = False;
		Items.PartiallySent.Check = False;
		Items.Sent.Check = True;
	Else
		Items.ShowAll.Check = True;
		Items.New.Check = False;
		Items.PartiallySent.Check = False;
		Items.Sent.Check = False;
	EndIf; 
	
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "DeliveryStatus", vStatus,DataCompositionComparisonType.Equal, , ?(vStatus = "All", False, True));
	
	Items.List.Refresh();	
EndProcedure // SetParametersDinamicList

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangePage(pCommand)
	SetParametersDinamicList(pCommand.Name);
EndProcedure // ChangePage

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute,pValue,pComparisonType = Undefined)
	vComparisonType =  ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
	vValue = pValue;	
	If ValueIsFilled(vValue) Then
		vFilter = List.Filter;
		vField = New DataCompositionField(pAttribute);
		If vFilter.Items.Count() = 0 Then	
			vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
			vFilterItem.LeftValue = vField;
			vFilterItem.ComparisonType = vComparisonType;
			vFilterItem.RightValue = vValue;
			vFilterItem.Use = True;
		Else
			// Find field
			vCancel = False;
			For Each int In  vFilter.Items Do
				If  int.LeftValue = vField  Then
					// Field delete
					vFilter.Items.Delete(int);	
					// Add a new
					vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
					vFilterItem.LeftValue = vField;
					vFilterItem.ComparisonType = vComparisonType;
					vFilterItem.RightValue = vValue;
					vFilterItem.Use = True;
					vCancel = True;
					Break;
				EndIf;	
			EndDo;
			If Not vCancel Then
				// The field is not found, we add a new
				vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
				vFilterItem.LeftValue = vField;
				vFilterItem.ComparisonType = vComparisonType;
				vFilterItem.RightValue = vValue;
				vFilterItem.Use = True;
			EndIf;
		EndIf;
	EndIf;
	Items.List.Refresh();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, , , , False);
EndProcedure // ClearingAttributeAtServer 

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRoleName)
	Return IsInRole(pRoleName);
EndFunction // IsInRoleAtServer

#EndRegion
