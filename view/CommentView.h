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
 * Prototype BlogSession
 */
class BlogSession;
/* ****************************************************************************
 * Prototype Comment
 */
class Comment;
/* ****************************************************************************
 * CommentView
 */
class CommentView : public Wt::WTemplate
{
    public:
        // For new comment, goes immediately to edit mode
        CommentView(BlogSession& session, long long parentId);

        // Existing comment
        CommentView(BlogSession& session, Wt::Dbo::ptr<Comment> comment);

        virtual void resolveString(const std::string& varName, const std::vector<Wt::WString>& args, std::ostream& result);

    protected:
        virtual void renderTemplate(std::ostream& result);

    private:
        BlogSession& session_;
        Wt::Dbo::ptr<Comment> comment_;
        Wt::WTextArea *editArea_;

        void Reply();
        void Edit();
        void Rm();
        void Save();
        void Cancel();
        bool IsNew() const;

        void RenderView();
};

#endif // COMMENT_VIEW_H_
// --- End Of File ------------------------------------------------------------
