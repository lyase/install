// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
#ifndef BLOG_VIEW_H_
#define BLOG_VIEW_H_

#include <Wt/WCompositeWidget>
#include "BlogImpl.h"
/* ****************************************************************************
 * Prototype Blog Impl
 */
class BlogImpl;
/* ****************************************************************************
 * BlogView
 */
class BlogView : public Wt::WCompositeWidget
{
    public:
        BlogView(const std::string& basePath, Wt::Dbo::SqlConnectionPool& db, const std::string& rssFeedUrl, const std::string& defaultTheme, Wt::WContainerWidget *parent = 0);

        void SetInternalBasePath(const std::string& basePath);

        Wt::WString user();
        void login(const std::string& user);
        void logout();

        Wt::Signal<Wt::WString>& userChanged() { return userChanged_; }

    private:
        BlogImpl *impl_;
        Wt::Signal<Wt::WString> userChanged_;
};
#endif // BLOG_VIEW_H_
// --- End Of File ------------------------------------------------------------
