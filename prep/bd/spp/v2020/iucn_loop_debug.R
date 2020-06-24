
############## trouble shoot code to pull maps ######################
for(i in seq_along(taxa)) {
  i <- 1
taxon <- taxa[i]
print(i)
spp_ids_in_taxon <- spp_maps %>%
  filter(str_detect(dbf_file, taxon)) %>%
  .$iucn_sid
cat(sprintf('processing %s spp in %s...\n', length(spp_ids_in_taxon), taxon)) #help with this, message?

spp_cells <- parallel::mclapply(spp_ids_in_taxon, mc.cores = 32,
                                FUN = function(x) { ### x <- spp_ids_in_taxon[1]
                                  f <- file.path('/home/ohara/git-annex/spp_risk_dists/spp_rasters_2019',
                                                 sprintf('iucn_sid_%s.csv', x))
                                  if(file.exists(f)) {
                                    y <- read_csv(f, col_types = 'di') %>%
                                      mutate(iucn_sid = x) %>%
                                      select(-presence)  %>%
                                      filter(cell_id %in% fp_cells)
                                  } else {
                                    y <- data.frame(cell_id = NA,
                                                    iucn_sid = x, 
                                                    f = f, error = 'file not found')
                                  }
                                  return(y)
                                })
  #bind_rows() %>%
  #mutate(spp_gp = taxon)

taxa_cells_list[[i]] <- spp_cells
}

################ try without mclapply ###################

for(i in seq_along(taxa)) { 
  #i <- 5
  taxon <- taxa[i]
  print(i)
  spp_ids_in_taxon <- spp_maps %>%
    filter(str_detect(dbf_file, taxon)) %>%
    .$iucn_sid
  cat(sprintf('processing %s spp in %s...\n', length(spp_ids_in_taxon), taxon)) #help with this, message?
  
  spp_cells <- lapply(spp_ids_in_taxon,
                      FUN = function(x) { ### x <- spp_ids_in_taxon[1]
                        f <- file.path('/home/ohara/git-annex/spp_risk_dists/spp_rasters_2019',
                                       sprintf('iucn_sid_%s.csv', x))
                        if(file.exists(f)) {
                          y <- read_csv(f, col_types = 'di') %>%
                            mutate(iucn_sid = x) %>%
                            dplyr::select(-presence)  %>%
                            filter(cell_id %in% tet_cells)
                        } else {
                          y <- data.frame(cell_id = NA,
                                          iucn_sid = x, 
                                          f = f, error = 'file not found')
                        }
                        return(y)
                      }) %>%
    bind_rows() %>%
    mutate(spp_gp = taxon)
  
  taxa_cells_list[[i]] <- spp_cells
}
