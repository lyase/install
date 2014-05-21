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
extern std::string rootPrefix;
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

    Wt::log("start") << " *** Home::Home() env.hostName() = " << env.hostName().c_str() << " *** ";
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
    // Didn't work, debug
    //std::vector<std::string> quary = split(theFeeder.c_str(), "\t");
    //std::string x = quary.at(3);
    //appPath_ = x.c_str(); // Fix enumerate
    std::vector <std::string> fields;
    boost::split( fields, theFeeder, boost::is_any_of( "\t" ) );
    std::string myFeeder = fields.at(3);
    appPath_ = myFeeder.c_str(); // Fix enumerate
#endif    
    Wt::log("notice") << "(Home::Home:  appPath: " << appPath_.toStdString() << ")";


    if(myConnectionPool.find(domainName.toStdString()) == myConnectionPool.end())
    {
        // element not found;
        Wt::log("notice") << "(Home::Home: myConnectionPool element not found " << domainName.toStdString() << ")";
        return;
    }
    try
    {
        dbConnection_ = boost::any_cast<Wt::Dbo::SqlConnectionPool *>(myConnectionPool[domainName.toStdString()]);
    }
    catch (...)
    {
        Wt::log("error") << "(Home::Home: failed connection " << domainName.toStdString() << ")";
        return;
    }
    std::string mrPath(appPath_.toStdString() + "app_root/ww-home"); // Fix name
    messageResourceBundle().use(mrPath, false);
    // Fix if it should use local copy of themes
    useStyleSheet(Wt::WApplication::resourcesUrl() + "css/wittywizard.css");
    useStyleSheet(Wt::WApplication::resourcesUrl() + "css/wittywizard_ie.css", "lt IE 7"); // "." +
    // Debug
    if (0)
    {
        Wt::log("notice") << "Home::Home: (resourcesUrl(): " << resourcesUrl() << ")"; // /resources/
        Wt::log("notice") << "Home::Home: (appRoot(): " << appRoot() << ")";           // ./app_root/
        Wt::log("notice") << "Home::Home: (docRoot(): " << docRoot() << ")";           // ./doc_root
    }
    //useStyleSheet("css/chatwidget.css");
    //useStyleSheet("css/chatwidget_ie6.css", "lt IE 7");
    //setCssTheme("polished");

    #ifdef THEME3
        Wt::WBootstrapTheme *bootstrapTheme = new Wt::WBootstrapTheme();
        bootstrapTheme->setVersion(Wt::WBootstrapTheme::Version3);
        setTheme(bootstrapTheme);
        // load the default bootstrap3 (sub-)theme
        // Fix if it should use local copy of themes
        useStyleSheet(Wt::WApplication::resourcesUrl() + "themes/bootstrap/3/bootstrap-theme.min.css");
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
    // Fix if it should use local copy of themes
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
    internalPathChanged().connect(this, &Home::Setup);
    internalPathChanged().connect(this, &Home::setLanguageFromPath);
    internalPathChanged().connect(this, &Home::LogInternalPath);
    // Setup
    Setup();
    // Set Lanuage From Path
    setLanguageFromPath();
} // end void Home::Init()
/* ****************************************************************************
 * setup
 */
void Home::Setup()
{
    if (!homePage_)
    {
        // Clear the Screen
        root()->clear();
        // Create Home Page
        CreateHome();
        // Create Home Page
        root()->addWidget(homePage_);
        // Set Lanuage From Path
        setLanguageFromPath();
    }
} // end void Home::Setup
/* ****************************************************************************
 * Create Home
 */
