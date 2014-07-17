#ifdef VIDEOMAN
#ifndef THEVIDEO_H
#define THEVIDEO_H

#include <Wt/Dbo/Dbo>
#include <Wt/Dbo/Types>
#include <Wt/Dbo/WtSqlTraits>
/* ****************************************************************************
 * pageLocation
 */
enum pageLocation
{
    TOP,
    BOTTOM,
    LEFT,
    RIGHT
};
/* ****************************************************************************
 * TheVideo
 * categories:    coma delimited array of Categories for Categories Combo box, each in its own Combo Box
 *                  Make|Model|Year
 * name:             Name for Combo box
 * title:            Title for Video Player
 * path:             Full Path minus video extension and quality
 * m4v:              is video m4v extension
 * ogv:              is video ogv extension
 * isUtube:          is Yew Tube video
 * poster:           Full path to image
 * width:            Width of Video in pixils
 * height:           Height of Video in pixils
 * autoplay:         is autoplay
 * pagetop:          page Location: iframe = fully qualified URL path to html file, xml = message ID
 * pagetopwidth:     page Width: 40px, 100%
 * pagetopheight:    page Height: 40px, 100%
 * pagebottom:       page Location: iframe = fully qualified URL path to html file, xml = message ID
 * pagebottomwidth:  page Width: 40px, 100%
 * pagebottomheight: page Height: 40px, 100%
 */
class TheVideo : public Wt::Dbo::Dbo<TheVideo>
{
    public:
        TheVideo();
        //
        std::string schema;             // schema for Combo box
        std::string schema_names;       // schema names for Combo box
        std::string categories;         // categories for Combo box
        std::string name;               // Name for Combo box
        std::string title;              // Title for Video Player
        std::string path;               // Full Path minus video extension and quality
        std::string language;           // language: en, cn, ru...
        int ism4v;                      // is video m4v extension
        int isogv;                      // is video ogv extension
        int isutube;                    // is U Tube video
        int isautoplay;                 // is autoplay
        std::string poster;             // Full path to image
        std::string width;              // Width of Video
        std::string height;             // Height of Video
        std::string sizes;              // coma delimited array of sizes: 1080,720 | Create check box
        std::string quality;            // coma delimited array of quality: hd,lq | Create check box
        Wt::WString pagetop;            // page Location: iframe = fully qualified URL path to html file, xml = message ID
        std::string pagetopwidth;       // page Width: 40px, 100%
        std::string pagetopheight;      // page Height: 40px, 100%
        Wt::WString pagebottom;         // page HTML in 1 line, no returns, no quotes
        std::string pagebottomlink;     // page HTML Link
        std::string pagebottomwidth;    // page Width: 40px, 100%
        std::string pagebottomheight;   // page Height: 40px, 100%
        //
        template<class Action>
        void persist(Action &a)
        {
            Wt::Dbo::field(a, schema,           "schema");
            Wt::Dbo::field(a, schema_names,     "schema_names");
            Wt::Dbo::field(a, categories,       "categories");
            Wt::Dbo::field(a, name,             "name");
            Wt::Dbo::field(a, title,            "title");
            Wt::Dbo::field(a, path,             "path");
            Wt::Dbo::field(a, language,         "language");
            Wt::Dbo::field(a, ism4v,            "ism4v");
            Wt::Dbo::field(a, isogv,            "isogv");
            Wt::Dbo::field(a, isutube,          "isutube");
            Wt::Dbo::field(a, isautoplay,       "isautoplay");
            Wt::Dbo::field(a, poster,           "poster");
            Wt::Dbo::field(a, width,            "width");
            Wt::Dbo::field(a, height,           "height");
            Wt::Dbo::field(a, sizes,            "sizes");
            Wt::Dbo::field(a, quality,          "quality");
            Wt::Dbo::field(a, pagetop,          "pagetop");
            Wt::Dbo::field(a, pagetopwidth,     "pagetopwidth");
            Wt::Dbo::field(a, pagetopheight,    "pagetopheight");
            Wt::Dbo::field(a, pagebottom,       "pagebottom");
            Wt::Dbo::field(a, pagebottomlink,   "pagebottomlink");
            Wt::Dbo::field(a, pagebottomwidth,  "pagebottomwidth");
            Wt::Dbo::field(a, pagebottomheight, "pagebottomheight");
        }
};
#endif // THEVIDEO_H
#endif // VIDEOMAN
// --- End Of File ------------------------------------------------------------
