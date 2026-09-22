
#Region FormEventHandlers

 // --------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("ObjectRef", ObjectRef) And ObjectRef <> Undefined Then
		FillServicesAtServer();
	Else
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pParameter = ObjectRef Then
		FillServicesAtServer();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RefreshAction(pCommand)
	Services.Clear();
	If ObjectRef <> Undefined Then
		FillServicesAtServer();
	EndIf;
EndProcedure // RefreshAction

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillServicesAtServer()
	vServices = ObjectRef.Services.Unload(, "IsRoomRevenue, IsInPrice, IsSplit, Folio, Room, AccountingDate, Service, Price, Quantity, Unit, Sum, VATRate, CalendarDayType, PriceTag, FolioCurrency, Discount, DiscountSum, AgentCommission, CommissionSum, Remarks");
	vServices.Columns.Add("Client");
	vServices.Columns.Add("SumWithDiscount", cmGetSumTypeDescription());
	For Each vSrvRow In vServices Do
		vSrvRow.SumWithDiscount = vSrvRow.Sum - vSrvRow.DiscountSum;
	EndDo;
	
	vOneRoomGuests = New ValueTable();
	If TypeOf(ObjectRef) = Type("DocumentRef.Accommodation") Then
		vOneRoomGuests = cmGetOneRoomAccommodations(ObjectRef.Room, ObjectRef.GuestGroup, ObjectRef.CheckInDate, ObjectRef.CheckOutDate);
	Else
		vOneRoomGuests = cmGetOneRoomReservations(ObjectRef.Number, ObjectRef.GuestGroup, ObjectRef.CheckInDate, ObjectRef.CheckOutDate);
	EndIf;
	
	// Add services from other room documents
	For Each vRow In vOneRoomGuests Do
		If ValueIsFilled(vRow.Ref) Then
			vDocRef = vRow.Ref;
			If vDocRef <> ObjectRef Then
				For Each vDocSrvRow In vDocRef.Services Do
					vServicesRows = vServices.FindRows(New Structure("Folio, Service, AccountingDate, IsSplit", vDocSrvRow.Folio, vDocSrvRow.Service, vDocSrvRow.AccountingDate, vDocSrvRow.IsSplit));
					If vServicesRows.Count() = 1 Then
						vSrvRow = vServicesRows.Get(0);
						vSrvRow.Sum = vSrvRow.Sum + vDocSrvRow.Sum;
						vSrvRow.DiscountSum = vSrvRow.DiscountSum + vDocSrvRow.DiscountSum;
						vSrvRow.CommissionSum = vSrvRow.CommissionSum + vDocSrvRow.CommissionSum;
						If vSrvRow.IsRoomRevenue And vSrvRow.IsInPrice Then
							vSrvRow.Quantity = ?(vSrvRow.Quantity = 0, ?(vSrvRow.Sum < 0, -1, 1), vSrvRow.Quantity);
						Else
							vSrvRow.Quantity = vSrvRow.Quantity + vDocSrvRow.Quantity;
						EndIf;
						vSrvRow.Price = Round(vSrvRow.Sum/vSrvRow.Quantity, 2);
					Else
						vSrvRow = vServices.Add();
						FillPropertyValues(vSrvRow, vDocSrvRow);
					EndIf;
					vSrvRow.SumWithDiscount = vSrvRow.Sum - vSrvRow.DiscountSum;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	vServices.Sort("AccountingDate, Folio, IsRoomRevenue DESC, IsInPrice DESC, Service");
	For Each vSrvRow In vServices Do
		If ValueIsFilled(vSrvRow.Folio) Then
			vSrvRow.Client = vSrvRow.Folio.Client;
		EndIf;
	EndDo;
	
	// Fill totals
	TotalAmount = vServices.Total("Sum");
	TotalDiscountAmount = vServices.Total("DiscountSum");
	TotalAmountWithDiscount = TotalAmount - TotalDiscountAmount;
	TotalCommissionAmount = vServices.Total("CommissionSum");
	
	ValueToFormAttribute(vServices, "Services");
EndProcedure // FillServicesAtServer

#EndRegion
