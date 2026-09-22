
#Region Public

// -----------------------------------------------------------------------------
Procedure pmSaveReportAttributes(pGenerateOnly = False) Export
	cmSaveReportAttributes(ThisObject, , pGenerateOnly);
EndProcedure // pmSaveReportAttributes

// -----------------------------------------------------------------------------
Procedure pmLoadReportAttributes(pParameter = Undefined) Export
	cmLoadReportAttributes(ThisObject, pParameter);
EndProcedure // pmLoadReportAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill parameters with default values
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfYear(CurrentSessionDate());
	EndIf;
	If Not ValueIsFilled(PeriodTo) Then
		PeriodTo = EndOfQuarter(CurrentSessionDate());
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(Company) Then
			Company = Hotel.Company;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
Procedure pmGenerate(pSpreadsheet) Export
	// Clear output spreadsheet
	pSpreadsheet.Clear();
	
	// Choose template
	vTemplate = ThisObject.GetTemplate("Report");
	
	// Report header
	vHeaderArea = vTemplate.GetArea("Header");
	
	// Header parameters
	vHeaderArea.Parameters.mPeriodStr = PeriodPresentation(BegOfDay(PeriodFrom), EndOfDay(PeriodTo), cmLocalizationCode());
	vHeaderArea.Parameters.mCompanyName = TrimAll(Company.LegacyName);
	vHeaderArea.Parameters.mCompanyPostAddress = cmGetAddressPresentation(Company.PostAddress);
	vHeaderArea.Parameters.mCompanyOKPOCode = TrimAll(Company.OKPO);
	
	// Put header
	pSpreadsheet.Put(vHeaderArea);
	
	// Add page break
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Get total sales  
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SalesTurnovers.Hotel AS Hotel, 
	|   SalesTurnovers.Service AS Service,
	|	SUM(SalesTurnovers.SalesTurnover) AS SalesTurnover
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&qPeriodFrom,
	|			&qPeriodTo,
	|			Period,
	|			NOT IsCorrection 
	|				AND (Hotel = &qHotel OR &qIsEmptyHotel)
	|				AND Company = &qCompany
	|				) AS SalesTurnovers
	|
	|GROUP BY
	|	SalesTurnovers.Hotel,
	|	SalesTurnovers.Service
	|
	|ORDER BY
	|	SalesTurnovers.Service";
	vQry.SetParameter("qPeriodFrom", BegOfDay(PeriodFrom));
	vQry.SetParameter("qPeriodTo", EndOfDay(PeriodTo));
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qCompany", Company);    
	vQry.SetParameter("qIsEmptyHotel", True);    
	If ValueIsFilled(Hotel) Then
		vQry.SetParameter("qIsEmptyHotel", False);    
	EndIf;
	
	vQryResult = vQry.Execute().Unload(); 
	
	vServiceByCity = New ValueTable();
	vServiceByCity.Columns.Add("Hotel");
	vServiceByCity.Columns.Add("Service");
	vServiceByCity.Columns.Add("SalesTurnover");
	vServiceByCity.Columns.Add("City");
	
	For Each vQryResultRow In vQryResult Do		
		For i = 2 To 36 do   
			vNum = ?(i>9, String(i), "0"+String(i));
			If IsServInServiceGroup(vQryResultRow.Service, ThisObject["Service" + vNum]) Then 
				vFilters = New Structure;
				vFilters.Insert("Service", vQryResultRow.Service);
				vFilters.Insert("Hotel", vQryResultRow.Hotel);
				vRows = vServiceByCity.FindRows(vFilters);
				If vRows.Count() = 0 Then
					vNewRow = vServiceByCity.Add();  
					FillPropertyValues(vNewRow, vQryResultRow); 
					If ValueIsFilled(vQryResultRow.Hotel.PostAddress) Then
						vAddressFields = cmParseAddress(vQryResultRow.Hotel.PostAddress);
					   	If ValueIsFilled(vAddressFields.City) Then
							vNewRow.City = vAddressFields.City;
						EndIf;
					EndIf; 
				EndIf;
            EndIf;
		EndDo;
	EndDo; 
	
	vServiceAll = vServiceByCity.Copy();
    vServiceByCity.GroupBy("City", "SalesTurnover");
	vServiceAll.GroupBy("Service", "SalesTurnover");

	// Part 1 header
	vPart1HeaderArea = vTemplate.GetArea("Part1Header");
	
	// Put part 1 header
	pSpreadsheet.Put(vPart1HeaderArea);
	
	
	vSum = New Structure("mSum01, mSum02, mSum03, mSum04, mSum05, mSum06, mSum07, mSum08, mSum09, mSum10, mSum11, mSum12, mSum13, mSum14, mSum15, mSum16, mSum17, mSum18, mSum19, mSum20, mSum21, mSum22, mSum23, mSum24, mSum25, mSum26, mSum27, mSum28, mSum29, mSum30, mSum31, mSum32, mSum33, mSum34, mSum35, mSum36", 
							0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);	
							
	For Each vQryResultRow In vServiceAll Do
		For i = 2 To 36 do   
			vNum = ?(i>9, String(i), "0" + String(i));
			If IsServInServiceGroup(vQryResultRow.Service, ThisObject["Service" + vNum]) Then 
				vSum["mSum" + vNum] = vSum["mSum" + vNum] + vQryResultRow.SalesTurnover; 
				vSum.mSum01 = vSum.mSum01 + vQryResultRow.SalesTurnover; 
            EndIf;
		EndDo;
	EndDo;
	
	vPart1Area = vTemplate.GetArea("Part1");
	For Each vRowStr In vSum Do  
		vNum = StrReplace(vRowStr.Key, "mSum", "");
		vPart1Area.Parameters["mSum" + vNum] = 	Format(vRowStr.Value,"ND=12; NFD=2"); 
	EndDo;
	
	pSpreadsheet.Put(vPart1Area);
	
	//Part 2
	
	// Add page break
	pSpreadsheet.PutHorizontalPageBreak();
	
	// Part 2 header
	vPart2HeaderArea = vTemplate.GetArea("Part2Header");
	
	// Put part 2 header
	pSpreadsheet.Put(vPart2HeaderArea);
	
	vSumStr = 36;
	For Each vQryResultRow In vServiceByCity Do
        vPart2RowArea = vTemplate.GetArea("Part2Row");
		vPart2RowArea.Parameters.mCity = vQryResultRow.City;
		vSumStr = vSumStr + 1;
		vPart2RowArea.Parameters.mNumStr = vSumStr;
        vPart2RowArea.Parameters.mSum = Format(vQryResultRow.SalesTurnover,"ND=12; NFD=2");
		pSpreadsheet.Put(vPart2RowArea);
	EndDo;
	
	// Part 2 footer
	vPart2FooterArea = vTemplate.GetArea("Part2Footer");
	
	// Put part 2 footer
	pSpreadsheet.Put(vPart2FooterArea);
	
EndProcedure // pmGenerate

#EndRegion

// -----------------------------------------------------------------------------
Function IsServInServiceGroup(pService, pServiceGroup)
	If pServiceGroup.IncludeAll Then
		Return True;
	EndIf;
	vSrvGrpRow = pServiceGroup.Services.Find(pService, "Service");
	If vSrvGrpRow <> Undefined Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // IsServInServiceGroup
