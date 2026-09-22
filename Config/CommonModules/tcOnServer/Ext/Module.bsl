
#Region Public

// -----------------------------------------------------------------------------
Function cmGetDocumentItemRefByDocNumber(pDocName, pDocNumber, pEmptyRef=False) Export	
	If pEmptyRef = Undefined Then
		pEmptyRef = False;
	EndIf;
	If pEmptyRef Then
		Return Documents[pDocName].EmptyRef();
	Else
		vDocRef = Documents[pDocName].FindByNumber(pDocNumber);
		Return vDocRef;
	EndIf;
EndFunction // cmGetDocumentItemRefByDocNumber

// -----------------------------------------------------------------------------
Function cmGetCatalogItemRefByCode(pCatalogName, pCode = "", pEmptyRef=False, pAttribute="")	Export	
	If pEmptyRef = Undefined Then
		pEmptyRef = False;
	EndIf;
	If pAttribute = Undefined Then
		pAttribute = "";
	EndIf;
	If pEmptyRef Then
		Return Catalogs[pCatalogName].EmptyRef();
	Else
		If ValueIsFilled(pAttribute) Then
			vCatalogRef = Catalogs[pCatalogName].FindByCode(pCode)[pAttribute];
		Else
			vCatalogRef = Catalogs[pCatalogName].FindByCode(pCode);
		EndIf;
		Return vCatalogRef;
	EndIf;
EndFunction // cmGetCatalogItemRefByCode

// -----------------------------------------------------------------------------
Function cmGetCatalogItemRefByName(pCatalogName, pName = "", pEmptyRef=False, pAttribute="")	Export	
	If pEmptyRef = Undefined Then
		pEmptyRef = False;
	EndIf;
	If pAttribute = Undefined Then
		pAttribute = "";
	EndIf;
	If pEmptyRef Then
		Return Catalogs[pCatalogName].EmptyRef();
	Else
		If ValueIsFilled(pAttribute) Then
			vCatalogRef = Catalogs[pCatalogName][pName][pAttribute];
		Else
			vCatalogRef = Catalogs[pCatalogName][pName];
		EndIf;
		Return vCatalogRef;
	EndIf;
EndFunction // cmGetCatalogItemRefByName

// -----------------------------------------------------------------------------
Function cmGetCatalogItemRefByAttribute(pCatalogName, pAttributeName = "", pEmptyRef=False, pAttribute="")	Export	
	If pEmptyRef = Undefined Then
		pEmptyRef = False;
	EndIf;
	If pAttribute = Undefined Then
		pAttribute = "";
	EndIf;
	If pEmptyRef Then
		Return Catalogs[pCatalogName].EmptyRef();
	Else
		vCatalogRef = Catalogs[pCatalogName].FindByAttribute(pAttributeName,pAttribute);
		Return vCatalogRef;
	EndIf;
EndFunction // cmGetCatalogItemRefByName

// -----------------------------------------------------------------------------
Function cmGetCatalogItemRefByDescription(pCatalogName, pDescription = "", pEmptyRef=False, pAttribute="") Export	
	If pEmptyRef = Undefined Then
		pEmptyRef = False;
	EndIf;
	If pAttribute = Undefined Then
		pAttribute = "";
	EndIf;
	If pEmptyRef Then
		Return Catalogs[pCatalogName].EmptyRef();
	Else
		If ValueIsFilled(pAttribute) Then
			vCatalogRef = Catalogs[pCatalogName].FindByDescription(pDescription, True)[pAttribute];
		Else
			vCatalogRef = Catalogs[pCatalogName].FindByDescription(pDescription, True);
		EndIf;
		Return vCatalogRef;
	EndIf;
EndFunction // cmGetCatalogItemRefByDescription

// -----------------------------------------------------------------------------
Function cmGetEnumItem(pEnumName, pEnumItem) Export
	vEnum = Enums[pEnumName][pEnumItem];
	Return vEnum;
EndFunction // cmGetEnumItem

// -----------------------------------------------------------------------------
// Gets the value of the props of the object
// Parameters:
//  pRef		 - ref at object	 - Ref at catalog or document
//  pAttribute	 - 	string - Attribute description
// 
// Returns:
//  Any - Attribute value
//
Function cmGetAttributeByRef(pRef, pAttribute = "") Export
	If pAttribute = Undefined Then
		pAttribute = "";
	EndIf;
	If Not ValueIsFilled(pAttribute) Then
		vVal = pRef.Description;
	Else
		vFindedDot = Find(pAttribute, ".");
		If vFindedDot > 0 Then
			vFirstAttribute = Left(pAttribute, vFindedDot-1);
			vSecondAttribute = Right(pAttribute, StrLen(pAttribute)-vFindedDot);
			vVal = pRef[vFirstAttribute];
			vVal = vVal[vSecondAttribute];
		Else
			vVal = pRef[pAttribute];
		EndIf;
	EndIf;
	Return vVal;
EndFunction // cmGetAttributeByRef

// -----------------------------------------------------------------------------
Procedure cmChangeObjectAttributeByRef(pRef, pAttribute = "", pValue = Undefined) Export
	If Not ValueIsFilled(pRef) Or Not ValueIsFilled(pAttribute) Then
		Return;
	EndIf;
	Try
		vObj = pRef.GetObject();
		vObj[pAttribute] = pValue;
		vObj.Write();
	Except
		Return;
	EndTry;
EndProcedure // cmChangeObjectAttributeByRef

// -----------------------------------------------------------------------------
Function cmGetMetadataMethodOrAttribiteByRef(pRef, pMethod = "", pAttribute = "") Export
	// Check paramters
	If pAttribute = Undefined Then
		pAttribute = "";
	EndIf;
	If pMethod = Undefined Then
		pMethod = "";
	EndIf;
	If Not IsBlankString(pMethod) Then
		If pMethod = "Presentation" Then
			vVal = pRef.Metadata().Presentation();
		ElsIf pMethod = "FullName" Then
			vVal = pRef.Metadata().FullName();
		ElsIf pMethod = "Parent" Then
			vVal = pRef.Metadata().Parent();
		Else
			vVal = pRef.Description;
		EndIf;
	Else
		If Not IsBlankString(pAttribute) Then
			vVal = pRef.Metadata[pAttribute];
		Else
			vVal = pRef.Description;
		EndIf;
	EndIf;
	Return vVal;
EndFunction // cmGetMetadataMethodOrAttribiteByRef

// -----------------------------------------------------------------------------
//  Returns icon of the given room status
//
// Parameters:
//  pRoomStatus	 - CatalogRef.RoomStatuses	 - Room status
// 
// Returns:
//  Picture - Picture object
//
Function cmGetRoomStatusIconOnServer(pRoomStatus) Export
	vPicture = PictureLib.Empty;
	If ValueIsFilled(pRoomStatus) Then
		If ValueIsFilled(pRoomStatus.RoomStatusIcon) Then
			If pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.None Then
				vPicture = PictureLib.Empty;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
				vPicture = PictureLib.RoomStatusReserved;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
				vPicture = PictureLib.Occupied;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
				vPicture = PictureLib.OccupiedDirty;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
				vPicture = PictureLib.Waiting;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
				vPicture = PictureLib.RoomStatusCleaning;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
				vPicture = PictureLib.TidyingUp;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
				vPicture = PictureLib.Vacant;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
				vPicture = PictureLib.RoomStatusRepair;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Luggage Then
				vPicture = PictureLib.RoomStatusLuggage;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Then
				vPicture = PictureLib.RoomStatusMalfunction;
			EndIf;
		EndIf;
	EndIf;
	Return vPicture;
EndFunction // cmGetRoomStatusIconOnServer

// -----------------------------------------------------------------------------
Function cmGetRoomStatusIconIndexOnServer(pRoomStatus) Export
	vPictureIndex = 5;
	If ValueIsFilled(pRoomStatus) Then
		If ValueIsFilled(pRoomStatus.RoomStatusIcon) Then
			If pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.None Then
				vPictureIndex = 3;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Reserved Then
				vPictureIndex = 6;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Occupied Then
				vPictureIndex = 2;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.OccupiedDirty Then
				vPictureIndex = 7;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Waiting Then
				vPictureIndex = 1;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.TidyingUp Then
				vPictureIndex = 0;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.CheckOut Then
				vPictureIndex = 3;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Vacant Then
				vPictureIndex = 4;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Repair Then
				vPictureIndex = 8;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Luggage Then
				vPictureIndex = 9;
			ElsIf pRoomStatus.RoomStatusIcon = Enums.RoomStatusesIcons.Malfunction Then
				vPictureIndex = 10;
			EndIf;
		EndIf;
	EndIf;
	Return vPictureIndex;
EndFunction // cmGetRoomStatusIconIndexOnServer

// -----------------------------------------------------------------------------
Function cmGetCurrentHotelAttribute(pAttr = "") Export
	// Check parameters
	If pAttr = Undefined Then
		pAttr = "";
	EndIf;
	If ValueIsFilled(pAttr) Then
		Return SessionParameters.CurrentHotel[pAttr];
	Else
		Return SessionParameters.CurrentHotel;
	EndIf;
EndFunction // cmGetCurrentHotelAttribute

// -----------------------------------------------------------------------------
Function cmGetCurrentUserAttribute(pAttr = "") Export
	If pAttr = Undefined Then
		pAttr = "";
	EndIf;
	If ValueIsFilled(pAttr) Then
		Return SessionParameters.CurrentUser[pAttr];
	Else
		Return SessionParameters.CurrentUser;
	EndIf;
EndFunction // cmGetCurrentUserAttribute

// -----------------------------------------------------------------------------
Function cmGetGuestsChoiceDataList(pText) Export
	vChoiceDataList = New ValueList;
	vQry = New Query;
	vQry.Text =
	"SELECT
	|	Clients.Ref AS Ref,
	|	Clients.Description AS Description,
	|	Clients.FullName AS FullName,
	|	Clients.Code AS Code,
	|	Clients.DateOfBirth AS DateOfBirth,
	|	Clients.IdentityDocumentSeries AS IDSeries,
	|	Clients.IdentityDocumentNumber AS IDNumber,
	|	Clients.Phone AS Phone,
	|	Clients.SocialSecurityNumber AS SocialSecurityNumber
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	Clients.FullName LIKE &qText
	|	AND Clients.DeletionMark = False
	|	AND Clients.IsFolder = False";
	vQry.SetParameter("qText", pText+"%");
	vCurrentUser = SessionParameters.CurrentUser;
	If ValueIsFilled(vCurrentUser) And ValueIsFilled(vCurrentUser.Customer) Then
		vQry.Text = vQry.Text + " AND Clients.Author = &qAuthor";
		vQry.SetParameter("qAuthor", vCurrentUser);
	EndIf;
	vQryResult = vQry.Execute().Select();
	While vQryResult.Next() Do
		vChoiceDataList.Add(vQryResult.Ref, vQryResult.FullName + " " + 
		                                    ?(ValueIsFilled(vQryResult.DateOfBirth), Format(vQryResult.DateOfBirth, "DLF=D") + " ", "") + 
											?(ValueIsFilled(vQryResult.Phone), TrimAll(vQryResult.Phone) + " ", "") + 
											?(ValueIsFilled(vQryResult.SocialSecurityNumber), TrimAll(vQryResult.SocialSecurityNumber) + " ", "") +
											?(ValueIsFilled(vQryResult.IDSeries), TrimAll(vQryResult.IDSeries) + " ", "") + 
											?(ValueIsFilled(vQryResult.IDNumber), TrimAll(vQryResult.IDNumber) + " ", "") +
											"("+TrimAll(vQryResult.Code)+")");
	EndDo;
	//Return
	Return PutToTempStorage(vChoiceDataList);
EndFunction // cmGetGuestsChoiceDataList

