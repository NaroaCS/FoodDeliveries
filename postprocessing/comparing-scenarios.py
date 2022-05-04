from netrc import netrc
import numpy as np
import pandas as pd
import os
import glob
import matplotlib
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import AxesGrid



#CHANGE folder  
os.chdir("../data")
extension = 'csv'

date='2021-01-31 12.00.00'
date2='2021-02-03 12.00.00'
date3='2021-02-08 12.00.00'

if False: #Load all csv files in directory and concat just once 
    #Charging
    charge_filenames = [i for i in glob.glob('./'+date+'/bike_station_charge*.{}'.format(extension))]
    charge_df_temp= pd.concat([pd.read_csv(f) for f in charge_filenames ])
    print(charge_df_temp.head())
    charge_df_temp.to_csv('./'+date+'/charge_concat.csv',index=False)

    #Bike trips
    bike_filenames =[i for i in glob.glob('./'+date+'/bike_trip_event*.{}'.format(extension))]
    bike_df_temp= pd.concat([pd.read_csv(f) for f in bike_filenames ])
    print(bike_df_temp.head())
    bike_df_temp.to_csv('./'+date+'/bike_concat.csv',index=False)

    #User trips
    user_filenames =[i for i in glob.glob('./'+date+'/people_trips_*.{}'.format(extension))]
    user_df_temp= pd.concat([pd.read_csv(f) for f in user_filenames ])
    print(user_df_temp.head())
    user_df_temp.to_csv('./'+date+'/user_concat.csv',index=False)

if False:
    #Charging
    charge_filenames2 = [i for i in glob.glob('./'+date2+'/bike_station_charge*.{}'.format(extension))]
    charge_df_temp2= pd.concat([pd.read_csv(f) for f in charge_filenames2 ])
    print(charge_df_temp2.head())
    charge_df_temp2.to_csv('./'+date2+'/charge_concat.csv',index=False)

    #Bike trips
    bike_filenames2 =[i for i in glob.glob('./'+date2+'/bike_trip_event*.{}'.format(extension))]
    bike_df_temp2= pd.concat([pd.read_csv(f) for f in bike_filenames2 ])
    print(bike_df_temp2.head())
    bike_df_temp2.to_csv('./'+date2+'/bike_concat.csv')

    #User trips
    user_filenames2 =[i for i in glob.glob('./'+date2+'/people_trips_*.{}'.format(extension))]
    user_df_temp2= pd.concat([pd.read_csv(f) for f in user_filenames2 ])
    print(user_df_temp2.head())
    user_df_temp2.to_csv('./'+date2+'/user_concat.csv')

if False:
    #Charging
    charge_filenames3 = [i for i in glob.glob('./'+date3+'/bike_station_charge*.{}'.format(extension))]
    charge_df_temp3= pd.concat([pd.read_csv(f) for f in charge_filenames3 ])
    print(charge_df_temp3.head())
    charge_df_temp3.to_csv('./'+date3+'/charge_concat.csv',index=False)

    #Bike trips
    bike_filenames3 =[i for i in glob.glob('./'+date3+'/bike_trip_event*.{}'.format(extension))]
    bike_df_temp3= pd.concat([pd.read_csv(f) for f in bike_filenames3 ])
    print(bike_df_temp3.head())
    bike_df_temp3.to_csv('./'+date3+'/bike_concat.csv')

    #User trips
    user_filenames3 =[i for i in glob.glob('./'+date3+'/people_trips_*.{}'.format(extension))]
    user_df_temp3= pd.concat([pd.read_csv(f) for f in user_filenames3 ])
    print(user_df_temp3.head())
    user_df_temp3.to_csv('./'+date3+'/user_concat.csv')



