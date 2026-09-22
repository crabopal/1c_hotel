
#Region Public

// ---------------------------------------------------------------------------------
// Добавить группу отбора в коллекцию КоллекцияЭлементов.
//
// Параметры:
//  КоллекцияЭлементов - ОтборКомпоновкиДанных, КоллекцияЭлементовОтбораКомпоновкиДанных,
//                       ГруппаЭлементовОтбораКомпоновкиДанных - контейнер
//                       с элементами и группами отбора, например Список.Отбор или группа в отборе.
//  Представление      - Строка - представление группы.
//  ТипГруппы          - ТипГруппыЭлементовОтбораКомпоновкиДанных - тип группы.
//
// Возвращаемое значение:
//  ГруппаЭлементовОтбораКомпоновкиДанных - группа отбора.
//
Function cmAddFilterItemsGroup(Val КоллекцияЭлементов, Представление, ТипГруппы) Export
	
	If ТипЗнч(КоллекцияЭлементов) = Тип("ГруппаЭлементовОтбораКомпоновкиДанных") Then
		КоллекцияЭлементов = КоллекцияЭлементов.Элементы;
	EndIf;
	
	ГруппаЭлементовОтбора = cmFindFilterItemByPresentation(КоллекцияЭлементов, Представление);
	If ГруппаЭлементовОтбора = Undefined Then
		ГруппаЭлементовОтбора = КоллекцияЭлементов.Добавить(Тип("ГруппаЭлементовОтбораКомпоновкиДанных"));
	Else
		ГруппаЭлементовОтбора.Элементы.Очистить();
	EndIf;
	
	ГруппаЭлементовОтбора.Представление    = Представление;
	ГруппаЭлементовОтбора.Применение       = ТипПримененияОтбораКомпоновкиДанных.Элементы;
	ГруппаЭлементовОтбора.РежимОтображения = РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный;
	ГруппаЭлементовОтбора.ТипГруппы        = ТипГруппы;
	ГруппаЭлементовОтбора.Использование    = Истина;
	
	Return ГруппаЭлементовОтбора;
	
EndFunction

// ---------------------------------------------------------------------------------
// Удалить элементы отбора с заданным именем поля или представлением.
//
// Параметры:
//  ОбластьУдаления - КоллекцияЭлементовОтбораКомпоновкиДанных - контейнер с элементами и группами отбора,
//                                                               например, Список.Отбор или группа в отборе..
//  ИмяПоля         - Строка - имя поля компоновки (не используется для групп).
//  Представление   - Строка - представление поля компоновки.
//
Procedure cmDeleteFilterItemsGroup(Val ОбластьУдаления, Val ИмяПоля = Undefined, Val Представление = Undefined) Export
	
	If ValueIsFilled(ИмяПоля) Then
		ЗначениеПоиска = New ПолеКомпоновкиДанных(ИмяПоля);
		СпособПоиска = 1;
	Else
		СпособПоиска = 2;
		ЗначениеПоиска = Представление;
	EndIf;
	
	МассивЭлементов = New Array;
	
	cmFindRecursively(ОбластьУдаления.Элементы, МассивЭлементов, СпособПоиска, ЗначениеПоиска);
	
	For Each  Элемент In МассивЭлементов Do
		If Элемент.Родитель = Undefined Then
			ОбластьУдаления.Элементы.Удалить(Элемент);
		Else
			Элемент.Родитель.Элементы.Удалить(Элемент);
		EndIf;
	EndDo;
	
EndProcedure

// ---------------------------------------------------------------------------------
// Установить или обновить значение параметра pNameAttribute динамического списка Список.
//
// Параметры:
//  pList          - ДинамическийСписок - реквизит формы, для которого требуется установить параметр.
//  pNameAttribute    - Строка             - имя параметра динамического списка.
//  pValue        - Произвольный        - новое значение параметра.
//  pUse   - Булево             - признак использования параметра.
//
Procedure cmSetOrRefreshDynamicListParameter(pList, pNameAttribute, pValue, pUse = True) Export
	
	vCurValueAttribute = pList.Parameters.FindParameterValue(New DataCompositionParameter(pNameAttribute));
	If vCurValueAttribute <> Undefined Then
		If pUse И vCurValueAttribute.Value <> pValue Then
			vCurValueAttribute.Value = pValue;
		EndIf;
		If vCurValueAttribute.Use <> pUse Then
			vCurValueAttribute.Use = pUse;
		EndIf;
	EndIf;
	
EndProcedure

// ---------------------------------------------------------------------------------
// Удалить элемент группы отбора динамического списка.
//
// Параметры:
//  ДинамическийСписок - ДинамическийСписок - реквизит формы, для которого требуется установить отбор.
//  ИмяПоля         - Строка - имя поля компоновки (не используется для групп).
//  Представление   - Строка - представление поля компоновки.
//
Procedure cmDeleteDynamicListSelectionGroupItems(ДинамическийСписок, ИмяПоля = Undefined, Представление = Undefined) Export
	
	cmDeleteFilterItemsGroup(
		ДинамическийСписок.КомпоновщикНастроек.ФиксированныеНастройки.Отбор,
		ИмяПоля,
		Представление);
	
	cmDeleteFilterItemsGroup(
		ДинамическийСписок.КомпоновщикНастроек.Настройки.Отбор,
		ИмяПоля,
		Представление);
	
EndProcedure

