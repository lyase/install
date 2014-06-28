/* ****************************************************************************
 * Witty Wizard
 * Video Manager
 * Version: 1.0.0
 * Last Date Modified: 20 May 2014
 *
 * Requires Cookie Patch: https://github.com/chan-jesus/vidanueva/blob/master/witty.patch
 *
 */
#ifdef VIDEOMAN
#include <Wt/WApplication>
#include <Wt/WEnvironment>
#include <Wt/WLogger>
#include <Wt/WContainerWidget>
#include <Wt/WImage>
#include <Wt/WComboBox>
#include <Wt/WText>
#include <Wt/WTemplate>
#ifdef WVIDEO
    #include <Wt/WVideo>
#else
    #include <Wt/WMediaPlayer>
#endif
// Database
#include <Wt/Dbo/Dbo>
#include <Wt/Dbo/ptr>
#include <Wt/Dbo/Session>
#include <Wt/Dbo/Impl>
#include <Wt/Dbo/Types>
#include <Wt/Dbo/QueryModel>
//
#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_utils.hpp"
//
#include <QString>
#include <QStringList>
#include <QDebug>
#ifdef REGX
    #include <QRegularExpression>
#else
    #include <boost/algorithm/string.hpp>
#endif

#include "view/VideoImpl.h"
//#include "VideoView.h"
#include "model/VideoSession.h"
#include "model/TheVideo.h"
#include "WittyWizard.h"
/* ****************************************************************************
 * Video Impl
 * This gets called every time the page is refreshed
 */
VideoImpl::VideoImpl(const std::string& appPath, const std::string& basePath, Wt::Dbo::SqlConnectionPool& connectionPool) : appPath_(appPath), basePath_(basePath), session_(appPath, connectionPool), videoPage_(0)
{
    Wt::log("start") << " *** VideoImpl::VideoImpl() *** ";
    items_ = new Wt::WContainerWidget(this);\
    items_->setId("videocan");
    Init();
} // end VideoImpl::VideoImpl
/* ****************************************************************************
 * ~Video Impl
 */
VideoImpl::~VideoImpl()
{
    clear();
} // end VideoImpl::~VideoImpl
/* ****************************************************************************
 * init
 */
void VideoImpl::Init()
{
    Wt::log("start") << " *** VideoImpl::Init() ***";
    MakeVideo();
    // Now add in the event handler
    Wt::WApplication *app = Wt::WApplication::instance();
    app->internalPathChanged().connect(this, &VideoImpl::HandlePathChange);
} // end void VideoImpl::Init()
/* ****************************************************************************
 * make Video
 */
void VideoImpl::MakeVideo()
{
    Wt::log("start") << " *** VideoImpl::MakeVideo( ) *** ";
    #ifdef USE_TEMPLATE
        Wt::WApplication *app = Wt::WApplication::instance();
        Wt::WTemplate *videoTemplate = new Wt::WTemplate(Wt::WString::tr("videoman-template"), app->root()); //  <message id="videoman-template">
        videoPage_ = videoTemplate;
    #endif

    // Set Category and Video from Internal Path, ComboBox or Cookie
    GetCategoriesPath();
    #ifndef USE_TEMPLATE
        // Clear all the WContainerWidget Items
        items_->clear();
    #endif
    //
    CreateCategoryCombo();
    //
    CreateVideoCombobox();
    Wt::log("end") << " ** VideoImpl::MakeVideo() ** ";
} // end void VideoImpl::MakeVideo()
/* ****************************************************************************
 * Create Category Combo
 * First time Internal Path will not be set
 * Combobox will not be set
 */
