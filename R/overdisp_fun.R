#' Overdispertion test
#'
#' Test for Overdispertion for \code{glmerMod}. An approximation of 
#' overdispertion by checking if residual deviance is greater than 
#' the residual degrees of freedom. 
#'
#' @param model glmerMod model
#' @export

overdisp_fun <- function(model) {
  ## number of variance parameters in 
  ##   an n-by-n variance-covariance matrix
  vpars <- function(m) {
    nrow(m) * (nrow(m) + 1) / 2
  }
  model_df <- sum(sapply(VarCorr(model), vpars)) + length(fixef(model))
  residual_df <- nrow(model.frame(model)) - model_df
  pearson_residuals <- residuals(model, type="pearson")
  pearson_chisq <- sum(pearson_residuals^2)
  pratio <- pearson_chisq / residual_df
  pvalue <- pchisq(pearson_chisq, df = residual_df, lower.tail = FALSE)
  a <- round(c(
      chisq = pearson_chisq, 
      ratio = pratio, 
      rdf = residual_df, 
      p = pvalue), 3)
  print(data.frame(
      key = names(a),
      value = a,
      row.names = NULL
  ), row.names = FALSE)
  
}