if False:#Just trying to patch some error...

    #Results with perhomones
    charge_df=pd.read_csv('./'+date+'/charge_concat.csv')
    bike_df=pd.read_csv('./'+date+'/bike_concat.csv')
    user_df=pd.read_csv('./'+date+'/user_concat.csv')
    #user_df=pd.read_csv('./'+date+'/user_concat.csv',dtype={"Num Bikes": int, "Wandering Speed": float, "Evaporation":float, "Exploitation":float})
    charge_df.drop(charge_df.loc[charge_df['Num Bikes']=='Num Bikes'].index, inplace=True)
    bike_df.drop(bike_df.loc[bike_df['Num Bikes']=='Num Bikes'].index, inplace=True)
    user_df.drop(user_df.loc[user_df['Num Bikes']=='Num Bikes'].index, inplace=True)
    error_charge=[0,2,3,4,5,6,7,8,9,14,15,16,17]
    error_bike=[0,2,3,4,5,6,7,8,9,15,16,17,18,19]
    error_user=[0,2,3,4,5,6,7,8,9,12,15,16,17,18,19]
    for i in error_charge:
        charge_df.iloc[:,i]=pd.to_numeric(charge_df.iloc[:,i])
    for i in error_bike:
        bike_df.iloc[:,i]=pd.to_numeric(bike_df.iloc[:,i])
    for i in error_user:
        user_df.iloc[:,i]=pd.to_numeric(user_df.iloc[:,i])
    user_df['Trip Served'] = user_df['Trip Served'].astype('bool')
    charge_df.to_csv('./'+date+'/charge_concat.csv')
    bike_df.to_csv('./'+date+'/bike_concat.csv')
    user_df.to_csv('./'+date+'/user_concat.csv')

#Results with perhomones (P, Pheromones)
#charge_df=pd.read_csv('./'+date+'/charge_concat.csv')
bike_df=pd.read_csv('./'+date+'/bike_concat.csv')
user_df=pd.read_csv('./'+date+'/user_concat.csv')

#Results without perhomones, no wandering (N, Nominal)
#charge_df_n=pd.read_csv('./'+date2+'/charge_concat.csv')
bike_df_n=pd.read_csv('./'+date2+'/bike_concat.csv')
user_df_n=pd.read_csv('./'+date2+'/user_concat.csv')

#Results with random movement (R, Random)
#charge_df_r=pd.read_csv('./'+date3+'/charge_concat.csv')
bike_df_r=pd.read_csv('./'+date3+'/bike_concat.csv')
user_df_r=pd.read_csv('./'+date3+'/user_concat.csv')

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

wait_matrix_p=np.zeros((x_size,y_size))
served_matrix_p=np.zeros((x_size,y_size))

wait_matrix_n=np.zeros((x_size,y_size))
served_matrix_n=np.zeros((x_size,y_size))

wait_matrix_r=np.zeros((x_size,y_size))
served_matrix_r=np.zeros((x_size,y_size))

wait_matrix_p_n=np.zeros((x_size,y_size))
served_matrix_p_n=np.zeros((x_size,y_size))

wait_matrix_p_r=np.zeros((x_size,y_size))
served_matrix_p_r=np.zeros((x_size,y_size))

wait_matrix_r_n=np.zeros((x_size,y_size))
served_matrix_r_n=np.zeros((x_size,y_size))

