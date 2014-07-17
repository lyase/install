#ifdef VIDEOMAN
#ifndef VIDEO_H
#define VIDEO_H
#include <Wt/WApplication>
#include <Wt/WContainerWidget>
#include <Wt/WEnvironment>
#include <Wt/WComboBox>
//
#include <Wt/Dbo/Dbo>
//
#include <QString>
//
#include "model/TheVideo.h"
#include "model/VideoSession.h"
/* ****************************************************************************
 * pageType
 */
enum pageType
{
  iframe,
  xml
};
/* ****************************************************************************
 * Video Implement
 */
class VideoImpl : public Wt::WContainerWidget
{
    public:
        VideoImpl(const std::string& appPath, const std::string& basePath, Wt::Dbo::SqlConnectionPool& connectionPool, const std::string& lang);
        void SetInternalBasePath(const std::string& basePath);
        virtual ~VideoImpl();
        /* --------------------------------------------------------------------
         * session
         */
        VideoSession& session()  { return session_;  }

    private:
        // Init in constructor
        std::string appPath_;
        std::string basePath_;
        VideoSession session_;
        std::string lang_;
        //
        void refresh();
        void Init();
        void MakeVideo();
        void HandlePathChange(const std::string& path);

        void CategoryComboChanged();
        void VideoComboChanged();
        bool CreateCategoryCombo();
        bool CreateVideoCombobox();
        void GetVideo();
        std::string GetCategories(std::string delimitor);
        bool GetCategoriesPath();
        void ClearCategories();
        Wt::WWidget* GetPage(Wt::WString src);
        Wt::WWidget* WrapView(Wt::WWidget *(VideoImpl::*createWidget)());
        Wt::WWidget* PageContentTop();
        Wt::WWidget* PageContentBottom();
        Wt::WWidget* YouTubeContent();
        //
        std::string defaultPageTopHeight = "800px";
        std::string defaultPageTopWidth = "790px";
        std::string defaultPageBottomHeight = "800px";
        std::string defaultPageBottomWidth = "790px";
        //
        Wt::WString TextPageTopIframe;     // Top Page iFrame
        Wt::WString TextPageBottomIframe;  // Bottom Page iFrame
        Wt::WString TextYouTubeIframe;     // You-Tube iFrame
        //
        std::string domainName = "";
        Wt::WWidget* videoPage_ = NULL;
        Wt::WTemplate *videoTemplate = NULL;
        bool isVideo = false;
        bool bindVideo = false;
        bool isChanged = false;
        Wt::WContainerWidget* items_ = NULL;
        Wt::WContainerWidget* bindItems = NULL;
        // ComboBoxs
        Wt::WComboBox *ComboCategory_0 = NULL;  // Category 0
        Wt::WComboBox *ComboCategory_1 = NULL;  // Category 1
        Wt::WComboBox *ComboCategory_2 = NULL;  // Category 2
        Wt::WComboBox *ComboCategory_3 = NULL;  // Category 3
        Wt::WComboBox *ComboCategory_4 = NULL;  // Category 4
        Wt::WComboBox *ComboCategory_5 = NULL;  // Category 5
        Wt::WComboBox *ComboVideo = NULL;       // Video Name
        Wt::WComboBox *ComboSizes = NULL;       // Sizes: sizes="1080,720"
        Wt::WComboBox *ComboQuality = NULL;     // quality="hd,lq"
        //
        std::string mp4Video = "";
        std::string ogvVideo = "";
        std::string poster = "";
        std::string title = "";
        std::string size = "";
        std::string quality = "";
        bool isutube = false;
        int numberCats = -1;
        std::string categoryQuery = "";  // Full Path from Database: Cat-1|Cat-2
        std::string categoryPath = "";   // Full Path from Database: Cat-1/Cat-2
        std::string categoryText_0 = ""; // First Category:  Cat-1
        std::string categoryText_1 = ""; // Second Category: Cat-2
        std::string categoryText_2 = ""; //
        std::string categoryText_3 = ""; //
        std::string categoryText_4 = ""; //
        std::string categoryText_5 = ""; //
        std::string videoText = "";      // Video Name
        int currentVideoIndex = -1;
        int oldVideoIndex = -2;
        //
        std::string myInternalPath = "";
        //
        #ifdef WVIDEO
            Wt::WVideo *player;
        #else
            Wt::WMediaPlayer *player = NULL;
        #endif
        #ifdef USE_TEMPLATE
            Wt::WTemplate *videoTemplate = NULL;
        #endif
};
#endif // VIDEO_H
#endif // VIDEOMAN
// --- End Of File ------------------------------------------------------------
