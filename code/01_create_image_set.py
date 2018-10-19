import glob, os
import numpy as np
import pandas as pd
import cv2
from collections import Counter


# train set, individually ------

clusters = pd.read_csv("df_clustering.csv", sep=";")
# labels_clusters = pd.read_csv("df_label_clustering.csv", sep=";")

img_files = glob.glob(os.path.join("data_sample_2", "*", "*.*"))
for file in img_files:
    pk = file.split("_")[3].split("/")[0]+"_"+os.path.split(file)[-1].split(".")[0].replace("picture", "")
    target_clusters = clusters[clusters.pk == pk].cluster.values[0]
    # target_clusters = labels_clusters[labels_clusters.pk == pk].cluster.values[0]

    image_gray = cv2.imread(file, cv2.IMREAD_GRAYSCALE)
    image_rgb = cv2.imread(file)

    image_gray = cv2.resize(image_gray, (1024, 768), interpolation = cv2.INTER_CUBIC)
    image_rgb = cv2.resize(image_rgb, (1024, 768), interpolation = cv2.INTER_CUBIC)

    if file == img_files[0]:
        x_train_gray = np.array([image_gray])
        x_train_rgb = np.array([image_rgb])

        y_train_clusters = np.array([target_clusters])
        # y_train_labels_clusters = np.array([target_labels_clusters])

    else:
        x_train_gray = np.append(x_train_gray, np.array([image_gray]), axis=0)
        x_train_rgb = np.append(x_train_rgb, np.array([image_rgb]), axis=0)

        y_train_clusters = np.append(y_train_clusters, [target_clusters], axis=0)

x_train_gray = x_train_gray.reshape((len(img_files), 768, 1024, 1))

# train set, aggregated --------

target_obj = pd.read_csv("data_sample_2/hotels_sample.csv", sep=",")

folders = glob.glob(os.path.join("data_sample_2", "*"))
folders = list(filter(lambda x: "." not in x, folders))

ids = list(map(lambda x: x.split("_")[-1].split("/")[0], img_files))
min_num_imgs = min(Counter(ids).values())

for folder in folders:
    accomodation_id = int(folder.split("_")[-1])
    target = target_obj[target_obj.ID == accomodation_id].TYPE.values[0]

    images = glob.glob(os.path.join(folder, "*.*"))
    for file in images[:min_num_imgs]:
        image_gray = cv2.imread(file, cv2.IMREAD_GRAYSCALE)
        image_rgb = cv2.imread(file)

        image_gray = cv2.resize(image_gray, (1024, 768), interpolation=cv2.INTER_CUBIC)
        image_gray = image_gray.reshape((768, 1024, 1))
        image_rgb = cv2.resize(image_rgb, (1024, 768), interpolation=cv2.INTER_CUBIC)

        if file == images[0]:
            image_gray_temp = np.array(image_gray)
            image_rgb_temp = np.array(image_rgb)
        else:
            image_gray_temp = np.append(image_gray_temp, np.array(image_gray), axis=2)
            image_rgb_temp = np.append(image_rgb_temp, np.array(image_rgb), axis=2)

    if folder == folders[0]:
        x_train_gray_agg = np.array([image_gray_temp])
        x_train_rgb_agg = np.array([image_rgb_temp])

        y_train_target_obj = np.array([target])
    else:
        x_train_gray_agg = np.append(x_train_gray_agg, np.array([image_gray_temp]), axis=0)
        x_train_rgb_agg = np.append(x_train_rgb_agg, np.array([image_rgb_temp]), axis=0)

        y_train_target_obj = np.append(y_train_target_obj, [target], axis=0)



x_train_gray.shape
x_train_rgb.shape
x_train_gray_agg.shape
x_train_rgb_agg.shape

y_train_clusters.shape
y_train_target_obj.shape