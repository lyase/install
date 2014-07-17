/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
//#include <fstream>
//#include <iostream>

//#include <boost/lexical_cast.hpp>
//#include <boost/tokenizer.hpp>
#include <boost/algorithm/string.hpp>

//#include <Wt/WAnchor>
//#include <Wt/WMessageBox>
//#include <Wt/Test/WTestEnvironment>
//#include <Wt/WPushButton>
//#include <Wt/WTabWidget>
//#include <Wt/WTable>
//#include <Wt/WTableCell>
//#include <Wt/WVBoxLayout>
//#include <Wt/WFlashObject>
#include <algorithm>
#include <Wt/WApplication>
#include <Wt/WEnvironment>
#include <Wt/WLogger>

#include <Wt/WLineEdit>
#include <Wt/WMenu>
#include <Wt/WNavigationBar>
#include <Wt/WPopupMenu>
#include <Wt/WPopupMenuItem>

#include <Wt/WStackedWidget>
#include <Wt/WTemplate>
#include <Wt/WText>
#include <Wt/WViewWidget>
//#include <Wt/WVideo>
//#include <Wt/WMediaPlayer>
//#include <Wt/WImage>
#include <Wt/WBootstrapTheme>
#include <Wt/WComboBox>
//
#ifdef BLOGMAN
    #include "BlogRSSFeed.h"
    #include "model/BlogSession.h"
    #include "model/Token.h"
    #include "model/User.h"
    #include "view/BlogView.h"
#endif // BLOGMAN
//
#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_utils.hpp"

//#include <QXmlStreamReader>
#include <QDebug>
//#include <QString>
//#include <QFile>

//#include <Wt/Dbo/SqlConnectionPool>

#include "HomeBase.h"
#include "SimpleChat.h"
#ifdef VIDEOMAN
    #include "view/VideoView.h"
    #include "view/VideoImpl.h"
#endif
#include "view/HitView.h"
//#include "WittyWizard.h"
/* ****************************************************************************
 * default Language
 */
const std::string defaultLanguage = "en";
const int defaultLanguageIndex    = 0;
/* ****************************************************************************
 * Global Variable - Set in main.cpp
 * root Prefix: Used to set the URL Path: http:domain.tdl\prefix\root-path
 * See Wt Documenation on: --deploy-path=
 */
extern std::string rootPrefix;
/* ****************************************************************************
 * Connection Pool Map
 * Holds the Pointer to Wt::Dbo::SqlConnectionPool *
 */
extern std::map <std::string, boost::any> myConnectionPool;
/* ****************************************************************************
 * Global Variable - Set in main.cpp
 * Full Path to Domain: /home/domain.tdl/
 */
extern std::map <std::string, std::string> myDomainPath;
/* ****************************************************************************
 * Global Variable - Set in main.cpp
 * See domain.xml: gasAccount="pub-xxxxxxxxxxxx"
 * http://www.google.com/adsense/
 */
extern std::map <std::string, std::string> myGasAccount;
/* ****************************************************************************
 * Global Variable - Set in main.cpp
 * Google Analytic Account: See domain.xml: gaAccount="UA-xxxxxxxx-x"
 * http://google.com/analytics/
 */
extern std::map <std::string, std::string> myGaAccount;
/* ****************************************************************************
 * Global Variable - Set in main.cpp
 * myIncludes: Each Menu
 * See domain.xml:includes="home|chat|blog|about|contact|video"
 */
extern std::map <std::string, std::string> myIncludes;
/* ****************************************************************************
 * Global Variable
 * See domain.xml:defaultTheme="blue"
 */
extern std::map <std::string, std::string> myDefaultTheme;
/* ****************************************************************************
 * Global functions
 */
extern bool isFile(const std::string& name);
extern bool isPath(const std::string& pathName);
/* ************************************************************************* */
/*! \class Home
 *  \brief Virtual Base Class
 */
