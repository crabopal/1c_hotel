
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pStr - String	 - String to be remove
// 
// Returns:
//  String - Removed string
//
Function cmRemoveUTFControlSymbols(pStr) Export
	vStr = "";
	vStrLen = StrLen(pStr);
	i = 1;
	While i <= vStrLen Do
		vChar = Mid(pStr, i, 1);
		vCharCode = CharCode(vChar);
		If vChar = "<" Or vChar = ">" Or vChar = "/" Or vChar = "&" Then
			vChar = " ";
		ElsIf vCharCode = 133 Then
			vChar = " ";
		ElsIf vCharCode = 8226 Then
			vChar = "";
		ElsIf vCharCode < 32 Or 
		      vCharCode >= 65536 And vCharCode <= 131069 Or 
		      vCharCode >= 131072 And vCharCode <= 196605 Or 
		      vCharCode >= 196608 And vCharCode <= 262141 Or 
		      vCharCode >= 262144 And vCharCode <= 327677 Or 
		      vCharCode >= 327680 And vCharCode <= 393213 Or 
		      vCharCode >= 393216 And vCharCode <= 458749 Or 
		      vCharCode >= 458752 And vCharCode <= 524285 Or 
		      vCharCode >= 524288 And vCharCode <= 589821 Or 
		      vCharCode >= 589824 And vCharCode <= 655357 Or 
		      vCharCode >= 655360 And vCharCode <= 720893 Or 
		      vCharCode >= 720896 And vCharCode <= 786429 Or 
		      vCharCode >= 786432 And vCharCode <= 851965 Or 
		      vCharCode >= 851968 And vCharCode <= 917501 Or 
		      vCharCode >= 917504 And vCharCode <= 983037 Or 
		      vCharCode >= 983040 And vCharCode <= 1048573 Or 
		      vCharCode >= 1048576 And vCharCode <= 1114109 Then
			// Those are UTF control symbols
			vChar = "";
		ElsIf vCharCode >= 160 And vCharCode <= 55295 Or 
		      vCharCode >= 57344 And vCharCode <= 64975 Or
			  vCharCode >= 65008 And vCharCode <= 65533 Then
			// Those are normal letters in different languages
			If CachedCommonFunctions.cmForceAPIExchangeInASCII() Then
				// Only ASCII is supported
				vChar = "?";
			EndIf;
		ElsIf vCharCode >= 32 And vCharCode <= 126 Then
			// Those are ASCII chars
		Else
			// Those are not defined
			vChar = "";
		EndIf;
		vStr = vStr + vChar;
		i = i + 1;
	EndDo;
	Return vStr;
EndFunction // RemoveUTFControlSymbols

// -----------------------------------------------------------------------------
//
// Parameters:
//  pStr - String	 - String to be remove
// 
// Returns:
//  String - Removed string
//
Function cmReplaceControlCharacters(Val pStr) Export 
    pStr = StrReplace(pStr, Char(0), "[NUL]");
	pStr = StrReplace(pStr, Char(1), "[SOH]");
	pStr = StrReplace(pStr, Char(2), "[STX]");
	pStr = StrReplace(pStr, Char(3), "[ETX]");
	pStr = StrReplace(pStr, Char(4), "[EOT]");
	pStr = StrReplace(pStr, Char(5), "[ENQ]");
	pStr = StrReplace(pStr, Char(6), "[ACK]");
	pStr = StrReplace(pStr, Char(7), "[BEL]");
	pStr = StrReplace(pStr, Char(8), "[BS]");
	pStr = StrReplace(pStr, Char(9), "[TAB]");
	pStr = StrReplace(pStr, Char(10), "[LF]");
	pStr = StrReplace(pStr, Char(11), "[VT]");
	pStr = StrReplace(pStr, Char(12), "[FF]");
	pStr = StrReplace(pStr, Char(13), "[CR]");
	pStr = StrReplace(pStr, Char(14), "[SO]");
	pStr = StrReplace(pStr, Char(15), "[SI]");
	pStr = StrReplace(pStr, Char(16), "[DLE]");
	pStr = StrReplace(pStr, Char(17), "[DC1]");
	pStr = StrReplace(pStr, Char(18), "[DC2]");
	pStr = StrReplace(pStr, Char(19), "[DC3]");
	pStr = StrReplace(pStr, Char(20), "[DC4]");
	pStr = StrReplace(pStr, Char(21), "[NAK]");
	pStr = StrReplace(pStr, Char(22), "[SYN]");
	pStr = StrReplace(pStr, Char(23), "[ETB]");
	pStr = StrReplace(pStr, Char(24), "[CAN]");
	pStr = StrReplace(pStr, Char(25), "[EM]");
	pStr = StrReplace(pStr, Char(26), "[SUB]");
	pStr = StrReplace(pStr, Char(27), "[ESC]");
	pStr = StrReplace(pStr, Char(28), "[FS]");
	pStr = StrReplace(pStr, Char(29), "[GS]");
	pStr = StrReplace(pStr, Char(30), "[RS]");
	pStr = StrReplace(pStr, Char(31), "[US]");
	pStr = StrReplace(pStr, Char(127), "[Delete]");
	Return pStr;
EndFunction // ReplaceControlCharacters

// -----------------------------------------------------------------------------
// Description: Checks whether given string is number or not
// Parameters: String with number presentation to be checked
// Return value: True if string could be converted to the number, false if not
// -----------------------------------------------------------------------------
Function cmIsNumber(pStr) Export
	If TypeOf(pStr) = Type("Number") Then
		Return True;
	EndIf;
	
	vStr = TrimAll(pStr);
	vStrLen = StrLen(vStr);
	If vStrLen = 0 Then
		Return False;
	EndIf;
	
	vIsNumber = True;
	i = 0;
	While i < vStrLen Do
		i = i + 1;
		vChar = Mid(vStr, i, 1);
		
		If StrFind("0123456789.,", vChar) > 0 Then
			Continue;
		EndIf;
		
		If vChar <> "-" Then
			vIsNumber = False;
			Break;
		EndIf;
		
		If i > 1 Then
			vIsNumber = False;
			Break;
		EndIf;
	EndDo;
	
	Return vIsNumber;
EndFunction // cmIsNumber

// -----------------------------------------------------------------------------
//
// Parameters:
//  pAddress - String	 - String to be checked
// 
// Returns:
//  Boolean - True if input string is an IP address with format 999.999.999.999
//
Function cmIsIPAddress(pAddress) Export
	vResult = False;
	If IsBlankString(pAddress) Then
		Return vResult;
	EndIf;
	vParts = StrSplit(TrimAll(pAddress), ".", True);
	If vParts.Count() = 4 Then
		vResult = True;
		For i = 0 To 3 Do
			vPart = vParts[i];
			If IsBlankString(vPart) Then
				vResult = False;
				Break;
			EndIf;
			vPartLen = StrLen(vPart);
			If vPartLen > 3 Then
				vResult = False;
				Break;
			EndIf;
			If Not cmIsNumber(vPart) Then
				vResult = False;
				Break;
			EndIf;
			If vPartLen > 1 Then
				If Left(vPart, 1) = "0" Then
					vResult = False;
					Break;
				EndIf;
			EndIf;
			vPartNumber = Number(vPart);
			If vPartNumber < 0 Or vPartNumber > 255 Then
				vResult = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	Return vResult;
EndFunction // cmIsIPAddress

#EndRegion