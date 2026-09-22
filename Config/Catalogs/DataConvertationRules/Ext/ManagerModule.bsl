
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
//  Converts JSON to structure
//
// Parameters:
//  pJSONString	 - String	 - JSON formatted string
// 
// Returns:
//  Structure - Based on JSON
//
Function JSONtoStructure(pJSONString) Export
	vResult = Undefined;
	
	If Not IsBlankString(pJSONString) Then
		vJSONReader = New JSONReader;
		vJSONReader.SetString(pJSONString);
		vResult = ReadJSON(vJSONReader);
	EndIf;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Converts JSON to map
//
// Parameters:
//  pJSONString	 - 	 - JSON formatted string
// 
// Returns:
//  Map - Based on JSON
//
Function JSONtoMap(pJSONString) Export
	vResult = Undefined;
	
	If Not IsBlankString(pJSONString) Then
		vJSONReader = New JSONReader;
		vJSONReader.SetString(pJSONString);
		vResult = ReadJSON(vJSONReader, True);
	EndIf;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Converts JSON to value tree, that can be used for creating data convertations rules
//
// Parameters:
//  pJSONString				 - String	 - JSON String
//  pSetDefaultParameters	 - Boolean	 - 
// 
// Returns:
//  ValueTree - ValueTree
//
Function JSONtoValueTree(pJSONString, pSetDefaultParameters = False) Export
	vResult = New ValueTree;
	vResult.Columns.Add("Key");
	vResult.Columns.Add("KeyType");
	vResult.Columns.Add("temp_KeyType");
	vResult.Columns.Add("Value");
	vResult.Columns.Add("ValueCalculatingRule");
	
	vJSONStructure = JSONtoMap(pJSONString);
	
	If vJSONStructure <> Undefined Then
		JSON_GenerateValueTree(vJSONStructure, pSetDefaultParameters, vResult);
	EndIf;
	
	FormatValueTree(vResult);
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Converts Map, Structure, Array or ValueTable into JSON formatted string
//
// Parameters:
//  pMap				 - Map	 - Map or Structure with data
//  pDateFormatString	 - String	 - Format string for auto formatting date data type
// 
// Returns:
//  String - JSON formatted string
//
Function MapToJSON(pMap, pDateFormatString = Undefined) Export
	vResult = Undefined;
	
	vJSONSettings = New JSONWriterSettings(JSONLineBreak.None);
	vJSONWriter = New JSONWriter;
	vJSONWriter.SetString(vJSONSettings);		
	JSON_MapToJSON(pMap, vJSONWriter, pDateFormatString);
	
	vResult = vJSONWriter.Close();
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Converts XML to map or structure (if possible)
//
// Parameters:
//  pXMLString			 - 				 - XML formatted string
//  pParseToStructure	 - Boolean, true - convert xml to structure, false - conver xml to map. If XML contains nodes names that cant be used for structure keys it will cause exeption.
//  pTextValueName		 - 				 - Key name for the map / structure into which the text from the XML node will be placed
// 
// Returns:
//  Map, Structure - 
//
Function XMLtoMap(pXMLString, pParseToStructure = False, pTextValueName = "__TextValue") Export
	If pParseToStructure Then 
		vResult = New Structure;
	Else
		vResult = New Map;
	EndIf;
	
	If Not IsBlankString(pXMLString) Then
		ReadXMLtoMap(pXMLString, vResult, pParseToStructure, pTextValueName)	
	EndIf;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Converts predefined value tree into JSON
