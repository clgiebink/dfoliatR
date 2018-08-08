#' Composite defoliation series to determine outbreak events
#'
#' @param x a defol object
#' @param comp_name the desired series name for the outbreak composite
#' @param filter_prop the minimum proportion of defoliated trees to be considered an outbreak. Default is 0.25.
#' @param filter_min_series The minimum number of trees required for an outbreak event. Default is 3 trees

outbreak <- function(x, comp_name = "comp", filter_prop = 0.25, filter_min_series = 3){
  if(!is.defol(x)) stop("x must be a defol object")
  defol_events <- c("defoliated", "max_defoliation")
  event_count <- as.data.frame(table(year = subset(x, x$defol_status %in% defol_events)$year))
  series_count <- sample_depth(x)
  counts <- merge(event_count, series_count,
                  by = 'year')
  counts$prop <- counts$Freq / counts$samp_depth
  filter_mask <- (counts$prop >= filter_prop) & (counts$samp_depth >= filter_min_series)
  comp_years <- subset(counts, filter_mask)$year
  event_years <- data.frame(year = as.integer(levels(comp_years)[comp_years]),
                            defol_status = "outbreak")
  comp <- merge(counts, event_years, by = "year", all = TRUE)
  series_cast <- reshape2::dcast(x, year ~ series, value.var = "value")
  series_cast$mean <- rowMeans(series_cast[, -1], na.rm=TRUE)
  out <- merge(series_cast[, c("year", "mean")], comp, by = "year")
  out$series <- comp_name
  out <- out[, c('year', 'series', 'samp_depth', 'Freq', 'prop', 'mean', 'defol_status')]
  names(out)[c(3:7)] <- c("num_trees", "num_defol_trees", "prop_defol_trees", "mean_index", "outbreak_status")
  class(out) <- c("outbreak", "data.frame")
  return(out)
}



#' Calculate the sample depth of a host series data.frame
#'
#' @param x An rwl object.
#' @return A data.frame containing the years and number of trees
#'
#' @export
#'
sample_depth <- function(x) {
  # if(!is.fhx(x)) stop("x must be an fhx object")
  x_stats <- series_stats(x)
  n_trees <- nrow(x_stats)
  out <- data.frame(year = min(x_stats$first):max(x_stats$last))
  for(i in 1:n_trees){
    yrs <- x_stats[i, ]$first : x_stats[i, ]$last
    treespan <- data.frame(year = yrs, z = 1)
    names(treespan)[2] <- paste(x_stats$series[i])
    out <- merge(out, treespan, by=c('year'), all=TRUE)
  }
  if(n_trees > 1){
    out$samp_depth <- rowSums(out[, -1], na.rm=TRUE)
  }
  else out$samp_depth <- out[, -1]
  out <- subset(out, select=c('year', 'samp_depth'))
  return(out)
}

#' Generate tree-level descriptive statistics on a defol object.
#'
#' @param x A defol object after running \code{defoliate_trees}.
#'
#' @return A data.frame containing tree/series-level statistics.
#'
#' @export
defol_stats <- function(x) {
  if(!is.defol(x)) stop("x must be a defol object")
  plyr::ddply(x, c('series'), function(df) {
    first <- min(df$year)
    last <- max(df$year)
    years <- length(df$year)
    count <- plyr::count(df, "defol_status")
    num_defol <- count$freq[2]
    tot_defol <- sum(count$freq[c(1, 2)])
    avg_defol <- round(tot_defol / num_defol, 0)
    out <- c(first, last, years, num_defol, tot_defol, avg_defol)
    names(out) <- c("first", "last", "years", "num_events", "tot_years", "mean_duration")
    return(out)
    }
  )
}

