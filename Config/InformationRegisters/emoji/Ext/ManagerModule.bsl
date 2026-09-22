#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

//Initialise emoji from attached template
Procedure pmInit() Export
	vTextList = InformationRegisters.emoji.GetTemplate("List");
	i = 0;
	While i < vTextList.LineCount() Do
		i = i + 1;
		curLine = vTextList.GetLine(i);
		pos = StrFind(curLine,";");
		If pos = 0 Then
			Continue;
		EndIf;
		
		name = Mid(curLine,pos+1);
		code = Left(curLine,pos-1);
		
		tm = InformationRegisters.emoji.CreateRecordManager();
		
		tm.Name  = name;
		tm.urlString = StrReplace(code,"\x","%");
		tm.emString = DecodeString(tm.urlString,StringEncodingMethod.URLEncoding);
		tm.Write();		
	EndDO;
EndProcedure

#EndRegion


