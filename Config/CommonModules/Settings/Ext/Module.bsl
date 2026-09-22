
#Region Public

// -----------------------------------------------------------------------------
// Description: Returns catalog object reference by it's external system code
// Parameters: Hotel, External system code, Name of the catalog in the 
//             metadata, Object's code in the external system
// Return value: Reference to the catalog object or undefined
// -----------------------------------------------------------------------------
Function cmGetObjectRefByExternalSystemCode(pHotelRef, pExternalSystemCode, pObjectTypeName, pObjectExternalCode, pSearchInCatalog = True, pInteraction = Undefined, pWithFolders = False) Export
	vObjectRef = Undefined;  
	// Try to  
	If ValueIsFilled(pInteraction) Then
		vRes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteraction, pObjectTypeName, , , , , pObjectExternalCode);
		If vRes.Count() > 0 Then
			vObjectRef = vRes[0].RefKey1;
		EndIf;
	EndIf;
	// Try to find reference to the object in the program by external code
	If Not IsBlankString(pExternalSystemCode) And Not IsBlankString(pObjectExternalCode) And Not ValueIsFilled(vObjectRef) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	(ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|			OR ExternalSystemsObjectCodesMappings.Hotel = &qEmptyHotel)
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
		|	AND ExternalSystemsObjectCodesMappings.ObjectExternalCode = &qObjectExternalCode";
		vQry.SetParameter("qHotel", pHotelRef);
		vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		vQry.SetParameter("qExternalSystemCode", TrimAll(pExternalSystemCode));
		vQry.SetParameter("qObjectTypeName", TrimAll(pObjectTypeName));
		vQry.SetParameter("qObjectExternalCode", TrimAll(pObjectExternalCode));
		vObjects = vQry.Execute().Unload();
		If vObjects.Count() = 1 Then
			vObjectRef = vObjects.Get(0).ObjectRef;
		EndIf;
	EndIf;
	
	If Upper(pExternalSystemCode) = "BITRIX24" And Not ValueIsFilled(vObjectRef) Then
		If pObjectTypeName = "Employees" And cmIsNumber(pObjectExternalCode) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Employees.Ref AS Ref
			|FROM
			|	Catalog.Employees AS Employees
			|WHERE
			|	NOT Employees.DeletionMark
			|	AND Employees.B24EmployeeID = &qObjectExternalCode
			|	AND (Employees.Hotel = &qHotel
			|			OR Employees.Hotel = VALUE(Catalog.Hotels.EmptyRef)
			|			OR &qHotelIsEmpty)";
			vQry.SetParameter("qHotel", pHotelRef);
			vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotelRef));
			vQry.SetParameter("qObjectExternalCode", Number(pObjectExternalCode));
			vObjects = vQry.Execute().Unload();
			If vObjects.Count() = 1 Then
				vObjectRef = vObjects.Get(0).Ref;
			EndIf;
		EndIf;
	EndIf;
	
	If pSearchInCatalog = True And Not ValueIsFilled(vObjectRef) Then
		vCatalogsHierarchical = False;
		If Not IsBlankString(pObjectTypeName) Then
			vCatalogsHierarchical = Metadata.Catalogs[pObjectTypeName].Hierarchical;
		EndIf;
		If Not ValueIsFilled(vObjectRef) And Not IsBlankString(pObjectExternalCode) And Not IsBlankString(pObjectTypeName) Then
			// Try to find object ref by code assuming that object type name is name of the catalog
			vQry = New Query();
			
			If pObjectTypeName = "Rooms" Then
				If pWithFolders Then
					vCatalogsHierarchical = False;
				EndIf;
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	CatalogItems.Ref
				|FROM
				|	Catalog." + pObjectTypeName + " AS CatalogItems
				|WHERE
				|	(NOT CatalogItems.DeletionMark)
				|" + ?(vCatalogsHierarchical, "AND (NOT CatalogItems.IsFolder)", "") + "
				|	AND CatalogItems.Description = &qObjectExternalCode
				|	AND (CatalogItems.Owner = &qHotel
				|		OR &qHotelIsEmpty)";
				vQry.SetParameter("qHotel", pHotelRef);
				vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotelRef));
			ElsIf pObjectTypeName = "RoomTypes" Then
				If pWithFolders Then
					vCatalogsHierarchical = False;
				EndIf;
				vQry.Text = 
				"SELECT
				|	CatalogItems.Ref
				|FROM
				|	Catalog." + pObjectTypeName + " AS CatalogItems
				|WHERE
				|	(NOT CatalogItems.DeletionMark)
				|" + ?(vCatalogsHierarchical, "AND (NOT CatalogItems.IsFolder)", "") + "
				|	AND CatalogItems.Code = &qObjectExternalCode
				|	AND (CatalogItems.Owner = &qHotel
				|		OR &qHotelIsEmpty)";
				vQry.SetParameter("qHotel", pHotelRef);
				vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotelRef));
			Else
				If pWithFolders Then
					vCatalogsHierarchical = False;
				EndIf;
				vQry.Text = 
				"SELECT
				|	CatalogItems.Ref
				|FROM
				|	Catalog." + pObjectTypeName + " AS CatalogItems
				|WHERE
				|	(NOT CatalogItems.DeletionMark) 
				|" + ?(vCatalogsHierarchical, "AND (NOT CatalogItems.IsFolder)", "") + "
				|	AND CatalogItems.Code = &qObjectExternalCode";    
				If Metadata.Catalogs[pObjectTypeName].Attributes.Find("Hotel") <> Undefined Then
					vQry.Text = vQry.Text + " AND (CatalogItems.Hotel = &qHotel OR CatalogItems.Hotel = VALUE(Catalog.Hotels.EmptyRef) OR &qHotelIsEmpty)";
					vQry.SetParameter("qHotel", pHotelRef);
					vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotelRef));
				EndIf;	
			EndIf;
			If pObjectTypeName = "Currencies" And (TypeOf(pObjectExternalCode) = Type("Number") Or cmIsNumber(TrimAll(pObjectExternalCode))) Then
				vQry.SetParameter("qObjectExternalCode", Number(pObjectExternalCode));
			Else
				vQry.SetParameter("qObjectExternalCode", TrimAll(pObjectExternalCode));
			EndIf;
			vObjects = vQry.Execute().Unload();
			If vObjects.Count() = 1 Then
				vObjectRef = vObjects.Get(0).Ref;
			ElsIf pObjectTypeName = "Rooms" Then
				If pWithFolders Then
					vCatalogsHierarchical = False;
				EndIf;
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	CatalogItems.Ref
				|FROM
				|	Catalog." + pObjectTypeName + " AS CatalogItems
				|WHERE
				|	(NOT CatalogItems.DeletionMark)    
				|" + ?(vCatalogsHierarchical, "AND (NOT CatalogItems.IsFolder)", "") + "
				|	AND CatalogItems.Description = &qObjectExternalCode";
				
				If pObjectTypeName = "Currencies" And (TypeOf(pObjectExternalCode) = Type("Number") Or cmIsNumber(TrimAll(pObjectExternalCode))) Then
					vQry.SetParameter("qObjectExternalCode", Number(pObjectExternalCode));
				Else
					vQry.SetParameter("qObjectExternalCode", TrimAll(pObjectExternalCode));
				EndIf;
				vObjects = vQry.Execute().Unload();
				If vObjects.Count() = 1 Then
					vObjectRef = vObjects.Get(0).Ref;
				EndIf;
			EndIf;
		EndIf;
		If Not ValueIsFilled(vObjectRef) And Not IsBlankString(pObjectExternalCode) Then
			If pWithFolders Then
				vCatalogsHierarchical = False;
			EndIf;
			// Try to find object ref by description assuming that object type name is name of the catalog
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	CatalogItems.Ref
			|FROM
			|	Catalog." + pObjectTypeName + " AS CatalogItems
			|WHERE
			|	(NOT CatalogItems.DeletionMark)
			|" + ?(vCatalogsHierarchical, "AND (NOT CatalogItems.IsFolder)", "") + "
			|	AND CatalogItems.Description = &qObjectExternalCode";
			vQry.SetParameter("qObjectExternalCode", TrimAll(pObjectExternalCode));
			vObjects = vQry.Execute().Unload();
			If vObjects.Count() = 1 Then
				vObjectRef = vObjects.Get(0).Ref;
			EndIf;
		EndIf;
	EndIf;
	If Not IsBlankString(TrimAll(pObjectExternalCode)) And (vObjectRef = Undefined Or Not ValueIsFilled(vObjectRef)) And (Not ValueIsFilled(pInteraction) Or ValueIsFilled(pInteraction) And pInteraction.DebugMode) Then
		WriteLogEvent(NStr("en = 'Dataconversion.Object not found'; ru = 'Конверсия данных.Не найден объект по коду'; de = 'Datenkonvertierung.Kein Objekt vom Code gefunden'"),EventLogLevel.Warning,,,"Hotel="+pHotelRef+";ExternalSystemCode="+pExternalSystemCode+";ObjectTypeName="+pObjectTypeName+";ObjectExternalCode="+pObjectExternalCode);
	EndIf;
	Return vObjectRef;