bool VideoImpl::CreateCategoryCombo()
{
    Wt::log("start") << " *** VideoImpl::CreateCategoryCombo() ***";
    // Create an instance of app to access Internal Paths
    Wt::log("notice") << "VideoImpl::CreateCategoryCombo() read internal Path: categoryPath = " << categoryPath  << " | categoryQuery = " << categoryQuery << " | videoText = __" << videoText << "__";
    if (categoryPath.empty())
    {
        categoryPath = GetCategories("/");
    }
    if (categoryQuery.empty())
    {
        categoryQuery = GetCategories("|");
    }
    //
    std::string categoriesQueryName=""; // cat-0|cat-1|cat-2|cat-3...
    try
    {
        // Start a Transaction
        Wt::Dbo::Transaction t(session_);
        typedef Wt::Dbo::collection< Wt::Dbo::ptr<TheVideo> > TheVideos;
        // Get database list of all Videos
        TheVideos videos = session_.find<TheVideo>();
        for (TheVideos::const_iterator i = videos.begin(); i != videos.end(); ++i)
        {
            //Wt::log("notice") << "VideoImpl::CreateCategoryCombo:  const_iterator " << (*i)->categories << ")";
            // Category List: cat-0|cat-1|cat-2|cat-3...
            QString myCategoriesSchema = QString::fromStdString((*i)->categories);
            // Currently only testing 1 category
            #ifdef REGX
                QRegExp rx("|"); // RegEx for ' ' or ',' or '.' or ':' or '\t'
                QStringList categoryFields = myCategoriesSchema.split(rx);
            #else
                // @FIXIT test
                //std::vector <std::string> categoryFields;
                //boost::split( categoryFields, myCategoriesSchema.toStdString(), boost::is_any_of( "|" ) );
                QStringList categoryFields = myCategoriesSchema.split("|");
            #endif
            if (myCategoriesSchema.isEmpty())
            {
                numberCats = 0;
            }
            else
            {
                numberCats = myCategoriesSchema.contains('|') + 1;
            }
            if (numberCats > 1)
            {
                    int catSize = categoryFields.size();
                    if (catSize > 1)
                    {
                        // if I use (name of javascript concept where you name a variable like category_$x = 0; not a c concept) a categoryText_x where x is i, it becomes: categoryText_0 and assigns the correct value to it
                        for (int catIndex=0;catIndex<catSize;catIndex++)
                        {
                            switch(catIndex)
                            {
                                case 0:
                                    categoryText_0 = categoryFields.at(catIndex).toStdString();
                                    break;
                                case 1:
                                    categoryText_1 = categoryFields.at(catIndex).toStdString();
                                    break;
                                case 2:
                                    categoryText_2 = categoryFields.at(catIndex).toStdString();
                                    break;
                                case 3:
                                    categoryText_3 = categoryFields.at(catIndex).toStdString();
                                    break;
                                case 4:
                                    categoryText_4 = categoryFields.at(catIndex).toStdString();
                                    break;
                                case 5:
                                    categoryText_5 = categoryFields.at(catIndex).toStdString();
                                    break;
                            }
                        } // end for (int catIndex=0;catIndex<catSize;catIndex++)
                    } // end  if (catSize > 1)
            } // end if (numberCats > 1)
            switch (numberCats)
            {
                case 0:
                    // FIXIT for video list only
                    break;
                case 1:
                    categoriesQueryName = myCategoriesSchema.toStdString(); // cat-0
                    // if (!ComboCategory_0) // this does not work reliable
                    if (!isComboCategory_0)
                    {
                        Wt::log("notice") << "VideoImpl::CreateCategoryCombo:  new ComboCategory_0 WComboBox";
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        ComboCategory_0->addItem(categoriesQueryName); // it did not exist, add it
                        isComboCategory_0 = true;
                    }
                    if (ComboCategory_0->findText(categoriesQueryName) == -1)
                    {
                        ComboCategory_0->addItem(categoriesQueryName); // it did not exist, add it
                    }
                    if (categoriesQueryName == categoryQuery)
                    {
                        ComboCategory_0->setCurrentIndex(ComboCategory_0->findText(categoryQuery));
                    }
                    break;
                case 2:
                    if (!ComboCategory_0)
                    {
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        isComboCategory_0 = true;
                    }
                    if (!ComboCategory_1)
                    {
                        ComboCategory_1 = new Wt::WComboBox(items_);
                    }
                    if (ComboCategory_0->findText(categoryText_0) == -1)
                    {
                        ComboCategory_0->addItem(categoryText_0); // it did not exist, add it
                    }
                    if (categoryFields.at(0).toStdString() == categoryText_0)
                    {
                        ComboCategory_0->setCurrentIndex(ComboCategory_0->findText(categoryText_0));
                    }
                    if (ComboCategory_1->findText(categoryText_1) == -1)
                    {
                        ComboCategory_1->addItem(categoryText_1); // it did not exist, add it
                    }
                    if (categoryFields.at(1).toStdString() == categoryText_1)
                    {
                        ComboCategory_1->setCurrentIndex(ComboCategory_1->findText(categoryText_1));
                    }
                    break;
                case 3:
                    if (!ComboCategory_0)
                    {
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        isComboCategory_0 = true;
                    }
                    if (!ComboCategory_1)
                    {
                        ComboCategory_1 = new Wt::WComboBox(items_);
                    }
                    if (!ComboCategory_2)
                    {
                        ComboCategory_2 = new Wt::WComboBox(items_);
                    }
                    if (ComboCategory_0->findText(categoryText_0) == -1)
                    {
                        ComboCategory_0->addItem(categoryText_0); // it did not exist, add it
                    }
                    if (categoryFields.at(0).toStdString() == categoryText_0)
                    {
                        ComboCategory_0->setCurrentIndex(ComboCategory_0->findText(categoryText_0));
                    }
                    if (ComboCategory_1->findText(categoryText_1) == -1)
                    {
                        ComboCategory_1->addItem(categoryText_1); // it did not exist, add it
                    }
                    if (categoryFields.at(1).toStdString() == categoryText_1)
                    {
                        ComboCategory_1->setCurrentIndex(ComboCategory_1->findText(categoryText_1));
                    }
                    if (ComboCategory_2->findText(categoryText_2) == -1)
                    {
                        ComboCategory_2->addItem(categoryText_2); // it did not exist, add it
                    }
                    if (categoryFields.at(2).toStdString() == categoryText_2)
                    {
                        ComboCategory_2->setCurrentIndex(ComboCategory_2->findText(categoryText_2));
                    }
                    break;
                case 4:
                    if (!ComboCategory_0)
                    {
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        isComboCategory_0 = true;
                    }
                    if (!ComboCategory_1)
                    {
                        ComboCategory_1 = new Wt::WComboBox(items_);
                    }
                    if (!ComboCategory_2)
                    {
                        ComboCategory_2 = new Wt::WComboBox(items_);
                    }
                    if (!ComboCategory_3)
                    {
                        ComboCategory_3 = new Wt::WComboBox(items_);
                    }
                    if (ComboCategory_0->findText(categoryText_0) == -1)
                    {
                        ComboCategory_0->addItem(categoryText_0); // it did not exist, add it
                    }
                    if (categoryFields.at(0).toStdString() == categoryText_0)
                    {
                        ComboCategory_0->setCurrentIndex(ComboCategory_0->findText(categoryText_0));
                    }
                    if (ComboCategory_1->findText(categoryText_1) == -1)
                    {
                        ComboCategory_1->addItem(categoryText_1); // it did not exist, add it
                    }
                    if (categoryFields.at(1).toStdString() == categoryText_1)
                    {
                        ComboCategory_1->setCurrentIndex(ComboCategory_1->findText(categoryText_1));
                    }
                    if (ComboCategory_2->findText(categoryText_2) == -1)
                    {
                        ComboCategory_2->addItem(categoryText_2); // it did not exist, add it
                    }
                    if (categoryFields.at(2).toStdString() == categoryText_2)
                    {
                        ComboCategory_2->setCurrentIndex(ComboCategory_2->findText(categoryText_2));
                    }
                    if (ComboCategory_3->findText(categoryText_3) == -1)
                    {
                        ComboCategory_3->addItem(categoryText_3); // it did not exist, add it
                    }
                    if (categoryFields.at(3).toStdString() == categoryText_3)
                    {
                        ComboCategory_3->setCurrentIndex(ComboCategory_3->findText(categoryText_3));
                    }
                    break;
                case 5:
                    if (!ComboCategory_0)
                    {
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        isComboCategory_0 = true;
                    }
                    if (!ComboCategory_1)
                    {
                        ComboCategory_1 = new Wt::WComboBox(items_);
                    }
                    if (!ComboCategory_2)
                    {
                        ComboCategory_2 = new Wt::WComboBox(items_);
                    }
                    if (!ComboCategory_3)
                    {
                        ComboCategory_3 = new Wt::WComboBox(items_);
                    }
                    if (!ComboCategory_4)
                    {
                        ComboCategory_4 = new Wt::WComboBox(items_);
                    }
                    if (ComboCategory_0->findText(categoryText_0) == -1)
                    {
                        ComboCategory_0->addItem(categoryText_0); // it did not exist, add it
                    }
                    if (categoryFields.at(0).toStdString() == categoryText_0)
                    {
                        ComboCategory_0->setCurrentIndex(ComboCategory_0->findText(categoryText_0));
                    }
                    if (ComboCategory_1->findText(categoryText_1) == -1)
                    {
                        ComboCategory_1->addItem(categoryText_1); // it did not exist, add it
                    }
                    if (categoryFields.at(1).toStdString() == categoryText_1)
                    {
                        ComboCategory_1->setCurrentIndex(ComboCategory_1->findText(categoryText_1));
                    }
                    if (ComboCategory_2->findText(categoryText_2) == -1)
                    {
                        ComboCategory_2->addItem(categoryText_2); // it did not exist, add it
                    }
                    if (categoryFields.at(2).toStdString() == categoryText_2)
                    {
                        ComboCategory_2->setCurrentIndex(ComboCategory_2->findText(categoryText_2));
                    }
                    if (ComboCategory_3->findText(categoryText_3) == -1)
                    {
                        ComboCategory_3->addItem(categoryText_3); // it did not exist, add it
                    }
                    if (categoryFields.at(3).toStdString() == categoryText_3)
                    {
                        ComboCategory_3->setCurrentIndex(ComboCategory_3->findText(categoryText_3));
                    }
                    if (ComboCategory_4->findText(categoryText_4) == -1)
                    {
                        ComboCategory_4->addItem(categoryText_4); // it did not exist, add it
                    }
                    if (categoryFields.at(4).toStdString() == categoryText_4)
                    {
                        ComboCategory_4->setCurrentIndex(ComboCategory_4->findText(categoryText_4));
                    }
                    break;
                case 6:
                    if (!ComboCategory_0)
                    {
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        isComboCategory_0 = true;
                    }
                    if (!ComboCategory_1)
                    {
                        ComboCategory_1 = new Wt::WComboBox(items_);
                    }
                    if (!ComboCategory_2)
                    {
                        ComboCategory_2 = new Wt::WComboBox(items_);
                    }
                    if (!ComboCategory_3)
                    {
                        ComboCategory_3 = new Wt::WComboBox(items_);
                    }
                    if (!ComboCategory_4)
                    {
                        ComboCategory_4 = new Wt::WComboBox(items_);
                    }
                    if (!ComboCategory_5)
                    {
                        ComboCategory_5 = new Wt::WComboBox(items_);
                    }
                    if (ComboCategory_0->findText(categoryText_0) == -1)
                    {
                        ComboCategory_0->addItem(categoryText_0); // it did not exist, add it
                    }
                    if (categoryFields.at(0).toStdString() == categoryText_0)
                    {
                        ComboCategory_0->setCurrentIndex(ComboCategory_0->findText(categoryText_0));
                    }
                    if (ComboCategory_1->findText(categoryText_1) == -1)
                    {
                        ComboCategory_1->addItem(categoryText_1); // it did not exist, add it
                    }
                    if (categoryFields.at(1).toStdString() == categoryText_1)
                    {
                        ComboCategory_1->setCurrentIndex(ComboCategory_1->findText(categoryText_1));
                    }
                    if (ComboCategory_2->findText(categoryText_2) == -1)
                    {
                        ComboCategory_2->addItem(categoryText_2); // it did not exist, add it
                    }
                    if (categoryFields.at(2).toStdString() == categoryText_2)
                    {
                        ComboCategory_2->setCurrentIndex(ComboCategory_2->findText(categoryText_2));
                    }
                    if (ComboCategory_3->findText(categoryText_3) == -1)
                    {
                        ComboCategory_3->addItem(categoryText_3); // it did not exist, add it
                    }
                    if (categoryFields.at(3).toStdString() == categoryText_3)
                    {
                        ComboCategory_3->setCurrentIndex(ComboCategory_3->findText(categoryText_3));
                    }
                    if (ComboCategory_4->findText(categoryText_4) == -1)
                    {
                        ComboCategory_4->addItem(categoryText_4); // it did not exist, add it
                    }
                    if (categoryFields.at(4).toStdString() == categoryText_4)
                    {
                        ComboCategory_4->setCurrentIndex(ComboCategory_4->findText(categoryText_4));
                    }
                    if (ComboCategory_5->findText(categoryText_5) == -1)
                    {
                        ComboCategory_5->addItem(categoryText_5); // it did not exist, add it
                    }
                    if (categoryFields.at(5).toStdString() == categoryText_5)
                    {
                        ComboCategory_5->setCurrentIndex(ComboCategory_5->findText(categoryText_5));
                    }
                    break;
            } // end switch (numberCats)
            //Wt::log("notice") << " VideoImpl::CreateCategoryCombo() numberCats = " << numberCats << " : name = " << mySchema.toStdString() << " ";
        } // end for (TheVideos::const_iterator i = videos.begin(); i != videos.end(); ++i)
        // Commit Transaction
        t.commit();
        // Set Listening Events for CategoryCombo OnChange
        switch (numberCats)
        {
            case 0:
                break;
            case 1:
                ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                #ifdef USE_TEMPLATE
                    videoTemplate->bindWidget("catcombobinder-0", ComboCategory_0);
                #endif
                break;
            case 2:
                ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_1->activated().connect(this, &VideoImpl::CategoryComboChanged);
                #ifdef USE_TEMPLATE
                    videoTemplate->bindWidget("catcombobinder-0", ComboCategory_0);
                    videoTemplate->bindWidget("catcombobinder-1", ComboCategory_1);
                #endif
                break;
            case 3:
                ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_1->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_2->activated().connect(this, &VideoImpl::CategoryComboChanged);
                #ifdef USE_TEMPLATE
                    videoTemplate->bindWidget("catcombobinder-0", ComboCategory_0);
                    videoTemplate->bindWidget("catcombobinder-1", ComboCategory_1);
                    videoTemplate->bindWidget("catcombobinder-2", ComboCategory_2);
                #endif
                break;
            case 4:
                ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_1->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_2->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_3->activated().connect(this, &VideoImpl::CategoryComboChanged);
                #ifdef USE_TEMPLATE
                    videoTemplate->bindWidget("catcombobinder-0", ComboCategory_0);
                    videoTemplate->bindWidget("catcombobinder-1", ComboCategory_1);
                    videoTemplate->bindWidget("catcombobinder-2", ComboCategory_2);
                    videoTemplate->bindWidget("catcombobinder-3", ComboCategory_3);
                #endif
                break;
            case 5:
                ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_1->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_2->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_3->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_4->activated().connect(this, &VideoImpl::CategoryComboChanged);
                #ifdef USE_TEMPLATE
                    videoTemplate->bindWidget("catcombobinder-0", ComboCategory_0);
                    videoTemplate->bindWidget("catcombobinder-1", ComboCategory_1);
                    videoTemplate->bindWidget("catcombobinder-2", ComboCategory_2);
                    videoTemplate->bindWidget("catcombobinder-3", ComboCategory_3);
                    videoTemplate->bindWidget("catcombobinder-4", ComboCategory_4);
                #endif
                break;
            case 6:
                ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_1->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_2->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_3->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_4->activated().connect(this, &VideoImpl::CategoryComboChanged);
                ComboCategory_5->activated().connect(this, &VideoImpl::CategoryComboChanged);
                #ifdef USE_TEMPLATE
                    videoTemplate->bindWidget("catcombobinder-0", ComboCategory_0);
                    videoTemplate->bindWidget("catcombobinder-1", ComboCategory_1);
                    videoTemplate->bindWidget("catcombobinder-2", ComboCategory_2);
                    videoTemplate->bindWidget("catcombobinder-3", ComboCategory_3);
                    videoTemplate->bindWidget("catcombobinder-4", ComboCategory_4);
                    videoTemplate->bindWidget("catcombobinder-5", ComboCategory_5);
                #endif
                break;
        } // end switch (numberCats)
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "VideoImpl::CreateCategoryCombo: Failed reading from video database.";
        Wt::log("error") << "VideoImpl::CreateCategoryCombo()  Failed reading from video database.";
        return false;
    }
    //
    Wt::log("end") << " ** VideoImpl::CreateCategoryCombo() **";
    return true;
} // end bool VideoImpl::CreateCategoryCombo()
/* ****************************************************************************
 * Create Video Combobox
 * categoryPath is set in program
 * Called From:
 * categoryComboChanged
 *
 */
