// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
#ifndef BLOG_SESSION_H_
#define BLOG_SESSION_H_

#include <Wt/WSignal>
#include <Wt/Auth/Login>

#include "BlogUserDatabase.h"

/* ****************************************************************************
 * Prototype class Comment
 */
class Comment;
/* ****************************************************************************
 * Prototype class Post
 */
class Post;
/* ****************************************************************************
 * Prototype class User
 */
class User;
/* ****************************************************************************
 * Blog Session
 * Derived from Session
 */
class BlogSession : public Wt::Dbo::Session
{
    public:
        BlogSession(Wt::Dbo::SqlConnectionPool& connectionPool);
        //
        static void configureAuth();
        //
        Wt::Dbo::ptr<User> user() const;
        //
        Wt::Signal< Wt::Dbo::ptr<Comment> >& commentsChanged() { return commentsChanged_; }
        BlogUserDatabase& users() { return users_; }
        Wt::Auth::Login& login() { return login_; }
        //
        Wt::Auth::PasswordService* passwordAuth() const;
        const std::vector<const Wt::Auth::OAuthService *>& oAuth() const;
        static Wt::Dbo::SqlConnectionPool* createConnectionPool(const std::string& dbParm);
    private:
        Wt::Dbo::SqlConnectionPool& connectionPool_;
        BlogUserDatabase users_;
        Wt::Auth::Login login_;

        Wt::Signal< Wt::Dbo::ptr<Comment> > commentsChanged_;
};

#endif // BLOG_SESSION_H_
// --- End Of File ------------------------------------------------------------
