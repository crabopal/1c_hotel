
#Region Public

// ---------------------------------------------------------------------
//
Procedure pmRun() Export
	#If Client Then
		// Show progress bar
		ProgressForm = GetCommonForm("Progress");
		ProgressForm.Open();
		ProgressForm.MaxValue = 100;
		ProgressForm.Value = 0;
		ProgressForm.ActionRemarks = NStr("en = 'Load...'; de = 'Laden von ...'; ru = 'Загрузка...'");
		ProgressForm.ValueRemarks = NStr("en = 'Loaded: '; de = 'Geladen: '; ru = 'Загружено: '");
	#EndIf
	
	BeginTransaction(DataLockControlMode.Managed);
	Try
		
		For Each vStr In Metadata.InformationRegisters.CodesFMS.Templates  Do
			#If Client Then
				ProgressForm.ActionRemarks = vStr.Synonym;
			#EndIf
			
			vType = vStr.Name;
			vList = InformationRegisters.CodesFMS.GetTemplate(vType);
			
			vCount = vList.TableHeight - 1;  
			vProgressFinished = 100;
			For vInt = 2 To (vCount + 1) Do
				#If Client Then
					ProgressForm.Value = (vInt - 1) * vProgressFinished / vCount;
				#EndIf
				vCode 				= vList.Area(vInt, 1, vInt, 1).Text;
				If vCode = "" Then
					Continue;
				EndIf;	  
				vIDDesc = 2;
				vIdCode = 3;
				vDescription = TrimAll(vList.Area(vInt, vIDDesc, vInt, vIDDesc).Text);
				vID = TrimAll(vList.Area(vInt, vIdCode, vInt, vIdCode).Text);
				If vID = "" And vDescription = "" Then
					Break;
				EndIf;	
				
				vRecordManager = InformationRegisters.CodesFMS.CreateRecordSet();
				vRecordManager.Filter.Code.Set(vCode);
				vRecordManager.Filter.ID.Set(vID);
				vRecordManager.Filter.Type.Set(vType);
				vRecordManager.Read();
				
				If  vRecordManager.Count() = 0  Then
					NewRecord =  vRecordManager.Add();
					NewRecord.Code = vCode;
					NewRecord.ID = vID;
					NewRecord.Description = vDescription;
					NewRecord.Type = vType;
				ElsIf   vRecordManager.Count() = 1 Then
					NewRecord = vRecordManager[0];
					NewRecord.Description = vDescription;
				EndIf;	
				vRecordManager.Write();
			EndDo;
			
			CommitTransaction();
		EndDo;
	Except    
		RollbackTransaction();
		vErrorDescription = ErrorDescription();
		#If Client Then
			If ProgressForm.IsOpen() Then
				ProgressForm.Close();
			EndIf;
		#EndIf
		Raise vErrorDescription;
	EndTry;
	#If Client Then
		If ProgressForm.IsOpen() Then
			ProgressForm.Close();
		EndIf;
	#EndIf             
	vMsg = NStr("en = 'Information about FMS units updated'; 
				|de = 'Informationen über FMS Einheiten aktualisiert'; 
				|ru = 'Информация о подразделениях ФМС обновлена'");
	tcCommonFunctionOnClientServer.TextMessage(vMsg, MessageStatus.Information);
EndProcedure // pmRun

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

#EndRegion