bool VideoImpl::CreateVideoCombobox()
{
    if (categoryQuery.empty())
    {
        Wt::log("error") << " *** VideoImpl::CreateVideoCombobox() empty categoryQuery = __" << categoryQuery << "__ *** ";
        categoryQuery = GetCategories("/");
    }
    else
    {
        Wt::log("start") << " *** VideoImpl::CreateVideoCombobox() categoryQuery = __" << categoryQuery << "__ *** ";
    }
    try
    {
        Wt::Dbo::QueryModel< Wt::Dbo::ptr<TheVideo> > *model = new Wt::Dbo::QueryModel< Wt::Dbo::ptr<TheVideo> >();
        model->setQuery(session_.query< Wt::Dbo::ptr<TheVideo> >("select u from video u").where("categories = ?").bind(categoryQuery), false);
        model->addColumn("name");
        // ComboVideo has not been set
        // if (!ComboVideo) // not working reliable
        if (!isComboVideo)
        {
            ComboVideo = new Wt::WComboBox(items_);
            Wt::log("notice") << "VideoImpl::CreateVideoCombobox()  new ComboBox";
            isComboVideo = true;
        }
        else
        {
            // ComboVideo = new Wt::WComboBox(items_); // Creates Duplicates
            Wt::log("notice") << "VideoImpl::CreateVideoCombobox()  reuse ComboBox";
        }
        // ComboVideo->clear(); do not do this, it deletes the database files
        Wt::log("notice") << "VideoImpl::CreateVideoCombobox() Query = " << categoryQuery << " | Model row count = " << model->rowCount() << " ";
        ComboVideo->setModel(model);
        ComboVideo->refresh();
        ComboVideo->setCurrentIndex(0);
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "VideoImpl::CreateVideoCombobox: Failed reading record from video database category = " << categoryQuery << "";
        Wt::log("error") << "VideoImpl::CreateVideoCombobox() Failed reading record from video database category = " << categoryQuery << " ";
        return false;
    }
    GetVideo();
    Wt::log("end") << " ** VideoImpl::CreateVideoCombobox() ** ";
    return true;
} // end bool VideoImpl::CreateVideoCombobox()
/* ****************************************************************************
 * get Video
 */