// -----------------------------------------------------------------------------
Function ChangeCurrentHotel(pHotel) Export
	If ValueIsFilled(pHotel) Then
		SessionParameters.CurrentHotel = pHotel;
		SetTimeZone(SessionParameters.CurrentWorkstation);
		vHotelTitle = TrimAll(pHotel.LegacyName);
		If IsBlankString(vHotelTitle) Then
			vHotelTitle = TrimAll(pHotel.Description);
		EndIf;
		Return vHotelTitle;
	Else
		Return "";
	EndIf;
EndFunction // ChangeCurrentHotel

// -----------------------------------------------------------------------------
Function GetFullHotelName(pHotel) Export
	If ValueIsFilled(pHotel) Then
		Return Catalogs.Hotels.pmGetHotelPrintName(pHotel, SessionParameters.CurrentLanguage);
	Else
		Return "";
	EndIf;
EndFunction // GetFullHotelName

// -----------------------------------------------------------------------------
Function CheckIfHotelCouldBeCleared() Export
	vAllowClear = False;
	If IsInRole("RightsToChooseHotel") Then
		vUser = SessionParameters.CurrentUser;
		If ValueIsFilled(vUser) Then
			vPermissionGroup = cmGetEmployeePermissionGroup(vUser);
			If ValueIsFilled(vPermissionGroup) Then
				If vPermissionGroup.HotelAllowed.Count() = 0 Then
					vAllowClear = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vAllowClear;
EndFunction // CheckIfHotelCouldBeCleared

// -----------------------------------------------------------------------------
//  Description: Returns text according to the current or parameter language.
//  In comparison to the NStr() function it is simply returns input string if
//  string format is wrong or language is undefined. NStr() in this case returns empty string
//
// Parameters:
//  pStr	 - String - Text string in different languages
//  pLang	 - CatalogRef.Languages	 - Language
// 
// Returns:
//  String - Text in given language
//
Function cmNStrAtServer(pStr, pLang = Undefined) Export
	Return cmNStr(pStr, pLang);
EndFunction // cmNStrAtServer

// -----------------------------------------------------------------------------
Procedure cmWriteLogEventAtServer(pEventName, pEventLogLevel = Undefined, pMetadata = Undefined, pData = Undefined, pRemarks = "") Export
	vMetadata = Undefined;
	If pMetadata <> Undefined Then
		Execute("vMetadata = Metadata."+pMetadata);
	Endif;
	vData = Undefined;
	If pData <> Undefined Then
		Execute("vData = "+pData);
	EndIf;
	vEventLogLevel = EventLogLevel.Information;
	If Not pEventLogLevel = Undefined Then 
		If TypeOf(pEventLogLevel) =  Type("String") Then
			vEventLogLevel =  EventLogLevel[pEventLogLevel];
		Else
			vEventLogLevel = pEventLogLevel;
		EndIf;	
	EndIf;	
	
	WriteLogEvent(pEventName, vEventLogLevel, vMetadata, vData, pRemarks);
EndProcedure // cmWriteLogEventAtServer

// -----------------------------------------------------------------------------
Function cmCheckUserPermissionsAtServer(pPermission) Export
	Return cmCheckUserPermissions(pPermission);
EndFunction // cmCheckUserPermissionsAtServer

// -----------------------------------------------------------------------------
Function cmGetEmployeePermissionGroupAtServer(pEmployee) Export
	Return cmGetEmployeePermissionGroup(pEmployee);
EndFunction // cmGetEmployeePermissionGroupAtServer

// -----------------------------------------------------------------------------
Function cmGetServerCurrentSessionDate() Export
	Return CurrentSessionDate();
EndFunction // cmGetServerCurrentDate

// -----------------------------------------------------------------------------
Function cmGetAtributeAsArray(pObj) Export
	vArr = new Structure();
	If ValueIsFilled(pObj.Ref) Then
		vObj = pObj.GetObject();
		vObjMetadata = vObj.Metadata();
		vObjMetadataName = vObjMetadata.FullName();
		// Attributes
		For Each Atribute In vObjMetadata.Attributes Do 
			vArr.Insert(Atribute.Name, vObj[Atribute.Name]);	
		EndDo;	
		vArr.Insert("Ref", vObj.Ref);
		If lower(Left(vObjMetadataName, 7)) = "catalog" Then
			Try
				If Not vArr.Property("Description") Then
					vArr.Insert("Description", vObj.Description);
				EndIf;	
			Except
			EndTry;
			Try
				If Not vArr.Property("Code") Then
					vArr.Insert("Code", vObj.Code);
				EndIf;
			Except
			EndTry;
			Try
				If Not vArr.Property("Parent") Then
					vArr.Insert("Parent", vObj.Parent);
				EndIf;
			Except
			EndTry;
			Try
				If Not vArr.Property("Owner") Then
					vArr.Insert("Owner", vObj.Owner);
				EndIf;
			Except
			EndTry;
			Try
				If Not vArr.Property("RefDeletionMark") Then
					vArr.Insert("RefDeletionMark", vObj.DeletionMark);
				EndIf;
			Except
			EndTry;
		ElsIf lower(Left(vObjMetadataName, 8)) = "document" Then
			Try
				If Not vArr.Property("Number") Then
					vArr.Insert("Number", vObj.Number);
				EndIf;	
			Except
			EndTry;
			Try
				If Not vArr.Property("Date") Then
					vArr.Insert("Date", vObj.Date);
				EndIf;
			Except
			EndTry;
			Try
				If Not vArr.Property("Author") Then
					vArr.Insert("Author", vObj.Author);
				EndIf;
			Except
			EndTry;
			Try
				If Not vArr.Property("RefPosted") Then
					vArr.Insert("RefPosted", vObj.Posted);
				EndIf;
			Except
			EndTry;
			Try
				If Not vArr.Property("RefDeletionMark") Then
					vArr.Insert("RefDeletionMark", vObj.DeletionMark);
				EndIf;
			Except
			EndTry;
		EndIf;
		// Tabular parts
		For Each TabPart In vObjMetadata.TabularSections Do
			vTabPartName = TabPart.Name;
			vTabPartRows = new Array;
			For i = 0 To (vObj[vTabPartName].Count() - 1) Do
				vTabPartRow = vObj[vTabPartName][i];
				vTabPartStruct = new Structure;
				For Each TabPartAttr In TabPart.Attributes Do
					vTabPartStruct.Insert(TabPartAttr.Name, vTabPartRow[TabPartAttr.Name]);
				EndDo;
				vTabPartRows.Add(vTabPartStruct);
			EndDo;
			vArr.Insert(vTabPartName, vTabPartRows);
		EndDo;
	EndIf;
	Return vArr;
EndFunction	

// -----------------------------------------------------------------------------
Function cmGetUserPasswordKKM(pAskAlways = False, pCashRegister) Export
	vPassword = "";
	If Not pAskAlways Then
		vUser = SessionParameters.CurrentUser;
		If ValueIsFilled(vUser) Then
			If ValueIsFilled(vUser.EmployeePreferences) Then
				vPassword = TrimAll(vUser.EmployeePreferences.CashRegisterPassword);
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vPassword) And ValueIsFilled(pCashRegister) And Not IsBlankString(pCashRegister.CashRegisterPassword) Then
		vPassword = TrimAll(pCashRegister.CashRegisterPassword);
	EndIf;
	Return vPassword;
EndFunction	

// -----------------------------------------------------------------------------
//  Description: Returns array of text lines built from the multi line text
//
// Parameters:
//  pTextStr - String	 - Multi line text
// 
// Returns:
//  Array - Array of text lines
//
Function GetTextLinesArray(pTextStr) Export
	vTxtArr = New Array;
	If Not IsBlankString(pTextStr) Then
		vTxt = New TextDocument();
		vTxt.SetText(pTextStr);
		For i = 1 To vTxt.LineCount() Do
			vStr = vTxt.GetLine(i);
			vTxtArr.Add(vStr);
		EndDo;
	EndIf;
	Return vTxtArr;
EndFunction // cmGetTextLinesArray

// -----------------------------------------------------------------------------
//  Description: Removes prefix and leading zeros from the document number
//
// Parameters:
//  pNumber	 - String	 - Document number
// 
// Returns:
//  String - Document number presentation
//
Function GetDocumentNumberPresentation(pNumber) Export
	vNumberPresentation = "";
	vNumber = TrimAll(pNumber);
	Try
		vNumberLength = StrLen(vNumber);
		vPrefixLength = 0;
		For i = 1 To vNumberLength Do
			vChar = Mid(vNumber, i, 1);
			If (vChar < "0" Or vChar > "9") And vChar <> "/" Then
				vPrefixLength = i;
			EndIf;
		EndDo;
		If vPrefixLength < vNumberLength Then
			vNumberPresentation = Mid(vNumber, vPrefixLength + 1);
			vNumberPresentation = Format(Number(vNumberPresentation), "ND=12; NFD=0; NG=");
		EndIf;
		If IsBlankString(vNumberPresentation) Then
			vNumberPresentation = vNumber;
		EndIf;
	Except
		vNumberPresentation = TrimAll(pNumber);
	EndTry;
	Return vNumberPresentation;
EndFunction // cmGetDocumentNumberPresentation	

// -----------------------------------------------------------------------------
//
// Parameters:
//  pName	 - String	 - Session parameter
// 
// Returns:
//  String - Session parameter value
//
Function cmGetSessionParametersAttribute(pName) Export
	Return SessionParameters[pName];
EndFunction // cmGetServerCurrentDate

// -----------------------------------------------------------------------------
//  Description: Returns structure with client identity cards connection parameters
// 
// Returns:
//  Structure - Params 
//
Function cmGetCurrentWorkstation() Export 
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vCurWstn = SessionParameters.CurrentWorkstation;
		If vCurWstn.HasConnectionToIdentityCardsProcessingSystem And ValueIsFilled(vCurWstn.IdentityCardsProcessingSystemParameters) Then
			vParams = vCurWstn.IdentityCardsProcessingSystemParameters;
			If (vParams.CardReaderType = Enums.CardReaderTypes.RS232 Or vParams.CardReaderType = Enums.CardReaderTypes.RS232_1C Or vParams.CardReaderType = Enums.CardReaderTypes.IronLogicZ2) Then
				strucRFID = New Structure("RFID, CardReaderType, LogicalDeviceNumber, Port, BaudRate, DataBits, Parity, StopBits, Prefix, Suffix",
				                          vParams, vParams.CardReaderType, vParams.LogicalDeviceNumber, vParams.Port, vParams.BaudRate,
				                          vParams.DataBits, vParams.Parity, vParams.StopBits, vParams.Prefix, vParams.Suffix);
				
				Return strucRFID;
			EndIf;
		EndIf;
	EndIf;
EndFunction

