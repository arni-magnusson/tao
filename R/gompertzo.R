#' Gompertz Growth Model (Old Style)
#'
#' Fit a Gompertz growth model to otoliths and/or tags, using a traditional
#' parametrization.
#'
#' @param par is a parameter list.
#' @param data is a data list.
#' @param t age (vector).
#' @param Linf asymptotic maximum length.
#' @param k growth coefficient.
#' @param tau location parameter.
#' @param silent passed to \code{\link[RTMB]{MakeADFun}}.
#' @param \dots passed to \code{\link[RTMB]{MakeADFun}}.
#'
#' @details
#' The main function \code{gompertzo} creates a model object, ready for
#' parameter estimation. The auxiliary functions \code{gompertzo_curve} and
#' \code{gompertzo_objfun} are called by the main function to calculate the
#' regression curve and objective function value. The user can also call the
#' auxiliary functions directly for plotting and model exploration.
#'
#' The \code{par} list contains the following elements:
#' \itemize{
#'   \item \code{log_Linf}, asymptotic maximum length
#'   \item \code{log_k}, growth coefficient
#'   \item \code{tau}, location parameter
#'   \item \code{log_sigma_1}, growth variability at length \code{Lshort}
#'   \item \code{log_sigma_2} (*), growth variability at length \code{Llong}
#'   \item \code{log_age} (*), age at release of tagged individuals (vector)
#' }
#'
#' *: The parameter \code{log_sigma_2} can be omitted to estimate growth
#' variability that does not vary with length. The parameter vector
#' \code{log_age} can be omitted to fit to otoliths only.
#'
#' The \code{data} list contains the following elements:
#' \itemize{
#'   \item \code{Aoto} (*), age from otoliths (vector)
#'   \item \code{Loto} (*), length from otoliths (vector)
#'   \item \code{Lrel} (*), length at release of tagged individuals (vector)
#'   \item \code{Lrec} (*), length at recapture of tagged individuals (vector)
#'   \item \code{liberty} (*), time at liberty of tagged individuals in years
#'         (vector)
#'   \item \code{Lshort} (*), length where sd(length) is \code{sigma_1}
#'   \item \code{Llong} (*), length where sd(length) is \code{sigma_2}
#' }
#'
#' *: The data vectors \code{Aoto} and \code{Loto} can be omitted to fit to
#' tagging data only. The data vectors \code{Lrel}, \code{Lrec}, and
#' \code{liberty} can be omitted to fit to otoliths only. The reference lengths
#' \code{Lshort} and \code{Llong} are only required when estimating growth
#' variability that varies with length, i.e., when the \code{log_sigma_2}
#' parameter is specified.
#'
#' @return
#' The \code{gompertzo} function returns a TMB model object, produced by
#' \code{\link[RTMB]{MakeADFun}}.
#'
#' The \code{gompertzo_curve} function returns a numeric vector of predicted
#' length at age.
#'
#' The \code{gompertzo_objfun} function returns the negative log-likelihood as a
#' single number, describing the goodness of fit of \code{par} to the
#' \code{data}.
#'
#' @note
#' The Schnute parametrization used in \code{\link{gompertz}} reduces parameter
#' correlation and improves convergence reliability compared to the traditional
#' parametrization used in \code{gompertzo}. Therefore, the \code{gompertz}
#' parametrization can be recommended for general usage, as both
#' parametrizations produce the same growth curve. However, there can be some
#' use cases where the traditional parametrization (\code{Linf}, \code{k},
#' \code{tau}) is preferred over the Schnute parametrization (\code{L1},
#' \code{L2}, \code{k}).
#'
#' Gompertz is a special case of the Richards (1959) model, where \eqn{b=0}. If
#' the best model fit of a \code{\link{richards}} model to a particular dataset
#' involves a very small estimated value of \eqn{b}, then the \code{gompertz}
#' model offers a preferable parametrization, as it produces the same curve
#' using fewer parameters.
#'
#' The Gompertz (1825) growth model, as parametrized by Ricker (1979, Eq. 23)
#' predicts length at age as:
#'
#' \deqn{L ~=~ L_\infty\exp\!\big(\!\!-\!e^{-k(t-\tau)}\big)}{
#'       Linf * exp(-exp(-k * (t-tau)))}
#'
#' The variability of length at age increases linearly with length,
#'
#' \deqn{\sigma_L ~=~ \alpha \,+\, \beta \hat L}{
#'       sigma_L = alpha + beta * Lhat}
#'
#' where the slope is \eqn{\beta=(\sigma_2-\sigma_1) /
#' (L_\mathrm{long}-L_\mathrm{short})}{beta = (sigma_2-sigma_1) /
#' (Llong-Lshort)} and the intercept is \eqn{\alpha=\sigma_1 - \beta
#' L_\mathrm{short}}{alpha = sigma_1 - beta * Lshort}. Alternatively, growth
#' variability can be modelled as a constant
#' (\eqn{\sigma_L=\sigma_1}{sigma_L=sigma_1}) that does not vary with length,
#' see \code{log_sigma_2} above.
#'
#' The negative log-likelihood is calculated by comparing the observed and
#' predicted lengths:
#' \preformatted{
#'   nll_Loto <- -dnorm(Loto, Loto_hat, sigma_Loto, TRUE)
#'   nll_Lrel <- -dnorm(Lrel, Lrel_hat, sigma_Lrel, TRUE)
#'   nll_Lrec <- -dnorm(Lrec, Lrec_hat, sigma_Lrec, TRUE)
#'   nll <- sum(nll_Loto) + sum(nll_Lrel) + sum(nll_Lrec)
#' }
#'
#' @references
#' Gompertz, B. (1825).
#' On the nature of the function expressive of the law of human mortality, and
#' on a new mode of determining the value of life contingencies.
#' \emph{Philosophical Transactions of the Royal Society}, \bold{115}, 513-583.
# \doi{10.1098/rstl.1825.0026}.
#'
#' Ricker, W.E. (1979).
#' Growth rates and models.
#' In: W.S. Hoar et al. (eds.) \emph{Fish physiology 8: Bioenergetics and
#' growth}. New York: Academic Press, pp. 677-743.
#'
#' @seealso
#' \code{\link{gcm}}, \code{\link{gompertz}}/\code{gompertzo},
#' \code{\link{richards}}/\code{\link{richards}}, \code{\link{schnute3}}, and
#' \code{\link{vonbert}}/\code{\link{vonberto}} are alternative growth models.
#'
#' \code{\link{otoliths_skj}} and \code{\link{tags_skj}} are example datasets.
#'
#' \code{\link{fishgrowth-package}} gives an overview of the package.
#'
#' @examples
#' # Explore initial parameter values
#' plot(len~age, otoliths_skj, xlim=c(0,4), ylim=c(0,100))
#' x <- seq(0, 4, 0.1)
#' points(lenRel~I(lenRel/60), tags_skj, col=4)
#' points(lenRec~I(lenRel/60+liberty), tags_skj, col=3)
#' lines(x, gompertzo_curve(x, Linf=75, k=1, tau=0), lty=2)
#'
#' # Prepare parameters and data
#' init <- list(log_Linf=log(75), log_k=log(1), tau=0,
#'              log_sigma_1=log(1), log_sigma_2=log(1),
#'              log_age=log(tags_skj$lenRel/60))
#' dat <- list(Aoto=otoliths_skj$age, Loto=otoliths_skj$len,
#'             Lrel=tags_skj$lenRel, Lrec=tags_skj$lenRec,
#'             liberty=tags_skj$liberty, Lshort=30, Llong=60)
#' gompertzo_objfun(init, dat)
#'
#' # Fit model
#' model <- gompertzo(init, dat)
#' fit <- nlminb(model$par, model$fn, model$gr,
#'               control=list(eval.max=1e4, iter.max=1e4))
#' report <- model$report()
#' sdreport <- sdreport(model, getReportCovariance=FALSE)
#'
#' # Plot results
#' plot(len~age, otoliths_skj, xlim=c(0,4), ylim=c(0,100))
#' points(report$age, report$Lrel, col=4)
#' points(report$age+report$liberty, report$Lrec, col=3)
#' Lhat <- with(report, gompertzo_curve(x, Linf, k, tau))
#' lines(x, Lhat, lwd=2)
#'
#' # Model summary
#' est <- report[c("Linf", "k", "tau", "sigma_1", "sigma_2")]
#' est
#' fit[-1]
#' head(summary(sdreport), 5)
#'
#' #############################################################################
#'
#' # Fit to otoliths only
#' init_oto <- list(log_Linf=log(75), log_k=log(1), tau=0,
#'                  log_sigma_1=log(1), log_sigma_2=log(1))
#' dat_oto <- list(Aoto=otoliths_skj$age, Loto=otoliths_skj$len,
#'                 Lshort=30, Llong=60)
#' model_oto <- gompertzo(init_oto, dat_oto)
#' fit_oto <- nlminb(model_oto$par, model_oto$fn, model_oto$gr,
#'                   control=list(eval.max=1e4, iter.max=1e4))
#' model_oto$report()[c("Linf", "k", "tau", "sigma_1", "sigma_2")]
#'
#' # Same, but now estimating constant sigma instead of sigma varying by length
#' # We do this by omitting log_sigma_2, Lshort, Llong
#' init_oto_c <- list(log_Linf=log(75), log_k=log(1), tau=0,
#'                    log_sigma_1=log(1))
#' dat_oto_c <- list(Aoto=otoliths_skj$age, Loto=otoliths_skj$len)
#' model_oto_c <- gompertzo(init_oto_c, dat_oto_c)
#' fit_oto_c <- nlminb(model_oto_c$par, model_oto_c$fn, model_oto_c$gr,
#'                     control=list(eval.max=1e4, iter.max=1e4))
#' model_oto_c$report()[c("Linf", "k", "tau", "sigma_1")]
#'
#' #############################################################################
#'
#' # Fit to tags only
#' init_tags <- list(log_Linf=log(75), log_k=log(1), tau=0,
#'                   log_sigma_1=log(1), log_sigma_2=log(1),
#'                   log_age=log(tags_skj$lenRel/60))
#' dat_tags <- list(Lrel=tags_skj$lenRel, Lrec=tags_skj$lenRec,
#'                  liberty=tags_skj$liberty, Lshort=30, Llong=60)
#' model_tags <- gompertzo(init_tags, dat_tags)
#' fit_tags <- nlminb(model_tags$par, model_tags$fn, model_tags$gr,
#'                    control=list(eval.max=1e4, iter.max=1e4))
#' model_tags$report()[c("Linf", "k", "tau")]
#'
#' @importFrom RTMB dnorm MakeADFun REPORT
#'
#' @export

