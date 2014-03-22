/*
 * Copyright (C) 2011 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 */

#include <Wt/Dbo/Impl>
#include <Wt/Auth/Identity>

#include "BlogUserDatabase.h"
#include "User.h"
#include "Token.h"
/* ****************************************************************************
 *
 */
using namespace Wt;
/* ****************************************************************************
 * InvalidUser
 */
class InvalidUser : public std::runtime_error
{
    public:
        InvalidUser(const std::string& id) : std::runtime_error("Invalid user: " + id) { }
};
/* ****************************************************************************
 * Transaction
 */
class TransactionImpl : public Auth::AbstractUserDatabase::Transaction, public dbo::Transaction
{
    public:
        TransactionImpl(dbo::Session& session) : dbo::Transaction(session)
        {
        }

        virtual ~TransactionImpl()
        {
        }

        virtual void commit()
        {
            dbo::Transaction::commit();
        }

        virtual void rollback()
        {
            dbo::Transaction::rollback();
        }
};
/* ****************************************************************************
 * Blog User Database
 */
BlogUserDatabase::BlogUserDatabase(dbo::Session& session) : session_(session)
{

}
/* ****************************************************************************
 * start Transaction
 */
Auth::AbstractUserDatabase::Transaction *BlogUserDatabase::startTransaction()
{
    return new TransactionImpl(session_);
}
/* ****************************************************************************
 * find
 */
dbo::ptr<User> BlogUserDatabase::find(const Auth::User& user) const
{
    getUser(user.id());

    return user_;
}
/* ****************************************************************************
 * find
 */
Auth::User BlogUserDatabase::find(const dbo::ptr<User> user) const
{
    user_ = user;

    return Auth::User(boost::lexical_cast<std::string>(user_.id()), *this);
}
/* ****************************************************************************
 * find With Id
 */
Auth::User BlogUserDatabase::findWithId(const std::string& id) const
{
    getUser(id);

    if (user_)
    {
        return Auth::User(id, *this);
    }
    else
    {
        return Auth::User();
    }
}
/* ****************************************************************************
 * password
 */
Auth::PasswordHash BlogUserDatabase::password(const Auth::User& user) const
{
    WithUser find(*this, user);

    return Auth::PasswordHash(user_->passwordMethod, user_->passwordSalt, user_->password);
}
/* ****************************************************************************
 * set Password
 */
void BlogUserDatabase::setPassword(const Auth::User& user, const Auth::PasswordHash& password)
{
    WithUser find(*this, user);

    user_.modify()->password = password.value();
    user_.modify()->passwordMethod = password.function();
    user_.modify()->passwordSalt = password.salt();
}
/* ****************************************************************************
 * status
 */
Auth::User::Status BlogUserDatabase::status(const Auth::User& user) const
{
    (void)user; // Eat user Warning
    return Auth::User::Normal;
}
/* ****************************************************************************
 * set Status
 */
void BlogUserDatabase::setStatus(const Auth::User& user, Auth::User::Status status)
{
    (void)user; // Eat user Warning
    (void)status; // Eat status Warning
    throw std::runtime_error("Changing status is not supported.");
}
/* ****************************************************************************
 * add Identity
 */
void BlogUserDatabase::addIdentity(const Auth::User& user, const std::string& provider, const Wt::WString& identity)
{
    WithUser find(*this, user);

    if (provider == Auth::Identity::LoginName)
    {
        user_.modify()->name = identity;
    }
    else
    {
        user_.modify()->oAuthProvider = provider;
        user_.modify()->oAuthId = identity.toUTF8();
    }
}
/* ****************************************************************************
 * identity
 */
Wt::WString BlogUserDatabase::identity(const Auth::User& user, const std::string& provider) const
{
    WithUser find(*this, user);

    if (provider == Auth::Identity::LoginName)
    {
        return user_->name;
    }
    else if (provider == user_->oAuthProvider)
    {
        return Wt::WString::fromUTF8(user_->oAuthId);
    }
    else
    {
        return WString::Empty;
    }
}
/* ****************************************************************************
 * remove Identity
 */
void BlogUserDatabase::removeIdentity(const Auth::User& user, const std::string& provider)
{
    WithUser find(*this, user);

    if (provider == Auth::Identity::LoginName)
    {
        user_.modify()->name = "";
    }
    else if (provider == user_->oAuthProvider)
    {
        user_.modify()->oAuthProvider = std::string();
        user_.modify()->oAuthId = std::string();
    }
}
/* ****************************************************************************
 * find With Identity
 */
