// This may look like C code, but it's really -*- C++ -*-
/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */
#ifndef POST_VIEW_H_
#define POST_VIEW_H_

#include <Wt/WTemplate>
#include <Wt/Dbo/ptr>

#include "../model/Post.h"
/* ****************************************************************************
 * BlogSession
 */
class BlogSession;
/* ****************************************************************************
 * Comment
 */
class Comment;
/* ****************************************************************************
 * PostView
 */
class PostView : public Wt::WTemplate
{
    public:
        enum RenderType { Brief, Detail, Edit };

        PostView(BlogSession& session, const std::string& basePath, Wt::Dbo::ptr<Post> post, RenderType type);

        virtual void resolveString(const std::string& varName, const std::vector<Wt::WString>& args, std::ostream& result);

    protected:
        virtual void renderTemplate(std::ostream& result);

    private:
        BlogSession& session_;
        std::string basePath_;
        Wt::Dbo::ptr<Post> post_;

        RenderType viewType_;
        Wt::WText *commentCount_;
        Wt::WLineEdit *titleEdit_;
        Wt::WTextArea *briefEdit_, *bodyEdit_;

        void render(RenderType type);
        void UpdateCommentCount(Wt::Dbo::ptr<Comment> comment);
        void SaveEdit();
        void ShowView();

        void Publish();
        void Retract();
        void ShowEdit();
        void Rm();

        void SetState(Post::State state);
};

#endif // POST_VIEW_H_
// --- End Of File ------------------------------------------------------------
