# 01 Libraries ----
library(keras)
library(magick)  
library(tidyverse)
library(imager)
library(data.table)


# 02 Parameters ----
main_directory = getwd()

# Path to the directory where all the images are 
image_files_path <- file.path(
  main_directory, 
  "data", 
  "input", 
  "generated_by_us",
  "all_images"
)

# Images list
file_list <- list.files(
  image_files_path, 
  full.names = TRUE, 
  recursive = TRUE
)

# Output path
output_name_file = "df_clustering.csv"

output_file = file.path(
  main_directory, 
  "data",
  "output", 
  output_name_file
)

# Files with labels
file_labels_name = "labels_per_image.csv"
path_file_labels = file.path(
  main_directory, 
  "data",
  "input",
  "generated_by_us",
  "labels_per_image",
  file_labels_name
)

want_to_use_labels_per_image = TRUE
  
# 03 Feature selection ----
# Pretrained model
model <- application_vgg16(
  weights = "imagenet", 
  include_top = FALSE
)
  
# Function to load the data
image_prep <- function(x) {
  arrays <- lapply(x, function(path) {
    img <- image_load(path, target_size = c(224, 224))
    x <- image_to_array(img)
    x <- array_reshape(x, c(1, dim(x)))
    x <- imagenet_preprocess_input(x)
  })
  do.call(abind::abind, c(arrays, list(along = 1)))
}
  

  
# Using the pretrained model to select features
vgg16_feature_list <- data.frame()
  
for (image in file_list) {
    
  cat("Image", which(file_list == image), "from", length(file_list), "\n")
  vgg16_feature <- predict(model, image_prep(image))
  
  #Getting the image name
  image_name_extension = gsub(
    pattern = paste0(image_files_path, "/"), 
    replacement = "", 
    x = image
  )
  
  dot_position = str_locate(
    string = image_name_extension,
    pattern = "\\."
  )
  
  dot_position = as.numeric(dot_position[1,1])
  
  image_name = substr(
    start = 1,
    stop = dot_position -1,
    x = image_name_extension
  )
  
  flatten <- as.data.frame.table(
    vgg16_feature, 
    responseName = "value"
    ) %>%
    select(value)
    
  flatten <- cbind(image_name, as.data.frame(t(flatten)))
    
  vgg16_feature_list <- rbind(vgg16_feature_list, flatten)
}

vgg16_feature_list = vgg16_feature_list %>% 
  rename(
    pk = image_name
  )

# 04 Using labels as feautres ----
# Reading the input file
df_input_labels_per_image = fread(path_file_labels)

# Completing with missing values 
missing_pks = setdiff(vgg16_feature_list[, 1], df_input_labels_per_image$pk)
labels_created = setdiff(colnames(df_input_labels_per_image), "pk")

df_missing = data.frame(pk = missing_pks)

for(i_label in labels_created){
  df_missing[[i_label]] = -1
}

df_labels_per_image = rbind(
  df_input_labels_per_image,
  df_missing
)

df_labels_per_image$pk = as.character(df_labels_per_image$pk)
vgg16_feature_list_with_labels = vgg16_feature_list %>% 
  left_join(
    df_labels_per_image
  )


# 05 Doing PCA ----
pca <- prcomp(
  vgg16_feature_list[, -1],
  center = TRUE,
  scale = FALSE
)

pca_with_labels <- prcomp(
  vgg16_feature_list_with_labels[, -1],
  center = TRUE,
  scale = FALSE
)

# Choose 90% of variance as the  number of PCA 
summary(pca)  
total_components = 54
pca_components = pca$x
pca_components_num_selected = pca_components[, 1:total_components]

total_kgroups = 2  


pca_components_with_labels = pca_with_labels$x
pca_components_with_labels_num_selected = pca_components_with_labels[, 1:total_components]

# 06 K Means ----
# Doing clustering using components
cluster_pca <- kmeans(pca_components, total_kgroups)
cluster_pca_with_labels <- kmeans(pca_components_with_labels, total_kgroups)


cluster_list <- data.frame(
  cluster = cluster_pca$cluster, 
  cluster_with_labels = cluster_pca_with_lavels$cluster,
  vgg16_feature_list
  ) %>%
  select(
    pk,
    cluster, 
    cluster_with_labels
  ) 



# 07 Preparing the output ----
df_output = cluster_list
df_output$cluster = as.factor(df_output$cluster)
df_output$cluster_with_labels = as.factor(df_output$cluster_with_labels)
row.names(df_output) = NULL

df_output %>%
  ggplot(aes(x = PC1, y = PC2, color = cluster, label = class)) +
  geom_point() + 
  geom_text(aes(label=class),hjust=0, vjust=0)


write.csv2(
  x = df_output,
  file = output_file
)

df_output %>% 
  group_by(
    cluster,
    class
  ) %>% 
  summarise(
    total = n()
  )


# 999 Sanity checks ----

df_output$class = as.factor(df_output$class)
df_output %>% 
  group_by(
    image_name
  ) %>% 
  summarise(
    total = n()
  ) %>% 
  filter(
    total > 1
  )
