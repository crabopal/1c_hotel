#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Filter") And TypeOf(Parameters.Filter) = Type("Structure") And Parameters.Filter.Property("Hotel") And ValueIsFilled(Parameters.Filter.Hotel) Then
		SelHotel = Parameters.Filter.Hotel;
	ElsIf Parameters.Property("Hotel") And ValueIsFilled(Parameters.Hotel) Then
		SelHotel = Parameters.Hotel;
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then	
		SelHotel = SessionParameters.CurrentHotel;
	EndIf;
	List.Parameters.SetParameterValue("qHotel", SelHotel);

	If Parameters.Property("Filter") And TypeOf(Parameters.Filter) = Type("Structure") And Parameters.Filter.Property("RoomType") And ValueIsFilled(Parameters.Filter.RoomType) Then
		SelRoomType = Parameters.Filter.RoomType;
	ElsIf Parameters.Property("RoomType") And ValueIsFilled(Parameters.RoomType) Then
		SelRoomType = Parameters.RoomType;
	EndIf;
	List.Parameters.SetParameterValue("qRoomType", SelRoomType);

	If Parameters.Property("Filter") And TypeOf(Parameters.Filter) = Type("Structure") And Parameters.Filter.Property("RoomClass") And ValueIsFilled(Parameters.Filter.RoomClass) Then
		SelRoomClass = Parameters.Filter.RoomClass;
	ElsIf Parameters.Property("RoomClass") And ValueIsFilled(Parameters.RoomClass) Then
		SelRoomClass = Parameters.RoomClass;
	EndIf;
	List.Parameters.SetParameterValue("qRoomClass", SelRoomClass);

	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
	EndIf;	 

	If Not IsInRole("Administrator") Then
		If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then 
			vMsg = NStr("en = 'You do not have rights (094) for manage accommodation templates!'; 
						|de = 'Sie haben keine Rechte (094) zum Verwalten von Unterkunftsvorlagen!'; 
						|ru = 'Нет прав (094) на управление шаблонами размещений!'");
			tcCommonFunctionOnClientServer.TextMessage(vMsg);
			ReadOnly = True;
		EndIf;	  
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure AdultsOnChange(pItem)
	If SelAdults > 0 Then
		AttributeChangeAtServer("NumberOfAdults", SelAdults);
	Else
		ClearingAttributeAtServer("NumberOfAdults");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure TeensOnChange(pItem)
	If SelTeens > 0 Then
		AttributeChangeAtServer("NumberOfTeenagers", SelTeens);
	Else
		ClearingAttributeAtServer("NumberOfTeenagers");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChildrenOnChange(pItem)
	If SelChildren > 0 Then
		AttributeChangeAtServer("NumberOfChildren", SelChildren);
	Else
		ClearingAttributeAtServer("NumberOfChildren");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure InfantsOnChange(pItem)
	If SelInfants > 0 Then
		AttributeChangeAtServer("NumberOfInfants", SelInfants);
	Else
		ClearingAttributeAtServer("NumberOfInfants");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelOnlySplitOnChange(pItem)
	If SelOnlySplit Then
		AttributeChangeAtServer("IsForFolioSplit", SelOnlySplit);
	Else
		ClearingAttributeAtServer("IsForFolioSplit");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelOnChange(pItem)
	List.Parameters.SetParameterValue("qHotel", SelHotel);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeOnChange(pItem)
	List.Parameters.SetParameterValue("qRoomType", SelRoomType);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelRoomClassOnChange(pItem)
	List.Parameters.SetParameterValue("qRoomClass", SelRoomClass);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EditRoomTypesAction(Command)
	vSelectedRefs = New ValueList();
	For Each vRow In Items.List.SelectedRows Do
		vRowData = Items.List.RowData(vRow);
		vSelectedRefs.Add(vRowData.Ref);
	EndDo;
	OpenForm("Catalog.AccommodationTemplates.Form.tcEditRoomTypesForm", New Structure("SelectedTemplates", vSelectedRefs), ThisObject);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined)
	If ValueIsFilled(pValue) Then
		vComparisonType = ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, pValue, vComparisonType, , True);
	EndIf;
EndProcedure // AttributeChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, pAttribute, , , , False);
EndProcedure // ClearingAttributeAtServer

#EndRegion        