//
// Parameters:
//  pRules	 - CatalogRef.DataConvertationRules	 - Ref
//  pParams	 - Structure						 - Structure with additional parameters
// 
// Returns:
//  String - JSON formatted string
//
Function ValueTreeToJSON(pRules, pParams = Undefined) Export
	vResult = Undefined;
	vLoadRuleTree = pRules.LoadRuleTreeStorage.Get();
	
	vJSONSettings = New JSONWriterSettings(JSONLineBreak.None);
	vJSONWriter = New JSONWriter;
	vJSONWriter.SetString(vJSONSettings);
	vJSONWriter.WriteStartObject();
	JSON_ConvertValueTree(vLoadRuleTree, pParams, vJSONWriter);
	vJSONWriter.WriteEndObject();
	
	vResult = vJSONWriter.Close();
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Return Value from map based on array path
//
// Parameters:
//  pMap		 - Map - Map
//  pArrayPath	 - Array - Array with path to value
// 
// Returns:
//  Any - Value from Map
//
Function GetMapValueByArrayPath(pMap, pArrayPath) Export
	vResult = Undefined;	
	vCurrentResult 	= pMap;
	
	Try
		vId = 0;
		For Each vPath In pArrayPath Do
			If vCurrentResult <> Undefined AND TypeOf(vCurrentResult) = Type("Map") Then
				vCurrentResult = vCurrentResult[vPath];
				vId = vId + 1;
			Else
				Break;
			EndIf;
		EndDo;
		If vId = pArrayPath.Count() Then
			vResult = vCurrentResult;	
		EndIf;
	Except
		vResult = Undefined;	
	EndTry;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//  Converts JSON or XML formatted string into value tree for user view
//
// Parameters:
//  pInputString	 - String	 - JSON or XML formatted string
//  pStringFormat	 - String	 - "JSON" or "XML", if undefined function will try to read both as XML and JSON and fill this parameter
// 
// Returns:
//  ValueTree - Result
//
Function JSON_or_XML_to_ValueTable(pInputString, pStringFormat = "") Export
	vResult = New ValueTree;
	vResult.Columns.Add("Key");
	vResult.Columns.Add("KeyType");
	vResult.Columns.Add("temp_KeyType");
	vResult.Columns.Add("Value");
	
	If ValueIsFilled(pInputString) Then
		GenerateValueTree(pInputString, pStringFormat, vResult);
	EndIf;
	
	vResult.Rows.Sort("KeyType, Key", True);
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pExternalSystemInteraction	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  pFunction					 - String								 - Function name
//  pConvertationType			 - ConvertationType						 - ConvertationType
// 
// Returns:
//  ConvertationRule - Convertation rule
//
Function GetRules(pExternalSystemInteraction, pFunction, pConvertationType) Export
	vResult = Undefined;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	ExternalSystemFunctionMapping.ConvertationRule AS ConvertationRule
		|FROM
		|	InformationRegister.ExternalSystemFunctionMapping AS ExternalSystemFunctionMapping
		|WHERE
		|	ExternalSystemFunctionMapping.ExternalSystemInteraction = &ExternalSystemInteraction
		|	AND ExternalSystemFunctionMapping.Function = &Function
		|	AND ExternalSystemFunctionMapping.ConvertationType = &ConvertationType";
	
	vQuery.SetParameter("ConvertationType", pConvertationType);
	vQuery.SetParameter("ExternalSystemInteraction", pExternalSystemInteraction);
	vQuery.SetParameter("Function", pFunction);
	
	vQueryResult = vQuery.Execute();
	
	vRes = vQueryResult.Select();
	
	While vRes.Next() Do
		vResult = vRes.ConvertationRule;
	EndDo;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pTreeRow				 - TreeRow			 - Tree 
