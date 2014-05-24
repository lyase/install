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

#include "BlogRSSFeed.h"
#include "model/BlogSession.h"
#include "model/Token.h"
#include "model/User.h"

#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_utils.hpp"

//#include <QXmlStreamReader>
#include <QDebug>
//#include <QString>
//#include <QFile>

//#include <Wt/Dbo/SqlConnectionPool>

#include "HomeBase.h"
#include "view/BlogView.h"
#include "SimpleChat.h"
#ifdef VIDEOMAN
    #include "view/VideoView.h"
    #include "view/VideoImpl.h"
#endif
#include "WittyWizard.h"
/* ****************************************************************************
 * default Language
 */
const std::string defaultLanguage = "en";
const int defaultLanguageIndex    = 0;
/* ****************************************************************************
 * root Prefix: Used to set the URL Path: http:domain.tdl\prefix\root-path
 */
extern std::string rootPrefix;
/* ****************************************************************************
 * Map
 */
extern std::map <std::string, boost::any> myConnectionPool;
extern std::map <std::string, std::string> myRssFeed;
/* ************************************************************************* */
/*! \class Home
 *  \brief Virtual Base Class
 */
Home::Home(const Wt::WEnvironment& env) : Wt::WApplication(env), homePage_(0)
{

    Wt::log("start") << " *** Home::Home() env.hostName() = " << env.hostName().c_str() << " *** ";
    myHost = env.hostName().c_str(); // localhost:8088
    myUrlScheme = env.urlScheme().c_str(); // http or https
    myBaseUrl = myUrlScheme + "://" + myHost + "/";
    QString filePath = appRoot().c_str();
    filePath.append("domains.xml");
    domainName = env.hostName().c_str();
    unsigned pos = domainName.indexOf(":");
    if (pos > 0)
    {
        domainName = domainName.mid(0, pos);
    }
    // this is just for testing multiple sites in a localhost nated network
    if (0) domainName = "beta.wittywizard.org";
    if (0) domainName = "beta.lightwizzard.com";
    if (0) domainName = "beta.vetshelpcenter.com";
    if(myRssFeed.find(domainName.toStdString()) == myRssFeed.end())
    {
        // element not found;
        Wt::log("notice") << "(Home::Home: myRssFeed element not found " << domainName.toStdString() << ")";
        return;
    }
    std::string theFeeder = myRssFeed[domainName.toStdString()];

#ifdef REGX    
    QString theRssFeed = theFeeder.c_str();
    QRegExp rx("(\\t)"); // RegEx for ' ' or ',' or '.' or ':' or '\t'
    QStringList query = theRssFeed.split(rx);
    appPath_ = query[3]; // Fix enumerate
#else
    // I could do this with QString
    std::vector <std::string> fields;
    boost::split( fields, theFeeder, boost::is_any_of( "\t" ) );
    std::string myFeeder = fields.at(3);
    appPath_ = myFeeder.c_str(); // Fix enumerate
#endif    
    Wt::log("notice") << "Home::Home() appPath: " << appPath_.toStdString() << "";
    // connect to Connection Pool
    if(myConnectionPool.find(domainName.toStdString()) == myConnectionPool.end())
    {
        // element not found;
        Wt::log("error") << "Home::Home() myConnectionPool element not found " << domainName.toStdString() << "";
        return;
    }
    try
    {
        dbConnection_ = boost::any_cast<Wt::Dbo::SqlConnectionPool *>(myConnectionPool[domainName.toStdString()]);
    }
    catch (...)
    {
        Wt::log("error") << "->>> Home::Home() Failed Connection Pool " << domainName.toStdString() << "<<<-";
        return;
    }
    std::string mrPath(appPath_.toStdString() + "app_root/ww-home"); // Fix name
    messageResourceBundle().use(mrPath, false);
    // Fix if it should use local copy of themes
    useStyleSheet(Wt::WApplication::resourcesUrl() + "css/wittywizard.css");
    useStyleSheet(Wt::WApplication::resourcesUrl() + "css/wittywizard_ie.css", "lt IE 7"); // "." +
    // Debug to see what path is returned in settings
    if (0)
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
    // Set Lanuage to 0
    language_ = 0;
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
    Wt::log("start") << " *** Home::Setup() *** ";
    // Clear the Screen
    root()->clear();
    // Create Home Page
    CreateHome();
    // Add Home Page to root
    root()->addWidget(homePage_);
    // Set Lanuage From Path
    SetLanguageFromPath();
    // now set call backs
    internalPathChanged().connect(this, &Home::SetLanguageFromPath);
    internalPathChanged().connect(this, &Home::LogInternalPath);
} // end void Home::Init()
/* ****************************************************************************
 * Create Home
 * Set up menu
 */
