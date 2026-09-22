
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not ThisForm.Parameters.Property("BaseRate", BaseRate) Then
		tcCommonFunctionOnClientServer.TextMessage(NSTr("en = 'Room rate to copy is not filled'; de = 'Der zu kopierende Tarif ist nicht gefüllt'; ru = 'Тариф для копирования не заполнен'"));
		Cancel = True;
		Return;
	EndIf;
	If BaseRate.IsFolder Then
		Cancel = True;
		Return;
	EndIf;
	NewCode = TrimAll(Left(BaseRate.Code,4))+"1";
	NewDescription = TrimAll(BaseRate.Description) + " - " + NStr("en='copy '; ru='копия ' de='Kopie '");
	isCopyAttributes = True;
	CopyCalendar = 0;
	CopyPrices = 0;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandOK(Command)
	newRate = MakeCopyAtServer();
	If newRate <> Undefined Then
		Close();
		ShowValue(,newRate);
	EndIf;
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function MakeCopyAtServer()
	newRate = BaseRate.Copy();
	newRate.Code = NewCode;
	newRate.Description = NewDescription;
	Try
		newRate.Write();
	Except
		tcCommonFunctionOnClientServer.TextMessage(ErrorDescription());
		Return Undefined;
	EndTry;
	
	If CopyCalendar = 1 Then
		CopyCalendar(BaseRate,newRate.Ref);
	EndIf;
	If CopyPrices = 1 Then
		CopyRoomRatePrices(BaseRate,newRate.Ref);
	EndIf;
	Return newRate.Ref;
EndFunction

// --------------------------------------------------------------------------------
&AtServer
Procedure CopyCalendar(fromRate,toRate)
	vNewCalendar = RatesManagement.CopyCalendar(fromRate.Calendar,NewDescription,NewCode);
 	// Save new calendar to the room rate
	vRoomRateObj = toRate.GetObject();
	vRoomRateObj.Calendar = vNewCalendar;
	vRoomRateObj.Write();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure CopyRoomRatePrices(fromRate,toRate)
	// 1. Get the list of Set room rate prices
	vQ = New Query;
	vQ.Text = "SELECT
	          |	SetRoomRatePrices.Ref AS Ref,
	          |	SetRoomRatePrices.Date AS Date
	          |FROM
	          |	Document.SetRoomRatePrices AS SetRoomRatePrices
	          |WHERE
	          |	SetRoomRatePrices.RoomRate = &qRoomRate
	          |	AND SetRoomRatePrices.Posted
	          |
	          |ORDER BY
	          |	SetRoomRatePrices.Date DESC";
	vQ.SetParameter("qRoomRate",fromRate);
	qRes = vQ.Execute().Select();
	// 2.Copy them 
	While qRes.Next() Do
		newDoc = qRes.Ref.Copy();
		newDoc.RoomRate = toRate;
		newDoc.Date = qRes.Date;
		Try
			newDoc.Write(DocumentWriteMode.Posting);
			newDoc.pmWriteToSetRoomRatePricesChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
		Except
			tcCommonFunctionOnClientServer.TextMessage(ErrorDescription());
		EndTry;
	EndDo;
EndProcedure

#EndRegion
