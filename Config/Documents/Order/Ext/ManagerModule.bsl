
#Region Public

// --------------------------------------------------------------------------------
Procedure InitializeOrdersSubsystem() Export
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	OrderStatuses.Ref,
		|	OrderStatuses.PredefinedDataName
		|FROM
		|	Catalog.OrderStatuses AS OrderStatuses";
	vQueryResult = vQuery.Execute();
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		vObject = vSelectionDetailRecords.Ref.GetObject();
		If vSelectionDetailRecords.PredefinedDataName = "New" Then
			vObject.isNewOrder       = True;
			vObject.isOrderComplete  = False;
			vObject.SetAuthor        = False;
			vObject.isOrderCancel    = False;
			vObject.SortCode         = 1;
			vObject.Write();
			vNewOrder = vObject.Ref;
		ElsIf vSelectionDetailRecords.PredefinedDataName = "Confirmed" Then 
			vObject.isNewOrder       = False;
			vObject.isOrderComplete  = False;
			vObject.SetAuthor        = True;
			vObject.isOrderCancel    = False;
			vObject.SortCode         = 2;
			vObject.Write();
			vConfirmedOrder = vObject.Ref;
		ElsIf vSelectionDetailRecords.PredefinedDataName = "Cancel" Then 
			vObject.isNewOrder       = False;
			vObject.isOrderComplete  = False;
			vObject.SetAuthor        = False;
			vObject.isOrderCancel    = True;
			vObject.SortCode         = 0;
			vObject.Write();
		ElsIf vSelectionDetailRecords.PredefinedDataName = "Complete" Then 
			vObject.isNewOrder       = False;
			vObject.isOrderComplete  = True;
			vObject.SetAuthor        = False;
			vObject.isOrderCancel    = False;
			vObject.SortCode         = 3;
			vObject.Write();
			vCompleteOrder = vObject.Ref;
		EndIf;
	EndDo;
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	OrderTypes.Ref
		|FROM
		|	Catalog.OrderTypes AS OrderTypes
		|WHERE
		|	OrderTypes.Predefined";
	vQueryResult = vQuery.Execute();
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		vObject = vSelectionDetailRecords.Ref.GetObject();
		vObject.StatusesCourse.Clear();
		vRow = vObject.StatusesCourse.Add();
		vRow.Status = vNewOrder; 
		vRow = vObject.StatusesCourse.Add();
		vRow.Status = vConfirmedOrder; 
		vRow = vObject.StatusesCourse.Add();
		vRow.Status = vCompleteOrder; 
		vObject.Write();
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
Procedure GetNextStatus(pDoc, pOType, pCurrStatus = Undefined, pThisObject = False, pWrite = True) Export 
	isNextStat = False;
	If Not ValueIsFilled(pOType) Then
		Return;
	EndIf;
	If ValueIsFilled(pCurrStatus) Then
		For Each vStatus In pOType.StatusesCourse Do 
			If isNextStat Then
				SetStatus(pDoc,vStatus.Status, pThisObject, pWrite);
			EndIf;		
			If vStatus.Status = pCurrStatus Then 
				isNextStat = True;			
			EndIf;		
		EndDo;
	Else
		For Each vStatus In pOType.StatusesCourse Do 			
			If vStatus.Status.isNewOrder Then 
				SetStatus(pDoc, vStatus.Status, pThisObject, pWrite);		
			EndIf;		
		EndDo;				
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
Procedure SetStatus(pDoc, pStatus, pThisObject = False, vWrite = True) Export 
	If Not pThisObject then
		vObject = pDoc.GetObject();	
	Else
		vObject = pDoc;	
	EndIf;
	isEdit = False;	
	If vObject.Status <> pStatus Then
		vObject.Status = pStatus;	
		isEdit = True;
	EndIf;
	If pStatus.SetAuthor And ValueIsFilled(vObject.Author) Then
		isEdit = True;
		vObject.Author = SessionParameters.CurrentUser;	
	EndIf;	
	If isEdit And vWrite Then
		vObject.Write();				
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
Function GetOrderByCharge(pCharge) Export
	vOrder = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	Order.Ref AS Ref
	|FROM
	|	Document.Order AS Order
	|WHERE
	|	Order.Charge = &qCharge
	|	AND Order.Posted
	|
	|ORDER BY
	|	Order.PointInTime DESC";
	vQry.SetParameter("qCharge", pCharge);
	vOrders = vQry.Execute().Unload();
	For Each vOrdersRow In vOrders Do
		vOrder = vOrdersRow.Ref;
		Break;
	EndDo;
	Return vOrder;
EndFunction // GetOrderByCharge

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
