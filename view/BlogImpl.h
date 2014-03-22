#ifndef BLOGIMPL_H
#define BLOGIMPL_H

#include <Wt/WCompositeWidget>
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
class BlogView;
/* ****************************************************************************
 * Blog Impl
 */
class BlogImpl : public Wt::WContainerWidget
{
    public:
        BlogImpl(const std::string& basePath, Wt::Dbo::SqlConnectionPool& connectionPool, const std::string& rssFeedUrl, BlogView* blogView);
        void setInternalBasePath(const std::string& basePath);
        virtual ~BlogImpl();
        /* ********************************************************************
         * session
         */
        BlogSession& session()
        {
            return session_;
        }

    private:
        void onUserChanged();
        void logout();
        void loggedOut();
        void loggedIn();
        void bindPanelTemplates();
        void editUsers();
        void authorPanel();
        void editProfile();
        void refresh();
        void handlePathChange(const std::string& path);
        void editUser(const std::string& ids);
        bool checkLoggedIn();
        bool checkAdministrator();
        Wt::Dbo::ptr<User> findUser(const std::string& name);
        bool yearMonthDiffer(const Wt::WDateTime& dt1, const Wt::WDateTime& dt2);
        void showArchive(Wt::WContainerWidget* parent);
        void showPostsByDateTopic(const std::string& path, Wt::WContainerWidget* parent);
        void newPost();
        void showPosts(dbo::ptr<User> user);
        void showPosts(const Posts& posts, Wt::WContainerWidget* parent);
        void showPost(const dbo::ptr<Post> post, PostView::RenderType type, Wt::WContainerWidget* parent);
        void showError(const Wt::WString& msg);

        std::string basePath_, rssFeedUrl_;
        BlogSession session_;
        BlogView*   blogView_;
        BlogLoginWidget* loginWidget_;

        Wt::WStackedWidget* panel_;
        Wt::WTemplate* authorPanel_;
        EditUsers* users_;
        EditUser*  userEditor_;
        Wt::WTemplate* mustLoginWarning_;
        Wt::WTemplate* mustBeAdministratorWarning_;
        Wt::WTemplate* invalidUser_;
        Wt::WTemplate* loginStatus_;
        Wt::WContainerWidget* items_;
};


#endif // BLOGIMPL_H
// --- End Of File ------------------------------------------------------------
