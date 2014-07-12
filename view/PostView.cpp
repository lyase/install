/*
 * Copyright (C) 2009 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */
#ifdef BLOGMAN

#include "CommentView.h"
#include "PostView.h"
#include "asciidoc/asciidoc.h"

#include "../model/BlogSession.h"
#include "../model/Comment.h"
#include "../model/Tag.h"
#include "../model/Token.h"
#include "../model/User.h"

#include <Wt/WAnchor>
#include <Wt/WLineEdit>
#include <Wt/WPushButton>
#include <Wt/WText>
#include <Wt/WTextArea>

/* ****************************************************************************
 * Post View
 */
PostView::PostView(BlogSession& session, const std::string& basePath, Wt::Dbo::ptr<Post> post, RenderType type) : session_(session), basePath_(basePath), post_(post)
{
    viewType_ = Brief;
    render(type);
} // end PostView::PostView(
/* ****************************************************************************
 * Render Template
 */
void PostView::renderTemplate(std::ostream& result)
{
    Wt::Dbo::Transaction t(session_);

    WTemplate::renderTemplate(result);

    post_.purge();

    t.commit();
} // end void PostView::RenderTemplate(
/* ****************************************************************************
 * Resolve String
 */
void PostView::resolveString(const std::string& varName, const std::vector<Wt::WString>& args, std::ostream& result)
{
    if (varName == "title")
    {
        format(result, post_->title);
    }
    else if (varName == "date")
    {
        format(result, post_->date.toString("dddd, MMMM d, yyyy @ HH:mm"));
    }
    else if (varName == "brief")
    {
        if (!post_->briefSrc.empty())
        {
            format(result, post_->briefHtml, Wt::XHTMLText);
        }
        else
        {
            format(result, post_->bodyHtml, Wt::XHTMLText);
        }
    }
    else if (varName == "brief+body")
    {
        format(result, "<div>" + post_->briefHtml + "</div><div id=\"" + basePath_ + post_->permaLink() + "/more\"><div>" + post_->bodyHtml + "</div></div>", Wt::XHTMLUnsafeText);
    }
    else
    {
        WTemplate::resolveString(varName, args, result);
    }
} // end void PostView::ResolveString
/* ****************************************************************************
 * Render
 */
void PostView::render(RenderType type)
{
    if (type != Edit)
    {
        viewType_ = type;
    }
    clear();

    switch (type)
    {
        case Detail:
            {
                setTemplateText(tr("blog-post"));

                commentCount_ = new Wt::WText(post_->commentCount());

                CommentView *comments = new CommentView(session_, post_->rootComment());
                session_.commentsChanged().connect(this, &PostView::UpdateCommentCount);

                bindWidget("comment-count", commentCount_);
                bindWidget("comments", comments);
                bindString("anchor", basePath_ + post_->permaLink());

                break;
            }
        case Brief:
            {
                setTemplateText(tr("blog-post-brief"));

                Wt::WAnchor *titleAnchor = new Wt::WAnchor(Wt::WLink(Wt::WLink::InternalPath, basePath_ + post_->permaLink()), post_->title);
                bindWidget("title", titleAnchor);

                if (!post_->briefSrc.empty())
                {
                    Wt::WAnchor *moreAnchor = new Wt::WAnchor(Wt::WLink(Wt::WLink::InternalPath, basePath_ + post_->permaLink() + "/more"), tr("blog-read-more"));
                    bindWidget("read-more", moreAnchor);
                }
                else
                {
                    bindString("read-more", Wt::WString::Empty);
                }

                commentCount_ = new Wt::WText("(" + post_->commentCount() + ")");

                Wt::WAnchor *commentsAnchor = new Wt::WAnchor(Wt::WLink(Wt::WLink::InternalPath, basePath_ + post_->permaLink() + "/comments"));
                commentsAnchor->addWidget(commentCount_);
                bindWidget("comment-count", commentsAnchor);

                break;
            }
        case Edit:
            {
                setTemplateText(tr("blog-post-edit"));

                bindWidget("title-edit", titleEdit_ = new Wt::WLineEdit(post_->title));
                bindWidget("brief-edit", briefEdit_ = new Wt::WTextArea(post_->briefSrc));
                bindWidget("body-edit", bodyEdit_ = new Wt::WTextArea(post_->bodySrc));

                Wt::WPushButton *saveButton = new Wt::WPushButton(tr("save"));
                Wt::WPushButton *cancelButton = new Wt::WPushButton(tr("cancel"));
                bindWidget("save", saveButton);
                bindWidget("cancel", cancelButton);

                saveButton->clicked().connect(this, &PostView::SaveEdit);
                cancelButton->clicked().connect(this, &PostView::ShowView);

                break;
            }
    }

    if (type == Detail || type == Brief)
    {
        if (session_.user() == post_->author)
        {
            Wt::WPushButton *publishButton;
            if (post_->state != Post::Published)
            {
                publishButton = new Wt::WPushButton(tr("publish"));
                publishButton->clicked().connect(this, &PostView::Publish);
            }
            else
            {
                publishButton = new Wt::WPushButton(tr("retract"));
                publishButton->clicked().connect(this, &PostView::Retract);
            }
            bindWidget("publish", publishButton);

            Wt::WPushButton *editButton = new Wt::WPushButton(tr("edit"));
            editButton->clicked().connect(this, &PostView::ShowEdit);
            bindWidget("edit", editButton);

            Wt::WPushButton *deleteButton = new Wt::WPushButton(tr("delete"));
            deleteButton->clicked().connect(this, &PostView::Rm);
            bindWidget("delete", deleteButton);
        }
        else
        {
            bindString("publish", Wt::WString::Empty);
            bindString("edit", Wt::WString::Empty);
            bindString("delete", Wt::WString::Empty);
        }
    }

    Wt::WAnchor *postAnchor = new Wt::WAnchor(Wt::WLink(Wt::WLink::InternalPath, basePath_ + "author/" + post_->author->name.toUTF8()),  post_->author->name);
    bindWidget("author", postAnchor);
} // end void PostView::Render
/* ****************************************************************************
 * Save Edit
 */
