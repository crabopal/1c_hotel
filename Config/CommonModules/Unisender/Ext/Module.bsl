// -----------------------------------------------------------------------------
Function GetLists() Export
	vAPIAddress = Constants.UnisenderAPIAddress.Get();
	If IsBlankString(vAPIAddress) Then
		vAPIAddress = "api.unisender.com/ru/api";
		Constants.UnisenderAPIAddress.Set(vAPIAddress);
	EndIf;
	
	vAPIKey = Constants.UnisenderAPIKey.Get();
	If IsBlankString(vAPIKey) Then
		Raise "Unisender API key is not specified!";
	EndIf;
	
	vSSLConn = New OpenSSLSecureConnection(Undefined, Undefined);
	vHTTP = New HTTPConnection(vAPIAddress, , , , , , vSSLConn);
	
	vCmd = "/getLists?format=json&api_key=" + vAPIKey;
	
	vRequest = New HTTPRequest(vCmd);
	vReply = vHTTP.Get(vRequest);
	vReplyBody = vReply.GetBodyAsString();
	
	vLists = New ValueList();
	
	vJSONReader = New JSONReader();
	vJSONReader.SetString(vReplyBody);
	
	Try
		vResult = ReadJSON(vJSONReader);
	Except
		Raise vReplyBody;
	EndTry;
	vJSONReader.Close();
	
	If vResult.Property("error") Then
		Raise vResult.code + Chars.LF + vResult.error;
	EndIf;

	For Each vListItem In vResult.result Do
		vLists.Add(vListItem.id, vListItem.title);
    EndDo;
	
	Return vLists;
EndFunction // GetLists

// -----------------------------------------------------------------------------
Function CreateList(pListName) Export
	vAPIAddress = Constants.UnisenderAPIAddress.Get();
	If IsBlankString(vAPIAddress) Then
		vAPIAddress = "api.unisender.com/ru/api";
		Constants.UnisenderAPIAddress.Set(vAPIAddress);
	EndIf;
	
	vAPIKey = Constants.UnisenderAPIKey.Get();
	If IsBlankString(vAPIKey) Then
		Raise "Unisender API key is not specified!";
	EndIf;
	
	vSSLConn = New OpenSSLSecureConnection(Undefined, Undefined);
	vHTTP = New HTTPConnection(vAPIAddress, , , , , , vSSLConn); 
	
	vCmd = "/createList?format=json&api_key=" + vAPIKey + "&title=" + EncodeString(pListName, StringEncodingMethod.URLEncoding);
	
	vRequest = New HTTPRequest(vCmd);
	vReply = vHTTP.Get(vRequest);
	vReplyBody = vReply.GetBodyAsString();
	
	vJSONReader = New JSONReader();
	vJSONReader.SetString(vReplyBody);
	
	Try
		vResult = ReadJSON(vJSONReader);
	Except
		Raise vReplyBody;
	EndTry;
	vJSONReader.Close();
	
	vListId = 0;
	If vResult.Property("error") Then
		Raise vResult.code + Chars.LF + vResult.error;
	Else
		vListId = vResult.result.id;
	EndIf;

	Return vListId;
EndFunction // CreateList

// -----------------------------------------------------------------------------
Function GetClientTagsList(pClient)
	vList = New ValueList();
	Return vList;
EndFunction // GetClientTagsList

// -----------------------------------------------------------------------------
Function GetClientTags(pClient)
	vTags = "";
	vTagsList = GetClientTagsList(pClient);
	For Each vTagsListItem In vTagsList Do
		vTags = vTags + ?(IsBlankString(vTags), "", ",") + TrimAll(vTagsListItem.Presentation);
	EndDo;
	Return vTags;
EndFunction // GetClientTags

// -----------------------------------------------------------------------------
Function GetFields() Export
	vAPIAddress = Constants.UnisenderAPIAddress.Get();
	If IsBlankString(vAPIAddress) Then
		vAPIAddress = "api.unisender.com/ru/api";
		Constants.UnisenderAPIAddress.Set(vAPIAddress);
	EndIf;
	
	vAPIKey = Constants.UnisenderAPIKey.Get();
	If IsBlankString(vAPIKey) Then
		Raise "Unisender API key is not specified!";
	EndIf;
	
	vSSLConn = New OpenSSLSecureConnection(Undefined, Undefined);
	vHTTP = New HTTPConnection(vAPIAddress, , , , , , vSSLConn); 
	
	vCmd = "/getFields?format=json&api_key=" + vAPIKey;
	
	vRequest = New HTTPRequest(vCmd);
	vReply = vHTTP.Get(vRequest);
	vReplyBody = vReply.GetBodyAsString();
	
	vFields = New ValueList();
	
	vJSONReader = New JSONReader();
	vJSONReader.SetString(vReplyBody);
	
	Try
		vResult = ReadJSON(vJSONReader);
	Except
		Raise vReplyBody;
	EndTry;
	vJSONReader.Close();
	
	If vResult.Property("error") Then
		Raise vResult.code + Chars.LF + vResult.error;
	EndIf;

	For Each vFieldItem In vResult.result Do
		vFields.Add(vFieldItem.name, vFieldItem.id);
    EndDo;
	
	Return vFields;
