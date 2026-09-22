// ----------------------------------------------------------------------------
// Data processors framework start
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure //pmLoadDataProcessorAttributes

//-----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure //pmSaveDataProcessorAttributes

//-----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
//-----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// Fill parameters with default values
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(PeriodFrom) Then
		PeriodFrom = BegOfDay(CurrentSessionDate()) - 24*3600 ; // For yesterday
		PeriodTo = EndOfDay(PeriodFrom);
	EndIf;
EndProcedure //pmFillAttributesWithDefaultValues

//-----------------------------------------------------------------------------
// Run data processor in silent mode
//-----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False, pThinClient = False, pAddressStorage = "") Export
	// 1. Get data
	vInvoicesByGroupCustomer = GetInvoicesList();
	If vInvoicesByGroupCustomer.Count() > 0 Then		
		vPath = cmGetFullFileName("INVOICES", ExportDir);
		If pThinClient Then      
			// Temp dir at server to create files and archive
			vPath = cmGetFullFileName("INVOICES", TempFilesDir());	
		EndIf;
		
		DeleteFiles(vPath);
        CreateDirectory(vPath);
		
		vZPFileName = ?(pThinClient, vPath, ExportDir) + "\" + TrimAll(Hotel) + "_" + Format(CurrentSessionDate(), "DF=yyyyMMddHmmss") + ".zip";
		
		// Zip all output files
		vZP = New ZipFileWriter(vZPFileName);
		
		While vInvoicesByGroupCustomer.Next() Do
			vFullFilePath = vPath + "\" + cmGetValidFileName(TrimAll(vInvoicesByGroupCustomer.Company) + "_" + TrimAll(vInvoicesByGroupCustomer.Customer) + ".xml");
			
			WriteInvoiceCase(vInvoicesByGroupCustomer, vFullFilePath);
					
			vZP.Add(vFullFilePath, ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.DontProcess); 			
		EndDo;
  
		vZP.Write();
		If pThinClient Then
			pAddressStorage = PutToTempStorage(New BinaryData(vZPFileName), New UUID());	
		EndIf;
		DeleteFiles(vPath);
	EndIf;	
EndProcedure //pmRun

//-----------------------------------------------------------------------------
// Data processors framework end
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Returns the list of guests 
// checked in during export period
// 
Function GetInvoicesList()
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Settlement.Ref AS Ref,
	|	Settlement.Number AS Number,
	|	Settlement.Company AS Company,
	|	Settlement.AccountingCustomer AS Customer,
	|	Settlement.Date AS Date,
	|	Settlement.Remarks AS Remarks,
	|	Settlement.Sum AS Sum,
	|	Settlement.SumDue AS SumDue,
	|	Settlement.AccountingCurrency AS Currency,
	|	1 AS SettlementCount
	|FROM
	|	Document.Settlement AS Settlement
	|WHERE
	|	Settlement.Posted
	|	AND NOT Settlement.DoNotExportToTheAccountingSystem
	|	AND Settlement.Date >= &qPeriodFrom
	|	AND Settlement.Date <= &qPeriodTo
	|	AND Settlement.Hotel = &qHotel
	|
	|ORDER BY
	|	Settlement.Number
	|TOTALS
	|	MIN(Number),
	|	MAX(Company),
	|	SUM(Sum),
	|	SUM(SumDue),
	|	SUM(SettlementCount)
	|BY
	|	Customer";
	vQry.SetParameter("qPeriodFrom", PeriodFrom);
	vQry.SetParameter("qPeriodTo", PeriodTo);
	vQry.SetParameter("qHotel", Hotel);
		
	Return vQry.Execute().Select(QueryResultIteration.ByGroupsWithHierarchy);  
EndFunction //GetCheckedInGuests

