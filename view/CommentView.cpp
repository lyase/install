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

#include "../model/BlogSession.h"
#include "../model/Comment.h"
#include "../model/Tag.h"
#include "../model/Token.h"
#include "../model/User.h"
#include "../model/Post.h"

#include <Wt/WContainerWidget>
#include <Wt/WPushButton>
#include <Wt/WTemplate>
#include <Wt/WText>
#include <Wt/WTextArea>

/* ****************************************************************************
 * Comment View
 */
CommentView::CommentView(BlogSession& session, Wt::Dbo::ptr<Comment> comment) : session_(session), comment_(comment)
{
    comment_ = comment;

    RenderView();
} // end CommentView::CommentView
/* ****************************************************************************
 * Comment View
 */
CommentView::CommentView(BlogSession& session, long long parentId) : session_(session)
{
    Wt::Dbo::ptr<Comment> parent = session_.load<Comment>(parentId);

    comment_.reset(new Comment);
    comment_.modify()->parent = parent;
    comment_.modify()->post = parent->post;

    Edit();
} // end CommentView::CommentView
/* ****************************************************************************
 * Is New
 */
bool CommentView::IsNew() const
{
    return comment_.id() == -1;
} // end bool CommentView::IsNew()
/* ****************************************************************************
 * Edit
 */
void CommentView::Edit()
{
    clear();

    Wt::Dbo::Transaction t(session_);

    setTemplateText(tr("blog-edit-comment"));

    editArea_ = new Wt::WTextArea();
    editArea_->setText(comment_->textSrc());
    editArea_->setFocus();

    Wt::WPushButton *save = new Wt::WPushButton(tr("save"));
    save->clicked().connect(this, &CommentView::Save);

    Wt::WPushButton *cancel = new Wt::WPushButton(tr("cancel"));
    cancel->clicked().connect(this, &CommentView::Cancel);

    bindWidget("area", editArea_);
    bindWidget("save", save);
    bindWidget("cancel", cancel);

    t.commit();
} // end void CommentView::Edit(
/* ****************************************************************************
 * Cancel
 */
void CommentView::Cancel()
{
    if (IsNew())
    {
        delete this;
    }
    else
    {
        Wt::Dbo::Transaction t(session_);
        RenderView();
        t.commit();
    }
} // end void CommentView::Cancel
/* ****************************************************************************
 * Render Template
 */
void CommentView::renderTemplate(std::ostream& result)
{
    Wt::Dbo::Transaction t(session_);

    Wt::WTemplate::renderTemplate(result);

    comment_.purge();

    t.commit();
} // end void CommentView::RenderTemplate
/* ****************************************************************************
 * Resolve String
 */
void CommentView::resolveString(const std::string& varName, const std::vector<Wt::WString>& args, std::ostream& result)
{
    if (varName == "author")
    {
        format(result, comment_->author ? comment_->author->name : "anonymous");
    }
    else if (varName == "date")
    {
        format(result, comment_->date.timeTo(Wt::WDateTime::currentDateTime()) + " ago");
    }
    else if (varName == "contents")
    {
        format(result, comment_->textHtml(), Wt::XHTMLText);
    }
    else
    {
        Wt::WTemplate::resolveString(varName, args, result);
    }
} // end void CommentView::ResolveString
/* ****************************************************************************
 * Render View
 */
void CommentView::RenderView()
{
    clear();

    bool isRootComment = !comment_->parent;
    setTemplateText(isRootComment ? tr("blog-root-comment") : tr("blog-comment"));

    bindString("collapse-expand", Wt::WString::Empty); // NYI

    Wt::WText *replyText = new Wt::WText(isRootComment ? tr("comment-add") : tr("comment-reply"));
    replyText->setStyleClass("link");
    replyText->clicked().connect(this, &CommentView::Reply);
    bindWidget("reply", replyText);

    bool mayEdit = session_.user() && (comment_->author == session_.user() || session_.user()->role == User::Admin);

    if (mayEdit)
    {
        Wt::WText *editText = new Wt::WText(tr("comment-edit"));
        editText->setStyleClass("link");
        editText->clicked().connect(this, &CommentView::Edit);
        bindWidget("edit", editText);
    }
    else
    {
        bindString("edit", Wt::WString::Empty);
    }

    bool mayDelete = (session_.user() && session_.user() == comment_->author) || session_.user() == comment_->post->author;

    if (mayDelete)
    {
        Wt::WText *deleteText = new Wt::WText(tr("comment-delete"));
        deleteText->setStyleClass("link");
        deleteText->clicked().connect(this, &CommentView::Rm);
        bindWidget("delete", deleteText);
    }
    else
    {
        bindString("delete", Wt::WString::Empty);
    }

    typedef std::vector< Wt::Dbo::ptr<Comment> > CommentVector;
    CommentVector comments(comment_->children.begin(), comment_->children.end());

    Wt::WContainerWidget *children = new Wt::WContainerWidget();
    for (int i = (int)comments.size() - 1; i >= 0; --i)
    {
        children->addWidget(new CommentView(session_, comments[i]));
    }
    bindWidget("children", children);
} // end void CommentView::RenderView
/* ****************************************************************************
 * Save
 */
void CommentView::Save()
{
    Wt::Dbo::Transaction t(session_);

    bool isNew = comment_.id() == -1;

    Comment *comment = comment_.modify();

    comment->setText(editArea_->text());

    if (isNew)
    {
        session_.add(comment_);
        comment->date = Wt::WDateTime::currentDateTime();
        comment->author = session_.user();
        session_.commentsChanged().emit(comment_);
    }

    RenderView();

    t.commit();
} // end void CommentView::Save
/* ****************************************************************************
 * Reply
 */
void CommentView::Reply()
{
    Wt::Dbo::Transaction t(session_);

    Wt::WContainerWidget *c = resolve<Wt::WContainerWidget *>("children");
    c->insertWidget(0, new CommentView(session_, comment_.id()));

    t.commit();
} // end void CommentView::Reply
/* ****************************************************************************
 * Rm
 */
void CommentView::Rm()
{
    Wt::Dbo::Transaction t(session_);

    comment_.modify()->setDeleted();
    RenderView();

    t.commit();
} // end void CommentView::Rm
#endif // BLOGMAN
// --- End Of File ------------------------------------------------------------
