/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */
#include <Wt/WAnchor>
#include <Wt/WApplication>
#include <Wt/WCheckBox>
#include <Wt/WContainerWidget>
#include <Wt/WEnvironment>
#include <Wt/WLineEdit>
#include <Wt/WPushButton>
#include <Wt/WStackedWidget>
#include <Wt/WTemplate>
#include <Wt/WText>

#include <Wt/Auth/PasswordService>
#include <Wt/Auth/PasswordVerifier>

//#include <Wt/Dbo/backend/Sqlite3>

#include <boost/algorithm/string/classification.hpp>
#include <boost/algorithm/string/split.hpp>
#include <boost/algorithm/string.hpp>

#include "BlogImpl.h"
#include "PostView.h"
#include "BlogView.h"
#include "EditUsers.h"
#include "BlogLoginWidget.h"

#include "model/BlogSession.h"
#include "model/Comment.h"
#include "model/Post.h"
#include "model/Tag.h"
#include "model/Token.h"
#include "model/User.h"

/* ****************************************************************************
 * Blog Impl
 */
BlogImpl::BlogImpl(const std::string& basePath, Wt::Dbo::SqlConnectionPool& connectionPool, const std::string& rssFeedUrl, BlogView* blogView) : basePath_(basePath), session_(connectionPool), rssFeedUrl_(rssFeedUrl), blogView_(blogView), panel_(0), authorPanel_(0), users_(0), userEditor_(0), mustLoginwarning_(0), mustBeAdministratorwarning_(0), invalidUser_(0)
{
    Wt::WApplication *app = wApp;
    // Do we want to use our own xml or use a common Template?
    app->messageResourceBundle().use(Wt::WApplication::appRoot() + "blog");
    // Do we want every Domain to have their own Resources? if so add path
    app->useStyleSheet(Wt::WApplication::resourcesUrl() + "css/blog.css");
    app->useStyleSheet(Wt::WApplication::resourcesUrl() + "css/asciidoc.css");
    //
    app->internalPathChanged().connect(this, &BlogImpl::handlePathChange);
    //
    loginStatus_ = new Wt::WTemplate(tr("blog-login-status"), this);
    panel_ = new Wt::WStackedWidget(this);
    items_ = new Wt::WContainerWidget(this);
    //
    session_.login().changed().connect(this, &BlogImpl::onUserChanged);
    //
    loginWidget_ = new BlogLoginWidget(session_, basePath);
    loginWidget_->hide();
    //
    Wt::WText *loginLink = new Wt::WText(tr("login"));
    loginLink->setStyleClass("link");
    loginLink->clicked().connect(loginWidget_, &WWidget::show);
    loginLink->clicked().connect(loginLink, &WWidget::hide);
    //
    Wt::WText *registerLink = new Wt::WText(tr("Wt.Auth.register"));
    registerLink->setStyleClass("link");
    registerLink->clicked().connect(loginWidget_, &BlogLoginWidget::registerNewUser);
    //
    Wt::WAnchor* archiveLink = new Wt::WAnchor(Wt::WLink(Wt::WLink::InternalPath, basePath_ + "all"), tr("archive"));
    //
    loginStatus_->bindWidget("login", loginWidget_);
    loginStatus_->bindWidget("login-link", loginLink);
    loginStatus_->bindWidget("register-link", registerLink);
    loginStatus_->bindString("feed-url", rssFeedUrl_);
    loginStatus_->bindWidget("archive-link", archiveLink);
    //
    onUserChanged();
    //
    loginWidget_->processEnvironment();
} // end
/* ****************************************************************************
 * ~Blog Impl
 */
BlogImpl::~BlogImpl()
{
    clear();
} // end
/* ****************************************************************************
 * on User Changed
 */
void BlogImpl::onUserChanged()
{
    if (session_.login().loggedIn())
    {
        loggedIn();
    }
    else
    {
        loggedOut();
    }
} // end
/* ****************************************************************************
 * set Internal Base Path
 */
void BlogImpl::setInternalBasePath(const std::string& basePath)
{
    basePath_ = basePath;
    refresh();
} // end
/* ****************************************************************************
 * logout
 */
