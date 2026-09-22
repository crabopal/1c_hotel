
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	If Parameters.Property("Hotel") Then
		Hotel = Parameters.Hotel;
	Else
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Parameters.Property("ParentDoc") Then
		ParentDoc = Parameters.ParentDoc;
		If ValueIsFilled(ParentDoc) Then
			Hotel = ParentDoc.Hotel;
		EndIf;
		AttributeChangeAtServer("ParentDoc", GetParentDocs(Parameters.ParentDoc), DataCompositionComparisonType.InList);
	EndIf;		
	ChangeHotelAtServer(Hotel);
	// Set hotel color          
	If Not IsInRole("RightsToChooseHotel") Then
		Items.Hotel.ReadOnly = True;
		Items.Hotel.ChoiceButton = False;
		Items.Hotel.ClearButton = False;
	EndIf;
	RefreshFilter();
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(Cancel)
	If tcOnClient.IsHomePageWindow(ThisObject) Then
		vPrefix = NStr("en = 'Orders history: '; de = 'Bestellhistorie: '; ru = 'Журнал заказов: '");
		tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Document.Order.Write" Then
		Items.List.Refresh();
	ElsIf pEventName = "System.Hotel.Changed" And pParameter <> Hotel Then
		If ValueIsFilled(pParameter) Then
			Hotel = pParameter;
			AttributeChangeAtServer("Hotel", Hotel);
			If tcOnClient.IsHomePageWindow(ThisObject) Then
				vPrefix = NStr("en = 'Orders history: '; de = 'Bestellhistorie: '; ru = 'Журнал заказов: '");
				tcCommonFunctionOnClientServer.cmSetFormTitleHotelName(ThisObject, vPrefix);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure TypeOnChange(Item)
	TypeOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure StatusFilterOnChange(Item)
	StatusFilterOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure StatusListOnChange(Item)
	StatusFilterOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DepartmentOnChange(Item)
	DepartmentOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceOnChange(Item)
	ServiceOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RoomsOnChange(Item)
	RoomsOnChangeOnServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelOnChange(Item)
	ChangeHotelAtServer(Hotel);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ResponsibleOnChange(Item)
	ResponsibleOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RentStartDateOnChange(pItem)
	RentStartDateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RentEndDateOnChange(Item)
	RentEndDateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Hotels.ChoiceForm", , pItem, UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // SelHotelStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	ChangeHotelAtServer(pSelectedValue);
EndProcedure // SelHotelChoiceProcessing

// -----------------------------------------------------------------------------
&AtClient
Procedure SelHotelClearing(pItem, pStandardProcessing)
	If Not IsInRoleAtServer("RightsToChooseHotel") Then
		pStandardProcessing = False;
	ENdIf;
EndProcedure // SelHotelClearing

// -----------------------------------------------------------------------------
&AtServer
Function IsInRoleAtServer(pRoleName)
	Return IsInRole(pRoleName);
EndFunction // IsInRoleAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Create(Command)     
	If CheckFilling() Then
		vParam = New Structure();
		vParam.Insert("basis",ParentDoc);
		vParam.Insert("hotel",Hotel);
		
		OpenForm("Document.Order.Form.DocumentForm", vParam, ThisObject, True);
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
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
	RefreshFilter();
EndProcedure

