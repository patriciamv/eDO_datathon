# 01 Packages ----
library(stringr)


# 02 Parameters ----
main_directory = getwd()

# Location of accomodation folders
input_path = file.path(
  main_directory, 
  "data", 
  "input", 
  "images"
)

list_input_files = list.files(input_path)



# Location of folders where there will be all the images
ouptut_path = file.path( 
  main_directory, 
  "data", 
  "input", 
  "generated_by_us",
  "all_images"
)

# 03 Putting all images together ----
#For each folder, we take the images, change the name amb move to ouptut_path

# These counts controll how the process has finished
total_images_correctly_copied = 0
total_images_incorrectly_copied = 0
total_images_unk_copied = 0


for(i_folder in list_input_files){
  # This piece of code takes the accomodation_id
  n_characters = nchar(i_folder)
  
  first_number = str_locate(
    string = i_folder, 
    pattern = "0|1|2|3|4|5|6|7|8|9"
  )
  
  first_number = as.numeric(first_number[1,1])
  
  accomodation_id = substr(i_folder, start = first_number, stop = n_characters)
  
  # Per each folder, the images are moved and renamed
  accomodation_input_path = file.path(input_path, i_folder)
  
  list_images = list.files(accomodation_input_path)
  
  if(FALSE){
    i_picture = list_images[3]
  }
  
  for(i_picture in list_images){
    # Tals words in the picture name
    length_picture = nchar(i_picture)
    
    #This piece of code takes the picture_id
    numbers_location = str_locate_all(
      string = i_picture, 
      pattern = "0|1|2|3|4|5|6|7|8|9"
    )[[1]]
    
    range_numbers = range(numbers_location[,1])
    
    picutre_id = substr(
      i_picture, 
      start = range_numbers[1], 
      stop = range_numbers[2]
    )
    
    # Getting the extension of the image
    dot_position = str_locate(
      string = i_picture, 
      pattern = "\\."
    )
    
    dot_position = as.numeric(dot_position[1,1])
    
    image_extension = substr(
      i_picture, 
      start = dot_position+1, 
      stop = length_picture
    )
    
    # Copying the image into the new folder with the name accomodation_id_picture_id
    s = file.copy(
      from = file.path(accomodation_input_path, i_picture), 
      to = file.path(
        from = ouptut_path, 
        to = paste0(accomodation_id, "_",picutre_id,".",image_extension)
      ),
      overwrite = TRUE
    )
    
    message(paste0(accomodation_id, "_",picutre_id,".",image_extension, ": ", s))
    if(!is.na(s) && s == TRUE){
      total_images_correctly_copied = total_images_correctly_copied + 1
    } else if(!is.na(s) && s == FALSE){
      total_images_incorrectly_copied = total_images_incorrectly_copied + 1
    }else{
      total_images_unk_copied = total_images_unk_copied + 1
    }
  }
}

total_images_correctly_copied
total_images_incorrectly_copied
total_images_unk_copied