void BlogImpl::logout()
{
    session_.login().logout();
} // end
/* ****************************************************************************
 * logged Out
 */
void BlogImpl::loggedOut()
{
    loginStatus_->bindEmpty("profile-link");
    loginStatus_->bindEmpty("author-panel-link");
    loginStatus_->bindEmpty("userlist-link");

    loginStatus_->resolveWidget("login")->hide();
    loginStatus_->resolveWidget("login-link")->show();
    loginStatus_->resolveWidget("register-link")->show();

    refresh();
    panel_->hide();
} // end
/* ****************************************************************************
 * logged In
 */
void BlogImpl::loggedIn()
{
    Wt::WApplication::instance()->changeSessionId();

    refresh();

    loginStatus_->resolveWidget("login")->show();
    loginStatus_->resolveWidget("login-link")->hide();
    loginStatus_->resolveWidget("register-link")->hide();

    Wt::WText *profileLink = new Wt::WText(tr("profile"));
    profileLink->setStyleClass("link");
    profileLink->clicked().connect(this, &BlogImpl::editProfile);

    Wt::Dbo::ptr<User> user = session().user();

    if (user->role == User::Admin)
    {
        Wt::WText *editUsersLink = new Wt::WText(tr("edit-users"));
        editUsersLink->setStyleClass("link");
        editUsersLink->clicked().connect(SLOT(this, BlogImpl::editUsers));
        loginStatus_->bindWidget("userlist-link", editUsersLink);

        Wt::WText *authorPanelLink = new Wt::WText(tr("author-post"));
        authorPanelLink->setStyleClass("link");
        authorPanelLink->clicked().connect(SLOT(this, BlogImpl::authorPanel));
        loginStatus_->bindWidget("author-panel-link", authorPanelLink);
    }
    else
    {
        loginStatus_->bindEmpty("userlist-link");
        loginStatus_->bindEmpty("author-panel-link");
    }

    loginStatus_->bindWidget("profile-link", profileLink);

    bindPanelTemplates();
} // end
/* ****************************************************************************
 * bind Panel Templates
 */
void BlogImpl::bindPanelTemplates()
{
    if (!session_.user()) { return; }
    Wt::Dbo::Transaction t(session_);

    if (authorPanel_)
    {
        Wt::WPushButton *newPost = new Wt::WPushButton(tr("new-post"));
        newPost->clicked().connect(SLOT(this, BlogImpl::newPost));
        WContainerWidget *unpublishedPosts = new WContainerWidget();
        showPosts(session_.user()->allPosts(Post::Unpublished), unpublishedPosts);

        authorPanel_->bindString("user", session_.user()->name);
        authorPanel_->bindInt("unpublished-count", (int)session_.user()->allPosts(Post::Unpublished).size());
        authorPanel_->bindInt("published-count", (int)session_.user()->allPosts(Post::Published).size());
        authorPanel_->bindWidget("new-post", newPost);
        authorPanel_->bindWidget("unpublished-posts", unpublishedPosts);
    }

    t.commit();
} // end
/* ****************************************************************************
 * edit Users
 */
void BlogImpl::editUsers()
{
    panel_->show();

    if (!users_)
    {
        users_ = new EditUsers(session_, basePath_);
        panel_->addWidget(users_);
        bindPanelTemplates();
    }

    panel_->setCurrentWidget(users_);
} // end
/* ****************************************************************************
 * author Panel
 */
void BlogImpl::authorPanel()
{
    panel_->show();
    if (!authorPanel_)
    {
        authorPanel_ = new Wt::WTemplate(tr("blog-author-panel"));
        panel_->addWidget(authorPanel_);
        bindPanelTemplates();
    }
    panel_->setCurrentWidget(authorPanel_);
} // end
/* ****************************************************************************
 * edit Profile
 */
void BlogImpl::editProfile()
{
    loginWidget_->letUpdatePassword(session_.login().user(), true);
} // end
/* ****************************************************************************
 * refresh
 */
void BlogImpl::refresh()
{
    //handlePathChange(wApp->internalPath());
    handlePathChange();
} // end
/* ****************************************************************************
 * handle Path Change
 */