// ---------------------------------------------------------------------------------
//  Sets the title of the form the name of the hotel
//
// Parameters:
//  pForm	 - Form	 - The form for which you want to set the title
//  pPrefix	 - String - Prefix
//
&AtClient
Procedure cmSetFormTitleHotelName(pForm, pPrefix="") Export 
	pForm.AutoTitle = False;
	pForm.Title = pPrefix+tcOnServer.cmGetHotelPresentation();
EndProcedure //  cmSetFormTitleHotelName()

// ---------------------------------------------------------------------------------
//  Close all windows
//
&AtClient
Procedure cmCloseAllWindows() Export 
	//Close all windows
	vWindows = GetWindows();
	For Each vWnd In vWindows  Do
		If vWnd.HomePage = False And vWnd.Content.Count()>0 Then
			vCurForm = vWnd.Content[0];
			vCurForm.Close();
		EndIf;	
	EndDo;
EndProcedure //  cmCloseAllWindows()

// ---------------------------------------------------------------------------------
//  Get color attribute value as color object
//
// Parameters:
//  pRef - CatalogRef	 - Any ref
// 
// Returns:
//  Color - 
//
&AtServer
Function cmGetColorFromValueStorage(pRef) Export
	vColor = pRef["Color"].Get();
	If vColor <> Undefined And TypeOf(vColor) <> Type("Color") Then
		vColor = Undefined;
	EndIf;
	Return vColor;
EndFunction // cmGetColorFromValueStorage

// ---------------------------------------------------------------------------------
//  Выполняет поиск элемента отбора в коллекции по заданному представлению.
//
// Parameters:
//  pCollection	 - КоллекцияЭлементовОтбораКомпоновкиДанных	 - контейнер с элементами и группами отбора,
//  	например, Список.Отбор.Элементы или группа в отборе.
//  pDescription - Строка									 - представление группы.
// 
// Returns:
//  DataCompositionFilterItem - Item.
//
Function cmFindFilterItemByPresentation(pCollection, pDescription) Export
	
	vReturnValue = Undefined;
	
	For Each vItem In pCollection Do
		If vItem.Presentation = pDescription Then
			vReturnValue = vItem;
			Break;
		EndIf;
	EndDo;
	
	Return vReturnValue
	
EndFunction

// ---------------------------------------------------------------------------------
//
// Parameters:
//  pListAttribute		 - Array - 
//  pFilterFieldName	 - String	 - 
//  pFilterFieldValue	 - Any		 - 
//  pFieldName			 - String	 - 
//  pBackColor			 - Color	 - 
//
&AtServer
Procedure cmAddBackColorToTheListCell(pListAttribute, pFilterFieldName, pFilterFieldValue, pFieldName, pBackColor) Export
	vCndAppItem = pListAttribute.ConditionalAppearance.Items.Add();
	
	vFilterItem = vCndAppItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vFilterItem.LeftValue = New DataCompositionField(pFilterFieldName);
	vFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	vFilterItem.RightValue = pFilterFieldValue;
	vFilterItem.Use = True;
	
	vCndAppItem.Appearance.SetParameterValue("BackColor", pBackColor);
	
	vFieldItem = vCndAppItem.Fields.Items.Add();
	vFieldItem.Field = New DataCompositionField(pFieldName);
EndProcedure //  cmAddBackColorToTheListCell

// ---------------------------------------------------------------------------------
// Add conditional appearance
//
// Parameters:
//  pConditionalAppearance	 - ConditionalAppearance - Conditional appearance managed form
//  pParameters				 - Structure			 - Structure.Key - name parameter,  Structure.Value - value parameter
//  pFilters				 - ValueTable			 - ValueTable.FildName - String, ValueTable.ComparisonType - DataCompositionComparisonType, ValueTable.Value  - Selection condition.
//  pFields					 - Array.String			 - Array fields
//
&AtServer
Procedure cmAddConditionalAppearance(pConditionalAppearance, pParameters, pFilters, pFields) Export
	
	vDayTypeAppearance = pConditionalAppearance.Items.Add();
	// Set parameters
	For Each vParam In pParameters Do
		vDayTypeAppearance.Appearance.SetParameterValue(vParam.Key, vParam.Value);
	EndDo; 
	// Set filter field
	For Each vStr In pFilters Do
		vDayTypeAppearanceFilter = vDayTypeAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vDayTypeAppearanceFilter.LeftValue = New DataCompositionField(vStr.Name);
		vDayTypeAppearanceFilter.ComparisonType = vStr.ComparisonType;
		vDayTypeAppearanceFilter.RightValue = vStr.Value;
		vDayTypeAppearanceFilter.Use = True;
	EndDo; 
	// Fields
	For Each vField In pFields Do
		vDayTypeAppearanceField = vDayTypeAppearance.Fields.Items.Add();
		vDayTypeAppearanceField.Field = New DataCompositionField(vField);
		vDayTypeAppearanceField.Use = True;
	EndDo; 
EndProcedure //  cmAddConditionalAppirance() 

// ------------------------------------------------------------------------------------
//  Adds brackets [] around formula symbol name
//
// Parameters:
//  pSymbol	 - String - Parameter
// 
// Returns:
//  String - Symbol
//
Function GetFormulaSymbolName(pSymbol) Export
	vSymbol = TrimAll(pSymbol);
	vSymbol = StrReplace(vSymbol, " ", "");
	vSymbol = StrReplace(vSymbol, "[", "");
	vSymbol = StrReplace(vSymbol, "]", "");
	vSymbol = "[" + vSymbol + "]";
	Return vSymbol;