void Home::CreateHome()
{
    Wt::WTemplate *result = new Wt::WTemplate(Wt::WString::tr("template"), root()); //  <message id="template">
    homePage_ = result;
    //
    Wt::WStackedWidget *contents = new Wt::WStackedWidget();
    Wt::WAnimation fade(Wt::WAnimation::Fade, Wt::WAnimation::Linear, 250);
    contents->setTransitionAnimation(fade);
    contents->setId("main_page");
    // Create a navigation bar with a link to a web page.
    Wt::WNavigationBar *navigation = new Wt::WNavigationBar(contents);
    navigation->setId("navigation");
    //navigation->setTitle("Witty Wizard", "http://www.google.com/search?q=witty+wizard");
    navigation->setTitle(Wt::WString::tr("title"));
    //navigation->setResponsive(true); // caused it to be collapsable

    Wt::WStackedWidget *contentsStack = new Wt::WStackedWidget(contents);
    //contentsStack->setId("contents");
    contentsStack->addStyleClass("contents");

    // Setup a Left-aligned menu.
    mainMenu_ = new Wt::WMenu(contentsStack, contents);
    mainMenu_->setId("mainmenu");
    mainMenu_->setStyleClass("mainmenu");
    navigation->addMenu(mainMenu_);
    // FIXIT
    Wt::WText *searchResult = new Wt::WText(Wt::WString::tr("search"));

    mainMenu_->addItem(Wt::WString::tr("home"),  HomePage())->setPathComponent("");
    mainMenu_->addItem(Wt::WString::tr("blog"),  deferCreate(boost::bind(&Home::Blog, this))); // http://localhost:8088/?_=/blog or http://localhost:8088/blog
    mainMenu_->addItem(Wt::WString::tr("chat"),  deferCreate(boost::bind(&Home::Chat, this))); // http://localhost:8088/?_=/chat
    // Make sure you can completly remove any module, this goes for blog or chat also
    #ifdef VIDEOMAN
        mainMenu_->addItem(Wt::WString::tr("video"), deferCreate(boost::bind(&Home::VideoMan, this)));
        // FIXIT add Menu Options for all videos
    #endif // VIDEOMAN
    mainMenu_->addItem(Wt::WString::tr("contact"), deferCreate(boost::bind(&Home::Contact, this)));
    mainMenu_->addItem(Wt::WString::tr("about"), deferCreate(boost::bind(&Home::About, this)));
    //mainMenu_->addItem("Search", searchResult);

    // Setup a Right-aligned menu.
    Wt::WMenu *rightMenu = new Wt::WMenu();
    //rightMenu->setId("rightmenu");
    navigation->addMenu(rightMenu, Wt::AlignRight);

    // Create a Language popup submenu for the Help menu.
    Wt::WPopupMenu *languagePopup = new Wt::WPopupMenu();
    languagePopup->setId("languages");
    for (unsigned i = 0; i < languages.size(); ++i)
    {
        // Get Language
        const Lang& l = languages[i];
        // Add Popup Item with Description.
        Wt::WMenuItem *mi = languagePopup->addItem(Wt::WString::fromUTF8(l.longDescription_));
        mi->triggered().connect(boost::bind(&Home::HandleLanguagePopup, this, i));
    }
    // Create a Theme popup submenu for the Help menu.
    Wt::WPopupMenu *themePopup = new Wt::WPopupMenu();
    themePopup->setId("theme");
    // Add Theme Item Red
    Wt::WMenuItem *mit = themePopup->addItem(Wt::WString::tr("red"));
    mit->triggered().connect(boost::bind(&Home::HandleThemePopup, this, 0));
    // Add Theme Item White
    mit = themePopup->addItem(Wt::WString::tr("white"));
    mit->triggered().connect(boost::bind(&Home::HandleThemePopup, this, 1));
    // Add Theme Item Blue
    mit = themePopup->addItem(Wt::WString::tr("blue"));
    mit->triggered().connect(boost::bind(&Home::HandleThemePopup, this, 2));
    // Add Theme Item Green
    mit = themePopup->addItem(Wt::WString::tr("green"));
    mit->triggered().connect(boost::bind(&Home::HandleThemePopup, this, 3));
    // Add Theme Item Tan
    mit = themePopup->addItem(Wt::WString::tr("tan"));
    mit->triggered().connect(boost::bind(&Home::HandleThemePopup, this, 4));
    // Add Theme Item default
    mit = themePopup->addItem(Wt::WString::tr("default"));
    mit->triggered().connect(boost::bind(&Home::HandleThemePopup, this, 5));


    // Language Popdown
    Wt::WMenuItem *item = new Wt::WMenuItem(Wt::WString::tr("language"));
    item->setId("language");
    // Add Language Popup to Menu
    item->setMenu(languagePopup);
    rightMenu->addItem(item);


    // Theme Popdown
    Wt::WMenuItem *themeItem = new Wt::WMenuItem(Wt::WString::tr("theme"));
    themeItem->setId("help");
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
    result->bindWidget("menu", navigation);
    result->bindWidget("contents", contents);
    // Banner
    Wt::WText *banner = new Wt::WText("<!-- <a href='#'>Witty Wizard</a> -->", Wt::XHTMLUnsafeText);
    // CopyRight
    Wt::WText *copyright = new Wt::WText("Witty Wizard Content Management System (CMS) <a href='http://beta.WittyWizard.org/'>beta.WittyWizard.org</a>", Wt::XHTMLUnsafeText);
    // Footer Menu
    Wt::WText *footermenu = new Wt::WText("<a href='http://beta.WittyWizard.org:8088'>Home</a> | <a href='http://beta.WittyWizard.org:8088/contact'>Contact</a>", Wt::XHTMLUnsafeText);
    // Google Analytics
    Wt::WText *ga = new Wt::WText("<script>/*<![CDATA[*/(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)})(window,document,'script','//www.google-analytics.com/analytics.js','ga');ga('create', '" + std::string("UA-48275805-1") + "', '" + myHost + "');ga('send', 'pageview');/* ]]> */</script>", Wt::XHTMLUnsafeText);
    //
    Wt::WText *hitcounter = new Wt::WText("Hits:");

    result->bindWidget("banner", banner);
    result->bindWidget("copyright", copyright);
    result->bindWidget("footermenu", footermenu);
    result->bindWidget("ga", ga);
    result->bindWidget("hitcounter", hitcounter);
    /*
    sideBarContent_ = new WContainerWidget();
    result->bindWidget("sidebar", sideBarContent_);
    */
} // end void Home::CreateHome
/* ****************************************************************************
 * set Language
 */