//void BlogImpl::handlePathChange(const std::string& path)
void BlogImpl::handlePathChange()
{
    /* *-----------------------------------------------------------------------
     * Do we need path passed in as a
     */
    //(void)path; // Eat path warning
    Wt::WApplication *app = wApp;

    if (app->internalPathMatches(basePath_))
    {
        Wt::Dbo::Transaction t(session_);

        std::string path = app->internalPathNextPart(basePath_);

        items_->clear();

        if (users_)
        {
            delete users_;
            users_ = 0;
        }

        if (path.empty())
        {
            showPosts(session_.find<Post>("where state = ? order by date desc limit 10").bind(Post::Published), items_);
        }
        else if (path == "author")
        {
            std::string author = app->internalPathNextPart(basePath_ + path + '/');
            Wt::Dbo::ptr<User> user = findUser(author);

            if (user)
            {
                showPosts(user);
            }
            else
            {
                showError(tr("blog-no-author").arg(author));
            }
        }
        else if (path == "edituser")
        {
            editUser(app->internalPathNextPart(basePath_ + path + '/'));
        }
        else if (path == "all")
        {
            showArchive(items_);
        }
        else
        {
            std::string remainder = app->internalPath().substr(basePath_.length());
            showPostsByDateTopic(remainder, items_);
        }

        t.commit();
    }
} // end
/* ****************************************************************************
 * edit User
 */
void BlogImpl::editUser(const std::string& ids)
{
    if (!checkLoggedIn()) { return; }
    if (!checkAdministrator()) { return; }
    Wt::Dbo::dbo_traits<User>::IdType id;
    try
    {
        id = boost::lexical_cast<Wt::Dbo::dbo_traits<User>::IdType>(ids);
    }
    catch (boost::bad_lexical_cast&)
    {
        id = Wt::Dbo::dbo_traits<User>::invalidId();
    }
    panel_->show();
    try
    {
        Wt::Dbo::Transaction t(session_);
        Wt::Dbo::ptr<User> target(session_.load<User>(id));
        if (!userEditor_)
        {
            panel_->addWidget(userEditor_ = new EditUser(session_));
        }
        userEditor_->SwitchUser(target);
        panel_->setCurrentWidget(userEditor_);
    }
    catch (Wt::Dbo::ObjectNotFoundException)
    {
        if (!invalidUser_)
        {
            panel_->addWidget(invalidUser_ = new Wt::WTemplate(tr("blog-invaliduser")));
        }
        panel_->setCurrentWidget(invalidUser_);
    }
} // end
/* ****************************************************************************
 * check Logged In
 */
bool BlogImpl::checkLoggedIn()
{
    if (session_.user()) { return true; }
    panel_->show();
    if (!mustLoginwarning_)
    {
        panel_->addWidget(mustLoginwarning_ = new Wt::WTemplate(tr("blog-mustlogin")));
    }
    panel_->setCurrentWidget(mustLoginwarning_);
    return false;
}
/* ****************************************************************************
 * check Administrator
 */
bool BlogImpl::checkAdministrator()
{
    if (session_.user() && (session_.user()->role == User::Admin)) { return true; }
    panel_->show();
    if (!mustBeAdministratorwarning_)
    {
        panel_->addWidget(mustBeAdministratorwarning_ = new Wt::WTemplate(tr("blog-mustbeadministrator")));
    }
    panel_->setCurrentWidget(mustBeAdministratorwarning_);
    return false;
} // end
/* ****************************************************************************
 * find User
 */
Wt::Dbo::ptr<User> BlogImpl::findUser(const std::string& name)
{
    return session_.find<User>("where name = ?").bind(name);
} // end
/* ****************************************************************************
 * year Month Differ
 */
bool BlogImpl::yearMonthDiffer(const Wt::WDateTime& dt1, const Wt::WDateTime& dt2)
{
    return dt1.date().year() != dt2.date().year() || dt1.date().month() != dt2.date().month();
} // end
/* ****************************************************************************
 * show Archive
 */