EndFunction //  GetFormulaSymbolName

// ------------------------------------------------------------------------------------
//  Shows user message in the messages panel
//  Usage examples:
//  
//  1. Для вывода сообщения у поля управляемой формы, связанного с реквизитом объекта:
//  tcCommonFunctionOnClientServer.UserMessage(NStr("ru = 'Сообщение об ошибке!'; en = 'Error message!'; de = 'Fehlermeldung!'"), , "ObjectAttribute", "Object");
//  
//  Альтернативный вариант использования в форме объекта:
//  tcCommonFunctionOnClientServer.UserMessage(NStr("ru = 'Сообщение об ошибке!'; en = 'Error message!'; de = 'Fehlermeldung!'"), , "Object.ObjectAttribute");
//  
//  2. Для вывода сообщения рядом с полем управляемой формы, связанным с реквизитом формы:
//  tcCommonFunctionOnClientServer.UserMessage(NStr("ru = 'Сообщение об ошибке!'; en = 'Error message!'; de = 'Fehlermeldung!'"), , "FormAttributeName");
//  
//  3. Для вывода сообщения связанного с объектом информационной базы:
//  tcCommonFunctionOnClientServer.UserMessage(НСтр("ru = 'Сообщение об ошибке!'; en = 'Error message!'; de = 'Fehlermeldung!'"), InfobaseObject, "Author", , True);
//  
//  4. Для вывода сообщения по ссылке на объект информационной базы:
//  tcCommonFunctionOnClientServer.UserMessage(НСтр("ru = 'Сообщение об ошибке!'; en = 'Error message!'; de = 'Fehlermeldung!'"), Ref, , , True);
//  
//  Случаи некорректного использования:
//  1. Передача одновременно параметров pDataKey и pDataPath.
//  2. Передача в параметре pDataKey значения типа отличного от допустимых.
//  3. Установка ссылки без установки поля (и/или пути к данным).
//
// Parameters:
//  pMessage	 - String	 - Message text
//  pDataKey	 - String	 - The object or key of the infobase entry to which this message refers
//  pField		 - String	 - Form attribute name
//  pDataPath	 - String	 - Contains a path in the form
//  pIsObject	 - Boolean	 - Specifies whether the pDataPath parameter contains a string or an object
//
Procedure UserMessage(Val pMessage,	Val pDataKey = Undefined, Val pField = "", Val pDataPath = "", pIsObject = False) Export
	vMessage = New UserMessage;
	vMessage.Text = pMessage;
	vMessage.Field = pField;
	
	If pIsObject Then
		vMessage.SetData(pDataKey);
	Else
		vMessage.DataKey = pDataKey;
	EndIf;
	
	If Not IsBlankString(pDataPath) Then
		vMessage.DataPath = pDataPath;
	EndIf;
	
	vMessage.Message();
EndProcedure

// ------------------------------------------------------------------------------------
//  Shows text message in the messages panel. Use instead standard Message() function
//
// Parameters:
//  pMessage		 - String		 - Message text
//  pMessageStatus	 - MessageStatus - Message status to be shown before message text
//
Procedure TextMessage(Val pMessage, pMessageStatus = Undefined) Export
	#IF ThickClientOrdinaryApplication THEN
		// ACC:69-off Use old fashioned message style in thick client mode
		Message(pMessage, pMessageStatus);
		// ACC:69-on
	#ELSE
		vMessage = "";
		If pMessageStatus = MessageStatus.Attention Then
			vMessage = "!!! - " + TrimAll(pMessage);
		ElsIf pMessageStatus = MessageStatus.VeryImportant Then
			vMessage = "!! - " + TrimAll(pMessage);
		ElsIf pMessageStatus = MessageStatus.Important Then
			vMessage = "! - " + TrimAll(pMessage);
		ElsIf pMessageStatus = MessageStatus.Information Then
			vMessage = "i - " + TrimAll(pMessage);
		ElsIf pMessageStatus = MessageStatus.Ordinary Then
			vMessage = "- " + TrimAll(pMessage);
		Else
			vMessage = TrimAll(pMessage);
		EndIf;
		UserMessage(vMessage);
	#ENDIF
EndProcedure // TextMessage

// ------------------------------------------------------------------------------------
//  Convert from decimal to any number system.
//
// Parameters:
//  pValue	 - Number	 - Value to covert.
//  pSystem	 - Number	 - number system.
// 
// Returns:
//  String - result.
//
Function DecToAnyNumberSystem(Val pValue = 0, Val pSystem = 16) Export
	If pSystem <= 0 Then 
		Return "";
	КонецЕсли;
	pValue = Number(pValue);
	If pValue <= 0 Then 
		Return "0";
	КонецЕсли;
	
	pValue = Int(pValue);
	vResult = "";
	vStr = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"; 
	While pValue > 0 Do
		vResult = Mid(vStr, pValue % pSystem + 1, 1) + vResult;
		pValue = Int(pValue / pSystem);		
	EndDo;
	
	Return vResult;
EndFunction // ConvertFrom10ToAnyNumberSystem()

