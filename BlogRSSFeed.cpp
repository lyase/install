/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
#include <Wt/WApplication>
#include <Wt/Http/Response>
#include <Wt/Utils>
#include <Wt/WLogger>

#include "BlogRSSFeed.h"

#include "model/BlogSession.h"
#include "model/User.h"
#include "model/Post.h"
#include "model/Comment.h"
#include "model/Tag.h"
#include "model/Token.h"

#include <map>

#include <boost/cast.hpp>

#include <assert.h>     /* assert */
#include "WittyWizard.h"

//#include <QString>
//#include <QRegExp>
//#include <QStringList>
/* ****************************************************************************
 * Global Connection Pool Map - Set in main.cpp
 */
extern std::map <std::string, boost::any> myConnectionPool;
/* ****************************************************************************
 * Global Variable - Set in main.cpp
 * Full Path to Domain: /home/domain.tdl/
 * vector
 */
extern std::map <std::string, std::string> myDomainPath;
/* ****************************************************************************
 * BlogRSSFeed
 */
BlogRSSFeed::BlogRSSFeed()
{
} // end BlogRSSFeed::BlogRSSFeed
/* ****************************************************************************
 * ~BlogRSSFeed
 */
BlogRSSFeed::~BlogRSSFeed()
{
} // end BlogRSSFeed::~BlogRSSFeed(
/* ****************************************************************************
 * handleRequest
 */