void BlogImpl::showArchive(Wt::WContainerWidget *parent)
{
    static const char* dateFormat = "MMMM yyyy";

    new Wt::WText(tr("archive-title"), parent);

    Posts posts = session_.find<Post>("order by date desc");

    Wt::WDateTime formerDate;
    for (Posts::const_iterator i = posts.begin(); i != posts.end(); ++i)
    {
        if ((*i)->state != Post::Published)
        {
            continue;
        }
        if (formerDate.isNull() || yearMonthDiffer(formerDate, (*i)->date))
        {
            Wt::WText *title = new Wt::WText((*i)->date.date().toString(dateFormat), parent);
            title->setStyleClass("archive-month-title");
        }

        Wt::WAnchor *a = new Wt::WAnchor(Wt::WLink(Wt::WLink::InternalPath, basePath_ + (*i)->permaLink()), (*i)->title, parent);
        a->setInline(false);

        formerDate = (*i)->date;
    }
} // end
/* ****************************************************************************
 * show Posts By Date Topic
 */
void BlogImpl::showPostsByDateTopic(const std::string& path, Wt::WContainerWidget *parent)
{
    std::vector<std::string> parts;
    boost::split(parts, path, boost::is_any_of("/"));

    Wt::WDate lower, upper;
    try
    {
        int year = boost::lexical_cast<int>(parts[0]);

        if (parts.size() > 1)
        {
            int month = boost::lexical_cast<int>(parts[1]);

            if (parts.size() > 2)
            {
                int day = boost::lexical_cast<int>(parts[2]);

                lower.setDate(year, month, day);
                upper = lower.addDays(1);
            }
            else
            {
                lower.setDate(year, month, 1);
                upper = lower.addMonths(1);
            }
        }
        else
        {
            lower.setDate(year, 1, 1);
            upper = lower.addYears(1);
        }

        Posts posts = session_.find<Post>("where date >= ? and date < ? and (state = ? or author_id = ?)").bind(Wt::WDateTime(lower)).bind(Wt::WDateTime(upper)).bind(Post::Published).bind(session_.user().id());

        if (parts.size() > 3)
        {
            std::string title = parts[3];

            for (Posts::const_iterator i = posts.begin(); i != posts.end(); ++i)
            {
                if ((*i)->titleToUrl() == title)
                {
                    showPost(*i, PostView::Detail, parent);
                    return;
                }
            }
            showError(tr("blog-no-post"));
        }
        else
        {
            showPosts(posts, parent);
        }
    }
    catch (std::exception& e)
    {
        showError(tr("blog-no-post"));
    }
} // end
/* ****************************************************************************
 * new Post
 */
void BlogImpl::newPost()
{
    Wt::Dbo::Transaction t(session_);

    authorPanel();
    Wt::WContainerWidget *unpublishedPosts = authorPanel_->resolve<Wt::WContainerWidget *>("unpublished-posts");

    Wt::Dbo::ptr<Post> post(new Post);

    Post *p = post.modify();
    p->state = Post::Unpublished;
    p->author = session_.user();
    // FIX Multilingual
    p->title = "Title";
    p->briefSrc = "Brief ...";
    p->bodySrc = "Body ...";

    showPost(post, PostView::Edit, unpublishedPosts);

    t.commit();
} // end
/* ****************************************************************************
 * show Posts
 */
void BlogImpl::showPosts(Wt::Dbo::ptr<User> user)
{
    showPosts(user->latestPosts(), items_);
} // end
/* ****************************************************************************
 * show Posts
 */
void BlogImpl::showPosts(const Posts& posts, Wt::WContainerWidget* parent)
{
    for (Posts::const_iterator i = posts.begin(); i != posts.end(); ++i)
    {
        showPost(*i, PostView::Brief, parent);
    }
} // end
/* ****************************************************************************
 * show Post
 */
void BlogImpl::showPost(const Wt::Dbo::ptr<Post> post, PostView::RenderType type, Wt::WContainerWidget* parent)
{
    parent->addWidget(new PostView(session_, basePath_, post, type));
} // end
/* ****************************************************************************
 * show Error
 */
void BlogImpl::showError(const Wt::WString& msg)
{
    items_->addWidget(new Wt::WText(msg));
} // end
// --- End Of File ------------------------------------------------------------
