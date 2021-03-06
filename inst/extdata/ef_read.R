# East fork host series
ef_h <- dplR::read.compact("inst/extdata/EFKDF2.TRE")

usethis::use_data(ef_h, overwrite = TRUE)

# Nonhost chronology for Eastfork
bac <- dplR::read.compact("inst/extdata/BAC2.CRN")
ef_nh <- bac[, 1, drop = FALSE]

usethis::use_data(ef_nh, overwrite = TRUE)

# Run defoliate_trees
ef_defol <- dfoliatR::defoliate_trees(ef_h, ef_nh, series_end_event = TRUE)

usethis::use_data(ef_defol, overwrite = TRUE)

# Run outbreak on defol
ef_obr <- dfoliatR::outbreak(ef_defol)

usethis::use_data(ef_obr, overwrite = TRUE)
