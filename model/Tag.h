// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */
#ifndef TAG_H_
#define TAG_H_

#include <Wt/Dbo/Types>
/* ****************************************************************************
 * Post
 */
class Post;
/* ****************************************************************************
 * dbo
 */
namespace dbo = Wt::Dbo;
/* ****************************************************************************
 * Posts
 */
typedef dbo::collection< dbo::ptr<Post> > Posts;
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
            dbo::field(a, name, "name");

            dbo::hasMany(a, posts, dbo::ManyToMany, "post_tag");
        }
};

DBO_EXTERN_TEMPLATES(Tag);

#endif // TAG_H_
// --- End Of File ------------------------------------------------------------