//  pParams					 - Structure		 - Params
//  pValueCalculatingRule	 - ValueCalculatingRule	 - ValueCalculatingRule
//  pParamsRow				 - Structure			 - ParamsRow
// 
// Returns:
//  TreeRowValue - TreeRowValue
//
Function GetTreeRowValue(pTreeRow, pParams, pValueCalculatingRule, pParamsRow) Export
	vResult = Undefined;
	Try
		SetSafeMode(True);
		
		Value 		= pTreeRow.Value;
		If Not IsBlankString(pValueCalculatingRule) Then
			If TypeOf(pParams) = Type("Structure") Then
				If StrStartWith(pValueCalculatingRule, "Row.") Or StrStartWith(pValueCalculatingRule, "Строка.") Then
					
					vParamName 	= StrReplace(pValueCalculatingRule, "Row.", "");
					vParamName 	= StrReplace(vParamName, "Строка.", "");
					
					vEvalString = "pParamsRow." + vParamName;
					vResult 	= Eval(vEvalString); // pParamsRow[vParamName];
					
				Else
					Parameters 	= pParams;
					Параметры	= pParams;
					
					vResult = Eval(pValueCalculatingRule);
				EndIf;
			ElsIf TypeOf(pParams) = Type("Map") Then
				
			EndIf;
		Else
			vResult = pTreeRow.Value; 	
		EndIf;
		
		SetSafeMode(False);
	Except
       vErr = ErrorDescription();
	EndTry;
	
	Return vResult;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pExternalSystemInteraction	 - CatalogRef.ExternalSystemInteractions - External system interactions
//  pFunction					 - String								 - Function name
//  pConvertationType			 - ConvertationType						 - ConvertationType
//  pConvertationRule			 - ConvertationRule						 - ConvertationRule
//
Procedure WriteFunctionMapping(pExternalSystemInteraction, pFunction, pConvertationType, pConvertationRule) Export
	vRecordManager 								= InformationRegisters.ExternalSystemFunctionMapping.CreateRecordManager();
	vRecordManager.ExternalSystemInteraction 	= pExternalSystemInteraction;
	vRecordManager.Function 					= pFunction;
	vRecordManager.ConvertationType 			= pConvertationType;
	vRecordManager.ConvertationRule 			= pConvertationRule;
	vRecordManager.Write(True);
EndProcedure

// --------------------------------------------------------------------------------
//
// Parameters:
//  pValueTable				 - ValueTable	 -  Data
//  pDelimiter				 - String		 -  Delimiter
//  pColumnsNamesStructure	 - Structure	 -  Columns names
//  pDateFormat				 - String		 -  Date format
// 
// Returns:
//  String - CSV
//
Function ValuteTableToCSV(pValueTable, pDelimiter = ";", pColumnsNamesStructure = Undefined, pDateFormat = Undefined) Export
	vResult = "";	
	
	If pValueTable <> Undefined Then
		vHeadersString = "";
		For Each vTableColumn in pValueTable.Columns Do
			vName = vTableColumn.Name;
			If pColumnsNamesStructure <> Undefined Then
				If Not pColumnsNamesStructure.Property(vTableColumn.Name, vName) Then
					vName = vTableColumn.Name;
				EndIf;	
			EndIf;
			
			If vHeadersString = "" Then 
				vHeadersString = vName;
			Else
				vHeadersString = vHeadersString + pDelimiter + vName;	
			EndIf;
		EndDo;
		
		vDataString = "";
		For Each vRow In pValueTable Do
			vFirst = True;
			For Each vTableColumn In pValueTable.Columns Do
				If pDateFormat <> Undefined And TypeOf(vRow[vTableColumn.Name]) = Type("Date") Then
					vCurrentData = Format(vRow[vTableColumn.Name], pDateFormat);	
				Else
					vCurrentData = StrReplace(String(vRow[vTableColumn.Name]), pDelimiter, ".");
					vCurrentData = StrReplace(vCurrentData, Chars.LF, " ");
				EndIf;
				If vFirst Then
					vDataString = vDataString + vCurrentData;
					vFirst = False;
				Else
					vDataString = vDataString + pDelimiter + vCurrentData;
				EndIf;
			EndDo;
			vDataString = vDataString + Chars.LF;
		EndDo;
		
		vResult = vHeadersString + Chars.LF + vDataString;
	EndIf;
	
	Return vResult;