void VideoImpl::GetVideo()
{
    Wt::log("start") << " *** VideoImpl::GetVideo( ) *** ";
    // clear all variables
    mp4Video = "";
    ogvVideo = "";
    poster = "";
    title = "";
    try
    {
        if (videoText.empty())
        {
            videoText = ComboVideo->currentText().toUTF8();
            Wt::log("notice") << "VideoImpl::getVideo()  set empty videoText path = " << ComboCategory_0->currentText().toUTF8() << "/" << videoText  << " | count = " << ComboVideo->count() << " ";
        }
        else
        {
            ComboVideo->setCurrentIndex(ComboVideo->findText(videoText));
            if (ComboVideo->currentIndex() == -1)
            {
                ComboVideo->setCurrentIndex(0); // Not found, set it to the first Video
            }
            Wt::log("notice") << "VideoImpl::getVideo() videoText | ComboVideo = " << videoText << " | " << ComboVideo->currentText().toUTF8()  << " | count = " << ComboVideo->count() <<  " ";
        }
        // Set Internal Path to Video
        // FIXIT add set Cookie support
        isChanged=true;
        switch (numberCats)
        {
            case 0:
                Wt::WApplication::instance()->setInternalPath(basePath_ + ComboCategory_0->currentText().toUTF8() + "/" + ComboVideo->currentText().toUTF8(), true);
                break;
            case 1:
                Wt::WApplication::instance()->setInternalPath(basePath_ + ComboCategory_0->currentText().toUTF8() + "/" + ComboVideo->currentText().toUTF8(), true);
                Wt::log("notice") << "<<<<<<< VideoImpl::getVideo() set Internal Path = " << ComboCategory_0->currentText().toUTF8() << "/" << ComboVideo->currentText().toUTF8() << " >>>>>>>";
                break;
            case 2:
                Wt::WApplication::instance()->setInternalPath(basePath_ + ComboCategory_0->currentText().toUTF8()  + "/" + ComboCategory_1->currentText().toUTF8() + "/" + ComboVideo->currentText().toUTF8(), true);
                break;
            case 3:
                Wt::WApplication::instance()->setInternalPath(basePath_ + ComboCategory_0->currentText().toUTF8() + "/" + ComboCategory_1->currentText().toUTF8() + "/" + ComboCategory_2->currentText().toUTF8() + "/" + ComboVideo->currentText().toUTF8(), true);
                break;
            case 4:
                Wt::WApplication::instance()->setInternalPath(basePath_ + ComboCategory_0->currentText().toUTF8() + "/" + ComboCategory_1->currentText().toUTF8() + "/" + ComboCategory_2->currentText().toUTF8() + "/" + ComboCategory_3->currentText().toUTF8() + "/" + ComboVideo->currentText().toUTF8(), true);
                break;
            case 5:
                Wt::WApplication::instance()->setInternalPath(basePath_ + ComboCategory_0->currentText().toUTF8() + "/" + ComboCategory_1->currentText().toUTF8() + "/" + ComboCategory_2->currentText().toUTF8() + "/" + ComboCategory_3->currentText().toUTF8() + "/" + ComboCategory_4->currentText().toUTF8() + "/" + ComboVideo->currentText().toUTF8(), true);
                break;
            case 6:
                Wt::WApplication::instance()->setInternalPath(basePath_ + ComboCategory_0->currentText().toUTF8() + "/" + ComboCategory_1->currentText().toUTF8() + "/" + ComboCategory_2->currentText().toUTF8() + "/" + ComboCategory_3->currentText().toUTF8() + "/" + ComboCategory_4->currentText().toUTF8() + "/" + ComboCategory_5->currentText().toUTF8()+ "/" + ComboVideo->currentText().toUTF8(), true);
                break;
        }
        ComboVideo->activated().connect(this, &VideoImpl::VideoComboChanged);
        isChanged=false;
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "VideoImpl::getVideo: videoText.empty";
        Wt::log("error") << "(VideoImpl::getVideo:  videoText.empty)";
    }

    try
    {
        // Start a Transaction
        Wt::Dbo::Transaction t(session_);
        //Wt::Dbo::QueryModel< Wt::Dbo::ptr<TheVideo> > *model = new Wt::Dbo::QueryModel< Wt::Dbo::ptr<TheVideo> >();
        //model->setQuery(session_.query< Wt::Dbo::ptr<TheVideo> >("select u from video u").where("name = ?").bind(videoCombo->currentText().toUTF8()), false);
        Wt::Dbo::ptr<TheVideo> playVideo = session_.find<TheVideo>().where("name = ?").bind(ComboVideo->currentText().toUTF8());
        //
        bool isPageTop = false;
        std::string pageTopSrc="";
        std::string pageTopWidth = "";
        std::string pageTopHeight = "";
        bool isPageBottom = false;
        std::string pageBottomSrc = "";
        std::string pageBottomWidth = "";
        std::string pageBottomHeight = "";

        pageTop    = playVideo->pagetop.c_str();    // source: http://url.tdl/iframe.html
        pageBottom = playVideo->pagebottom.c_str();

        if (!pageTop.empty())
        {
            isPageTop     = true;
            pageTopWidth  = playVideo->pagetopwidth.c_str();
            pageTopHeight = playVideo->pagetopheight.c_str();
            pageTopSrc = "<div id=\"pagebottom\" class=\"pagebottom\"><iframe id=\"pagebottomframe\" class=\"well\" src=\"" + pageTop + "\" width=\"" + pageTopWidth + "\" height=\"" + pageTopHeight + "\" style=\"\" frameBorder=\"1\" scrolling=\"yes\" ></iframe></div>";
        }
        if (!pageBottom.empty())
        {
            isPageBottom     = true;
            pageBottomWidth  = playVideo->pagebottomwidth.c_str();
            pageBottomHeight = playVideo->pagebottomheight.c_str();
            pageBottomSrc = "<div id=\"pagebottom\" class=\"pagebottom\"><iframe id=\"pagebottomframe\" class=\"well\" src=\"" + pageBottom + "\" width=\"" + pageBottomWidth + "\" height=\"" + pageBottomHeight + "\" style=\"\" frameBorder=\"1\" scrolling=\"yes\" ></iframe></div>";
        }
        //
        width  = playVideo->width;
        height = playVideo->height;
        //
        if (playVideo->isutube)
        {
            yewtubesrc = playVideo->path;
            poster = "<div id=\"pagetop\" class=\"pagetop\"></div><br /><div id=\"yewtube\" class=\"yewtube\"><iframe id=\"vframe\" src=\"" + yewtubesrc + "\" width=\"" + std::to_string(width) + "\" height=\"" + std::to_string(height) + "\" style=\"\" frameBorder=\"0\" scrolling=\"no\" allowfullscreen=\"true\"></iframe></div><br /><div id=\"pagebottom\" class=\"pagebottom\"></div>";
        }
        else // if (playVideo->isutube)
        {

            /* sizes="1080,720"
             *
             */
            //std::vector <std::string> sizesFields;
            //boost::split( sizesFields, playVideo->sizes, boost::is_any_of( "," ) );
            QString sizeField = playVideo->sizes.c_str();
            QStringList sizesFields = sizeField.split(",");
            size = sizesFields.at(0).toStdString(); // FIXIT read from combobox
            int sizeCount = sizesFields.size();
            if (sizeCount > 1)
            {
                // Create a dropdown box
                if (!ComboSizes)
                {
                    ComboSizes = new Wt::WComboBox(items_);
                    Wt::log("notice") << "VideoImpl::GetVideo()  new ComboBox ComboSizes";
                }
                else
                {
                    size = ComboSizes->currentText().toUTF8();
                }
                ComboSizes->clear();
                for (int sizecnt=0;sizecnt<sizeCount;sizecnt++)
                {
                    if (ComboSizes->findText(sizesFields.at(sizecnt).toStdString()) == -1)
                    {
                        ComboSizes->addItem(sizesFields.at(sizecnt).toStdString()); // it did not exist, add it
                    }
                    ComboSizes->setCurrentIndex(0);
                }
                size = sizesFields.at(0).toStdString(); // FIXIT read from combobox
            }
            //  quality="hd,lq"
            //std::vector <std::string> qualityFields;
            //boost::split( qualityFields, playVideo->quality, boost::is_any_of( "," ) );
            QString qualityField = playVideo->quality.c_str();
            QStringList qualityFields = qualityField.split(",");
            int qualityCount = qualityFields.size();
            quality = qualityFields.at(0).toStdString(); // fix read from combobox
            if (qualityCount > 1)
            {
                // Create a dropdown box
                if (!ComboQuality)
                {
                    ComboQuality = new Wt::WComboBox(items_);
                    Wt::log("notice") << "VideoImpl::GetVideo()  new ComboBox ComboQuality";
                }
                else
                {
                    quality = ComboQuality->currentText().toUTF8();
                }
                ComboQuality->clear();
                for (int qualitycnt=0;qualitycnt<sizeCount;qualitycnt++)
                {
                    if (ComboQuality->findText(qualityFields.at(qualitycnt).toStdString()) == -1)
                    {
                        ComboQuality->addItem(qualityFields.at(qualitycnt).toStdString()); // it did not exist, add it
                    }
                    ComboQuality->setCurrentIndex(0);
                } // end for (int qualitycnt=0;qualitycnt<sizeCount;qualitycnt++)
            } // end if (qualityCount > 1)
            //
            if (playVideo->ism4v)
            {
                mp4Video = playVideo->path + "-" + quality + "-" + size + ".m4v";
            }
            if (playVideo->isogv)
            {
                ogvVideo = playVideo->path + "-" + quality + "-" + size + ".ogv";
            }
            poster = playVideo->poster;

        } // end if (playVideo->isutube)
        //
        if (isPageTop)
        {
            if (!isTextPageTop) // not working if (!TextPageTop)
            {
                TextPageTop = new Wt::WText(pageTopSrc, Wt::XHTMLUnsafeText, items_);
                TextPageTop->setStyleClass("pagetop");
                isTextPageTop = true;
            }
            else
            {
                std::string jsPageTop = "document.getElementById('pagetopframe').src='" + pageTop + "';";
                Wt::log("notice") << " VideoImpl::getVideo() jsPageTop = " << jsPageTop << " ";
                this->doJavaScript(jsPageTop);
            } // end if (!TextPageTop)
        } // end if (isPageTop)
        //
        if (playVideo->isutube)
        {
            // if (!TextYewTubeIframe) // not working
            if (!isTextYewTubeIframe)
            {
                TextYewTubeIframe = new Wt::WText(poster, Wt::XHTMLUnsafeText, items_);
                TextYewTubeIframe->setStyleClass("yewtube");
                isTextYewTubeIframe = true;
            }
            else
            {
                std::string jsframe = "document.getElementById('vframe').src='" + yewtubesrc + "';";
                Wt::log("notice") << " VideoImpl::getVideo() jsframe = " << jsframe << " ";
                this->doJavaScript(jsframe);
            }
        }
        else
        {
        #ifdef WVIDEO
            if (!player)
            {
                // Create Video Player
                player = new Wt::WVideo(items_);
            }
            else
            {
                player->clearSources();
            }
            if (!mp4Video.empty())
            {
                player->addSource(mp4Video);
            }
            if (!ogvVideo.empty())
            {
                player->addSource(ogvVideo);
            }
            if (!poster.empty())
            {
                player->setPoster(poster);
                player->setAlternativeContent(new Wt::WImage(poster));
            }
            player->resize(width, height);
        #else
            //
            //Wt::WApplication::instance()-> useStyleSheet(Wt::WApplication::resourcesUrl() + "jPlayer/skin/blue.monday/jplayer.blue.monday.css");
            //Wt::WApplication::instance()-> useStyleSheet(Wt::WApplication::resourcesUrl() + "jPlayer/skin/pink.flag/jplayer.pink.flag.css");
            //
            // Create Video Player
            if (!player)
            {
                player = new Wt::WMediaPlayer(Wt::WMediaPlayer::Video, items_);
            }
            else
            {
                player->clearSources();
            }
            if (!mp4Video.empty())
            {
                player->addSource(Wt::WMediaPlayer::M4V, Wt::WLink(mp4Video));
            }
            if (!ogvVideo.empty())
            {
                player->addSource(Wt::WMediaPlayer::OGV, Wt::WLink(ogvVideo));
            }
            if (!poster.empty())
            {
                player->addSource(Wt::WMediaPlayer::PosterImage, Wt::WLink(poster));
            }
            if (!title.empty())
            {
                player->setTitle(title);
            }
            player->setVideoSize(width, height);
        #endif
        } // end if (playVideo->isutube)
        if (isPageBottom)
        {
            if (!isTextPageBottom) // not working if (!TextPageBottom)
            {
                TextPageBottom = new Wt::WText(pageBottomSrc, Wt::XHTMLUnsafeText, items_);
                TextPageBottom->setStyleClass("pagebottom");
                isTextPageBottom = true;
            }
            else
            {
                std::string jsPageBottom = "document.getElementById('pagebottomframe').src='" + pageBottom + "';";
                Wt::log("notice") << " VideoImpl::getVideo() jsPageBottom = " << jsPageBottom << " ";
                this->doJavaScript(jsPageBottom);
            } // end if (!TextPageTop)
        } // end if (isPageTop)
        #ifdef USE_TEMPLATE
            videoTemplate->bindWidget("videocombobinder", ComboVideo);
        #endif
        // Commit Transaction
        t.commit();
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "VideoImpl::getVideo: Failed reading from video database";
        Wt::log("error") << "VideoImpl::getVideo()  Failed reading from video database";
    }
    SetCookie("videomancat", categoryPath);
    SetCookie("videomanvideo", videoText);
    SetCookie("videomanquery", categoryQuery);
    Wt::log("end") << " ** VideoImpl::getVideo() ** ";
} // end void VideoImpl::GetVideo()
/* ****************************************************************************
 * Category Combo Changed
 */
