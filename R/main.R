#' Measure defoliation events in host trees
#' @description Conduct host/nonhost comparison to identify defoliation events
#'
#' @param host_tree a data.frame rwl object containing the tree-level growth series for all
#' host trees to be compared to the non-host chronology
#' @param nonhost_chron a data.frame rwl object comtaining a single non-host chronology
#' @param duration_years the mimimum number of years in which to consider a defolation event
#' @param max_reduction the minimum level of tree growth to be considered in defoliation
#' @param list_output defaults to \code{FALSE}. This option is to output a long list object containing a separate data.frame for each series in
#' \code{host_tree} that includes the input series and the \code{nonhost_chron}, the corrected series, and
#' the character string identifying the defoliation events.
#'
#' @return a list object with elements containing data.frame rwl objects of the host and non-host series, corrected
#'
#' @export
defoliate_trees <- function(host_tree, nonhost_chron, duration_years = 8, max_reduction = -1.28, list_output = FALSE) {
  if(ncol(nonhost_chron) > 1) stop("nonhost_chron can only contain 1 series")
  if(max_reduction > 0) max_reduction <- max_reduction * -1
  host_tree <- data.frame(host_tree)
  nonhost_chron <- data.frame(nonhost_chron)
  nseries <- ncol(host_tree)
  tree_list <- lapply(seq_len(nseries), function(i){
    input_series <- stats::na.omit(dplR::combine.rwl(host_tree[, i, drop=FALSE], nonhost_chron))
    corrected_series <- correct_host_series(input_series)
    defoliated_series <- id_defoliation(corrected_series, duration_years = duration_years, max_reduction = max_reduction)
    return(defoliated_series)
    }
  )
  if (list_output) return(tree_list)
  else return(stack_defoliation(tree_list))
}


#' Composite defoliation series to determine outbreak events
#'
#' @param x a defol object
#' @param comp_name the desired series name for the outbreak composite
#' @param filter_prop the minimum proportion of defoliated trees to be considered an outbreak. Default is 0.25.
#' @param filter_min_series The minimum number of trees required for an outbreak event. Default is 3 trees
#'
#' @export
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