void PostView::SaveEdit()
{
    Wt::Dbo::Transaction t(session_);

    bool newPost = post_.id() == -1;

    Post *post = post_.modify();

    post->title = titleEdit_->text();
    post->briefSrc = briefEdit_->text();
    post->bodySrc = bodyEdit_->text();

    post->briefHtml = asciidoc(post->briefSrc);
    post->bodyHtml = asciidoc(post->bodySrc);

    if (newPost)
    {
        session_.add(post_);

        post->date = Wt::WDateTime::currentDateTime();
        post->state = Post::Unpublished;
        post->author = session_.user();

        Wt::Dbo::ptr<Comment> rootComment = session_.add(new Comment);
        rootComment.modify()->post = post_;
    }

    session_.flush();

    render(viewType_);

    t.commit();
} // end void PostView::SaveEdit
/* ****************************************************************************
 * Show View
 */
void PostView::ShowView()
{
    if (post_.id() == -1)
    {
        delete this;
    }
    else
    {
        Wt::Dbo::Transaction t(session_);
        render(viewType_);
        t.commit();
    }
} // end void PostView::ShowView
/* ****************************************************************************
 * Publish
 */
void PostView::Publish()
{
    SetState(Post::Published);
} // end void PostView::Publish
/* ****************************************************************************
 * Retract
 */
void PostView::Retract()
{
    SetState(Post::Unpublished);
} // end void PostView::Retract
/* ****************************************************************************
 * Set State
 */
void PostView::SetState(Post::State state)
{
    Wt::Dbo::Transaction t(session_);

    post_.modify()->state = state;
    if (state == Post::Published)
    {
        post_.modify()->date = Wt::WDateTime::currentDateTime();
    }
    render(viewType_);

    t.commit();
} // end void PostView::SetState
/* ****************************************************************************
 * Show Edit
 */
void PostView::ShowEdit()
{
    Wt::Dbo::Transaction t(session_);

    render(Edit);

    t.commit();
} // end void PostView::ShowEdit
/* ****************************************************************************
 * Rm
 */
void PostView::Rm()
{
    Wt::Dbo::Transaction t(session_);
    post_.remove();
    t.commit();

    delete this;
} // end void PostView::Rm
/* ****************************************************************************
 * update Comment Count
 */
void PostView::UpdateCommentCount(Wt::Dbo::ptr<Comment> comment)
{
    if (comment->post == post_)
    {
        std::string count = comment->post->commentCount();

        if (commentCount_->text().toUTF8()[0] == '(')
        {
            commentCount_->setText("(" + count + ")");
        }
        else
        {
            commentCount_->setText(count);
        }
    }
} // end void PostView::UpdateCommentCount
#endif // BLOGMAN
// --- End Of File ------------------------------------------------------------
