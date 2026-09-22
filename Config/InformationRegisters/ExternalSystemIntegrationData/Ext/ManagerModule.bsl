#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
Procedure WriteData(pExternalSystem, pDataType, pDataName, pRefKey1, pRefKey2, pDataValue, pExternalSystemDataCode = Undefined) Export
	
	If NOT ValueIsFilled(pExternalSystem) OR NOT ValueIsFilled(pDataType) OR NOT ValueIsFilled(pDataName) Then
		Return;
	EndIf;
	
	vRecMng 							= InformationRegisters.ExternalSystemIntegrationData.CreateRecordManager();
	vRecMng.ExternalSystem 				= pExternalSystem;
	vRecMng.DataType 					= pDataType;
	vRecMng.DataName					= pDataName;
	vRecMng.RefKey1 					= pRefKey1;
	vRecMng.RefKey2 					= pRefKey2;
	vRecMng.ExternalSystemDataCode 		= pExternalSystemDataCode;
	vRecMng.DataValue					= pDataValue;
	vRecMng.Write(True);
	
EndProcedure

// -----------------------------------------------------------------------------
Procedure ClearDataByExternalSystemAndDataType(pExternalSystem, pDataType, pDataName = Undefined, pRefKey1 = Undefined, pRefKey2 = Undefined, pDataValue = Undefined, pExternalSystemDataCode = Undefined) Export
	
	If NOT ValueIsFilled(pExternalSystem) OR NOT ValueIsFilled(pDataType) Then
		Return;
	EndIf;
	
	vRecSet 											= InformationRegisters.ExternalSystemIntegrationData.CreateRecordSet();
	vRecSet.Filter.ExternalSystem.Use					= True;
	vRecSet.Filter.ExternalSystem.Value					= pExternalSystem;
	vRecSet.Filter.DataType.Use							= True;
	vRecSet.Filter.DataType.Value						= pDataType;
	If pDataName <> Undefined Then
		vRecSet.Filter.DataName.Use						= True;
		vRecSet.Filter.DataName.Value					= pDataName;	
	EndIf;
	If pRefKey1 <> Undefined Then
		vRecSet.Filter.RefKey1.Use						= True;
		vRecSet.Filter.RefKey1.Value					= pRefKey1;	
	EndIf;
	If pRefKey2 <> Undefined Then
		vRecSet.Filter.RefKey2.Use						= True;
		vRecSet.Filter.RefKey2.Value					= pRefKey2;	
	EndIf;
	If pExternalSystemDataCode <> Undefined Then
		vRecSet.Filter.ExternalSystemDataCode.Use		= True;
		vRecSet.Filter.ExternalSystemDataCode.Value		= pExternalSystemDataCode;	
	EndIf;
	vRecSet.Read();
	vRecSet.Clear();
	vRecSet.Write(True);
	
EndProcedure 

