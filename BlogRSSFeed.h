// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
#ifndef BLOG_RSS_FEED_H_
#define BLOG_RSS_FEED_H_

#include <Wt/WResource>

/* ****************************************************************************
 * Prototype class BlogSession
 */
class BlogSession;
/* ****************************************************************************
 * BlogRSSFeed
 */
class BlogRSSFeed : public Wt::WResource
{
    public:
        BlogRSSFeed();
        virtual ~BlogRSSFeed();

    protected:
        virtual void handleRequest(const Wt::Http::Request &request, Wt::Http::Response &response);
};

#endif // BLOG_RSS_FEED_H_
// --- End Of File ------------------------------------------------------------