EndFunction // GetFields

// -----------------------------------------------------------------------------
Procedure CreateField(pName, pPresentation) Export
	vAPIAddress = Constants.UnisenderAPIAddress.Get();
	If IsBlankString(vAPIAddress) Then
		vAPIAddress = "api.unisender.com/ru/api";
		Constants.UnisenderAPIAddress.Set(vAPIAddress);
	EndIf;
	
	vAPIKey = Constants.UnisenderAPIKey.Get();
	If IsBlankString(vAPIKey) Then
		Raise "Unisender API key is not specified!";
	EndIf;
	
	vSSLConn = New OpenSSLSecureConnection(Undefined, Undefined);
	vHTTP = New HTTPConnection(vAPIAddress, , , , , , vSSLConn); 
	
	vCmd = "/createField?format=json&api_key=" + vAPIKey;
	vCmd = vCmd + "&name=" + TrimAll(pName) + "&public_name=" + EncodeString(TrimAll(pPresentation), StringEncodingMethod.URLEncoding) + "&type=string";
	
	vRequest = New HTTPRequest(vCmd);
	vReply = vHTTP.Get(vRequest);
	vReplyBody = vReply.GetBodyAsString();
	
	vJSONReader = New JSONReader();
	vJSONReader.SetString(vReplyBody);
	
	Try
		vResult = ReadJSON(vJSONReader);
	Except
		Raise vReplyBody;
	EndTry;
	vJSONReader.Close();
	
	If vResult.Property("error") Then
		tcCommonFunctionOnClientServer.TextMessage(vResult.code + ": " + vResult.error, MessageStatus.Attention);
	EndIf;
EndProcedure // CreateField

// -----------------------------------------------------------------------------
Procedure CheckAndCreateExtraFields() Export
	vExtraFields = GetFields();
	
	vCheckFields = New ValueList();
	vCheckFields.Add("Name", NStr("en='Full name'; ru='Полное имя клиента'; de='Vollständiger Name'"));
	vCheckFields.Add("LastName", NStr("en='Last name'; ru='Фамилия клиента'; de='Nachname'"));
	vCheckFields.Add("FirstName", NStr("en='First name'; ru='Имя клиента'; de='Vorname'"));
	vCheckFields.Add("SecondName", NStr("en='Second name'; ru='Отчество клиента'; de='Patronymikon'"));
	
	For Each vCheckFieldItem In vCheckFields Do
		If vExtraFields.FindByValue(vCheckFieldItem.Value) = Undefined Then
			CreateField(vCheckFieldItem.Value, vCheckFieldItem.Presentation);
		EndIf;
	EndDo;
EndProcedure // CheckAndCreateExtraFields

// -----------------------------------------------------------------------------
Function ExportClientsList(pClientsList, pListId) Export
	CheckAndCreateExtraFields();
	
	vAPIAddress = Constants.UnisenderAPIAddress.Get();
	If IsBlankString(vAPIAddress) Then
		vAPIAddress = "api.unisender.com/ru/api";
		Constants.UnisenderAPIAddress.Set(vAPIAddress);
	EndIf;
	
	vAPIKey = Constants.UnisenderAPIKey.Get();
	If IsBlankString(vAPIKey) Then
		Raise "Unisender API key is not specified!";
	EndIf;
	
	vSSLConn = New OpenSSLSecureConnection(Undefined, Undefined);
	vHTTP = New HTTPConnection(vAPIAddress, , , , , , vSSLConn); 
	
	vCmd = "/importContacts?format=json&api_key=" + vAPIKey;
	// Add fields
	vCmd = vCmd + "&overwrite_tags=1&field_names[0]=email&field_names[1]=email_list_ids&field_names[2]=phone&field_names[3]=phone_list_ids&field_names[4]=Name&field_names[5]=LastName&field_names[6]=FirstName&field_names[7]=SecondName&field_names[8]=tags";
	// Add clients
	For Each vClientItem In pClientsList Do
		i = pClientsList.IndexOf(vClientItem);
		
		vClient = vClientItem.Value;
		vTags = GetClientTags(vClient);
		
		If Not IsBlankString(vClient.Phone) Or Not IsBlankString(vClient.EMail) Then
			vCmd = vCmd + 
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][0]=" + EncodeString(TrimAll(vClient.EMail), StringEncodingMethod.URLEncoding) +
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][1]=" + Format(pListId, "NFD=; NZ=; NG=") +
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][2]=" + EncodeString(TrimAll(vClient.Phone), StringEncodingMethod.URLEncoding) +
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][3]=" + Format(pListId, "NFD=; NZ=; NG=") +
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][4]=" + EncodeString(TrimAll(vClient.FullName), StringEncodingMethod.URLEncoding) + 
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][5]=" + EncodeString(TrimAll(vClient.LastName), StringEncodingMethod.URLEncoding) + 
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][6]=" + EncodeString(TrimAll(vClient.FirstName), StringEncodingMethod.URLEncoding) + 
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][7]=" + EncodeString(TrimAll(vClient.SecondName), StringEncodingMethod.URLEncoding) + 
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][8]=" + EncodeString(vTags, StringEncodingMethod.URLEncoding);
		EndIf;
	EndDo;
	
	vRequest = New HTTPRequest(vCmd);
	vReply = vHTTP.Get(vRequest);
	vReplyBody = vReply.GetBodyAsString();
	
	vJSONReader = New JSONReader();
	vJSONReader.SetString(vReplyBody);
	
	Try
		vResult = ReadJSON(vJSONReader);
	Except
		Raise vReplyBody;
	EndTry;
	vJSONReader.Close();
	
	If vResult.Property("error") Then
		Raise vResult.code + Chars.LF + vResult.error;
	Else
		Return vResult.result.log;
	EndIf;
