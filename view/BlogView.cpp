/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
#ifdef BLOGMAN
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

#include <boost/algorithm/string/classification.hpp>
#include <boost/algorithm/string/split.hpp>
#include <boost/algorithm/string.hpp>

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
#include "BlogImpl.h"
/* ****************************************************************************
 * Blog View Constructor
 */
BlogView::BlogView(const std::string& basePath, const std::string& appPath, Wt::Dbo::SqlConnectionPool& db, const std::string& rssFeedUrl, const std::string& defaultTheme, Wt::WContainerWidget* parent) : Wt::WCompositeWidget(parent), userChanged_(this)
{
    impl_ = new BlogImpl(basePath, appPath, db, rssFeedUrl, defaultTheme, this);
    setImplementation(impl_);
} // end BlogView
/* ****************************************************************************
 * set Internal Base Path
 */
void BlogView::SetInternalBasePath(const std::string& basePath)
{
    impl_->SetInternalBasePath(basePath);
} // end SetInternalBasePath
/* ****************************************************************************
 * user
 */
Wt::WString BlogView::user()
{
    if (impl_->session().user())
    {
        return impl_->session().user()->name;
    }
    else
    {
        return Wt::WString::Empty;
    }
} // end user
#endif // BLOGMAN
// --- End Of File ------------------------------------------------------------