Home::Home(const Wt::WEnvironment& env) : Wt::WApplication(env), homePage_(0)
{
    Wt::log("start") << " *** Home::Home() env.hostName() = " << env.hostName().c_str() << " *** ";
    myHost = env.hostName().c_str();       // localhost:8088
    myUrlScheme = env.urlScheme().c_str(); // http or https
    myBaseUrl = myUrlScheme + "://" + myHost + "/"; // FIXIT
    domainName = env.hostName().c_str();
    unsigned pos = domainName.find(":");
    if (pos > 0)
    {
        domainName = domainName.substr(0, pos);
    }
    // this is just for testing multiple sites in a localhost nated network
    if (0) domainName = "wittywizard.org";
    if (0) domainName = "lightwizzard.com";
    if (0) domainName = "vetshelpcenter.com";
    #if defined(BLOGMAN) || defined(VIDEOMAN)
    //
    if (!SetSqlConnectionPool(domainName))
    {
        Wt::log("error") << "(Home::Home: SetSqlConnectionPool failed for domain: " << domainName << ")";
        // FIXIT make this a error page
        return;
    }
    // connect to Connection Pool
    if(myConnectionPool.find(domainName) == myConnectionPool.end())
    {
        // element not found;
        Wt::log("error") << "Home::Home() myConnectionPool element not found " << domainName << "";
        return;
    }
    try
    {
        dbConnection_ = boost::any_cast<Wt::Dbo::SqlConnectionPool *>(myConnectionPool[domainName]);
    }
    catch (...)
    {
        Wt::log("error") << "->>> Home::Home() Failed Connection Pool " << domainName << "<<<-";
        return;
    }
    #endif // BLOGMAN || VIDEOMAN
    //
    if (!isFile(appRoot() + "home/" + domainName + "/ww-home.xml"))
    {
        Wt::log("error") << "**** Home::Home() missing file: " <<  appRoot() + "home/" + domainName + "/ww-home.xml" << "****";
    }
    messageResourceBundle().use(appRoot() + "home/" + domainName + "/ww-home", false);
    // Fix if it should use local copy of themes
    useStyleSheet(Wt::WApplication::resourcesUrl() + "css/wittywizard.css");
    useStyleSheet(Wt::WApplication::resourcesUrl() + "css/wittywizard_ie.css", "lt IE 7"); // "." +
    // Debug to see what path is returned in settings
    if (1)
    {
        Wt::log("notice") << "Home::Home: (resourcesUrl(): " << resourcesUrl() << ")"; // /resources/
        Wt::log("notice") << "Home::Home: (appRoot(): " << appRoot() << ")";           // ./app_root/
        Wt::log("notice") << "Home::Home: (docRoot(): " << docRoot() << ")";           // ./doc_root
    }
    //useStyleSheet("css/chatwidget.css");
    //useStyleSheet("css/chatwidget_ie6.css", "lt IE 7");
    //setCssTheme("polished");
    // Theme: Not to be confused with wittywizard theme
    #ifdef THEME3
        Wt::WBootstrapTheme *bootstrapTheme = new Wt::WBootstrapTheme();
        bootstrapTheme->setVersion(Wt::WBootstrapTheme::Version3);
        setTheme(bootstrapTheme);
        // load the default bootstrap3 (sub-)theme
        // Fix if it should use local copy of themes
        //useStyleSheet(Wt::WApplication::resourcesUrl() + "themes/bootstrap/3/bootstrap-theme.min.css");
    #elif THEME2
        Wt::WBootstrapTheme *bootstrapTheme = new Wt::WBootstrapTheme();
        bootstrapTheme->setVersion(Wt::WBootstrapTheme::Version2);
        setTheme(bootstrapTheme);
        // load the default bootstrap2 (sub-)theme
        // Fix if it should use local copy of themes
        useStyleSheet(Wt::WApplication::resourcesUrl() + "themes/bootstrap/2/bootstrap-theme.min.css");
    #else
        setTheme(new Wt::WBootstrapTheme());
    #endif
    // Fix if it should use local copy of themes, std::string cssPath = "";
    useStyleSheet(Wt::WApplication::resourcesUrl() + "style/everywidget.css");
    useStyleSheet(Wt::WApplication::resourcesUrl() + "style/dragdrop.css");
    useStyleSheet(Wt::WApplication::resourcesUrl() + "style/combostyle.css");
    useStyleSheet(Wt::WApplication::resourcesUrl() + "style/pygments.css");
    // Set Title
    // Fix needs to be per page
    //setTitle(MyCmsDomain.MyTitle);
    // Set Locale
    setLocale("");
} // end Home::Home
/* ****************************************************************************
 * Destructor ~Home
 */
