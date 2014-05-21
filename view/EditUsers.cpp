#include "EditUsers.h"

#include <Wt/Dbo/Dbo>
#include <Wt/WApplication>
#include <Wt/WBreak>
#include <Wt/WContainerWidget>
#include <Wt/WLineEdit>
#include <Wt/WPushButton>
#include <Wt/WSignalMapper>
#include <Wt/WTemplate>
#include <Wt/WText>

//using namespace Wt;
//namespace dbo = Wt::Dbo;
/* ****************************************************************************
 * EditUsers
 */
EditUsers::EditUsers(Wt::Dbo::Session& aSession, const std::string& basePath) : session_(aSession), basePath_(basePath)
{
    setStyleClass("user-editor");
    setTemplateText(tr("edit-users-list"));
    limitEdit_  = new Wt::WLineEdit;
    Wt::WPushButton* goLimit = new Wt::WPushButton(tr("go-limit"));
    goLimit->clicked().connect(SLOT(this, EditUsers::LimitList));
    bindWidget("limit-edit",limitEdit_);
    bindWidget("limit-button",goLimit);
    LimitList();
} // end EditUsers::EditUsers
/* ****************************************************************************
 * Limit List
 */
void EditUsers::LimitList()
{
    Wt::WContainerWidget* list = new Wt::WContainerWidget;
    bindWidget("user-list",list);

    typedef Wt::Dbo::collection<Wt::Dbo::ptr<User> > UserList;
    Wt::Dbo::Transaction t(session_);
    UserList users = session_.find<User>().where("name like ?").bind("%"+limitEdit_->text()+"%").orderBy("name");

    Wt::WSignalMapper<Wt::Dbo::dbo_traits<User>::IdType >* userLinkMap = new Wt::WSignalMapper<Wt::Dbo::dbo_traits<User>::IdType >(this);
    userLinkMap->mapped().connect(this,&EditUsers::OnUserClicked);
    for (UserList::const_iterator i = users.begin(); i != users.end(); ++i)
    {
        Wt::WText* t = new Wt::WText((*i)->name, list);
        t->setStyleClass("link");
        new Wt::WBreak(list);
        userLinkMap->mapConnect(t->clicked(), (*i).id());
    }
    if (!users.size())
    {
        new Wt::WText(tr("no-users-found"),list);
    }
} // end void EditUsers::LimitList
/* ****************************************************************************
 * On User Clicked
 */
void EditUsers::OnUserClicked(Wt::Dbo::dbo_traits<User>::IdType id)
{
    wApp->setInternalPath(basePath_ + "edituser/" + boost::lexical_cast<std::string>(id), true);
} // end void EditUsers::OnUserClicked
/* ************************************************************************* */
/* ************************************************************************* */
/* ****************************************************************************
 * Edit User
 */
EditUser::EditUser(Wt::Dbo::Session& aSession) : Wt::WTemplate(tr("edit-user")), session_(aSession), roleButton_(new Wt::WPushButton)
{
    bindWidget("role-button",roleButton_);
    roleButton_->clicked().connect(SLOT(this, EditUser::SwitchRole));
} // end EditUser::EditUser
/* ****************************************************************************
 * Switch User
 */
void EditUser::SwitchUser(Wt::Dbo::ptr<User> target)
{
    target_ = target;
    BindTemplate();
} // end void EditUser::SwitchUser
/* ****************************************************************************
 * Bind Template
 */
void EditUser::BindTemplate()
{
    bindString("username", target_->name);
    if (target_->role == User::Admin)
    {
        roleButton_->setText(tr("demote-admin"));
    }
    else
    {
        roleButton_->setText(tr("promote-user"));
    }
} // end void EditUser::BindTemplate
/* ****************************************************************************
 * Switch Role
 */
void EditUser::SwitchRole()
{
    Wt::Dbo::Transaction t(session_);
    target_.reread();
    if (target_->role == User::Admin)
    {
        target_.modify()->role = User::Visitor;
    }
    else
    {
        target_.modify()->role = User::Admin;
    }
    t.commit();
    BindTemplate();
} // end void EditUser::SwitchRole
// --- End Of File ------------------------------------------------------------