//-----------------------------------------------------------------------------
Function GetServicesByInvoices(pInvoice)
vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SettlementServices.Service AS Service,
	|	SettlementServices.Price AS Price,
	|	SUM(SettlementServices.Quantity) AS Quantity,
	|	SUM(SettlementServices.Sum) AS Sum,
	|	SettlementServices.VATRate AS VATRate,
	|	SUM(SettlementServices.VATSum) AS VATSum,
	|	SettlementServices.Charge AS Charge,
	|	SettlementServices.Unit AS Unit,
	|	SettlementServices.AccountingDate AS AccountingDate
	|FROM
	|	Document.Settlement.Services AS SettlementServices
	|WHERE
	|	SettlementServices.Ref = &qInvoice
	|
	|GROUP BY
	|	SettlementServices.Service,
	|	SettlementServices.VATRate,
	|	SettlementServices.Price,
	|	SettlementServices.Charge,
	|	SettlementServices.Unit,
	|	SettlementServices.AccountingDate";
	vQry.SetParameter("qInvoice", pInvoice);
	Return vQry.Execute().Unload();	
EndFunction //GetServicesByInvoices

//-----------------------------------------------------------------------------
Function GetPaymentByInvoices(pInvoice)
vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SettlementPaymentDocuments.PaymentDocDate AS PaymentDocDate,
	|	SettlementPaymentDocuments.Sum AS Sum
	|FROM
	|	Document.Settlement.PaymentDocuments AS SettlementPaymentDocuments
	|WHERE
	|	SettlementPaymentDocuments.Ref = &qInvoice";
	vQry.SetParameter("qInvoice", pInvoice);
	Return vQry.Execute().Unload();	
EndFunction //GetPaymentByInvoices

//-----------------------------------------------------------------------------
Procedure WriteInvoiceCase(pInvoices, pFullFilePath)		
	vXMLWriter = New XMLWriter;
	vXMLWriter.OpenFile(pFullFilePath, "UTF-8");
	vXMLWriter.WriteXMLDeclaration();
	
	#Region Facturae 
	vXMLWriter.WriteStartElement("namespace:Facturae");
	vXMLWriter.WriteNamespaceMapping("namespace2", "http://uri.etsi.org/01903/v1.2.2#");
	vXMLWriter.WriteNamespaceMapping("namespace3", "http://www.w3.org/2000/09/xmldsig#");
	vXMLWriter.WriteNamespaceMapping("namespace", "http://www.facturae.gob.es/formato/Versiones/Facturaev3_2_2.xml");
	
	WriteInvoiceFileHeader(pInvoices, vXMLWriter);	
	WriteInvoiceParties(pInvoices, vXMLWriter);
	WriteInvoiceInvoices(pInvoices, vXMLWriter);
		
	vXMLWriter.WriteEndElement();
	#EndRegion 
	
	vXMLWriter.Close();
EndProcedure //WriteInvoiceCase

//-----------------------------------------------------------------------------
Procedure WriteInvoiceFileHeader(pInvoices, pXMLWriter)
	pXMLWriter.WriteStartElement("FileHeader");
	
	WriteXML(pXMLWriter, "3.2.2", "SchemaVersion");
	WriteXML(pXMLWriter, "L", "Modality");
	WriteXML(pXMLWriter, "EM", "InvoiceIssuerType");
	
	#Region Batch 
	pXMLWriter.WriteStartElement("Batch");
	
	vBatchIdentifier = pInvoices.Number;
	
	vCompany = pInvoices.Company;
	If ValueIsFilled(vCompany) Then
		vBatchIdentifier = TrimAll(vCompany.TIN) + vBatchIdentifier;   	
	EndIf;
	
	WriteXML(pXMLWriter, vBatchIdentifier, "BatchIdentifier");
	WriteXML(pXMLWriter, pInvoices.SettlementCount, "InvoicesCount");
	
	#Region TotalInvoicesAmount
	pXMLWriter.WriteStartElement("TotalInvoicesAmount");
	
	WriteXML(pXMLWriter, Format(pInvoices.Sum, "ND=17; NFD=2; NZ=0; NG="), "TotalAmount");
	
	pXMLWriter.WriteEndElement();
	#EndRegion 
	
	#Region TotalOutstandingAmount
	pXMLWriter.WriteStartElement("TotalOutstandingAmount");
	
	WriteXML(pXMLWriter, Format(pInvoices.SumDue, "ND=17; NFD=2; NZ=0; NG="), "TotalAmount");
	
	pXMLWriter.WriteEndElement();
	#EndRegion   
	
	#Region TotalExecutableAmount
	pXMLWriter.WriteStartElement("TotalExecutableAmount");
	
	WriteXML(pXMLWriter, Format(pInvoices.SumDue, "ND=17; NFD=2; NZ=0; NG="), "TotalAmount");
	
	pXMLWriter.WriteEndElement();
	#EndRegion
		
	WriteXML(pXMLWriter, Upper(TrimAll(Hotel.BaseCurrency.Description)), "InvoiceCurrencyCode");
	
	pXMLWriter.WriteEndElement();
	#EndRegion
	
	pXMLWriter.WriteEndElement();
