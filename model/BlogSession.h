// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */
#ifndef BLOG_SESSION_H_
#define BLOG_SESSION_H_

#include <Wt/WSignal>
#include <Wt/Auth/Login>
// Database
#include <Wt/Dbo/Session>
#include <Wt/Dbo/ptr>
#include <Wt/Dbo/Dbo>
#ifdef POSTGRES
    #include <Wt/Dbo/backend/Postgres>
#elif SQLITE3
    #include <Wt/Dbo/backend/Sqlite3>
#elif MYSQL
    #include <Wt/Dbo/backend/MySQL>
#elif FIREBIRD
    #include <Wt/Dbo/backend/Firebird>
#endif // FIREBIRD
#include "BlogUserDatabase.h"
/* ****************************************************************************
 * OAuthService
 * PasswordService
 */
namespace Wt
{
    namespace Auth
    {
        class OAuthService;
        class PasswordService;
    }
}
/* ****************************************************************************
 * dbo
 */
namespace dbo = Wt::Dbo;
/* ****************************************************************************
 * Comment
 */
class Comment;
/* ****************************************************************************
 * Post
 */
class Post;
/* ****************************************************************************
 * User
 */
class User;
/* ****************************************************************************
 * Blog Session
 */
class BlogSession : public Wt::Dbo::Session
{
    public:
        static void configureAuth();

        BlogSession(Wt::Dbo::SqlConnectionPool& connectionPool);

        Wt::Dbo::ptr<User> user() const;

        Wt::Signal< Wt::Dbo::ptr<Comment> >& commentsChanged()
        {
            return commentsChanged_;
        }
        BlogUserDatabase& users() { return users_; }
        Wt::Auth::Login& login() { return login_; }

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