EndFunction // cmGetObjectRefByExternalSystemCode 

// -----------------------------------------------------------------------------
// Description: Returns catalog object external code for the external system
// Parameters: Hotel, External system code, Name of the catalog in the 
//             metadata, Catalog object reference
// Return value: Code of the catalog object in the external system or empty string
// -----------------------------------------------------------------------------
Function cmGetObjectExternalSystemCodeByRef(pHotelRef, pExternalSystemCode, pObjectTypeName, pObjectRef, pEmptyIfNotFound = False, pGetCode = False) Export
	Return CachedSettings.cmGetObjectExternalSystemCodeByRefReUse(pHotelRef, pExternalSystemCode, pObjectTypeName, pObjectRef, pEmptyIfNotFound, pGetCode);
EndFunction // cmGetObjectRefByExternalSystemCode 

// -----------------------------------------------------------------------------
// Description: Checks catalog object external system code mapping exists
// Parameters: Hotel, External system code, Object item reference, Name of the catalog in the 
//             metadata
// Return value: Reference to the catalog object or undefined
// -----------------------------------------------------------------------------
Function cmCheckExternalSystemCodeMapping(pHotelRef, pExternalSystemCode, pObjectRef, pObjectTypeName) Export
	vReturn = False;
	// Try to find reference to the object in the program by external code
	If Not IsBlankString(pExternalSystemCode) And ValueIsFilled(pObjectRef) And Not IsBlankString(pObjectTypeName) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	(ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|			OR ExternalSystemsObjectCodesMappings.Hotel = &qEmptyHotel)
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
		|	AND ExternalSystemsObjectCodesMappings.ObjectRef = &qObjectRef";
		vQry.SetParameter("qHotel", pHotelRef);
		vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
		vQry.SetParameter("qExternalSystemCode", TrimAll(pExternalSystemCode));
		vQry.SetParameter("qObjectTypeName", TrimAll(pObjectTypeName));
		vQry.SetParameter("qObjectRef", pObjectRef);
		vMappings = vQry.Execute().Unload();
		If vMappings.Count() > 0 Then
			vReturn = True;
		EndIf;
	EndIf;
	Return vReturn;