EndProcedure //WriteInvoiceFileHeader

//-----------------------------------------------------------------------------
Procedure WriteInvoiceParties(pInvoices, pXMLWriter) 
	pXMLWriter.WriteStartElement("Parties");
	
	WriteInvoiceSellerParty(pXMLWriter, pInvoices.Company);
	WriteInvoiceBuyerParty(pXMLWriter, pInvoices.Customer);
	
	pXMLWriter.WriteEndElement();	
EndProcedure //WriteInvoiceParties

//-----------------------------------------------------------------------------
Procedure WriteInvoiceSellerParty(pXMLWriter, pCompany)  
	pXMLWriter.WriteStartElement("SellerParty");
	
	#Region TaxIdentification 
	pXMLWriter.WriteStartElement("TaxIdentification");
	
	WriteXML(pXMLWriter, "J", "PersonTypeCode");
	WriteXML(pXMLWriter, "R", "ResidenceTypeCode"); 
	vTIN = "";
	If ValueIsFilled(pCompany) Then
		vTIN = TrimAll(pCompany.TIN);
	EndIf;
	WriteXML(pXMLWriter, vTIN, "TaxIdentificationNumber");
	
	pXMLWriter.WriteEndElement();
	#EndRegion
	
	#Region LegalEntity 
	pXMLWriter.WriteStartElement("LegalEntity");
	
	WriteXML(pXMLWriter, TrimAll(pCompany.LegacyName), "CorporateName");
	
	#Region AddressInSpain 
	pXMLWriter.WriteStartElement("AddressInSpain");
	
	vLegacyAddress = pCompany.LegacyAddress;
	If ValueIsFilled(vLegacyAddress) Then

		vAddressFields = cmParseAddress(vLegacyAddress);
		
		WriteXML(pXMLWriter, vAddressFields.Street + ", " + vAddressFields.House, "Address");
		WriteXML(pXMLWriter, vAddressFields.PostCode, "PostCode");
		WriteXML(pXMLWriter, vAddressFields.City, "Town"); 
		WriteXML(pXMLWriter, vAddressFields.Region, "Province"); 
	EndIf;
	WriteXML(pXMLWriter, "ESP", "CountryCode");
	
	pXMLWriter.WriteEndElement();
	#EndRegion
	
	pXMLWriter.WriteEndElement();
	#EndRegion
	
	pXMLWriter.WriteEndElement();	
EndProcedure //WriteInvoiceSellerParty

