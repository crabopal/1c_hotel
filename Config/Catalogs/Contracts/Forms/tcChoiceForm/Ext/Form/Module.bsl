
#Region FormEventHandlers

// ---------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Set customer filter if necessary
	vOwner = Catalogs.Customers.EmptyRef();
	If Parameters.Filter.Property("Owner") Then
		vOwner = Parameters.Filter.Owner;
		If ValueIsFilled(vOwner) Then  
			tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Owner", vOwner, , , True);
			Items.Owner.Visible = False;
		EndIf;
	EndIf;
	// Filter by hotel
	vHotel = Catalogs.Hotels.EmptyRef();
	If Parameters.Property("Hotel") Then
		vHotel = Parameters.Hotel;
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(vHotel) Then    
		vHotelsList = New ValueList;
		vHotelsList.Add(Catalogs.Hotels.EmptyRef());
		vHotelsList.Add(vHotel);
		
		tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Hotel", vHotelsList, , , True);
	EndIf;
	// Filter by period
	If Parameters.Property("ShowValidContractsOnly") Then
		If Parameters.ShowValidContractsOnly Then
			vPeriodFrom = '00010101';
			vPeriodTo = '00010101';
			vCreateDate = '00010101';
			If Parameters.Property("PeriodFrom") Then
				vPeriodFrom = Parameters.PeriodFrom;
			EndIf;
			If Parameters.Property("PeriodTo") Then
				vPeriodTo = Parameters.PeriodTo;
			EndIf;
			If Parameters.Property("CreateDate") Then
				vCreateDate = Parameters.CreateDate;
			EndIf;
			If ValueIsFilled(vOwner) And (ValueIsFilled(vPeriodFrom) Or ValueIsFilled(vPeriodTo) Or ValueIsFilled(vCreateDate)) Then
				vValidContracts = cmGetListOfValidContracts(vOwner, vPeriodFrom, vPeriodTo, vCreateDate, ?(ValueIsFilled(vHotel), vHotel, Undefined));
				tcCommonFunctionOnClientServer.cmSetFilterItems(List.Filter, "Ref", vValidContracts, , , True);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// ---------------------------------------------------------------------------------
&AtClient
Procedure Add(pCommand)
	vFilter = tcCommonFunctionOnClientServer.cmSearchItemsGroupAndFilter(List.Filter, "Owner");
	If vFilter.Count() > 0 Then
		vCustomer = vFilter[0].RightValue;
		If ValueIsFilled(vCustomer) Then   
			vParams = New Structure("FillingValues");   
			vFillingValues = New Structure("Owner", vCustomer);
			vParams.FillingValues = vFillingValues;
			OpenForm("Catalog.Contracts.ObjectForm", vParams, ThisObject, UniqueKey, , , New NotifyDescription("AfterCreateContract", ThisObject), FormWindowOpeningMode.LockOwnerWindow);		
		EndIf;	
	EndIf;	
EndProcedure

#EndRegion

#Region Private

// ---------------------------------------------------------------------------------
&AtClient
Procedure AfterCreateContract(Result, AdditionalParameters) Export
	
	Items.List.Refresh();
	
EndProcedure  

#EndRegion
   