void Home::HandleLanguagePopup(int data)
{
    Wt::log("start") << " *** Home::HandleLanguagePopup(data: " << data << ") *** ";
    std::string languagePath = internalPathNextPart("/"); // Checks First path element, its allows the Language: en, ru, cn
    std::string thePath = internalPath(); // will always be /...
    // Ensure Legal Language Code.
    if (IsPathLanguage(languagePath) == -1)
    {
        Wt::log("notice") << "Home::HandleLanguagePopup(Language not found in internal Path. " << ")";
        thePath = '/' + languages[data].code_ + thePath;
    }
    else // Legal Langauge Code
    {
        //
        if (languages[data].code_ == languagePath)
        {
            Wt::log("error") << "Home::HandleLanguagePopup(Language has not changed. " << ")";
            return; // No Reason to change anything, they picked the same Lanuage they are in
        }
        else
        {
            // We must replace the Old Lanuage First
            if (!StringReplace(thePath, languagePath, languages[data].code_))
            {
                Wt::log("error") << "Home::HandleLanguagePopup(Error in String Replace " << ")";
            }
        }
    }
    Wt::WApplication::instance()->setInternalPath(thePath,  true);
    Wt::log("end") << " *** Home::HandleLanguagePopup(data: " << data << ") *** ";
} // end void Home::HandleLanguagePopup
/* ****************************************************************************
 * set Theme
 */
void Home::HandleThemePopup(int data)
{
    Wt::log("start") << " *** Home::HandleThemePopup(data: " << data << ") *** ";
    SetTheme(false, data);
} // end void Home::HandleThemePopup
/* ****************************************************************************
 * Set Theme
 */