//-----------------------------------------------------------------------------
Procedure WriteInvoiceBuyerParty(pXMLWriter, pCustomer)  
	pXMLWriter.WriteStartElement("BuyerParty");
	
	#Region TaxIdentification 
	pXMLWriter.WriteStartElement("TaxIdentification");
	
	If pCustomer.IsIndividual Then
		WriteXML(pXMLWriter, "F", "PersonTypeCode");
	Else
		WriteXML(pXMLWriter, "J", "PersonTypeCode");	
	EndIf;
	WriteXML(pXMLWriter, "R", "ResidenceTypeCode"); 
	vTIN = "";
	If ValueIsFilled(pCustomer) Then
		vTIN = TrimAll(pCustomer.TIN);
	EndIf;
	WriteXML(pXMLWriter, vTIN, "TaxIdentificationNumber");
	
	pXMLWriter.WriteEndElement();
	#EndRegion
		
	#Region LegalEntity    
	If Not pCustomer.IsIndividual Then
		pXMLWriter.WriteStartElement("LegalEntity");
		
		WriteXML(pXMLWriter, TrimAll(pCustomer.LegacyName), "CorporateName");
	Else
		pXMLWriter.WriteStartElement("Individual");
		
		vClient = pCustomer.Client; 
		If ValueIsFilled(vClient) Then 
			WriteXML(pXMLWriter, TrimAll(vClient.LastName), "Name");
			WriteXML(pXMLWriter, TrimAll(vClient.FirstName), "FirstSurname");
			WriteXML(pXMLWriter, TrimAll(vClient.SecondName), "SecondSurname");
		EndIf;
	EndIf;
	
	#Region AddressInSpain 
	pXMLWriter.WriteStartElement("AddressInSpain");
	
	vLegacyAddress = pCustomer.LegacyAddress;
	If ValueIsFilled(vLegacyAddress) AND ValueIsFilled(pCustomer.Country) AND pCustomer.Country.ISOCode3 = "ESP" Then

		vAddressFields = cmParseAddress(vLegacyAddress);
		
		WriteXML(pXMLWriter, vAddressFields.Street + ", " + vAddressFields.House, "Address");
		WriteXML(pXMLWriter, vAddressFields.PostCode, "PostCode");
		WriteXML(pXMLWriter, vAddressFields.City, "Town"); 
		WriteXML(pXMLWriter, vAddressFields.Region, "Province"); 
	
	EndIf;
	If ValueIsFilled(pCustomer.Country) Then
		WriteXML(pXMLWriter, pCustomer.Country.ISOCode3, "CountryCode");
	Else
		WriteXML(pXMLWriter, "", "CountryCode");
	EndIf;
	
	pXMLWriter.WriteEndElement();
	#EndRegion
	
	pXMLWriter.WriteEndElement();
	#EndRegion 		
						
	pXMLWriter.WriteEndElement();	
EndProcedure //WriteInvoiceBuyerParty