void VideoImpl::CategoryComboChanged()
{
    isComboChange = true;
    //videoCombo->setCurrentIndex(0);
    // Make sure we want to update URL
    if (!isChanged)
    {
        categoryQuery = GetCategories("|");
        videoText = ""; // delete video, set index 0
        Wt::log("notice") << "-> VideoImpl::CategoryComboChanged() # Categories: " << std::to_string(numberCats) << " : categoryQuery = __" << categoryQuery << "__";
        CreateVideoCombobox();
    }
} // end void VideoImpl::CategoryComboChanged()
/* ****************************************************************************
 * Video Combo Changed
 */
void VideoImpl::VideoComboChanged()
{
    Wt::log("start") << " *** VideoImpl::VideoComboChanged() *** ";
    // videoIndex = videoCombo->currentIndex();
    // Make sure we want to update URL
    if (!isChanged)
    {
        Wt::log("notice") << "-> VideoImpl::VideoComboChanged() currentIndex = " << std::to_string(ComboVideo->currentIndex()) << " ";
        videoText = ComboVideo->currentText().toUTF8();
        GetVideo();
    }
} // end void VideoImpl::VideoComboChanged()
/* ****************************************************************************
 * Get Categories
 * delimitor: | = categoryQuery, / category Path
 * categoryType catType,
 */
