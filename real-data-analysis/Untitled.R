library(tidyverse)

setwd("../real-data-analysis/")

n_taxa <- list.files("for_plots", pattern = ".taxa", full.names = T) %>% 
  as.tibble() %>% 
  transmute(taxa = map(value, read_delim, 
                       delim = "\n", skip = 1, col_names = "n_taxa"),
            data = str_split(value, "/|\\.", simplify = T)[,2]) %>% 
  unnest() %>% 
  mutate(n_taxa = str_split(str_trim(n_taxa), 
                            pattern = " ", simplify = T)[,1] %>% as.numeric) %>% 
  group_by(data) %>% 
  filter(n_taxa == max(n_taxa)) %>% 
  ungroup()

tmaps <- list.files("for_plots", pattern = ".tmap", 
                    full.names = T, recursive = FALSE) %>% 
  as_tibble() %>% rename(files = value) %>% 
  mutate(map_data = map(files, read_delim, delim = "\t", col_names = FALSE)) %>% 
  separate(files, into = c("col1", "data"), "/") %>% select(-col1) %>% 
  separate(data, into = c("data", "analysis"), "_") %>% 
  mutate(analysis = str_remove(analysis, ".tmap")) %>% unnest() %>% 
  separate(X1, into = c("subclade_prob", "subclade_n"), "[\ ]+", extra = "merge") %>% 
  separate(subclade_n, into = c("subclade_n", "clade"), "\ ", extra = "merge") %>% 
  separate(clade, into = c("clade", "subclade"), " , ") %>% 
  mutate_at(vars(clade, subclade), str_remove_all, pattern = c("\\[\ |\ \\]"))

smaps <- list.files("for_plots", pattern = ".smap", 
                    full.names = T, recursive = FALSE) %>% 
  as_tibble() %>% rename(files = value) %>% 
  mutate(map_data = map(files, read_delim, delim = "\t", col_names = FALSE)) %>%
  separate(files, into = c("col1", "data"), "/") %>% select(-col1) %>% 
  separate(data, into = c("data", "analysis"), "_") %>% 
  mutate(analysis = str_remove(analysis, ".smap")) %>% unnest() %>% 
  separate(X1, into = c("clade_prob", "clade_n"), "[\ ]+", extra = "merge") %>% 
  separate(clade_n, into = c("clade_n", "clade"), "\ ", extra = "merge") %>% 
  left_join(n_taxa)
  
  
  
left_join(tmaps, smaps) %>% 
  mutate(ccdprob = as.numeric(subclade_n)/as.numeric(clade_n)) %>%
  select(-subclade_prob, -subclade_n, -clade_prob, -clade_n, -n_taxa) %>%
  spread(analysis, ccdprob) %>% 
  filter(complete.cases(.)) %>% 
  ggplot(aes(x = (bistro+mb)/2, y = bistro-mb)) + 
    geom_point() + 
    geom_smooth(method = "lm") + 
    geom_hline(yintercept = 0, color = "red") +
    theme_bw() + facet_grid(~data)


expand_clades <- function(string){
  tmp <- string %>% 
    str_remove_all(("\\{|\\}")) %>% 
    str_split(",", simplify = T) %>% c
  
  ## To be expanded
  tbe <- str_detect(tmp, "-")
  
  ## Expand
  if(any(tbe)){
    exps <- tmp[tbe] %>% 
      str_split("-", simplify = T) %>% 
      as.tibble() %>% 
      transmute(seq = map2(V1, V2, function(x,y) seq(x,y))) %>% 
      unlist(use.names = F)
    
    ## Return all elements:
    tmp[!tbe] %>% as.numeric %>% 
      c(exps) %>% 
      sort %>% 
      return()
  } else {
    return(sort(as.numeric(tmp)))
  }
}

tmaps_expanded <- tmaps %>% 
  mutate(clade_expanded = map(clade, expand_clades)) %>% 
  select(data, analysis, subclade_n, clade, subclade, clade_expanded)

smaps_expanded <- smaps %>% 
  mutate(clade_expanded = map(clade, expand_clades),
         all_taxa = map(n_taxa, seq, from = 1, by = 1),
         clade_complement = map2(n_taxa, clade_expanded, 
                                 function(x,y) setdiff(1:x, y))) %>% 
  select(data, analysis, clade_n, clade_expanded, clade_complement, clade) %>% 
  gather(key = "type", value = "clade_expanded", 
         clade_expanded, clade_complement) %>%
  mutate(type = str_remove(type, "clade_"))

map2(head(tmp$clade_expanded), head(tmp$clade_complement),
     function(x,y){
       print("This is the clade_expanded"); print(unlist(x))
       print("This is the clade_complement"); print(unlist(y))
     })

combined <- tmaps_expanded %>% 
  mutate_at(vars(clade_expanded), 
            funs(hash = map_chr(., digest::digest))) %>% 
  left_join(smaps_expanded %>%
              mutate_at(vars(clade_expanded), 
                        funs(hash = map_chr(., digest::digest))),
            by = c("data", "analysis", "hash")) 

compare <- combined %>% 
  select(data, analysis, subclade, clade_expanded = clade_expanded.x, 
         clade_n, subclade_n, clade = clade.x) %>% #filter(clade %in% c("{1-3}", "{4-6}"))
  mutate_at(vars(clade_n, subclade_n), as.numeric) %>% 
  mutate(ccdprob = subclade_n/clade_n) %>% 
  select(-clade_n, -subclade_n) %>% 
  spread(analysis, ccdprob) %>% filter(data == "cats-dogs")
filter(!is.na(bistro), !is.na(mb))

compare %>% 
  ggplot(aes(x = mb, y = bistro)) + 
  geom_point() +
  geom_smooth() +
  theme_bw()

compare %>% 
  ggplot(aes(x = mb, y = bistro)) + 
  geom_point() +
  geom_smooth() +
  facet_grid(~data) +
  theme_bw()