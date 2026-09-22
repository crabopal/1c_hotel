
#Region Public

// -----------------------------------------------------------------------------
//  Calculates bonuses balances by dates
//
// Parameters:
//  pCard			- CatalogRef.DiscountCards	- Ref
//  pDate			- Date					 	- Date
// 
// Returns:
//  Value table with boneses balances per bonuses expiry dates
//
Function cmGetBonusesBalancePerExpiryDates(pCard, pDate) Export
	vDate = pDate;
	If Not ValueIsFilled(pDate) Then
		vDate = CurrentSessionDate();
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	BonusesBalance.Card AS Card,
	|	BonusesBalance.ExpiryDate AS ExpiryDate,
	|	BonusesBalance.QuantityBalance AS QuantityBalance
	|FROM
	|	AccumulationRegister.Bonuses.Balance(
	|			&qPeriod,
	|			Card = &qCard) AS BonusesBalance
	|
	|ORDER BY
	|	Card,
	|	ExpiryDate";
	vQry.SetParameter("qCard", pCard);
	vQry.SetParameter("qPeriod", New Boundary(vDate, BoundaryType.Excluding));
	vBalances = vQry.Execute().Unload();
	Return vBalances;
EndFunction // cmGetBonusesBalancePerExpiryDates

#EndRegion