std::string VideoImpl::GetCategories(std::string delimitor)
{
    if (!isComboCategory_0)
    {
        return ""; // combo boxes not set yet
    }
    std::string newCategory = "";
    try
    {
        switch (numberCats)
        {
            case 0:
                // FIXIT only uses video combobox
                newCategory = "";
                break;
            case 1:
                if (ComboCategory_0)
                {
                    newCategory = categoryText_0 = ComboCategory_0->currentText().toUTF8(); // Change categoryPath
                }
                else
                {
                    // get cookie
                }
                break;
            case 2:
                if (ComboCategory_0)
                {
                    if (ComboCategory_1)
                    {
                        newCategory = ComboCategory_0->currentText().toUTF8() + delimitor + ComboCategory_1->currentText().toUTF8();
                    }
                }
                break;
            case 3:
                if (ComboCategory_0)
                {
                    if (ComboCategory_1)
                    {
                        if (ComboCategory_2)
                        {
                            newCategory = ComboCategory_0->currentText().toUTF8() + delimitor + ComboCategory_1->currentText().toUTF8() + delimitor + ComboCategory_2->currentText().toUTF8();
                        }
                    }
                }
                break;
            case 4:
                if (ComboCategory_0)
                {
                    if (ComboCategory_1)
                    {
                        if (ComboCategory_2)
                        {
                            if (ComboCategory_3)
                            {
                                newCategory = ComboCategory_0->currentText().toUTF8() + delimitor + ComboCategory_1->currentText().toUTF8() + delimitor + ComboCategory_2->currentText().toUTF8() + delimitor + ComboCategory_3->currentText().toUTF8();
                            }
                        }
                    }
                }
                break;
            case 5:
                if (ComboCategory_0)
                {
                    if (ComboCategory_1)
                    {
                        if (ComboCategory_2)
                        {
                            if (ComboCategory_3)
                            {
                                if (ComboCategory_4)
                                {
                                    newCategory = ComboCategory_0->currentText().toUTF8() + delimitor + ComboCategory_1->currentText().toUTF8() + delimitor + ComboCategory_2->currentText().toUTF8() + delimitor + ComboCategory_3->currentText().toUTF8() + delimitor + ComboCategory_4->currentText().toUTF8();
                                }
                            }
                        }
                    }
                }
                break;
            case 6:
                if (ComboCategory_0)
                {
                    if (ComboCategory_1)
                    {
                        if (ComboCategory_2)
                        {
                            if (ComboCategory_3)
                            {
                                if (ComboCategory_4)
                                {
                                    if (ComboCategory_5)
                                    {
                                        newCategory = ComboCategory_0->currentText().toUTF8() + delimitor + ComboCategory_1->currentText().toUTF8() + delimitor + ComboCategory_2->currentText().toUTF8() + delimitor + ComboCategory_3->currentText().toUTF8() + delimitor + ComboCategory_4->currentText().toUTF8() + delimitor + ComboCategory_5->currentText().toUTF8();
                                    }
                                }
                            }
                        }
                    }
                }
                break;
        }
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "VideoImpl::CreateCategoryCombo: Failed reading Categories: ";
        Wt::log("error") << "VideoImpl::GetCategories()  Failed reading Categories: ";
    }
    return newCategory;
} // end std::string VideoImpl::GetCategories(std::string delimitor)
/* ****************************************************************************
 * Get Categories Path
 * Contains first Category or Video
 * /video/cat-1/cat-2/cat-3/video-1
 * or
 * /video/video-1
 */