void BlogRSSFeed::handleRequest(const Wt::Http::Request &request, Wt::Http::Response &response)
{
    std::string myURL = request.headerValue("Host").c_str();
    //QString domainName = myURL.c_str();
    std::string domainName = myURL.c_str();
    //unsigned pos = domainName.indexOf(":");
    unsigned pos = domainName.find(":");
    if (pos > 0)
    {
        domainName = domainName.substr(0, pos);
    }
    if (!SetSqlConnectionPool(domainName))
    {
        Wt::log("error") << "(BlogRSSFeed::handleRequest: SetSqlConnectionPool failed for domain: " << domainName << ")";
        return;
    }
    Wt::log("notice") << "(BlogRSSFeed::handleRequest: domainName " << domainName << ")";
    //if(myConnectionPool.find(domainName.toStdString()) == myConnectionPool.end())
    if(myConnectionPool.find(domainName) == myConnectionPool.end())
    {
        // element not found;
        //Wt::log("notice") << "(BlogRSSFeed::handleRequest: myConnectionPool element not found " << domainName.toStdString() << ")";
        Wt::log("notice") << "(BlogRSSFeed::handleRequest: myConnectionPool element not found " << domainName << ")";
        //request.serverName().c_str() returned saber
        return;
    }
    Wt::Dbo::SqlConnectionPool *thePool;
    try
    {
        //thePool = boost::any_cast<Wt::Dbo::SqlConnectionPool *>(myConnectionPool[domainName.toStdString()]);
        thePool = boost::any_cast<Wt::Dbo::SqlConnectionPool *>(myConnectionPool[domainName]);
    }
    catch (...)
    {
        //Wt::log("notice") << "(BlogRSSFeed::handleRequest: failed connection cast " << domainName.toStdString() << ")";
        Wt::log("notice") << "(BlogRSSFeed::handleRequest: failed connection cast " << domainName << ")";
        //request.serverName().c_str() returned saber
        return;
    }
    BlogSession session(*thePool);

    response.setMimeType("application/rss+xml");
    //

    /*
Just to be clear about these instructions:

Take application lock (Wt::WApplication::UpdateLock) from handleRequest()
if you change WApplication (by changing message resource bundle)

void BlogRSSFeed::handleRequest(const Wt::Http::Request &request, Wt::Http::Response &response)
{
    // I see no useful variables to pull
}

/mnt/storage/jflesher/FileShare/Code/0-WittyWizard/WittyWizard/BlogRSSFeed.cpp:135: error: 'WApplication' has not been declared
     WApplication::UpdateLock lock(app);
     ^

Hello!

Use WApplication::instance() to get a pointer to current WApplication.
No need to construct application object in handleRequest().
The only place where application is created is application creating function (ApplicationCreator),
which is passed to WRun() or to WServer::addEntryPoint().
So, only Wt internals should create new instances of application, not your code!

WApplication::instance() can be used from event handling functions (e.g., slots connected to Wt signals) and handleRequest()
if WResource is bind to an application.
You can use assert(wApp) to make sure it is not 0.
It can be 0 no application instance is active currently (for example, in server-global WResource or in main() function).

Macro wApp is equal to WApplication::instance().

Derive from WApplication, it works.
For example, you derived MyApplication from WApplication.
To convert pointer to WApplication to pointer to MyApplication,
use boost polymorphic cast:

#include "boost/cast.cpp"

WApplication* app = WApplication::instance(); // to just wApp
MyApplication* myapp = boost::polymorphic_downcast(app);

boost::polymorphic_downcast uses C++ built-in operators static_cast or dynamic_cast.
Which one of them is used, depends on build configuration. Release build uses static_cast,
Debug build uses dynamic_cast and checks result is not 0.

If you use boost::polymorphic_downcast many times, it makes sense for you to create a macro for it:
#define DOWNCAST boost::polymorphic_downcast

Summary: to get WApplication*, use wApp, to get WEnvironment, use wApp->environment(),
to get pointer to your derived application class, use boost::polymorphic_downcast.

wApp is 0 in static WResource.


You seem to use global WResource (added with WServer::addResource()).
In this case, wApp is 0, so you can not use WApplication.
To translate with WString::tr,
you can use WServer::setLocalizedStrings().
For this, you need Wt::WMessageResourceBundle instance.

In main(), create new WMessageResourceBundle, call use() to add your translated XML files,
then pass it to WServer::setLocalizedStrings().

BTW, this solution does not respect user's locale, all strings are translated to server's locale.
I created feature request for this http://redmine.webtoolkit.eu/issues/3381

You can workaround this by creation several global WMessageResourceBundle instances (one per language) and
selection one of them depending on client's language manually.
Then you can use WMessageResourceBundle::resolveKey to translate.
To get clients locale, get HTTP header "Accept-Language" using Request::headerValue().
(Request instance is passed to handleRequest().) Parsing it is a complicated task.
For example, "en-US,en;q=0.8,ru;q=0.6" means Russian.

*/
    //const Wt::WEnvironment& env = Wt::WApplication::instance()->environment();
    /*
    const Wt::WEnvironment& env = new Wt::WEnvironment();

    Wt::WApplication *app = new Wt::WApplication(env);
    Wt::WApplication::UpdateLock lock(app);
    if (lock)
    {
        // exclusive access to app state
        app->messageResourceBundle().use(myDomainPath[domainName] + "app_root/ww-home", false);
    }
    //MyResources myRes = new MyResources(Wt::WApplication::instance()->environment(), domainName);
    //Wt::WApplication *app = Wt::WApplication::instance();

    */
    //Wt::WApplication* app = Wt::WApplication::instance(); // to just wApp



    //
    std::string url          = Wt::WString::tr("rss-url").toUTF8();
    std::string title_       = Wt::WString::tr("rss-title").toUTF8();
    std::string description_ = Wt::WString::tr("rss-description").toUTF8();
    //
    Wt::log("notice") << "(BlogRSSFeed::handleRequest:  url, title_, description_ = " << url << ", " <<  title_ << ", " <<  description_ << ")";
    //
    if (url.empty())
    {
        //url = request.urlScheme() + "://" + domainName.toStdString();
        url = request.urlScheme() + "://" + domainName;
        if (!request.serverPort().empty() && request.serverPort() != "80")
        {
            url += ":" + request.serverPort();
        }
        url += request.path();

        // remove '/feed/'
        url.erase(url.length() - 6);
    }

    response.out() << "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                      "<rss version=\"2.0\">\n"
                      "  <channel>\n"
                      "    <title>" << Wt::Utils::htmlEncode(title_) << "</title>\n"
                      "    <link>" << Wt::Utils::htmlEncode(url) << "</link>\n"
                      "    <description>" << Wt::Utils::htmlEncode(description_) << "</description>\n";
    Wt::Dbo::Transaction t(session);

    Posts posts = session.find<Post>("where state = ? order by date desc limit 10").bind(Post::Published);

    for (Posts::const_iterator i = posts.begin(); i != posts.end(); ++i)
    {
        Wt::Dbo::ptr<Post> post = *i;

        std::string permaLink = url + "/" + post->permaLink();

        response.out() << "    <item>\n"
                          "      <title>" << Wt::Utils::htmlEncode(post->title.toUTF8()) << "</title>\n"
                          "      <pubDate>" << post->date.toString("ddd, d MMM yyyy hh:mm:ss UTC")
                       << "</pubDate>\n"
                          "      <guid isPermaLink=\"true\">" << Wt::Utils::htmlEncode(permaLink)
                       << "</guid>\n";

        std::string description = post->briefHtml.toUTF8();
        if (!post->bodySrc.empty())
        {
            description += "<p><a href=\"" + permaLink + "\">Read the rest...</a></p>"; // Fix Language
        }

        response.out() << "      <description><![CDATA[" << description << "]]></description>\n    </item>\n";
    }

    response.out() << "  </channel>\n</rss>\n";

    t.commit();
} // end void BlogRSSFeed::handleRequest
// --- End Of File ------------------------------------------------------------