Auth::User BlogUserDatabase::findWithIdentity(const std::string& provider, const WString& identity) const
{
    dbo::Transaction t(session_);
    if (provider == Auth::Identity::LoginName)
    {
        if (!user_ || user_->name != identity)
        {
            user_ = session_.find<User>().where("name = ?").bind(identity);
        }
    }
    else
    {
        user_ = session_.find<User>().where("oauth_id = ?").bind(identity.toUTF8()).where("oauth_provider = ?").bind(provider);
    }
    t.commit();

    if (user_)
    {
        return Auth::User(boost::lexical_cast<std::string>(user_.id()), *this);
    }
    else
    {
        return Auth::User();
    }
}
/* ****************************************************************************
 * register New
 */
Auth::User BlogUserDatabase::registerNew()
{
    User *user = new User();
    user_ = session_.add(user);
    user_.flush();
    return Auth::User(boost::lexical_cast<std::string>(user_.id()), *this);
}
/* ****************************************************************************
 * add Auth Token
 */
void BlogUserDatabase::addAuthToken(const Auth::User& user, const Auth::Token& token)
{
    WithUser find(*this, user);

  /*
   * This should be statistically very unlikely but also a big
   * security problem if we do not detect it ...
   */
    if (session_.find<Token>().where("value = ?").bind(token.hash()).resultList().size() > 0)
    {
        throw std::runtime_error("Token hash collision");
    }
  /*
   * Prevent a user from piling up the database with tokens
   */
    if (user_->authTokens.size() > 50)
    {
        return;
    }
    user_.modify()->authTokens.insert(dbo::ptr<Token>(new Token(token.hash(), token.expirationTime())));
}
/* ****************************************************************************
 * update Auth Token
 */
int BlogUserDatabase::updateAuthToken(const Auth::User& user, const std::string& hash, const std::string& newHash)
{
    WithUser find(*this, user);

    for (Tokens::const_iterator i = user_->authTokens.begin(); i != user_->authTokens.end(); ++i)
    {
        if ((*i)->value == hash)
        {
            dbo::ptr<Token> p = *i;
            p.modify()->value = newHash;
            return std::max(Wt::WDateTime::currentDateTime().secsTo(p->expires), 0);
        }
    }

    return 0;
}
/* ****************************************************************************
 * remove Auth Token
 */
void BlogUserDatabase::removeAuthToken(const Auth::User& user, const std::string& hash)
{
    WithUser find(*this, user);

    for (Tokens::const_iterator i = user_->authTokens.begin(); i != user_->authTokens.end(); ++i)
    {
        if ((*i)->value == hash)
        {
            dbo::ptr<Token> p = *i;
            p.remove();
            break;
        }
    }
}
/* ****************************************************************************
 * find With Auth Token
 */
Auth::User BlogUserDatabase::findWithAuthToken(const std::string& hash) const
{
    dbo::Transaction t(session_);
    user_ = session_.query< dbo::ptr<User> >
            ("select u from \"user\" u join token t on u.id = t.user_id")
            .where("t.value = ?").bind(hash)
            .where("t.expires > ?").bind(WDateTime::currentDateTime());
    t.commit();

    if (user_)
    {
        return Auth::User(boost::lexical_cast<std::string>(user_.id()), *this);
    }
    else
    {
        return Auth::User();
    }
}
/* ****************************************************************************
 * failed Login Attempts
 */
int BlogUserDatabase::failedLoginAttempts(const Auth::User& user) const
{
    WithUser find(*this, user);

    return user_->failedLoginAttempts;
}
/* ****************************************************************************
 * set Failed Login Attempts
 */
void BlogUserDatabase::setFailedLoginAttempts(const Auth::User& user, int count)
{
    WithUser find(*this, user);

    user_.modify()->failedLoginAttempts = count;
}
/* ****************************************************************************
 * last Login Attempt
 */
WDateTime BlogUserDatabase::lastLoginAttempt(const Auth::User& user) const
{
    WithUser find(*this, user);

    return user_->lastLoginAttempt;
}
/* ****************************************************************************
 * set Last Login Attempt
 */
void BlogUserDatabase::setLastLoginAttempt(const Auth::User& user, const WDateTime& t)
{ 
    WithUser find(*this, user);

    user_.modify()->lastLoginAttempt = t;
}
/* ****************************************************************************
 * get User
 */
void BlogUserDatabase::getUser(const std::string& id) const
{
    if (!user_ || boost::lexical_cast<std::string>(user_.id()) != id)
    {
        dbo::Transaction t(session_);
        user_ = session_.find<User>().where("id = ?").bind(boost::lexical_cast<long long>(id));
        t.commit();
    }
}
/* ****************************************************************************
 * With User
 */
BlogUserDatabase::WithUser::WithUser(const BlogUserDatabase& self, const Auth::User& user) : transaction(self.session_)
{
    self.getUser(user.id());

    if (!self.user_)
    {
        throw InvalidUser(user.id());
    }
}
/* ****************************************************************************
 * commit
 */
BlogUserDatabase::WithUser::~WithUser()
{
    transaction.commit();
}
// --- End Of File ------------------------------------------------------------
