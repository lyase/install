/* ****************************************************************************
 *  Video
 */
#include <Wt/WApplication>
#include <Wt/WEnvironment>
#include <Wt/WLogger>
#include <Wt/WContainerWidget>
#include <Wt/WVideo>
#include <Wt/WMediaPlayer>
#include <Wt/WImage>
#include <Wt/WComboBox>
#include <Wt/WText>
//#include <Wt/Dbo/Dbo>
#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_utils.hpp"
#include <QString>
#include <QDebug>

#define WVIDEO
#include "view/VideoImpl.h"

/* ****************************************************************************
 * Video Impl
 */
VideoImpl::VideoImpl(std::string appPath, const std::string& basePath, Wt::Dbo::SqlConnectionPool* connectionPool) : basePath_(basePath)
{
    Wt::log("notice") << "( *** VideoImpl *** " << ")";

    theAppPath = appPath;
    connectionPool_ = connectionPool;
    items_ = new Wt::WContainerWidget(this);

    init();
}
/* ****************************************************************************
 * ~Video Impl
 */
VideoImpl::~VideoImpl()
{
    clear();
}
/* ****************************************************************************
 * init
 */
void VideoImpl::init()
{
    createVideo();
    Wt::WApplication *app = Wt::WApplication::instance();
    app->internalPathChanged().connect(this, &VideoImpl::handlePathChange);
}
/* ****************************************************************************
 * create Video
 */
