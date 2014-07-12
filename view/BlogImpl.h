/* ****************************************************************************
 * Blog Impl
 *
 * Modified for Witty Wizard
 *
 */
#ifndef BLOGIMPL_H
#define BLOGIMPL_H

#include <Wt/WApplication>
#include <Wt/WContainerWidget>
#include <Wt/WEnvironment>

#include <Wt/WAnchor>
#include <Wt/WCheckBox>
#include <Wt/WLineEdit>
#include <Wt/WPushButton>
#include <Wt/WStackedWidget>
#include <Wt/WTemplate>
#include <Wt/WText>

#include "model/BlogSession.h"
#include "EditUsers.h"
#include "BlogLoginWidget.h"
#include "BlogView.h"
#include "PostView.h"
/* ****************************************************************************
 * Prototype Blog View
 */
class BlogView;
/* ****************************************************************************
 * Blog Impl
 */
class BlogImpl : public Wt::WContainerWidget
{
    public:
        BlogImpl(const std::string& basePath, const std::string& appPath, Wt::Dbo::SqlConnectionPool& connectionPool, const std::string& rssFeedUrl, const std::string& defaultTheme, BlogView* blogView);
        void SetInternalBasePath(const std::string& basePath);
        virtual ~BlogImpl();
        /* --------------------------------------------------------------------
         * session
         */
        BlogSession& session()  { return session_; }

    private:
        void OnUserChanged();
        void Logout();
        void LoggedOut();
        void LoggedIn();
        void BindPanelTemplates();
        void EditTheUsers();
        void AuthorPanel();
        void EditProfile();
        void refresh();
        //void handlePathChange(const std::string& path);
        void HandlePathChange();
        void EditTheUser(const std::string& ids);
        bool CheckLoggedIn();
        bool CheckAdministrator();
        Wt::Dbo::ptr<User> FindUser(const std::string& name);
        bool YearMonthDiffer(const Wt::WDateTime& dt1, const Wt::WDateTime& dt2);
        void ShowArchive(Wt::WContainerWidget* parent);
        void ShowPostsByDateTopic(const std::string& path, Wt::WContainerWidget* parent);
        void NewPost();
        void ShowPosts(Wt::Dbo::ptr<User> user);
        void ShowPosts(const Posts& posts, Wt::WContainerWidget* parent);
        void ShowPost(const Wt::Dbo::ptr<Post> post, PostView::RenderType type, Wt::WContainerWidget* parent);
        void ShowError(const Wt::WString& msg);
        //
        std::string basePath_;
        BlogSession session_;
        std::string rssFeedUrl_;
        std::string defaultTheme_;
        BlogView*   blogView_;
        //
        BlogLoginWidget* loginWidget_;

        Wt::WContainerWidget* items_;
        Wt::WStackedWidget* panel_;
        Wt::WTemplate* authorPanel_;
        Wt::WTemplate* mustLoginwarning_;
        Wt::WTemplate* mustBeAdministratorwarning_;
        Wt::WTemplate* invalidUser_;
        Wt::WTemplate* loginStatus_;
        EditUsers* users_;
        EditUser*  userEditor_;
};
#endif // BLOGIMPL_H
// --- End Of File ------------------------------------------------------------
