#!/usr/bin/env python3
# -*- coding: utf-8 -*-

## REMEMBER to cd in the terminal to the folder where this file is stored
import numpy as np
import pandas as pd
import os
import glob
import matplotlib.pyplot as plt

#Load all csv files in directory
os.chdir("./2021-01-26 12.00.01/people_trips")
extension = 'csv'
all_filenames = [i for i in glob.glob('*.{}'.format(extension))]

#combine all files in a single dataframe
combined_df= pd.concat([pd.read_csv(f) for f in all_filenames ])

#Extract parameter values
low_pheromone_possible=combined_df['Low pheromone'].unique()
low_pheromone_possible.sort()
print('Low pheromone: ',low_pheromone_possible)

probability_possible=combined_df['Switch probability'].unique()
probability_possible.sort()
print('Switch probability: ',probability_possible)

read_update_possible=combined_df['Read update'].unique()
read_update_possible.sort()
print('Read update: ',read_update_possible)

#Set matrix sizes
i_size=low_pheromone_possible.size
j_size=read_update_possible.size
k_size=probability_possible.size

#We have three variables in two axes - i alone / j+k combined
x_size= i_size
y_size=j_size*k_size

#Initialize matrices
wait_matrix=np.zeros((x_size,y_size))
served_matrix=np.zeros((x_size,y_size))



for i in range(i_size):
    l=0
    for j in range(j_size):

        for k in range(k_size):

            #Read values and filter dataframe
            pheromone=low_pheromone_possible[i]
            probability=probability_possible[k]
            rate=read_update_possible[j]
            temp=combined_df.loc[(combined_df['Low pheromone']==pheromone)&(combined_df['Switch probability']==probability)&(combined_df['Read update']==rate)]

            #Compute aveage wait 
            sum=temp['Wait Time (min)'].sum()
            len=temp['Wait Time (min)'].size
            average_wait=sum/len
            wait_matrix[i,l]=average_wait #Save in matrix

            #Compute average percentage of served trips
            count_served=temp.loc[temp['Trip Served']==True].shape[0]
            count_unserved=temp.loc[temp['Trip Served']==False].shape[0]
            average_served=(count_served)/(count_served+count_unserved)*100
            served_matrix[i,l]=average_served #Save in matrix

            l+=1


#Combined matrix
comb_matrix=np.zeros((x_size,y_size))

max_wait=wait_matrix.max()
min_wait=wait_matrix.min()

served_max=served_matrix.max()
served_min=served_matrix.min()

for i in range(i_size):
    for j in range(l):
        comb_matrix[i,j]=((served_matrix[i,j]-served_min)/(served_max-served_min))-((wait_matrix[i,j]-min_wait)/(max_wait-min_wait))



#Process the labels for the combined axis
labels= []
for j in range(j_size):
    for k in range(k_size):
        labels.append([read_update_possible[j],probability_possible[k]])


#Create grid
yi = np.arange(0, x_size+1) #shift x and y
xi = np.arange(0, y_size+1)
X, Y = np.meshgrid(xi, yi)


#### FIGURE 1: WAIT TIMES

plt.subplot(3,1,1)
plt.pcolormesh(X, Y, wait_matrix,cmap='coolwarm')
    #for i in range(x_size-1):
        #for j in range(y_size-1):
            #plt.text(j,i, wait_matrix[i,j], color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels, rotation=90)
plt.xlabel("[Rate, Probability]")
plt.yticks(yi[:-1]+0.5, low_pheromone_possible)
plt.ylabel("Low pheromone threshold")
plt.title('Wait times [min]')

#### FIGURE 2: PERCENTAGE SERVED TRIPS

plt.subplot(3,1,2)
plt.pcolormesh(X, Y, served_matrix,cmap='coolwarm_r')
    #for i in range(x_size-1):
        #for j in range(y_size-1):
            #plt.text(j,i, wait_matrix[i,j], color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels, rotation=90)
plt.xlabel("[Rate, Probability]")
plt.yticks(yi[:-1]+0.5, low_pheromone_possible)
plt.ylabel("Low pheromone threshold")
plt.title('Served trips [%]')

#### FIGURE 3: COMBINED

plt.subplot(3,1,3)
plt.pcolormesh(X, Y, comb_matrix,cmap='coolwarm_r')
    #for i in range(x_size-1):
        #for j in range(y_size-1):
            #plt.text(j,i, wait_matrix[i,j], color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels, rotation=90)
plt.xlabel("[Rate, Probability]")
plt.yticks(yi[:-1]+0.5, low_pheromone_possible)
plt.ylabel("Low pheromone threshold")
plt.title('Combined')

plt.show()




#Init arrays
wait_pheromone=[]
wait_read=[]
wait_probability=[]

#Init arrays
x_pheromone= np.zeros((i_size,1))
y_wait_pheromone= np.zeros((i_size,1))
y_served_pheromone= np.zeros((i_size,1))
x_read=np.zeros((j_size,1))
y_wait_read=np.zeros((j_size,1))
y_served_read=np.zeros((j_size,1))
x_probability=np.zeros((k_size,1))
y_wait_probability=np.zeros((k_size,1))
y_served_probability=np.zeros((k_size,1))

for i in range(i_size):
    pheromone=low_pheromone_possible[i]
    temp=combined_df.loc[(combined_df['Low pheromone']==pheromone)]
    sum=temp['Wait Time (min)'].sum()
    len=temp['Wait Time (min)'].size
    x_pheromone[i]=pheromone
    y_wait_pheromone[i]=sum/len

    count_served=temp.loc[temp['Trip Served']==True].shape[0]
    count_unserved=temp.loc[temp['Trip Served']==False].shape[0]
    average_served=(count_served)/(count_served+count_unserved)*100
    y_served_pheromone[i]=average_served
    

for j in range(j_size):
    rate=read_update_possible[j]
    temp=combined_df.loc[(combined_df['Read update']==rate)]
    sum=temp['Wait Time (min)'].sum()
    len=temp['Wait Time (min)'].size
    x_read[j]=rate
    y_wait_read[j]=sum/len

    count_served=temp.loc[temp['Trip Served']==True].shape[0]
    count_unserved=temp.loc[temp['Trip Served']==False].shape[0]
    average_served=(count_served)/(count_served+count_unserved)*100
    y_served_read[j]=average_served

for k in range(k_size):
    probability=probability_possible[k]
    temp=combined_df.loc[combined_df['Switch probability']==probability]
    sum=temp['Wait Time (min)'].sum()
    len=temp['Wait Time (min)'].size
    x_probability[k]=probability
    y_wait_probability[k]=sum/len

    count_served=temp.loc[temp['Trip Served']==True].shape[0]
    count_unserved=temp.loc[temp['Trip Served']==False].shape[0]
    average_served=(count_served)/(count_served+count_unserved)*100
    y_served_probability[k]=average_served


plt.subplot(3,1,1)
plt.scatter(x_pheromone, y_wait_pheromone)

plt.subplot(3,1,2)
plt.scatter(x_read, y_wait_read)

plt.subplot(3,1,3)
plt.scatter(x_probability, y_wait_probability)

plt.show()


plt.subplot(3,1,1)
plt.scatter(x_pheromone, y_served_pheromone)

plt.subplot(3,1,2)
plt.scatter(x_read, y_served_read)

plt.subplot(3,1,3)
plt.scatter(x_probability, y_served_probability)

plt.show()