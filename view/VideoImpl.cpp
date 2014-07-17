/* ****************************************************************************
 * Witty Wizard
 * Video Manager
 * Version: 1.0.0
 * Last Date Modified: 15 July 2014
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
#include <Wt/WViewWidget>
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
#include <QDebug>
#include <boost/algorithm/string.hpp>

#include "view/VideoImpl.h"
//#include "VideoView.h"
#include "model/VideoSession.h"
#include "model/TheVideo.h"
#include "WittyWizard.h"
/* ****************************************************************************
 * Global Variable
 * See domain.xml:defaultTheme="blue"
 */
extern std::map <std::string, std::string> myDefaultTheme;
/* ****************************************************************************
 * Global functions
 */
extern bool isFile(const std::string& name);
/* ****************************************************************************
 * Video Impl
 * This gets called every time the page is refreshed
 * appPath: /full-path/app_root/home/domainName/video/videoman
 * basePath: /en/video/
 * connectionPool: dbo
 * lang: en, cn, ru ...
 */
VideoImpl::VideoImpl(const std::string& appPath, const std::string& basePath, Wt::Dbo::SqlConnectionPool& connectionPool, const std::string& lang) : appPath_(appPath), basePath_(basePath), session_(appPath, connectionPool), lang_(lang), videoPage_(0)
{
    items_ = new Wt::WContainerWidget(this);
    items_->setId("videocan");
    //
    bindItems = new Wt::WContainerWidget(this);
    bindItems->setId("videomanbinder");
    //Wt::WApplication *app = Wt::WApplication::instance();
    Wt::WApplication *app = wApp;
    domainName = app->environment().hostName().c_str();
    unsigned pos = domainName.find(":");
    if (pos > 0)
    {
        domainName = domainName.substr(0, pos);
    }
    // FIXIT Do we want to use our own Template or use a common Template?
    // /full-path/app_root/home/domainName/video/videoman.xml
    if (1 && !isFile(appPath + "videoman.xml")) { Wt::log("error") << " *** VideoImpl::VideoImpl() Themeplate Not Found: " << appPath + "videoman.xml" << " *** "; }
    app->messageResourceBundle().use(appPath + "videoman"); // ./app_root/ Wt::WApplication::appRoot()
    videoTemplate = new Wt::WTemplate(Wt::WString::tr("videoman-template"), this); //  <message id="videoman-template">
    videoPage_ = videoTemplate;

    Wt::log("start") << " *** VideoImpl::VideoImpl() lang = " << lang << " | domainName = " << domainName << " | appPath = " << appPath << " *** ";

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
    // Set Category and Video from Internal Path, ComboBox or Cookie
    GetCategoriesPath();
    // Clear all the WContainerWidget Items
    items_->clear();
    //
    CreateCategoryCombo();
    //
    CreateVideoCombobox();
    //
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
            //Wt::log("notice") << "VideoImpl::CreateCategoryCombo:  const_iterator = " << (*i)->categories;
            // Category List: cat-0|cat-1|cat-2|cat-3...
            // Currently only testing 1 category
            // @FIXIT test
            std::string myCategoriesSchema = (*i)->categories;
            std::vector<std::string> categoryFields;
            boost::split(categoryFields, myCategoriesSchema, boost::is_any_of("|"));
            //
            if (myCategoriesSchema.empty())
            {
                numberCats = 0;
            }
            else
            {
                //numberCats = myCategoriesSchema.contains('|') + 1;
                numberCats = std::count(myCategoriesSchema.begin(), myCategoriesSchema.end(), '_') + 1;
            }
            //Wt::log("notice") << "VideoImpl::CreateCategoryCombo:  numberCats = " << numberCats;
            if (numberCats > 1)
            {
                    int catSize = categoryFields.size();
                    if (catSize > 1)
                    {
                        // if I use (name of javascript concept where you name a variable like category_$x = 0; not a c concept) a categoryText_x where x is i, it becomes: categoryText_0 and assigns the correct value to it
                        for (int catIndex = 0; catIndex < catSize; catIndex++)
                        {
                            switch(catIndex)
                            {
                                case 0:
                                    //categoryText_0 = categoryFields.at(catIndex).toStdString();
                                    categoryText_0 = categoryFields[catIndex];
                                    break;
                                case 1:
                                    //categoryText_1 = categoryFields.at(catIndex).toStdString();
                                    categoryText_1 = categoryFields[catIndex];
                                    break;
                                case 2:
                                    //categoryText_2 = categoryFields.at(catIndex).toStdString();
                                    categoryText_2 = categoryFields[catIndex];
                                    break;
                                case 3:
                                    //categoryText_3 = categoryFields.at(catIndex).toStdString();
                                    categoryText_3 = categoryFields[catIndex];
                                    break;
                                case 4:
                                    //categoryText_4 = categoryFields.at(catIndex).toStdString();
                                    categoryText_4 = categoryFields[catIndex];
                                    break;
                                case 5:
                                    //categoryText_5 = categoryFields.at(catIndex).toStdString();
                                    categoryText_5 = categoryFields[catIndex];
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
                    categoriesQueryName = myCategoriesSchema; // cat-0
                    if (ComboCategory_0 == NULL) // this does not work reliable
                    {
                        Wt::log("notice") << "VideoImpl::CreateCategoryCombo:  new ComboCategory_0 WComboBox";
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    // Find it
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
                    if (ComboCategory_0 == NULL)
                    {
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_1 == NULL)
                    {
                        ComboCategory_1 = new Wt::WComboBox(items_);
                        ComboCategory_1->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    // Find it
                    if (ComboCategory_0->findText(categoryText_0) == -1)
                    {
                        ComboCategory_0->addItem(categoryText_0); // it did not exist, add it
                    }
                    if (categoryFields[0] == categoryText_0)
                    {
                        ComboCategory_0->setCurrentIndex(ComboCategory_0->findText(categoryText_0));
                    }
                    if (ComboCategory_1->findText(categoryText_1) == -1)
                    {
                        ComboCategory_1->addItem(categoryText_1); // it did not exist, add it
                    }
                    if (categoryFields[1] == categoryText_1)
                    {
                        ComboCategory_1->setCurrentIndex(ComboCategory_1->findText(categoryText_1));
                    }
                    break;
                case 3:
                    if (ComboCategory_0 == NULL)
                    {
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_1 == NULL)
                    {
                        ComboCategory_1 = new Wt::WComboBox(items_);
                        ComboCategory_1->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_2 == NULL)
                    {
                        ComboCategory_2 = new Wt::WComboBox(items_);
                        ComboCategory_2->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    // Find it
                    if (ComboCategory_0->findText(categoryText_0) == -1)
                    {
                        ComboCategory_0->addItem(categoryText_0); // it did not exist, add it
                    }
                    if (categoryFields[0] == categoryText_0)
                    {
                        ComboCategory_0->setCurrentIndex(ComboCategory_0->findText(categoryText_0));
                    }
                    if (ComboCategory_1->findText(categoryText_1) == -1)
                    {
                        ComboCategory_1->addItem(categoryText_1); // it did not exist, add it
                    }
                    if (categoryFields[1] == categoryText_1)
                    {
                        ComboCategory_1->setCurrentIndex(ComboCategory_1->findText(categoryText_1));
                    }
                    if (ComboCategory_2->findText(categoryText_2) == -1)
                    {
                        ComboCategory_2->addItem(categoryText_2); // it did not exist, add it
                    }
                    if (categoryFields[2] == categoryText_2)
                    {
                        ComboCategory_2->setCurrentIndex(ComboCategory_2->findText(categoryText_2));
                    }
                    break;
                case 4:
                    if (ComboCategory_0 == NULL)
                    {
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_1 == NULL)
                    {
                        ComboCategory_1 = new Wt::WComboBox(items_);
                        ComboCategory_1->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_2 == NULL)
                    {
                        ComboCategory_2 = new Wt::WComboBox(items_);
                        ComboCategory_2->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_3 == NULL)
                    {
                        ComboCategory_3 = new Wt::WComboBox(items_);
                        ComboCategory_3->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    // Find it
                    if (ComboCategory_0->findText(categoryText_0) == -1)
                    {
                        ComboCategory_0->addItem(categoryText_0); // it did not exist, add it
                    }
                    if (categoryFields[0] == categoryText_0)
                    {
                        ComboCategory_0->setCurrentIndex(ComboCategory_0->findText(categoryText_0));
                    }
                    if (ComboCategory_1->findText(categoryText_1) == -1)
                    {
                        ComboCategory_1->addItem(categoryText_1); // it did not exist, add it
                    }
                    if (categoryFields[1] == categoryText_1)
                    {
                        ComboCategory_1->setCurrentIndex(ComboCategory_1->findText(categoryText_1));
                    }
                    if (ComboCategory_2->findText(categoryText_2) == -1)
                    {
                        ComboCategory_2->addItem(categoryText_2); // it did not exist, add it
                    }
                    if (categoryFields[2] == categoryText_2)
                    {
                        ComboCategory_2->setCurrentIndex(ComboCategory_2->findText(categoryText_2));
                    }
                    if (ComboCategory_3->findText(categoryText_3) == -1)
                    {
                        ComboCategory_3->addItem(categoryText_3); // it did not exist, add it
                    }
                    if (categoryFields[3] == categoryText_3)
                    {
                        ComboCategory_3->setCurrentIndex(ComboCategory_3->findText(categoryText_3));
                    }
                    break;
                case 5:
                    if (ComboCategory_0 == NULL)
                    {
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_1 == NULL)
                    {
                        ComboCategory_1 = new Wt::WComboBox(items_);
                        ComboCategory_1->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_2 == NULL)
                    {
                        ComboCategory_2 = new Wt::WComboBox(items_);
                        ComboCategory_2->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_3 == NULL)
                    {
                        ComboCategory_3 = new Wt::WComboBox(items_);
                        ComboCategory_3->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_4 == NULL)
                    {
                        ComboCategory_4 = new Wt::WComboBox(items_);
                        ComboCategory_4->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    // Find it
                    if (ComboCategory_0->findText(categoryText_0) == -1)
                    {
                        ComboCategory_0->addItem(categoryText_0); // it did not exist, add it
                    }
                    if (categoryFields[0] == categoryText_0)
                    {
                        ComboCategory_0->setCurrentIndex(ComboCategory_0->findText(categoryText_0));
                    }
                    if (ComboCategory_1->findText(categoryText_1) == -1)
                    {
                        ComboCategory_1->addItem(categoryText_1); // it did not exist, add it
                    }
                    if (categoryFields[1] == categoryText_1)
                    {
                        ComboCategory_1->setCurrentIndex(ComboCategory_1->findText(categoryText_1));
                    }
                    if (ComboCategory_2->findText(categoryText_2) == -1)
                    {
                        ComboCategory_2->addItem(categoryText_2); // it did not exist, add it
                    }
                    if (categoryFields[2] == categoryText_2)
                    {
                        ComboCategory_2->setCurrentIndex(ComboCategory_2->findText(categoryText_2));
                    }
                    if (ComboCategory_3->findText(categoryText_3) == -1)
                    {
                        ComboCategory_3->addItem(categoryText_3); // it did not exist, add it
                    }
                    if (categoryFields[3] == categoryText_3)
                    {
                        ComboCategory_3->setCurrentIndex(ComboCategory_3->findText(categoryText_3));
                    }
                    if (ComboCategory_4->findText(categoryText_4) == -1)
                    {
                        ComboCategory_4->addItem(categoryText_4); // it did not exist, add it
                    }
                    if (categoryFields[4] == categoryText_4)
                    {
                        ComboCategory_4->setCurrentIndex(ComboCategory_4->findText(categoryText_4));
                    }
                    break;
                case 6:
                    if (ComboCategory_0 == NULL)
                    {
                        ComboCategory_0 = new Wt::WComboBox(items_);
                        ComboCategory_0->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_1 == NULL)
                    {
                        ComboCategory_1 = new Wt::WComboBox(items_);
                        ComboCategory_1->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_2 == NULL)
                    {
                        ComboCategory_2 = new Wt::WComboBox(items_);
                        ComboCategory_2->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_3 == NULL)
                    {
                        ComboCategory_3 = new Wt::WComboBox(items_);
                        ComboCategory_3->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_4 == NULL)
                    {
                        ComboCategory_4 = new Wt::WComboBox(items_);
                        ComboCategory_4->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    if (ComboCategory_5 == NULL)
                    {
                        ComboCategory_5 = new Wt::WComboBox(items_);
                        ComboCategory_5->activated().connect(this, &VideoImpl::CategoryComboChanged);
                    }
                    // Find it
                    if (ComboCategory_0->findText(categoryText_0) == -1)
                    {
                        ComboCategory_0->addItem(categoryText_0); // it did not exist, add it
                    }
                    if (categoryFields[0] == categoryText_0)
                    {
                        ComboCategory_0->setCurrentIndex(ComboCategory_0->findText(categoryText_0));
                    }
                    if (ComboCategory_1->findText(categoryText_1) == -1)
                    {
                        ComboCategory_1->addItem(categoryText_1); // it did not exist, add it
                    }
                    if (categoryFields[1] == categoryText_1)
                    {
                        ComboCategory_1->setCurrentIndex(ComboCategory_1->findText(categoryText_1));
                    }
                    if (ComboCategory_2->findText(categoryText_2) == -1)
                    {
                        ComboCategory_2->addItem(categoryText_2); // it did not exist, add it
                    }
                    if (categoryFields[2] == categoryText_2)
                    {
                        ComboCategory_2->setCurrentIndex(ComboCategory_2->findText(categoryText_2));
                    }
                    if (ComboCategory_3->findText(categoryText_3) == -1)
                    {
                        ComboCategory_3->addItem(categoryText_3); // it did not exist, add it
                    }
                    if (categoryFields[3] == categoryText_3)
                    {
                        ComboCategory_3->setCurrentIndex(ComboCategory_3->findText(categoryText_3));
                    }
                    if (ComboCategory_4->findText(categoryText_4) == -1)
                    {
                        ComboCategory_4->addItem(categoryText_4); // it did not exist, add it
                    }
                    if (categoryFields[4] == categoryText_4)
                    {
                        ComboCategory_4->setCurrentIndex(ComboCategory_4->findText(categoryText_4));
                    }
                    if (ComboCategory_5->findText(categoryText_5) == -1)
                    {
                        ComboCategory_5->addItem(categoryText_5); // it did not exist, add it
                    }
                    if (categoryFields[5] == categoryText_5)
                    {
                        ComboCategory_5->setCurrentIndex(ComboCategory_5->findText(categoryText_5));
                    }
                    break;
            } // end switch (numberCats)
            //Wt::log("notice") << " VideoImpl::CreateCategoryCombo() numberCats = " << numberCats << " : name = " << mySchema.toStdString() << " ";
        } // end for (TheVideos::const_iterator i = videos.begin(); i != videos.end(); ++i)
        // Commit Transaction
        t.commit();
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
        categoryQuery = GetCategories("/");
        Wt::log("error") << " *** VideoImpl::CreateVideoCombobox() empty categoryQuery = __" << categoryQuery << "__ | lang_ = " << lang_ << " *** ";
    }
    else
    {
        Wt::log("start") << " *** VideoImpl::CreateVideoCombobox() categoryQuery = __" << categoryQuery << "__ *** ";
    }
    try
    {
        Wt::Dbo::QueryModel< Wt::Dbo::ptr<TheVideo> > *model = new Wt::Dbo::QueryModel< Wt::Dbo::ptr<TheVideo> >();
        // FIXIT language  AND language = " + lang_
        //model->setQuery(session_.query< Wt::Dbo::ptr<TheVideo> >("select u from video u").where("categories = ? AND language = ?").bind(categoryQuery).bind(lang_), false);
        model->setQuery(session_.query< Wt::Dbo::ptr<TheVideo> >("select u from video u").where("categories = ?").bind(categoryQuery).where("language = ?").bind(lang_), false);
        //model->setQuery(session_.query< Wt::Dbo::ptr<TheVideo> >("select u from video u").where("categories = ?").bind(categoryQuery), false);
        model->addColumn("name");
        // ComboVideo has not been set
        if (ComboVideo == NULL)
        {
            ComboVideo = new Wt::WComboBox(items_);
            isChanged = true;
            ComboVideo->activated().connect(this, &VideoImpl::VideoComboChanged);
            isChanged = false;
            Wt::log("notice") << "VideoImpl::CreateVideoCombobox()  new ComboBox";
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
    // check cookie
    Wt::log("start") << " *** VideoImpl::GetVideo() ~ videoText = {" << videoText << "} | numberCats = " << numberCats << " | lang_ = " << lang_ << " | ComboCategory_0 = " << ComboCategory_0->currentText().toUTF8() << " *** ";
    // clear all variables
    mp4Video = "";
    ogvVideo = "";
    poster = "";
    title = "";
    //Wt::WViewWidget()
    std::string myTheme = GetCookie("theme");
    if (myTheme.empty())
    {
        myTheme = myDefaultTheme[domainName];
    }
    try
    {
        if (videoText.empty())
        {
            videoText = ComboVideo->currentText().toUTF8();
            Wt::log("warning") << "VideoImpl::getVideo()  set empty videoText path = " << ComboCategory_0->currentText().toUTF8() << "/" << videoText  << " | count = " << ComboVideo->count() << " ";
        }
        else
        {
            isChanged = true;
            ComboVideo->setCurrentIndex(ComboVideo->findText(videoText));
            if (ComboVideo->currentIndex() == -1)
            {
                ComboVideo->setCurrentIndex(0); // Not found, set it to the first Video
                videoText = ComboVideo->currentText().toUTF8(); // Reset the videoText to new text, this should be an old video link, missing, renamed or deleted video
            }
            Wt::log("info") << "VideoImpl::getVideo() Find videoText {"  << videoText << "} | ComboVideo = " << " | " << ComboVideo->currentText().toUTF8()  << " | count = " << ComboVideo->count() <<  " ";
            isChanged = false;
        }
    }
    catch (std::exception& e)
    {
        std::cerr << e.what() << std::endl;
        std::cerr << "VideoImpl::getVideo: videoText.empty";
        Wt::log("error") << "(VideoImpl::getVideo:  videoText.empty)";
    }
    //
    try
    {
        // Start a Transaction
        Wt::Dbo::Transaction t(session_);
        //Wt::Dbo::QueryModel< Wt::Dbo::ptr<TheVideo> > *model = new Wt::Dbo::QueryModel< Wt::Dbo::ptr<TheVideo> >();
        //model->setQuery(session_.query< Wt::Dbo::ptr<TheVideo> >("select u from video u").where("name = ?").bind(videoCombo->currentText().toUTF8()), false);
        //Wt::Dbo::ptr<TheVideo> playVideo = session_.find<TheVideo>().where("name = ? AND language = ?").bind(ComboVideo->currentText().toUTF8()).bind(lang_);
        Wt::Dbo::ptr<TheVideo> playVideo = session_.find<TheVideo>().where("name = ?").bind(ComboVideo->currentText().toUTF8()).where("language = ?").bind(lang_);
        //Wt::Dbo::ptr<TheVideo> playVideo = session_.find<TheVideo>().where("name = ?").bind(ComboVideo->currentText().toUTF8());
        // Set Text for Top iFrame
        if (playVideo->pagetop.empty())
        {
            TextPageTopIframe = Wt::WString::Empty;
        }
        else
        {
            TextPageTopIframe = "<div id='vpagetop' class='vpagetop' style='width:" + (playVideo->pagetopwidth.empty() ? defaultPageTopWidth : playVideo->pagetopwidth) + ";height:" + (playVideo->pagetopheight.empty() ? defaultPageTopHeight : playVideo->pagetopheight) + ";'>" + playVideo->pagetop + "</div>";
        }

        /*
        if (!playVideo->pagebottomlink.empty())
        {

            //bottomPage = new Wt::WText("<div id='vpagebottomlink' class='vpagebottomlink' style='width:" + playVideo->pagebottomwidth + "; height:" + playVideo->pagebottomheight + ";'><iframe id='pagebottomframe' theme='" + myTheme + "' src='" + playVideo->pagebottomlink + "' style='width:" + playVideo->pagebottomwidth + "; height:" + playVideo->pagebottomheight + ";' frameBorder='1' scrolling='auto' ></iframe></div>", Wt::XHTMLUnsafeText, bindItems);
            //bottomPage = new Wt::WText("<div id='vpagebottomlink' class='vpagebottomlink' style='width:" + playVideo->pagebottomwidth + "; height:" + playVideo->pagebottomheight + ";'><iframe id='pagebottomframe' theme='" + myTheme + "' style='width:" + playVideo->pagebottomwidth + "; height:" + playVideo->pagebottomheight + ";' frameBorder='1' scrolling='auto' ></iframe></div>", Wt::XHTMLUnsafeText, bindItems);
            //bottomPage->setStyleClass("videomanbottompage");
        }
        */
        //
        if (playVideo->pagebottom.empty())
        {
            TextPageBottomIframe = Wt::WString::Empty;
        }
        else
        {
            //Wt::WString tempPage = Wt::WString::fromUTF8("<div id='vpagebottom' class='vpagebottom' style='width:" + playVideo->pagebottomwidth + ";height:" + playVideo->pagebottomheight + ";'>" + playVideo->pagebottom + "</div>");
            //Wt::log("error") << "VideoImpl::getVideo: set tempPage size = " << tempPage.size();
            //bottomPage =  new Wt::WText(Wt::WString::fromUTF8("<div id='vpagebottom' class='vpagebottom' style='width:" + playVideo->pagebottomwidth + ";height:" + playVideo->pagebottomheight + ";'>" + playVideo->pagebottom + "</div>"), Wt::XHTMLUnsafeText, bindItems);
            // bottomPage->setStyleClass("videomanbottompage");
            //pageBottom = playVideo->pagebottom;
            //TextPageBottomIframe = "<div id='vpagebottom' class='vpagebottom' style='width:" + pageBottomWidth + ";height:" + pageBottomHeight + ";'>" + playVideo->pagebottom + "</div>";
            TextPageBottomIframe = "<div id='vpagebottom' class='vpagebottom' style='width:" + (playVideo->pagebottomwidth.empty() ? defaultPageBottomWidth : playVideo->pagebottomwidth) + ";height:" + (playVideo->pagebottomheight.empty() ? defaultPageBottomHeight : playVideo->pagebottomheight) + ";'>" + playVideo->pagebottom + "</div>";
        }

        //
        if (!playVideo->isutube)
        {

            /* sizes="1080,720"
             *
             */
            std::vector <std::string> sizesFields;
            boost::split( sizesFields, playVideo->sizes, boost::is_any_of( "," ) );
            //
            size = sizesFields[0]; // FIXIT read from combobox
            int sizeCount = sizesFields.size();
            if (sizeCount > 1)
            {
                // Create a dropdown box
                if (!ComboSizes) // FIXIT test: does this work?
                {
                    ComboSizes = new Wt::WComboBox(items_);
                    Wt::log("notice") << "VideoImpl::GetVideo()  new ComboBox ComboSizes";
                }
                else
                {
                    size = ComboSizes->currentText().toUTF8();
                }
                ComboSizes->clear();
                for (int sizecnt = 0; sizecnt < sizeCount;sizecnt++)
                {
                    if (ComboSizes->findText(sizesFields[sizecnt]) == -1)
                    {
                        ComboSizes->addItem(sizesFields[sizecnt]); // it did not exist, add it
                    }
                    ComboSizes->setCurrentIndex(0);
                }
                size = sizesFields[0]; // FIXIT read from combobox
            }
            //  quality="hd,lq"
            std::vector <std::string> qualityFields;
            boost::split( qualityFields, playVideo->quality, boost::is_any_of( "," ) );
            int qualityCount = qualityFields.size();
            quality = qualityFields[0]; // fix read from combobox
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
                    if (ComboQuality->findText(qualityFields[qualitycnt]) == -1)
                    {
                        ComboQuality->addItem(qualityFields[qualitycnt]); // it did not exist, add it
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
        //
        if (playVideo->isutube)
        {
            TextYouTubeIframe = Wt::WString::fromUTF8("<div id='vplayer' class='vplayer'><br /><div id='yewtube' class='yewtube'><iframe id='vframe' src='" + playVideo->path + "' width='" + playVideo->width + "' height='" + playVideo->height + "' style='' frameBorder='0' scrolling='no' allowfullscreen='true'></iframe></div><br /></div>");
        }
        else
        {
            TextYouTubeIframe = Wt::WString::Empty;
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
            player->resize(std::stoi(playVideo->width), std::stoi(playVideo->height));
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
            player->setVideoSize(std::stoi(playVideo->width), std::stoi(playVideo->height));
        #endif
        } // end if (playVideo->isutube)
        //
        videoTemplate->bindWidget("catcombobinder-0", new Wt::WText(""));
        videoTemplate->bindWidget("catcombobinder-1", new Wt::WText(""));
        videoTemplate->bindWidget("catcombobinder-2", new Wt::WText(""));
        videoTemplate->bindWidget("catcombobinder-3", new Wt::WText(""));
        videoTemplate->bindWidget("catcombobinder-4", new Wt::WText(""));
        videoTemplate->bindWidget("catcombobinder-5", new Wt::WText(""));
        videoTemplate->bindWidget("videocombobinder", new Wt::WText(""));

        videoTemplate->bindWidget("videoman", WrapView(&VideoImpl::YouTubeContent));
        videoTemplate->bindWidget("videomanpagetop", WrapView(&VideoImpl::PageContentTop));
        videoTemplate->bindWidget("videomanpagebottom", WrapView(&VideoImpl::PageContentBottom));


        /*
        std::string jsPageBottom = "document.getElementById('pagebottomframe').src='" + playVideo->pagebottomlink + "';";
        Wt::log("notice") << " VideoImpl::getVideo() jsPageBottom = " << jsPageBottom << " ";
        this->doJavaScript(jsPageBottom);
        */

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
    // Set Internal Path to Video
    // FIXIT add set Cookie support
    isChanged = true;
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
    isChanged = false;
    currentVideoIndex = oldVideoIndex = ComboVideo->currentIndex();
    Wt::log("end") << " ** VideoImpl::getVideo() ** ";
} // end void VideoImpl::GetVideo()
/* ****************************************************************************
 * Page Content Top
 */
Wt::WWidget* VideoImpl::PageContentTop()
{
    WContainerWidget *result = new WContainerWidget();
    if (!TextPageTopIframe.empty())
    {
        Wt::WText *w = new Wt::WText(TextPageTopIframe, Wt::XHTMLUnsafeText, result);
        w->setInternalPathEncoding(true);
    }
    return result;
} // end PageContentTop
/* ****************************************************************************
 * Page Content Bottom
 */
Wt::WWidget* VideoImpl::PageContentBottom()
{
    WContainerWidget *result = new WContainerWidget();
    if (!TextPageBottomIframe.empty())
    {
        Wt::WText *w = new Wt::WText(TextPageBottomIframe, Wt::XHTMLUnsafeText, result);
        w->setInternalPathEncoding(true);
    }
    return result;
} // end PageContentBottom
/* ****************************************************************************
 * You Tube Content
 */
Wt::WWidget* VideoImpl::YouTubeContent()
{
    WContainerWidget *result = new WContainerWidget();
    if (!TextYouTubeIframe.empty())
    {
        Wt::WText *w = new Wt::WText(TextYouTubeIframe, Wt::XHTMLUnsafeText, result);
        w->setInternalPathEncoding(true);
    }
    return result;
} // end YouTubeContent
/* ****************************************************************************
 * Wrap View
 */
Wt::WWidget* VideoImpl::WrapView(Wt::WWidget *(VideoImpl::*createWidget)())
{
    return makeStaticModel(boost::bind(createWidget, this));
} // end WrapView
/* ****************************************************************************
 * Category Combo Changed
 */
void VideoImpl::CategoryComboChanged()
{
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
    Wt::log("start!!!!!!!!") << " *** VideoImpl::VideoComboChanged() *** currentVideoIndex = " << currentVideoIndex << " | oldVideoIndex = " << oldVideoIndex;
    // videoIndex = videoCombo->currentIndex();
    // Make sure we want to update URL
    currentVideoIndex = ComboVideo->currentIndex();
    if (!isChanged && currentVideoIndex != oldVideoIndex)
    {
        Wt::log("notice") << "-> VideoImpl::VideoComboChanged() currentIndex = " << std::to_string(ComboVideo->currentIndex()) << " ";
        videoText = ComboVideo->currentText().toUTF8();
        GetVideo();
    }
} // end void VideoImpl::VideoComboChanged()
/* ****************************************************************************
 * Get Categories from Catergory Combo
 * delimitor: | = categoryQuery, / category Path
 * categoryType catType,
 */
std::string VideoImpl::GetCategories(std::string delimitor)
{
    if (ComboCategory_0 == NULL)
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
                if (ComboCategory_0 != NULL)
                {
                    newCategory = categoryText_0 = ComboCategory_0->currentText().toUTF8(); // Change categoryPath
                }
                else
                {
                    // get cookie
                }
                break;
            case 2:
                if (ComboCategory_0 != NULL)
                {
                    if (ComboCategory_1 != NULL)
                    {
                        newCategory = ComboCategory_0->currentText().toUTF8() + delimitor + ComboCategory_1->currentText().toUTF8();
                    }
                }
                break;
            case 3:
                if (ComboCategory_0 != NULL)
                {
                    if (ComboCategory_1 != NULL)
                    {
                        if (ComboCategory_2 != NULL)
                        {
                            newCategory = ComboCategory_0->currentText().toUTF8() + delimitor + ComboCategory_1->currentText().toUTF8() + delimitor + ComboCategory_2->currentText().toUTF8();
                        }
                    }
                }
                break;
            case 4:
                if (ComboCategory_0 != NULL)
                {
                    if (ComboCategory_1 != NULL)
                    {
                        if (ComboCategory_2 != NULL)
                        {
                            if (ComboCategory_3 != NULL)
                            {
                                newCategory = ComboCategory_0->currentText().toUTF8() + delimitor + ComboCategory_1->currentText().toUTF8() + delimitor + ComboCategory_2->currentText().toUTF8() + delimitor + ComboCategory_3->currentText().toUTF8();
                            }
                        }
                    }
                }
                break;
            case 5:
                if (ComboCategory_0 != NULL)
                {
                    if (ComboCategory_1 != NULL)
                    {
                        if (ComboCategory_2 != NULL)
                        {
                            if (ComboCategory_3 != NULL)
                            {
                                if (ComboCategory_4 != NULL)
                                {
                                    newCategory = ComboCategory_0->currentText().toUTF8() + delimitor + ComboCategory_1->currentText().toUTF8() + delimitor + ComboCategory_2->currentText().toUTF8() + delimitor + ComboCategory_3->currentText().toUTF8() + delimitor + ComboCategory_4->currentText().toUTF8();
                                }
                            }
                        }
                    }
                }
                break;
            case 6:
                if (ComboCategory_0 != NULL)
                {
                    if (ComboCategory_1 != NULL)
                    {
                        if (ComboCategory_2 != NULL)
                        {
                            if (ComboCategory_3 != NULL)
                            {
                                if (ComboCategory_4 != NULL)
                                {
                                    if (ComboCategory_5 != NULL)
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
 * Get Categories Path from internal Path
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
    ClearCategories();
    std::string path = app->internalPath(); // /en/video/
    std::vector<std::string> parts;
    boost::split(parts, path, boost::is_any_of("/"));
    // path = /en/video/IAM/00-02-N-IAM | parts.size()=5 | parts[0]= | parts[1]=en | parts[2]=video | parts[3]=IAM | parts[4]=00-02-N-IAM
    // Wt::log("notice") << " @@@@@@@@@@ VideoImpl::GetCategoriesPath() path = " << path << " | parts.size()=" << parts.size() << " | parts[0]=" << parts[0] << " | parts[1]=" << parts[1] << " | parts[2]=" << parts[2] << " | parts[3]=" << parts[3] << " | parts[4]=" << parts[4];
    // 0 Categories 1 Video
    if (parts.size() == 4)
    {
        categoryText_0 = "";
        videoText      = parts[3];
        categoryQuery = "";
        categoryPath  = "";
    }
    // 1 Categories 1 Video
    if (parts.size() == 5)
    {
        categoryText_0 = parts[3];
        videoText      = parts[4];
        categoryQuery = categoryText_0;
        categoryPath  = categoryText_0;
    }
    // 2 Categories 1 Video
    if (parts.size() == 6)
    {
        categoryText_0 = parts[3];
        categoryText_1 = parts[4];
        videoText      = parts[5];
        categoryQuery = categoryText_0 + "|" + categoryText_1;
        categoryPath  = categoryText_0 + "/" + categoryText_1;
    }
    // 3 Categories 1 Video
    if (parts.size() == 7)
    {
        categoryText_0 = parts[3];
        categoryText_1 = parts[4];
        categoryText_2 = parts[5];
        videoText      = parts[6];
        categoryQuery = categoryText_0 + "|" + categoryText_1 + "|" + categoryText_2;
        categoryPath  = categoryText_0 + "/" + categoryText_1 + "/" + categoryText_2;
    }
    // 4 Categories 1 Video
    if (parts.size() == 8)
    {
        categoryText_0 = parts[3];
        categoryText_1 = parts[4];
        categoryText_2 = parts[5];
        categoryText_3 = parts[6];
        videoText      = parts[7];
        categoryQuery = categoryText_0 + "|" + categoryText_1 + "|" + categoryText_2 + "|" + categoryText_3;
        categoryPath  = categoryText_0 + "/" + categoryText_1 + "/" + categoryText_2 + "/" + categoryText_3;
    }
    // 5 Categories 1 Video
    if (parts.size() == 9)
    {
        categoryText_0 = parts[3];
        categoryText_1 = parts[4];
        categoryText_2 = parts[5];
        categoryText_3 = parts[6];
        categoryText_4 = parts[7];
        videoText      = parts[8];
        categoryQuery = categoryText_0 + "|" + categoryText_1 + "|" + categoryText_2 + "|" + categoryText_3 + "|" + categoryText_4;
        categoryPath  = categoryText_0 + "/" + categoryText_1 + "/" + categoryText_2 + "/" + categoryText_3 + "/" + categoryText_4;
    }
    // 6 Categories 1 Video
    if (parts.size() == 10)
    {
        categoryText_0 = parts[3];
        categoryText_1 = parts[4];
        categoryText_2 = parts[5];
        categoryText_3 = parts[6];
        categoryText_4 = parts[7];
        categoryText_5 = parts[8];
        videoText      = parts[9];
        categoryQuery = categoryText_0 + "|" + categoryText_1 + "|" + categoryText_2 + "|" + categoryText_3 + "|" + categoryText_4 + "|" + categoryText_5;
        categoryPath  = categoryText_0 + "/" + categoryText_1 + "/" + categoryText_2 + "/" + categoryText_3 + "/" + categoryText_4 + "/" + categoryText_5;
    }
    bool isInternalPathLegal=false;
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
    if (isChanged) { return; }
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
                if (ComboVideo != NULL) // not working (ComboVideo)
                {
                    videoText = ComboVideo->currentText().toUTF8();
                    Wt::WApplication::instance()->setInternalPath(basePath_ + newCategory + "/" + videoText, true);
                }
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