// -----------------------------------------------------------------------------
Procedure UpdateDataByExternalSystemAndDataType(pExternalSystem, pDataType, pDataName = Undefined, pRefKey1 = Undefined, pNewRefKey1 = Undefined, pRefKey2 = Undefined, pNewRefKey2 = Undefined, 
												pDataValue = Undefined, pNewDataValue = Undefined, pExternalSystemDataCode = Undefined, pNewExternalSystemDataCode = Undefined) Export
	
	If NOT ValueIsFilled(pExternalSystem) OR NOT ValueIsFilled(pDataType) Then
		Return;
	EndIf;
	
	If pNewRefKey1 = Undefined And pNewRefKey2 = Undefined And pNewDataValue = Undefined And pNewExternalSystemDataCode = Undefined Then
		Return;
	EndIf;
	
	vRecSet 											= InformationRegisters.ExternalSystemIntegrationData.CreateRecordSet();
	vRecSet.Filter.ExternalSystem.Use					= True;
	vRecSet.Filter.ExternalSystem.Value					= pExternalSystem;
	vRecSet.Filter.DataType.Use							= True;
	vRecSet.Filter.DataType.Value						= pDataType;
	If pDataName <> Undefined Then
		vRecSet.Filter.DataName.Use						= True;
		vRecSet.Filter.DataName.Value					= pDataName;	
	EndIf;
	If pRefKey1 <> Undefined Then
		vRecSet.Filter.RefKey1.Use						= True;
		vRecSet.Filter.RefKey1.Value					= pRefKey1;	
	EndIf;
	If pRefKey2 <> Undefined Then
		vRecSet.Filter.RefKey2.Use						= True;
		vRecSet.Filter.RefKey2.Value					= pRefKey2;	
	EndIf;
	If pExternalSystemDataCode <> Undefined Then
		vRecSet.Filter.ExternalSystemDataCode.Use		= True;
		vRecSet.Filter.ExternalSystemDataCode.Value		= pExternalSystemDataCode;	
	EndIf;
	vRecSet.Read();
	
	If vRecSet.Count() > 0 Then
		For Each vRow In vRecSet Do
			If pNewRefKey1 <> Undefined Then
				vRow.RefKey1 					= pNewRefKey1;	
			EndIf;
			If pNewRefKey2 <> Undefined Then
				vRow.RefKey2 					= pNewRefKey2;
			EndIf;  
			If pNewDataValue <> Undefined Then
				vRow.DataValue 					= pNewDataValue;	
			EndIf;
			If pNewExternalSystemDataCode <> Undefined Then
				vRow.ExternalSystemDataCode 	= pNewExternalSystemDataCode;	
			EndIf;		
		EndDo;
		vRecSet.Write(True);
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
Function GetData(pExternalSystem, pDataType, pDataName = Undefined, pRefKey1 = Undefined, pRefKey2 = Undefined, pValue = Undefined, pExternalSystemDataCode = Undefined) Export
	
	vResult 					= New ValueTable;
	vDefinedTypeDescription 	= Metadata.DefinedTypes.ExternalSystemInteractionRefTypes.Type;
	vResult.Columns.Add("RefKey1", vDefinedTypeDescription);
	vResult.Columns.Add("RefKey2", vDefinedTypeDescription);
	vResult.Columns.Add("ExternalSystemDataCode");

	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemIntegrationData.DataName AS DataName,
		|	ExternalSystemIntegrationData.RefKey1 AS RefKey1,
		|	ExternalSystemIntegrationData.RefKey2 AS RefKey2,
		|	ExternalSystemIntegrationData.DataValue AS DataValue,
		|	ExternalSystemIntegrationData.ExternalSystemDataCode AS ExternalSystemDataCode
		|FROM
		|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
		|WHERE
		|	ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem
		|	AND ExternalSystemIntegrationData.DataType = &qDataType
		|	AND CASE
		|			WHEN &qDataNameFilled
		|				THEN ExternalSystemIntegrationData.DataName = &qDataName
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qRefKey1Filled
		|				THEN ExternalSystemIntegrationData.RefKey1 IN (&qRefKey1)
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qRefKey2Filled
		|				THEN ExternalSystemIntegrationData.RefKey2 IN (&qRefKey2)
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qValueIsFilled
		|				THEN ExternalSystemIntegrationData.DataValue = &qValue
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qExternalSystemDataCodeIsFilled
		|				THEN ExternalSystemIntegrationData.ExternalSystemDataCode = &qExternalSystemDataCode
		|			ELSE TRUE
		|		END
		|
		|ORDER BY
		|	RefKey1,
		|	RefKey2,
		|	ExternalSystemDataCode";
	
	vQuery.SetParameter("qExternalSystem", 					pExternalSystem);
	vQuery.SetParameter("qDataType", 						pDataType);
	vQuery.SetParameter("qDataNameFilled", 					ValueIsFilled(pDataName));
	vQuery.SetParameter("qDataName", 						pDataName);
	If TypeOf(pRefKey1) = Type("Array") Then
		vQuery.SetParameter("qRefKey1Filled", 				pRefKey1.Count() > 0); 
	Else
		vQuery.SetParameter("qRefKey1Filled", 				ValueIsFilled(pRefKey1));	
	EndIf;
	vQuery.SetParameter("qRefKey1", 						pRefKey1);
	If TypeOf(pRefKey2) = Type("Array") Then
		vQuery.SetParameter("qRefKey2Filled", 				pRefKey2.Count() > 0); 
	Else
		vQuery.SetParameter("qRefKey2Filled", 				?(pRefKey2 <> Undefined, True, False));	
	EndIf;
	vQuery.SetParameter("qRefKey2", 						pRefKey2);
	vQuery.SetParameter("qValueIsFilled", 					ValueIsFilled(pValue));
	vQuery.SetParameter("qValue", 							pValue);
	vQuery.SetParameter("qExternalSystemDataCodeIsFilled", 	ValueIsFilled(pExternalSystemDataCode));
	vQuery.SetParameter("qExternalSystemDataCode", 			pExternalSystemDataCode);
	
	vQueryResult 	= vQuery.Execute().Unload();
	vDataNames 		= vQueryResult.UnloadColumn("DataName");
	
	For each vDataName in vDataNames Do
		If vResult.Columns.Find(vDataName) = Undefined Then
			vResult.Columns.Add(vDataName);
		EndIf;
	EndDo;
	
	vFilter = New Structure("RefKey1, RefKey2, ExternalSystemDataCode", Undefined, Undefined, Undefined);
	For each vRow in vQueryResult Do
		If vFilter.RefKey1 <> vRow.RefKey1 OR vFilter.RefKey2 <> vRow.RefKey2 OR vFilter.ExternalSystemDataCode <> vRow.ExternalSystemDataCode Then	
			vFilter.RefKey1 				= vRow.RefKey1;
			vFilter.RefKey2 				= vRow.RefKey2;
			vFilter.ExternalSystemDataCode 	= vRow.ExternalSystemDataCode;
			
			vNewRow 						= vResult.Add();
			vNewRow.RefKey1 				= vRow.RefKey1;
			vNewRow.RefKey2 				= vRow.RefKey2;
			vNewRow.ExternalSystemDataCode 	= vRow.ExternalSystemDataCode;
			
			vKeyRows 	= vQueryResult.FindRows(vFilter);
			For each vKeyRow in vKeyRows Do
				vNewRow[vKeyRow.DataName] = vKeyRow.DataValue;	
			EndDo;
		EndIf;
	EndDo;
	
	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetDataList(pExternalSystem, pDataType, pDataName = Undefined, pRefKey1 = Undefined, pRefKey2 = Undefined, pValue = Undefined, pExternalSystemDataCode = Undefined) Export
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemIntegrationData.DataName AS DataName,
		|	ExternalSystemIntegrationData.RefKey1 AS RefKey1,
		|	ExternalSystemIntegrationData.RefKey2 AS RefKey2,
		|	ExternalSystemIntegrationData.DataValue AS DataValue,
		|	ExternalSystemIntegrationData.ExternalSystemDataCode AS ExternalSystemDataCode,
		|	ExternalSystemIntegrationData.DataType AS DataType,
		|	ExternalSystemIntegrationData.ExternalSystem AS ExternalSystem
		|FROM
		|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
		|WHERE
		|	ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem
		|	AND ExternalSystemIntegrationData.DataType = &qDataType
		|	AND CASE
		|			WHEN &qDataNameFilled
		|				THEN ExternalSystemIntegrationData.DataName = &qDataName
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qRefKey1Filled
		|				THEN ExternalSystemIntegrationData.RefKey1 = &qRefKey1
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qRefKey2Filled
		|				THEN ExternalSystemIntegrationData.RefKey2 = &qRefKey2
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qValueIsFilled
		|				THEN ExternalSystemIntegrationData.DataValue = &qValue
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qExternalSystemDataCodeIsFilled
		|				THEN ExternalSystemIntegrationData.ExternalSystemDataCode = &qExternalSystemDataCode
		|			ELSE TRUE
		|		END
		|
		|ORDER BY
		|	RefKey1,
		|	RefKey2,
		|	ExternalSystemDataCode";
	
	vQuery.SetParameter("qExternalSystem", 					pExternalSystem);
	vQuery.SetParameter("qDataType", 						pDataType);
	vQuery.SetParameter("qDataNameFilled", 					ValueIsFilled(pDataName));
	vQuery.SetParameter("qDataName", 						pDataName);
	vQuery.SetParameter("qRefKey1Filled", 					ValueIsFilled(pRefKey1));
	vQuery.SetParameter("qRefKey1", 						pRefKey1);
	vQuery.SetParameter("qRefKey2Filled", 					?(pRefKey2 <> Undefined, True, False));
	vQuery.SetParameter("qRefKey2", 						pRefKey2);
	vQuery.SetParameter("qValueIsFilled", 					ValueIsFilled(pValue));
	vQuery.SetParameter("qValue", 							pValue);
	vQuery.SetParameter("qExternalSystemDataCodeIsFilled", 	ValueIsFilled(pExternalSystemDataCode));
	vQuery.SetParameter("qExternalSystemDataCode", 			pExternalSystemDataCode);
	
	vQueryResult 	= vQuery.Execute().Unload();
		
	Return vQueryResult;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetExternalSystem(pDataType, pDataName = Undefined, pRefKey1 = Undefined, pRefKey2 = Undefined, pValue = Undefined, pExternalSystemDataCode = Undefined) Export
	vExternalSystem = Catalogs.ExternalSystemInteractions.EmptyRef();
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemIntegrationData.ExternalSystem AS ExternalSystem
		|FROM
		|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
		|WHERE
		|	ExternalSystemIntegrationData.DataType = &qDataType
		|	AND CASE
		|			WHEN &qDataNameFilled
		|				THEN ExternalSystemIntegrationData.DataName = &qDataName
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qRefKey1Filled
		|				THEN ExternalSystemIntegrationData.RefKey1 = &qRefKey1
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qRefKey2Filled
		|				THEN ExternalSystemIntegrationData.RefKey2 = &qRefKey2
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qValueIsFilled
		|				THEN ExternalSystemIntegrationData.DataValue = &qValue
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qExternalSystemDataCodeIsFilled
		|				THEN ExternalSystemIntegrationData.ExternalSystemDataCode = &qExternalSystemDataCode
		|			ELSE TRUE
		|		END
		|	AND ExternalSystemIntegrationData.ExternalSystem.DataProcessor <> VALUE(Catalog.DataProcessors.EmptyRef)
		|	AND ExternalSystemIntegrationData.ExternalSystem.IsActive
		|	AND NOT ExternalSystemIntegrationData.ExternalSystem.DeletionMark
		|
		|GROUP BY
		|	ExternalSystemIntegrationData.ExternalSystem";
	
	vQuery.SetParameter("qDataType", 						pDataType);
	vQuery.SetParameter("qDataNameFilled", 					ValueIsFilled(pDataName));
	vQuery.SetParameter("qDataName", 						pDataName);
	vQuery.SetParameter("qRefKey1Filled", 					ValueIsFilled(pRefKey1));
	vQuery.SetParameter("qRefKey1", 						pRefKey1);
	vQuery.SetParameter("qRefKey2Filled", 					?(pRefKey2 <> Undefined, True, False));
	vQuery.SetParameter("qRefKey2", 						pRefKey2);
	vQuery.SetParameter("qValueIsFilled", 					ValueIsFilled(pValue));
	vQuery.SetParameter("qValue", 							pValue);
	vQuery.SetParameter("qExternalSystemDataCodeIsFilled", 	ValueIsFilled(pExternalSystemDataCode));
	vQuery.SetParameter("qExternalSystemDataCode", 			pExternalSystemDataCode);
	
	vQueryResult = vQuery.Execute().Unload();
	
	If vQueryResult.Count() = 1 Then
		vExternalSystem = vQueryResult[0].ExternalSystem; 	
	EndIf;

	Return vExternalSystem;
EndFunction // GetDataByRefKey

#EndRegion

