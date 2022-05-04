import numpy as np
import pandas as pd
import os
import glob
import matplotlib.pyplot as plt

#CHANGE folder  
os.chdir("../data/2021-02-03 12.00.00")

if True: #Load all csv files in directory and concat just once 
    extension = 'csv'

    #Charging
    charge_filenames = [i for i in glob.glob('bike_station_charge*.{}'.format(extension))]
    charge_df_temp= pd.concat([pd.read_csv(f) for f in charge_filenames ])
    print(charge_df_temp.head())
    charge_df_temp.to_csv('charge_concat.csv',index=False)

    #Bike trips
    bike_filenames =[i for i in glob.glob('bike_trip_event*.{}'.format(extension))]
    bike_df_temp= pd.concat([pd.read_csv(f) for f in bike_filenames ])
    print(bike_df_temp.head())
    bike_df_temp.to_csv('bike_concat.csv')

    #User trips
    user_filenames =[i for i in glob.glob('people_trips_*.{}'.format(extension))]
    user_df_temp= pd.concat([pd.read_csv(f) for f in user_filenames ])
    print(user_df_temp.head())
    user_df_temp.to_csv('user_concat.csv')


#Read already concat .csv
charge_df=pd.read_csv('charge_concat.csv')
bike_df=pd.read_csv('bike_concat.csv')
user_df=pd.read_csv('user_concat.csv')

#Get the parameter ranges

n_bikes_possible=user_df['Num Bikes'].unique()
n_bikes_possible.sort()
print('Num Bikes: ',n_bikes_possible)

wander_speed_possible=user_df['Wandering Speed'].unique()
wander_speed_possible.sort()
print('Wandering Speed: ',wander_speed_possible)

evaporation_possible=user_df['Evaporation'].unique()
evaporation_possible.sort()
print('Evaporation: ',evaporation_possible)

exploitation_possible=user_df['Exploitation'].unique()
exploitation_possible.sort()
print('Exploitation: ',exploitation_possible)

#Set matrix sizes
i_size=n_bikes_possible.size
j_size=wander_speed_possible.size
k_size=evaporation_possible.size
l_size=exploitation_possible.size

#We have four variables in two axes i+j combined / k+l combined
x_size= i_size*j_size
y_size=k_size*l_size

#Initialize matrices
wait_matrix=np.zeros((x_size,y_size))
served_matrix=np.zeros((x_size,y_size))

u=-1

for i in range(i_size):

    for j in range(j_size):
        v=0
        u+=1
        for k in range(k_size):
            
            for l in range(l_size):

                #Read values and filter dataframe
                n_bikes=n_bikes_possible[i]
                wander_speed=wander_speed_possible[j]
                evaporation=evaporation_possible[k]
                exploitation=exploitation_possible[l]
                temp=user_df.loc[(user_df['Num Bikes']==n_bikes)&(user_df['Wandering Speed']==wander_speed)&(user_df['Evaporation']==evaporation)&(user_df['Exploitation']==exploitation)]

                #Compute aveage wait 
                sum=temp['Wait Time (min)'].sum()
                len=temp['Wait Time (min)'].size
                average_wait=sum/len
                wait_matrix[u,v]=average_wait #Save in matrix

                #Compute average percentage of served trips
                count_served=temp.loc[temp['Trip Served']==True].shape[0]
                count_unserved=temp.loc[temp['Trip Served']==False].shape[0]
                average_served=(count_served)/(count_served+count_unserved)*100
                served_matrix[u,v]=average_served #Save in matrix

                v+=1

print(wait_matrix.shape)

#Process the labels for the combined axis
labels_1= []
for i in range(i_size):
    for j in range(j_size):
        labels_1.append([n_bikes_possible[i],wander_speed_possible[j]])

labels_2 =[]

for k in range(k_size):
    for l in range(l_size):
        labels_2.append([evaporation_possible[k],exploitation_possible[l]])



#Create grid
yi = np.arange(0, x_size+1) #shift x and y
xi = np.arange(0, y_size+1)
X, Y = np.meshgrid(xi, yi)


#### FIGURE 1: WAIT TIMES

plt.pcolormesh(X, Y, wait_matrix,cmap='coolwarm')
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, wait_matrix[i,j], color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Wait times [min]')

plt.show()

#### FIGURE 2: PERCENTAGE SERVED TRIPS

plt.pcolormesh(X, Y, served_matrix,cmap='coolwarm_r')
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, served_matrix[i,j], color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Served trips [%]')

plt.show()
