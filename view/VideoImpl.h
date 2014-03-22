#ifndef VIDEO_H
#define VIDEO_H
#include <Wt/WApplication>
#include <Wt/WCompositeWidget>
#include <Wt/WComboBox>
#include <Wt/Dbo/Dbo>
//#include "model/BlogSession.h"
class BlogSession;
/* ****************************************************************************
 * myVideo
 */
struct myVideo
{
    std::string name;    // Name for Combo box
    std::string title;   // Title for Video Player
    std::string path;    // Full Path minus video extension and quality
    bool m4v;            // is video m4v extension
    bool ogv;            // is video ogv extension
    bool isUtube;        // is U Tube video
    std::string poster;  // Full path to image
    int width;           // Width of Video
    int height;          // Height of Video
    bool autoplay;       // is autoplay
    std::string sizes;   // coma delimited array of sizes: 1080,720
    std::string quality; // coma delimited array of quality: hd,lq
    std::string pages;   // coma delimited array of html content pages: page1,page2
};
/* ****************************************************************************
 * theVideo
 */
class theVideo
{
    public:
        std::string name;    // Name for Combo box
        std::string title;   // Title for Video Player
        std::string path;    // Full Path minus video extension and quality
        bool m4v;            // is video m4v extension
        bool ogv;            // is video ogv extension
        bool isUtube;        // is U Tube video
        std::string poster;  // Full path to image
        int width;           // Width of Video
        int height;          // Height of Video
        bool autoplay;       // is autoplay
        std::string sizes;   // coma delimited array of sizes: 1080,720
        std::string quality; // coma delimited array of quality: hd,lq
        std::string pages;   // coma delimited array of html content pages: page1,page2

        template<class Action>
        void persist(Action &a)
        {
            Wt::Dbo::field(a, name, "name");
            Wt::Dbo::field(a, title, "title");
            Wt::Dbo::field(a, path, "path");
            Wt::Dbo::field(a, m4v, "m4v");
            Wt::Dbo::field(a, ogv, "ogv");
            Wt::Dbo::field(a, isUtube, "isUtube");
            Wt::Dbo::field(a, poster, "poster");
            Wt::Dbo::field(a, width, "width");
            Wt::Dbo::field(a, height, "height");
            Wt::Dbo::field(a, autoplay, "autoplay");
            Wt::Dbo::field(a, sizes, "sizes");
            Wt::Dbo::field(a, quality, "quality");
            Wt::Dbo::field(a, pages, "pages");
        }
};
/* ****************************************************************************
 * Video
 */
class VideoImpl : public Wt::WContainerWidget
{
    public:
        VideoImpl(std::string appPath, const std::string& basePath, Wt::Dbo::SqlConnectionPool* connectionPool);
        void setInternalBasePath(const std::string& basePath);
        virtual ~VideoImpl();

    private:
        void init();
        void createVideo();
        void refresh();
        void handlePathChange(const std::string& path);

        void categoryComboChanged();
        void videoComboChanged();
        bool readVideo(std::string appPath);
        void setCategoryItemPath();
        void setComboBox();

        std::vector<myVideo> myVideos;
        bool isVideo=false;
        bool bindVideo = false;
        bool isChanged=false;
        std::string theAppPath;
        std::string basePath_;
        Wt::WContainerWidget* items_;
        Wt::Dbo::SqlConnectionPool* connectionPool_;
        int categoryIndex = 0;
        int videoIndex = 0;
        Wt::WComboBox *categoryCombo;
        Wt::WComboBox *videoCombo;
        #ifdef WVIDEO
            Wt::WVideo *player;
        #else
            Wt::WMediaPlayer *player;
        #endif
};
/* ****************************************************************************
 * VideoView
 */
class VideoView : public Wt::WCompositeWidget
{
    public:
        VideoView(std::string appPath, const std::string& basePath, Wt::Dbo::SqlConnectionPool* db);
        void setInternalBasePath(const std::string& basePath);
    private:
        VideoImpl *impl_;
};
#endif // VIDEO_H
// --- End Of File ------------------------------------------------------------