Home::~Home()
{

} // end Home::~Home()
/* ****************************************************************************
 * init
 */
void Home::Init()
{
    Wt::log("start") << " *** Home::Init() *** ";
    ReInit();
    // Set Lanuage From Path
    SetLanguageFromPath();
    // now set call backs
    internalPathChanged().connect(this, &Home::SetLanguageFromPath);
    internalPathChanged().connect(this, &Home::LogInternalPath);
} // end void Home::Init()
/* ****************************************************************************
 * Reinit
 */
void Home::ReInit()
{
    Wt::log("start") << " *** Home::ReInit() *** ";
    // Set Base URL
    SetBaseURL();
    // Clear the Screen
    root()->clear();
    // Create Home Page
    CreateHome();
    // Add Home Page to root
    root()->addWidget(homePage_);
} // end void Home::ReInit()
/* ****************************************************************************
 * Set Base URL
 * URL Schema: http or https + Root Prefix defined in deploy-path + Language Code
 */
void Home::SetBaseURL()
{
    myBaseUrl = myUrlScheme + "://" + myHost + "/" + rootPrefix + "/" + languages[GetDefaultLanguage()].name_ + "/";
} // end void Home::SetBaseURL
/* ****************************************************************************
 * Create Home
 * Set up menu
 */
void Home::CreateHome()
{
    Wt::WTemplate* homeTemplate = new Wt::WTemplate(Wt::WString::tr("template"), root()); // in ww-home.xml -> <message id="template">
    homePage_ = homeTemplate; // not sure why I need this
    homeTemplate_ = homeTemplate;
    //
    Wt::WStackedWidget* contents = new Wt::WStackedWidget();
    Wt::WAnimation fade(Wt::WAnimation::Fade, Wt::WAnimation::Linear, 250);
    contents->setTransitionAnimation(fade);
    contents->setId("main_page");
    // Create a navigation bar with a link to a web page.
    Wt::WNavigationBar *navigation = new Wt::WNavigationBar(contents);
    //navigation->setId("navigation");
    //navigation->setTitle("Witty Wizard", "http://www.google.com/search?q=witty+wizard");
    navigation->setTitle(Wt::WString::tr("title"));
    //navigation->setResponsive(true); // caused it to be collapsable

    Wt::WStackedWidget *contentsStack = new Wt::WStackedWidget(contents);
    //contentsStack->setId("contents");
    //contentsStack->addStyleClass("contents");

    // Setup a Left-aligned menu.
    mainMenu_ = new Wt::WMenu(contentsStack, contents);
    //mainMenu_->setId("mainmenu");
    //mainMenu_->setStyleClass("mainmenu");
    navigation->addMenu(mainMenu_);
    // FIXIT
    Wt::WText *searchResult = new Wt::WText(Wt::WString::tr("search"));
    // FIXIT
    //QString includeThis = myIncludes[domainName];
    //includeThis.split("|")
    // "|home|chat|blog|about|contact|video|"
    mainMenu_->addItem(Wt::WString::tr("home"),  HomePage())->setPathComponent("");
    std::string theIncludes = myIncludes[domainName];
    Wt::log("notice") << "Home::CreateHome:  theIncludes=" << theIncludes;

    #ifdef BLOGMAN
        if (theIncludes.find("|blog|") != std::string::npos)
        {
            mainMenu_->addItem(Wt::WString::tr("blog"),  deferCreate(boost::bind(&Home::Blog, this))); // http://localhost:8088/?_=/blog or http://localhost:8088/blog
        }
    #endif // BLOGMAN
    if (theIncludes.find("|chat|") != std::string::npos)
    {
        mainMenu_->addItem(Wt::WString::tr("chat"),  deferCreate(boost::bind(&Home::Chat, this))); //
    }
    // Make sure you can completly remove any module, this goes for blog or chat also
    #ifdef VIDEOMAN
        if (theIncludes.find("|video|") != std::string::npos)
        {
            mainMenu_->addItem(Wt::WString::tr("video"), deferCreate(boost::bind(&Home::VideoMan, this)));
        }
        // FIXIT add Menu Options for all videos
    #endif // VIDEOMAN
    if (theIncludes.find("|contact|") != std::string::npos)
    {
        mainMenu_->addItem(Wt::WString::tr("contact"), deferCreate(boost::bind(&Home::Contact, this)));
    }
    if (theIncludes.find("|about|") != std::string::npos)
    {
        mainMenu_->addItem(Wt::WString::tr("about"),   deferCreate(boost::bind(&Home::About, this)));
    }
    //mainMenu_->addItem("Search", searchResult);

    // Setup a Right-aligned menu.
    Wt::WMenu *rightMenu = new Wt::WMenu();
    //rightMenu->setId("rightmenu");
    navigation->addMenu(rightMenu, Wt::AlignRight);

    // Create a Language popup submenu for the Language Menu.
    Wt::WPopupMenu *languagePopup = new Wt::WPopupMenu();
    for (unsigned i = 0; i < languages.size(); ++i)
    {
        // Get Language
        const Lang& l = languages[i];
        // Add Popup Item with Description.
        Wt::WMenuItem *mi = languagePopup->addItem(Wt::WString::fromUTF8(l.longDescription_));
        mi->triggered().connect(boost::bind(&Home::HandleLanguagePopup, this, i));
        Wt::log("info") << " <<< Home::CreateHome() set Language -> " << l.longDescription_;
    }
    // Language Popdown
    Wt::WMenuItem *item = new Wt::WMenuItem(Wt::WString::tr("language"));
    // Add Language Popup to Menu
    item->setMenu(languagePopup);
    rightMenu->addItem(item);

    // Create a Theme popup submenu for the Theme Menu.
    Wt::WPopupMenu *themePopup = new Wt::WPopupMenu();
    for (unsigned i = 0; i < themes.size(); ++i)
    {
        // Get Theme
        const Theme& t = themes[i];
        // Add Popup Item with Description.
        Wt::WMenuItem *mit = themePopup->addItem(Wt::WString::fromUTF8(t.name_));
        mit->triggered().connect(boost::bind(&Home::HandleThemePopup, this, i));
        // Wt::log("notice") << " <<<<<<<<<<<<<<< Home::CreateHome() themes " << t.name_ << " >>>>>>>>>>>>>>>>>>>>> ";
    }
    // Theme Popdown
    Wt::WMenuItem *themeItem = new Wt::WMenuItem(Wt::WString::tr("theme"));
    // Add Theme Popup to Menu
    themeItem->setMenu(themePopup);
    rightMenu->addItem(themeItem);

    // Add a Search control.
    Wt::WLineEdit *searchText = new Wt::WLineEdit();
    searchText->setEmptyText(Wt::WString::tr("search"));

    searchText->enterPressed().connect(std::bind([=] ()
    {
        // FIXIT add a real search feature
        mainMenu_->select(4); // is the index a random menu item
        searchResult->setText(Wt::WString("Nothing found for {1}.").arg(searchText->text()));
    }));

    navigation->addSearch(searchText, Wt::AlignRight);

    contents->addWidget(contentsStack);

    // On Select
    mainMenu_->itemSelectRendered().connect(this, &Home::UpdateTitle);
    mainMenu_->itemSelected().connect(this, &Home::googleAnalyticsLogger);
    // Make the menu be internal-path aware.
    mainMenu_->setInternalPathEnabled("/"); // Not sure about this, should it be /en/ ?
    // Bind to Template
    //result->bindWidget("menu", mainMenu_);
    homeTemplate->bindWidget("menu", navigation);
    homeTemplate->bindWidget("contents", contents);
    // Banner
    std::string myBannerSource = Wt::WString::tr("banner-source").toUTF8();
    std::string myBannerAlt = Wt::WString::tr("banner-alt").toUTF8();
    Wt::WText* banner;
    if (!myBannerSource.empty())
    {
        banner = new Wt::WText("<img src='" + myBannerSource + "' alt='" + myBannerAlt + "'>", Wt::XHTMLUnsafeText);
    }
    else
    {
        banner = new Wt::WText("");
    }
    // CopyRight
    Wt::WText* copyright = new Wt::WText("<a href='" + myBaseUrl + "'>" + Wt::WString::tr("copyright") + "</a>", Wt::XHTMLUnsafeText); // FIXIT add copyright page to CMS
    // Footer Menu
    Wt::WText* footermenu = new Wt::WText("<a href='" + myBaseUrl + "'>" + Wt::WString::tr("home") + "</a> | <a href='" + myBaseUrl + "contact'>" + Wt::WString::tr("contact") + "</a>", Wt::XHTMLUnsafeText);
    // Google Analytics
    Wt::WText* ga = new Wt::WText("<script>/*<![CDATA[*/(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)})(window,document,'script','//www.google-analytics.com/analytics.js','ga');ga('create', '" + myGaAccount[domainName] + "', '" + myHost + "');ga('send', 'pageview');/* ]]> */</script>", Wt::XHTMLUnsafeText);
    //
    homeTemplate->bindWidget("banner", banner);
    homeTemplate->bindWidget("copyright", copyright);
    homeTemplate->bindWidget("footermenu", footermenu);
    homeTemplate->bindWidget("ga", ga);
    homeTemplate->bindWidget("hitcounter", HitCounter());
    /*
    sideBarContent_ = new WContainerWidget();
    result->bindWidget("sidebar", sideBarContent_);
    */
} // end void Home::CreateHome
/* ****************************************************************************
 * Hit Counter
 */