//-----------------------------------------------------------------------------
Procedure WriteInvoiceInvoices(pInvoices, pXMLWriter)
	pXMLWriter.WriteStartElement("Invoices");
	
	vInvoices = pInvoices.Select(); 
	
	While vInvoices.Next() Do
		vServices = GetServicesByInvoices(vInvoices.Ref); 
		vPayment = GetPaymentByInvoices(vInvoices.Ref);
		
		#Region Invoice
		pXMLWriter.WriteStartElement("Invoice");
		
		#Region InvoiceHeader
		pXMLWriter.WriteStartElement("InvoiceHeader");
		
		WriteXML(pXMLWriter, vInvoices.Number, "InvoiceNumber");
		WriteXML(pXMLWriter, "FA", "InvoiceDocumentType");
		WriteXML(pXMLWriter, "OO", "InvoiceClass");
		
		pXMLWriter.WriteEndElement();
		#EndRegion
		
		#Region InvoiceIssueData
		pXMLWriter.WriteStartElement("InvoiceIssueData");
		
		WriteXML(pXMLWriter, Format(vInvoices.Date, "DF=yyyy-MM-dd"), "IssueDate");
		WriteXML(pXMLWriter, TrimAll(vInvoices.Currency.Description), "InvoiceCurrencyCode");
		
		//#Region InvoicingPeriod
		//pXMLWriter.WriteStartElement("InvoicingPeriod");
		//
		//WriteXML(pXMLWriter, "", "StartDate");
		//WriteXML(pXMLWriter, "", "EndDate");  
		//
		//pXMLWriter.WriteEndElement();
		//#EndRegion
		
		WriteXML(pXMLWriter, TrimAll(vInvoices.Currency.Description), "TaxCurrencyCode");
		WriteXML(pXMLWriter, "es", "LanguageName");
		WriteXML(pXMLWriter, TrimAll(vInvoices.Remarks), "InvoiceDescription");
		
		pXMLWriter.WriteEndElement();
		#EndRegion
		
		#Region TaxesOutputs
		pXMLWriter.WriteStartElement("TaxesOutputs");
		
		vTaxServices = vServices.Copy(); 
		vTaxServices.GroupBy("VATRate", "VATSum, Sum");
		
		For Each vRow In vTaxServices Do
			If ValueIsFilled(vRow.VATRate) Then
				vVATRate = vRow.VATRate; 
				If Not vVATRate.NoVAT Then 
					WriteInvoiceTax(pXMLWriter, vVATRate.TaxRate, ?(vRow.Sum > 0, vRow.Sum, -vRow.Sum), ?(vRow.VATSum > 0, vRow.VATSum, -vRow.VATSum));
				EndIf;
			EndIf;
		EndDo;
		
		pXMLWriter.WriteEndElement();
		#EndRegion
		
		#Region InvoiceTotals
		pXMLWriter.WriteStartElement("InvoiceTotals");
			
		vTotalVatSum = vServices.Total("VATSum");
		vTatoalSum = vServices.Total("Sum");
		vTotalGros = vTatoalSum - vTotalVatSum;
		
		WriteXML(pXMLWriter, vTotalGros, "TotalGrossAmount");
		WriteXML(pXMLWriter, vTotalGros, "TotalGrossAmountBeforeTaxes");
		WriteXML(pXMLWriter, vTotalVatSum, "TotalTaxOutputs");
		WriteXML(pXMLWriter, "0.00", "TotalTaxesWithheld");
		WriteXML(pXMLWriter, vTatoalSum, "InvoiceTotal");   
		
		#Region PaymentsOnAccount
		pXMLWriter.WriteStartElement("PaymentsOnAccount");
			
		For Each vRow In vPayment Do
			#Region PaymentOnAccount
			pXMLWriter.WriteStartElement("PaymentOnAccount");
			
			WriteXML(pXMLWriter, Format(vRow.PaymentDocDate, "DF=yyyy-MM-dd"), "PaymentOnAccountDate");
			WriteXML(pXMLWriter, Format(vRow.Sum, "NFD=2; NZ=0; NG="), "PaymentOnAccountAmount");
			
			pXMLWriter.WriteEndElement();
			#EndRegion
		EndDo;
		
		pXMLWriter.WriteEndElement();
		#EndRegion
		
		vPaymentSumTotal = vPayment.Total("Sum"); 
		
		WriteXML(pXMLWriter, Format(vTatoalSum - vPaymentSumTotal, "NFD=2; NZ=0; NG="), "TotalOutstandingAmount");
		WriteXML(pXMLWriter, Format(vPaymentSumTotal, "NFD=2; NZ=0; NG="), "TotalPaymentsOnAccount");
		WriteXML(pXMLWriter, Format(vTatoalSum - vPaymentSumTotal, "NFD=2; NZ=0; NG="), "TotalExecutableAmount");
		
		pXMLWriter.WriteEndElement();
		#EndRegion

		#Region Items
		pXMLWriter.WriteStartElement("Items");
		 		
		For Each vRow In vServices Do
			WriteInvoiceItems(pXMLWriter, vRow.AccountingDate, vRow.Service.Code, vRow.Service.Description, vRow.Quantity, vRow.Price, vRow.VATRate, vRow.Sum, vRow.VATSum, vRow.Unit, vRow.Charge);	
		EndDo;
		
		pXMLWriter.WriteEndElement();
		#EndRegion
		
		pXMLWriter.WriteEndElement();
		#EndRegion	
	EndDo;
		
	pXMLWriter.WriteEndElement();
EndProcedure //WriteInvoiceInvoices

//-----------------------------------------------------------------------------
Procedure WriteInvoiceTax(pXMLWriter, pTaxRate, pSum, pVATSum)
	pXMLWriter.WriteStartElement("Tax");
	
	WriteXML(pXMLWriter, "01", "TaxTypeCode");
	WriteXML(pXMLWriter, Format(pTaxRate, "NFD=2; NZ=0; NG=0"), "TaxRate");
	
	pXMLWriter.WriteStartElement("TaxableBase");
	WriteXML(pXMLWriter, Format(pSum - pVATSum, "NFD=2; NZ=0; NG=0"), "TotalAmount");
	pXMLWriter.WriteEndElement(); 
	
	pXMLWriter.WriteStartElement("TaxAmount");
	WriteXML(pXMLWriter, Format(pVATSum, "NFD=2; NZ=0; NG=0"), "TotalAmount");
	pXMLWriter.WriteEndElement();
	
	pXMLWriter.WriteEndElement();