net_pheromone_matrix=np.zeros((x_size,y_size))

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

                #PHEROMONES#
                temp=user_df.loc[(user_df['Num Bikes']==n_bikes)&(user_df['Wandering Speed']==wander_speed)&(user_df['Evaporation']==evaporation)&(user_df['Exploitation']==exploitation)]
                #Compute aveage wait 
                sum=temp['Wait Time (min)'].sum()
                len=temp['Wait Time (min)'].size
                average_wait_p=sum/len
                #Compute average percentage of served trips
                count_served=temp.loc[temp['Trip Served']==True].shape[0]
                count_unserved=temp.loc[temp['Trip Served']==False].shape[0]
                average_served_p=(count_served)/(count_served+count_unserved)*100

                #NOMINAL
                temp_n=user_df_n.loc[(user_df_n['Num Bikes']==n_bikes)&(user_df_n['Wandering Speed']==wander_speed)]
                #Compute aveage wait 
                sum_n=temp_n['Wait Time (min)'].sum()
                len_n=temp_n['Wait Time (min)'].size
                average_wait_n=sum_n/len_n
                #Compute average percentage of served trips
                count_served_n=temp_n.loc[temp_n['Trip Served']==True].shape[0]
                count_unserved_n=temp_n.loc[temp_n['Trip Served']==False].shape[0]
                average_served_n=(count_served_n)/(count_served_n+count_unserved_n)*100

                #RANDOM
                temp_r=user_df_r.loc[(user_df_r['Num Bikes']==n_bikes)&(user_df_r['Wandering Speed']==wander_speed)]
                #Compute aveage wait 
                sum_r=temp_r['Wait Time (min)'].sum()
                len_r=temp_r['Wait Time (min)'].size
                average_wait_r=sum_r/len_r
                #Compute average percentage of served trips
                count_served_r=temp_r.loc[temp_r['Trip Served']==True].shape[0]
                count_unserved_r=temp_r.loc[temp_r['Trip Served']==False].shape[0]
                average_served_r=(count_served_r)/(count_served_r+count_unserved_r)*100

                #SAVE DATA
                wait_matrix_p[u,v]=average_wait_p
                served_matrix_p[u,v]=average_served_p
                wait_matrix_n[u,v]=average_wait_n 
                served_matrix_n[u,v]=average_served_n
                wait_matrix_r[u,v]=average_wait_r 
                served_matrix_r[u,v]=average_served_r

                wait_matrix_p_n[u,v]=average_wait_p - average_wait_n 
                served_matrix_p_n[u,v]=average_served_p - average_served_n 
                wait_matrix_p_r[u,v]=average_wait_p - average_wait_r 
                served_matrix_p_r[u,v]=average_served_p - average_served_r 
                wait_matrix_r_n[u,v]=average_wait_r - average_wait_n
                served_matrix_r_n[u,v]=average_served_r - average_served_n 

                # # Isolating the effect of pheromones only
                if served_matrix_p[u,v] <100 : #This happens mainly bcs vehicles need to charge at high wander speeds, we isolate this bcs it has an effect on wait time (trips not served are the ones w. longest wait)
                    net_pheromone_matrix[u,v]=np.NaN  ##NOTE: we're allowing for served in random to be below 100%
                else:  
                    if wait_matrix_p_n[u,v] == 0 : 
                        net_pheromone_matrix[u,v]= 0
                    else:  #Both p and r have a benefit  (-)-(-)=-+ // #Both p and r have a ng effect (incr wait) (+)-(+) = +- // (-)-(+)=-- // (+)-(-)=++
                        net_pheromone_matrix[u,v]= (average_wait_p - average_wait_r)/average_wait_n*100 #Net benefit (p-n)-(r-n) = p -r
                
                #Another version
                # if served_matrix_p[u,v] <100 or wait_matrix_p_n[u,v] >= 0.0 : #This happens mainly bcs vehicles need to charge at high wander speeds, we isolate this bcs it has an effect on wait time (trips not served are the ones w. longest wait)
                #     net_pheromone_matrix[u,v]=np.NaN  ##NOTE: we're allowing for served in random to be below 100%
                # else:   #Both p and r have a benefit  (-)-(-)=-+ // # P has a benefit but not R (-)-(+)=-- 
                #         net_pheromone_matrix[u,v]= (average_wait_p - average_wait_r)/average_wait_n*100 #Net benefit (p-n)-(r-n) = p -r


                v+=1


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

