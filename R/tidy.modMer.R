tidy.glmerMod <- function(x, exponentiate = FALSE, conf.int = .95, ci.method = c("Wald", "profile", "boot", NULL), ...){
  s <- summary(x)
  co <- coef(s)
  nn <- c("estimate", "std.error", "statistic", "p.value")
  ret <- broom:::fix_data_frame(co, nn)

  if (exponentiate) {
    ret$estimate <- exp(ret$estimate)
  }
  ci.method <- match.arg(ci.method)
  if (!is.null(ci.method)){
    CI <- lme4::confint.merMod(x, level = conf.int, method = ci.method)
    colnames(CI) <- c("conf.low", "conf.high")
    if (exponentiate) {
      CI <- exp(CI)
    }
    ret <- cbind(ret, CI[-1,])
    rownames(ret) <- c(1:NROW(ret))
  }
  ret
}

glance.glmerMod <- function(x){
  s <- summary(x)
  # including all the test statistics and p-values as separate
  # columns. Admittedly not perfect but does capture most use cases.
  ret <- list(n = nobs(x),
              ngrps = ngrps(x),
              random.var = VarCorr(x)[[1]][1],
              random.std.dev = sqrt(VarCorr(x)[[1]][1]),
              df = extractAIC(x)[1],
              AIC = extractAIC(x)[2],
              BIC = BIC(x),
              deviance = deviance(x)
              )
  ret <- as.data.frame(broom:::compact(ret))
  broom::finish_glance(ret, x)
}
