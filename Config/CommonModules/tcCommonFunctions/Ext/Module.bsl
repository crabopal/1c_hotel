
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  String - Token
//
Function GetDadataToken(pHotel = Undefined) Export
	vHotel = tcOnServer.cmGetSessionParametersAttribute("CurrentHotel");
	If ValueIsFilled(pHotel) Then
		vHotel = pHotel;
	EndIf;	
	vDadataToken = "";
	vInteraction = tcOnServer.GetExternalSystemInteractionsByInteractionType(PredefinedValue("Enum.Integrations.DADATA"), vHotel);
	If ValueIsFilled(vInteraction) Then
		vDadataToken = tcOnServer.cmGetAttributeByRef(vInteraction, "OAuth_AccessToken");
	EndIf;
	Return vDadataToken;
EndFunction // GetDadataToken

// -----------------------------------------------------------------------------
//
// Parameters:
//  pMessage		 -  String - 
//  pParam1			 - 	Param1 - 
//  pParam2			 - 	Param1 - 
//  pParam3			 - 	Param1 - 
//  pParam4			 - 	Param1 - 
//  pParametersArray - 	Array - 
//  pDelimiterArray	 - 	Array - 
// 
// Returns:
//  String - Result string
//
Function cmSetTextParameters(pMessage, pParam1 = Undefined, pParam2 = Undefined, pParam3 = Undefined, pParam4 = Undefined, pParametersArray = Undefined, pDelimiterArray = Undefined) Export
	vResult	= pMessage;
	
	If pDelimiterArray <> Undefined and TypeOf(pDelimiterArray) = Type("Array") Then
		vDelimiterArray = pDelimiterArray;
	Else
		vDelimiterArray = new Array;
		vDelimiterArray.Add(" ");
		vDelimiterArray.Add(",");
		vDelimiterArray.Add(".");
		vDelimiterArray.Add(";");
		vDelimiterArray.Add("'");
		vDelimiterArray.Add(")");
		vDelimiterArray.Add("(");
		vDelimiterArray.Add("!");
		vDelimiterArray.Add("?");
		vDelimiterArray.Add("%");
		vDelimiterArray.Add("~");
		vDelimiterArray.Add("-");
		vDelimiterArray.Add("*");
		vDelimiterArray.Add("^");
		vDelimiterArray.Add(":");
		vDelimiterArray.Add("#");
		vDelimiterArray.Add("=");
		vDelimiterArray.Add("<");
		vDelimiterArray.Add(">");
		vDelimiterArray.Add("/");
		vDelimiterArray.Add("|");
		vDelimiterArray.Add("\");
		vDelimiterArray.Add("""");
		vDelimiterArray.Add("+");
		vDelimiterArray.Add("[");
		vDelimiterArray.Add("]");
		vDelimiterArray.Add("{");
		vDelimiterArray.Add("}");
	EndIf;
	
	If pParam1 <> Undefined Then
		vResult = FindTextParameterAndReplaceItWithValue(vResult, pParam1, vDelimiterArray);
	EndIf;
	
	If pParam2 <> Undefined Then
		vResult = FindTextParameterAndReplaceItWithValue(vResult, pParam2, vDelimiterArray);
	EndIf;
	
	If pParam3 <> Undefined Then
		vResult = FindTextParameterAndReplaceItWithValue(vResult, pParam3, vDelimiterArray);
	EndIf;
	
	If pParam4 <> Undefined Then
		vResult = FindTextParameterAndReplaceItWithValue(vResult, pParam4, vDelimiterArray);
	EndIf;
	
	If pParametersArray <> Undefined and TypeOf(pParametersArray) = Type("Array") Then 
		For each vParameter in pParametersArray Do
			vResult = FindTextParameterAndReplaceItWithValue(vResult, vParameter, vDelimiterArray);
		EndDo;
	EndIf;
	
	Return vResult;
EndFunction

// Get common module by name
//
// Parameters:
//  pNameModule	 - String	 - Name common module
// 
// Returns:
//  CommonModule, Undefined - Common module or undefined
//
Function cmGetCommonModule(pNameModule = "") Export 
	If tcOnServer.cmCheckExistObjectInMetadata("CommonModules", pNameModule) Then 
		vModule = Eval(pNameModule); 
	Else 
		vModule = Undefined;
	EndIf;
	
	Return vModule; 
EndFunction //  cmGetCommonModul()

// Generates a format string according to the "Unified format of electronic banking messages"
//  for displaying it in the form of a QR code
//
// Parameters:
//  pDocumentData	 - Structure - Input data to fill
// 
// Returns:
//  String - Format string according to the "Unified format of electronic banking messages"
//
Function cmGenerateBankFormattedString(pDocumentData) Export
	vFormatString = "";
	vErr = "";
	vSEP = "|";
	SFormat = "ST";
	vCodeVersion = "0001";
	vCodePage  = "2";	// 1 - WIN1251, 2 -UTF8, 3 - KOI8-R
	
	vSysData = SFormat + vCodeVersion + vCodePage;
	
	//Checking input data
	If Not CheckDataStructure(pDocumentData, vErr) Then
		tcCommonFunctionOnClientServer.TextMessage(vErr);
		Return "";
	EndIf;
	
	vRequiredAttributes = InitPaymentStruct();
	
	If Not IsBlankString(vErr) Then
		tcCommonFunctionOnClientServer.TextMessage(vErr);
		Return "";
	EndIf;
	
	// Genarate string
	vArrFormatString = New Array();
	vArrFormatString.Add(vSysData);
	
	For Each vElement In vRequiredAttributes Do
		vItem = vElement.Key;
		vRowValue = "";
		If pDocumentData.Property(vItem, vRowValue) And ValueIsFilled(vRowValue) Then
			If vItem = "Sum" Then
				vArrFormatString.Add(vItem + "=" + Format(vRowValue * 100, "NG="));
			Else	
				vArrFormatString.Add(vItem + "=" + TrimAll(vRowValue));	
			EndIf;
		EndIf;
	EndDo;
	
	vFormatString = StrReplace(StrConcat(vArrFormatString, vSEP), Chars.LF, " ");
	
	Return	vFormatString;
EndFunction

#EndRegion


#Region Private

// -----------------------------------------------------------------------------
Function FindTextParameterAndReplaceItWithValue(pMessage, pValue, pDelimiterArray)
	vResult			= pMessage;
	vStartPosition	= 0;
	vEndPosition	= 0;
	
	vStartPosition	= StrFind(vResult,"&");
	vFound = False;
	While vStartPosition <> 0 and vFound = False Do
		If Mid(vResult, vStartPosition + 1, 1) = " " Then
			vStartPosition	= StrFind(vResult,"&",, vStartPosition + 1);
		Else
			vFound = True;
		EndIf;
	EndDo;
	If vStartPosition <> 0 Then
		For i = 0 to 20 Do
			For each vDelimiter in pDelimiterArray Do
				If Mid(vResult, vStartPosition + i, 1) = vDelimiter Then
					vEndPosition = vStartPosition + i;
					Break;
				EndIf;
			EndDo;
			If vEndPosition <> 0 Then
				Break;
			EndIf;
		EndDo;
		
		If vEndPosition <> 0 Then
			vResult	= StrReplace(vResult, Mid(vResult, vStartPosition, vEndPosition - vStartPosition), String(pValue)); 
		EndIf; 
	Else
		Return vResult; 
	EndIf;

	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
// Checks the relevance of the input data for the generation of QR-Code
// 
// Parameters:
// 	pDocumentData - Structure - data for checking
// 	pErrorText - String - error text
// Returns:
// 	Boolean - result checking
Function CheckDataStructure(pDocumentData, pErrorText = "")
	vRes = True;
	
	vRA = New Structure();
	vRA.Insert("Name", "en = 'Company name'; de = 'Firmenname'; ru = 'Наименование фирмы'");
	vRA.Insert("PersonalAcc", "en = 'Account number'; de = 'Rechnungsnummer'; ru = 'Номер счета получателя'");
	vRA.Insert("BankName", "en = 'Name of the bank'; de = 'Bank Name'; ru = 'Наименование банка'");
	vRA.Insert("BIC", "en = 'Bank Identification Сode'; de = 'BIC der Bank'; ru = 'БИК банка'");
	vRA.Insert("CorrespAcc", "en = 'Correspondent account number'; de = 'Korrespondenzbank'; ru = 'Счет банка корреспондента'");
	vRA.Insert("Sum", "en = 'Sum'; de = 'Summe'; ru = 'Сумма платежа'");
	
	// Add additional tag
	If Not pDocumentData.Property("CorrespAcc") Then
		pDocumentData.Insert("CorrespAcc", "0");
	ElsIf IsBlankString(TrimAll(pDocumentData.CorrespAcc)) Then
		pDocumentData.CorrespAcc = "0";
	EndIf;	
	If Not pDocumentData.Property("TechCode") Then
		pDocumentData.Insert("TechCode", "11");
	EndIf;	
	
	vTempateError = NStr("en = 'To generate a QR-code, you must fill in the parameter: %1';
						 |de = 'Um einen QR-Code zu generieren, müssen Sie den Parameter: %1 eingeben';
						 |ru = 'Для генерации QR-code необходимо заполнить параметр: %1'");
	
	vTempateErrorLen = NStr("en = 'Parameter length: %1 must be equal to %2 characters'; 
							|de = 'Parameterlänge: %1 muss gleich %2 Zeichen sein'; 
							|ru = 'Длина параметра: %1 должна быть равна %2 символам'");

	vArrErrors = New Array();
	For Each vElement In vRA Do
		If Not pDocumentData.Property(vElement.Key) Or Not ValueIsFilled(pDocumentData[vElement.Key]) Then
			vArrErrors.Add(StrTemplate(vTempateError, NStr(vElement.Value))); 
		EndIf;
	EndDo;
	
	// Check length
	For Each vId In pDocumentData Do
		If vId.Key = "Name" Then
			pDocumentData.Name = Left(pDocumentData.Name, 160);
		ElsIf vId.Key = "PersonalAcc" Then
			pDocumentData.PersonalAcc = Left(pDocumentData.PersonalAcc,20);
			If StrLen(pDocumentData.PersonalAcc) <> 20 Then
				vArrErrors.Add(StrTemplate(vTempateErrorLen, NStr("en = 'Account number'; de = 'Rechnungsnummer'; ru = 'Номер счета получателя'"), "20"));
			EndIf;	
		ElsIf vId.Key = "BankName" Then
			pDocumentData.BankName = Left(pDocumentData.BankName,45);
		ElsIf vId.Key = "BIC" Then
			pDocumentData.BIC = Left(pDocumentData.BIC,9);	
			If StrLen(pDocumentData.BIC) <> 9 Then
				vArrErrors.Add(StrTemplate(vTempateErrorLen, NStr("en = 'Bank Identification Сode'; de = 'BIC der Bank'; ru = 'БИК банка'"), "9"));
			EndIf;	
		ElsIf vId.Key = "PayeeINN" Then
			pDocumentData.PayeeINN = Left(pDocumentData.PayeeINN,12);
			If StrLen(pDocumentData.PayeeINN) < 10 Then
				vArrErrors.Add(StrTemplate(vTempateErrorLen, NStr("en = 'TIN'; de = 'TIN'; ru = 'ИНН'"), "10/12"));
			EndIf;
		ElsIf vId.Key = "KPP" Then
			vPayeeINN = Left(pDocumentData.PayeeINN, 12);
			pDocumentData.KPP = Left(pDocumentData.KPP,9);
			If StrLen(vPayeeINN) < 12 Then
				If StrLen(pDocumentData.KPP) < 9 Then
					vArrErrors.Add(StrTemplate(vTempateErrorLen, NStr("en = 'KPP'; de = 'KPP'; ru = 'КПП'"), "9"));
				EndIf;
			EndIf;
		ElsIf vId.Key = "Purpose" Then
			pDocumentData.Purpose = Left(pDocumentData.Purpose, 210);
		EndIf;	
	EndDo;
	
	If vArrErrors.Count() > 0 Then
		vRes = False;
		pErrorText = StrConcat(vArrErrors, Chars.LF)
	EndIf;
		
	Return vRes;
EndFunction

// -----------------------------------------------------------------------------
Function InitPaymentStruct()
	vStruct = New Structure;                        
	vStruct.Insert("Name",        "");	// ТекстПолучателя
	vStruct.Insert("PersonalAcc", "");	// НомерСчетаПолучателя
	vStruct.Insert("BankName", 	  "");	// НаименованиеБанкаПолучателя
	vStruct.Insert("BIC",         "");	// БИКБанкаПолучателя
	vStruct.Insert("CorrespAcc",  "");	// СчетБанкаПолучателя
	vStruct.Insert("Sum",         "");  // СуммаЧислом в рублях
	
	vStruct.Insert("Purpose",     "");  // НазначениеПлатежа
	vStruct.Insert("PayeeINN",    "");  // ИНН Получателя
	vStruct.Insert("PayerINN",    "");  // ИНН Плательщика
	vStruct.Insert("DrawerStatus",""); 	// СтатусСоставителя
	vStruct.Insert("KPP",         "");  // КПП Получателя
	vStruct.Insert("CBC",         "");	// Код БК
	vStruct.Insert("OKTMO",       ""); 	// Код ОКТМО
	vStruct.Insert("PaytReason",  "");  // ПоказательОснования
	vStruct.Insert("TaxPeriod",   "");  // ПоказательПериода
	vStruct.Insert("DocNo",    	  "");  // ПоказательНомера
	vStruct.Insert("DocDate",     "");  // ПоказательДаты
	vStruct.Insert("TaxPaytKind", ""); 	// ПоказательТипа
		
	vStruct.Insert("lastName",    "");  // ФамилияПлательщика
	vStruct.Insert("firstName",   ""); 	// ИмяПлательщика
	vStruct.Insert("middleName",  "");  // ОтчествоПлательщика
	vStruct.Insert("payerAddress","");  // АдресПлательщика
	vStruct.Insert("personalAccount", ""); // ЛицевойСчетБюджетногоПолучателя
	vStruct.Insert("docIdx",      "");   // ИндексПлатежногоДокумента
	vStruct.Insert("pensAcc",     "");	 // СНИЛС
	vStruct.Insert("contract",	  "");	 // Номер Договора
	vStruct.Insert("persAcc",     "");   // Номер Лицевого Счета Плательщика
	vStruct.Insert("flat",		  "");	 // Номер Квартиры
	vStruct.Insert("phone",		  "");	 // Номер Телефона
	vStruct.Insert("payerIdType", "");   // Вид Плательщика
	vStruct.Insert("payerIdNum",  "");	 // Номер Плательщика
	vStruct.Insert("childFio",	  "");	 // ФИО Ребенка
	vStruct.Insert("birthDate",	  "");	// Дата Рождения
	vStruct.Insert("paymTerm",	  "");	// Срок Платежа
	vStruct.Insert("paymPeriod",  "");	// Период Оплаты
	vStruct.Insert("category",	  "");	// Вид Платежа
	vStruct.Insert("serviceName", "");	// Код Услуги
	vStruct.Insert("counterId",	  "");	// Номер ПрибораУчета
	vStruct.Insert("counterVal",  "");	// Показание ПрибораУчета
	vStruct.Insert("quittId",	  "");	// Номер Извещения
	vStruct.Insert("quittDate",	  "");	// Дата Извещения
	vStruct.Insert("instNum",	  "");	// Номер Учреждения
	vStruct.Insert("classNum",	  "");	// Номер Группы
	vStruct.Insert("specFio",	  "");	// ФИО Преподавателя
	vStruct.Insert("addAmount",	  "");	// Сумма Страховки
	vStruct.Insert("ruleId",	  "");	//НомерПостановления
	vStruct.Insert("execId", 	  "");	//НомерИсполнительногоПроизводства
	vStruct.Insert("regType",	  "");	//КодВидаПлатежа
	vStruct.Insert("uin",		  "");	//ИдентификаторНачисления
	vStruct.Insert("TechCode",	  "");	//ТехническийКод
	
	Return vStruct;
EndFunction	

#EndRegion