Wt::WWidget* Home::HitCounter()
{
    HitView* hitCounter = new HitView(*dbConnection_, languages[GetDefaultLanguage()].code_);
    hitCounter->setObjectName("hitcounter");
    //
    return hitCounter->Update();
} // end Wt::WWidget* Home::HitCounter
/* ****************************************************************************
 * Handle Language Popup
 * data: passed in as a index into languages
 * assumes path: /lang
 */
void Home::HandleLanguagePopup(int data)
{
    Wt::log("start") << " *** Home::HandleLanguagePopup(data: " << data << ") language_ = " << language_ << " *** ";
    if (language_ == data) { return; } // Nothing to do
    std::string languagePath = internalPathNextPart("/"); // Checks First path element, its allows the Language: en, ru, cn
    std::string thePath = internalPath(); // will always be /lang...
    // We must replace the Old Lanuage First
    if (!StringReplace(thePath, languagePath, languages[data].name_))
    {
        Wt::log("error") << "Home::HandleLanguagePopup(Error in String Replace " << ")";
    }
    Wt::log("notice") << " *** Home::HandleLanguagePopup(data: " << data << ") set thePath = " << thePath << " *** ";
    //
    Wt::WApplication::instance()->setInternalPath(thePath,  true);
    //SetLanguageFromPath();
    Wt::log("end") << " *** Home::HandleLanguagePopup(data: " << data << ") *** ";
} // end void Home::HandleLanguagePopup
/* ****************************************************************************
 * set Theme
 */
