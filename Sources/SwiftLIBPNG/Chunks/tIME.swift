//
//  tIME.swift
//  
//
//  Created by Carlyn Maw on 4/23/23.
//


//Decided to NOT implement tIME at this junction as am generating pngs
//from scratch not modifying them by hand or editing the pixel data
//with LIBPNG beyond basic compression.



//MARK: from png.h
/* png_time is a way to hold the time in an machine independent way.
 * Two conversions are provided, both from time_t and struct tm.  There
 * is no portable way to convert to either of these structures, as far
 * as I know.  If you know of a portable way, send it to me.  As a side
 * note - PNG has always been Year 2000 compliant!
 */
//typedef struct png_time_struct
//{
//   png_uint_16 year; /* full year, as in, 1995 */
//   png_byte month;   /* month of year, 1 - 12 */
//   png_byte day;     /* day of month, 1 - 31 */
//   png_byte hour;    /* hour of day, 0 - 23 */
//   png_byte minute;  /* minute of hour, 0 - 59 */
//   png_byte second;  /* second of minute, 0 - 60 (for leap seconds) */
//} png_time;
//typedef png_time * png_timep;
//typedef const png_time * png_const_timep;
//typedef png_time * * png_timepp;
//#ifdef PNG_CONVERT_tIME_SUPPORTED
///* Convert from a struct tm to png_time */
//PNG_EXPORT(24, void, png_convert_from_struct_tm, (png_timep ptime,
//    const struct tm * ttime));
//
///* Convert from time_t to png_time.  Uses gmtime() */
//PNG_EXPORT(25, void, png_convert_from_time_t, (png_timep ptime, time_t ttime));
//#endif /* CONVERT_tIME */

//MARK: From docs
//http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html
//http://www.libpng.org/pub/png/spec/iso/index-object.html#11tIME
//The tIME chunk gives the time of the last image modification (not the time of initial image creation). It contains:
//
//   Year:   2 bytes (complete; for example, 1995, not 95)
//   Month:  1 byte (1-12)
//   Day:    1 byte (1-31)
//   Hour:   1 byte (0-23)
//   Minute: 1 byte (0-59)
//   Second: 1 byte (0-60)    (yes, 60, for leap seconds; not 61,
//                             a common error)
//Universal Time (UTC, also called GMT) should be specified rather than local time.
//
//The tIME chunk is intended for use as an automatically-applied time stamp that is updated whenever the image data is changed. It is recommended that tIME not be changed by PNG editors that do not change the image data. The Creation Time text keyword can be used for a user-supplied time (see the text chunk specification).
