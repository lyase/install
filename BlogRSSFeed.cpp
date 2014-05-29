/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */

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

#include <QString>
#include <QRegExp>
#include <QStringList>

/* ****************************************************************************
 * Map
 */
extern std::map <std::string, boost::any> myConnectionPool;
extern std::map <std::string, std::string> myRssFeed;
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
    QString domainName = myURL.c_str();
    unsigned pos = domainName.indexOf(":");
    if (pos > 0)
    {
        domainName = domainName.mid(0, pos);
    }
    //Wt::log("notice") << "(BlogRSSFeed::handleRequest: domainName " << domainName << ")";
    if(myConnectionPool.find(domainName.toStdString()) == myConnectionPool.end())
    {
        // element not found;
        Wt::log("notice") << "(BlogRSSFeed::handleRequest: myConnectionPool element not found " << domainName.toStdString() << ")";
        //request.serverName().c_str() returned saber
        return;
    }
    Wt::Dbo::SqlConnectionPool *thePool;
    try
    {
        thePool = boost::any_cast<Wt::Dbo::SqlConnectionPool *>(myConnectionPool[domainName.toStdString()]);
    }
    catch (...)
    {
        Wt::log("notice") << "(BlogRSSFeed::handleRequest: failed connection cast " << domainName.toStdString() << ")";
        //request.serverName().c_str() returned saber
        return;
    }
    BlogSession session(*thePool);

    response.setMimeType("application/rss+xml");

    if(myRssFeed.find(domainName.toStdString()) == myRssFeed.end())
    {
        // element not found;
        Wt::log("notice") << "(BlogRSSFeed::handleRequest: myRssFeed element not found " << domainName.toStdString() << ")";
        //request.serverName().c_str() returned saber
        return;
    }
    std::string theFeeder = myRssFeed[domainName.toStdString()];
    QString theRssFeed = theFeeder.c_str();
    QRegExp rx("(\\t)"); // RegEx for ' ' or ',' or '.' or ':' or '\t'

    QStringList query = theRssFeed.split(rx);

    std::string url = query[0].toStdString();
    std::string title_ = query[1].toStdString();
    std::string description_ = query[2].toStdString();

    //Wt::log("notice") << "(BlogRSSFeed::handleRequest:  url, title_, description_ = " << url << ", " <<  title_ << ", " <<  description_ << ")";

    if (url.empty())
    {
        url = request.urlScheme() + "://" + domainName.toStdString();
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
