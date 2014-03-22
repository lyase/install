/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */

//#include <fstream>
//#include <iostream>

//#include <boost/lexical_cast.hpp>
//#include <boost/tokenizer.hpp>
//#include <boost/algorithm/string.hpp>

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
#include "view/VideoImpl.h"
/*
 * get URL
#include <Wt/WEnvironment>

const WEnvironment& env = WApplication::instance()->environment();
   ...
 // read an application startup argument
 // (passed as argument in the URL or POST'ed to the application).
 if (!env.getParameterValues("login").empty())
 {
   std::string login = env.getParameterValues("login")[0];
 }
*/
/*
setCookie(cookieName, newSessionId, -1);

*/
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

    Wt::log("notice") << "(home env.hostName(): " << env.hostName().c_str() << ")";
    QString filePath = appRoot().c_str();
    filePath.append("domains.xml");
    QString domainName = env.hostName().c_str();
    unsigned pos = domainName.indexOf(":");
    if (pos > 0)
    {
        domainName = domainName.mid(0, pos);
    }
    if (0) domainName = "beta.wittywizard.org";
    if (0) domainName = "beta.lightwizzard.com";
    if (0) domainName = "beta.vetshelpcenter.com";
    if(myRssFeed.find(domainName.toStdString()) == myRssFeed.end())
    {
        // element not found;
        Wt::log("notice") << "(Home: myRssFeed element not found " << domainName.toStdString() << ")";
        return;
    }
    std::string theFeeder = myRssFeed[domainName.toStdString()];
#define REGX
#ifdef REGX    
    QString theRssFeed = theFeeder.c_str();
    QRegExp rx("(\\t)"); // RegEx for ' ' or ',' or '.' or ':' or '\t'
    QStringList query = theRssFeed.split(rx);
    appPath = query[3]; // Fix enumerate
#else
    std::vector<std::string> quary = split(theFeeder.c_str(), "\t");
    std::string x = quary.at(3);
    appPath = x.c_str(); // Fix enumerate    
#endif    
    Wt::log("notice") << "(home MyCmsDomain: " << appPath.toStdString() << ")";


    if(myConnectionPool.find(domainName.toStdString()) == myConnectionPool.end())
    {
        // element not found;
        Wt::log("notice") << "(Home: myConnectionPool element not found " << domainName.toStdString() << ")";
        return;
    }
    try
    {
        dbConnection_ = boost::any_cast<Wt::Dbo::SqlConnectionPool *>(myConnectionPool[domainName.toStdString()]);
    }
    catch (...)
    {
        Wt::log("error") << "(Home: failed connection " << domainName.toStdString() << ")";
        return;
    }

    messageResourceBundle().use(appPath.append("app_root/wt-home").toStdString(), false);
    useStyleSheet(Wt::WApplication::resourcesUrl() + "css/wittywizard.css");
    useStyleSheet(Wt::WApplication::resourcesUrl() + "css/wittywizard_ie.css", "lt IE 7"); // "." +
    if (0)
    {
        Wt::log("notice") << "(resourcesUrl(): " << resourcesUrl() << ")"; // /resources/
        Wt::log("notice") << "(appRoot(): " << appRoot() << ")";           // ./app_root/
        Wt::log("notice") << "(docRoot(): " << docRoot() << ")";           // ./doc_root
    }
    //useStyleSheet("css/chatwidget.css");
    //useStyleSheet("css/chatwidget_ie6.css", "lt IE 7");
    //setCssTheme("polished");
    setTheme(new Wt::WBootstrapTheme());
    // Set Title
    // Fix needs to be per page
    //setTitle(MyCmsDomain.MyTitle);
    // Set Locale
    setLocale("");
    // Set Lanuage to 0
    language_ = 0;
}
/* ****************************************************************************
 * Destructor ~Home
 */
Home::~Home()
{
}
/* ****************************************************************************
 * init
 */
void Home::init()
{
    internalPathChanged().connect(this, &Home::setup);
    internalPathChanged().connect(this, &Home::setLanguageFromPath);
    internalPathChanged().connect(this, &Home::logInternalPath);

    // Setup
    setup();
    // Set Lanuage From Path
    setLanguageFromPath();
}
/* ****************************************************************************
 * setServer
 */
/*
void Home::setServer(Wt::WServer& theServer)
{
    *myServer = theServer;
}
*/
/* ****************************************************************************
 * getServer
 */
/*
Wt::WServer *Home::getServer()
{
    return myServer;
}
*/
/* ****************************************************************************
 * setup
 */
void Home::setup()
{
    if (!homePage_)
    {
        // Clear the Screen
        root()->clear();
        // Create Home Page
        createHome();
        // Create Home Page
        root()->addWidget(homePage_);
        // Set Lanuage From Path
        setLanguageFromPath();
    }
}
/* ****************************************************************************
 * split
 */
