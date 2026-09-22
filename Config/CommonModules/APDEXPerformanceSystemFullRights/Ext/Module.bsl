
#Region Public

// --------------------------------------------------------------------------------
//  The procedure for recording an array of measurements
//
// Parameters:
//  pMeasurements	 - Array - Array items structure
// 
// Returns:
//  Number - Number - the current value of the recording period of measurements on the server in seconds.
//
Function CommitTimeIntervalMeasurement(pMeasurements) Export
	For Each vRow In pMeasurements Do
		vKeyOperation = vRow.Key;
		vBuffer = vRow.Value;
		For Each vRowBuffer In vBuffer Do
			vData = vRowBuffer.Value;
			vDuration = vData.Get("Duration");
			If vDuration = Undefined Then
				// Неоконченный замер, писать его пока рано
				Continue;
			EndIf;
			KeyOperationDurationCommit(vKeyOperation, vDuration, vRowBuffer.Key, vData["DateTo"], vData["Remarks"], vData["Weight"]);
		EndDo;
	EndDo;
	Return RecordingPeriod();
EndFunction

// --------------------------------------------------------------------------------
//  The current value of the measurement results recording period on the server
// 
// Returns:
//  Number - value in seconds.
//
Function RecordingPeriod() Export
	vCurDate = Constants.APDEXRecordingPeriod.Get();   
	If vCurDate >= 1 Then
		// Nothing, already set	
	Else
		vCurDate = 60;	
	EndIf;	
	Return vCurDate;
EndFunction

// --------------------------------------------------------------------------------
//  Current date on the server
// 
// Returns:
//  Date - date on the server.
//
Function DateOnServer() Export
	Return CurrentSessionDate();
EndFunction

// --------------------------------------------------------------------------------
//  The function creates a new element of the "Key operations" lookup.
//
// Parameters:
//  pKeyOperationDescription - String	 - key operation name
// 
// Returns:
//  CatalogRef.APDEXKeyOperations - Ref on catalog
//
Function AddAPDEXKeyOperation(pKeyOperationDescription) Export
	BeginTransaction();
	Try
		vDataLock = New DataLock;
		vDataLockItem = vDataLock.Add("Catalog.APDEXKeyOperations");
		vDataLockItem.SetValue("Name", pKeyOperationDescription);
		vDataLockItem.Mode = DataLockMode.Exclusive;
		vDataLock.Lock();
		
		vQuery = New Query;
		vQuery.Text = "SELECT TOP 1
		              |	KeyOperations.Ref AS Ref
		              |FROM
		              |	Catalog.APDEXKeyOperations AS KeyOperations
		              |WHERE
		              |	KeyOperations.Name = &qName
		              |
		              |ORDER BY
		              |	Ref";
		
		vQuery.SetParameter("qName", pKeyOperationDescription);
		vResult = vQuery.Execute();
		If vResult.IsEmpty() Then
			vTranslations = GetAPDEXKeyDescriptions();
			vTemplateRow = vTranslations.Find(pKeyOperationDescription);
			vTranslateDesc = pKeyOperationDescription;   
			
			vNewItem = Catalogs.APDEXKeyOperations.CreateItem(); 
			If vTemplateRow = Undefined Then
				vNewItem.Name = pKeyOperationDescription;
				vNewItem.Description = vTranslateDesc;
				vNewItem.TargetTime = 1;
			Else
				FillPropertyValues(vNewItem, vTemplateRow, , "MinimumLevel");
				vNewItem.MinimumLevel = Enums.APDEXPerformanceLevels[vTemplateRow.MinimumLevel];	
			EndIf;	  
			vNewItem.AdditionalProperties.Insert("DoNotCheckPriority", True); 
			vNewItem.Write();
			vKeyOperationRef = vNewItem.Ref;
		Else
			vSel = vResult.Select();
			vSel.Next();
			vKeyOperationRef = vSel.Ref;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction(); 
		WriteLogEvent("Catalog.APDEXKeyOperations.CreateItem", EventLogLevel.Error, , , ErrorDescription());
		Raise;
	EndTry;
	
	Return vKeyOperationRef;
EndFunction