EndFunction // cmCheckExternalSystemCodeMapping

// -----------------------------------------------------------------------------
// Description: Clears mappings for given hotel, external system name and object type
// Parameters: Hotel, External system code, Name of the catalog in the 
//             metadata
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmClearExternalSystemObjectMapping(pHotelRef, pExternalSystemCode, pObjectTypeName) Export
	vMgrObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
	vRcdSetObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordSet();
	
	vHotelFlt = vRcdSetObj.Filter.Hotel;
	vHotelFlt.ComparisonType = ComparisonType.Equal;
	vHotelFlt.Value = pHotelRef;
	vHotelFlt.Use = True;
	
	vExtSystemCodeFlt = vRcdSetObj.Filter.ExternalSystemCode;
	vExtSystemCodeFlt.ComparisonType = ComparisonType.Equal;
	vExtSystemCodeFlt.Value = TrimR(pExternalSystemCode);
	vExtSystemCodeFlt.Use = True;
	
	vObjectTypeFlt = vRcdSetObj.Filter.ObjectTypeName;
	vObjectTypeFlt.ComparisonType = ComparisonType.Equal;
	vObjectTypeFlt.Value = TrimR(pObjectTypeName);
	vObjectTypeFlt.Use = True;
	
	vRcdSetObj.Read();
	For Each vRcdSetObjRow In vRcdSetObj Do
		vObjectExternalCode = TrimR(vRcdSetObjRow.ObjectExternalCode);
		If pObjectTypeName = "AccommodationTypes" And 
		   (vObjectExternalCode = "OneGuestInRoom" Or vObjectExternalCode = "Together" Or vObjectExternalCode = "MainGuestInRoom") Then
			Continue;
		EndIf;
		vMgrObj.Hotel = pHotelRef;
		vMgrObj.ExternalSystemCode = TrimR(pExternalSystemCode);
		vMgrObj.ObjectTypeName = TrimR(pObjectTypeName);
		vMgrObj.ObjectExternalCode = vObjectExternalCode;
		vMgrObj.Read();
		If vMgrObj.Selected() Then
			vMgrObj.Delete();
		EndIf;
	EndDo;
EndProcedure // cmClearExternalSystemObjectMapping
	
// -----------------------------------------------------------------------------
// Description: Creates or updates record in external system objects mapping table
// Parameters: Hotel, External system code, Name of the catalog in the 
//             metadata, Код объекта в 1C:Отель, Код объекта во внешней системе
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmSaveExternalSystemObjectMapping(pHotelRef, pExternalSystemCode, pObjectTypeName, pObjectCode, pExtObjectCode) Export
	// Try to find object ref by code
	If Metadata.Catalogs[pObjectTypeName].Attributes.Find("Hotel") = Undefined Then
		vObjectRef = Catalogs[pObjectTypeName].FindByCode(TrimR(pObjectCode), False, , pHotelRef);
	Else
		vObjectRef = GetCatalogRef(pObjectTypeName, pObjectCode, pHotelRef);
	EndIf;
	// Try to update existing mapping or create new one
	vMgrObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
	vMgrObj.Hotel = pHotelRef;
	vMgrObj.ExternalSystemCode = TrimR(pExternalSystemCode);
	vMgrObj.ObjectTypeName = TrimR(pObjectTypeName);
	vMgrObj.ObjectExternalCode = TrimR(pExtObjectCode);
	vMgrObj.ObjectRef = vObjectRef;
	vMgrObj.Write(True);
