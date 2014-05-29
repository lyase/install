/*
 * Copyright (C) 2011 Emweb bvba, Kessel-Lo, Belgium.
 *
 * See the LICENSE file for terms of use.
 *
 * Modified for Witty Wizard
 *
 */

#include <Wt/Dbo/Impl>
#include <Wt/Auth/Identity>

#include "BlogUserDatabase.h"
#include "User.h"
#include "Token.h"
/* ****************************************************************************
 * Invalid User
 */
class InvalidUser : public std::runtime_error
{
    public:
        InvalidUser(const std::string& id) : std::runtime_error("Invalid user: " + id) { }
}; // end
/* ****************************************************************************
 * Transaction Impl
 */
class TransactionImpl : public Wt::Auth::AbstractUserDatabase::Transaction, public Wt::Dbo::Transaction
{
    public:
        TransactionImpl(Wt::Dbo::Session& session) : Wt::Dbo::Transaction(session)
        {
        }

        virtual ~TransactionImpl()
        {
        }

        virtual void commit()
        {
            Wt::Dbo::Transaction::commit();
        }

        virtual void rollback()
        {
            Wt::Dbo::Transaction::rollback();
        }
};
/* ************************************************************************* */
/* ************************************************************************* */
/* ****************************************************************************
 * Blog User Database
 */
BlogUserDatabase::BlogUserDatabase(Wt::Dbo::Session& session) : session_(session)
{

} // end
/* ****************************************************************************
 * start Transaction
 */
Wt::Auth::AbstractUserDatabase::Transaction *BlogUserDatabase::startTransaction()
{
    return new TransactionImpl(session_);
} // end
/* ****************************************************************************
 * find
 */
Wt::Dbo::ptr<User> BlogUserDatabase::find(const Wt::Auth::User& user) const
{
    getUser(user.id());

    return user_;
} // end
/* ****************************************************************************
 * find
 */
Wt::Auth::User BlogUserDatabase::find(const Wt::Dbo::ptr<User> user) const
{
    user_ = user;

    return Wt::Auth::User(boost::lexical_cast<std::string>(user_.id()), *this);
} // end
/* ****************************************************************************
 * find With Id
 */
Wt::Auth::User BlogUserDatabase::findWithId(const std::string& id) const
{
    getUser(id);

    if (user_)
    {
        return Wt::Auth::User(id, *this);
    }
    else
    {
        return Wt::Auth::User();
    }
} // end
/* ****************************************************************************
 * password
 */
Wt::Auth::PasswordHash BlogUserDatabase::password(const Wt::Auth::User& user) const
{
    WithUser find(*this, user);

    return Wt::Auth::PasswordHash(user_->passwordMethod, user_->passwordSalt, user_->password);
} // end
/* ****************************************************************************
 * set Password
 */
void BlogUserDatabase::setPassword(const Wt::Auth::User& user, const Wt::Auth::PasswordHash& password)
{
    WithUser find(*this, user);

    user_.modify()->password = password.value();
    user_.modify()->passwordMethod = password.function();
    user_.modify()->passwordSalt = password.salt();
} // end
/* ****************************************************************************
 * status
 */
Wt::Auth::User::Status BlogUserDatabase::status(const Wt::Auth::User& user) const
{
    (void)user; // Eat user warning
    return Wt::Auth::User::Normal;
} // end
/* ****************************************************************************
 * set Status
 */
void BlogUserDatabase::setStatus(const Wt::Auth::User& user, Wt::Auth::User::Status status)
{
    (void)user; // Eat user warning
    (void)status; // Eat status warning
    throw std::runtime_error("Changing status is not supported.");
} // end
/* ****************************************************************************
 * add Identity
 */
void BlogUserDatabase::addIdentity(const Wt::Auth::User& user, const std::string& provider, const Wt::WString& identity)
{
    WithUser find(*this, user);

    if (provider == Wt::Auth::Identity::LoginName)
    {
        user_.modify()->name = identity;
    }
    else
    {
        user_.modify()->oAuthProvider = provider;
        user_.modify()->oAuthId = identity.toUTF8();
    }
} // end
/* ****************************************************************************
 * identity
 */
Wt::WString BlogUserDatabase::identity(const Wt::Auth::User& user, const std::string& provider) const
{
    WithUser find(*this, user);

    if (provider == Wt::Auth::Identity::LoginName)
    {
        return user_->name;
    }
    else if (provider == user_->oAuthProvider)
    {
        return Wt::WString::fromUTF8(user_->oAuthId);
    }
    else
    {
        return Wt::WString::Empty;
    }
} // end
/* ****************************************************************************
 * remove Identity
 */
void BlogUserDatabase::removeIdentity(const Wt::Auth::User& user, const std::string& provider)
{
    WithUser find(*this, user);

    if (provider == Wt::Auth::Identity::LoginName)
    {
        user_.modify()->name = "";
    }
    else if (provider == user_->oAuthProvider)
    {
        user_.modify()->oAuthProvider = std::string();
        user_.modify()->oAuthId = std::string();
    }
} // end
/* ****************************************************************************
 * find With Identity
 */