// -----------------------------------------------------------------------------
Procedure AddError(amRC, pErrorCode, pErrorText) Export 
	vErrCode = pErrorCode;
	If Not ValueIsFilled(vErrCode) Then
		vErrCode = "999";  
	EndIf;	
    amRC.Insert("RC_CODE", vErrCode); 	
    amRC.Insert(vErrCode, pErrorText);	
	WriteLogEvent(NStr("en = 'IdentityCardsDriver.Error'; de = 'IdentityCardsDriver.Error'; ru = 'ДрайверКартИдентификацииКлиентов.Ошибка'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Procedure SaveLogicalDeviceNumber(IdentityCardSystemParameters, CurrentDeviceNumber) Export     
	SetPrivilegedMode(True);
	vPrmObj = IdentityCardSystemParameters.GetObject();
	vPrmObj.LogicalDeviceNumber = CurrentDeviceNumber;
	vPrmObj.Write();        
	SetPrivilegedMode(False);
EndProcedure

// -----------------------------------------------------------------------------
//  Creates new or returns existing client identification card by card identifier
//
// Parameters:
//  pIdentifier				 - 	 - 
//  pIDCardRef				 - 	 - 
//  pParentDoc				 - 	 - 
//  pFolio					 - 	 - 
//  pClient					 - 	 - 
//  pRoom					 - 	 - 
//  pDateTimeFrom			 - 	 - 
//  pDateTimeTo				 - 	 - 
//  pAdd					 - 	 - 
//  pCardUID				 - 	 - 
//  pUseDeleted				 - 	 - 
//  pIdentificationCardType	 - 	 - 
// 
// Returns:
//  CatalogRef.IdentificationCards - Client identification card reference
//
Function GetClientIdentificationCard(pIdentifier, pIDCardRef, pParentDoc, pFolio, pClient, pRoom, pDateTimeFrom, pDateTimeTo, pAdd = True, pCardUID = Undefined, pUseDeleted = False, pIdentificationCardType = Undefined, pDoorLockSystemAuthorization = Undefined) Export
	Return cmGetClientIdentificationCard(pIdentifier, pIDCardRef, pParentDoc, pFolio, pClient, pRoom, pDateTimeFrom, pDateTimeTo, pAdd, pCardUID, pUseDeleted, pIdentificationCardType, pDoorLockSystemAuthorization);
EndFunction // GetClientIdentificationCard

// -----------------------------------------------------------------------------
//  Сhange the catalog item attribute
//
// Parameters:
//  pRef		 - CatalogRef	 - Any ref to the catalog item
//  pAttributes	 - Structure	 - A list of attributes to change with new values
//
Procedure cmWriteAttributeCatalogByRef(pRef, pAttributes) Export 
	vObj = pRef.GetObject();
	For Each vKeyValue In pAttributes Do
		vObj[vKeyValue.Key] = vKeyValue.Value;
	EndDo;  
	vObj.Write();	
EndProcedure // cmWriteAttributeCatalogByRef()

// -----------------------------------------------------------------------------
//  Function tries to find and return client identification card by card identifier
//
// Parameters:
//  pIdentifier	 - String	 - Card ID
//  pUseDeleted	 - Boolean	 - Reuse cards marked for deletion or create new ones
// 
// Returns:
//  CatalogRef.IdentificationCards - Client identification card reference or empty reference
//  -----------------------------------------------------------------------------
//
Function GetClientIdentificationCardById(pIdentifier, pUseDeleted = False) Export
	Return cmGetClientIdentificationCardById(pIdentifier, pUseDeleted);
EndFunction // GetClientIdentificationCardById

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel					 - CatalogRef.Hotels	 - Hotel
//  pAssignedAuthorizations	 - CatalogRef.DoorLockSystemAuthorizations	 - Assigned authorizations
// 
// Returns:
//  CatalogRef.DoorLockSystemAuthorizations - Ref
//
Function qmFindAuthorizations(pHotel, pAssignedAuthorizations) Export
	vAuthRef = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DoorLockSystemAuthorizations.Ref AS Ref
	|FROM
	|	Catalog.DoorLockSystemAuthorizations AS DoorLockSystemAuthorizations
	|WHERE
	|	DoorLockSystemAuthorizations.AssignedAuthorizations = &qAssignedAuthorizations
	|	AND (DoorLockSystemAuthorizations.Hotel = &qHotel
	|			OR &qIsEmptyHotel)
	|	AND NOT DoorLockSystemAuthorizations.DeletionMark
	|	AND NOT DoorLockSystemAuthorizations.IsFolder
	|
	|ORDER BY
	|	DoorLockSystemAuthorizations.Code";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qAssignedAuthorizations", pAssignedAuthorizations);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() = 1 Then
		vAuthRef = vQryRes.Get(0).Ref;
	EndIf;
	Return vAuthRef;
EndFunction // pmFindAuthorizations

// -----------------------------------------------------------------------------
Function cmGetServiceDescription(pService) Export
	Return pService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage);
EndFunction // cmGetServiceDescription

// -----------------------------------------------------------------------------
Function cmGetOrderItemDescription(pItem) Export
	Return cmNStr(pItem.Description, SessionParameters.CurrentLanguage);
EndFunction // cmGetOrderItemDescription

// -----------------------------------------------------------------------------
Function cmGetPaymentSectionDescription(pPS) Export
	Return pPS.GetObject().pmGetDescription(SessionParameters.CurrentLanguage);
EndFunction // cmGetServiceDescription

// -----------------------------------------------------------------------------
Procedure Wait(pSeconds) Export
	cmWait(pSeconds);
EndProcedure // cmWait

// -----------------------------------------------------------------------------
Function cmFillParametersKeyCard(pAccRef) Export
	// Fill parameters
	vParameters = new Structure;
	vParameters.Insert("Room");
	vParameters.Insert("CheckInDate");
	vParameters.Insert("CheckOutDate");
	vParameters.Insert("Guest");
	vParameters.Insert("AccommodationType");
	vParameters.Insert("ParentDoc");
	vParameters.Insert("Folio");
	vParameters.Insert("DoorLockSystemAuthorization");
	vParameters.Insert("CurrentUser",SessionParameters.CurrentUser);
	vParameters.Insert("EmployeePreferences",SessionParameters.CurrentUser.EmployeePreferences);
	vParameters.Insert("EmployeePreferencesDoorLockSystemLogin",SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin);
	vParameters.Insert("NumberOfKeys", 1);
	vParameters.Insert("IdentificationCard", Catalogs.IdentificationCards.EmptyRef());
	
	vCurDoc = pAccRef;
	
	If ValueIsFilled(vCurDoc.Room) Then
		vParameters.Room = vCurDoc.Room;
	EndIf;
	vParameters.CheckInDate = cmGetKeyCardCheckInTime(vCurDoc.CheckInDate, ?(TypeOf(vCurDoc) = Type("DocumentRef.Reservation"), True, False));
	vParameters.CheckOutDate = cmGetLastCheckOutDateInChain(vCurDoc);
	vParameters.Guest = vCurDoc.Guest;
	vParameters.AccommodationType = vCurDoc.AccommodationType;
	vParameters.ParentDoc = vCurDoc;
	If ValueIsFilled(vParameters.Room) And ValueIsFilled(vParameters.Room.DoorLockSystemAuthorization) Then
		vParameters.DoorLockSystemAuthorization = vParameters.Room.DoorLockSystemAuthorization;
	ElsIf (TypeOf(vCurDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCurDoc) = Type("DocumentRef.Reservation")) And 
		ValueIsFilled(vCurDoc.BoardPlace) And ValueIsFilled(vCurDoc.BoardPlace.DoorLockSystemAuthorization) Then 
		vParameters.DoorLockSystemAuthorization = vCurDoc.BoardPlace.DoorLockSystemAuthorization;
	EndIf;
	// Fill folio from the last charging rule
	vParameters.Folio = Documents.Folio.EmptyRef();
	If vCurDoc.ChargingRules.Count() > 0 Then
		vParameters.Folio = vCurDoc.ChargingRules.Get(vCurDoc.ChargingRules.Count()-1).ChargingFolio;
	EndIf;
	Return vParameters;
EndFunction // IssueKeyCards

// -----------------------------------------------------------------------------
Function CalculateVATSum(pVATRAte, pAmount, pDate = '00010101') Export
	Return cmCalculateVATSum(pVATRAte, pAmount, pDate);
EndFunction // CalculateVATSum

// -----------------------------------------------------------------------------
//  Creates form item element according to the parameters
//
// Parameters:
//  pForm		 - ClientApplicationForm - Form to add item to
//  pParent		 - FormItem				 - Parent item of the new item
//  pName		 - String				 - Item name
//  pType		 - String- Value from the item type enumeration: "FormButton"; "FormDecoration"; "FormGroup"; "FormTable"; "FormField"
//  pParameters	 - Structure			 - Form item extra parameters and actions
// 
// Returns:
//  FormField  
//
Function cmCreateItem(pForm, pParent, pName, pType, pParameters) Export
	vItem = pForm.Items.Add(pType+pName, Type(pType), pParent);	
	For Each vParameter in pParameters Do 		
		If StrFind(vParameter.Key, "SetAction") > 0 Then 
			vItem.SetAction(StrReplace(vParameter.Key, "SetAction", ""), vParameter.Value);
		Else      
			vItem[vParameter.Key] = vParameter.Value;
		EndIf;		
	EndDo;
	Return vItem;
EndFunction
  
// -----------------------------------------------------------------------------
//  Get localization code being currently used. This function will work if
//  localization code was entered first in the Languages reference.
// 
// Returns:
//  String - Localization code for the session current language
//
Function LocalizationCode() Export
	vLocalizationCode = "";
	If ValueIsFilled(SessionParameters.CurrentLanguage) Then
		If Not IsBlankString(SessionParameters.CurrentLanguage.LocalizationCode) Then
			vLocalizationCode = "L=" + TrimAll(SessionParameters.CurrentLanguage.LocalizationCode);
		EndIf;
	EndIf;
	Return vLocalizationCode;
EndFunction // LocalizationCode

// -----------------------------------------------------------------------------
//  Description: Checks if current user has role specified as parameter
//
// Parameters:
//  pRoleName	 - String	 - User role description
// 
// Returns:
//  Boolean - Role Availability
//
Function cmIsInRole(pRoleName) Export   
	vIsInRole = CachedCommonFunctions.cmIsInRole(pRoleName);
	Return vIsInRole;
EndFunction // cmIsInRole

// -----------------------------------------------------------------------------
// Description: Checks if current user has access right specified as a parameter 
//              for a given metadata object
// -----------------------------------------------------------------------------
Function cmAccessRight(pRightName, pMetadataType, pMetadataName) Export
	Return AccessRight(pRightName, Metadata[pMetadataType][pMetadataName]);
EndFunction // cmAccessRight

// -----------------------------------------------------------------------------
// Fill catalogs with dafault items
Procedure cmFillFormOpenOptionsMetadata() Export
	vObjCatForms = Catalogs.FormOpenOptions;
	// Check catalog structure
	vCatalogs = vObjCatForms.FindByAttribute("SystemName","CTLG");
	If vCatalogs.IsEmpty() Then
		vCatalogsObj = vObjCatForms.CreateFolder();
		vCatalogsObj.SystemName = "CTLG";
		vCatalogsObj.Description = NStr("en = 'Catalogs'; de = 'Kataloge'; ru = 'Справочники'");
		vCatalogsObj.Write();
		vCatalogs = vCatalogsObj.Ref;
	EndIf;	
	vDocs = vObjCatForms.FindByAttribute("SystemName","DCMT");
	If vDocs.IsEmpty() Then
		vCatalogsObj = vObjCatForms.CreateFolder();
		vCatalogsObj.SystemName = "DCMT";
		vCatalogsObj.Description = NStr("en = 'Documents'; de = 'Unterlagen'; ru = 'Документы'");
		vCatalogsObj.Write();
		vDocs = vCatalogsObj.Ref;
	EndIf;	
	// Processing catalogs
	For Each vMetCat In Metadata.Catalogs Do
		vFoormsList = New ValueList;
		vCreateCatalog = False;
		For Each vFrm In vMetCat.Forms Do
			If vFrm.FormType = Metadata.ObjectProperties.FormType.Managed Then
				vFoormsList.Add(vFrm.Name, vFrm.Synonym);
				vCreateCatalog = True;
			EndIf;	
		EndDo;
		If vCreateCatalog Then
			vSystemName = "Catalog."+vMetCat.Name;
			vCurRef = vObjCatForms.FindByAttribute("SystemName",vSystemName,vCatalogs);
			If vCurRef.IsEmpty() Then
				vNewObj = vObjCatForms.CreateFolder();
				vNewObj.SystemName = vSystemName;
				vNewObj.Parent = vCatalogs;
				vNewObj.Description = vMetCat.Synonym;
				vNewObj.Write();
				vCurObj = vNewObj;
			Else
				vCurObj = vCurRef.GetObject();
			EndIf;	
			vCurObj.Forms = New ValueStorage(vFoormsList);
			vCurObj.Write();
		EndIf;
	EndDo;
	// Processing documents
	For Each vMetCat In Metadata.Documents Do
		vFoormsList = New ValueList;
		vCreateCatalog = False;
		For Each vFrm In vMetCat.Forms Do
			If vFrm.FormType = Metadata.ObjectProperties.FormType.Managed Then
				vFoormsList.Add(vFrm.Name, vFrm.Synonym);
				vCreateCatalog = True;
			EndIf;	
		EndDo;
		If vCreateCatalog Then
			vSystemName = "Document."+vMetCat.Name;
			vCurRef = vObjCatForms.FindByAttribute("SystemName",vSystemName,vDocs);
			If vCurRef.IsEmpty() Then
				vNewObj = vObjCatForms.CreateFolder();
				vNewObj.SystemName = vSystemName;
				vNewObj.Parent = vDocs;
				vNewObj.Description = vMetCat.Synonym;
				vNewObj.Write();
				vCurObj = vNewObj;
			Else
				vCurObj = vCurRef.GetObject();
			EndIf;	
			vCurObj.Forms = New ValueStorage(vFoormsList);
			vCurObj.Write();
		EndIf;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