EndFunction

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Procedure GenerateValueTree(pInputString, pStringFormat = "", rResult = Undefined, pCurrentValue = Undefined, pArrayID = 0)
	If rResult = Undefined Then
		rResult = New ValueTree;
		rResult.Columns.Add("Key");
		rResult.Columns.Add("KeyType");
		rResult.Columns.Add("temp_KeyType");
		rResult.Columns.Add("Value");
	EndIf;
	
	If pCurrentValue = Undefined Then
		If pStringFormat = "JSON" Then
			pCurrentValue = JSONtoMap(pInputString);	
		ElsIf pStringFormat = "XML" Then
			pCurrentValue = XMLtoMap(pInputString, False);	
		Else
			vSuccess = False;
			Try
				pCurrentValue = JSONtoMap(pInputString);
				vSuccess = True;
				pStringFormat = "JSON";
			Except
				vSuccess = False;	
			EndTry;
			
			If Not vSuccess Then
				Try
					pCurrentValue 		= XMLtoMap(pInputString, False);
					vSuccess		= True;
					pStringFormat 	= "XML";
				Except
					vSuccess = False;	
				EndTry;
			EndIf;
			
			If Not vSuccess Then
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	For Each vCurrentValueRow In pCurrentValue Do
		If TypeOf(vCurrentValueRow) = Type("KeyAndValue") Then
			vNewRow 				= rResult.Rows.Add();
			vNewRow.Key 			= vCurrentValueRow.Key;
			vNewRow.temp_KeyType 	= TypeOf(vCurrentValueRow.Value);

			If vNewRow.temp_KeyType = Type("Structure") Or vNewRow.temp_KeyType = Type("Array") Or vNewRow.temp_KeyType = Type("Map") Then
				GenerateValueTree(pInputString, pStringFormat, vNewRow, vCurrentValueRow.Value);	
			Else
				vNewRow.Value 	= vCurrentValueRow.Value;
			EndIf;
		ElsIf TypeOf(vCurrentValueRow) = Type("Structure") Or TypeOf(vCurrentValueRow) = Type("Array") Or TypeOf(vCurrentValueRow) = Type("Map") Then
			vNewRow 				= rResult.Rows.Add();
			vNewRow.Key 			= pArrayID;
			vNewRow.KeyType 		= Enums.JSONKeyTypes.ArrayElement;
			
			pArrayID = pArrayID + 1;
			GenerateValueTree(pInputString, pStringFormat, vNewRow,vCurrentValueRow, pArrayID)
		Else
			vNewRow 				= rResult.Rows.Add();
			vNewRow.temp_KeyType 	= TypeOf(vCurrentValueRow);
			vNewRow.Value 			= vCurrentValueRow;	
		EndIf;
		
		If Not ValueIsFilled(vNewRow.KeyType) Then
			If vNewRow.temp_KeyType = Type("Array") Then
				vNewRow.KeyType = Enums.JSONKeyTypes.Array;	
			ElsIf vNewRow.temp_KeyType = Type("Structure") Or vNewRow.temp_KeyType = Type("Map") Then
				vNewRow.KeyType = Enums.JSONKeyTypes.Structure;	
			Else
				vNewRow.KeyType = Enums.JSONKeyTypes.String;	
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
Procedure JSON_GenerateValueTree(pJSONStructure, pSetDefaultParameters, rValueTree, pArrayID = 0)	
	For Each vJSONRow In pJSONStructure Do
		If TypeOf(vJSONRow) = Type("KeyAndValue") Then
			vNewRow 				= rValueTree.Rows.Add();
			vNewRow.Key 			= vJSONRow.Key;
			vNewRow.temp_KeyType 	= TypeOf(vJSONRow.Value);

			If vNewRow.temp_KeyType = Type("Structure") Or vNewRow.temp_KeyType = Type("Array") Or vNewRow.temp_KeyType = Type("Map") Then
				JSON_GenerateValueTree(vJSONRow.Value, pSetDefaultParameters, vNewRow)	
			Else
				vNewRow.Value 	= vJSONRow.Value;
			EndIf;
		ElsIf TypeOf(vJSONRow) = Type("Structure") Or TypeOf(vJSONRow) = Type("Array") Or TypeOf(vJSONRow) = Type("Map") Then
			vNewRow 				= rValueTree.Rows.Add();
			vNewRow.Key 			= pArrayID;
			vNewRow.KeyType 		= Enums.JSONKeyTypes.ArrayElement;
			
			pArrayID = pArrayID + 1;
			JSON_GenerateValueTree(vJSONRow, pSetDefaultParameters, vNewRow, pArrayID);
		Else
			vNewRow 				= rValueTree.Rows.Add();
			vNewRow.temp_KeyType 	= TypeOf(vJSONRow);
			vNewRow.Value 			= vJSONRow;	
		EndIf;
		
		If Not ValueIsFilled(vNewRow.KeyType) Then
			If vNewRow.temp_KeyType = Type("Array") Then
				If vNewRow.Rows.Count() > 1 Then
					vNewRow.KeyType = Enums.JSONKeyTypes.FixedArray;	
				Else
					vNewRow.KeyType = Enums.JSONKeyTypes.Array;	
				EndIf;
			ElsIf vNewRow.temp_KeyType = Type("Structure") Or vNewRow.temp_KeyType = Type("Map") Then
				vNewRow.KeyType = Enums.JSONKeyTypes.Structure;	
			Else
				vNewRow.KeyType = Enums.JSONKeyTypes.String;	
			EndIf;
		EndIf;
		
		// Make "smart" default parameters logic
		If pSetDefaultParameters = True Then
			If vNewRow.KeyType <> Enums.JSONKeyTypes.ArrayElement Then
				If TypeOf(rValueTree) = Type("ValueTreeRow") AND (rValueTree.temp_KeyType = Type("Map") Or rValueTree.temp_KeyType = Type("Structure")) Then
					vNewRow.ValueCalculatingRule = rValueTree.ValueCalculatingRule + "." + vNewRow.Key;
				ElsIf pArrayID > 0 Then
					vNewRow.ValueCalculatingRule = "Row." + vNewRow.Key;					
				Else
					vNewRow.ValueCalculatingRule = "Parameters." + vNewRow.Key;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