EndProcedure //WriteInvoiceTax

//-----------------------------------------------------------------------------
Procedure WriteInvoiceItems(pXMLWriter, pAccountingDate, pItemCode, pItemDescription, pQuantity, pPrice, pVATRate, pSum, pVATSum, pUnit, pCharge)
	pXMLWriter.WriteStartElement("InvoiceLine");
	
	WriteXML(pXMLWriter, TrimAll(pItemDescription), "ItemDescription");
	WriteXML(pXMLWriter, Format(pQuantity, "NFD=1; NZ=0; NG="), "Quantity");
	
	vUnitRef = Catalogs.Units.FindByDescription(pUnit);
	If vUnitRef <> Undefined Then
		WriteXML(pXMLWriter, TrimAll(vUnitRef.Code), "UnitOfMeasure"); 
	EndIf;

	vPrice = pPrice / (100 + cmGetVATTaxRate(pVATRate, pAccountingDate)) * 100;   
	WriteXML(pXMLWriter, Format(Round(vPrice, 6, RoundMode.Round15as20), "NFD=6; NZ=0; NG="), "UnitPriceWithoutTax");
	vTotalCost = pQuantity * vPrice;
	WriteXML(pXMLWriter, Format(Round(vTotalCost, 2, RoundMode.Round15as20), "NFD=2; NZ=0; NG="), "TotalCost");
	If ValueIsFilled(pCharge) And pCharge.DiscountSum > 0 Then
		#Region DiscountsAndRebates
		pXMLWriter.WriteStartElement("DiscountsAndRebates");
		
		#Region DiscountsAndRebates
		pXMLWriter.WriteStartElement("Discount");
		
		WriteXML(pXMLWriter, TrimAll(pCharge.DiscountConfirmationText), "DiscountReason");
		WriteXML(pXMLWriter, Format(pCharge.Discount, "NFD=2; NZ=0; NG="), "DiscountRate");
		WriteXML(pXMLWriter, Format(pCharge.DiscountSum, "NFD=2; NZ=0; NG="), "DiscountAmount");
	
		pXMLWriter.WriteEndElement();
		#EndRegion
		
		pXMLWriter.WriteEndElement();
		#EndRegion
	EndIf;
	WriteXML(pXMLWriter, Format(Round(vTotalCost - ?(ValueIsFilled(pCharge), pCharge.DiscountSum, 0), 2, RoundMode.Round15as20), "NFD=2; NZ=0; NG="), "GrossAmount");

	#Region TaxesOutputs
	pXMLWriter.WriteStartElement("TaxesOutputs");
	If ValueIsFilled(pVATRate) Then
		If Not pVATRate.NoVAT Then
			pXMLWriter.WriteStartElement("Tax");
			
			WriteXML(pXMLWriter, "01", "TaxTypeCode");
			WriteXML(pXMLWriter, Format(pVATRate.TaxRate, "NFD=2; NZ=0; NG=0"), "TaxRate");
			
			pXMLWriter.WriteStartElement("TaxableBase");
			WriteXML(pXMLWriter, Format(pSum - pVATSum, "NFD=2; NZ=0; NG=0"), "TotalAmount");
			pXMLWriter.WriteEndElement(); 
			
			pXMLWriter.WriteStartElement("TaxAmount");
			WriteXML(pXMLWriter, Format(pVATSum, "NFD=2; NZ=0; NG=0"), "TotalAmount");
			pXMLWriter.WriteEndElement();
			
			pXMLWriter.WriteEndElement();
		EndIf;
	EndIf;
	pXMLWriter.WriteEndElement();
	#EndRegion
	
	If ValueIsFilled(pCharge) Then
		WriteXML(pXMLWriter, Format(pCharge.ServiceDate, "DF=yyyy-MM-dd"), "TransactionDate");
	EndIf;
	
	WriteXML(pXMLWriter, TrimAll(pItemCode), "ArticleCode");	
	pXMLWriter.WriteEndElement();
EndProcedure //WriteInvoiceItems 

