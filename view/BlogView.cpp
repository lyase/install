/*
 * Copyright (C) 2008 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */

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

#include <Wt/Dbo/backend/Sqlite3>

#include <boost/algorithm/string/classification.hpp>
#include <boost/algorithm/string/split.hpp>
#include <boost/algorithm/string.hpp>

#include "BlogImpl.h"

/* ****************************************************************************
 * Blog View Constructor
 */
BlogView::BlogView(const std::string& basePath, Wt::Dbo::SqlConnectionPool& db, const std::string& rssFeedUrl, Wt::WContainerWidget* parent) : Wt::WCompositeWidget(parent), userChanged_(this)
{
    impl_ = new BlogImpl(basePath, db, rssFeedUrl, this);
    setImplementation(impl_);
} // end
/* ****************************************************************************
 * set Internal Base Path
 */
void BlogView::setInternalBasePath(const std::string& basePath)
{
    impl_->setInternalBasePath(basePath);
} // end
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
} // end
// --- End Of File ------------------------------------------------------------