def shiftedColorMap(cmap, start=0, midpoint=0.5, stop=1.0, name='shiftedcmap'):
    '''
    Function to offset the "center" of a colormap. Useful for
    data with a negative min and positive max and you want the
    middle of the colormap's dynamic range to be at zero.

    Input
    -----
      cmap : The matplotlib colormap to be altered
      start : Offset from lowest point in the colormap's range.
          Defaults to 0.0 (no lower offset). Should be between
          0.0 and `midpoint`.
      midpoint : The new center of the colormap. Defaults to 
          0.5 (no shift). Should be between 0.0 and 1.0. In
          general, this should be  1 - vmax / (vmax + abs(vmin))
          For example if your data range from -15.0 to +5.0 and
          you want the center of the colormap at 0.0, `midpoint`
          should be set to  1 - 5/(5 + 15)) or 0.75
      stop : Offset from highest point in the colormap's range.
          Defaults to 1.0 (no upper offset). Should be between
          `midpoint` and 1.0.
    '''
    cdict = {
        'red': [],
        'green': [],
        'blue': [],
        'alpha': []
    }

    # regular index to compute the colors
    reg_index = np.linspace(start, stop, 257)

    # shifted index to match the data
    shift_index = np.hstack([
        np.linspace(0.0, midpoint, 128, endpoint=False), 
        np.linspace(midpoint, 1.0, 129, endpoint=True)
    ])

    for ri, si in zip(reg_index, shift_index):
        r, g, b, a = cmap(ri)

        cdict['red'].append((si, r, r))
        cdict['green'].append((si, g, g))
        cdict['blue'].append((si, b, b))
        cdict['alpha'].append((si, a, a))

    newcmap = matplotlib.colors.LinearSegmentedColormap(name, cdict)
    plt.register_cmap(cmap=newcmap)

    return newcmap


#P-color palettes
wait_max=wait_matrix_p.max()
wait_min=wait_matrix_p.min()
served_max=served_matrix_p.max()
served_min=served_matrix_p.min()
m= 1-(wait_max/(wait_max+abs(wait_min)))
orig_cmap = matplotlib.cm.coolwarm
shifted_cmap_wait_p = shiftedColorMap(orig_cmap, midpoint=m)
m= 1-(served_max/(served_max+abs(served_min)))
orig_cmap = matplotlib.cm.coolwarm_r
shifted_cmap_served_p = shiftedColorMap(orig_cmap, midpoint=m)

#N-color palettes
wait_max=wait_matrix_n.max()
wait_min=wait_matrix_n.min()
served_max=served_matrix_n.max()
served_min=served_matrix_n.min()
m= 1-(wait_max/(wait_max+abs(wait_min)))
orig_cmap = matplotlib.cm.coolwarm
shifted_cmap_wait_n = shiftedColorMap(orig_cmap, midpoint=m)
m= 1-(served_max/(served_max+abs(served_min)))
orig_cmap = matplotlib.cm.coolwarm_r
shifted_cmap_served_n = shiftedColorMap(orig_cmap, midpoint=m)

#R-color palettes
wait_max=wait_matrix_r.max()
wait_min=wait_matrix_r.min()
served_max=served_matrix_r.max()
served_min=served_matrix_r.min()
m= 1-(wait_max/(wait_max+abs(wait_min)))
orig_cmap = matplotlib.cm.coolwarm
shifted_cmap_wait_r = shiftedColorMap(orig_cmap, midpoint=m)
m= 1-(served_max/(served_max+abs(served_min)))
orig_cmap = matplotlib.cm.coolwarm_r
shifted_cmap_served_r = shiftedColorMap(orig_cmap, midpoint=m)

#P-N-color palettes
wait_max=wait_matrix_p_n.max()
wait_min=wait_matrix_p_n.min()
served_max=served_matrix_p_n.max()
served_min=served_matrix_p_n.min()
m= 1-(wait_max/(wait_max+abs(wait_min)))
orig_cmap = matplotlib.cm.coolwarm
shifted_cmap_wait_p_n = shiftedColorMap(orig_cmap, midpoint=m)
m= 1-(served_max/(served_max+abs(served_min)))
orig_cmap = matplotlib.cm.coolwarm_r
shifted_cmap_served_p_n = shiftedColorMap(orig_cmap, midpoint=m)