void Home::HandleThemePopup(int data)
{
    Wt::log("start") << " *** Home::HandleThemePopup(data: " << data << ") *** ";
    SetWizardTheme(false, data);
} // end void Home::HandleThemePopup
/* ****************************************************************************
 * Set Theme
 */
void Home::SetWizardTheme(bool fromCookie, int index)
{
    Wt::log("start") << " *** Home::SetWizardTheme(FromCookie: " << "data: " << index << ") *** ";
    std::string myTheme;
    if (fromCookie)
    {
        myTheme = GetCookie("theme");
        if (myTheme.empty())
        {
            myTheme = myDefaultTheme[domainName];
        }
    }
    else
    {
        myTheme = themes[index].name_;
    }
    if (!myTheme.empty())
    {
        // page or Wt-inline-css document.getElementById('wittywizardstylesheet').href='new_css.css';  style.property
        // + myBaseUrl
        // FIXIT check for legal path
        std::string jsCss = "document.getElementById('wittywizardstylesheet').href='" + Wt::WApplication::resourcesUrl() + "themes/wittywizard/" + myTheme + "/ww-" + myTheme + ".css';";
        this->doJavaScript(jsCss);
        SetCookie("theme", myTheme);
        SetCookie("themepath", Wt::WApplication::resourcesUrl() + "themes/wittywizard/");
        useStyleSheet(Wt::WApplication::resourcesUrl() + "themes/wittywizard/" + myTheme + "/ww-" + myTheme + ".css");
    }
} // end void Home::SetWizardTheme
/* ****************************************************************************
 * Set Language From Path
 * Path: prefix does not show up in path
 * Path: /language/module/...
 *
 * Fix video and other app paths
 */
