
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  rMesseg	 - String	 - errors
// 
// Returns:
//  Boolean - True or false result processing
//
Function pmMerge(rMesseg) Export
	vResult = False;
	If Not ValueIsFilled(MainRef) Or Not ValueIsFilled(MergedRef) Then
		Raise NStr("en='Both reference must be included!';ru='Обе ссылки должны быть указаны!';de='Beide Referenzen müssen enthalten sein!'");
	EndIf;
	If TypeOf(MainRef) <> TypeOf(MergedRef) Then
		Raise NStr("en='The reference type must be the same!';ru='Тип ссылки должен быть одинаковый!';de='Der Referenztyp muss gleich sein!'");
	EndIf;     
	BeginTransaction(DataLockControlMode.Managed);
	Try
		vRefsArray = New Array();
		vRefsArray.Add(MergedRef);
		vTableRefs = FindByRef(vRefsArray);
		vInfoBaseUsersCount = 0;
		vCounter = 0;
		
		For Each vTableRef In vTableRefs Do
			If vCounter = 0 Then
				vCounter = vCounter + 1;
			ElsIf vCounter >= 1000 Then
				If TransactionActive() Then
					CommitTransaction();
					BeginTransaction(DataLockControlMode.Managed);
					vCounter = 1;
				Else
					BeginTransaction(DataLockControlMode.Managed);
					vCounter = 1;
				EndIf;
			EndIf;
			vCounter = vCounter + 1;
			If vTableRef.Metadata = Metadata.InformationRegisters.InfoBaseUsers And TypeOf(MergedRef) = Type("CatalogRef.Employees") Then
				vInfoBaseUsersCount = vInfoBaseUsersCount + 1;
				Continue;
			EndIf;
			
			If TypeOf(MergedRef) = Type("CatalogRef.Clients") Then
				ClientMergeAttributes();
			EndIf;	
				
			vObj = Undefined;
			If Metadata.Documents.Contains(vTableRef.Metadata) Then
				vObj = vTableRef.Data.GetObject();
				For Each vAttribute In vTableRef.Metadata.Attributes Do
					If vAttribute.Type.ContainsType(TypeOf(vTableRef.Ref)) And vObj[vAttribute.Name] = vTableRef.Ref Then
						vObj[vAttribute.Name] = MainRef;
					EndIf;
				EndDo;
				For Each vTS In vTableRef.Metadata.TabularSections Do
					For Each vAttribute In vTS.Attributes Do
						If vAttribute.Type.ContainsType(TypeOf(vTableRef.Ref)) Then
							vRowTS = vObj[vTS.Name].Find(vTableRef.Ref, vAttribute.Name);
							While vRowTS <> Undefined Do
								vRowTS[vAttribute.Name] = MainRef;
								vRowTS = vObj[vTS.Name].Find(vTableRef.Ref, vAttribute.Name);
							EndDo;
						EndIf;
					EndDo;
				EndDo;
				For Each RegisterRecord In vTableRef.Metadata.RegisterRecords Do
					vRecordSet = vObj.RegisterRecords[RegisterRecord.Name];
					vRecordSet.Read();
					vNeedToRecord = False;
					vTableSet = vRecordSet.Unload();
					If vTableSet.Count() = 0 Then
						Continue;
					EndIf;
					vArrNameRow = New Array();
					For Each vDimension In RegisterRecord.Dimensions Do
						If vDimension.Type.ContainsType(TypeOf(vTableRef.Ref)) Then
							vArrNameRow.Add(vDimension.Name);
						EndIf;
					EndDo;
					If Metadata.InformationRegisters.Contains(RegisterRecord) Then
						For Each vResource In RegisterRecord.Resources Do
							If vResource.Type.ContainsType(TypeOf(vTableRef.Ref)) Then
								vArrNameRow.Add(vResource.Name);
							EndIf;
						EndDo;
					EndIf;
					For Each vAttribute In RegisterRecord.Attributes Do
						If vAttribute.Type.ContainsType(TypeOf(vTableRef.Ref)) Then
							vArrNameRow.Add(vAttribute.Name);
						EndIf;
					EndDo;
					For Each vNameRow In vArrNameRow Do
						vRowTableSet = vTableSet.Find(vTableRef.Ref, vNameRow);
						While vRowTableSet <> Undefined Do
							vRowTableSet[vNameRow] = MainRef;
							vNeedToRecord = True;
							vRowTableSet = vTableSet.Find(vTableRef.Ref, vNameRow);
						EndDo;
					EndDo;
					If Metadata.AccountingRegisters.Contains(RegisterRecord) Then
						If vTableRef.Ref.Metadata() = RegisterRecord.ChartOfAccounts Then
							For Each vRowTableSet In vTableSet Do
								If vRowTableSet.Account = vTableRef.Ref Then
									vRowTableSet.Account = MainRef;
									vNeedToRecord = True;
								EndIf;
							EndDo;
						EndIf;
					EndIf;
					If Metadata.CalculationRegisters.Contains(RegisterRecord) Then
						vRowTableSet = vTableSet.Find(vTableRef.Ref, "CalculationType");
						While vRowTableSet <> Undefined Do
							vRowTableSet["CalculationType"] = MainRef;
							vNeedToRecord = True;
							vRowTableSet = vTableSet.Find(vTableRef.Ref, "CalculationType");
						EndDo;
					EndIf;
					If vNeedToRecord Then
						vRecordSet.Load(vTableSet);
						vRecordSet.DataExchange.Load = True;
						vRecordSet.Write();
						ExchangePlansRecordChanges(RegisterRecord, vRecordSet);
					EndIf;
					For Each vSequence In Metadata.Sequences Do
						If vSequence.Documents.Contains(vTableRef.Metadata) Then
							vNeedToRecord = False;
							vRecordSet = Sequences[vSequence.Name].CreateRecordSet();
							vRecordSet.Filter.Recorder.Set(vTableRef.Data);
							vRecordSet.Read();
							If vRecordSet.Count() > 0 Then
								For Each vDimension In vSequence.Dimensions Do
									If vDimension.Type.ContainsType(TypeOf(vTableRef.Ref)) And vRecordSet[0][vDimension.Name] = vTableRef.Ref Then
										vRecordSet[0][vDimension.Name] = MainRef;
										vNeedToRecord = True;
									EndIf;
								EndDo;
								If vNeedToRecord Then
									vRecordSet.DataExchange.Load = True;
									vRecordSet.Write();
									ExchangePlansRecordChanges(vSequence, vRecordSet);
								EndIf;
							EndIf;
						EndIf;
					EndDo;
				EndDo;
			ElsIf Metadata.Catalogs.Contains(vTableRef.Metadata) Then
				vObj = vTableRef.Data.GetObject();
				If vTableRef.Metadata.Owners.Contains(vTableRef.Ref.Metadata()) And vObj.Owner = vTableRef.Ref Then
					vObj.Owner = MainRef;
				EndIf;
				If vTableRef.Metadata.Hierarchical And vObj.Parent = vTableRef.Ref Then
					vObj.Parent = MainRef;
				EndIf;
				For Each vAttribute In vTableRef.Metadata.Attributes Do
					If vAttribute.Type.ContainsType(TypeOf(vTableRef.Ref)) And vObj[vAttribute.Name] = vTableRef.Ref Then
						vObj[vAttribute.Name] = MainRef;
					EndIf;
				EndDo;
				For Each vTS In vTableRef.Metadata.TabularSections Do
					For Each vAttribute In vTS.Attributes Do
						If vAttribute.Type.ContainsType(TypeOf(vTableRef.Ref)) Then
							vRowTS = vObj[vTS.Name].Find(vTableRef.Ref, vAttribute.Name);
							While vRowTS <> Undefined Do
								vRowTS[vAttribute.Name] = MainRef;
								vRowTS = vObj[vTS.Name].Find(vTableRef.Ref, vAttribute.Name);
							EndDo;
						EndIf;
					EndDo;
				EndDo;
			ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(vTableRef.Metadata)
				  Or Metadata.ChartsOfAccounts.Contains(vTableRef.Metadata)
				  Or Metadata.ChartsOfCalculationTypes.Contains(vTableRef.Metadata)
				  Or Metadata.Tasks.Contains(vTableRef.Metadata)
				  Or Metadata.BusinessProcesses.Contains(vTableRef.Metadata) Then
				vObj = vTableRef.Data.GetObject();
				For Each vAttribute In vTableRef.Metadata.Attributes Do
					If vAttribute.Type.ContainsType(TypeOf(vTableRef.Ref)) And vObj[vAttribute.Name] = vTableRef.Ref Then
						vObj[vAttribute.Name] = MainRef;
					EndIf;
				EndDo;
				For Each vTS In vTableRef.Metadata.TabularSections Do
					For Each vAttribute In vTS.Attributes Do
						If vAttribute.Type.ContainsType(TypeOf(vTableRef.Ref)) Then
							vRowTS = vObj[vTS.Name].Find(vTableRef.Ref, vAttribute.Name);
							While vRowTS <> Undefined Do
								vRowTS[vAttribute.Name] = MainRef;
								vRowTS = vObj[vTS.Name].Find(vTableRef.Ref, vAttribute.Name);
							EndDo;
						EndIf;
					EndDo;
				EndDo;
			ElsIf Metadata.Constants.Contains(vTableRef.Metadata) Then
				Constants[vTableRef.Metadata.Name].Set(MainRef);
			ElsIf Metadata.InformationRegisters.Contains(vTableRef.Metadata) Then
				vDimensionStructure = New Structure();
				vRecordSet = InformationRegisters[vTableRef.Metadata.Name].CreateRecordSet();
				For Each vDimensions In vTableRef.Metadata.Dimensions Do
					vRecordSet.Filter[vDimensions.Name].Set(vTableRef.Data[vDimensions.Name]);
					vDimensionStructure.Insert(vDimensions.Name);
				EndDo;
				If vTableRef.Metadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
					vRecordSet.Filter["Period"].Set(vTableRef.Data.Period);
				EndIf;
				vRecordSet.Read();
				If vRecordSet.Count() = 0 Then
					Continue;
				EndIf;
				vSetTable = vRecordSet.Unload();
				vRecordSet.Clear();
				vRecordSet.DataExchange.Load = True;
				vRecordSet.Write();
				For Each vCol In vSetTable.Columns Do
					If vSetTable[0][vCol.Name] = vTableRef.Ref Then
						vSetTable[0][vCol.Name] = MainRef;
						If vDimensionStructure.Property(vCol.Name) Then
							vRecordSet.Filter[vCol.Name].Set(MainRef);
						EndIf;
					EndIf;
				EndDo;
				vRecordSet.Load(vSetTable);
				vRecordSet.Write();
				ExchangePlansRecordChanges(vTableRef.Metadata, vRecordSet);
			Else
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Reference type '; de = 'Referenztyp '; ru = 'Ссылки типа '") + vTableRef.Metadata + NStr("en = ' are not replaced!'; de = ' werden nicht ersetzt!'; ru = ' не заменяются!'"));
			EndIf;
			If vObj <> Undefined Then
				vObj.DataExchange.Load = True;
				vObj.Write();
				ExchangePlansRecordChanges(vTableRef.Metadata, vObj);
			EndIf;
		EndDo;
		vTableRefs = FindByRef(vRefsArray);
		If vTableRefs.Count() - vInfoBaseUsersCount = 0 Then
			MergedRef.GetObject().Delete();
			MergedRef = Undefined;
		Else
			Raise NStr("en='Failed to process all references ';ru='Не удалось обработать все ссылки ';de='Fehler beim Verarbeiten aller Referenzen - '") + TrimAll(MergedRef.Description) + " (" + TrimAll(MergedRef.Code) + ")!";
		EndIf;
		
		vResult = True;   
		CommitTransaction();
	Except
		vErrorText = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		rMesseg = vErrorText;
		WriteLogEvent("MergeAnyRefs.pmMerge", EventLogLevel.Error, , , rMesseg);
		vResult = False;
	EndTry;
	Return vResult;