std::vector<std::string> Home::split(std::string str, std::string delim)
{
      unsigned start = 0;
      unsigned end;
      std::vector<std::string> v;
      // /home/jflesher/FileShare/Code/0-WittyWizzard/WittyWizard/HomeBase.cpp:226: warning: comparison is always true due to limited range of data type [-Wtype-limits]
      //while( (end = str.find(delim, start)) != std::string::npos )
      //                                                      ^
      while( (end = str.find(delim, start)) != std::string::npos )
      {
            v.push_back(str.substr(start, end-start));
            start = end + delim.length();
      }
      v.push_back(str.substr(start));
      return v;
}
/* ****************************************************************************
 * createHome
 */
void Home::createHome()
{
    Wt::WTemplate *result = new Wt::WTemplate(tr("template"), root()); //  <message id="template">
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
    navigation->setTitle(tr("title"));
    //navigation->setResponsive(true); // caused it to be collapsable

    Wt::WStackedWidget *contentsStack = new Wt::WStackedWidget(contents);
    //contentsStack->setId("contents");
    contentsStack->addStyleClass("contents");

    // Setup a Left-aligned menu.
    mainMenu_ = new Wt::WMenu(contentsStack, contents);
    mainMenu_->setId("mainmenu");
    navigation->addMenu(mainMenu_);

    Wt::WText *searchResult = new Wt::WText("Search");

    mainMenu_->addItem(tr("home"),  home())->setPathComponent("");
    mainMenu_->addItem(tr("blog"),  deferCreate(boost::bind(&Home::blog, this))); // http://localhost:8088/?_=/blog
    mainMenu_->addItem(tr("chat"),  deferCreate(boost::bind(&Home::chat, this))); // http://localhost:8088/?_=/chat
    mainMenu_->addItem(tr("video"), deferCreate(boost::bind(&Home::video, this)));
    mainMenu_->addItem(tr("contact"), deferCreate(boost::bind(&Home::contact, this)));
    mainMenu_->addItem(tr("about"), deferCreate(boost::bind(&Home::about, this)));
    //mainMenu_->addItem("Search", searchResult);

    // Setup a Right-aligned menu.
    Wt::WMenu *rightMenu = new Wt::WMenu();
    //rightMenu->setId("rightmenu");
    navigation->addMenu(rightMenu, Wt::AlignRight);

    // Create a popup submenu for the Help menu.
    Wt::WPopupMenu *popup = new Wt::WPopupMenu();
    popup->setId("languages");
    for (unsigned i = 0; i < languages.size(); ++i)
    {
        // Get Language
        const Lang& l = languages[i];
        // Add Popup Item with Description.
        WMenuItem *mi = popup->addItem(WString::fromUTF8(l.longDescription_));
        mi->triggered().connect(boost::bind(&Home::handlePopup, this, i));
    }

    Wt::WMenuItem *item = new Wt::WMenuItem("Language");
    item->setId("Language");
    item->setMenu(popup);
    rightMenu->addItem(item);

    // Add a Search control.
    Wt::WLineEdit *edit = new Wt::WLineEdit();
    edit->setEmptyText("Enter a search item");

    edit->enterPressed().connect(std::bind([=] ()
    {
        // fix
        mainMenu_->select(4); // is the index of the "Sales"
        searchResult->setText(Wt::WString("Nothing found for {1}.").arg(edit->text()));
    }));

    navigation->addSearch(edit, Wt::AlignRight);

    contents->addWidget(contentsStack);

    // On Select
    mainMenu_->itemSelectRendered().connect(this, &Home::updateTitle);
    mainMenu_->itemSelected().connect(this, &Home::googleAnalyticsLogger);
    // Make the menu be internal-path aware.
    mainMenu_->setInternalPathEnabled("/");
    // Bind to Template
    //result->bindWidget("menu", mainMenu_);
    result->bindWidget("menu", navigation);
    result->bindWidget("contents", contents);
    /*
    sideBarContent_ = new WContainerWidget();
    result->bindWidget("sidebar", sideBarContent_);
    */
}
/* ****************************************************************************
 * setLanguage
 */
void Home::handlePopup(int data)
{
    Wt::log("notice") << "(data: " << data << ")";
    switch (data)
    {
        case 0: // English
            Wt::log("notice") << "(set language to English: " << ")";
            Wt::WApplication::instance()->setInternalPath("/",  true);
            break;
        case 1: // 中文 (Chinese)
            Wt::log("notice") << "(set language to Chinese: " << ")";
            Wt::WApplication::instance()->setInternalPath("/cn/",  true);
            break;
        case 2: // Русский (Russian)
            Wt::log("notice") << "(set language to Russian: " << ")";
            Wt::WApplication::instance()->setInternalPath("/ru/",  true);
            break;
    }
}
/* ****************************************************************************
 * setLanguage
 */