void Home::SetLanguageFromPath()
{
    if (isPathChanging)
    {
        Wt::log("restart") << " ~~~~ Home::SetLanguageFromPath() returning nothing done ~~~~ ";
        return;
    }
    //
    std::string languageName = internalPathNextPart("/"); // Checks First Argument
    //
    std::string thePath = internalPath(); // begins with /
    // Get a Valid Language, returns default if not found
    const Lang& theLanguage = GetLanguage(languageName);
    languageName = theLanguage.name_;
    std::string newPath = "/" + languageName;
    //
    int newLanguage = GetLanguageIndex(languageName); // Set to default Language Index if not set
    //
    std::vector<std::string> parts;
    boost::split(parts, thePath, boost::is_any_of("/"));

    Wt::log("start") << " Home::SetLanguageFromPath() language_ = " << language_ << " | newLanguage = " << newLanguage;

    if (language_ != newLanguage)
    {
        Wt::log("start") << " Home::SetLanguageFromPath() Language Change ~ path = " << thePath << " | parts.size()=" << parts.size() << " | parts[0]=" << parts[0] << " | parts[1]=" << parts[1];
    }
    else
    {
        Wt::log("start") << " Home::SetLanguageFromPath() No Language Change ~ path = " << thePath << " | parts.size()=" << parts.size() << " | parts[0]=" << parts[0] << " | parts[1]=" << parts[1];
    }

    // path = /                      | parts.size()=2 | parts[0]= | parts[1]=
    // path = /en                    | parts.size()=2 | parts[0]= | parts[1]=en
    // path = /en/video/Series/Video | parts.size()=5 | parts[0]= | parts[1]=en | parts[2]=video | parts[3]=Series | parts[4]=Video

    std::string moduleName = "";
    if (parts.size() > 2)
    {
        moduleName = parts[2];
    }
    // If Language changed, make new Path
    if (language_ == newLanguage)
    {
        newPath = thePath;
    }
    else
    {
        for (unsigned i = 2; i < parts.size(); ++i)
        {
            newPath = newPath + "/" + parts[i];
        }
    }

    Wt::log("start") << " *** Home::SetLanguageFromPath() languageCode set to = " << languageName << " | internalPathNextPart = " << internalPathNextPart("/")  << " | newPath = " << newPath << " *** ";

    //
    isPathChanging = true;
    #ifdef VIDEOMAN
        VideoView *video;
        if (moduleName == "video")
        {
            video = dynamic_cast<VideoView *>(findWidget("video"));
            if (video)
            {
                if (language_ == newLanguage)
                {
                    Wt::log("notice") << " <<<<<<< Home::SetLanguageFromPath() menu is video do return." << " | thePath = " << thePath;
                    isPathChanging = false; // Set isPathChanging so SetLanguageFromPath will fire
                    return; // we do not want to handle changes: FIXIT find a way to make this generic
                }
            }
        }
    #endif
    if (language_ != newLanguage)
    {
        // Set Local
        setLocale(theLanguage.name_);
        //setLocale(theLanguage.code_);
    }
    //
    #ifdef BLOGMAN
    BlogView *blog = dynamic_cast<BlogView *>(findWidget("blog"));
    if (blog)
    {
        if (moduleName == "blog")
        {
            if (language_ != newLanguage)
            {
                Wt::log("notice") << "Home::SetLanguageFromPath() for blog " << languageName <<  " | newPath = " << newPath;
                blog->SetInternalBasePath("/" + languageName + "/blog/");
            }
        }
    }
    #endif // BLOGMAN
    //
    #ifdef VIDEOMAN
    video = dynamic_cast<VideoView *>(findWidget("video"));
    if (video)
    {
        if (moduleName == "video")
        {
            if (language_ != newLanguage)
            {
                Wt::log("notice") << "Home::SetLanguageFromPath() for video " << languageName <<  " | newPath = " << newPath;
                video->SetInternalBasePath("/" + languageName + "/video/");
            }
        }
    }
    #endif
    UpdateTitle();
    if (language_ != newLanguage)
    {
        language_ = newLanguage; // Set language_ to current Language
        ReInit();
    }
    // Change Menu Base Path
    mainMenu_->setInternalBasePath(theLanguage.name_);
    // Change Path
    Wt::WApplication::instance()->setInternalPath(newPath, true);
    //
    homeTemplate_->bindWidget("hitcounter", HitCounter());
    // Set Theme
    SetWizardTheme(true, 0);
    Wt::log("end") << "Home::SetLanguageFromPath()";
    isPathChanging = false; // Set isPathChanging so SetLanguageFromPath will fire
} // end void Home::SetLanguageFromPath
/* ****************************************************************************
 * IsPathLanguage
 * langPath: pass in first path string
 * return -1 if not found, else return index of Language
 */