bool VideoImpl::GetCategoriesPath()
{
    Wt::log("start") << " *** VideoImpl::GetCategoriesPath() ***";
    // Create an instance of app to access Internal Paths
    Wt::WApplication* app = Wt::WApplication::instance();
    if (!app->internalPathMatches(basePath_))
    {
        return false;
    }
    bool isInternalPathLegal=false;
    ClearCategories();
    categoryText_0 = app->internalPathNextPart(basePath_); // /en/video/
    Wt::log("notice") << " <<<< VideoImpl::GetCategoriesPath() categoryText_0 = " << categoryText_0;
    // Check each step of the Path and assign it to a variable, and set categoryQuery and videoText
    if (!categoryText_0.empty())
    {
        categoryText_1 = app->internalPathNextPart(basePath_ + categoryText_0 + "/");                 // Contains first Category or Video
        if (!categoryText_1.empty())
        {
            categoryText_2 = app->internalPathNextPart(basePath_ + categoryText_1 + "/");             // Contains second Category or Video
            if (!categoryText_2.empty())
            {
                categoryText_3 = app->internalPathNextPart(basePath_ + categoryText_2 + "/");         // Contains third Category or Video
                if (!categoryText_3.empty())
                {
                    categoryText_4 = app->internalPathNextPart(basePath_ + categoryText_3 + "/");     // Contains forth Category or Video
                    if (!categoryText_4.empty())
                    {
                        categoryText_5 = app->internalPathNextPart(basePath_ + categoryText_4 + "/"); // Contains fith Category or Video
                        if (!categoryText_5.empty())
                        {
                            videoText = app->internalPathNextPart(basePath_ + categoryText_5 + "/");  // Contains sixth Video
                            if (!videoText.empty())
                            {
                                categoryQuery = categoryText_0 + "|" + categoryText_1 + "|" + categoryText_2 + "|" + categoryText_3 + "|" + categoryText_4 + "|" + categoryText_5;
                                categoryPath  = categoryText_0 + "/" + categoryText_1 + "/" + categoryText_2 + "/" + categoryText_3 + "/" + categoryText_4 + "/" + categoryText_5;
                                videoText = categoryText_5;
                                categoryText_5 = "";
                                if (numberCats == 5)
                                {
                                    isInternalPathLegal = true;
                                }
                                Wt::log("notice") << "1 ->>>>>>> VideoImpl::GetCategoriesPath() categoryText_3 = " << categoryText_3 << " | categoryText_4 = " << categoryText_4 << " | videoText = " << videoText << " <<<<<-";
                            }
                            else
                            {
                                categoryQuery = categoryText_0 + "|" + categoryText_1 + "|" + categoryText_2 + "|" + categoryText_3 + "|" + categoryText_4;
                                categoryPath  = categoryText_0 + "/" + categoryText_1 + "/" + categoryText_2 + "/" + categoryText_3 + "/" + categoryText_4;
                                videoText = categoryText_5;
                                categoryText_5 = "";
                                if (numberCats == 4)
                                {
                                    isInternalPathLegal = true;
                                }
                                Wt::log("notice") << "1.5 ->>>>>>> VideoImpl::GetCategoriesPath() categoryText_3 = " << categoryText_3 << " | categoryText_4 = " << categoryText_4 << " | videoText = " << videoText << " <<<<<-";
                            }
                        } // if (!categoryText_5.empty())
                        else
                        {
                            categoryQuery = categoryText_0 + "|" + categoryText_1 + "|" + categoryText_2 + "|" + categoryText_3 + "|" + categoryText_4;
                            categoryPath  = categoryText_0 + "/" + categoryText_1 + "/" + categoryText_2 + "/" + categoryText_3 + "/" + categoryText_4;
                            videoText = categoryText_5;
                            categoryText_5 = "";
                            if (numberCats == 4)
                            {
                                isInternalPathLegal = true;
                            }
                            Wt::log("notice") << "2 ->>>>>>> VideoImpl::GetCategoriesPath() categoryText_3 = " << categoryText_3 << " | categoryText_4 = " << categoryText_4 << " | videoText = " << videoText << " <<<<<-";
                        }
                    } // if (!categoryText_4.empty())
                    else
                    {
                        categoryQuery = categoryText_0 + "|" + categoryText_1 + "|" + categoryText_2 + "|" + categoryText_3;
                        categoryPath  = categoryText_0 + "/" + categoryText_1 + "/" + categoryText_2 + "/" + categoryText_3;
                        videoText     = categoryText_4;
                        categoryText_4 = "";
                        if (numberCats == 3)
                        {
                            isInternalPathLegal = true;
                        }
                        Wt::log("notice") << "3 ->>>>>>> VideoImpl::GetCategoriesPath() categoryText_2 = " << categoryText_2 << " | categoryText_3 = " << categoryText_3 << " | videoText = " << videoText << " <<<<<-";
                    }
                } // if (!categoryText_3.empty())
                else
                {
                    categoryQuery = categoryText_0 + "|" + categoryText_1 + "|" + categoryText_2;
                    categoryPath  = categoryText_0 + "/" + categoryText_1 + "/" + categoryText_2;
                    videoText     = categoryText_3;
                    categoryText_3 = "";
                    if (numberCats == 2)
                    {
                        isInternalPathLegal = true;
                    }
                    Wt::log("notice") << "4 ->>>>>>> VideoImpl::GetCategoriesPath() categoryText_1 = " << categoryText_1 << " | categoryText_2 = " << categoryText_2 << " | videoText = " << videoText << " <<<<<-";
                }
            } // if (!categoryText_2.empty())
            else
            {
                categoryPath = categoryQuery = categoryText_0;
                videoText = categoryText_1;
                categoryText_1 = "";
                if (numberCats == 1)
                {
                    isInternalPathLegal = true;
                }
                Wt::log("notice") << "5 ->>>>>>> VideoImpl::GetCategoriesPath() categoryText_0 = " << categoryText_0  << "categoryText_1 = " << categoryText_1  << " | videoText = " << videoText << " <<<<<-";
            }
        } // end if (!categoryText_1.empty())
        else
        {
            videoText = categoryText_1;
            categoryText_1 = "";
            if (numberCats == 0)
            {
                isInternalPathLegal = true;
            }
            Wt::log("notice") << "6 ->>>>>>> VideoImpl::GetCategoriesPath() categoryText_0 = " << categoryText_0 << " | videoText = " << videoText << " <<<<<-";
        }
    } // end if (!categoryText_0.empty())
    else
    {
        videoText = categoryText_0;
        categoryText_0 = "";
        Wt::log("notice") << "7 ->>>>>>> VideoImpl::GetCategoriesPath() videoText = " << videoText << " <<<<<-";
    }
    // Check to see if path is legal for number of Categories
    switch (numberCats)
    {
        case 0:
            if (!categoryText_0.empty()) // Nothing Legal:
            {
                ClearCategories();
                videoText = "";
                isInternalPathLegal=false;
            }
            break;
        case 1:
            if (categoryText_0.empty())  // Nothing Legal: cat-0
            {
                ClearCategories();
                videoText = "";
                isInternalPathLegal=false;
            }
            break;
        case 2:
            if (categoryText_1.empty())  // Nothing Legal: cat-0|cat-1
            {
                ClearCategories();
                videoText = "";
                isInternalPathLegal=false;
            }
            if (!categoryText_2.empty())  // Nothing Legal: cat-0|cat-1
            {
                ClearCategories();
                videoText = "";
                isInternalPathLegal=false;
            }
            break;
        case 3:
            if (categoryText_2.empty())  // Nothing Legal: cat-0|cat-1|cat-2
            {
                ClearCategories();
                videoText = "";
                isInternalPathLegal=false;
            }
            if (!categoryText_3.empty())  // Nothing Legal: cat-0|cat-1|cat-2
            {
                ClearCategories();
                videoText = "";
                isInternalPathLegal=false;
            }
            break;
        case 4:
            if (categoryText_3.empty())  // Nothing Legal: cat-0|cat-1|cat-2|cat-3
            {
                ClearCategories();
                videoText = "";
                isInternalPathLegal=false;
            }
            if (!categoryText_4.empty())  // Nothing Legal: cat-0|cat-1|cat-2|cat-3
            {
                ClearCategories();
                videoText = "";
                isInternalPathLegal=false;
            }
            break;
        case 5:
            if (categoryText_4.empty())  // Nothing Legal: cat-0|cat-1|cat-2|cat-3|cat-4
            {
                ClearCategories();
                videoText = "";
                isInternalPathLegal=false;
            }
            if (!categoryText_5.empty())  // Nothing Legal: cat-0|cat-1|cat-2|cat-3|cat-4
            {
                ClearCategories();
                videoText = "";
                isInternalPathLegal=false;
            }
            break;
        case 6:
            if (categoryText_5.empty())  // Nothing Legal: cat-0|cat-1|cat-2|cat-3|cat-4|cat-5
            {
                ClearCategories();
                videoText = "";
                isInternalPathLegal=false;
            }
            break;
    } // end switch (numberCats)
    //
    if (categoryPath.empty())
    {
        categoryPath = GetCategories("/");
        if (!categoryPath.empty())
        {
            categoryQuery = GetCategories("|");
            if (isComboVideo) // not working (ComboVideo)
            {
                videoText = ComboVideo->currentText().toUTF8();
            }
        }
        else
        {
            std::string myCookieQuery = GetCookie("videomanquery");
            std::string myCookieCat   = GetCookie("videomancat");
            std::string myCookieVideo = GetCookie("videomanvideo");
            if (!myCookieCat.empty())
            {
                categoryQuery = myCookieQuery;
                categoryPath = myCookieCat;
                videoText = myCookieVideo;
                Wt::log("notice") << "VideoImpl::GetCategoriesPath() read cookie: categoryPath = " << categoryPath  << " | categoryQuery = " << categoryQuery << " | videoText = __" << videoText << "__";
            }
        }
    } // end if (categoryPath.empty())
    if (!videoText.empty())
    {
        isInternalPathLegal = true;
    }
    Wt::log("end") << "->>>>>>> VideoImpl::GetCategoriesPath() categoryPath = " << categoryPath << " | categoryQuery = " << categoryQuery << " | videoText = " << videoText << " <<<<<-";
    return isInternalPathLegal;
} // end bool VideoImpl::GetCategoriesPath()
/* ****************************************************************************
 * handle Path Change
 */