void VideoImpl::createVideo()
{
    Wt::log("notice") << "( *** createVideo *** " << ")";
    setCategoryItemPath();
    Wt::log("notice") << "(createVideo ->  setCategoryItemPath = " << categoryIndex << "/" << videoIndex << ")";
    items_->clear();

    //#define DO_OGV
    std::string mp4Video = "/video/Trailer/light-wizzard-in-the-flesh-trailer-lq-1080.m4v";
    #ifdef DO_OGV
        std::string ogvVideo = "/video/Trailer/light-wizzard-in-the-flesh-trailer-1080.ogv";
    #endif
    std::string poster = "/video/Trailer/light-wizzard.png";
    std::string title = "";

    //std::string uTubeVideo = "http://youtu.be/A4-GKFdRxic";
    /*
<iframe id="ytplayer" type="text/html" width="640" height="390"
src="http://www.youtube.com/embed/A4-GKFdRxic?origin=http://example.com"  frameborder="0"/>
autoplay=1&
*/
    isChanged = true; // Prevent Combo Box from updating internalPath
    categoryCombo = new Wt::WComboBox(items_);
    // Fix
    categoryCombo->addItem("Trailer");
    categoryCombo->addItem("IAM");
    categoryCombo->setCurrentIndex(categoryIndex); //

    videoCombo = new Wt::WComboBox(items_);

    setComboBox();

    categoryCombo->activated().connect(this, &VideoImpl::categoryComboChanged);
    videoCombo->activated().connect(this, &VideoImpl::videoComboChanged);
    isChanged = false; // Allow Combo Box to update internalPath
/*
    Wt::WApplication* app = Wt::WApplication::instance();
    std::string categoryNumber = app->internalPathNextPart("/video/");
    if (!categoryNumber.empty())
    {
        if (categoryCombo->currentIndex() != std::stoi(categoryNumber))
        {
            // FIX add boundry test
            isChanged = true; // Prevent Combo Box from updating internalPath
            Wt::log("notice") << "(categoryCombo: " << categoryNumber << ")";
            categoryCombo->setCurrentIndex(std::stoi(categoryNumber));
            categoryComboChanged(); // Rebuild list in combo box
        }
        std::string videoNumber = app->internalPathNextPart("/video/" + categoryNumber + "/");
        if (!videoNumber.empty())
        {
            if (videoCombo->currentIndex() != std::stoi(videoNumber))
            {
                // FIX add boundry test
                isChanged = true; // Prevent Combo Box from updating internalPath
                Wt::log("notice") << "(videoCombo: " << videoNumber << ")";
                videoCombo->setCurrentIndex(std::stoi(videoNumber));
            }
        }
        isChanged = false; // Allow Combo Box to update internalPath
    }
*/
    if (categoryCombo->currentIndex() == 0)
    {
        new Wt::WText(Wt::WString::tr("trailer"), items_);
        mp4Video = "/video/Trailer/light-wizzard-in-the-flesh-trailer-lq-1080.m4v";
        poster = "/video/Trailer/light-wizzard.png";
        title = Wt::WString::tr("title-trailer").toUTF8().data();
        #ifdef DO_OGV
            ogvVideo = "/video/Trailer/light-wizzard-in-the-flesh-trailer-1080.ogv";
            // poster = "/video/Trailer/light-wizzard.png";
        #endif
    }
    else if (categoryCombo->currentIndex() == 1)
    {
        switch (videoCombo->currentIndex())
        {
            case 0:
                new Wt::WText(Wt::WString::tr("video-0"), items_);
                mp4Video = "http://lightwizzard.com/media/lw/light-wizzard-in-the-flesh/00-00-G-IAM/video/light-wizzard-in-the-flesh-00-00-G-IAM-lq-720.m4v";
                #ifdef DO_OGV
                    ogvVideo = "http://lightwizzard.com/media/lw/light-wizzard-in-the-flesh/00-00-G-IAM/video/light-wizzard-in-the-flesh-00-00-G-IAM-720.ogv";
                #endif
                poster = "http://lightwizzard.com/media/lw/light-wizzard-in-the-flesh/00-00-G-IAM/image/light-flesh.png";
                title = Wt::WString::tr("title-video-0").toUTF8().data();
                break;
            case 1:
                new Wt::WText(Wt::WString::tr("video-1"), items_);
                mp4Video = "http://lightwizzard.com/media/lw/light-wizzard-in-the-flesh/00-01-G-IAM/video/light-wizzard-in-the-flesh-00-01-G-IAM-lq-720.m4v";
                poster = "http://lightwizzard.com/media/lw/light-wizzard-in-the-flesh/00-01-G-IAM/image/light-flesh.png";
                title = Wt::WString::tr("title-video-1").toUTF8().data();
                break;
            case 2:
                new Wt::WText(Wt::WString::tr("video-2"), items_);
                mp4Video = "http://lightwizzard.com/media/lw/light-wizzard-in-the-flesh/00-02-G-IAM/video/light-wizzard-in-the-flesh-00-02-G-IAM-lq-720.m4v";
                poster = "http://lightwizzard.com/media/lw/light-wizzard-in-the-flesh/00-02-G-IAM/image/light-flesh.png";
                title = Wt::WString::tr("title-video-2").toUTF8().data();
                break;
            case 3:
                new Wt::WText(Wt::WString::tr("video-3"), items_);
                mp4Video = "http://lightwizzard.com/media/lw/light-wizzard-in-the-flesh/00-03-G-IAM/video/light-wizzard-in-the-flesh-00-03-G-IAM-lq-720.m4v";
                poster = "http://lightwizzard.com/media/lw/light-wizzard-in-the-flesh/00-03-G-IAM/image/light-flesh.png";
                title = Wt::WString::tr("title-video-3").toUTF8().data();
                break;
            case 4:
                new Wt::WText(Wt::WString::tr("video-4"), items_);
                mp4Video = "http://lightwizzard.com/media/lw/light-wizzard-in-the-flesh/00-04-G-IAM/video/light-wizzard-in-the-flesh-00-04-G-IAM-lq-720.m4v";
                poster = "http://lightwizzard.com/media/lw/light-wizzard-in-the-flesh/00-04-G-IAM/image/light-flesh.png";
                title = Wt::WString::tr("title-video-4").toUTF8().data();
                break;
        }
    }

    Wt::log("notice") << "(mp4Video: " << mp4Video << ")";

#ifdef WVIDEO
    player = new Wt::WVideo(items_);
    player->addSource(mp4Video);
    #ifdef DO_OGV
        player->addSource(ogvVideo);
    #endif
    player->setPoster(poster);
    player->setAlternativeContent(new Wt::WImage(poster));
    player->resize(640, 360);
#else
    //Wt::WApplication::instance()-> useStyleSheet(Wt::WApplication::resourcesUrl() + "jPlayer/skin/blue.monday/jplayer.blue.monday.css");
    //Wt::WApplication::instance()-> useStyleSheet(Wt::WApplication::resourcesUrl() + "jPlayer/skin/pink.flag/jplayer.pink.flag.css");
    player = new Wt::WMediaPlayer(Wt::WMediaPlayer::Video, items_);
    player->addSource(Wt::WMediaPlayer::M4V, Wt::WLink(mp4Video));
    #ifdef DO_OGV
        player->addSource(Wt::WMediaPlayer::OGV, Wt::WLink(ogvVideo));
    #endif
    player->addSource(Wt::WMediaPlayer::PosterImage, Wt::WLink(poster));
    player->setTitle(title);
    player->setVideoSize(640, 360);
#endif

    //this->addWidget(items_);
}
/* ****************************************************************************
 * category Combo Changed
 */
void VideoImpl::setComboBox()
{
    Wt::log("notice") << "(setComboBox)";
    videoCombo->clear();

    switch (categoryCombo->currentIndex())
    {
        case 0:
            // fix tr
            videoCombo->addItem("Trailer");
            break;
        case 1:
            videoCombo->addItem("Step 0");
            videoCombo->addItem("Step 1");
            videoCombo->addItem("Step 2");
            videoCombo->addItem("Step 3");
            videoCombo->addItem("Step 4");
            break;
    }
    videoCombo->setCurrentIndex(videoIndex);
}
/* ****************************************************************************
 * category Combo Changed
 */