// ------------------------------------------------------------------------------------
// The function converts a HEX number to DEC
//
// Parameters:
//  pHexString	 - String	 - HEX number
// 
// Returns:
//  Number - Dec number
//
Function HexToDecNumberSystem(Val pHexString) Export
	
	If pHexString = "0" Then 
		Return 0;
	EndIf;
	
	vHexChars	= "0123456789ABCDEF";
	pHexString 	= TrimAll(pHexString);
	vMultiplier = StrLen(pHexString) - 1;
	vRes 		= 0;
	vId 		= 1;
	vBasis		= 16;
	While vMultiplier >= 0 Do
		vCurSymbol 	= Mid(pHexString, vId, 1);
		vPres 	= StrFind(vHexChars, vCurSymbol) - 1;
		vRes 	= vRes + vPres * Pow(vBasis, vMultiplier);
		vMultiplier = vMultiplier - 1;
		vId	= vId + 1;
	EndDo;
	
	Return vRes;
	
EndFunction // HexToDecNumberSystem()  

// ------------------------------------------------------------------------------------
//  Color creation constructor, to reduce rule validation triggers in ACC configuration.
//
// Parameters:
//  pRed	 - Number	 - component of red.
//  pGreen	 - Number	 - component of green.
//  pBlue	 - Number	 - component of blue.
// 
// Returns:
//  Color - color created via constructor.
//
Function ColorConstructor(Val pRed = Undefined, Val pGreen = Undefined, Val pBlue = Undefined) Export
	vColor = Undefined;
	// ACC:1346-off      
	If pRed = Undefined Or pGreen = Undefined Or pBlue = Undefined Then 
		vColor = New Color();
	Else
		vColor = New Color(pRed, pGreen, pBlue);	
	EndIf;
	// ACC:1346-on
	Return vColor;
EndFunction

// ------------------------------------------------------------------------------------
// Font constructor
//
// Parameters:
//  pFontName	 - Sting - FontName
//  pSize		 - Number - Font size 
//  pBold		 - Boolean - Bold
//  pItalics	 - Boolean	 - Italics 
//  pUnderscore	 - Boolean	 - Underscore
//  pStrikeOut	 - Boolean	 - Strike out
//  pScale		 - Number	 - Scale
// 
// Returns:
//  Font - Font created via constructor.
//
Function FontConstructor(Val pFontName = Undefined, Val pSize = Undefined, Val pBold = Undefined, Val pItalics = Undefined, Val pUnderscore = Undefined, Val pStrikeOut = Undefined, Val pScale = Undefined) Export
	
	// ACC:1346-off
	Return New Font(pFontName, pSize, pBold, pItalics, pUnderscore, pStrikeOut, pScale);
	// ACC:1346-on
	
EndFunction // FontConstructor()

// ---------------------------------------------------------------------------------
//  Pads a string with characters to the left or right to the specified length
//
// Parameters:
//  pStr			 - String	 - Input string
//  pNumberSymbols	 - Number	 - Number symbols
//  pSymbol			 - String	 - Symbol
//  pLeft			 - Boolean	 - Add to left or right
// 
// Returns:
//  String - Result
//
Function ComplementString(Val pStr, Val pNumberSymbols, Val pSymbol = "0", pLeft = True) Export 
	pStr = TrimAll(pStr);
	vNum = pNumberSymbols - StrLen(pStr);
	If vNum > 0 Then
		vNewStr = "";
		For vId = 1 To vNum Do
			vNewStr = vNewStr + pSymbol;
		EndDo;   
		If pLeft Then
			pStr = vNewStr + pStr;
		Else
			pStr = pStr + vNewStr;
		EndIf;
	EndIf;
	Return pStr;
EndFunction

// ---------------------------------------------------------------------------------
//
// Parameters:
//  pBorderType	 - ControlBorderType - Border type
//  pThickness	 - Number	 - Thickness
// 
// Returns:
//  Border - Border object
//
Function BorderConstructor(pBorderType, pThickness = 1) Export

	Return  New Border(pBorderType, pThickness);

EndFunction // BorderConstructor()

// ---------------------------------------------------------------------------------
//  Pads a string with characters to the left or right to the specified length
//
// Parameters:
//  pFile	 - File	 - The file to be checked
// 
// Returns:
//  Boolean - Result
//
Function cmExists(pFile) Export 
	Try
    	Return pFile.Exists(); 
	Except
		Return pFile.Exist();
	EndTry;	
EndFunction // cmExists

