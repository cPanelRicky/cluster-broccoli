package de.frosner.broccoli.controllers

import de.frosner.broccoli.conf
import de.frosner.broccoli.services.SecurityService
import de.frosner.broccoli.util.Logging
import jp.t2v.lab.play2.auth.{AuthConfig, CookieTokenAccessor}
import play.api.Configuration
import play.api.mvc.{RequestHeader, Result, Results}

import scala.concurrent.{ExecutionContext, Future}
import scala.reflect.ClassTag
import scala.util.{Failure, Success, Try}

trait AuthConfigImpl extends AuthConfig with Logging {

  val securityService: SecurityService

  type Id = String

  type User = Account

  type Authority = Role

  val idTag: ClassTag[Id] = scala.reflect.classTag[Id]

  val sessionTimeoutInSeconds = securityService.sessionTimeoutInSeconds

  def resolveUser(id: Id)(implicit ctx: ExecutionContext): Future[Option[User]] = Future.successful(securityService.getAccount(id))

  def loginSucceeded(request: RequestHeader)(implicit ctx: ExecutionContext): Future[Result] =
    Future.successful(Results.Ok("loginSucceeded"))

  def logoutSucceeded(request: RequestHeader)(implicit ctx: ExecutionContext): Future[Result] =
    Future.successful(Results.Ok("logoutSucceeded"))

  def authenticationFailed(request: RequestHeader)(implicit ctx: ExecutionContext): Future[Result] =
    Future.successful(Results.Forbidden("authenticationFailed"))

  override def authorizationFailed(request: RequestHeader, user: User, authority: Option[Authority])(implicit context: ExecutionContext): Future[Result] = {
    Future.successful(Results.Forbidden("authorizationFailed"))
  }


  def authorize(user: User, authority: Authority)(implicit ctx: ExecutionContext): Future[Boolean] = Future.successful {
    true
//    (user.role, authority) match {
//      case (Administrator, _)       => true
//      case (NormalUser, NormalUser) => true
//      case _                        => false
//    }
  }

  override lazy val tokenAccessor = new CookieTokenAccessor(
    // Set the secure flag only in production
    cookieSecureOption = play.api.Play.isProd(play.api.Play.current),
    cookieMaxAge       = Some(sessionTimeoutInSeconds)
  )

}