void Home::CreateHome()
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

    mainMenu_->addItem(tr("home"),  HomePage())->setPathComponent("");
    mainMenu_->addItem(tr("blog"),  deferCreate(boost::bind(&Home::Blog, this))); // http://localhost:8088/?_=/blog
    mainMenu_->addItem(tr("chat"),  deferCreate(boost::bind(&Home::Chat, this))); // http://localhost:8088/?_=/chat
    #ifdef VIDEOMAN
        mainMenu_->addItem(tr("video"), deferCreate(boost::bind(&Home::VideoMan, this)));
        // FIXIT add Menu Options for all videos
    #endif // VIDEOMAN
    mainMenu_->addItem(tr("contact"), deferCreate(boost::bind(&Home::Contact, this)));
    mainMenu_->addItem(tr("about"), deferCreate(boost::bind(&Home::About, this)));
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
        Wt::WMenuItem *mi = popup->addItem(Wt::WString::fromUTF8(l.longDescription_));
        mi->triggered().connect(boost::bind(&Home::HandlePopup, this, i));
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
    mainMenu_->itemSelectRendered().connect(this, &Home::UpdateTitle);
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
} // end void Home::CreateHome
/* ****************************************************************************
 * setLanguage
 */
void Home::HandlePopup(int data)
{
    Wt::log("start") << " *** Home::handlePopup(data: " << data << ") *** ";
    switch (data)
    {
        case 0: // English
            Wt::log("notice") << "Home::handlePopup(set language to English: " << ")";
            Wt::WApplication::instance()->setInternalPath("/",  true);
            break;
        case 1: // 中文 (Chinese)
            Wt::log("notice") << "Home::handlePopup(set language to Chinese: " << ")";
            Wt::WApplication::instance()->setInternalPath("/cn/",  true);
            break;
        case 2: // Русский (Russian)
            Wt::log("notice") << "Home::handlePopup(set language to Russian: " << ")";
            Wt::WApplication::instance()->setInternalPath("/ru/",  true);
            break;
    }
} // end void Home::HandlePopup
/* ****************************************************************************
 * setLanguage
 */
void Home::SetLanguage(int index)
{
    Wt::log("start") << " *** Home::setLanguage(index) " << index << " *** ";
    if (homePage_)
    {
        const Lang& l = languages[index];

        setLocale(l.code_);

        std::string langPath = l.path_;
        mainMenu_->setInternalBasePath(langPath);
        BlogView *blog = dynamic_cast<BlogView *>(findWidget("blog"));
        if (blog)
        {
            Wt::log("notice") << "(Home::setLanguage: blog " << index << ")";
            blog->setInternalBasePath(langPath + "blog/");
        }
        UpdateTitle();

        language_ = index;
    }
} // end void Home::SetLanguage
/* ****************************************************************************
 * setLanguageFromPath
 * Fix video and other app paths
 */
void Home::setLanguageFromPath()
{
    std::string langPath = internalPathNextPart("/");

    if (langPath.empty())
    {
        langPath = '/';
        Wt::log("start") << " *** Home::setLanguageFromPath() empty -> langPath = " << langPath << " *** ";
    }
    else
    {
        langPath = '/' + langPath + '/';
        Wt::log("start") << " *** Home::setLanguageFromPath() langPath = " << langPath << " *** "; // /video/
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
        SetLanguage(newLanguage);
    }
} // end void Home::setLanguageFromPath
/* ****************************************************************************
 * update Title
 */
void Home::UpdateTitle()
{
    if (mainMenu_->currentItem())
    {
        setTitle(tr("page.title") + " - " + mainMenu_->currentItem()->text());
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
    return new Wt::WText(tr("home.intro"));
} // end Wt::WWidget *Home::HomePage
/* ****************************************************************************
 * Contact
 */
Wt::WWidget *Home::Contact()
{
    return new Wt::WText(tr("home.contact"));
} // end Wt::WWidget *Home::Contact
/* ****************************************************************************
 * About
 */
Wt::WWidget *Home::About()
{
    return new Wt::WText(tr("home.about"));
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
    VideoView* thisVideo = new VideoView(appPath_.append("app_root/video/").toUtf8().data(), langPath + "video/", *dbConnection_);
    thisVideo->setObjectName("video");

    return thisVideo;
} // end Wt::WWidget *Home::VideoMan
#endif // VIDEOMAN
/* ****************************************************************************
 * chat
 */
Wt::WWidget *Home::Chat()
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
 * tr
 */
Wt::WString Home::tr(const char *key)
{
    return Wt::WString::tr(key);
} // end Wt::WString Home::tr
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