Procedure FormatValueTree(rValueTree)
	rValueTree.Columns.Delete("temp_KeyType");
	rValueTree.Columns.Add("Required");
EndProcedure

// --------------------------------------------------------------------------------
Procedure JSON_ConvertValueTree(pValueTree, pParams, rJSONWriter, pParamsRow = Undefined)
	For Each vTreeRow In pValueTree.Rows Do
		If vTreeRow.KeyType = Enums.JSONKeyTypes.FixedArray Then
			rJSONWriter.WritePropertyName(vTreeRow.Key);
			rJSONWriter.WriteStartArray();
				JSON_ConvertValueTree(vTreeRow, pParams, rJSONWriter, pParamsRow);
			rJSONWriter.WriteEndArray();
		ElsIf vTreeRow.KeyType = Enums.JSONKeyTypes.Array Then 
			rJSONWriter.WritePropertyName(vTreeRow.Key);
			rJSONWriter.WriteStartArray();
			
			If pParams <> Undefined and ValueIsFilled(vTreeRow.ValueCalculatingRule) Then 
				vValue = GetTreeRowValue(vTreeRow, pParams, vTreeRow.ValueCalculatingRule, pParamsRow);
				If vValue <> Undefined Then
					For Each vParamsRow In vValue Do
						JSON_ConvertValueTree(vTreeRow, pParams, rJSONWriter, vParamsRow);	
					EndDo;
				EndIf;
			EndIf;
			rJSONWriter.WriteEndArray();
		ElsIf vTreeRow.KeyType = Enums.JSONKeyTypes.Structure Or vTreeRow.KeyType = Enums.JSONKeyTypes.ArrayElement Then
			If vTreeRow.KeyType = Enums.JSONKeyTypes.Structure Then
				rJSONWriter.WritePropertyName(vTreeRow.Key);
			EndIf;
			
			rJSONWriter.WriteStartObject();
				JSON_ConvertValueTree(vTreeRow, pParams, rJSONWriter, pParamsRow);
			rJSONWriter.WriteEndObject();
		Else 
			rJSONWriter.WritePropertyName(vTreeRow.Key);
			vValue = GetTreeRowValue(vTreeRow, pParams, vTreeRow.ValueCalculatingRule, pParamsRow);
			If vValue <> Null And vValue <> Undefined Then
				If TypeOf(vValue) = Type("Boolean") Then
					rJSONWriter.WriteValue(vValue);
				ElsIf TypeOf(vValue) = Type("Number") Then
					rJSONWriter.WriteValue(vValue);
				Else
					rJSONWriter.WriteValue(String(vValue));
				EndIf;
			Else
				rJSONWriter.WriteValue("");	
			EndIf;
		EndIf;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
