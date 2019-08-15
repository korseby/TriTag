/*
 *	No idea why the authors didn't export this important functions
 *	patrick@feedface.com
 */

#include <id3.h>
#include <id3/field.h>
#include <id3/tag.h>

#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */

#define ID3_CATCH(code) try { code; } catch (...) { }

	ID3_C_EXPORT void CCONV
	ID3Field_SetEncoding(ID3Field *field, ID3_TextEnc enc)
	{
		if (field) {
			ID3_CATCH(reinterpret_cast<ID3_Field *>(field)->SetEncoding(enc));
		}
	}
	
	ID3_C_EXPORT size_t CCONV
	ID3Tag_GetPrependedBytes(ID3Tag *tag)
	{
		size_t s = 0;
		if (tag) {
			ID3_CATCH(s = reinterpret_cast<ID3_Tag *>(tag)->GetPrependedBytes());
		}
		return s;
	}
	
	ID3_C_EXPORT size_t CCONV
	ID3Tag_GetAppendedBytes(ID3Tag *tag)
	{
		size_t s = 0;
		if (tag) {
			ID3_CATCH(s = reinterpret_cast<ID3_Tag *>(tag)->GetAppendedBytes());
		}
		return s;
	}
	
	ID3_C_EXPORT size_t CCONV
	ID3Tag_GetFileSize(ID3Tag *tag)
	{
		size_t s = 0;
		if (tag) {
			ID3_CATCH(s = reinterpret_cast<ID3_Tag *>(tag)->GetFileSize());
		}
		return s;
	}

	ID3_C_EXPORT size_t CCONV
	ID3Tag_GetDataSize(ID3Tag *tag)
	{
		size_t s = ID3Tag_GetFileSize(tag) - ID3Tag_GetPrependedBytes(tag)
			- ID3Tag_GetAppendedBytes(tag);
			
		return (s < 0) ? 0 : s;
	}

#ifdef __cplusplus
}
#endif /* __cplusplus */
