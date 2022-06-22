model Parameters

import "./main.gaml"

global {
	//----------------------Simulation Parameters------------------------
	
	//Simulation time step
	float step <- 2 #sec; 
	
	//Simulation starting date
	date starting_date <- date("2021-10-12 08:00:00"); 
	
	//Date for log files
	//date logDate <- #now;
	date logDate <- date("2022-06-03 10:14:00");
	
	date nowDate <- #now;
	
	//Duration of the simulation
	int numberOfDays <- 1; //WARNING: If >1 set numberOfHours to 24h
	int numberOfHours <- 24; //WARNING: If one day, we can also specify the number of hours, otherwise set 24h
	
	//----------------------Logging Parameters------------------------
	bool loggingEnabled <- false parameter: "Logging" category: "Logs";
	bool printsEnabled <- false parameter: "Printing" category: "Logs";
	
	bool autonomousBikeEventLog <-false parameter: "Autonomous Bike Event/Trip Log" category: "Logs";
	bool docklessBikeEventLog <-false parameter: "Dockless Bike Event/Trip Log" category: "Logs";
	bool scooterEventLog <- false parameter: "Scooter Event/Trip Log" category: "Logs";
	bool eBikeEventLog <- false parameter: "EBike Event/Trip Log" category: "Logs";
	bool conventionalBikesEventLog <-false parameter: "Conventional Bike Event/Trip Log" category: "Logs";
	bool carEventLog <-false parameter: "Car Event/Trip Log" category: "Logs";
	
	bool peopleTripLog <-false parameter: "People Trip Log" category: "Logs";
	bool peopleEventLog <-false parameter: "People Event Log" category: "Logs";
	
	bool packageTripLog <-false parameter: "Package Trip Log" category: "Logs";
	bool packageEventLog <-false parameter: "Package Event Log" category: "Logs";
		
	bool stationChargeLogs <- false parameter: "Station Charge Log" category: "Logs";
	
	bool roadsTraveledLog <- false parameter: "Roads Traveled Log" category: "Logs";
	
	//----------------------------------Scenarios-----------------------------
	bool traditionalScenario <- false parameter: "Traditional Scenario" category: "Scenarios";
	int numVehiclesPackageTraditional <- 100 min:100 max:1000 parameter: "Number or Vehicles for Package Delivery in Traditional Scenario" category:"Initial";
	
	//----------------------Autonomous Bike Parameters------------------------
	//bool autonomousBikesInUse <- true parameter: "Bike are in use: " category: "Bike";
	int numAutonomousBikes <- 75 				min: 0 max: 500 parameter: "Num Autonomous Bikes:" category: "Bike";
	float maxBatteryLifeAutonomousBike <- 30000.0 #m	min: 10000#m max: 300000#m parameter: "Autonomous Bike Battery Capacity (m):" category: "Bike"; //battery capacity in m
	float PickUpSpeedAutonomousBike <-  8/3.6 #m/#s min: 1/3.6 #m/#s max: 15/3.6 #m/#s parameter: "Autonomous Bike Pick-up Speed (m/s):" category:  "Bike";
	float RidingSpeedAutonomousBike <-  10.2/3.6 #m/#s min: 1/3.6 #m/#s max: 15/3.6 #m/#s parameter: "Autonomous Bike Riding Speed (m/s):" category:  "Bike";
	float minSafeBatteryAutonomousBike <- 0.25*maxBatteryLifeAutonomousBike #m; //Amount of battery at which we seek battery and that is always reserved when charging another bike
	float autonomousBikeCO2Emissions <- 0.035 #kg/#km parameter: "Autonomous Bike CO2 Emissions: " category: "Initial";
	
	//--------------------Dockless Bike Parameters------------------------
	//bool autonomousBikesInUse <- true parameter: "Bike are in use: " category: "Bike";
	int numDocklessBikes <- 75 	min: 0 max: 500 parameter: "Num Dockless Bikes:" category: "Dockless Bike";
	// Data extracted from: Characterizing the speed and paths of shared bicycle use in Lyon || Simulation study on the fleet performance of shared autonomous bicycles
	float RidingSpeedDocklessBike <-  10.2/3.6 #m/#s min: 1/3.6 #m/#s max: 15/3.6 #m/#s parameter: "Riding Speed Dockless Bike (m/s):" category:  "Dockless Bike";
	// Data extracted from: Good to Go - Assessing the Environmental Performance of New Mobility || Can Autonomy Make Bicycle-Sharing Systems More Sustainable - Environmental Impact Analysis of an Emerging Mobility Technology
	float docklessBikeCO2Emissions <- 0.010 #kg/#km parameter: "Dockless Bike CO2 Emissions: " category: "Initial";
	
	//---------------------Scooter Parameters--------------------------------------------
	// Data extracted from: Mi Electric Scooter Pro: https://www.mi.com/global/mi-electric-scooter-pro/specs/
	float maxBatteryLifeScooter <- 30000.0 #m	min: 25000.0#m max: 45000.0#m parameter: "Scooter Battery Capacity (m):" category: "Scooter"; 
	float PickUpSpeedScooter <-  20/3.6 #m/#s min: 1/3.6 #m/#s max: 25/3.6 #m/#s parameter: "Scooter Pick-up Speed (m/s):" category:  "Scooter";
	float RidingSpeedScooter <-  20/3.6 #m/#s min: 1/3.6 #m/#s max: 25/3.6 #m/#s parameter: "Scooter Riding Speed (m/s):" category:  "Scooter";
	float minSafeBatteryScooter <- 0.25*maxBatteryLifeScooter #m; 
	// Data extracted from: Good to Go - Assessing the Environmental Performance of New Mobility || Can Autonomy Make Bicycle-Sharing Systems More Sustainable - Environmental Impact Analysis of an Emerging Mobility Technology
	float scooterCO2Emissions <- 0.035 #kg/#km parameter: "Scooter CO2 Emissions: " category: "Initial";
	
	//---------------------EBike Parameters--------------------------------------------
	// Data extracted from: Juiced Bikes eBikes riding range: https://www.juicedbikes.com/pages/real-world-range-test
	float maxBatteryLifeEBike <- 30000.0 #m	min: 10000.0#m max: 300000.0#m parameter: "EBike Battery Capacity (m):" category: "EBike"; 
	// Data extracted from: City Bike eBikes: https://citibikenyc.com/how-it-works/electric
	float PickUpSpeedEBike <-  17/3.6 #m/#s min: 1/3.6 #m/#s max: 30/3.6 #m/#s parameter: "EBike Pick-up Speed (m/s):" category:  "EBike";
	float RidingSpeedEBike <-  17/3.6 #m/#s min: 1/3.6 #m/#s max: 30/3.6 #m/#s parameter: "EBike Riding Speed (m/s):" category:  "EBike";
	float minSafeBatteryEBike <- 0.25*maxBatteryLifeEBike #m; 
	// Data extracted from: Good to Go - Assessing the Environmental Performance of New Mobility || Can Autonomy Make Bicycle-Sharing Systems More Sustainable - Environmental Impact Analysis of an Emerging Mobility Technology
	float eBikeCO2Emissions <- 0.024 #kg/#km parameter: "EBike CO2 Emissions: " category: "Initial";
	
	//---------------------Conventional Bike Parameters--------------------------------------------
	// Data extracted from: Characterizing the speed and paths of shared bicycle use in Lyon || Simulation study on the fleet performance of shared autonomous bicycles
	float PickUpSpeedConventionalBikes <-  10.2/3.6 #m/#s min: 1/3.6 #m/#s max: 15/3.6 #m/#s parameter: "Conventional Bike Pick-up Speed (m/s):" category:  "Conventional Bike";
	float RidingSpeedConventionalBikes <-  10.2/3.6 #m/#s min: 1/3.6 #m/#s max: 15/3.6 #m/#s parameter: "Conventional Bike Riding Speed (m/s):" category:  "Conventional Bike";
	// Data extracted from: Good to Go - Assessing the Environmental Performance of New Mobility || Can Autonomy Make Bicycle-Sharing Systems More Sustainable - Environmental Impact Analysis of an Emerging Mobility Technology
	float conventionalBikeCO2Emissions <- 0.010 #kg/#km parameter: "Scooter CO2 Emissions: " category: "Initial";
	
	//---------------------Car Parameters--------------------------------------------
	// Data extracted from: 
	float maxBatteryLifeCar <- 500000.0 #m	min: 300000.0#m max: 900000.0#m parameter: "Car Battery Capacity (m):" category: "Car"; 
	float PickUpSpeedCar <-  30/3.6 #m/#s min: 1/3.6 #m/#s max: 50/3.6 #m/#s parameter: "Car Pick-up Speed (m/s):" category:  "Car";
	float RidingSpeedCar<-  30/3.6 #m/#s min: 1/3.6 #m/#s max: 50/3.6 #m/#s parameter: "Car Riding Speed (m/s):" category:  "Car";
	float minSafeBatteryCar <- 0.10*maxBatteryLifeCar #m; 
	// Data extracted from: 
	float carCO2Emissions <- 0.160 #kg/#km parameter: "Car CO2 Emissions: " category: "Initial";
		
	//----------------------numChargingStationsion Parameters------------------------
	int numChargingStations <- 5 	min: 1 max: 10 parameter: "Num Charging Stations:" category: "Initial";
	//float V2IChargingRate <- maxBatteryLife/(4.5*60*60) #m/#s; //4.5 h of charge
	float V2IChargingRate <- maxBatteryLifeAutonomousBike/(111) #m/#s;  // 111 s battery swapping -> average of the two reported by Fei-Hui Huang 2019 Understanding user acceptancd of battery swapping service of sustainable transport
	int chargingStationCapacity <- 16; //Average number of docks in bluebikes stations in April 2022
	
	//----------------------People Parameters------------------------
	//int numPeople <- 250 				min: 0 max: 1000 parameter: "Num People:" category: "Initial";
	float maxWaitTimePeople <- 60 #mn		min: 3#mn max: 60#mn parameter: "Max Wait Time People:" category: "People";
	float maxWalkTimePeople <- 10 #mn  min: 1 #mn  max: 15 #mn parameter: "Max Walking Time People:" category: "People";
	float maxDistancePeople_AutonomousBike <- maxWaitTimePeople*PickUpSpeedAutonomousBike #m; //The maxWaitTime is translated into a max radius taking into account the speed of the bikes
    float peopleSpeed <- 5/3.6 #m/#s	min: 1/3.6 #m/#s max: 10/3.6 #m/#s parameter: "People Speed (m/s):" category: "People";
   	float maxDistancePeople_DocklessBike <- maxWalkTimePeople*peopleSpeed #m; 
    
    //--------------------Package--------------------
    float maxWaitTimePackage <- 15 #mn		min: 3#mn max: 15#mn parameter: "Max Wait Time Package:" category: "Package";
	float maxDistancePackage_AutonomousBike <- maxWaitTimePackage*PickUpSpeedAutonomousBike #m;
	float maxDistancePackage_Scooter <- maxWaitTimePackage*PickUpSpeedScooter#m;
	float maxDistancePackage_EBike <- maxWaitTimePackage*PickUpSpeedEBike#m;
	float maxDistancePackage_ConventionalBike <- maxWaitTimePackage*PickUpSpeedConventionalBikes #m;
	float maxDistancePackage_Car <- maxWaitTimePackage*PickUpSpeedCar#m;
   
    /*int numpackage <- 500;
    int lunchmin <- 11;
    int lunchmax <- 14;
    int dinnermin <- 17;
    int dinnermax <- 21;*/
    
    //Demand 
    string cityDemandFolder <- "./../includes/Demand";
    csv_file demand_csv <- csv_file (cityDemandFolder+ "/user_trips_new.csv",true);
    csv_file pdemand_csv <- csv_file (cityDemandFolder+ "/package_demand.csv",true);
       
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