void VideoImpl::categoryComboChanged()
{
    Wt::log("notice") << "(categoryComboChanged)";
    videoCombo->setCurrentIndex(0);
    videoIndex = 0;
    categoryIndex = categoryCombo->currentIndex();
    setComboBox();
    // Make sure we want to update URL
    if (!isChanged)
    {
        Wt::log("notice") << "(categoryComboChanged: " << std::to_string(categoryCombo->currentIndex()) << ")";
        Wt::WApplication::instance()->setInternalPath("/video/" + std::to_string(categoryCombo->currentIndex()) + "/" + std::to_string(videoCombo->currentIndex()), true);
    }
}
/* ****************************************************************************
 * video Combo Changed
 */
void VideoImpl::videoComboChanged()
{
    Wt::log("notice") << "(videoComboChanged)";
    videoIndex = videoCombo->currentIndex();
    // Make sure we want to update URL
    if (!isChanged)
    {
        Wt::log("notice") << "(videoComboChanged: " << std::to_string(videoCombo->currentIndex()) << ")";
        Wt::WApplication::instance()->setInternalPath("/video/" + std::to_string(categoryCombo->currentIndex()) + "/" + std::to_string(videoCombo->currentIndex()), true);
    }
}
/* ****************************************************************************
 * readVideo
 */
bool VideoImpl::readVideo(std::string appPath)
{
    int categories = 0;
    // Open XML File
    const char *filePath = appPath.c_str();
    rapidxml::file<> xmlFile(filePath);
    rapidxml::xml_document<> doc;
    doc.parse<0>(xmlFile.data());
    // Find our root node
    rapidxml::xml_node<> * root_node = doc.first_node("videos");
    // define xml item
    rapidxml::xml_attribute<> *x_item;
    for (rapidxml::xml_node<> * domain_node = root_node->first_node("category"); domain_node; domain_node = domain_node->next_sibling("category"))
    {
        // title
        x_item = domain_node->first_attribute("title");
        if (!x_item)
        {
            Wt::log("error") << "(readVideo: Missing XML Element: title = " << domain_node->name() << ")";
            return 1;
        }
        std::string title(x_item->value(), x_item->value_size());
        myVideos.push_back(myVideo());

        for (rapidxml::xml_node<> * domain_node = root_node->first_node("video"); domain_node; domain_node = domain_node->next_sibling("video"))
        {

        }
        categories++;
    }
    return true;
}
/* ****************************************************************************
 * set Internal Base Path
 */
void VideoImpl::setInternalBasePath(const std::string& basePath)
{
    basePath_ = basePath;
    refresh();
}
/* ****************************************************************************
 * refresh
 */
void VideoImpl::refresh()
{
    handlePathChange(wApp->internalPath());
}
/* ****************************************************************************
 * handle Path Change
 */
void VideoImpl::handlePathChange(const std::string& path)
{
    //(void)path; // Eat path Warning
    Wt::log("notice") << "(handlePathChange: path = " << path << ")"; // /video/1/1

    Wt::WApplication *app = wApp;
    if (app->internalPathMatches(basePath_))
    {
        createVideo();
        return;
    }
    else
    {
        //v1->pause();
        Wt::log("notice") << "(handlePathChange: video stop)";
    }
}
/* ****************************************************************************
 * getCategoryItemPath
 * Path must have video in it
 * the last path is the item, the rest are categories
 * /video/1/2 is Category 1, Item 2
 * /video/1/2/3 is Category 1, Category 3, Item 3
 */
void VideoImpl::setCategoryItemPath()
{
    Wt::log("notice") << "(setCategoryItemPath)";
    Wt::WApplication* app = Wt::WApplication::instance();
    if (app->internalPathMatches("/video/"))
    {
        std::string categoryNumber = app->internalPathNextPart("/video/");
        if (!categoryNumber.empty())
        {
            categoryIndex = std::stoi(categoryNumber);
            std::string videoNumber = app->internalPathNextPart("/video/" + categoryNumber + "/");
            if (!videoNumber.empty())
            {
                videoIndex = std::stoi(videoNumber);
                Wt::log("notice") << "(setCategoryItemPath: " << categoryNumber + "/" + videoNumber << ")";
            }
        }
    }
}
/* ************************************************************************* */
/* ************************************************************************* */
/* ****************************************************************************
 * VideoView
 */
VideoView::VideoView(std::string appPath, const std::string& basePath, Wt::Dbo::SqlConnectionPool* db)
{
    impl_ = new VideoImpl(appPath, basePath, db);
    setImplementation(impl_);
}
/* ****************************************************************************
 * set Internal Base Path
 */
void VideoView::setInternalBasePath(const std::string& basePath)
{
    impl_->setInternalBasePath(basePath);
}
// --- End Of File ------------------------------------------------------------