// --------------------------------------------------------------------------------
//  Single measurement recording procedure
//
// Parameters:
//  pKeyOperation	 - CatalogRef.APDEXKeyOperations, String - Key operation or String
//  pDuration		 - Number								 - Number
//  pDateFrom		 - Date									 - Date from
//  pDateTo			 - Date									 - Date to
//  pRemarks		 - String								 - Remarks
//  pWeight			 - Number								 - Weight
//  pHotel			 - CatalogRef.Hotels					 - Ref
//
Procedure KeyOperationDurationCommit(pKeyOperation, pDuration, pDateFrom, pDateTo = Undefined, pRemarks = Undefined, pWeight = Undefined, pHotel = Undefined) Export
	If TypeOf(pKeyOperation) = Type("String") Then
		pKeyOperation = APDEXPerformanceSystemOnServerReuse.GetAPDEXKeyOperationByName(pKeyOperation);
	Else
		// Nothing, already set 
	EndIf;
	If pRemarks = Undefined Then
		pRemarks = SessionParameters.APDEXRemarks;
	Else
		vJSONWriter = New JSONWriter;
		vJSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
		WriteJSON(vJSONWriter, pRemarks);
		pRemarks = vJSONWriter.Close();
	EndIf;
	vRmg = InformationRegisters.APDEXTimeMeasurements.CreateRecordManager();
	vRmg.KeyOperation = pKeyOperation;
	vRmg.DateFrom = pDateFrom;
	vRmg.SessionNumber = InfoBaseSessionNumber();
	vRmg.Duration = ?(pDuration = 0, 0.001, pDuration); 
	vRmg.Date = CurrentSessionDate();
	If pDateTo <> Undefined Then
		vRmg.DateTo = pDateTo;
	EndIf;
	vRmg.User = InfoBaseUsers.CurrentUser();
	vRmg.PeriodUTC = CurrentSessionDate();
	vRmg.Remarks = pRemarks;  
	       
	If pHotel = Undefined Then
		vHotel = SessionParameters.CurrentHotel;
	Else
		vHotel = pHotel;
	EndIf;	
	vRmg.Hotel = vHotel;
	If pWeight <> Undefined Then
		vRmg.Weight = pWeight;
	EndIf;
	
	vRmg.Write();
EndProcedure

// --------------------------------------------------------------------------------
Procedure FillAPDEXKeyOperation() Export
	TranslationsAPDEX = GetAPDEXKeyDescriptions(); 
	vCurItems = GetAllAPDEXKeyOperations().Unload();
	For Each vTemplateRow In TranslationsAPDEX Do     
		vRefRow = vCurItems.Find(vTemplateRow.Name);
		If vRefRow <> Undefined Then
			vRef = vRefRow.Reference;
			vObject = vRef.GetObject();
		Else			
			vObject = Catalogs.APDEXKeyOperations.CreateItem();
			vObject.Name = vTemplateRow.Name;
		EndIf;		 
		vObject.DataExchange.Load = True;    
		FillPropertyValues(vObject, vTemplateRow, , "MinimumLevel");
		vObject.MinimumLevel = Enums.APDEXPerformanceLevels[vTemplateRow.MinimumLevel];
		vObject.Write();         
	EndDo;
EndProcedure

#EndRegion  

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function GetAPDEXKeyDescriptions() 
	vTabDoc = GetCommonTemplate("APDEXKeyOperations");
	
	vAreasTab = vTabDoc.Area(1, 1, vTabDoc.TableHeight, vTabDoc.TableWidth);
	
	vQueryBuilder = New QueryBuilder;
	vQueryBuilder.DataSource = New DataSourceDescription(vAreasTab);  
	vQueryBuilder.Execute();
	
	vTranslations = vQueryBuilder.Result.Unload();
	Return vTranslations;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Function GetAllAPDEXKeyOperations()	
	vQry = New Query();
	vQry.Text =
	"SELECT
	|	AKeyOperations.Name AS Name,
	|	AKeyOperations.Ref AS Reference
	|FROM 
	|	Catalog.APDEXKeyOperations AS AKeyOperations"; 
	vQryRes = vQry.Execute();
	Return vQryRes;
EndFunction

#EndRegion		
 