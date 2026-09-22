
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;

	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	If not Parameters.Filter.Property("Hotel") Then
		SelHotel = SessionParameters.CurrentHotel;
		
		vArray = New Array;
		vArray.Add(SelHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel",vArray);
	EndIf;
	
	If Parameters.Property("RoomQuota") Then
		SelRoomQuota = Parameters.RoomQuota;
		SelRoomQuotaOnChangeAtServer();
	EndIf;
	If Parameters.Property("SelEmployee") Then
		SelEmployee = Parameters.SelEmployee;
		SelEmployeeOnChangeAtServer();
	EndIf;
	If Parameters.Property("SelHistoryFrom") Then
		SelHistoryTo = Parameters.SelHistoryTo;
		SelHistoryFrom = Parameters.SelHistoryFrom;
		SelHistoryFromOnChangeAtServer();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SelCustomerOnChange(Item)
	SelCustomerOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelAgentOnChange(Item)
	SelAgentOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelContractOnChange(Item)
	SelContractOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelRoomQuotaOnChange(Item)
	SelRoomQuotaOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelRoomTypeOnChange(Item)
	SelRoomTypeOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelRoomOnChange(Item)
	SelRoomOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelEmployeeOnChange(Item)
	SelEmployeeOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelRoomStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	vParametrs = New Structure();
	vParametrs.Insert("ChoiceMode", True);
	If ValueIsFilled(SelRoomType) Then
		vParametrs.Insert("Filter", New Structure("RoomType", SelRoomType));
	EndIf;
	
	OpenForm("Catalog.Rooms.Form.tcListForm", vParametrs, Item);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelDateFromOnChange(Item)
	SelDateFromOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelDateToOnChange(Item)
	SelDateToOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelHistoryFromOnChange(Item)
	SelHistoryFromOnChangeAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SelHistoryToOnChange(Item)
	SelHistoryFromOnChangeAtServer();
EndProcedure

#EndRegion 

#Region Private

// --------------------------------------------------------------------------------  
&AtServer
Procedure ClearingAttributeAtServer(pAttribute)
	vFilter =  List.Filter;
	vValue = New DataCompositionField(pAttribute);
	vDelList = New Array;
	For Each int In vFilter.Items Do
		If int.LeftValue = vValue Then
			vDelList.Add(int);			
		EndIf;	
	EndDo;
	For Each int In vDelList Do
		vFilter.Items.Delete(int);	
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------  
&AtServer
Procedure AttributeChangeAtServer(pAttribute,pValue,pComparisonType = Undefined,pAddNew = False)
	vValue = pValue;	
	vComparisonType =  ?(pComparisonType = Undefined, DataCompositionComparisonType.Equal, pComparisonType);
	
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
			If pAddNew Then
				vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
				vFilterItem.LeftValue      = vField;
				vFilterItem.ComparisonType = vComparisonType;
				vFilterItem.RightValue     = vValue;
				vFilterItem.Use            = True;
			Else
				// Find field
				vCancel = False;
				For Each int In  vFilter.Items Do
					If  int.LeftValue = vField  Then
						// Field delete
						vFilter.Items.Delete(int);	
						// Add a new
						vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
						vFilterItem.LeftValue      = vField;
						vFilterItem.ComparisonType = vComparisonType;
						vFilterItem.RightValue     = vValue;
						vFilterItem.Use            = True;
						vCancel                    = True;
						Break;
					EndIf;	
				EndDo;
				If Not vCancel Then
					// The field is not found, we add a new
					vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
					vFilterItem.LeftValue      = vField;
					vFilterItem.ComparisonType = vComparisonType;
					vFilterItem.RightValue     = vValue;
					vFilterItem.Use            = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelCustomerOnChangeAtServer()
	If not ValueIsFilled(SelCustomer) Then
		ClearingAttributeAtServer("Customer");
	Else 
		AttributeChangeAtServer("Customer", SelCustomer);
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelAgentOnChangeAtServer()
	If not ValueIsFilled(SelAgent) Then
		ClearingAttributeAtServer("Agent");
	Else 
		AttributeChangeAtServer("Agent", SelAgent);
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelContractOnChangeAtServer()
	If not ValueIsFilled(SelContract) Then
		ClearingAttributeAtServer("Contract");
	Else 
		AttributeChangeAtServer("Contract", SelContract);
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelRoomQuotaOnChangeAtServer()
	If not ValueIsFilled(SelRoomQuota) Then
		ClearingAttributeAtServer("RoomQuota");
	Else 
		AttributeChangeAtServer("RoomQuota", SelRoomQuota);
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelRoomTypeOnChangeAtServer()
	If not ValueIsFilled(SelRoomType) Then
		ClearingAttributeAtServer("RoomType");
	Else 
		AttributeChangeAtServer("RoomType", SelRoomType);
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelRoomOnChangeAtServer()
	If not ValueIsFilled(SelRoom) Then
		ClearingAttributeAtServer("Room");
	Else 
		AttributeChangeAtServer("Room", SelRoom);
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelEmployeeOnChangeAtServer()
	If not ValueIsFilled(SelEmployee) Then
		ClearingAttributeAtServer("Author");
	Else 
		AttributeChangeAtServer("Author", SelEmployee);
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelDateFromOnChangeAtServer()	
	If ValueIsFilled(SelDateFrom) Then
		AttributeChangeAtServer("DateFrom", SelDateFrom, DataCompositionComparisonType.Greater);
	Else
		ClearingAttributeAtServer("DateFrom");	
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelDateToOnChangeAtServer()
	If ValueIsFilled(SelDateTo) Then	
		AttributeChangeAtServer("DateTo", EndOfDay(SelDateTo), DataCompositionComparisonType.Less);
	Else
		ClearingAttributeAtServer("DateTo");
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SelHistoryFromOnChangeAtServer()
	ClearingAttributeAtServer("Date");
	If ValueIsFilled(SelHistoryFrom) Then
		AttributeChangeAtServer("Date", SelHistoryFrom, DataCompositionComparisonType.GreaterOrEqual, True);
	EndIf;
	If ValueIsFilled(SelHistoryTo) Then
		AttributeChangeAtServer("Date", EndOfDay(SelHistoryTo), DataCompositionComparisonType.LessOrEqual, True);
	EndIf;
EndProcedure

#EndRegion
