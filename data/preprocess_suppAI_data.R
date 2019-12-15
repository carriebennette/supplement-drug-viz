library(dplyr)
library(httr)
library(jsonlite)
library(purrr)
library(readr)
library(rvest)
library(tidyr)

# load JSON file of data from AI2 (SuppAI dataset)
json_file <- "sentence_dict.json"
df_json <- jsonlite::fromJSON(json_file)
max <- length(df_json) # store how many records (for loop below)

# initialize matrix to store JSON data; likely a more elegant way to do this
supp_ai <- matrix(, nrow = max, ncol = 3)
colnames(supp_ai) <- c("code1", "code2", "papers")

for (i in 1:max){
  supp_ai[i, 1] <- df_json[[i]]$arg1[1,1]
  supp_ai[i, 2] <- df_json[[i]]$arg2[1,1]
  supp_ai[i, 3] <- length(df_json[[i]]$paper_id)
}

# convert to tibble and clean up
df_supp_ai <- supp_ai %>%
  as_tibble(stringsAsFactors = FALSE) %>%
  mutate(papers = as.numeric(papers)) 

# pull in CUI names from API
# not included in datasets for download for some reason 
GetCUIName <- function(cui){
  path <- paste0("https://supp.ai/api/agent/", cui)
  request <- GET(url = path, 
                 query = list(cui = cui))
  response <- content(request, as = "text", encoding = "UTF-8") 
  
  list <- fromJSON(response, flatten = TRUE)
  if(list[[1]] == "Not Found"){
    df <- data.frame(cui = cui, 
                     name = list[[1]], 
                     type = list[[1]])
  }else{
    df <- data.frame(cui = list[[1]], 
                     name = list[[2]],
                     type = list[[6]])
  }
  
  return(df)
  
}

httr::set_config(httr::config(http_version = 0)) # weird fix so things don't time out
cui_list <- unique(df_supp_ai$code1)
cui_names_list <- map(cui_list, GetCUIName) 

cui_names <- do.call(rbind, cui_names_list) %>%
  # manual fixes (these are not really drugs):
  filter(!(type == "drug" &  name == "Magnesium Sulfate") &
           !(type == "drug" & name == "Potassium Chloride") &
           !(type == "drug" & name == "Sodium Chloride")) %>%
  mutate(code1 = as.character(cui), 
         code2 = as.character(cui),
         name1 = as.character(name),
         name2 = as.character(name),
         type1 = as.character(type),
         type2 = as.character(type)) %>%
  mutate(name1 = ifelse(name1 == "8-Chloro-Cyclic Adenosine Monophosphate", "8-Chloro-cAMP", name1), # make name shorter (hack for better visual)
         name2 = ifelse(name2 == "8-Chloro-Cyclic Adenosine Monophosphate", "8-Chloro-cAMP", name2), NA) %>%
  mutate(name1 = ifelse(name1 == "Gamma-Aminobutyric Acid", "GABA", name1),
         name2 = ifelse(name2 == "Gamma-Aminobutyric Acid", "GABA", name2), NA) %>%
  mutate(name1 = ifelse(name1 == "Omega-N-Methylarginine", "L-NMMA", name1),
         name2 = ifelse(name2 == "Omega-N-Methylarginine", "L-NMMA", name2), NA) %>%
  mutate(name1 = ifelse(name1 == "Doxorubicin Hydrochloride", "Doxorubicin HCl", name1),
         name2 = ifelse(name2 == "Doxorubicin Hydrochloride", "Doxorubicin HCl", name2), NA) %>%
  mutate(name1 = ifelse(name1 == "Ng-Nitroarginine Methyl Ester", "L-NAME", name1),
         name2 = ifelse(name2 == "Ng-Nitroarginine Methyl Ester", "L-NAME", name2), NA) 
  

df_supp_ai_names <- df_supp_ai %>%
  left_join(cui_names %>% select(code1, name1, type1), by = "code1") %>%
  left_join(cui_names %>% select(code2, name2, type2), by = "code2")

