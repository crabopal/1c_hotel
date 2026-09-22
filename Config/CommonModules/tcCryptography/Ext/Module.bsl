
#Region Public

// ----------------------------------------------------------------------------
//
// Parameters:
//  pSecretKey	 - String, BinaryData	 - The key to use in the hash algorithm
//  pMessage	 - String, BinaryData	 - The input to compute the hash code
//  pHashFunc	 - HashFunction			 - The name of the hash algorithm to use for hashing
// 
// Returns:
//  BinaryData, Undefined - The computed hash code or Undefined
//
Function HMAC(Val pSecretKey, Val pMessage, Val pHashFunc) Export	
	vResult = Undefined;
	
	If CheckHashFuncIsSupported(pHashFunc) Then		
		vBlockSize = 64;
		
		pSecretKey = GetBDFromString(pSecretKey);
		pMessage = GetBDFromString(pMessage);
		
		If pSecretKey.Size() > vBlockSize Then
			pSecretKey = Hash(pSecretKey, pHashFunc);
		EndIf;
		 
		vSecretKeyBufferBlock = New BinaryDataBuffer(vBlockSize);
		vSecretKeyBufferBlock.WriteBitwiseOr(0, GetBinaryDataBufferFromBinaryData(pSecretKey));
									
		vIBinaryDataBuffer = GetFillBinaryDataBuffer(vBlockSize, NumberFromHexString("0x36"));
		vIBinaryData = GetHashFromValueAndKey(vSecretKeyBufferBlock, GetBinaryDataBufferFromBinaryData(pMessage), vIBinaryDataBuffer, pHashFunc);  
		
		vOBinaryDataBuffer = GetFillBinaryDataBuffer(vBlockSize, NumberFromHexString("0x5C"));
		vResult = GetHashFromValueAndKey(vSecretKeyBufferBlock, GetBinaryDataBufferFromBinaryData(vIBinaryData), vOBinaryDataBuffer, pHashFunc);				 
	EndIf;
	
	Return vResult;
EndFunction // HMAC

// ----------------------------------------------------------------------------
//
// Parameters:
//  pValue		 - BinaryData, String	 - The input to compute the hash code
//  pHashFunc	 - HashFunction			 - The name of the hash algorithm to use for hashing
// 
// Returns:
//  Number, BinaryData - The hash sum
//
Function Hash(Val pValue, Val pHashFunc) Export
	vDataHashing = New DataHashing(pHashFunc);
	vDataHashing.Append(pValue);
	Return vDataHashing.HashSum;
EndFunction // Hash

#EndRegion

#Region Private

// ----------------------------------------------------------------------------
Function CheckHashFuncIsSupported(Val pHashFunc)
	If pHashFunc = HashFunction.MD5 Or pHashFunc = HashFunction.SHA1 Or pHashFunc = HashFunction.SHA256 Then
		Return True;
	EndIf;
	Return False;	
EndFunction // CheckHashFuncIsSupported

// ----------------------------------------------------------------------------
Function GetBDFromString(Val pValue)	
	If TypeOf(pValue) = Type("String") Then
		Return GetBinaryDataFromString(pValue);		
	EndIf;
	Return pValue;
EndFunction // GetBinaryDataFromString

// ----------------------------------------------------------------------------
Function GetFillBinaryDataBuffer(Val pBlockSize, Val pByte)
	vBinaryDataBuffer = New BinaryDataBuffer(pBlockSize, ByteOrder.BigEndian);
	For vNumber = 0 To vBinaryDataBuffer.Size - 1 Do
		vBinaryDataBuffer.Set(vNumber, pByte); 	
	EndDo;
	Return vBinaryDataBuffer;
EndFunction // GetFillBinaryDataBuffer

// ----------------------------------------------------------------------------
Function GetHashFromValueAndKey(Val pSecretKeyBuffer, Val pMessageBuffer, Val pByteBuffers, Val pHashFunc)
	pByteBuffers.WriteBitwiseXor(0, pSecretKeyBuffer);	
	Return Hash(GetBinaryDataFromBinaryDataBuffer(pByteBuffers.Concat(pMessageBuffer)), pHashFunc);
EndFunction // GetHashFromMessageAndKey

#EndRegion