EndFunction // pmMerge

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pMetadata, pData)
	Try
		If Metadata.Documents.Contains(pMetadata) Then
			Documents[pMetadata.Name].ExchangePlansRecordChanges(pData);
		ElsIf Metadata.Catalogs.Contains(pMetadata) Then
			Catalogs[pMetadata.Name].ExchangePlansRecordChanges(pData);
		ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(pMetadata) Then
			ChartsOfCharacteristicTypes[pMetadata.Name].ExchangePlansRecordChanges(pData);
		ElsIf Metadata.ChartsOfAccounts.Contains(pMetadata) Then
			ChartsOfAccounts[pMetadata.Name].ExchangePlansRecordChanges(pData);
		ElsIf Metadata.InformationRegisters.Contains(pMetadata) Then
			InformationRegisters[pMetadata.Name].ExchangePlansRecordChanges(pData);
		ElsIf Metadata.AccountingRegisters.Contains(pMetadata) Then
			AccountingRegisters[pMetadata.Name].ExchangePlansRecordChanges(pData);
		ElsIf Metadata.AccumulationRegisters.Contains(pMetadata) Then
			AccumulationRegisters[pMetadata.Name].ExchangePlansRecordChanges(pData);
		Else
			Return;
		EndIf;
	Except
		Return;
	EndTry;
EndProcedure // ExchangePlansRecordChanges

// -----------------------------------------------------------------------------
Procedure ClientMergeAttributes()
	vMainRefObj = MainRef.GetObject();
	vIsChenged = False;
	For Each vAttribute In Metadata.Catalogs.Clients.Attributes Do
		If Not ValueIsFilled(MainRef[vAttribute.Name]) And ValueIsFilled(MergedRef[vAttribute.Name]) Then
			vMainRefObj[vAttribute.Name] = MergedRef[vAttribute.Name];
			vIsChenged = True;
		EndIf;
	EndDo;
	If vIsChenged Then
		vMainRefObj.Write();
		
		vEventDescription = NStr("en = 'Clients have been merged'; de = 'Mandanten wurden zusammengelegt'; ru = 'Выполнено объединение клиентов'");
		InformationRegisters.UserActionsHistory.WriteUserActivityRecord(MainRef, vEventDescription, SessionParameters.CurrentHotel);
	EndIf;
EndProcedure

#EndRegion 
