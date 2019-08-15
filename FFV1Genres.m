RCS_ID("$Id: FFV1Genres.m 234 2004-07-31 13:55:31Z ravemax $")

#include "FFV1Genres.h"

#define NUM_V1_GENRES   80

static NSString* V1Genres[NUM_V1_GENRES] = {
	@"Blues",
	@"Classic Rock",
	@"Country",
	@"Dance",
	@"Disco",
	@"Funk",
	@"Grunge",
	@"Hip-Hop",
	@"Jazz",
	@"Metal",
	@"New Age",
	@"Oldies",
	@"Other",
	@"Pop",
	@"R&B",
	@"Rap",
	@"Reggae",
	@"Rock",
	@"Techno",
	@"Industrial",
	@"Alternative",
	@"Ska",
	@"Death Metal",
	@"Pranks",
	@"Soundtrack",
	@"Euro-Techno",
	@"Ambient",
	@"Trip-Hop",
	@"Vocal",
	@"Jazz+Funk",
	@"Fusion",
	@"Trance",
	@"Classical",
	@"Instrumental",
	@"Acid",
	@"House",
	@"Game",
	@"Sound Clip",
	@"Gospel",
	@"Noise",
	@"AlternRock",
	@"Bass",
	@"Soul",
	@"Punk",
	@"Space",
	@"Meditative",
	@"Instrumental Pop",
	@"Instrumental Rock",
	@"Ethnic",
	@"Gothic",
	@"Darkwave",
	@"Techno-Industrial",
	@"Electronic",
	@"Pop-Folk",
	@"Eurodance",
	@"Dream",
	@"Southern Rock",
	@"Comedy",
	@"Cult",
	@"Gangsta",
	@"Top 40",
	@"Christian Rap",
	@"Pop/Funk",
	@"Jungle",
	@"Native American",
	@"Cabaret",
	@"New Wave",
	@"Psychadelic",
	@"Rave",
	@"Showtunes",
	@"Trailer",
	@"Lo-Fi",
	@"Tribal",
	@"Acid Punk",
	@"Acid Jazz",
	@"Polka",
	@"Retro",
	@"Musical",
	@"Rock & Roll",
	@"Hard Rock"
};

NSString* v1GenreToString(int index) {
	if ((index < 0) || (index >= NUM_V1_GENRES))
		return NULL;
	return V1Genres[index];
}

int v1GenreFromString(NSString* str) {
	int i;
	for (i = 0; i < NUM_V1_GENRES; i++)
		if ([str isEqualToString:V1Genres[i]])
			return i;
	
	return GENRE_CUSTOM;
}

NSArray* v1Genres() {
	return [NSArray arrayWithObjects:V1Genres count:NUM_V1_GENRES];
}
