
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
// Function - Get client
//
// Parameters:
//  pExternalSystem	 - CatalogRef.ExternalSystemInteractions - Ref
//  pID				 - String - OTA ID
// 
// Returns:
//  CatalogRef.Clients - Ref guest
//
Function GetClient(pExternalSystem, pID) Export 
    vClient = Undefined;
	
	vQuery = New Query;
	vQuery.Text = "SELECT
	|	OTAID.Client AS Client
	|FROM
	|	InformationRegister.OTAID AS OTAID
	|WHERE
	|	OTAID.ExternalSystem = &qExternalSystem
	|	AND OTAID.ID = &qID";
	
	vQuery.SetParameter("qExternalSystem", pExternalSystem);
	vQuery.SetParameter("qID", pID);
	
	vResult = vQuery.Execute();
	If Not vResult.IsEmpty() Then
		vSelection = vResult.Select();
		vSelection.Next();
		vClient = vSelection.Client;
	EndIf;
	Return vClient;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pExternalSystem	 - CatalogRef.ExternalSystemInteractions - Ref
//  pClient			 - CatalogRef.Clients					 - Ref guest
//  pID				 - String								 - OTA ID
//
Procedure WriteOTA_ID(pExternalSystem, pClient, pID) Export
	vRecMng = InformationRegisters.OTAID.CreateRecordManager();	
	vRecMng.ExternalSystem 	= pExternalSystem;
	vRecMng.Client 	= pClient;
	vRecMng.ID 		= pID;
	vRecMng.Date 	= CurrentSessionDate();
	vRecMng.Write(True);
EndProcedure // WriteOTA_ID()

#EndRegion
	