#P-R-color palettes
wait_max=wait_matrix_p_r.max()
wait_min=wait_matrix_p_r.min()
served_max=served_matrix_p_r.max()
served_min=served_matrix_p_r.min()
m= 1-(wait_max/(wait_max+abs(wait_min)))
orig_cmap = matplotlib.cm.coolwarm
shifted_cmap_wait_p_r = shiftedColorMap(orig_cmap, midpoint=m)
m= 1-(served_max/(served_max+abs(served_min)))
orig_cmap = matplotlib.cm.coolwarm_r
shifted_cmap_served_p_r = shiftedColorMap(orig_cmap, midpoint=m)

#R-N-color palettes
wait_max=wait_matrix_r_n.max()
wait_min=wait_matrix_r_n.min()
served_max=served_matrix_r_n.max()
served_min=served_matrix_r_n.min()
m= 1-(wait_max/(wait_max+abs(wait_min)))
orig_cmap = matplotlib.cm.coolwarm
shifted_cmap_wait_r_n = shiftedColorMap(orig_cmap, midpoint=m)
m= 1-(served_max/(served_max+abs(served_min)))
orig_cmap = matplotlib.cm.coolwarm_r
shifted_cmap_served_r_n = shiftedColorMap(orig_cmap, midpoint=m)

#net pallete
wait_max=np.nanmax(net_pheromone_matrix)
print(wait_max)
wait_min=np.nanmin(net_pheromone_matrix)
print(wait_min)
m= 1-(wait_max/(wait_max+abs(wait_min)))
print(m)
orig_cmap = matplotlib.cm.coolwarm
shifted_cmap_wait_net = shiftedColorMap(orig_cmap, midpoint=m)
# combined_max=np.nanmax(combined_matrix)
# print(combined_max)
# combined_min=np.nanmin(combined_matrix)
# print(combined_min)
# m2= 1-(combined_max/(combined_max+abs(combined_min))) #1 - vmax / (vmax + abs(vmin)
# print(m2)
# orig_cmap2 = matplotlib.cm.coolwarm
# shifted_cmap2 = shiftedColorMap(orig_cmap2, midpoint=m2, name='shifted')