// -----------------------------------------------------------------------------  
&AtServer
Procedure AttributeChangeAtServer(pAttribute, pValue, pComparisonType = Undefined, pAddNew = False)
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
				For Each int In vFilter.Items Do
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
	RefreshFilter();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshFilter()
	Items.StatusFilter.ChoiceList.Clear();	
	Items.StatusFilter.ChoiceList.Add(Catalogs.OrderStatuses.EmptyRef(), NStr("en='All'; ru='Все'; de='Alle'"));

	Items.StatusList.ChoiceList.Clear();	
	Items.StatusList.ChoiceList.Add(Catalogs.OrderStatuses.EmptyRef(), NStr("en='All'; ru='Все'; de='Alle'"));
	
	
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(Hotel, "BackgroundColorImportant");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	OrderStatuses.Ref,
	|	OrderStatuses.Description,
	|	COUNT(Order.Ref) AS Count
	|FROM
	|	Catalog.OrderStatuses AS OrderStatuses
	|		FULL JOIN (SELECT
	|			Order.Ref AS Ref
	|		FROM
	|			Document.Order AS Order
	|		WHERE
	|			NOT Order.DeletionMark
	|	";
	If ValueIsFilled(Department) Then
		Query.Text = Query.Text + 
		"AND Order.Department = &Department
		|	";
	EndIf;
	If ValueIsFilled(RentStartDate) Then
		If ValueIsFilled(Type) And (Type.Type = Enums.TypesOfOrder.Rent Or Type.Type = Enums.TypesOfOrder.RentDaily) Then
			Query.Text = Query.Text + 
			"AND Order.OrderDateFrom = &OrderDateFrom
			|	";
		Else
			Query.Text = Query.Text + 
			"AND Order.OrderTime >= &OrderTimeStart
			|	";
			Query.Text = Query.Text + 
			"AND Order.OrderTime <= &OrderTimeEnd
			|	";			
		EndIf;		
	EndIf;
	If ValueIsFilled(RentEndDate) Then
		Query.Text = Query.Text + 
		"AND Order.OrderDateTo = &OrderDateTo
		|	";
	EndIf;	
	If ValueIsFilled(Hotel) Then
		Query.Text = Query.Text + 
		"AND Order.Hotel = &Hotel
		|	";
	EndIf;
	If ValueIsFilled(Room) Then
		Query.Text = Query.Text + 
		"AND Order.Room = &Room
		|	";
	EndIf;
	If ValueIsFilled(Type) Then
		Query.Text = Query.Text + ""
		"AND Order.Type = &Type
		|	";
	EndIf;
	If ValueIsFilled(Author) Then
		Query.Text = Query.Text + ""
		"AND Order.Author = &Author
		|	";
	EndIf;		
	If ValueIsFilled(ParentDoc) Then
		Query.Text = Query.Text + ""
		"AND Order.ParentDoc in (&ParentDoc)
		|	";
	EndIf;	
	Query.Text = Query.Text +  
	"
	|           ) AS Order
	|		ON OrderStatuses.Ref = Order.Ref.Status
	|WHERE
	|	NOT OrderStatuses.DeletionMark                                        
	|
	|GROUP BY
	|	OrderStatuses.Ref,
	|	OrderStatuses.Description
	|
	|ORDER BY
	|	OrderStatuses.SortCode";	
	
	If ValueIsFilled(Hotel) Then
		Query.SetParameter("Hotel",Hotel);
	EndIf;
	If ValueIsFilled(Room) Then
		Query.SetParameter("Room",Room);
	EndIf;
	If ValueIsFilled(Type) Then
		Query.SetParameter("Type",Type);		
	EndIf;
	If ValueIsFilled(Department) Then
		Query.SetParameter("Department",Department);		
	EndIf;
	If ValueIsFilled(Author) Then
		Query.SetParameter("Author",Author);		
	EndIf;
	If ValueIsFilled(ParentDoc) Then
		Query.SetParameter("ParentDoc", GetParentDocs(ParentDoc));		
	EndIf;
	If ValueIsFilled(RentStartDate) Then		
		If ValueIsFilled(Type) And (Type.Type = Enums.TypesOfOrder.Rent Or Type.Type = Enums.TypesOfOrder.RentDaily) Then
			Query.SetParameter("OrderDateFrom",RentStartDate);					
		Else
			Query.SetParameter("OrderTimeStart",RentStartDate);	
			Query.SetParameter("OrderTimeEnd",EndOfDay(RentStartDate));				
		EndIf;		
	EndIf;
	If ValueIsFilled(RentEndDate) Then
		Query.SetParameter("OrderDateTo",RentEndDate);		
	EndIf;
	
	vQueryResult = Query.Execute();
	
	vRes = vQueryResult.Select();
	
	While vRes.Next() Do
		vCount = vRes.Count;
		If Not ValueIsFilled(vCount) Then
			vCount = 0;
		EndIf;		
		Items.StatusFilter.ChoiceList.Add(vRes.Ref, vRes.Description + " (" + vCount + ")");		
		Items.StatusList.ChoiceList.Add(vRes.Ref, vRes.Description + " (" + vCount + ")");		
	EndDo;
	
	Items.StatusFilter.ColumnsCount = Items.StatusFilter.ChoiceList.Count();
	
	If Items.StatusFilter.ChoiceList.Count() > 7 Then
		Items.StatusFilter.Visible = False;
		Items.StatusList.Visible = True;
	Else
		Items.StatusFilter.Visible = True;
		Items.StatusList.Visible = False;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure TypeOnChangeAtServer()
	If Not ValueIsFilled(Type) Then
		ClearingAttributeAtServer("Type");
	Else 
		AttributeChangeAtServer("Type", Type);
	EndIf;
	RentStartDateOnChangeAtServer();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure StatusFilterOnChangeAtServer()
	If Not ValueIsFilled(Status) Then
		ClearingAttributeAtServer("Status");		
	Else 
		AttributeChangeAtServer("Status", Status);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure DepartmentOnChangeAtServer()
	If Not ValueIsFilled(Department) Then
		ClearingAttributeAtServer("Department");		
	Else 
		AttributeChangeAtServer("Department", Department);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ServiceOnChangeAtServer()
	If Not ValueIsFilled(Service) Then
		ClearingAttributeAtServer("Service");		
	Else 
		AttributeChangeAtServer("Service", Service);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure RoomsOnChangeOnServer()
	If Not ValueIsFilled(Room) Then
		ClearingAttributeAtServer("Room");
	Else 
		AttributeChangeAtServer("Room", Room);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ResponsibleOnChangeAtServer()
	If Not ValueIsFilled(Author) Then
		ClearingAttributeAtServer("Author");		
	Else 
		AttributeChangeAtServer("Author", Author);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetParentDocs(Doc)
	vObject	= Doc;
	vDocs = New ValueTable;
	vDocs.Columns.Add("Doc");
	vDocRow = vDocs.Add();
	vDocRow.Doc = vObject.Ref;
	While ValueIsFilled(vObject.ParentDoc) Do
		vFindDoc = vDocs.Find(vObject.ParentDoc, "Doc");
		If ValueIsFilled(vFindDoc) Then
			Break;
		Else
			vDocRow = vDocs.Add();
			vDocRow.Doc = vObject.ParentDoc;
			vObject = vObject.ParentDoc; 
		EndIf;
	EndDo;	
	Return vDocs.UnloadColumn("Doc");
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Procedure RentStartDateOnChangeAtServer()
	If ValueIsFilled(Type) And (Type.Type = Enums.TypesOfOrder.Rent Or Type.Type = Enums.TypesOfOrder.RentDaily) Then
		vParam  = "OrderDateFrom";
	Else
		vParam  = "OrderTime";
	EndIf;
	
	If Not ValueIsFilled(RentStartDate) Then
		ClearingAttributeAtServer(vParam);		
	Else 
		If ValueIsFilled(Type) And (Type.Type = Enums.TypesOfOrder.Rent Or Type.Type = Enums.TypesOfOrder.RentDaily) Then
			AttributeChangeAtServer(vParam, RentStartDate, DataCompositionComparisonType.GreaterOrEqual);
		Else	
			ClearingAttributeAtServer(vParam);		
			AttributeChangeAtServer(vParam, RentStartDate, DataCompositionComparisonType.GreaterOrEqual, True);
			AttributeChangeAtServer(vParam, EndOfDay(RentStartDate), DataCompositionComparisonType.LessOrEqual, True);			
		EndIf;
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure RentEndDateOnChangeAtServer()
	If Not ValueIsFilled(RentEndDate) Then
		ClearingAttributeAtServer("OrderDateTo");		
	Else 
		AttributeChangeAtServer("OrderDateTo", RentEndDate, DataCompositionComparisonType.LessOrEqual);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ChangeHotelAtServer(pHotel)
	List.Parameters.SetParameterValue("qHotel", pHotel);
	List.Parameters.SetParameterValue("qHotelIsFilled", ValueIsFilled(pHotel));
	
	If ValueIsFilled(pHotel) Then
		If ValueIsFilled(ParentDoc) And ParentDoc.Hotel <> pHotel Then
			ParentDoc = Undefined;
			ClearingAttributeAtServer("ParentDoc");
		EndIf;
	EndIf;
	
	// Set hotel color          
	Items.GroupHotel.BackColor = CachedCommonFunctions.cmGetColorByColorStringFromRef(pHotel, "BackgroundColorImportant");	
EndProcedure // ChangeHotelAtServer

#EndRegion
