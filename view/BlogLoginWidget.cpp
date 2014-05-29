/*
 * Copyright (C) 2011 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
#include <Wt/WLineEdit>
#include <Wt/WTemplate>
#include <Wt/WText>
#include <Wt/Auth/PasswordService>
#include <Wt/Auth/RegistrationWidget>
#include "BlogLoginWidget.h"
#include "model/BlogSession.h"
#include "model/Token.h"
#include "model/User.h"
/* ****************************************************************************
 * Blog Login Widget
 */
BlogLoginWidget::BlogLoginWidget(BlogSession &session, const std::string& basePath, Wt::WContainerWidget *parent) : AuthWidget(session.login(), parent)
{
    setInline(true);

    Wt::Auth::AuthModel *model = new Wt::Auth::AuthModel(session.passwordAuth()->baseAuth(), session.users(), this);
    model->addPasswordAuth(session.passwordAuth());
    model->addOAuth(session.oAuth());

    setModel(model);

    setInternalBasePath(basePath + "login");
} // end
/* ****************************************************************************
 * create Login View
 */
void BlogLoginWidget::createLoginView()
{
    AuthWidget::createLoginView();

    setTemplateText(tr("blog-login"));

    Wt::WLineEdit *userName = resolve<Wt::WLineEdit *>("user-name");
    userName->setEmptyText("login");
    userName->setToolTip("login");

    Wt::WLineEdit *password = resolve<Wt::WLineEdit *>("password");
    password->setEmptyText("password");
    password->setToolTip("password");
    password->enterPressed().connect(this, &BlogLoginWidget::attemptPasswordLogin);
} // end
/* ****************************************************************************
 * create Logged In View
 */
void BlogLoginWidget::createLoggedInView()
{
    AuthWidget::createLoggedInView();

    Wt::WText *logout = new Wt::WText(tr("logout"));
    logout->setStyleClass("link");
    logout->clicked().connect(&login(), &Wt::Auth::Login::logout);
    bindWidget("logout", logout);
} // end
// --- End Of File ------------------------------------------------------------
