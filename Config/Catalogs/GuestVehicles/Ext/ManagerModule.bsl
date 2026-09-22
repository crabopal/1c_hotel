
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
Function GetVehicleByDescription(pDescription) Export
	vCar = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	GuestVehicles.Ref AS Ref
	|FROM
	|	Catalog.GuestVehicles AS GuestVehicles
	|WHERE
	|	GuestVehicles.Description = &qDescription
	|	AND NOT GuestVehicles.DeletionMark
	|
	|ORDER BY
	|	GuestVehicles.Code DESC";
	vQry.SetParameter("qDescription", pDescription);
	vCars = vQry.Execute().Unload();
	If vCars.Count() > 0 Then
		vCar = vCars.Get(0).Ref;
	EndIf;
	Return vCar;
EndFunction // GetVehicleByDescription

#EndRegion