Wt::Auth::User BlogUserDatabase::findWithIdentity(const std::string& provider, const Wt::WString& identity) const
{
    Wt::Dbo::Transaction t(session_);
    if (provider == Wt::Auth::Identity::LoginName)
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
        return Wt::Auth::User(boost::lexical_cast<std::string>(user_.id()), *this);
    }
    else
    {
        return Wt::Auth::User();
    }
} // end
/* ****************************************************************************
 * register New
 */
Wt::Auth::User BlogUserDatabase::registerNew()
{
    User *user = new User();
    user_ = session_.add(user);
    user_.flush();
    return Wt::Auth::User(boost::lexical_cast<std::string>(user_.id()), *this);
} // end
/* ****************************************************************************
 * add Auth Token
 */
void BlogUserDatabase::addAuthToken(const Wt::Auth::User& user, const Wt::Auth::Token& token)
{
    WithUser find(*this, user);
    // This should be statistically very unlikely but also a big security problem if we do not detect it ...
    if (session_.find<Token>().where("value = ?").bind(token.hash()).resultList().size() > 0)
    {
        throw std::runtime_error("Token hash collision");
    }
    // Prevent a user from piling up the database with tokens
    if (user_->authTokens.size() > 50)
    {
        return;
    }
    user_.modify()->authTokens.insert(Wt::Dbo::ptr<Token>(new Token(token.hash(), token.expirationTime())));
} // end
/* ****************************************************************************
 * update Auth Token
 */
int BlogUserDatabase::updateAuthToken(const Wt::Auth::User& user, const std::string& hash, const std::string& newHash)
{
    WithUser find(*this, user);

    for (Tokens::const_iterator i = user_->authTokens.begin(); i != user_->authTokens.end(); ++i)
    {
        if ((*i)->value == hash)
        {
            Wt::Dbo::ptr<Token> p = *i;
            p.modify()->value = newHash;
            return std::max(Wt::WDateTime::currentDateTime().secsTo(p->expires), 0);
        }
    }

    return 0;
} // end
/* ****************************************************************************
 * remove Auth Token
 */
void BlogUserDatabase::removeAuthToken(const Wt::Auth::User& user, const std::string& hash)
{
    WithUser find(*this, user);

    for (Tokens::const_iterator i = user_->authTokens.begin(); i != user_->authTokens.end(); ++i)
    {
        if ((*i)->value == hash)
        {
            Wt::Dbo::ptr<Token> p = *i;
            p.remove();
            break;
        }
    }
} // end
/* ****************************************************************************
 * find With Auth Token
 */
Wt::Auth::User BlogUserDatabase::findWithAuthToken(const std::string& hash) const
{
    Wt::Dbo::Transaction t(session_);
    user_ = session_.query< Wt::Dbo::ptr<User> >("select u from \"user\" u join token t on u.id = t.user_id").where("t.value = ?").bind(hash).where("t.expires > ?").bind(Wt::WDateTime::currentDateTime());
    t.commit();

    if (user_)
    {
        return Wt::Auth::User(boost::lexical_cast<std::string>(user_.id()), *this);
    }
    else
    {
        return Wt::Auth::User();
    }
} // end
/* ****************************************************************************
 * failed Login Attempts
 */
int BlogUserDatabase::failedLoginAttempts(const Wt::Auth::User& user) const
{
    WithUser find(*this, user);

    return user_->failedLoginAttempts;
} // end
/* ****************************************************************************
 * set Failed Login Attempts
 */
void BlogUserDatabase::setFailedLoginAttempts(const Wt::Auth::User& user, int count)
{
    WithUser find(*this, user);

    user_.modify()->failedLoginAttempts = count;
} // end
/* ****************************************************************************
 * last Login Attempt
 */
Wt::WDateTime BlogUserDatabase::lastLoginAttempt(const Wt::Auth::User& user) const
{
    WithUser find(*this, user);

    return user_->lastLoginAttempt;
} // end
/* ****************************************************************************
 * set Last Login Attempt
 */
void BlogUserDatabase::setLastLoginAttempt(const Wt::Auth::User& user, const Wt::WDateTime& t)
{ 
    WithUser find(*this, user);

    user_.modify()->lastLoginAttempt = t;
} // end
/* ****************************************************************************
 * get User
 */
void BlogUserDatabase::getUser(const std::string& id) const
{
    if (!user_ || boost::lexical_cast<std::string>(user_.id()) != id)
    {
        Wt::Dbo::Transaction t(session_);
        user_ = session_.find<User>().where("id = ?").bind(boost::lexical_cast<long long>(id));
        t.commit();
    }
} // end
/* ****************************************************************************
 * With User
 */
BlogUserDatabase::WithUser::WithUser(const BlogUserDatabase& self, const Wt::Auth::User& user) : transaction(self.session_)
{
    self.getUser(user.id());

    if (!self.user_)
    {
        throw InvalidUser(user.id());
    }
} // end
/* ****************************************************************************
 * ~ With User
 */
BlogUserDatabase::WithUser::~WithUser()
{
    transaction.commit();
} // end
// --- End Of File ------------------------------------------------------------
