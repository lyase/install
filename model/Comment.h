// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */
#ifndef COMMENT_H_
#define COMMENT_H_

#include <Wt/WDateTime>

#include <Wt/Dbo/Types>
#include <Wt/Dbo/WtSqlTraits>
/* ****************************************************************************
 * Prototype Comment
 */
class Comment;
/* ****************************************************************************
 * Prototype Post
 */
class Post;
/* ****************************************************************************
 * Prototype User
 */
class User;
/* ****************************************************************************
 * ptr Comments
 */
typedef Wt::Dbo::collection<Wt::Dbo::ptr<Comment> > Comments;
/* ****************************************************************************
 * Comment
 */
class Comment
{
    public:
        Wt::Dbo::ptr<User>    author;
        Wt::Dbo::ptr<Post>    post;
        Wt::Dbo::ptr<Comment> parent;

        Wt::WDateTime     date;

        void setText(const Wt::WString& text);
        void setDeleted();

        const Wt::WString& textSrc() const { return textSrc_; }
        const Wt::WString& textHtml() const { return textHtml_; }

        Comments          children;

        template<class Action>
        void persist(Action& a)
        {
            Wt::Dbo::field(a, date, "date");
            Wt::Dbo::field(a, textSrc_, "text_source");
            Wt::Dbo::field(a, textHtml_, "text_html");

            Wt::Dbo::belongsTo(a, post, "post", Wt::Dbo::OnDeleteCascade);
            Wt::Dbo::belongsTo(a, author, "author");
            Wt::Dbo::belongsTo(a, parent, "parent", Wt::Dbo::OnDeleteCascade);

            Wt::Dbo::hasMany(a, children, Wt::Dbo::ManyToOne, "parent");
        }

    private:
        Wt::WString textSrc_;
        Wt::WString textHtml_;
};

DBO_EXTERN_TEMPLATES(Comment);

#endif // COMMENT_H_
// --- End Of File ------------------------------------------------------------
