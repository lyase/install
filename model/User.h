// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */
#ifndef USER_H_
#define USER_H_

#include <Wt/Dbo/Types>

#include "Post.h"
/* ****************************************************************************
 * Prototype Comment
 */
class Comment;
/* ****************************************************************************
 * Prototype Token
 */
class Token;
/* ****************************************************************************
 * Comments
 */
typedef Wt::Dbo::collection< Wt::Dbo::ptr<Comment> > Comments;
/* ****************************************************************************
 * ptr Posts
 */
typedef Wt::Dbo::collection< Wt::Dbo::ptr<Post> > Posts;
/* ****************************************************************************
 * ptr Tokens
 */
typedef Wt::Dbo::collection< Wt::Dbo::ptr<Token> > Tokens;
/* ****************************************************************************
 * User
 */
class User
{
    public:
        User();

        enum Role
        {
            Visitor = 0,
            Admin = 1
        };

        Wt::WString name;
        Role role;

        std::string password;
        std::string passwordMethod;
        std::string passwordSalt;
        int failedLoginAttempts;
        Wt::WDateTime lastLoginAttempt;

        std::string oAuthId;
        std::string oAuthProvider;

        Tokens authTokens;
        Comments comments;
        Posts posts;

        Posts latestPosts(int count = 10) const;
        Posts allPosts(Post::State state) const;

        template<class Action>
        void persist(Action& a)
        {
            Wt::Dbo::field(a, name,                "name");
            Wt::Dbo::field(a, password,            "password");
            Wt::Dbo::field(a, passwordMethod,      "password_method");
            Wt::Dbo::field(a, passwordSalt,        "password_salt");
            Wt::Dbo::field(a, role,                "role");
            Wt::Dbo::field(a, failedLoginAttempts, "failed_login_attempts");
            Wt::Dbo::field(a, lastLoginAttempt,    "last_login_attempt");
            Wt::Dbo::field(a, oAuthId,             "oauth_id");
            Wt::Dbo::field(a, oAuthProvider,       "oauth_provider");

            Wt::Dbo::hasMany(a, comments,   Wt::Dbo::ManyToOne, "author");
            Wt::Dbo::hasMany(a, posts,      Wt::Dbo::ManyToOne, "author");
            Wt::Dbo::hasMany(a, authTokens, Wt::Dbo::ManyToOne, "user");
        }
};

DBO_EXTERN_TEMPLATES(User);

#endif // USER_H_
// --- End Of File ------------------------------------------------------------