// ---------------------------------------------------------------------------------
//  Сheck your email for correct spelling
//
// Parameters:
//  pTextEmail		 - String	 - mail
//  pAttributeCheck	 - String	 - attribute check
// 
// Returns:
//  Boolean - Result
//
Function CheckEmail(pTextEmail, pAttributeCheck = "Email", pShowMessage = True) Export
	If IsBlankString(pTextEmail) Then
		Return True;
	EndIf;
	
	vErrorMessage = Nstr("en = 'The EMail is typed incorrectly, please, check the EMail and rewrite it!';de = 'Die E-Mail ist falsch eingegeben, bitte, überprüfen Sie die E-Mail und schreiben Sie sie neu!';ru = 'Неправильно набран EMail, пожалуйста, уточните EMail и перезапишите!'");
	
	NumberOfEntries =  StrOccurrenceCount(pTextEmail, "/");
	If NumberOfEntries > 0 Then
		pTextEmail = StrReplace(pTextEmail, "/", ".");
	EndIf;
	
	Try
		If Not tcOnServer.cmStrLikeByRegularExpression(pTextEmail, "^[a-zA-Z0-9_%+-]+(\.[a-zA-Z0-9_%+-]+)*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") Then
			If pShowMessage Then
				tcCommonFunctionOnClientServer.UserMessage(vErrorMessage, , pAttributeCheck);
			EndIf;
			Return False;
		EndIf;
	Except
		Try
			vArrayProhibited = New Array;
			vArrayProhibited.Add(" ");
			vArrayProhibited.Add("	");
			vArrayProhibited.Add("!");
			vArrayProhibited.Add("#");
			vArrayProhibited.Add("$");
			vArrayProhibited.Add("%");
			vArrayProhibited.Add("&");
			vArrayProhibited.Add("`");
			vArrayProhibited.Add("=");
			vArrayProhibited.Add(",");
			vArrayProhibited.Add("'");
			vArrayProhibited.Add("..");
			vArrayProhibited.Add("""");
			vArrayProhibited.Add("№");
			vArrayProhibited.Add(";");
			vArrayProhibited.Add(":");
			vArrayProhibited.Add("?");
			vArrayProhibited.Add("*");
			vArrayProhibited.Add(">");
			vArrayProhibited.Add("<");
			vArrayProhibited.Add("[");
			vArrayProhibited.Add("]");
			vArrayProhibited.Add("{");
			vArrayProhibited.Add("}");
			vArrayProhibited.Add("~");
			vArrayProhibited.Add("^");
			vArrayProhibited.Add("'"); 
			
			For Each vStr In vArrayProhibited Do
				If StrOccurrenceCount(pTextEmail, vStr) > 0 Then
					Raise vErrorMessage;
				EndIf;
			EndDo;
			
			If StrConcat(StrSplit(Lower(pTextEmail), "абвгдеёжзийклмнопрстуфхцчшщъыьэюя")) <> Lower(pTextEmail)
				Or StrEndsWith(pTextEmail, ".") = True
				Or StrStartsWith(pTextEmail, ".") = True
				Or StrOccurrenceCount(pTextEmail, "@") <> 1
				And StrLen(pTextEmail) > 0 Then
				
				Raise vErrorMessage;
			EndIf;
			
			vIndexDog = StrFind(pTextEmail, "@");
			vDomainPart = Mid(pTextEmail, vIndexDog + 1);
			If StrFind(vDomainPart,".") = 0 And StrLen(pTextEmail) > 0 Then
				Raise vErrorMessage;
			EndIf;
		Except
			vErrorInfo = ErrorInfo();
			vText = ErrorProcessing.BriefErrorDescription(vErrorInfo);
			If pShowMessage Then
				tcCommonFunctionOnClientServer.UserMessage(vText, , pAttributeCheck);
			EndIf;
			Return False;
		EndTry;
	EndTry;
	
	Return True;
EndFunction // CheckEmail

// ---------------------------------------------------------------------------------
//
// Parameters:
//  pValue	 - String	 - Number in basis number system
//  pBasis	 - Number	 - Number system
// 
// Returns:
//  Number - Number in 10 number system
//
Function BasicToDec(Val pValue, Val pBasis) Export
	vResult = 0;
	vLength = StrLen(pValue);
	For vChar = 1 To StrLen(pValue) Do
		vMultiplier = 1;
		For vCount = 1 To vLength - vChar Do 
			vMultiplier = vMultiplier * pBasis;
		EndDo;
		vResult = vResult + (Find("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", Mid(pValue, vChar, 1))-1) * vMultiplier;
	EndDo;
	Return Round(vResult);
EndFunction // BasicToDec

// ---------------------------------------------------------------------------------
//
// Parameters:
//  pDec	 - Number	 - Number in 10 number system
//  pBasis	 - Number	 - Number system
// 
// Returns:
//  String - Number in basis number system
//
Function DecToBasic(Val pDec, Val pBasis) Export
	vResult = "";
	While pDec <> 0 Do
		vIndex =pDec % pBasis;
		vResult = Mid("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", vIndex + 1, 1) + vResult;
		pDec = Int(pDec / pBasis);
	EndDo;
	Return vResult
EndFunction // DecToBasic

// ---------------------------------------------------------------------------------
//
// Parameters:
//  pItem			 - FormItem	 - Item for change
//  pFilterField	 - String - Choice parameter name	
//  pNewParametrs	 - Array - Choice parameter values 
//
Procedure cmChangeItemChoiceParameters(pItem, pFilterField, pNewParametrs) Export
	vNewFilterItems = New FixedArray(pNewParametrs);
	vNewParam = New ChoiceParameter("Filter." + pFilterField, vNewFilterItems);
	
	vFilterIterms = New Array();
	vFilterIterms.Add(vNewParam);

	vNewParams = New FixedArray(vFilterIterms);
	pItem.ChoiceParameters = vNewParams; 	
EndProcedure

// ---------------------------------------------------------------------------------
// 
// Returns:
//  Number - 24 * 60 * 60 
//
Function cmOneDay(pDays = 1) Export 
	
	vAd = pDays * 24 * 60 * 60;
	Return vAd;

EndFunction // cmOneDay()

// --------------------------------------------------------------------------------
//
// Parameters:
//  pFormat			 - String	 - Date format
//  pDateString		 - String	 - Date string
//  pFormatLanguage	 - String	 - Format language
//  pSkip			 - Boolean	 - Skip extra checks
//  rSuccess		 - Boolean	 - Success
// 
// Returns:
//  Date - Result
//
Function StringToDateByFormat(Val pFormat, Val pDateString, pFormatLanguage = "", pSkip = False, rSuccess = False) Export
	vLanguage = "";
	If Not IsBlankString(pFormatLanguage) Then
		vLanguage = "L=" + pFormatLanguage +";";
	EndIf;
	
	Try
		vDate = Format('00010101', "DF=" + pFormat);
	Except
		Return '00010101';
	EndTry;
	
	vFM = New Map;
	For i = 1 To StrLen(pFormat) + 7 Do
		vFM[Mid(pFormat + "dMyHhms", i, 1)] = 0;
	EndDo;
	
	vDateString = pDateString;
	For i = 1 To 12 Do
		vDateString = StrReplace(vDateString, Format(Date(1, i, 2), vLanguage + "DF=MMММ"), Format(i, "ND=4; NZ=; NLZ=; NG="));
		vDateString = StrReplace(vDateString, Format(Date(1, i, 2), vLanguage + "DF=MMМ"), Format(i, "ND=3; NZ=; NLZ=; NG="));
	EndDo;
	
	For i = 1 To StrLen(pFormat) Do
		vFM[Mid(pFormat, i, 1)] = 10 * vFM[Mid(pFormat, i, 1)] + StrFind("123456789", Mid(vDateString, i, 1));
	EndDo;
	
	vFM["y"] = vFM["y"] + ?(vFM["y"] < 50, 2000, ?(vFM["y"] < 100, 1900, 0));
	
	vDate = '00010101';
	Try
		vDate = Date(vFM["y"], vFM["M"], vFM["d"], vFM["H"] + vFM["h"], vFM["m"], vFM["s"]);
	Except
		vDate = '00010101';
	EndTry;
	
	If Format(vDate, "DF=" + pFormat) = pDateString Then
		rSuccess = True;
	EndIf;
	
	If pSkip Or rSuccess Then
		Return vDate;
	EndIf;
	
	vOccurrenceDayCount = StrOccurrenceCount(pFormat, "d");
	If Not rSuccess And vOccurrenceDayCount = 1 Then
		vFormat = StrConcat(StrSplit(pFormat, "d", True), "dd");
		vDate = StringToDateByFormat(vFormat, pDateString, pFormatLanguage, True, rSuccess);
	EndIf;
	
	vOccurrenceMonthCount = StrOccurrenceCount(pFormat, "M");
	If Not rSuccess And vOccurrenceMonthCount = 1 Then
		vFormat = StrConcat(StrSplit(pFormat, "M", True), "MM");
		vDate = StringToDateByFormat(vFormat, pDateString, pFormatLanguage, True, rSuccess);
	EndIf;
	
	If Not rSuccess And vOccurrenceDayCount = 1 And vOccurrenceMonthCount = 1 Then
		vFormat = StrConcat(StrSplit(StrConcat(StrSplit(pFormat, "d", True), "dd"), "M", True), "MM");
		vDate = StringToDateByFormat(vFormat, pDateString, pFormatLanguage, True, rSuccess);
	EndIf;
	
	Return vDate;
EndFunction // StringToDateByFormat

// ---------------------------------------------------------------------------------
Function ConvertTextFormat(pText, pEncodingFrom = "UTF-8", pEncodingTo = "windows-1251") Export 
	vBinaryData = GetBinaryDataFromString(pText, pEncodingFrom);
	vResString = GetStringFromBinaryData(vBinaryData, pEncodingTo); 
	Return vResString;
EndFunction // ConvertTextFormat()

#EndRegion

#Region Private

// ---------------------------------------------------------------------------------
//  Найти элемент или группу отбора по заданному имени поля или представлению.
//
// Parameters:
//  ОбластьПоиска	 - 		 - ОтборКомпоновкиДанных, КоллекцияЭлементовОтбораКомпоновкиДанных,
//  		ГруппаЭлементовОтбораКомпоновкиДанных - контейнер
//  		с элементами и группами отбора, например Список.Отбор или группа в отборе.
//  ИмяПоля			 - Строка	 - имя поля компоновки (не используется для групп).
//  Представление	 - Строка	 - представление поля компоновки.
// 
// Returns:
//  Массив - Коллекция отборов.
//
Function cmSearchItemsGroupAndFilter(Val ОбластьПоиска,
									Val ИмяПоля = Undefined,
									Val Представление = Undefined) Export
	
	If ValueIsFilled(ИмяПоля) Then
		ЗначениеПоиска = New ПолеКомпоновкиДанных(ИмяПоля);
		СпособПоиска = 1;
	Else
		СпособПоиска = 2;
		ЗначениеПоиска = Представление;
	EndIf;
	
	МассивЭлементов = New Array;
	
	cmFindRecursively(ОбластьПоиска.Элементы, МассивЭлементов, СпособПоиска, ЗначениеПоиска);
	
	Return МассивЭлементов;
	
EndFunction

// ---------------------------------------------------------------------------------
//  Добавить элемент компоновки в контейнер элементов компоновки.
//
// Parameters:
//  ОбластьДобавления						 - КоллекцияЭлементовОтбораКомпоновкиДанных	 - контейнер с элементами и группами отбора,
//  	например, Список.Отбор или группа в отборе.
//  pItemName									 - Строка									 - имя поля компоновки данных (заполняется всегда).
//  pComparisonType							 - ВидСравненияКомпоновкиДанных				 - вид сравнения.
//  pRightValue							 - Произвольный								 - сравниваемое значение.
//  pPresentation							 - Строка									 - представление элемента компоновки данных.
//  pUse							 - Булево									 - использование элемента.
//  pViewMode						 - РежимОтображенияЭлементаНастройкиКомпоновкиДанных - режим отображения.
//  pUserSettingID	 - Строка											 - см. ОтборКомпоновкиДанных.ИдентификаторПользовательскойНастройки
//  											в синтакс-помощнике.
// 
// Returns:
//  DataCompositionFilterItem - элемент компоновки.
//
Function cmAddDataCompositionField(ОбластьДобавления,
									Val pItemName,
									Val pComparisonType,
									Val pRightValue = Undefined,
									Val pPresentation  = Undefined,
									Val pUse  = Undefined,
									Val pViewMode = Undefined,
									Val pUserSettingID = Undefined) Export 
	
	vItem = ОбластьДобавления.Элементы.Добавить(Тип("ЭлементОтбораКомпоновкиДанных"));
	vItem.ЛевоеЗначение = New ПолеКомпоновкиДанных(pItemName);
	vItem.ВидСравнения = pComparisonType;
	
	If pViewMode = Undefined Then
		vItem.РежимОтображения = РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный;
	Else
		vItem.РежимОтображения = pViewMode;
	EndIf;
	
	If pRightValue <> Undefined Then
		vItem.ПравоеЗначение = pRightValue;
	EndIf;
	
	If pPresentation <> Undefined Then
		vItem.Представление = pPresentation;
	EndIf;
	
	If pUse <> Undefined Then
		vItem.Использование = pUse;
	EndIf;
	
	// Важно: установка идентификатора должна выполняться
	// в конце настройки элемента, иначе он будет скопирован
	// в пользовательские настройки частично заполненным.
	If pUserSettingID <> Undefined Then
		vItem.ИдентификаторПользовательскойНастройки = pUserSettingID;
	ElsIf vItem.РежимОтображения <> РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный Then
		vItem.ИдентификаторПользовательскойНастройки = pItemName;
	EndIf;
	
	Return vItem;
	
EndFunction //  cmAddDataCompositionField

// ---------------------------------------------------------------------------------
//  Изменить элемент отбора с заданным именем поля или представлением.
//
// Parameters:
//  pSearchArea		 - КоллекцияЭлементовОтбораКомпоновкиДанных		 - контейнер с элементами и группами отбора,
//  		например, Список.Отбор или группа в отборе.
//  pItemName		 - Строка										 - имя поля компоновки данных (заполняется всегда).
//  pPresentation	 - Строка										 - представление элемента компоновки данных.
//  pRightValue		 - Произвольный									 - сравниваемое значение.
//  pComparisonType	 - ВидСравненияКомпоновкиДанных					 - вид сравнения.
//  pUse			 - Булево										 - использование элемента.
//  pViewMode		 - РежимОтображенияЭлементаНастройкиКомпоновкиДанных - режим отображения.
//  pUserSettingID	 - Строка											 - см. ОтборКомпоновкиДанных.ИдентификаторПользовательскойНастройки
//  											в синтакс-помощнике.
// 
// Returns:
//  Number - количество измененных элементов.
//
Function cmChangeFilterItems(pSearchArea,
								Val pItemName = Undefined,
								Val pPresentation = Undefined,
								Val pRightValue = Undefined,
								Val pComparisonType = Undefined,
								Val pUse = Undefined,
								Val pViewMode = Undefined,
								Val pUserSettingID = Undefined) Export
	
	If ValueIsFilled(pItemName) Then
		vSearchValue = New ПолеКомпоновкиДанных(pItemName);
		vMeans = 1;
	Else
		vMeans = 2;
		vSearchValue = pPresentation;
	EndIf;
	
	vArr = New Array;
	
	cmFindRecursively(pSearchArea.Items, vArr, vMeans, vSearchValue);
	
	For Each vItem Из vArr Do
		If pItemName <> Undefined Then
			vItem.ЛевоеЗначение = New DataCompositionField(pItemName);
		EndIf;
		If pPresentation <> Undefined Then
			vItem.Представление = pPresentation;
		EndIf;
		If pUse <> Undefined Then
			vItem.Использование = pUse;
		EndIf;
		If pComparisonType <> Undefined Then
			vItem.ВидСравнения = pComparisonType;
		EndIf;
		If pRightValue <> Undefined Then
			vItem.ПравоеЗначение = pRightValue;
		EndIf;
		If pViewMode <> Undefined Then
			vItem.РежимОтображения = pViewMode;
		EndIf;
		If pUserSettingID <> Undefined Then
			vItem.ИдентификаторПользовательскойНастройки = pUserSettingID;
		EndIf;
	EndDo;
	
	Return vArr.Count();
	
EndFunction //  cmChangeFilterItems

// ---------------------------------------------------------------------------------
//  Добавить или заменить существующий элемент отбора.
//
// Parameters:
//  pSearchArea		 - КоллекцияЭлементовОтбораКомпоновкиДанных		 - контейнер с элементами и группами отбора,
//  		например, Список.Отбор или группа в отборе.
//  pItemName		 - Строка										 - имя поля компоновки данных (заполняется всегда).
//  pRightValue		 - произвольный									 - сравниваемое значение.
//  pComparisonType	 - ВидСравненияКомпоновкиДанных					 - вид сравнения.
//  pPresentation	 - Строка										 - представление элемента компоновки данных.
//  pUse			 - Булево										 - использование элемента.
//  pViewMode		 - РежимОтображенияЭлементаНастройкиКомпоновкиДанных - режим отображения.
//  pUserSettingID	 - Строка											 - см. ОтборКомпоновкиДанных.ИдентификаторПользовательскойНастройки
//  											в синтакс-помощнике.
//
Procedure cmSetFilterItems(pSearchArea,
								Val pItemName,
								Val pRightValue = Undefined,
								Val pComparisonType = Undefined,
								Val pPresentation = Undefined,
								Val pUse = Undefined,
								Val pViewMode = Undefined,
								Val pUserSettingID = Undefined) Export
	
	ЧислоИзмененных = cmChangeFilterItems(pSearchArea, pItemName, pPresentation,
							pRightValue, pComparisonType, pUse, pViewMode, pUserSettingID);
	
	If ЧислоИзмененных = 0 Then
		If pComparisonType = Undefined Then
			If ТипЗнч(pRightValue) = Тип("Array")
				Или ТипЗнч(pRightValue) = Тип("FixedArray")
				Или ТипЗнч(pRightValue) = Тип("ValueList") Then
				pComparisonType = ВидСравненияКомпоновкиДанных.ВСписке;
			Else
				pComparisonType = ВидСравненияКомпоновкиДанных.Равно;
			EndIf;
		EndIf;
		If pViewMode = Undefined Then
			pViewMode = РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный;
		EndIf;
		cmAddDataCompositionField(pSearchArea, pItemName, pComparisonType,
								pRightValue, pPresentation, pUse, pViewMode, pUserSettingID);
	EndIf;
	
EndProcedure //  cmSetFilterItems

// ---------------------------------------------------------------------------------
//  Добавить или заменить существующий элемент отбора динамического списка.
//
// Parameters:
//  pDynamicList	 - ДинамическийСписок							 - Список, в котором требуется установить отбор.
//  pItemName		 - Строка										 - Поле, по которому необходимо установить отбор.
//  pRightValue		 - Произвольный									 - Значение отбора.
//  									Необязательный. Значение по умолчанию: Undefined.
//  									Внимание! If передать Undefined, то значение не будет изменено.
//  pComparisonType	 - ВидСравненияКомпоновкиДанных					 - Условие отбора.
//  pPresentation	 - Строка										 - Представление элемента компоновки данных.
//  										Необязательный. Значение по умолчанию: Undefined.
//  										If указано, то выводится только флажок использования с указанным представлением (значение не выводится).
//  										Для очистки (чтобы значение снова выводилось) следует передать пустую строку.
//  pUse			 - Булево										 - Флажок использования этого отбора.
//  										Необязательный. Значение по умолчанию: Undefined.
//  pViewMode		 - РежимОтображенияЭлементаНастройкиКомпоновкиДанных - Способ отображения этого отбора
//  пользователю.
//  * РежимОтображенияЭлементаНастройкиКомпоновкиДанных.БыстрыйДоступ - В группе быстрых настроек над списком.
//  * РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Обычный       - В настройка списка (в подменю Еще).
//  * РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный   - Запретить пользователю менять этот отбор.
//  pUserSettingID	 - Строка											 - Уникальный идентификатор этого отбора.
//  											Используется для связи с пользовательскими настройками.
//
Procedure cmAddOrReplaceItemDynamicList(pDynamicList, pItemName,
	pRightValue = Undefined,
	pComparisonType = Undefined,
	pPresentation = Undefined,
	pUse = Undefined,
	pViewMode = Undefined,
	pUserSettingID = Undefined) Export
	
	If pViewMode = Undefined Then
		pViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	
	If pViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
		vFilter = pDynamicList.КомпоновщикНастроек.ФиксированныеНастройки.Отбор;
	Else
		vFilter = pDynamicList.КомпоновщикНастроек.Настройки.Отбор;
	EndIf;
	
	cmSetFilterItems(
		vFilter,
		pItemName,
		pRightValue,
		pComparisonType,
		pPresentation,
		pUse,
		pViewMode,
		pUserSettingID);
	
EndProcedure //  cmAddOrReplaceItemDynamicList

// ---------------------------------------------------------------------------------
//
// Parameters:
//  КоллекцияЭлементов	 - 	 - 
//  МассивЭлементов		 - 	 - 
//  СпособПоиска		 - 	 - 
//  ЗначениеПоиска		 - 	 - 
//
Procedure cmFindRecursively(КоллекцияЭлементов, МассивЭлементов, СпособПоиска, ЗначениеПоиска)
	
	Для каждого ЭлементОтбора Из КоллекцияЭлементов Do
		
		If ТипЗнч(ЭлементОтбора) = Тип("ЭлементОтбораКомпоновкиДанных") Then
			
			If СпособПоиска = 1 Then
				If ЭлементОтбора.ЛевоеЗначение = ЗначениеПоиска Then
					МассивЭлементов.Добавить(ЭлементОтбора);
				EndIf;
			ElsIf СпособПоиска = 2 Then
				If ЭлементОтбора.Представление = ЗначениеПоиска Then
					МассивЭлементов.Добавить(ЭлементОтбора);
				EndIf;
			EndIf;
		Else
			
			cmFindRecursively(ЭлементОтбора.Элементы, МассивЭлементов, СпособПоиска, ЗначениеПоиска);
			
			If СпособПоиска = 2 И ЭлементОтбора.Представление = ЗначениеПоиска Then
				МассивЭлементов.Добавить(ЭлементОтбора);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure //  cmFindRecursively

#EndRegion
