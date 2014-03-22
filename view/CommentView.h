// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */
#ifndef COMMENT_VIEW_H_
#define COMMENT_VIEW_H_

#include <Wt/WTemplate>
#include <Wt/Dbo/ptr>
/* ****************************************************************************
 * WTextArea
 */
namespace Wt
{
    class WTextArea;
}
/* ****************************************************************************
 * BlogSession
 */
class BlogSession;
/* ****************************************************************************
 * Comment
 */
class Comment;
/* ****************************************************************************
 * dbo
 */
namespace dbo = Wt::Dbo;
/* ****************************************************************************
 * CommentView
 */
class CommentView : public Wt::WTemplate
{
    public:
        // For new comment, goes immediately to edit mode
        CommentView(BlogSession& session, long long parentId);

        // Existing comment
        CommentView(BlogSession& session, dbo::ptr<Comment> comment);

        virtual void resolveString(const std::string& varName,
                                   const std::vector<Wt::WString>& args,
                                   std::ostream& result);

    protected:
        virtual void renderTemplate(std::ostream& result);

    private:
        BlogSession& session_;
        dbo::ptr<Comment> comment_;
        Wt::WTextArea *editArea_;

        void reply();
        void edit();
        void rm();
        void save();
        void cancel();
        bool isNew() const;

        void renderView();
};

#endif // COMMENT_VIEW_H_
// --- End Of File ------------------------------------------------------------
