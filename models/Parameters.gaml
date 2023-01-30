model Parameters

import "./main.gaml"

global {
	//----------------------Simulation Parameters------------------------
	
	//Simulation time step
	float step <- 10 #sec; 
	
	//Simulation starting date
	date starting_date <- date("2022-10-11 12:00:00"); 
	
	//Date for log files
	//date logDate <- #now;
	date logDate <- date("2022-12-22 13:15:00");
	
	date nowDate <- #now;
	
	//Duration of the simulation
	int numberOfDays <- 1; //WARNING: If >1 set numberOfHours to 24h
	int numberOfHours <- 24; //WARNING: If one day, we can also specify the number of hours, otherwise set 24h
	
	//----------------------Logging Parameters------------------------
	bool loggingEnabled <- false parameter: "Logging" category: "Logs";
	bool printsEnabled <- false parameter: "Printing" category: "Logs";
	
	bool autonomousBikeEventLog <-false parameter: "Autonomous Bike Event/Trip Log" category: "Logs";
	bool carEventLog <-false parameter: "Car Event/Trip Log" category: "Logs";
	
	bool packageTripLog <-false parameter: "Package Trip Log" category: "Logs";
	bool packageEventLog <-false parameter: "Package Event Log" category: "Logs";
		
	bool stationChargeLogs <- false parameter: "Station Charge Log" category: "Logs";
	bool gasstationFuelLogs <- false parameter: "Gas Station Charge Log" category: "Logs";
	
	bool roadsTraveledLog <- false parameter: "Roads Traveled Log" category: "Logs";
	
	//----------------------------------Scenarios-----------------------------
	bool traditionalScenario <- false parameter: "Traditional Scenario" category: "Scenarios";
	int numVehiclesPackageTraditional <- 35 ;
	
	//----------------------Autonomous Scenario-------------------------
	//-----------------Autonomous Bike Parameters-----------------------
	int numAutonomousBikes <- 230 min: 50 max: 300 parameter: "Number of Autonomous Bicycles:" category: "Autonomous Bicycle";
	float PickUpSpeedAutonomousBike <-  14/3.6 #m/#s min: 8/3.6 #m/#s max: 14/3.6 #m/#s step: 3/3.6 parameter: "Bike Speed (m/s):" category:  "Autonomous Bicycle";
	float RidingSpeedAutonomousBike <-  PickUpSpeedAutonomousBike;
	float maxBatteryLifeAutonomousBike <- 65000.0 #m	min: 35000#m max: 65000#m step: 15000 parameter: "Battery Capacity (m):" category: "Autonomous Bicycle"; //battery capacity in m
	
	float minSafeBatteryAutonomousBike <- 0.25*maxBatteryLifeAutonomousBike #m; //Amount of battery at which we seek battery and that is always reserved when charging another bike
	float nightSafeBatteryAutonomousBike <- 0.9*maxBatteryLifeAutonomousBike #m; 
	
	//------------------------------------Charging Station Parameters--------------------------------------
	int numChargingStations <- 75 	min: 1 max: 100 parameter: "Num Charging Stations:" category: "Autonomous Bicycle";
	//float V2IChargingRate <- maxBatteryLife/(4.5*60*60) #m/#s; //4.5 h of charge
	float V2IChargingRate <- maxBatteryLifeAutonomousBike/(4.5*60*60) #m/#s;  // 111 s battery swapping -> average of the two reported by Fei-Hui Huang 2019 Understanding user acceptancd of battery swapping service of sustainable transport
	string rechargeRate <- "4.5hours" parameter: "Full Recharge" category: "Autonomous Bicycle" among: ["4.5hours", "111s"];
	bool nightRechargeCond <- false parameter: "Night Recharge Condition" category: "Autonomous Bicycle";
	bool rechargeCond <- false parameter: "Battery Condition" category: "Autonomous Bicycle";
	
	//----------------------Traditional Scenario-------------------------
	//------------------------Car Parameters------------------------------
	// Data extracted from: https://www.thecoldwire.com/how-many-miles-does-a-full-tank-of-gas-last/
	int numCars <- 40 parameter: "Number of Cars:" category: "Car";
	//bool isCombustionCar <- true parameter: "Combustion Car" category: "Car";
    string carType <- "Combustion" parameter: "Car Type" category: "Car" among: ["Combustion", "Electric"];
	// Data extracted from: https://movotiv.com/statistics
	float RidingSpeedCar<-  30/3.6 #m/#s parameter: "Car Speed (m/s):" category:  "Car";
	//float maxFuelCar <- 342000.0 #m	min: 320000.0#m max: 645000.0#m parameter: "Car Battery Capacity (m):" category: "Car";
	float maxFuelCar <- 500000.0 #m	min:300000.0 max: 900000.0;
	// Data extracted from: https://www.autoinsuresavings.org/far-drive-vehicle-empty/
	float minSafeFuelCar <- 1*maxFuelCar/16 #m; 
	float nightSafeFuelCar <- 0.9*maxFuelCar #m; 
	// Data extracted from: Good to Go - Assessing the Environmental Performance of New Mobility || Can Autonomy Make Bicycle-Sharing Systems More Sustainable - Environmental Impact Analysis of an Emerging Mobility Technology
	float refillingRate <- maxFuelCar/(3*60) #m/#s;  // average time to fill a tank is 2 minutes: https://www.api.org/oil-and-natural-gas/consumer-information/consumer-resources/staying-safe-pump#:~:text=It%20may%20be%20a%20temptation,be%20discharged%20at%20the%20nozzle.
        
    //--------------------------Package Parameters----------------------------
    float maxWaitTimePackage <- 60 #mn parameter: "Maximum Wait Time Package (s):" category: "Package";
	float maxDistancePackage_AutonomousBike <- maxWaitTimePackage*PickUpSpeedAutonomousBike #m;
	float maxDistancePackage_Car <- maxWaitTimePackage*RidingSpeedCar#m;
     
    //--------------------------Demand Parameters-----------------------------
    string cityDemandFolder <- "./../includes/Demand";
    csv_file pdemand_csv <- csv_file (cityDemandFolder+ "/fooddeliverytrips_cambridge.csv",true);
    
    //----------------------Map Parameters------------------------
	//Case - Cambridge
	string cityScopeCity <- "Cambridge";
	string residence <- "R";
	string office <- "O";
	string park <- "P";
	string health <- "H";
	string education <- "E";
	string usage <- "usage";
	
	map<string, rgb> color_map <- [residence::#papayawhip-10, office::#gray, park::#lightgreen, education::#lightblue, "Other"::#black];
    map<string, rgb> color_map_2 <-  [residence::#dimgray, office::#darkcyan, park::#darkolivegreen+15, education::#steelblue-50, "Other"::#black];
    
	//GIS FILES To Upload - Cambridge
	string cityGISFolder <- "./../includes/City/"+cityScopeCity;
	file bound_shapefile <- file(cityGISFolder + "/Bounds.shp")			parameter: "Bounds Shapefile:" category: "GIS";
	file buildings_shapefile <- file(cityGISFolder + "/Buildings.shp")	parameter: "Building Shapefile:" category: "GIS";
	file roads_shapefile <- file(cityGISFolder + "/Roads.shp")			parameter: "Road Shapefile:" category: "GIS";
	
	//Charging Stations - Cambridge
	csv_file chargingStations_csv <- csv_file(cityGISFolder+ "/bluebikes_stations_cambridge.csv",true);
	
	//Restaurants - Cambridge
	csv_file restaurants_csv <- csv_file (cityGISFolder+ "/restaurants_cambridge.csv",true);
	
	//Gas Stations - Cambridge
	csv_file gasstations_csv <- csv_file (cityGISFolder+ "/gasstations.csv",true);
	 
	//Image File
	file imageRaster <- file('./../images/gama_black.png');
	
	bool show_building <- true;
	bool show_road <- true;
	bool show_restaurant <- true;
	bool show_gasStation <- true;
	bool show_chargingStation <- true;
	bool show_package <- true;
	bool show_car <- true;
	bool show_autonomousBike <- true;
}	