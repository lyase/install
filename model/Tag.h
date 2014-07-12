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
#ifndef TAG_H_
#define TAG_H_

#include <Wt/Dbo/Types>
/* ****************************************************************************
 * Prototype Post
 */
class Post;
/* ****************************************************************************
 * Posts
 */
typedef Wt::Dbo::collection< Wt::Dbo::ptr<Post> > Posts;
/* ****************************************************************************
 * Tag
 */
class Tag
{
    public:
        Tag() { }
        Tag(const std::string& aName) : name(aName) { }

        std::string name;

        Posts posts;

        template<class Action>
        void persist(Action& a)
        {
            Wt::Dbo::field(a, name, "name");

            Wt::Dbo::hasMany(a, posts, Wt::Dbo::ManyToMany, "post_tag");
        }
};

DBO_EXTERN_TEMPLATES(Tag);
#endif // TAG_H_
#endif // BLOGMAN
// --- End Of File ------------------------------------------------------------