//  Sets the properties of the form
//
// Parameters:
//  pForm	 - Form	 - managed form
//
Procedure cmSetFormProperties(pForm) Export
	vArrNameForm = StrSplit(pForm.FormName,".");
	If vArrNameForm.Count()=0 Then
		Return;
	EndIf;
	vObjectTypeName = vArrNameForm[0]+"."+vArrNameForm[1];
	vFormName = vArrNameForm[vArrNameForm.Count()-1];
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FormOpenOptionsPropertiesForms.Item,
		|	FormOpenOptionsPropertiesForms.Visible,
		|	FormOpenOptionsPropertiesForms.Enabled,
		|	FormOpenOptionsPropertiesForms.FillItem,
		|	FormOpenOptionsPropertiesForms.Title
		|FROM
		|	Catalog.FormOpenOptions.PropertiesForm AS FormOpenOptionsPropertiesForms
		|WHERE
		|	FormOpenOptionsPropertiesForms.Ref.Form = &qFormName
		|	AND FormOpenOptionsPropertiesForms.Ref.IsActive
		|	AND FormOpenOptionsPropertiesForms.Ref.SystemName = &qObjectTypeName
		|	AND FormOpenOptionsPropertiesForms.Ref.DeletionMark = FALSE";
	
	Query.SetParameter("qFormName", vFormName);
	Query.SetParameter("qObjectTypeName", vObjectTypeName);
	
	QueryResult = Query.Execute();
	
	vRes = QueryResult.Select();      
	
	vExistCheckedAttributes = False;
	
	vAllAttributes = pForm.GetAttributes();
	For Each vAt In vAllAttributes Do
		If vAt.Name = "CheckedAttributesManual" Then
			vExistCheckedAttributes = True;
			Break; 
		EndIf;	
	EndDo;	
	
	While vRes.Next() Do
		Try
			vItem = pForm.Items[vRes.Item];
			vItem.Visible = vRes.Visible;
			vItem.Enabled = vRes.Enabled;
			If Not IsBlankString(vRes.Title) Then
				vItem.Title = vRes.Title;
			EndIf;
			If vExistCheckedAttributes Then
				If ValueIsFilled(vItem.DataPath) And vRes.FillItem Then
					pForm.CheckedAttributesManual.Add(vItem.DataPath);
				EndIf;
			EndIf;	
		Except
			WriteLogEvent(NStr("en = 'Fill in the form parameters'; de = 'Füllen Sie die Formularparameter aus'; ru = 'Заполняем параметры формы'"), EventLogLevel.Error,,NStr("en = 'Failed to set form parameters'; de = 'Fehler beim Festlegen der Formularparameter'; ru = 'Не удалось установить параметры формы'")+ErrorDescription());
		EndTry;
	EndDo;
EndProcedure	

// -----------------------------------------------------------------------------
//  Description: Checks the fill of the form attributes
//
// Parameters:
//  pCheckedAttributes		 - Array	 - List attributes
//  pCheckedAttributesManual - ValueList - List attributes manuals to check
//  pObject					 - Object	 - Object
// 
// Returns:
//  Boolean - True or False
//
Function cmFillCheckProcessingForm(pCheckedAttributes, pCheckedAttributesManual, pObject) Export
	vCancel = False;
	vIdObj = pCheckedAttributes.Find("Object");
	vArrAtr = New Array;
	If Not vIdObj = Undefined Then
		pCheckedAttributes.Delete(vIdObj);
		For Each vId In pCheckedAttributesManual Do
			vStr = vId.Value;
			vCharStr = StrFind(vStr, ".");
			vStrOccurrenceCount = StrOccurrenceCount(vStr, ".");
			If vCharStr = 0 Then
				vArrAtr.Add(vId.Value);
			Else 
				vStrAtr =  Mid(vStr, vCharStr + 1, StrLen(vStr) - vCharStr);
				vArrAtr.Add(vStrAtr);
			EndIf;	
		EndDo;
		vAdPapams = pObject.AdditionalProperties;
		vAdPapams.Insert("CheckedAttributes", vArrAtr);
		vCancel = Not pObject.CheckFilling();
	EndIf;
	Return vCancel;
EndFunction

// -----------------------------------------------------------------------------
// Description: Gets the binary data of the props by reference to the object
// Parameters:
//  <pRef>  		- Any Ref
//  <pAtrtibute>  	- Type.String
// Returns:
//   <Type.BinaryData>  Or Undefined
Function cmGetBinaryDataByRef(pRef = Undefined,pAtrtibute="") Export 
	vData = Undefined;
	If pRef <> Undefined And Not IsBlankString(pAtrtibute) Then
		vData = pRef[pAtrtibute].Get();
	EndIf; 
	Return vData;	
EndFunction //  cmBinaryDataByRef()

// -----------------------------------------------------------------------------
Function cmGetHideCorrectionVisibility(pHotel) Export
	vHideCorrectionsIsVisible = True;
	If ValueIsFilled(pHotel) Then
		If Not ValueIsFilled(pHotel.AccountingDate) Then
			vHideCorrectionsIsVisible = False;
		EndIf;
	EndIf;
	Return vHideCorrectionsIsVisible;
EndFunction // cmGetHideCorrectionVisibility

// -----------------------------------------------------------------------------
// Get hotel presentation
// Parameters:
//  Hotel  - <Type.Catalogref or Undafined> - 
// Returns:
//   <Type.String>   - Hotel full name
//
Function cmGetHotelPresentation(pHotel = Undefined) Export 
	vHotelName = "";
	If pHotel = Undefined Then
		vHotel = SessionParameters.CurrentHotel;
	Else
		vHotel = pHotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		vHotelName = Catalogs.Hotels.pmGetHotelPrintName(vHotel, SessionParameters.CurrentLanguage);
	EndIf;
	Return vHotelName;
EndFunction //  cmGetHotelPresentation()

// -----------------------------------------------------------------------------
// Function - Check exist object in metadata
//
// Parameters:
//  pType	 - String - metedata object
//
//  pName	 - String - Name module
//
// Returns:
//  Bolean -  Exist object in metadata
//
Function cmCheckExistObjectInMetadata(pType, pName) Export
	vObj = Metadata[pType].Find(pName);
	If vObj = Undefined Then 
		Return False;
	Else 
		Return True;
	EndIf;
EndFunction	

// -----------------------------------------------------------------------------
Function qmGetIssuedBy(pUnitCode) Export
	vQryRes = cmGetFMSRecord(pUnitCode, True).Choose();
	While vQryRes.Next() Do
		Return TrimAll(vQryRes.Description);
	EndDo;
	Return "";
EndFunction // GetIssuedBy

// -----------------------------------------------------------------------------
//  Description: This function checks whether current user has rights to open
//  report form or not
//
// Parameters:
//  pReport	 - CatalogRef.Reports - Catalog Reports reference
// 
// Returns:
//  Boolean - Boolean, true if user has rights, false if not
//
Function CheckUserRightsToOpenReport(pReport) Export
	vUserHasRights = True;
	If Not cmCheckUserPermissions("HavePermissionToRunAllReports") Then
		If ValueIsFilled(pReport) And ValueIsFilled(SessionParameters.CurrentUser) Then
			vPermissionGroup = SessionParameters.CurrentUser.PermissionGroup;
			If ValueIsFilled(vPermissionGroup) Then
				If pReport.PermissionGroup <> vPermissionGroup Then
					If pReport.PermissionGroups.Find(vPermissionGroup, "PermissionGroup") = Undefined Then
						vUserHasRights = False;
					EndIf;
				EndIf;
			Else
				vUserHasRights = False;
			EndIf;
		EndIf;
	EndIf;
	Return vUserHasRights;
EndFunction // CheckUserRightsToOpenReport

// -----------------------------------------------------------------------------
Function GetMainFormCaption(pHotel) Export
	vCaption = "";
	vCurNodeCode = "";
	vCurNode = ExchangePlans.CentralOfficeExchangePlan.ThisNode();
	If ValueIsFilled(vCurNode) Then
		vCurNodeCode = TrimAll(vCurNode.Code);
	EndIf;
	If IsBlankString(vCurNodeCode) Then
		vCurNode = ExchangePlans.ReplicationExchangePlan.ThisNode();
		If ValueIsFilled(vCurNode) Then
			vCurNodeCode = TrimAll(vCurNode.Code);
		EndIf;
	EndIf;
	If IsBlankString(vCurNodeCode) Then
		If ValueIsFilled(pHotel) Then
			vCaption = TrimAll(pHotel) + ?(ValueIsFilled(pHotel.AccountingDate), " - " + Format(pHotel.AccountingDate, "DF=dd.MM.yyyy"), "") + " ";
		Else
			vCaption = "";
		EndIf;
	Else
		If ValueIsFilled(pHotel) Then
			vCaption = TrimAll(pHotel) + ?(ValueIsFilled(pHotel.AccountingDate), " - " + Format(pHotel.AccountingDate, "DF=dd.MM.yyyy"), "") + " - " + vCurNodeCode + " ";
		Else
			vCaption = vCurNodeCode + " ";
		EndIf;
	EndIf;
	Return vCaption;
EndFunction // GetMainFormCaption

// -----------------------------------------------------------------------------
Function GetQuantityTypeDescription() Export
	vNQ = New NumberQualifiers(19, 7);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetQuantityTypeDescription

// -----------------------------------------------------------------------------
Function GetSumTypeDescription() Export
	vNQ = New NumberQualifiers(17, 2);
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetSumTypeDescription

// -----------------------------------------------------------------------------
Function GetNumberTypeDescription(pTotalDigits, pDecDigits, pNonnegative = False) Export
	If pNonnegative Then
		vNQ = New NumberQualifiers(pTotalDigits, pDecDigits, AllowedSign.Nonnegative);
	Else
		vNQ = New NumberQualifiers(pTotalDigits, pDecDigits);
	EndIf;
	vTA = New Array;
	vTA.Add(Type("Number"));
	vTypeDescr = New TypeDescription(vTA, vNQ);
	Return vTypeDescr;
EndFunction // cmGetNumberTypeDescription

// -----------------------------------------------------------------------------
Function GetCatalogTypeDescription(pCatalog) Export
	vTA = New Array;
	vTA.Add(Type("CatalogRef." + pCatalog));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetCatalogTypeDescription

// -----------------------------------------------------------------------------
Function GetDocumentTypeDescription(pDocument) Export
	vTA = New Array;
	vTA.Add(Type("DocumentRef." + pDocument));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetDocumentTypeDescription

// -----------------------------------------------------------------------------
Function GetDateTimeTypeDescription() Export
	vDQ = New DateQualifiers(DateFractions.DateTime);
	vTA = New Array;
	vTA.Add(Type("Date"));
	vTypeDescr = New TypeDescription(vTA, , , vDQ);
	Return vTypeDescr;
EndFunction // cmGetDateTimeTypeDescription

// -----------------------------------------------------------------------------
Function GetDateTypeDescription() Export
	vDQ = New DateQualifiers(DateFractions.Date);
	vTA = New Array;
	vTA.Add(Type("Date"));
	vTypeDescr = New TypeDescription(vTA, , , vDQ);
	Return vTypeDescr;
EndFunction // cmGetDateTypeDescription

// -----------------------------------------------------------------------------
Function GetTimeTypeDescription() Export
	vDQ = New DateQualifiers(DateFractions.Time);
	vTA = New Array;
	vTA.Add(Type("Date"));
	vTypeDescr = New TypeDescription(vTA, , , vDQ);
	Return vTypeDescr;
EndFunction // cmGetTimeTypeDescription

// -----------------------------------------------------------------------------
Function GetBooleanTypeDescription() Export
	vTA = New Array;
	vTA.Add(Type("Boolean"));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetBooleanTypeDescription

// -----------------------------------------------------------------------------
Function GetStringTypeDescription(pLength = 0, pAllowedLength = 0) Export
	If pLength <> 0 Or pAllowedLength <> 0 Then
		vSQ = New StringQualifiers(pLength, pAllowedLength);
		vTA = New Array;
		vTA.Add(Type("String"));
		vTypeDescr = New TypeDescription(vTA, , vSQ);
	Else
		vTA = New Array;
		vTA.Add(Type("String"));
		vTypeDescr = New TypeDescription(vTA);
	EndIf;
	Return vTypeDescr;
EndFunction // cmGetStringTypeDescription

// -----------------------------------------------------------------------------
Function GetValueStorageTypeDescription() Export
	vTA = New Array;
	vTA.Add(Type("ValueStorage"));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetValueStorageTypeDescription

// -----------------------------------------------------------------------------
Function GetEnumTypeDescription(pEnum) Export
	vTA = New Array;
	vTA.Add(Type("EnumRef."+pEnum));
	vTypeDescr = New TypeDescription(vTA);
	Return vTypeDescr;
EndFunction // cmGetEnumTypeDescription

// -----------------------------------------------------------------------------
Function NeedToCheckEmployeePINCode() Export
	If ValueIsFilled(SessionParameters.CurrentWorkstation) And SessionParameters.CurrentWorkstation.EmployeePINCodesAreMandatory Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // NeedToCheckEmployeePINCode

// -----------------------------------------------------------------------------
Function CheckEmployeePINCode(pPIN) Export
	If IsBlankString(pPIN) Then
		Return False;
	EndIf;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Employees.Ref AS Ref
	|FROM
	|	Catalog.Employees AS Employees
	|WHERE
	|	Employees.PBXAccountCode = &qPIN
	|	AND NOT Employees.DeletionMark
	|	AND NOT Employees.IsFolder";
	vQry.SetParameter("qPIN", Number(pPIN));
	vEmployees = vQry.Execute().Unload();
	If vEmployees.Count() = 1 Then
		SessionParameters.CurrentUser = vEmployees.Get(0).Ref;
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckEmployeePINCode

// -----------------------------------------------------------------------------
Function FindWorkstationByName(pWstnName) Export
	Return Catalogs.Workstations.FindByCode(pWstnName);
EndFunction // FindWorkstationByName

// -------------------------------------------------------------------------
Function AddWorkstation(Val vCurComputerName, Val vCurEmplRef) Export
	Var vMessage, vNewWstn, vSysInfo;
	vCurComputerRef = Undefined;
	Try
	vNewWstn = Catalogs.Workstations.CreateItem();
	vNewWstn.Code = vCurComputerName;
	If ComputerName() = vCurComputerName Then
		vSysInfo = New SystemInfo();
		vNewWstn.SysInfo = "Processor: " + vSysInfo.Processor + "; RAM: " + vSysInfo.RAM + "Mb; OS Version: " + vSysInfo.OSVersion;
	EndIf;
	vNewWstn.Write();
	vCurComputerRef = vNewWstn.Ref;
	vMessage = "ru = 'Зарегистрировано новое рабочее место <" + TrimAll(vCurComputerRef.Code) + ">! Необходимо установить его параметры.';
	           |de = 'Neue Workstation <" + TrimAll(vCurComputerRef.Code) + "> wurde erstellt! Es ist notwendig, um Arbeitsplatz Attributen zu füllen.';
	           |en = 'New workstation <" + TrimAll(vCurComputerRef.Code) + "> has been created! It is neccessary to fill workstation attributes.';"; 
	WriteLogEvent(NStr("en='System.OnStart';ru='Программа.Запуск';de='System.OnStart'"), EventLogLevel.Information, vCurComputerRef.Metadata(), vCurComputerRef, NStr(vMessage));
	cmSendMessageToEmployee(vCurEmplRef, NStr(vMessage));
	Except
		WriteLogEvent("AddWorkstation.Error",EventLogLevel.Error,,,ErrorDescription());
	EndTry;
	Return vCurComputerRef;
EndFunction // AddWorkstation

// -------------------------------------------------------------------------
Procedure SetSessionParametersCurrentWorkstation(pCurrentWorkstation) Export
	SessionParameters.CurrentWorkstation = pCurrentWorkstation;
EndProcedure // SetSessionParametersCurrentWorkstation

// -------------------------------------------------------------------------
Procedure GetPayerNameAndTIN(pCustomer, rPayerName, rPayerTIN) Export
	If ValueIsFilled(pCustomer) And TypeOf(pCustomer) = Type("CatalogRef.Customers") Then
		rPayerTIN = "";
		vTIN = TrimAll(pCustomer.TIN);
		If cmIsNumber(vTIN) And (StrLen(vTIN) = 10 Or StrLen(vTIN) = 12) Then
			rPayerTIN = vTIN;
		EndIf;
		If Not IsBlankString(pCustomer.LegacyName) Then
			rPayerName = TrimAll(pCustomer.LegacyName);
		Else
			rPayerName = TrimAll(pCustomer.Description);
		EndIf;
	Else
		rPayerTIN = "";
		rPayerName = "";
	EndIf;
EndProcedure // GetPayerNameAndTIN

// -------------------------------------------------------------------------
Function GetForecastStartDate(pHotel) Export
	vForecastStartDate = BegOfDay(CurrentSessionDate());
	If ValueIsFilled(pHotel) And Not pHotel.IsFolder And ValueIsFilled(pHotel.AccountingDate) Then
		vForecastStartDate = BegOfDay(pHotel.AccountingDate);
	EndIf;
	Return vForecastStartDate;
EndFunction // GetForecastStartDate

// -----------------------------------------------------------------------------
Function GetCardIdentifier(pCardData) Export
	vCardID = pCardData;
	If StrLen(pCardData) > 3 Then
		// Remove prefix and suffix chars
		If Right(pCardData, 3) = "+++" Then
			vCardID = Mid(TrimAll(pCardData), 2);
			vCardID = Left(vCardID, StrLen(vCardID) - 3);
		ElsIf Right(pCardData, 2) = "?," Then
			vCardID = Mid(TrimAll(pCardData), 2);
			vCardID = Left(vCardID, StrLen(vCardID) - 2);
		ElsIf CharCode(Left(pCardData, 1)) = 1110 And CharCode(Mid(pCardData, 14, 1)) = 191 Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf CharCode(Left(pCardData, 1)) = 186 And CharCode(Mid(pCardData, 14, 1)) = 191 Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf Left(pCardData, 1) = ";" And Mid(pCardData, 14, 1) = "?" Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf Upper(Right(pCardData, 7)) = "NO CARD" And StrLen(TrimAll(pCardData)) > 7 Then
			vCardID = TrimAll(Left(TrimAll(pCardData), StrLen(TrimAll(pCardData)) - 7));
		EndIf;
	Else
		vCardID = "";
	EndIf;
	Return vCardID;
EndFunction // GetCardIdentifier	

// -----------------------------------------------------------------------------
Function IsNumber(pStr) Export
	Return cmIsNumber(pStr);
EndFunction // IsNumber

// -----------------------------------------------------------------------------
Function GetDocumentRefByUUID(pDocumentType, pUUIDStr) Export
	vRef = Undefined;
	vUUID = New UUID(TrimAll(pUUIDStr));
	vRef = Documents[pDocumentType].GetRef(vUUID);
	If vRef.GetObject() = Undefined Then
		vRef = Undefined;
	EndIf;
	Return vRef;
EndFunction	

// -----------------------------------------------------------------------------
Function GetCatalogRefByUUID(pCatalogType, pUUIDStr) Export
	vRef = Undefined;
	vUUID = New UUID(TrimAll(pUUIDStr));
	vRef = Catalogs[pCatalogType].GetRef(vUUID);
	If vRef.GetObject() = Undefined Then
		vRef = Undefined;
	EndIf;
	Return vRef;
EndFunction	

// -----------------------------------------------------------------------------
Function ConvertCurrencies(pSum, pFromCurrency, pFromCurrencyExchangeRate = 0, pToCurrency, pToCurrencyExchangeRate = 0, pExchangeRateDate = Undefined, pHotel = Undefined) Export 
	Return cmConvertCurrencies(pSum, pFromCurrency, pFromCurrencyExchangeRate, pToCurrency, pToCurrencyExchangeRate, pExchangeRateDate, ?(ValueIsFilled(pHotel), pHotel, SessionParameters.CurrentHotel));
EndFunction // cmConvertCurrencies

// -----------------------------------------------------------------------------
Function GetCountryByCode(pCountryCode) Export
	Return cmGetCountryByCode(pCountryCode);
EndFunction // GetCountryByCode

// -----------------------------------------------------------------------------
Function GetDocumentTypeByMRZCountryCode(pCountryCode) Export
	If Upper(pCountryCode) = "RUS" Then
		Return Catalogs.IdentityDocumentTypes.FindByCode("22");
	Else
		Return Catalogs.IdentityDocumentTypes.FindByCode("ИП");
	EndIf;
EndFunction // GetDocumentTypeByMRZCountryCode

// -----------------------------------------------------------------------------
Function FormatSum(pSum, pCurrency, pZeroPresentation = "", pLang = Undefined, pNoCurency = False) Export
	Return cmFormatSum(pSum, pCurrency, pZeroPresentation, pLang, pNoCurency);
EndFunction // FormatSum

// -----------------------------------------------------------------------------
// Description: Returns text representation of the amount
// Parameters: Amount, Currency
// Return value:Formating String
// -----------------------------------------------------------------------------
Function cmFormattedSumString(pSum, pCurrency, pSmall = False) Export
	vSum = pSum;
	
	vLargeTextFont = New Font(, ?(pSmall, 12, 14));
	vSmallTextFont = New Font(, ?(pSmall, 8, 10));

	vArrStr = New Array;
	vSumStr = cmFormatSum(vSum, pCurrency, "NZ=");
	vPos = StrFind(vSumStr, ".");
	If vPos = 0 Then
		vPos = StrFind(vSumStr, ",");
	EndIf;		
	vArrSum = New Array;
	vArrSum.Add(New FormattedString(Left(vSumStr, vPos), vLargeTextFont));
	vArrSum.Add(New FormattedString(Mid(vSumStr, vPos+1), vSmallTextFont));
	vArrStr.Add(New FormattedString(vArrSum));
	
	Return New FormattedString(vArrStr, , );
EndFunction // cmFormattedSumString

