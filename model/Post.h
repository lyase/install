// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
#ifdef BLOGMAN
#ifndef POST_H_
#define POST_H_

#include <Wt/WDate>
#include <Wt/WString>

#include <Wt/Dbo/Types>
#include <Wt/Dbo/WtSqlTraits>

#include "Comment.h"
#include "Tag.h"
/* ****************************************************************************
 * Prototype User
 */
class User;
/* ****************************************************************************
 * ptr Comments
 */
typedef Wt::Dbo::collection< Wt::Dbo::ptr<Comment> > Comments;
/* ****************************************************************************
 * ptr Tags
 */
typedef Wt::Dbo::collection< Wt::Dbo::ptr<Tag> > Tags;
/* ****************************************************************************
 * Post
 */
class Post : public Wt::Dbo::Dbo<Post>
{
    public:
        enum State
        {
            Unpublished = 0,
            Published = 1
        };

        Wt::Dbo::ptr<User> author;
        State          state;

        Wt::WDateTime  date;
        Wt::WString    title;
        Wt::WString    briefSrc;
        Wt::WString    briefHtml;
        Wt::WString    bodySrc;
        Wt::WString    bodyHtml;

        Comments       comments;
        Tags           tags;

        std::string permaLink() const;
        std::string commentCount() const;
        Wt::Dbo::ptr<Comment> rootComment() const;
        std::string titleToUrl() const;

        template<class Action>
        void persist(Action& a)
        {
            Wt::Dbo::field(a, state,     "state");
            Wt::Dbo::field(a, date,      "date");
            Wt::Dbo::field(a, title,     "title");
            Wt::Dbo::field(a, briefSrc,  "brief_src");
            Wt::Dbo::field(a, briefHtml, "brief_html");
            Wt::Dbo::field(a, bodySrc,   "body_src");
            Wt::Dbo::field(a, bodyHtml,  "body_html");

            Wt::Dbo::belongsTo(a, author, "author");

            Wt::Dbo::hasMany(a, comments, Wt::Dbo::ManyToOne,  "post");
            Wt::Dbo::hasMany(a, tags,     Wt::Dbo::ManyToMany, "post_tag");
        }
};

DBO_EXTERN_TEMPLATES(Post);
#endif // POST_H_
#endif // BLOGMAN
// --- End Of File ------------------------------------------------------------
