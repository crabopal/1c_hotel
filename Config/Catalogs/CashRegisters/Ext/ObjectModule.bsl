
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite 

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function pmGetLastClosedCashRegisterDay(Val pDate = Undefined) Export
	If Not ValueIsFilled(pDate) Then
		pDate = CurrentSessionDate();
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	CloseOfCashRegisterDay.Ref AS Ref
	|FROM
	|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDay
	|WHERE
	|	CloseOfCashRegisterDay.Posted
	|	AND CloseOfCashRegisterDay.CashRegister = &qCashRegister
	|	AND CloseOfCashRegisterDay.Date < &qDate
	|
	|ORDER BY
	|	CloseOfCashRegisterDay.PointInTime DESC";
	vQry.SetParameter("qCashRegister", Ref);
	vQry.SetParameter("qDate", pDate);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() > 0 Then
		Return vQryRes.Get(0).Ref;
	Else
		Return Undefined;
	EndIf;
EndFunction // pmGetLastClosedCashRegisterDay    

#EndRegion
