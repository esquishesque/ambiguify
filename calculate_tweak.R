#!/usr/bin/env Rscript
require(tidyverse)

d <- read.csv("temp_output/seam_measurements.csv") %>% 
  mutate(upward = value > lag(value),
         seam = as.logical(seam),
         value = round(value,5),
         before_seam = as.logical(before_seam),
         row = row_number()) %>% 
  mutate(stable = (upward & lead(upward) & lag(upward) & lag(upward,2)) |
           (!upward & !lead(upward) & !lag(upward) & !lag(upward,2))) %>% 
  filter(!seam, stable)
  
  
befores <- d %>% 
  filter(before_seam) %>% 
  select(-seam, -before_seam, -stable, -row)
afters_upward <- d %>% 
  filter(!before_seam,
         upward) %>% 
  select(word, value, time) %>% 
  arrange(word, time)
afters_downward <- d %>% 
  filter(!before_seam,
         !upward) %>% 
  select(word, value, time) %>% 
  arrange(word, time)


getMatchUpward = function(v_word, v_value){
  df <- afters_upward %>% 
    filter(word == v_word)
  index <- df %>% 
    pull(value) %>% 
    detect_index(~ (v_value < .x) & (.x - v_value < 0.01))
  return(pull(df, time)[index])
}

getMatchDownward = function(v_word, v_value){
  df <- afters_downward %>% 
    filter(word == v_word)
  index <- df %>% 
    pull(value) %>% 
    detect_index(~ (.x < v_value) & (v_value - .x < 0.01))
  return(pull(df, time)[index])
}

getMatch = function(v_word, v_upward, v_value){
  if(v_upward)
  {
    return(getMatchUpward(v_word, v_value))
  }
  else
  {
    return(getMatchDownward(v_word, v_value))
  }
}
  
# times <- c()
# for (i in 1:1000)
# {
#   start.time <- Sys.time()
#   befores %>%
#     filter(row_number() <= 10) %>%
#     rowwise() %>%
#     mutate(pair = list(getMatch(word, upward, value))) %>%
#     ungroup()
#   end.time <- Sys.time()
#   times <- c(times, end.time - start.time)
# }
# mean(times)*7500/60

output <- befores %>% 
  rowwise() %>% 
  mutate(time_pair = list(getMatch(word, upward, value))) %>% 
  ungroup() %>% 
  unnest(cols = c(time_pair), keep_empty=T) %>% 
  select(word, time, time_pair) %>% 
  group_by(word) %>% 
  slice_min(time_pair - time, n=1, with_ties=F) %>% 
  mutate(time_pair=if_else(is.na(time_pair), time, time_pair)) %>% 
  t() %>% 
  as_tibble()

  #defiintely should be doing this with some sort of map or appply
for (i in 1:ncol(output))
{
  
  write.table(pull(output, i),
	      "temp_output/tweak_times.txt",
	      row.names = F,
	      quote = F,
	      append = T,
	      col.names = F)
  
}