void VideoImpl::HandlePathChange(const std::string& path)
{
    Wt::log("start") << " *** VideoImpl::HandlePathChange(path: " << path << ") | isChanged = " << isChanged << " | basePath_ = " << basePath_ << " *** "; // /video/1/1
    // set categoryQuery
    GetCategoriesPath();
    // get app for internal paths
    Wt::WApplication *app = wApp;
    if (app->internalPathMatches(basePath_)) // /en/video/
    {
        Wt::log("notice") << "<<<<<<<<<<<<<<<<<<<<<<< VideoImpl::HandlePathChange() basePath_ match ";
        if (!isChanged) // if we are not changing path in another function
        {
            std::string newCategory = GetCategories("|"); // check comboboxes
            if (categoryQuery == newCategory) // Has Path Changed -
            {
                if (videoText != ComboVideo->currentText().toUTF8())
                {
                    videoText = ComboVideo->currentText().toUTF8();
                    GetVideo();
                } // end if (videoText != ComboVideo->currentText().toUTF8())
            } // end if (categoryQuery == newCategory)
            newCategory = GetCategories("|"); // check comboboxes
            if (path != newCategory)
            {
                Wt::log("notice") << "<<<<<<<<<<<<<<<<<<<<<<< VideoImpl::HandlePathChange() Change Internal Path ";
                if (isComboVideo) // not working (ComboVideo)
                {
                    videoText = ComboVideo->currentText().toUTF8();
                }
                Wt::WApplication::instance()->setInternalPath(basePath_ + newCategory + "/" + videoText, true);
            }
        } // end if (!isChanged)
    }
    Wt::log("end") << " ** VideoImpl::HandlePathChange() ** ";
} // end void VideoImpl::HandlePathChange(const std::string& path)
/* ****************************************************************************
 * set Internal Base Path
 */
void VideoImpl::SetInternalBasePath(const std::string& basePath)
{
    basePath_ = basePath;
    refresh();
} // end void VideoImpl::SetInternalBasePath
/* ****************************************************************************
 * refresh
 */
void VideoImpl::refresh()
{
    //HandlePathChange(wApp->internalPath());
} // end void VideoImpl::refresh()
/* ****************************************************************************
 * Clear Categories
 */
void VideoImpl::ClearCategories()
{
    videoText      = "";
    categoryPath   = "";
    categoryQuery  = "";
    categoryText_0 = "";
    categoryText_1 = "";
    categoryText_2 = "";
    categoryText_3 = "";
    categoryText_4 = "";
    categoryText_5 = "";
} // end void VideoImpl::ClearCategories()
#endif // VIDEOMAN
// --- End Of File ------------------------------------------------------------