void Home::setLanguage(int index)
{
    Wt::log("notice") << "(setLanguage: " << index << ")";
    if (homePage_)
    {
        const Lang& l = languages[index];

        setLocale(l.code_);

        std::string langPath = l.path_;
        mainMenu_->setInternalBasePath(langPath);
        BlogView *blog = dynamic_cast<BlogView *>(findWidget("blog"));
        if (blog)
        {
            Wt::log("notice") << "(setLanguage: blog " << index << ")";
            blog->setInternalBasePath(langPath + "blog/");
        }
        updateTitle();

        language_ = index;
    }
}
/* ****************************************************************************
 * setLanguageFromPath
 * Fix
 */
void Home::setLanguageFromPath()
{
    std::string langPath = internalPathNextPart("/");
    Wt::log("notice") << "(setLanguageFromPath: " << langPath << ")";

    if (langPath.empty())
    {
        langPath = '/';
    }
    else
    {
        langPath = '/' + langPath + '/';
    }
    int newLanguage = 0;

    for (unsigned i = 0; i < languages.size(); ++i)
    {
        if (languages[i].path_ == langPath)
        {
            newLanguage = i;
            break;
        }
    }

    if (newLanguage != language_)
    {
        setLanguage(newLanguage);
    }
}

/* ****************************************************************************
 * update Title
 */
void Home::updateTitle()
{
    if (mainMenu_->currentItem())
    {
        setTitle(tr("page.title") + " - " + mainMenu_->currentItem()->text());
    }
}
/* ****************************************************************************
 * logInternalPath
 */
void Home::logInternalPath(const std::string& path)
{
    // simulate an access log for the interal paths
    Wt::log("notice") << "Home::logInternalPath: " << path;
    /*
    WApplication* app = WApplication::instance();
    if (app->internalPathMatches("/video/"))
    {
        std::string categoryNumber = app->internalPathNextPart("/video/");
        if (!categoryNumber.empty())
        {
            std::string videoNumber = app->internalPathNextPart("/video/" + categoryNumber + "/");
            if (!videoNumber.empty())
            {
                Wt::log("notice") << "(videoNumber: " << categoryNumber + "/" + videoNumber << ")";
                //setCurrentVideo(videoNumber);
                video();
            }
        }
    }
    */
}
/* ****************************************************************************
 * home
 */
Wt::WWidget *Home::home()
{
    return new Wt::WText(tr("home.intro"));
}
/* ****************************************************************************
 * Contact
 */
Wt::WWidget *Home::contact()
{
    return new Wt::WText(tr("home.contact"));
}
/* ****************************************************************************
 * About
 */
Wt::WWidget *Home::about()
{
    return new Wt::WText(tr("home.about"));
}
/* ****************************************************************************
 * blog
 */
Wt::WWidget *Home::blog()
{
    const Lang& l = languages[language_];
    std::string langPath = l.path_;
    BlogView *blog = new BlogView(langPath + "blog/", *dbConnection_, "/wt/blog/feed/");
    blog->setObjectName("blog");

    if (!blog->user().empty())
    {
        chatSetUser(blog->user());
    }
    blog->userChanged().connect(this, &Home::chatSetUser);

    return blog;
}
/* ****************************************************************************
 * Video
 */
Wt::WWidget *Home::video()
{
    //
    const Lang& l = languages[language_];
    std::string langPath = l.path_;
    VideoView* thisVideo = new VideoView(appPath.append("app_root/video/video.xml").toUtf8().data(), langPath + "video/", dbConnection_);
    thisVideo->setObjectName("video");

    return thisVideo;
}
/* ****************************************************************************
 * chat
 */
Wt::WWidget *Home::chat()
{
    return new Wt::WText(tr("chatter"));

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
}
/* ****************************************************************************
 * chatSetUser
 */
void Home::chatSetUser(const Wt::WString& userName)
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
}
/* ****************************************************************************
 * wrapView
 */
Wt::WWidget *Home::wrapView(Wt::WWidget *(Home::*createWidget)())
{
    return makeStaticModel(boost::bind(createWidget, this));
}
/* ****************************************************************************
 * href
 */
std::string Home::href(const std::string& url, const std::string& description)
{
    return "<a href=\"" + url + "\" target=\"_blank\">" + description + "</a>";
}
/* ****************************************************************************
 * tr
 */
Wt::WString Home::tr(const char *key)
{
    return Wt::WString::tr(key);
}
/* ****************************************************************************
 * googleAnalyticsLogger
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
}
// --- End Of File ------------------------------------------------------------