// -----------------------------------------------------------------------------
Function cmFormattedSumTitle(pTitle, pSmall = False) Export
	vTextFont = New Font(, ?(pSmall, 10, 12));
	Return New FormattedString(pTitle, vTextFont);
EndFunction // cmFormattedSumTitle

// -----------------------------------------------------------------------------
// Description: Converts text to a formatted string
// Parameters: pArrStrings - array of fixed structures("String, Font")
// -----------------------------------------------------------------------------
Function cmGenerateFormattedString(pArrStrings) Export
	vResultArr = New Array;
	vArrStr = New Array;
	For Each vRowArr In pArrStrings Do
		If TypeOf(vRowArr) = Type("Picture") Then
			vArrStr.Add(vRowArr);
		ElsIf Not vRowArr.TextColor = Undefined And vRowArr.BackColor = Undefined And vRowArr.Ref = Undefined Then
			vArrStr.Add(New FormattedString(vRowArr.String, vRowArr.Font, vRowArr.TextColor));
		ElsIf vRowArr.TextColor = Undefined And Not vRowArr.Ref = Undefined Then
			vArrStr.Add(New FormattedString(vRowArr.String, vRowArr.Font, , , vRowArr.Ref));
		ElsIf Not vRowArr.TextColor = Undefined And Not vRowArr.Ref = Undefined Then
			vArrStr.Add(New FormattedString(vRowArr.String, vRowArr.Font, vRowArr.TextColor, , vRowArr.Ref));
		Else 
			vArrStr.Add(New FormattedString(vRowArr.String, vRowArr.Font));
		EndIf;
	EndDo;
	vResultArr.Add(New FormattedString(vArrStr));
	Return New FormattedString(vResultArr, , );
EndFunction //  cmGenerateFormattedString

// -----------------------------------------------------------------------------
Function DoAutoPeriodExtension(pHotel, pCheckOutDate, pFreeOfChargeMinutes) Export
	vMessage = "";
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE (&qHotelIsEmpty
	|			OR Accommodation.Hotel = &qHotel)
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND DATEDIFF(Accommodation.CheckOutDate, &qCheckOutDate, MINUTE) >= &qFreeOfChargePeriodInMinutes
	|
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qCheckOutDate", pCheckOutDate);
	vQry.SetParameter("qFreeOfChargePeriodInMinutes", pFreeOfChargeMinutes);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		Try
			vAccObj = vDocsRow.Ref.GetObject();
			If vAccObj.pmGetNextAccommodationInChain() = Undefined Then
				vAccObj.CheckOutDate = vAccObj.CheckOutDate + 3600;
				vAccObj.Duration = vAccObj.pmCalculateDuration();
				vAccObj.pmCalculateServices();
				vAccObj.Write(DocumentWriteMode.Posting);
				vAccObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
		Except
			vMessage = vMessage + TrimAll(vDocsRow.Ref) + " - " + cmGetRootErrorDescription(ErrorInfo()) + Chars.LF;
			WriteLogEvent(NStr("en='DataProcessor.ExtendInHouseGuestsPeriodOfStay';ru='Обработка.ПродлитьПериодПроживанияГостей';de='DataProcessor.ExtendInHouseGuestsPeriodOfStay'"), EventLogLevel.Warning, vAccObj.Metadata(), vAccObj.Ref, vMessage);
		EndTry;
	EndDo;
	Return TrimAll(vMessage);
EndFunction // DoAutoPeriodExtension

// -----------------------------------------------------------------------------
Function GetListOfAccommodationsToCheckOut(pHotel, pCheckOutDate, pFreeOfChargeMinutes) Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Ref,
	|	Accommodation.Room AS Room,
	|	Accommodation.Guest.FullName AS Guest,
	|	Accommodation.CheckInDate AS CheckInDate,
	|	Accommodation.CheckOutDate AS CheckOutDate
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	(&qHotelIsEmpty
	|			OR Accommodation.Hotel = &qHotel)
	|	AND Accommodation.Posted
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND (Accommodation.AccommodationType.Type = &qRoom
	|			OR Accommodation.AccommodationType.Type = &qBeds)
	|	AND Accommodation.CheckOutDate < &qCheckOutDate
	|
	|ORDER BY
	|	Accommodation.PointInTime";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qHotelIsEmpty", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qCheckOutDate", pCheckOutDate + pFreeOfChargeMinutes*60);
	vQry.SetParameter("qRoom", Enums.AccomodationTypes.Room);
	vQry.SetParameter("qBeds", Enums.AccomodationTypes.Beds);
	vAccDocs = vQry.Execute().Unload();
	vDocsArr = New Array();
	For Each vAccDocsRow In vAccDocs Do
		vAccDocStruct = New Structure("Ref, Room, Guest, CheckInDate, CheckOutDate", vAccDocsRow.Ref, vAccDocsRow.Room, vAccDocsRow.Guest, vAccDocsRow.CheckInDate, vAccDocsRow.CheckOutDate);
		vDocsArr.Add(vAccDocStruct);
	EndDo;
	Return vDocsArr;
EndFunction // GetListOfAccommodationsToCheckOut

// -----------------------------------------------------------------------------
Function GetInvoiceDefaultPrintForm(pLang) Export
	vQry = New Query;
	vQry.Text = "SELECT
	            |	ObjectPrintingForms.Ref AS Ref,
	            |	ObjectPrintingForms.Code AS Code
	            |FROM
	            |	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	            |WHERE
	            |	ObjectPrintingForms.ObjectType = &qObjectType
	            |	AND ObjectPrintingForms.IsActive
	            |	AND ObjectPrintingForms.IsDefault
	            |	AND (ObjectPrintingForms.Language = &qLanguage
	            |			OR ObjectPrintingForms.Language = &qEmptyLanguage)
	            |	AND NOT ObjectPrintingForms.DeletionMark
	            |	AND NOT ObjectPrintingForms.IsFolder
	            |
	            |ORDER BY
	            |	Code";
	vQry.SetParameter("qObjectType", Documents.Settlement.EmptyRef());
	vQry.SetParameter("qLanguage", pLang);
	vQry.SetParameter("qEmptyLanguage", Catalogs.Languages.EmptyRef());
	vQryResult = vQry.Execute().Select();
	While vQryResult.Next() Do
		Return vQryResult.Ref;
	EndDo;
	Return Undefined;
EndFunction // GetInvoiceDefaultPrintForm

// -----------------------------------------------------------------------------
Function GetProformaInvoiceDefaultPrintForm(pLang) Export
	vQry = New Query;
	vQry.Text = "SELECT
	            |	ObjectPrintingForms.Ref AS Ref,
	            |	ObjectPrintingForms.Code AS Code
	            |FROM
	            |	Catalog.ObjectPrintingForms AS ObjectPrintingForms
	            |WHERE
	            |	ObjectPrintingForms.ObjectType = &qObjectType
	            |	AND ObjectPrintingForms.IsActive
	            |	AND ObjectPrintingForms.IsDefault
	            |	AND (ObjectPrintingForms.Language = &qLanguage
	            |			OR ObjectPrintingForms.Language = &qEmptyLanguage)
	            |	AND NOT ObjectPrintingForms.DeletionMark
	            |	AND NOT ObjectPrintingForms.IsFolder
	            |
	            |ORDER BY
	            |	Code";
	vQry.SetParameter("qObjectType", Documents.ProformaInvoice.EmptyRef());
	vQry.SetParameter("qLanguage", pLang);
	vQry.SetParameter("qEmptyLanguage", Catalogs.Languages.EmptyRef());
	vQryResult = vQry.Execute().Select();
	While vQryResult.Next() Do
		Return vQryResult.Ref;
	EndDo;
	Return Undefined;
EndFunction // GetProformaInvoiceDefaultPrintForm

// -----------------------------------------------------------------------------
Function GetPrintSettingsArray(pWorkstationPrintSettings, pObjectPrintForm) Export
	vPrintSettingsArray = New Array();
	vFilter = New Structure("ObjectPrintingForm, IsActive", pObjectPrintForm, True); 
	vPrintSettingsSet = pWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
	For Each vPSRow In vPrintSettingsSet Do
		vPrintSettingsArray.Add(New Structure("Report, ObjectPrintingForm, IsActive, PrintDirection, FileSaveCatalog, FileName, AddTimeToTheFileName, EMails, PrinterName, FitToPage, PrintScale, Copies, CopiesPerPage, Collate, PageOrientation, PageSize, TopMargin, BottomMargin, LeftMargin, RightMargin, HeaderSize, FooterSize, BlackAndWhite, DuplexPrintingType", 
		                                       vPSRow.Report, vPSRow.ObjectPrintingForm, vPSRow.IsActive, vPSRow.PrintDirection, vPSRow.FileSaveCatalog, vPSRow.FileName, vPSRow.AddTimeToTheFileName, vPSRow.EMails, vPSRow.PrinterName, vPSRow.FitToPage, vPSRow.PrintScale, vPSRow.Copies, vPSRow.CopiesPerPage, vPSRow.Collate, vPSRow.PageOrientation, vPSRow.PageSize, vPSRow.TopMargin, vPSRow.BottomMargin, vPSRow.LeftMargin, vPSRow.RightMargin, vPSRow.HeaderSize, vPSRow.FooterSize, vPSRow.BlackAndWhite, vPSRow.DuplexPrintingType));
	EndDo;
	Return vPrintSettingsArray;
EndFunction // GetPrintSettingsArray

// -----------------------------------------------------------------------------
// Description: Applies print settings to the report or other print form
// Parameters: Spreadsheet with form, Structure with print form settings
// Return value: None
// -----------------------------------------------------------------------------
Procedure SetSpreadsheetSettings(pSpreadsheet, pPrintSettings) Export
	cmSetSpreadsheetSettings(pSpreadsheet, pPrintSettings);
EndProcedure // SetSpreadsheetSettings

