// $Id: FFV1Genres.h 234 2004-07-31 13:55:31Z ravemax $

#define GENRE_CUSTOM (-1)

NSString* v1GenreToString(int index); // NULL if invalid index
int v1GenreFromString(NSString* str); // GENRE_CUSTOM if unknown
NSArray* v1Genres();
