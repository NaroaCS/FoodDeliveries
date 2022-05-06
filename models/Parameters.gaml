model Parameters

import "./main.gaml"

global {
	//----------------------Simulation Parameters------------------------
	
	//Simulation time step
	float step <- 2 #sec; //TODO: Adjust this as desired (bigger step -> higher speed -> lower resolution)
	
	//Simulation starting date
	date starting_date <- date("2021-10-12 06:00:00"); 
	
	//Date for log files
	//date logDate <- #now;
	date logDate <- date("2022-05-04 00:00:00");
	
	date nowDate <- #now;
	
	//Duration of the simulation
	int numberOfDays <- 1; //WARNING: If >1 set numberOfHours to 24h
	int numberOfHours <- 24; //WARNING: If one day, we can also specify the number of hours, otherwise set 24h
	
	//----------------------Logging Parameters------------------------
	bool loggingEnabled <- true parameter: "Logging" category: "Logs";
	bool printsEnabled <- false parameter: "Printing" category: "Logs";
	
	bool bikeEventLog <-true parameter: "Bike Event/Trip Log" category: "Logs";
	
	bool peopleTripLog <-true parameter: "People Trip Log" category: "Logs";
	bool peopleEventLog <-false parameter: "People Event Log" category: "Logs";
	
	bool packageTripLog <-true parameter: "Package Trip Log" category: "Logs";
	bool packageEventLog <-false parameter: "Package Event Log" category: "Logs";
	
	bool stationChargeLogs <- true parameter: "Station Charge Log" category: "Logs";
	
	bool roadsTraveledLog <- false parameter: "Roads Traveled Log" category: "Logs";
	
	//----------------------Bike Parameters------------------------
	int numBikes <- 100 				min: 0 max: 500 parameter: "Num Bikes:" category: "Initial";
	float maxBatteryLife <- 30000.0 #m	min: 10000#m max: 300000#m parameter: "Battery Capacity (m):" category: "Bike"; //battery capacity in m
	float PickUpSpeed <-  8/3.6 #m/#s min: 1/3.6 #m/#s max: 15/3.6 #m/#s parameter: "Bike Pick-up Speed (m/s):" category:  "Bike";
	float RidingSpeed <-  10.2/3.6 #m/#s min: 1/3.6 #m/#s max: 15/3.6 #m/#s parameter: "Riding Speed (m/s):" category:  "Bike";
	float minSafeBattery <- 0.25*maxBatteryLife #m; //Amount of battery at which we seek battery and that is always reserved when charging another bike
	
	//----------------------numChargingStationsion Parameters------------------------
	int numChargingStations <- 5 	min: 1 max: 10 parameter: "Num Charging Stations:" category: "Initial";
	//float V2IChargingRate <- maxBatteryLife/(4.5*60*60) #m/#s; //4.5 h of charge
	float V2IChargingRate <- maxBatteryLife/(111) #m/#s;  // 111 s battery swapping -> average of the two reported by Fei-Hui Huang 2019 Understanding user acceptancd of battery swapping service of sustainable transport
	int chargingStationCapacity <- 16; //Average number of docks in bluebikes stations in April 2022
	
	//----------------------People Parameters------------------------
	//int numPeople <- 250 				min: 0 max: 1000 parameter: "Num People:" category: "Initial";
	float maxWaitTime <- 60 #mn		min: 3#mn max: 60#mn parameter: "Max Wait Time:" category: "People";
	float maxDistance <- maxWaitTime*PickUpSpeed #m; //The maxWaitTime is translated into a max radius taking into account the speed of the bikes
    float peopleSpeed <- 5/3.6 #m/#s	min: 1/3.6 #m/#s max: 10/3.6 #m/#s parameter: "People Speed (m/s):" category: "People";
    
    //--------------------Package--------------------
    int numpackage <- 100;
    int lunchmin <- 11;
    int lunchmax <- 14;
    int dinnermin <- 17;
    int dinnermax <- 21;
    
    //Demand 
    string cityDemandFolder <- "./../includes/Demand";
    csv_file demand_csv <- csv_file (cityDemandFolder+ "/user_trips_new.csv",true);
    csv_file pdemand_csv <- csv_file (cityDemandFolder+ "/prueba.csv",true);
       
    //----------------------Map Parameters------------------------
	
	//Case 1 - Urban Swarms Map
	string cityScopeCity <- "Kendall";
	string residence <- "R";
	string office <- "O";
	string usage <- "Usage";
	
	map<string, rgb> color_map <- [residence::#white, office::#gray, "Other"::#black];
    
	//GIS FILES To Upload
	string cityGISFolder <- "./../includes/City/"+cityScopeCity;
	file bound_shapefile <- file(cityGISFolder + "/Bounds.shp")			parameter: "Bounds Shapefile:" category: "GIS";
	file buildings_shapefile <- file(cityGISFolder + "/Buildings.shp")	parameter: "Building Shapefile:" category: "GIS";
	file roads_shapefile <- file(cityGISFolder + "/Roads.shp")			parameter: "Road Shapefile:" category: "GIS";
	
	
	file chargingStations_csv <- file("./../includes/City/Cambridge/current_bluebikes_stations.csv");
		
	csv_file supermarket_csv <- csv_file (cityGISFolder+ "/FoodPlaces.csv",true);
	 
	//Image File
	file imageRaster <- file('./../images/gama_black.png');
			
}	