# this dataset contains a list of the most commonly used supplements in the US.
# data was manually pulled from Kantor et al JAMA article describing trends in supplement use 
# (https://jamanetwork.com/journals/jama/fullarticle/2565748) as well as NIH Office of Dietary Supplements
# (https://ods.od.nih.gov/). 
# Using these datasets also helps eliminate several items listed as supplememnts that seem silly to include
# e.g., glucose (which is largest # by far), Progesterone (which is a prescription drug), and
# many things that are not sold as suppelments but rather are metabolites
supplement_use_trends <- read_csv("supplement_categories.csv")

curated_supp <- df_supp_ai_names %>% 
  left_join(supplement_use_trends %>% mutate(name1 = name, 
                                             category1 = category), by = "name1") %>%
  left_join(supplement_use_trends %>% mutate(name2 = name,
                                             category2 = category), by = "name2") %>%
  select(name1, name2, type1, type2, category1, category2, papers, code1, code2) %>%
  filter(papers >= 25) %>%
  mutate(category1 = ifelse(is.na(category1) & type1 == "drug", "drug", category1),
         category2 = ifelse(is.na(category2) & type2 == "drug", "drug", category2)) %>%
  filter(!is.na(category1) & !is.na(category2)) %>%
  unique() %>%
  mutate(combo = paste0(name1, "_", name2))

# create inverse (needed to accurately represent bi-directional flow)
# prob a better way to do this
curated_supp_rev <- curated_supp %>%
  mutate(tempA = name1, tempB = category1, tempC = type1, tempD = code1,
         name1 = name2, category1 = category2, type1 = type2, code1 = code2,
         name2 = tempA, category2 = tempB, type2 = tempC, code2 = tempD) %>%
  select(-tempA, -tempB, -tempC, -tempD) %>%
  unique()  %>%
  mutate(combo = paste0(name1, "_", name2))

# create flow matrix! 
combined_df <- rbind(curated_supp, curated_supp_rev) %>%
  arrange(type1, category1, name1, papers)

name_list <-  unique(combined_df$name1)
cui_list <-  unique(combined_df$code1)
flow_matrix <- matrix(0, length(name_list), length(name_list))

for(z in 1:nrow(combined_df)){
  for(i in 1:nrow(flow_matrix)){
    for(j in 1:ncol(flow_matrix)){
      if (combined_df$combo[z] == paste0(name_list[i], "_", name_list[j])){
        flow_matrix[i,j] <- combined_df$papers[z]
        flow_matrix[j,i] <- combined_df$papers[z]
      }else{
      }
    }  
  }
}

# also store joined categories of each supplement/drug (will be assigned colors)
category_list <- combined_df %>%
  select(name1, category1) %>%
  unique() %>%
  mutate(color = case_when(
    # drugs:
    category1 == "drug" ~ "#e08619",
    # supplements:
    category1 == "Fatty Acid" ~ "#352604",
    category1 == "Fiber" ~ "#38030e",
    category1 == "Mineral" ~ "#690a55",
    category1 == "Amino Acid" ~ "#5c870b",
    category1 == "Vitamin" ~ "#0a6b78",
    category1 == "Botanical" ~ "#364f06",
    category1 == "Other" ~ "#0d3a78",
    category1 == "Hormone" ~ "#3d0431",
    category1 == "Protein" ~ "#0a4d80",
    TRUE ~ "#eb9c09"
  )) %>%
  select(color) %>%
  as.list() %>% 
  as.vector()

names(category_list) <- NULL
category_list <- unlist(category_list) # this process seems awkward, but it works

# output data as JSON file for use in D3
# need to figure out how to work with JSON data more elegantly than this... 
json_matrix <- jsonlite::toJSON(flow_matrix, dataframe = 'values', pretty = TRUE)
write(json_matrix, "matrix.json")

json_names <- jsonlite::toJSON(name_list, dataframe = 'values', pretty = TRUE)
write(json_names, "name_list.json")

json_names <- jsonlite::toJSON(cui_list, dataframe = 'values', pretty = TRUE)
write(json_names, "cui_list.json")

json_categories <- jsonlite::toJSON(category_list, dataframe = 'values', pretty = TRUE)
write(json_categories, "category_list.json")



