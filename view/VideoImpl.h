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
 * Prototype VideoSession
 */
//class VideoSession;
/* ****************************************************************************
 * pageType
 */
enum pageType
{
  iframe,
  xml
};
/* ****************************************************************************
 * Video
 */
class VideoImpl : public Wt::WContainerWidget
{
    public:
        VideoImpl(const std::string& appPath, const std::string& basePath, Wt::Dbo::SqlConnectionPool& connectionPool);
        void SetInternalBasePath(const std::string& basePath);
        virtual ~VideoImpl();
        /* --------------------------------------------------------------------
         * session
         */
        VideoSession& session()  { return session_;  }

    private:
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
        //
        std::string appPath_;
        std::string basePath_;
        VideoSession session_;
        Wt::WWidget* videoPage_;
        //std::vector<myVideo> myVideos;
        bool isVideo = false;
        bool bindVideo = false;
        bool isChanged = false;
        Wt::WContainerWidget* items_;
        QString catagoryPath;
        //int categoryIndex = 0;
        //int videoIndex = 0;
        // ComboBoxs
        bool isComboCategory_0 = false;
        Wt::WComboBox *ComboCategory_0;  // Category 0
        Wt::WComboBox *ComboCategory_1;  // Category 1
        Wt::WComboBox *ComboCategory_2;  // Category 2
        Wt::WComboBox *ComboCategory_3;  // Category 3
        Wt::WComboBox *ComboCategory_4;  // Category 4
        Wt::WComboBox *ComboCategory_5;  // Category 5
        bool isComboVideo = false;
        Wt::WComboBox *ComboVideo;       // Video Name
        Wt::WComboBox *ComboSizes;       // Sizes: sizes="1080,720"
        Wt::WComboBox *ComboQuality;     // quality="hd,lq"
        bool isTextYewTubeIframe = false;
        Wt::WText *TextYewTubeIframe;    // yew-tube iFrame
        bool isTextPageTop = false;
        Wt::WText *TextPageTop;          // page top
        bool isTextPageBottom = false;
        Wt::WText *TextPageBottom;       // page bottom
        //
        std::string mp4Video;
        std::string ogvVideo;
        std::string poster;
        std::string yewtubesrc;
        std::string title;
        int width, height;
        std::string size;
        std::string quality;
        std::string pageBottom;
        std::string pageTop;
        bool isutube = false;
        bool isComboChange = false;

        //TheVideo myVideo;
        int numberCats = -1;
        std::string categoryQuery;  // Full Path from Database: Cat-1|Cat-2
        std::string categoryPath;   // Full Path from Database: Cat-1/Cat-2
        std::string categoryText_0; // First Category:  Cat-1
        std::string categoryText_1; // Second Category: Cat-2
        std::string categoryText_2; //
        std::string categoryText_3; //
        std::string categoryText_4; //
        std::string categoryText_5; //
        std::string videoText;      // Video Name

        #ifdef WVIDEO
            Wt::WVideo *player;
        #else
            Wt::WMediaPlayer *player;
        #endif
};
#endif // VIDEO_H
#endif // VIDEOMAN
// --- End Of File ------------------------------------------------------------
