
sources <- paste0('R/', list.files('R', pattern="*.R$"))
sapply(sources, source, .GlobalEnv)