int Home::IsPathLanguage(std::string langPath)
{
    int foundLanguageIndex = -1;
    for (unsigned i = 0; i < languages.size(); ++i)
    {
        if (languages[i].name_ == langPath)
        {
            foundLanguageIndex = i;
            Wt::log("notice") << " *** Home::IsPathLanguage() langPath = " << langPath << " found at " << i << " ***"; // en, cn, ru ...
            break;
        }
    }
    return foundLanguageIndex;
} // end Home::IsPathLanguage
/* ****************************************************************************
 * GetLanguageIndex
 */
int Home::GetLanguageIndex(std::string languageName)
{
    int newLanguageIndex = IsPathLanguage(languageName);
    if (newLanguageIndex == -1)
    {
        newLanguageIndex = defaultLanguageIndex;
    }
    return newLanguageIndex;
} // end Home::GetLanguageIndex
/* ****************************************************************************
 * GetLanguage
 */
const Lang& Home::GetLanguage(std::string languageName)
{
    return languages[GetLanguageIndex(languageName)];
} // end Home::GetLanguage
/* ****************************************************************************
 * GetDefaultLanguage
 */
int Home::GetDefaultLanguage()
{
    int newLanguageIndex = language_;
    if (newLanguageIndex == -1)
    {
        newLanguageIndex = defaultLanguageIndex;
    }
    return newLanguageIndex;
} // end Home::GetDefaultLanguage
/* ****************************************************************************
 * Update Title
 */
void Home::UpdateTitle()
{
    if (mainMenu_->currentItem())
    {
        setTitle(Wt::WString::tr("page.title") + " - " + mainMenu_->currentItem()->text());
    }
} // end void Home::UpdateTitle
/* ****************************************************************************
 * Log Internal Path
 */
void Home::LogInternalPath(const std::string& path)
{
    // simulate an access log for the interal paths
    Wt::log("start") << " *** Home::LogInternalPath(" << path << ") *** ";
} // end void Home::LogInternalPath
/* ****************************************************************************
 * Home Page
 */
Wt::WWidget* Home::HomePage()
{
    return new Wt::WText(Wt::WString::tr("home.intro"));
} // end Wt::WWidget *Home::HomePage
/* ****************************************************************************
 * Contact
 */
Wt::WWidget *Home::Contact()
{
    return new Wt::WText(Wt::WString::tr("home.contact"));
} // end Wt::WWidget *Home::Contact
/* ****************************************************************************
 * About
 */
Wt::WWidget *Home::About()
{
    return new Wt::WText(Wt::WString::tr("home.about"));
} // end Wt::WWidget *Home::About
/* ****************************************************************************
 * blog
 */
#ifdef BLOGMAN
Wt::WWidget *Home::Blog()
{
    const Lang& l = languages[language_];
    std::string langPath = l.name_;
    std::string defaultTheme = myDefaultTheme[domainName];
    // FIXIT: do I add language, then add a resource for each language?
    BlogView* blog = new BlogView("/" + langPath + "/blog/", appRoot() + "home/" + domainName + "/", *dbConnection_, "/" + rootPrefix + "/blog/feed/", defaultTheme);
    blog->setObjectName("blog");

    if (!blog->user().empty())
    {
        ChatSetUser(blog->user());
    }
    blog->userChanged().connect(this, &Home::ChatSetUser);

    return blog;
} // end Wt::WWidget *Home::Blog
#endif // BLOGMAN
/* ****************************************************************************
 * Video Manager
 * myAppRoot: Path to video.xml
 * Internal Path
 * debase Connection
 */