gompertzo <- function(par, data, silent=TRUE, ...)
{
  wrap <- function(objfun, data)
  {
    function(par) objfun(par, data)
  }
  if(is.null(par$log_sigma_1))
    stop("'par' list must include 'log_sigma_1'")
  if(!is.null(par$log_sigma_2))
  {
    if(is.null(data$Lshort))
      stop("'data' list must include 'Lshort' when 'log_sigma_2' is specified")
    if(is.null(data$Llong))
      stop("'data' list must include 'Llong' when 'log_sigma_2' is specified")
  }
  MakeADFun(wrap(gompertzo_objfun, data=data), par, silent=silent, ...)
}

#' @rdname gompertzo
#'
#' @export

gompertzo_curve <- function(t, Linf, k, tau)
{
  Linf * exp(-exp(-k * (t-tau)))
}

#' @rdname gompertzo
#'
#' @export

gompertzo_objfun <- function(par, data)
{
  # Extract parameters
  Linf <- exp(par$log_Linf)
  k <- exp(par$log_k)
  tau <- par$tau
  sigma_1 <- exp(par$log_sigma_1)
  sigma_2 <- if(is.null(par$log_sigma_2)) NULL else exp(par$log_sigma_2)

  # Extract data
  Lshort <- data$Lshort
  Llong <- data$Llong

  # Calculate sigma coefficients (sigma = a + b*L)
  if(is.null(sigma_2))
  {
    sigma_slope <- 0  # if user did not pass log_sigma_2 then use constant sigma
    sigma_intercept <- sigma_1
  }
  else
  {
    sigma_slope <- (sigma_2 - sigma_1) / (Llong - Lshort)
    sigma_intercept <- sigma_1 - Lshort * sigma_slope
  }

  # Initialize likelihood
  nll <- 0

  # Report quantities of interest
  REPORT(Linf)
  REPORT(k)
  REPORT(tau)
  REPORT(Lshort)
  REPORT(Llong)
  REPORT(sigma_1)
  REPORT(sigma_2)

  # Model includes otolith data
  if(!is.null(data$Aoto) && !is.null(data$Loto))
  {
    # data
    Aoto <- data$Aoto
    Loto <- data$Loto
    # Lhat
    Loto_hat <- gompertzo_curve(Aoto, Linf, k, tau)
    # sigma
    sigma_Loto <- sigma_intercept + sigma_slope * Loto_hat
    # nll
    nll_Loto <- -dnorm(Loto, Loto_hat, sigma_Loto, TRUE)
    nll <- nll + sum(nll_Loto)
    # report
    REPORT(Aoto)
    REPORT(Loto)
    REPORT(Loto_hat)
    REPORT(sigma_Loto)
    REPORT(nll_Loto)
  }

  # Model includes tagging data
  if(!is.null(par$log_age) && !is.null(data$Lrel) &&
     !is.null(data$Lrec) && !is.null(data$liberty))
  {
    # par
    age <- exp(par$log_age)
    # data
    Lrel <- data$Lrel
    Lrec <- data$Lrec
    liberty <- data$liberty
    # Lhat
    Lrel_hat <- gompertzo_curve(age, Linf, k, tau)
    Lrec_hat <- gompertzo_curve(age+liberty, Linf, k, tau)
    # sigma
    sigma_Lrel <- sigma_intercept + sigma_slope * Lrel_hat
    sigma_Lrec <- sigma_intercept + sigma_slope * Lrec_hat
    # nll
    nll_Lrel <- -dnorm(Lrel, Lrel_hat, sigma_Lrel, TRUE)
    nll_Lrec <- -dnorm(Lrec, Lrec_hat, sigma_Lrec, TRUE)
    nll <- nll + sum(nll_Lrel) + sum(nll_Lrec)
    # report
    REPORT(age)
    REPORT(Lrel)
    REPORT(Lrec)
    REPORT(liberty)
    REPORT(Lrel_hat)
    REPORT(Lrec_hat)
    REPORT(sigma_Lrel)
    REPORT(sigma_Lrec)
    REPORT(nll_Lrel)
    REPORT(nll_Lrec)
  }

  nll
}