Procedure JSON_MapToJSON(pValues, rJSONWriter, pDateFormatString)
	
	If TypeOf(pValues) = Type("Map") Or TypeOf(pValues) = Type("Structure") Then
		rJSONWriter.WriteStartObject();
		For Each vKeyAndValue in pValues Do
			If TypeOf(vKeyAndValue.Key) = Type("Number") Then
				rJSONWriter.WritePropertyName(Format(vKeyAndValue.Key,"NDS=.; NGS=; NZ=0; NG="));
			Else
				rJSONWriter.WritePropertyName(String(vKeyAndValue.Key));
			EndIf;			
			JSON_MapToJSON(vKeyAndValue.Value, rJSONWriter, pDateFormatString);		
		EndDo;
		rJSONWriter.WriteEndObject();
	ElsIf TypeOf(pValues) = Type("Array") Then
		rJSONWriter.WriteStartArray();
		For Each vValue in pValues Do
			JSON_MapToJSON(vValue, rJSONWriter, pDateFormatString)
		EndDo;
		rJSONWriter.WriteEndArray();
	ElsIf TypeOf(pValues) = Type("ValueTable") Then
		rJSONWriter.WriteStartArray();
		For Each vValue in pValues Do
			rJSONWriter.WriteStartObject();
			For Each vColumn in pValues.Columns Do
				rJSONWriter.WritePropertyName(vColumn.Name);
				JSON_MapToJSON(vValue[vColumn.Name], rJSONWriter, pDateFormatString);
			EndDo;
			rJSONWriter.WriteEndObject();
		EndDo;
		rJSONWriter.WriteEndArray();
	ElsIf TypeOf(pValues) = Type("ValueTableRow") Then
		rJSONWriter.WriteStartObject();
		vValutTableOwner = pValues.Owner();
		For Each vColumn in vValutTableOwner.Columns Do
			rJSONWriter.WritePropertyName(vColumn.Name);
			JSON_MapToJSON(pValues[vColumn.Name], rJSONWriter, pDateFormatString);
		EndDo;
		rJSONWriter.WriteEndObject();
	Else
		vMeataDataValueType = Metadata.FindByType(TypeOf(pValues));
		If TypeOf(pValues) = Type("Boolean") Then
			rJSONWriter.WriteValue(pValues);	
		ElsIf TypeOf(pValues) = Type("Number") Then
			rJSONWriter.WriteValue(pValues);	
		ElsIf TypeOf(pValues) = Type("Date") And pDateFormatString <> Undefined Then
			rJSONWriter.WriteValue(Format(pValues, pDateFormatString));
		ElsIf vMeataDataValueType <> Undefined And Metadata.Documents.Contains(vMeataDataValueType) And ValueIsFilled(pValues) Then 
			// If it's a document we convert it to guuid. as there is no use for text presentation of document
			rJSONWriter.WriteValue(String(pValues.UUID()));			
		Else			
			rJSONWriter.WriteValue(String(pValues));
		EndIf;
	EndIf;
	