#ifdef VIDEOMAN
Wt::WWidget *Home::VideoMan()
{
    //
    Wt::log("start") << " *** Home::VideoMan() internalPath = " << internalPath();
    const Lang& l = languages[language_];
    std::string langPath = l.name_;
    VideoView* thisVideo = new VideoView(appRoot() + "home/" + domainName + "/video/", "/" + langPath + "/video/", *dbConnection_, l.code_);
    thisVideo->setObjectName("video");
    Wt::log("end") << " *** Home::VideoMan()";
    return thisVideo;
} // end Wt::WWidget *Home::VideoMan
#endif // VIDEOMAN
/* ****************************************************************************
 * Admin
 */
Wt::WWidget* Home::Admin()
{
    return new Wt::WText(Wt::WString::tr("admin"));
} // end void Home::Admin
/* ****************************************************************************
 * chat
 */
Wt::WWidget *Home::Chat()
{
    return new Wt::WText(Wt::WString::tr("chatter"));

    Wt::WContainerWidget *result = new Wt::WContainerWidget();

    //ChatApplication chatWidget = new ChatApplication(Wt::WApplication.environment, Wt::WApplication.environment.server);
    //chatWidget->setStyleClass("chat");

   // Wt::WServer *server_ = new WApplication.environment.server();


    //SimpleChatWidget *chatWidget = new SimpleChatWidget(Wt::WApplication.environment.server, root());
    //chatWidget->setStyleClass("chat");

    //new ChatApplication(myEnv, chatServer);

    //SimpleChatServer chatServer(this->root());
    //server.addEntryPoint(Wt::Application, boost::bind(createApplication, _1, boost::ref(chatServer)));
    // ChatWidget::createWidget();
    //root()->addWidget(new WText(WString::tr("chatter")));

    //SimpleChatWidget *chatWidget2 = new SimpleChatWidget(ChatApplication::server_, root());
    //chatWidget2->setStyleClass("chat");

    //root()->addWidget(new WText(WString::tr("details")));

    //return chatWidget2;

    //    ChatApplication::ChatApplication *myChat = new ChatApplication::ChatApplication(root(), "");
    //    return myChat;
    return result;
} // end Wt::WWidget *Home::chat
/* ****************************************************************************
 * chat Set User
 */
void Home::ChatSetUser(const Wt::WString& userName)
{
    Wt::WApplication::instance()->doJavaScript
            ("if (window.chat && window.chat.emit) {"
             """try {"
             ""  "window.chat.emit(window.chat, 'login', "
             ""                    "" + userName.jsStringLiteral() + "); "
             """} catch (e) {"
             ""  "window.chatUser=" + userName.jsStringLiteral() + ";"
             """}"
             "} else "
             """window.chatUser=" + userName.jsStringLiteral() + ";");
} // end void Home::chatSetUser
/* ****************************************************************************
 * wrap View
 */
Wt::WWidget *Home::WrapView(Wt::WWidget *(Home::*createWidget)())
{
    return makeStaticModel(boost::bind(createWidget, this));
} // end Wt::WWidget *Home::wrapView
/* ****************************************************************************
 * href
 */
std::string Home::href(const std::string& url, const std::string& description)
{
    return "<a href=\"" + url + "\" target=\"_blank\">" + description + "</a>";
} // end std::string Home::href
/* ****************************************************************************
 * google Analytics Logger
 */
void Home::googleAnalyticsLogger()
{
    std::string googleCmd =
            "if (window.pageTracker) {"
            """try {"
            ""  "setTimeout(function() {"
            ""  "window.pageTracker._trackPageview(\""
            + environment().deploymentPath() + internalPath() + "\");"
            ""  "}, 1000);"
            """} catch (e) { }"
            "}";

    doJavaScript(googleCmd);
} // end void Home::googleAnalyticsLogger
// --- End Of File ------------------------------------------------------------
