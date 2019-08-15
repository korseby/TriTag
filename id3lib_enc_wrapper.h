/*
 *  id3lib_enc_wrapper.h
 *  TriTag
 *
 *  Created by Patrick Gleichmann on Wed Feb 11 2004.
 *  Copyright (c) 2004 FEEDFACE.com. All rights reserved.
 *
 */

#include <id3.h>

ID3_C_EXPORT void CCONV ID3Field_SetEncoding(ID3Field *field, ID3_TextEnc enc);
ID3_C_EXPORT size_t CCONV ID3Tag_GetPrependedBytes(ID3Tag *tag);
ID3_C_EXPORT size_t CCONV ID3Tag_GetAppendedBytes(ID3Tag *tag);
ID3_C_EXPORT size_t CCONV ID3Tag_GetFileSize(ID3Tag *tag);
ID3_C_EXPORT size_t CCONV ID3Tag_GetDataSize(ID3Tag *tag);

