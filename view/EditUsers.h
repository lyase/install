/* ****************************************************************************
 * Edit Users
 */
#ifndef EDIT_USERS_H_
#define EDIT_USERS_H_

#include "../model/User.h"
#include "../model/Tag.h"
#include "../model/Token.h"
#include "../model/Comment.h"

#include <Wt/Dbo/ptr>
#include <Wt/WStackedWidget>
#include <Wt/WTemplate>
/* ****************************************************************************
 * WLineEdit
 * WPushButton
 * Session
 */
namespace Wt
{
    class WLineEdit;
    class WPushButton;
    namespace Dbo
    {
        class Session;
    }
}
/* ****************************************************************************
 * Edit Users
 */
class EditUsers : public Wt::WTemplate
{
    public:
        EditUsers(Wt::Dbo::Session& aSesssion, const std::string& basePath);
    private:
        void OnUserClicked(Wt::Dbo::dbo_traits<User>::IdType id);
        void LimitList();

        Wt::Dbo::Session& session_;
        std::string basePath_;
        Wt::WLineEdit* limitEdit_;
};
/* ****************************************************************************
 * Edit User
 */
class EditUser : public Wt::WTemplate
{
    public:
        EditUser(Wt::Dbo::Session& aSesssion);
        void SwitchUser(Wt::Dbo::ptr<User> target);
    private:
        void BindTemplate();
        void SwitchRole();

        Wt::Dbo::Session& session_;
        Wt::Dbo::ptr<User> target_;
        Wt::WPushButton* roleButton_;
};

#endif
// --- End Of File ------------------------------------------------------------