#### FIGURE 13: NET PHEROMONE IMPACT
plt.pcolormesh(X, Y, net_pheromone_matrix,cmap=shifted_cmap_wait_net)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(net_pheromone_matrix[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Combined: If not 100 perc. served Nan, otherwise net pheromone wait impact[min]')
plt.savefig('net.png', bbox_inches='tight')
plt.show()

#### FIGURE 1: WAIT TIMES PHEROMONES
plt.pcolormesh(X, Y, wait_matrix_p,cmap=shifted_cmap_wait_p)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(wait_matrix_p[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Wait times [min]: Pheromones')
plt.savefig('wait_p.png', bbox_inches='tight')
plt.show()

#### FIGURE 2: PERCENTAGE SERVED TRIPS PHEROMONES

plt.pcolormesh(X, Y, served_matrix_p,cmap=shifted_cmap_served_p)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(served_matrix_p[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Served trips [%]: Pheromones')
plt.savefig('served_p.png', bbox_inches='tight')
plt.show()


#### FIGURE 3: WAIT TIMES NOMINAL
plt.pcolormesh(X, Y, wait_matrix_n,cmap=shifted_cmap_wait_n)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(wait_matrix_n[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Wait times [min]: Nominal')
plt.savefig('wait_n.png', bbox_inches='tight')
plt.show()

#### FIGURE 4: PERCENTAGE SERVED TRIPS NOMINAL
plt.pcolormesh(X, Y, served_matrix_n,cmap=shifted_cmap_served_n)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(served_matrix_n[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Served trips [%]: Nominal')
plt.savefig('served_n.png', bbox_inches='tight')
plt.show()

#### FIGURE 5: WAIT TIMES RANDOM
plt.pcolormesh(X, Y, wait_matrix_r,cmap=shifted_cmap_wait_r)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(wait_matrix_r[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Wait times [min]: Random')
plt.savefig('wait_r.png', bbox_inches='tight')
plt.show()

#### FIGURE 6: PERCENTAGE SERVED TRIPS RANDOM
plt.pcolormesh(X, Y, served_matrix_r,cmap=shifted_cmap_served_r)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(served_matrix_r[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Served trips [%]: Random')
plt.savefig('served_r.png', bbox_inches='tight')
plt.show()

#### FIGURE 7: WAIT TIMES DIFFERENCE P-N

plt.pcolormesh(X, Y, wait_matrix_p_n,cmap=shifted_cmap_wait_p_n)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(wait_matrix_p_n[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Wait times difference [min]: pheromones - nominal')
plt.savefig('wait_p_n.png', bbox_inches='tight')
plt.show()

#### FIGURE 8: PERCENTAGE SERVED TRIPS DIFFERENCE P-N
plt.pcolormesh(X, Y, served_matrix_p_n,cmap=shifted_cmap_served_p_n)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(served_matrix_p_n[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Served trips difference [%]: pheromones - nominal')
plt.savefig('served_p_n.png', bbox_inches='tight')
plt.show()

#### FIGURE 9: WAIT TIMES DIFFERENCE P-R

plt.pcolormesh(X, Y, wait_matrix_p_r,cmap=shifted_cmap_wait_p_r)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(wait_matrix_p_r[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Wait times difference [min]: pheromones - random')
plt.savefig('wait_p_r.png', bbox_inches='tight')
plt.show()

#### FIGURE 10: PERCENTAGE SERVED TRIPS DIFFERENCE P-R
plt.pcolormesh(X, Y, served_matrix_p_r,cmap=shifted_cmap_served_p_r)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(served_matrix_p_r[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Served trips difference [%]: pheromones -random')
plt.savefig('served_p_r.png', bbox_inches='tight')
plt.show()


#### FIGURE 11: WAIT TIMES DIFFERENCE R-N

plt.pcolormesh(X, Y, wait_matrix_r_n,cmap=shifted_cmap_wait_r_n)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(wait_matrix_r_n[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Wait times difference [min]: random - nominal')
plt.savefig('wait_r_n.png', bbox_inches='tight')
plt.show()

#### FIGURE 12: PERCENTAGE SERVED TRIPS DIFFERENCE R-N
plt.pcolormesh(X, Y, served_matrix_r_n,cmap=shifted_cmap_served_r_n)
for i in range(x_size):
    for j in range(y_size):
        plt.text(j,i, round(served_matrix_r_n[i,j],2), color="w")
plt.colorbar()
plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
plt.xlabel("[Evaporation, Exploitation]")
plt.yticks(yi[:-1]+0.5, labels_1)
plt.ylabel("[Num bikes, Wander Speed]")
plt.title('Served trips difference [%]: random - nominal')
plt.savefig('served_r_n.png', bbox_inches='tight')
plt.show()



#Combined matrix
# #comb_matrix=np.zeros((x_size,y_size))
        #OLD:
        # #for i in range(x_size):
        # #for j in range(y_size):
        # #        comb_matrix[i,j]=((served_matrix[i,j]-served_min)/(served_max-served_min))-((wait_matrix[i,j]-min_wait)/(max_wait-min_wait))

# combined_max=np.nanmax(combined_matrix)
# print(combined_max)
# combined_min=np.nanmin(combined_matrix)
# print(combined_min)
# m2= 1-(combined_max/(combined_max+abs(combined_min))) #1 - vmax / (vmax + abs(vmin)
# print(m2)
# orig_cmap2 = matplotlib.cm.coolwarm
# shifted_cmap2 = shiftedColorMap(orig_cmap2, midpoint=m2, name='shifted')


# plt.pcolormesh(X, Y, combined_matrix,cmap=shifted_cmap2)
# for i in range(x_size):
#     for j in range(y_size):
#         plt.text(j,i, round(combined_matrix[i,j],2), color="w")
# plt.colorbar()
# plt.xticks(xi[:-1]+0.5, labels_2, rotation=90)
# plt.xlabel("[Evaporation, Exploitation]")
# plt.yticks(yi[:-1]+0.5, labels_1)
# plt.ylabel("[Num bikes, Wander Speed]")
# plt.title('Combined: If not 100 perc. served Nan, otherwise pheromone wait-nominal wait')

# plt.show()