void Home::SetTheme(bool fromCookie, int index)
{
    Wt::log("start") << " *** Home::SetTheme(FromCookie: " << "data: " << index << ") *** ";
    std::string myTheme;
    if (fromCookie)
    {
        myTheme = GetCookie("theme");
    }
    else
    {
        switch (index)
        {
            case 0: // Red
                Wt::log("notice") << "Home::SetTheme(set Theme to Red)";
                myTheme = "red";
                break;
            case 1: // White
                Wt::log("notice") << "Home::SetTheme(set Theme to White)";
                myTheme = "white";
                break;
            case 2: // Blue
                Wt::log("notice") << "Home::SetTheme(set Theme to Blue)";
                myTheme = "blue";
                break;
            case 3: // Green
                Wt::log("notice") << "Home::SetTheme(set Theme to Green)";
                myTheme = "green";
                break;
            case 4: // Tan
                Wt::log("notice") << "Home::SetTheme(set Theme to Tan)";
                myTheme = "tan";
                break;
            case 5: // Default
                Wt::log("notice") << "Home::SetTheme(set Theme to Default)";
                myTheme = "default";
                break;
        }
        SetCookie("theme", myTheme);
    }
    if (!myTheme.empty())
    {
        // page or Wt-inline-css document.getElementById('wittywizardstylesheet').href='new_css.css';  style.property
        // + myBaseUrl
        std::string jsCss = "document.getElementById('wittywizardstylesheet').href='" + Wt::WApplication::resourcesUrl() + "themes/wittywizard/" + myTheme + "/ww-" + myTheme + ".css';";
        this->doJavaScript(jsCss);
        //useStyleSheet(Wt::WApplication::resourcesUrl() + "themes/wittywizard/" + myTheme + "/ww-" + myTheme + ".css");
        SetCookie("themepath", Wt::WApplication::resourcesUrl() + "themes/wittywizard/");
    }
} // end void Home::SetTheme
/* ****************************************************************************
 * Set Language
 * index: Index to Language
 * langPath: Language Code: en, cn, ru, ...
 */
void Home::SetLanguage(int index, std::string languageCode)
{
    isPathChanging = true;
    std::string currentLanguageCode = internalPathNextPart("/"); // Checks First path statement
    std::string thePath = internalPath(); // begins with /
    Wt::log("start") << " <<<<<<<*** Home::SetLanguage(index: " << index << ", languagePath: " << languageCode << ") " << " | thePath = " << thePath;
    #ifdef VIDEOMAN
        VideoView *video;
    #endif
    if (IsPathLanguage(currentLanguageCode) == -1)
    {
        // Language not set
        thePath = '/' + languageCode + thePath;
    }
    else
    {
        currentMenuItem = internalPathNextPart('/' + languageCode + '/'); // Checks second path statement: Menu Item
        if (!currentMenuItem.empty())
        {
            #ifdef VIDEOMAN
            if (currentMenuItem == "video")
            {
                video = dynamic_cast<VideoView *>(findWidget("video"));
                if (video)
                {
                    Wt::log("notice") << " <<<<<<< Home::SetLanguage() menu is video do return." << " | thePath = " << thePath;
                    isPathChanging = false; // Set isPathChanging so SetLanguageFromPath will fire
                    return; // we do not want to handle changes: FIXIT find a way to make this generic
                }
            }
            #endif
        } // end if (!currentMenuItem.empty())
    } // end if (IsPathLanguage(currentLanguageCode) == -1)
    Wt::log("notice") << " *** Home::SetLanguage(index: " << index << ", languagePath: " << languageCode << ") " << " | thePath = " << thePath << " | currentMenuItem = " << currentMenuItem;
    // << " | Wt::WEnvironment::locale() = " << Wt::WEnvironment::locale()
    // Get Language
    const Lang& theLanguage = languages[index];
    // Set Local
    setLocale(theLanguage.code_);
    // Change Menu Base Path
    mainMenu_->setInternalBasePath('/' + languageCode + '/');
    // Change Path
    Wt::WApplication::instance()->setInternalPath(thePath, true);
    //
    BlogView *blog = dynamic_cast<BlogView *>(findWidget("blog"));
    if (blog)
    {
        if (!thePath.find('/' + languageCode + "blog/"))
        {
            Wt::log("notice") << "Home::SetLanguage() for blog " << index << ")";
            blog->SetInternalBasePath(thePath + "blog/");
        }
    }
    //
    #ifdef VIDEOMAN
    video = dynamic_cast<VideoView *>(findWidget("video"));
    if (video)
    {
        if (!thePath.find('/' + languageCode + "video/"))
        {
            Wt::log("notice") << "Home::SetLanguage() for video " << index <<  " | thePath = " << thePath << ")";
            video->SetInternalBasePath(thePath + "video/");
        }
    }
    #endif
    UpdateTitle();
    language_ = index; // Set language_ to current Language
    isPathChanging = false; // Set isPathChanging so SetLanguageFromPath will fire
} // end void Home::SetLanguage
/* ****************************************************************************
 * SetLanguageFromPath
 * Fix video and other app paths
 */