EndProcedure

// --------------------------------------------------------------------------------
Function ReadXMLtoMap(pXMLString, rResult, pParseToStructure, pTextValueName, rXMLReader = Undefined, pReturnLevel = Undefined, pDoNotRead = False)
	If rXMLReader = Undefined Then
		rXMLReader	= New XMLReader;
		rXMLReader.SetString(pXMLString);
	EndIf;
	
	If pReturnLevel = Undefined Then
		vReturnLevel = 1;
	Else
		vReturnLevel = pReturnLevel; 	
	EndIf;
	
	vCurrentLevel 		= vReturnLevel;
	vCurrentResult 		= Undefined;
	vArrayResult		= Undefined;
	While pDoNotRead Or rXMLReader.Read() Do
		If rXMLReader.NodeType = XMLNodeType.StartElement Then
			// Increase level
			vCurrentLevel 	= vCurrentLevel + 1;
			
			// If level > 2 then go deeper
			If vCurrentLevel > vReturnLevel + 1 Then
				ReadXMLtoMap(pXMLString, vCurrentResult, pParseToStructure, pTextValueName, rXMLReader, vCurrentLevel, True);
				// Decrease level
				vCurrentLevel = vCurrentLevel - 1;
				Continue;
			EndIf;
			
			// Get current result by name
			If pParseToStructure Then
				rResult.Property(rXMLReader.Name, vCurrentResult);
			Else
				vCurrentResult 	= rResult.Get(rXMLReader.Name);
			EndIf;
			If vCurrentResult = Undefined Then
				// If not found - add to result
				rResult.Insert(rXMLReader.Name, ?(pParseToStructure, New Structure, New Map));
				vCurrentResult = rResult[rXMLReader.Name]; 
			ElsIf TypeOf(vCurrentResult) <> Type("Array") Then
				// If found and its not array - create array instead
				vInsertResult = New Array;
				vInsertResult.Add(vCurrentResult);
				rResult[rXMLReader.Name] 	= vInsertResult;
				
				// Get array result to add in the end and create current result 
				vArrayResult				= rResult[rXMLReader.Name];
				vCurrentResult 				= ?(pParseToStructure, New Structure, New Map);
			Else
				// Get array result to add in the end and create current result 
				vArrayResult 	= rResult[rXMLReader.Name];
				vCurrentResult 	= ?(pParseToStructure, New Structure, New Map);
			EndIf;
			While rXMLReader.NextAttribute() Do
				If pParseToStructure Then
					vCurrentResult.Insert(GetProperStructureName(rXMLReader.Name), rXMLReader.Value);
				Else
					vCurrentResult.Insert(rXMLReader.Name, rXMLReader.Value);
				EndIf;
			EndDo;
		ElsIf rXMLReader.NodeType = XMLNodeType.Text Then			
			// If text - add value to current result with special name
			vCurrentResult.Insert(pTextValueName, rXMLReader.Value);
		ElsIf rXMLReader.NodeType = XMLNodeType.EndElement Then
			// If result is array - add current result to array
			If vArrayResult <> Undefined Then
				vArrayResult.Add(vCurrentResult);	
			EndIf;
			
			// Decrease level
			vCurrentLevel = vCurrentLevel - 1;
			
			// If current level < return level + 1 - return
			If vCurrentLevel < vReturnLevel + 1 Then
				Return rResult;
			EndIf;
		EndIf;
		pDoNotRead = False;
	EndDo;
EndFunction

// --------------------------------------------------------------------------------
Function GetProperStructureName(pName)
	vResult = pName;
	
	vResult = StrReplace(vResult, ":", "");
	vResult = StrReplace(vResult, ".", "");
	vResult = StrReplace(vResult, ",", "");
	vResult = StrReplace(vResult, "-", "");

	Return vResult;
EndFunction

#EndRegion