// -----------------------------------------------------------------------------
Function GetCommandInterfaceFOParametersAtServer(pThinClientMode = False, pWebClientMode = False, pMobileDeviceMode = False, pThickClientMode = False) Export
	// Retrieve active sessions
	vActiveSessions = New ValueTable();
	vActiveSessions.Columns.Add("Period");
	vActiveSessions.Columns.Add("Employee");
	vActiveSessions.Columns.Add("EmployeeUUID");
	vActiveSessions.Columns.Add("EmployeeRef");
	vActiveSessions.Columns.Add("SessionID");
	
	SetPrivilegedMode(True);
	vActiveSessionsArray = GetInfoBaseSessions();
	For Each vActiveSession In vActiveSessionsArray Do
		vUser = vActiveSession.User;
		vUserUUID = "";
		vEmployeeRef = Undefined;
		If vUser <> Undefined Then
			vUserUUID = String(vUser.UUID);
			If Not IsBlankString(vUserUUID) Then
				vEmployeeRef = cmGetEmployeeByUserUUID(vUserUUID);
			EndIf;
		EndIf;
		
		vActiveSessionsRow = vActiveSessions.Add();
		vActiveSessionsRow.Period = vActiveSession.SessionStarted;
		
		vActiveSessionsRow.Employee = ?(vActiveSession.User <> Undefined, vActiveSession.User.Name, "");
		vActiveSessionsRow.Employee = ?(vActiveSession.User <> Undefined, vActiveSession.User.Name, "");
		vActiveSessionsRow.SessionID = vActiveSession.SessionNumber;
		vActiveSessionsRow.EmployeeUUID = vUserUUID;
		vActiveSessionsRow.EmployeeRef = vEmployeeRef;
	EndDo;
	SetPrivilegedMode(False);
	
	// Delete all inactive sessions from the register
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ActiveSessions.Period AS Period,
	|	ActiveSessions.Employee AS Employee,
	|	ActiveSessions.SessionID AS SessionID
	|FROM
	|	InformationRegister.ActiveSessions AS ActiveSessions";
	vSessions = vQry.Execute().Unload();
	For Each vSessionsRow In vSessions Do
		If vActiveSessions.FindRows(New Structure("Period, Employee, SessionID", vSessionsRow.Period, vSessionsRow.Employee, vSessionsRow.SessionID)).Count() = 0 Then
			vRcdMgr = InformationRegisters.ActiveSessions.CreateRecordManager();
			vRcdMgr.Period = vSessionsRow.Period;
			vRcdMgr.Employee = vSessionsRow.Employee;
			vRcdMgr.SessionID = vSessionsRow.SessionID;
			vRcdMgr.Read();
			If vRcdMgr.Selected() Then
				vRcdMgr.Delete();
			EndIf;
		EndIf;
	EndDo;
	
	// Create record for the current mobile device session
	vCurSession = GetCurrentInfoBaseSession();
	vRcdMgr = InformationRegisters.ActiveSessions.CreateRecordManager();
	vRcdMgr.Period = vCurSession.SessionStarted;
	vRcdMgr.Employee = ?(vCurSession.User <> Undefined, vCurSession.User.Name, "");
	vRcdMgr.SessionID = vCurSession.SessionNumber;
	vRcdMgr.ComputerName = vCurSession.ComputerName;
	vRcdMgr.ThinClientMode = pThinClientMode;
	vRcdMgr.ThickClientMode = pThickClientMode;
	vRcdMgr.WebClientMode = pWebClientMode;
	vRcdMgr.MobileDeviceMode = pMobileDeviceMode;
	vRcdMgr.Write(True);
	
	// Delete all inactive report settings records
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	CurrentUnsavedReportSettings.Report AS Report,
	|	CurrentUnsavedReportSettings.Employee AS Employee,
	|	CurrentUnsavedReportSettings.SessionID AS SessionID
	|FROM
	|	InformationRegister.CurrentUnsavedReportSettings AS CurrentUnsavedReportSettings";
	vSettings = vQry.Execute().Unload();
	For Each vSettingsRow In vSettings Do
		If vActiveSessions.FindRows(New Structure("EmployeeRef, SessionID", vSettingsRow.Employee, vSettingsRow.SessionID)).Count() = 0 Then
			vRcdMgr = InformationRegisters.CurrentUnsavedReportSettings.CreateRecordManager();
			vRcdMgr.Report = vSettingsRow.Report;
			vRcdMgr.Employee = vSettingsRow.Employee;
			vRcdMgr.SessionID = vSettingsRow.SessionID;
			vRcdMgr.Read();
			If vRcdMgr.Selected() Then
				vRcdMgr.Delete();
			EndIf;
		EndIf;
	EndDo;
	
	// Set MobileDevice functional option parameters
	vFOParams = New Structure("Period, Employee, SessionID, Hotel", vCurSession.SessionStarted, ?(vCurSession.User <> Undefined, vCurSession.User.Name, ""), vCurSession.SessionNumber, SessionParameters.CurrentHotel);
	Return vFOParams;
EndFunction // GetCommandInterfaceFOParametersAtServer

// -------------------------------------------------------------------------
Function UserIsNotAllowedToRunExtraSession() Export
	vResult = False;
	vEmployeePermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vEmployeePermissionGroup) Then
		If vEmployeePermissionGroup.EmployeesAreNotAllowedToRunMoreThenOneSessionPerWorkstation Then
			vCurSession = GetCurrentInfoBaseSession();
			vEmployee = ?(vCurSession.User <> Undefined, TrimR(vCurSession.User.Name), "");
			vComputer = TrimR(vCurSession.ComputerName);
			If Not IsBlankString(vEmployee) And Not IsBlankString(vComputer) Then
				vQry = New Query();
				vQry.Text = 
				"SELECT
				|	ActiveSessions.Period AS Period,
				|	ActiveSessions.Employee AS Employee,
				|	ActiveSessions.SessionID AS SessionID,
				|	ActiveSessions.ComputerName AS ComputerName,
				|	ActiveSessions.ThinClientMode AS ThinClientMode,
				|	ActiveSessions.ThickClientMode AS ThickClientMode,
				|	ActiveSessions.WebClientMode AS WebClientMode,
				|	ActiveSessions.MobileDeviceMode AS MobileDeviceMode
				|FROM
				|	InformationRegister.ActiveSessions AS ActiveSessions
				|WHERE
				|	ActiveSessions.Employee = &qEmployee
				|	AND ActiveSessions.ComputerName = &qComputerName
				|
				|ORDER BY
				|	Period";
				vQry.SetParameter("qEmployee", vEmployee);
				vQry.SetParameter("qComputerName", vComputer);
				vSessions = vQry.Execute().Unload();
				If vSessions.Count() > 1 Then
					vResult = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // UserIsNotAllowedToRunExtraSession

// -------------------------------------------------------------------------
Function GetRumModesForPermissionGroup(pUser = Undefined) Export  
	vStruct = New Structure;
	vStruct.Insert("EmployeesAreNotAllowedToRunMoreThenOneSessionPerWorkstation", False);
	vStruct.Insert("ThickClientLaunchIsForbidden", False);
	vStruct.Insert("ThinClientLaunchIsForbidden", False);
	vStruct.Insert("MobileClientLaunchIsForbidden", False);
	vStruct.Insert("WebClientLaunchIsForbidden", False);
	
	vUser = SessionParameters.CurrentUser;
	If ValueIsFilled(pUser) Then
		vUser = pUser;
	EndIf;	
	// Get params
	vEmployeePermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
	If ValueIsFilled(vEmployeePermissionGroup) Then
		FillPropertyValues(vStruct, vEmployeePermissionGroup); 
	EndIf;
	
	Return vStruct;
EndFunction	

// -------------------------------------------------------------------------
Function SetDesktop(pMobileClientMode = False) Export 
	vHomePageSettings = New HomePageSettings;
	vDefaultDesignerForm = vHomePageSettings.GetForms().LeftColumn;
	vForms = New HomePageForms;
	vArrForms = vForms.LeftColumn;
	vDefaultForm = "";
	vIsFirstRun = False;
	// Try to get default desktop form from permission group settings
	vCurrentUser = cmGetCurrentUserAttribute();
	If ValueIsFilled(vCurrentUser) Then
		vPermissionGroup = cmGetEmployeePermissionGroupAtServer(vCurrentUser);
		If ValueIsFilled(vPermissionGroup) Then
			vDesktopDP = cmGetAttributeByRef(vPermissionGroup, "DesktopExternalDataProcessor");
			If ValueIsFilled(vDesktopDP) Then
				vURL = GetURL(vDesktopDP, "ExternalProcessingStorage"); 
				vName = tcOnServer.ConnectExternalDataProcessor(vURL, tcOnServer.GetExternalProcessingValidName(tcOnServer.cmGetAttributeByRef(vDesktopDP, "FileName")));
				vDefaultForm = "ExternalDataProcessor." + vName + ".Form";
			Else
				vDefaultForm = cmGetAttributeByRef(vPermissionGroup, "DesktopForm");
			EndIf;
		EndIf;
	EndIf;
	If Not IsBlankString(vDefaultForm) Then
		// Set default settings 
		vArrForms.Add(vDefaultForm);
	Else
		// Load user settings
		vHomePageSettingsUser = SystemSettingsStorage.Load("Common/HomePageSettings");
		// Get default form for user
		vDefaultForm = GetActualFormDesktop(pMobileClientMode); 
		If vHomePageSettingsUser = Undefined Then
			// Set default settings 
			vArrForms.Add(vDefaultForm);
			vIsFirstRun = True;
		Else
			If vDefaultDesignerForm.Find(vDefaultForm) = Undefined Then
				// Set default settings 
				vArrForms.Add(vDefaultForm);
			Else
				// Get user settings forms
				vTempForms = SystemSettingsStorage.Load("Common/UserDesktopForms");
				If vTempForms <> Undefined And vTempForms.Count() > 2 Then
					vTempForms = Undefined;
				EndIf;
				If vTempForms <> Undefined Then
					// Apply user settings
					For Each vInd In vTempForms Do
						If Not vDefaultDesignerForm.Find(vInd) = Undefined Then
							vArrForms.Add(vInd);	
						EndIf;
					EndDo;
				EndIf;	
				If vArrForms.Count() = 0 Then
					vArrForms.Add(vDefaultForm);
				EndIf; 
			EndIf;
		EndIf; 
	EndIf; 
	// Set new settings
	vHomePageSettings.SetForms(vForms); 
	// Save user settings
	SystemSettingsStorage.Save("Common/HomePageSettings", "", vHomePageSettings);   
	Return vIsFirstRun;	
EndFunction // SetDesktop

// -------------------------------------------------------------------------
Function GetActualFormDesktop(pMobileClientMode = False)
	vFrm = "";
	If IsInRole("Administrator") Or IsInRole("SubsystemDesktopAccess") Then
		vFrm = "CommonForm.tcDesktop";    
	ElsIf IsInRole("SubsystemFrontOffice") Then
		If Not pMobileClientMode Then
			vFrm = "Document.Accommodation.Form.tcAccommodationListForm";
		Else
			vFrm = "Document.Accommodation.Form.mcAccommodationListForm";	
		EndIf;
	ElsIf IsInRole("SubsystemResources") Then	 
		vFrm = "Catalog.Resources.Form.tcResourcesCalendar";
	ElsIf IsInRole("SubsystemInvoices") Then	 
		vFrm = "DocumentJournal.CustomerAccountsJournal.Form.tcListForm";	 
	ElsIf IsInRole("SubsystemHousekeeping") Then
		If Not pMobileClientMode Then
			vFrm = "Catalog.Rooms.Form.tcHousekeepingForm";
		Else
			vFrm = "Catalog.Rooms.Form.mcHousekeepingForm";	
		EndIf;
	ElsIf IsInRole("SubsystemOrders") Then	 
		vFrm = "Document.Order.Form.tcListForm";
	ElsIf IsInRole("SubsystemTasks") Then	 
		vFrm = "DataProcessor.Messages.Form.tcForm";
	ElsIf IsInRole("Agent") Then	 	
		If Not pMobileClientMode Then
			vFrm = "Document.Reservation.Form.tcReservationListForm";
		Else
			vFrm = "Document.Reservation.Form.mcReservationListForm";	
		EndIf;
	ElsIf IsInRole("SubsystemCRM") Then	 
		vFrm = "Document.SMSDelivery.Form.tcListForm";
	ElsIf IsInRole("SelfService") Then	 
		vFrm = "CommonForm.tcSelfService";
	EndIf; 
	Return vFrm;
EndFunction //  GetActualFormDesktop

// -------------------------------------------------------------------------
Function GetRoomRoomType(pRoom, pDate) Export
	vRoomType = Undefined;
	If ValueIsFilled(pRoom) And ValueIsFilled(pDate) Then
		vRoomObj = pRoom.GetObject();
		vRoomAttrs = vRoomObj.pmGetRoomAttributes(pDate);
		If vRoomAttrs <> Undefined And vRoomAttrs.Count() > 0 Then
			vRoomAttrsRow = vRoomAttrs.Get(0);
			If ValueIsFilled(vRoomAttrsRow.RoomType) Then
				vRoomType = vRoomAttrsRow.RoomType;
			EndIf;
		EndIf;
	EndIf;
	Return vRoomType;
EndFunction // GetRoomRoomType

// -------------------------------------------------------------------------
Procedure cmInitHotel(pObject) Export
	If Not ValueIsFilled(pObject.Ref) And Not ValueIsFilled(pObject.Hotel) Then
		If Not IsInRole("RightsToChooseHotel") Then
			pObject.Hotel = SessionParameters.CurrentHotel;
		EndIf;
	EndIf;