EndProcedure // cmSaveExternalSystemObjectMapping

// -----------------------------------------------------------------------------
Function GetCatalogRef(pObjectTypeName, pObjectCode, pHotelRef)
	
	vCatalogsHierarchical = False;
	If Not IsBlankString(pObjectTypeName) Then
		vCatalogsHierarchical = Metadata.Catalogs[pObjectTypeName].Hierarchical;
	EndIf;
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	TabList.Ref
	|FROM
	|	Catalog."+pObjectTypeName+" AS TabList
	|WHERE
	|	NOT TabList.DeletionMark
	|" + ?(vCatalogsHierarchical, "AND (NOT TabList.IsFolder)", "") + "
	|	AND (TabList.Hotel = &qHotel
	|			OR TabList.Hotel = &qEmptyHotel)
	|	AND TabList.Code = &qObjectCode
	|
	|ORDER BY
	|	TabList.Ref.Code";
	vQry.SetParameter("qHotel", pHotelRef);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qObjectCode", pObjectCode);

	vRes = vQry.Execute();
	If vRes.IsEmpty() Then
		Return Undefined;
	Else
		vSel = vRes.Select();
		vSel.Next();
		Return vSel.Ref;
	EndIf;
	
EndFunction //  GetCatalogRef()

// -----------------------------------------------------------------------------
// Description: Creates or updates record in external system objects mapping table
// Parameters: Hotel, External system code, Name of the catalog in the 
//             metadata, Код объекта в 1C:Отель, Код объекта во внешней системе
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmDeleteExternalSystemObjectMapping(pHotelRef, pExternalSystemCode, pObjectTypeName, pObjectRef) Export
	// Try to update existing mapping or create new one
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.Hotel,
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode,
	|	ExternalSystemsObjectCodesMappings.ObjectTypeName,
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode,
	|	ExternalSystemsObjectCodesMappings.ObjectRef
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
	|	AND ExternalSystemsObjectCodesMappings.ObjectRef = &qObjectRef";
	vQry.SetParameter("qHotel", pHotelRef);
	vQry.SetParameter("qExternalSystemCode", TrimR(pExternalSystemCode));
	vQry.SetParameter("qObjectTypeName", TrimAll(pObjectTypeName));
	vQry.SetParameter("qObjectRef", pObjectRef);
	vRcds = vQry.Execute().Unload();
	For Each vRcdsRow In vRcds Do
		vMgrObj = InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vMgrObj.Hotel = vRcdsRow.Hotel;
		vMgrObj.ExternalSystemCode = TrimR(vRcdsRow.ExternalSystemCode);
		vMgrObj.ObjectTypeName = TrimAll(vRcdsRow.ObjectTypeName);
		vMgrObj.ObjectExternalCode = TrimR(vRcdsRow.ObjectExternalCode);
		vMgrObj.Read();
		If vMgrObj.Selected() Then
			vMgrObj.Delete();
		EndIf;
	EndDo;
EndProcedure // cmDeleteExternalSystemObjectMapping

// -----------------------------------------------------------------------------
// Description: Copies last to the current time interaction ID translation table data
// Parameters: None
// Return value: None
// -----------------------------------------------------------------------------
Procedure cmCopyLastTranslationTableData() Export
	// [ToDo]
EndProcedure // cmCopyLastTranslationTableData

// -----------------------------------------------------------------------------
// Description: Returns reference to interaction item by external id
// Parameters: Interaction ID as string, pAllInteractions - as boolean
// Return value: Reference to interaction item
// -----------------------------------------------------------------------------
Function cmGetInteractionByID(pInteractionID, pAllInteractions = False) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExternalSystemInteractions.Ref AS Ref
	|FROM
	|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	|WHERE
	|	NOT ExternalSystemInteractions.DeletionMark
	|	AND ExternalSystemInteractions.InteractionID = &qInteractionID
	|	AND NOT ExternalSystemInteractions.IsFolder
	|	AND CASE
	|			WHEN &qAllInteractions
	|				THEN TRUE
	|			ELSE ExternalSystemInteractions.IsActive
	|		END";
	vQry.SetParameter("qInteractionID", pInteractionID);
	vQry.SetParameter("qAllInteractions", pAllInteractions);
	vInteractionObj = Undefined;
	Return vQry.Execute().Unload();
EndFunction // cmGetInteractionByID

#EndRegion