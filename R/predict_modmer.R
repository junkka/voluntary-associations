#' Predict merMod
#'
#' Predict response for glmm regression
#'
#' @param model glmm model
#' @param newdata data.frame with new observations
#' @param vars vector of characters containing names of variables 
#'   which to predict all levels of
#' @param alpha confidence interval. Default is 0.05
#' @seealso \link{https://github.com/bbolker/asaglmm/blob/master/papers/bolker_chap.rmd}
#' @export

predict_mermod <- function(model, newdata, vars, alpha = 0.05){
  ## baseline prediction, on the linear predictor (logit) scale:
  library(lme4)
  library(Matrix)
  pp <-  predict(model,re.form=NA, type = "response", newdata=newdata)
  pred0 <- predict(model,re.form=NA,newdata=newdata)
  ## fixed-effects model matrix for new data
  mm <- model.matrix(as.formula(sprintf("~  %s * %s", vars[1], vars[2])),
                 newdata)
  rs <- stringr::str_detect(names(fixef(model)), paste0("^",vars[1], "|^", vars[2]))
  rs[1] <- TRUE

  V <- vcov(model)[rs,rs]     ## variance-covariance matrix of beta
  pred_variance <- diag(mm %*% V %*% t(mm)) # Variance of prediction
  pred_se <- sqrt(pred_variance) # std errors of predictions
  # Add residual variance for prediction intervals
  pred_se2 <- sqrt(pred_variance + VarCorr(model)[[1]][1])  
  ## inverse-link (logistic) function
  linkinv <- model@resp$family$linkinv
  ## construct 95% Normal CIs on the link scale and
  ##  transform back to the response (probability) scale:
  crit <- -qnorm(alpha/2)
  a <- cbind(pred = pp, 
        linkinv(cbind(
              ci_lwr=pred0-crit*pred_se,
              ci_upr=pred0+crit*pred_se,
              pred_lwr=pred0-crit*pred_se2,
              pred_upr=pred0+crit*pred_se2
            )))
}
