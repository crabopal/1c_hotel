#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// DATA FROM THIS REGISTER SHOULD NOT BE DISTRIBUTED BETWEEN NODES
EndProcedure // ExchangePlansRecordChanges

// Initialise command names with default values
Procedure pmInit() Export
	vList = InformationRegisters.ChatCommands.GetTemplate("CommandsList");
	
	vCount = vList.TableHeight - 1;
	For i = 2 To (vCount + 1) Do
		vText 				= vList.Area(i, 1, i, 1).Text;
		If vText = "" Then
			Continue;
		EndIf;	
		vCommand = TrimAll(vList.Area(i, 2, i, 2).Text);
		If vCommand = "" Then
			Break;
		EndIf;	
		
		vRecordManager = InformationRegisters.ChatCommands.CreateRecordSet();
		vRecordManager.Filter.Text.Set(vText);
		vRecordManager.Read();
		
		If  vRecordManager.Count()=0  Then
			NewRecord =  vRecordManager.Add();
			NewRecord.Text 					= vText;
			NewRecord.CommandName			= vCommand;
		ElsIf   vRecordManager.Count()=1 Then
			NewRecord = vRecordManager[0];
			NewRecord.CommandName = vCommand;
		EndIf;	
		vRecordManager.Write();
	EndDo;

EndProcedure

#EndRegion