EndFunction // ExportClientsList

// -----------------------------------------------------------------------------
Function ExportDiscountCardsList(pDiscountCardsList, pListId) Export
	CheckAndCreateExtraFields();
	
	vAPIAddress = Constants.UnisenderAPIAddress.Get();
	If IsBlankString(vAPIAddress) Then
		vAPIAddress = "api.unisender.com/ru/api";
		Constants.UnisenderAPIAddress.Set(vAPIAddress);
	EndIf;
	
	vAPIKey = Constants.UnisenderAPIKey.Get();
	If IsBlankString(vAPIKey) Then
		Raise "Unisender API key is not specified!";
	EndIf;
	
	vSSLConn = New OpenSSLSecureConnection(Undefined, Undefined);
	vHTTP = New HTTPConnection(vAPIAddress, , , , , , vSSLConn); 
	
	vCmd = "/importContacts?format=json&api_key=" + vAPIKey;
	// Add fields
	vCmd = vCmd + "&overwrite_tags=1&field_names[0]=email&field_names[1]=email_list_ids&field_names[2]=phone&field_names[3]=phone_list_ids&field_names[4]=Name&field_names[5]=LastName&field_names[6]=FirstName&field_names[7]=SecondName&field_names[8]=tags";
	// Add discount cards
	For Each vDiscountCardItem In pDiscountCardsList Do
		i = pDiscountCardsList.IndexOf(vDiscountCardItem);
		
		vDiscountCard = vDiscountCardItem.Value;
		vTags = "";
		vClient = vDiscountCard.Client;
		If ValueIsFilled(vClient) Then
			vTags = GetClientTags(vClient);
		EndIf;
		
		If Not IsBlankString(vDiscountCard.Phone) Or Not IsBlankString(vDiscountCard.EMail) Then
			vCmd = vCmd + 
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][0]=" + EncodeString(TrimAll(vDiscountCard.EMail), StringEncodingMethod.URLEncoding) +
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][1]=" + Format(pListId, "NFD=; NZ=; NG=") +
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][2]=" + EncodeString(TrimAll(vDiscountCard.Phone), StringEncodingMethod.URLEncoding) +
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][3]=" + Format(pListId, "NFD=; NZ=; NG=") +
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][4]=" + EncodeString(Title(TrimAll(vDiscountCard.Description)), StringEncodingMethod.URLEncoding) + 
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][5]=" + EncodeString(TrimAll(vClient.LastName), StringEncodingMethod.URLEncoding) + 
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][6]=" + EncodeString(TrimAll(vClient.FirstName), StringEncodingMethod.URLEncoding) + 
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][7]=" + EncodeString(TrimAll(vClient.SecondName), StringEncodingMethod.URLEncoding) + 
			       "&data[" + Format(i, "NFD=; NZ=; NG=") + "][8]=" + EncodeString(vTags, StringEncodingMethod.URLEncoding);
		EndIf;
	EndDo;
	
	vRequest = New HTTPRequest(vCmd);
	vReply = vHTTP.Get(vRequest);
	vReplyBody = vReply.GetBodyAsString();
	
	vJSONReader = New JSONReader();
	vJSONReader.SetString(vReplyBody);
	
	Try
		vResult = ReadJSON(vJSONReader);
	Except
		Raise vReplyBody;
	EndTry;
	vJSONReader.Close();
	
	If vResult.Property("error") Then
		Raise vResult.code + Chars.LF + vResult.error;
	Else
		Return vResult.result.log;
	EndIf;
EndFunction // ExportClientsList