EndProcedure // cmInitHotel

// -------------------------------------------------------------------------
Procedure SetTimeZone(Val vCurComputerRef) Export
	vTimeZone = "";
	If ValueIsFilled(vCurComputerRef) And Not IsBlankString(vCurComputerRef.WorkstationTimeZone) Then
		vTimeZone = TrimAll(vCurComputerRef.WorkstationTimeZone);
	EndIf;
	If IsBlankString(vTimeZone) Then
		vCurHotelRef = SessionParameters.CurrentHotel;
		If ValueIsFilled(vCurHotelRef) And Not IsBlankString(vCurHotelRef.HotelTimeZone) Then
			vTimeZone = TrimAll(vCurHotelRef.HotelTimeZone);
		EndIf;
	EndIf;
	If IsBlankString(vTimeZone) Then
		vTimeZone = TrimAll(Constants.InfoBaseTimeZone.Get());
	EndIf;
	If Not IsBlankString(vTimeZone) Then
		SetSessionTimeZone(vTimeZone);
	EndIf;
EndProcedure // SetTimeZone

// -------------------------------------------------------------------------
Function GetStringUUIDByRef(pRef) Export
	Return String(pRef.UUID());
EndFunction // GetStringUUIDByRef

// -------------------------------------------------------------------------
Function GetExternalSystemInteractionsByInteractionType(pIntegrationType, pHotel) Export
	Return Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(pIntegrationType, pHotel);
EndFunction // GetExternalSystemInteractionsByInteractionType	

// -------------------------------------------------------------------------
Function GetNumberOfBedsForReservation(pRoomType, pAccommodationType) Export
	vNumberOfBeds = 0;
	If ValueIsFilled(pAccommodationType) Then
		If pAccommodationType.Type = Enums.AccomodationTypes.Room Then
			vRoomTypeAttrs = pRoomType.NumberOfBedsPerRoom;
		ElsIf pAccommodationType.Type = Enums.AccomodationTypes.Beds Then
			vNumberOfBeds = pAccommodationType.NumberOfBeds;
		EndIf;
	EndIf;
	Return vNumberOfBeds;
EndFunction // GetNumberOfBedsForReservation

// -------------------------------------------------------------------------
Function CheckRoomForRoomType(pRoomType, pRoom, pDate) Export
	vRoom = pRoom;
	If ValueIsFilled(vRoom) And ValueIsFilled(pDate) Then
		vRoomAttrs = vRoom.GetObject().pmGetRoomAttributes(pDate);
		For Each vRoomAttrsRow In vRoomAttrs Do
			If vRoomAttrsRow.RoomType <> pRoomType Then
				vRoom = Catalogs.Rooms.EmptyRef();
			Endif;
			Break;
		EndDo;
	EndIf;
	Return vRoom;
EndFunction // CheckRoomForRoomType
 
// -------------------------------------------------------------------------
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False) Export
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -------------------------------------------------------------------------
Function GetExternalProcessingValidName(Val pStr) Export
	Return cmGetValidName(pStr); 	
EndFunction // GetExternalProcessingValidName

// -------------------------------------------------------------------------
//  Gets hex string from color
//
// Parameters:
//  pColor	 - Color - Clor to convert
// 
// Returns:
//  String - Hex value color
//
Function ColorToHex(Val pColor) Export
	vHex = "";
	If TypeOf(pColor) <> Type("Color") Then
		Return vHex;
	EndIf;	
	If pColor.Type = ColorType.Absolute Then     
		vRed = tcCommonFunctionOnClientServer.DecToAnyNumberSystem(pColor.R); 
		vGreen = tcCommonFunctionOnClientServer.DecToAnyNumberSystem(pColor.G); 
		vBlue = tcCommonFunctionOnClientServer.DecToAnyNumberSystem(pColor.B);
		
		vHex = tcCommonFunctionOnClientServer.ComplementString(vRed, 2)
			+ tcCommonFunctionOnClientServer.ComplementString(vGreen, 2)
			+ tcCommonFunctionOnClientServer.ComplementString(vBlue, 2);
	ElsIf pColor.Type = ColorType.WebColor Then
		vColor = CachedCommonFunctions.WebColorCatalog().Get(pColor);               
		If vColor <> Undefined Then
			Return ColorToHex(vColor); 
		Else
			vHex = "000000";
		EndIf;                              
	ElsIf pColor.Type = ColorType.WindowsColor Or pColor.Type = ColorType.StyleItem Then
		vHex = "000000";
		vMemoryStream = New MemoryStream();
		vTab = New SpreadsheetDocument;
		vTab.Area(1, 1, 1, 1).BackColor = pColor;
		vTab.Write(vMemoryStream, SpreadsheetDocumentFileType.ODS);
		
		vMemoryStream.Seek(0, PositionInStream.Begin);
		
		vTab.Read(vMemoryStream,, SpreadsheetDocumentFileType.ODS);
		vBackgroundColor = vTab.Area(1, 1, 1, 1).BackColor;
		
		vRed = tcCommonFunctionOnClientServer.DecToAnyNumberSystem(vBackgroundColor.R); 
		vGreen = tcCommonFunctionOnClientServer.DecToAnyNumberSystem(vBackgroundColor.G); 
		vBlue = tcCommonFunctionOnClientServer.DecToAnyNumberSystem(vBackgroundColor.B);
		
		vHex = tcCommonFunctionOnClientServer.ComplementString(vRed, 2)
			+ tcCommonFunctionOnClientServer.ComplementString(vGreen, 2)
			+ tcCommonFunctionOnClientServer.ComplementString(vBlue, 2);
			
			vMemoryStream.Close();
	Else
		vHex = "000000";
	EndIf;
	
	Return "#" + vHex;
EndFunction // ColorToHex()

// -------------------------------------------------------------------------
// Get the color of a string in HEX form.
//
// Parameters:
//  pHexString	 - String	 - Type #RRGGBB or #RGB - where R, RR - Red, G, GG - Green, B, BB - Blue,
// 
// Returns:
//  Color - Color.
//
Function HexToColor(Val pHexString) Export  
	If IsBlankString(pHexString) Then                               
		// Return empty color   
		vColor = tcCommonFunctionOnClientServer.ColorConstructor();
		Return vColor;
	EndIf;
	
	vShortColorString 	= 4;
	vFullColorString 	= 7;
	
    vColorString = Upper(pHexString);
    vColorIsSet = True;
	
	vRed	= -1;
	vGreen	= -1;
	vBlue	= -1;
	
	Try
		If StrLen(vColorString) = vShortColorString Then
			// Color type #RGB -> #RRGGBB (#F18 -> #FF1188).
			vColorString = Left(vColorString, 1)
				+ Mid(vColorString, 2, 1) + Mid(vColorString, 2, 1)
				+ Mid(vColorString, 3, 1) + Mid(vColorString, 3, 1)
				+ Mid(vColorString, 4, 1) + Mid(vColorString, 4, 1);
		EndIf;
		
		If StrLen(vColorString) = vFullColorString Then
			// Color type #RRGGBB (#FF1188 - FF - red, 11 - green, 88 - blue).
			vRed 	= tcCommonFunctionOnClientServer.HexToDecNumberSystem(Mid(vColorString, 2, 2));
			vGreen 	= tcCommonFunctionOnClientServer.HexToDecNumberSystem(Mid(vColorString, 4, 2));
			vBlue 	= tcCommonFunctionOnClientServer.HexToDecNumberSystem(Mid(vColorString, 6, 2));
		Else
			vColorIsSet	= False;
		EndIf;
	Except
		vColorIsSet = False;
	EndTry;
	
	If Not vColorIsSet Then
		vColor = tcCommonFunctionOnClientServer.ColorConstructor();
		Return vColor;
	EndIf;
	
	vColor = tcCommonFunctionOnClientServer.ColorConstructor(vRed, vGreen, vBlue);
	Return vColor;
EndFunction

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  ValueList - ResortFeeExemptionReasonsList
//
Function GetResortFeeExemptionReasonsList(pHotel = Undefined) Export 
	Return Catalogs.ResortFeeExemptionReasons.GetResortFeeExemptionReasonsList(pHotel);
EndFunction // GetResortFeeExemptionReasonsList()()

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  ValueList - TouristTaxExemptionReasonsList
//
Function GetTouristTaxExemptionReasonsList(pHotel = Undefined) Export 
	Return Catalogs.ResortFeeExemptionReasons.GetTouristTaxExemptionReasonsList(pHotel);
EndFunction // GetTouristTaxExemptionReasonsList

// -----------------------------------------------------------------------------
Function GetCurrentSessionDate() Export
	Return CurrentSessionDate();
EndFunction // GetCurrentSessionDate

// -----------------------------------------------------------------------------
Function IsHotelAllowedForEmployee(pHotel) Export
	vIsAllowed = False;
	If IsInRole("RightsToChooseHotel") Then
		vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
		If ValueIsFilled(vPermissionGroup) Then
			If vPermissionGroup.HotelAllowed.Count() > 0 Then
				If vPermissionGroup.HotelAllowed.Find(pHotel, "Hotel") <> Undefined Then
					vIsAllowed = True;
				EndIf;
			Else
				vIsAllowed = True;
			EndIf;
		EndIf;
	EndIf;
	Return vIsAllowed;
EndFunction // IsHotelAllowedForEmployee

// -----------------------------------------------------------------------------
// Description: Parses address string into the structure of address elements like
//              country, region, district, city, street, house, flat and so on
// Parameters: Address string
// Return value: Address structure
// -----------------------------------------------------------------------------
Function ParseAddress(pAddress) Export
	Return cmParseAddress(pAddress);
EndFunction // ParseAddress

// -----------------------------------------------------------------------------
// Description: Builds address string from the list of address elements like
//              country, region, district, city, street, house, flat and so on
// Parameters: Address elements
// Return value: Address string
// -----------------------------------------------------------------------------
Function BuildAddress(pCountry = "", pPostCode = "", pRegion = "", pArea = "", pCity = "", pStreet = "", pHouse = "", pFlat = "") Export
	Return cmBuildAddress(pCountry, pPostCode, pRegion, pArea, pCity, pStreet, pHouse, pFlat);
EndFunction // BuildAddress

// --------------------------------------------------------------------------------
//
// Parameters:
//  pRef			 - Arbitrary - Ref
//  pAttributeName	 - String	 - Attribute name
//  pIndex			 - Arbitrary - Extra params
// 
// Returns:
//  String - Result
//
Function cmGetURL(pRef, pAttributeName = "", pIndex = Undefined) Export
	Return GetURL(pRef, pAttributeName, pIndex);
EndFunction // GetURL

// --------------------------------------------------------------------------------
//
// Parameters:
//  pFileName	 - String	 - File name
// 
// Returns:
//  String - Result
//
Function GetValidFileName(pFileName) Export
	Return cmGetValidFileName(pFileName);
EndFunction // GetValidFileName

// --------------------------------------------------------------------------------
// Procedure - Run user exit algoritm
//
// Parameters:
//  pName	 - String - User exit description
//
Procedure RunUserExitAlgorithm(pName) Export
	vUserExitProc = Catalogs.ExternalDataProcessors[pName];
	If ValueIsFilled(vUserExitProc) Then
		If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			If Not IsBlankString(vUserExitProc.Algorithm) Then
				SetSafeMode(True);
				Execute(TrimAll(vUserExitProc.Algorithm));
				SetSafeMode(False);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
Function cmStrLikeByRegularExpression(pStr, pRegular, pIgnoreRegister = False, pMultiLineSearch = False) Export
	vResult = True;
	Execute("vResult = StrLikeByRegularExpression(pStr, pRegular, pIgnoreRegister, pMultiLineSearch);");
	Return vResult;
EndFunction // StrLikeByRegularExpression

#EndRegion
