from keras.utils import to_categorical
from keras.models import Sequential
from keras.layers import Dense, Conv2D, Flatten

#one-hot encode target column
y_train_clusters = to_categorical(y_train_clusters)

#create model
model = Sequential()

#add model layers
model.add(Conv2D(64, kernel_size=3, activation="relu", input_shape=(768,1024,1)))
model.add(Conv2D(32, kernel_size=3, activation="relu"))
model.add(Flatten())
model.add(Dense(3, activation="softmax"))

#compile model using accuracy to measure model performance
model.compile(optimizer='adam', loss='categorical_crossentropy')

#train the model
model.fit(x_train_gray[:3], y_train_clusters[:3], validation_data=(x_train_gray[:3], y_train_clusters[:3]), epochs=3)


#predict first 3 images in the test set
model.predict(x_train_gray[:3])
y_train_clusters