void Home::SetLanguageFromPath()
{
    if (isPathChanging)
    {
        Wt::log("restart") << " ~~~~ Home::SetLanguageFromPath() returning nothing done ~~~~ ";
        return;
    }
    std::string thePath = internalPath(); // begins with /
    std::string languageCode = internalPathNextPart("/"); // Checks First
    int newLanguage = 0;
    bool updateLanguage = false;
    // this will only happen if menu home is clicked
    if (languageCode.empty())
    {
        languageCode = defaultLanguage;
        updateLanguage = true;
        Wt::log("start") << " *** Home::SetLanguageFromPath() languageCode empty -> set languageCode to default = " << languageCode << " | internalPathNextPart = " << internalPathNextPart("/")  << " | thePath = " << thePath << " *** ";
    }
    else
    {
        for (unsigned i = 0; i < languages.size(); ++i)
        {
            if (languages[i].code_ == languageCode)
            {
                newLanguage = i;
                Wt::log("start") << " *** Home::SetLanguageFromPath() languageCode = " << languageCode << " found at " << i << " | thePath = " << thePath << " ***"; // en, cn, ru...
                break;
            }
        }
    }
    // Only update if Language changes or it needs to be updated
    if (lastPath.empty())
    {
        updateLanguage = true;
    }
    else
    {
        if (lastPath != thePath)
        {
            updateLanguage = true;
        }
    }
    // do I really need to test newLanguage != language_
    if (newLanguage != language_ || updateLanguage)
    {
        SetLanguage(newLanguage, languageCode);
        // Set Theme
        SetTheme(true, 0);
    }
} // end void Home::SetLanguageFromPath
/* ****************************************************************************
 * update Title
 */
void Home::UpdateTitle()
{
    if (mainMenu_->currentItem())
    {
        setTitle(Wt::WString::tr("page.title") + " - " + mainMenu_->currentItem()->text());
    }
} // end void Home::UpdateTitle
/* ****************************************************************************
 * logInternalPath
 */
void Home::LogInternalPath(const std::string& path)
{
    // simulate an access log for the interal paths
    Wt::log("start") << " *** Home::logInternalPath(" << path << ") *** ";
} // end void Home::LogInternalPath
/* ****************************************************************************
 * Home Page
 */
Wt::WWidget *Home::HomePage()
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
Wt::WWidget *Home::Blog()
{
    const Lang& l = languages[language_];
    std::string langPath = l.path_;
    BlogView *blog = new BlogView(langPath + "blog/", *dbConnection_, "/" + rootPrefix + "/blog/feed/");
    blog->setObjectName("blog");

    if (!blog->user().empty())
    {
        ChatSetUser(blog->user());
    }
    blog->userChanged().connect(this, &Home::ChatSetUser);

    return blog;
} // end Wt::WWidget *Home::Blog
/* ****************************************************************************
 * Video Man
 */
#ifdef VIDEOMAN
Wt::WWidget *Home::VideoMan()
{
    //
    const Lang& l = languages[language_];
    std::string langPath = l.path_;
    std::string myAppRoot = appPath_.toStdString() + appRoot().substr(2).c_str();
    VideoView* thisVideo = new VideoView(myAppRoot + "video/", langPath + "video/", *dbConnection_);
    thisVideo->setObjectName("video");

    return thisVideo;
} // end Wt::WWidget *Home::VideoMan
#endif // VIDEOMAN
/* ****************************************************************************
 * IsPathLanguage
 * langPath: pass in first path string
 * return -1 if not found, else return index of Language
 */
int Home::IsPathLanguage(std::string langPath)
{
    int foundLanguage = -1;
    for (unsigned i = 0; i < languages.size(); ++i)
    {
        if (languages[i].code_ == langPath)
        {
            foundLanguage = i;
            Wt::log("notice") << " *** Home::IsPathLanguage() langPath = " << langPath << " found at " << i << " ***"; // en, cn, ru ...
            break;
        }
    }
    return foundLanguage;
} // end Home::IsPathLanguage
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
