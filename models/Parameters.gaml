model Parameters

import "./main.gaml"

global {
	//----------------------Simulation Parameters------------------------
	
	//Simulation time step
	float step <- 2 #sec; 
	
	//Simulation starting date
	date starting_date <- date("2021-10-12 00:00:00"); 
	
	//Date for log files
	//date logDate <- #now;
	date logDate <- date("2022-11-15 17:50:00");
	
	date nowDate <- #now;
	
	//Duration of the simulation
	int numberOfDays <- 1; //WARNING: If >1 set numberOfHours to 24h
	int numberOfHours <- 24; //WARNING: If one day, we can also specify the number of hours, otherwise set 24h
	
	//----------------------Logging Parameters------------------------
	bool loggingEnabled <- true parameter: "Logging" category: "Logs";
	bool printsEnabled <- false parameter: "Printing" category: "Logs";
	
	bool autonomousBikeEventLog <-true parameter: "Autonomous Bike Event/Trip Log" category: "Logs";
	bool docklessBikeEventLog <-false parameter: "Dockless Bike Event/Trip Log" category: "Logs";
	bool scooterEventLog <- false parameter: "Scooter Event/Trip Log" category: "Logs";
	bool eBikeEventLog <- false parameter: "EBike Event/Trip Log" category: "Logs";
	bool conventionalBikesEventLog <-false parameter: "Conventional Bike Event/Trip Log" category: "Logs";
	bool carEventLog <-false parameter: "Car Event/Trip Log" category: "Logs";
	
	bool peopleTripLog <-false parameter: "People Trip Log" category: "Logs";
	bool peopleEventLog <-false parameter: "People Event Log" category: "Logs";
	
	bool packageTripLog <-true parameter: "Package Trip Log" category: "Logs";
	bool packageEventLog <-true parameter: "Package Event Log" category: "Logs";
		
	bool stationChargeLogs <- true parameter: "Station Charge Log" category: "Logs";
	bool gasstationFuelLogs <- false parameter: "Gas Station Charge Log" category: "Logs";
	
	bool roadsTraveledLog <- true parameter: "Roads Traveled Log" category: "Logs";
	
	//----------------------------------Scenarios-----------------------------
	bool traditionalScenario <- false parameter: "Traditional Scenario" category: "Scenarios";
	int numVehiclesPackageTraditional <- 100 min:1 max:1000 parameter: "Number or Vehicles for Package Delivery in Traditional Scenario" category:"Initial";
	
	//----------------------Autonomous Scenario-------------------------
	//-----------------Autonomous Bike Parameters-----------------------
	int numAutonomousBikes <- 200				min: 0 max: 500 parameter: "Num Autonomous Bikes:" category: "Bike";
	float maxBatteryLifeAutonomousBike <- 30000.0 #m	min: 10000#m max: 70000#m parameter: "Autonomous Bike Battery Capacity (m):" category: "Bike"; //battery capacity in m
	float PickUpSpeedAutonomousBike <-  8/3.6 #m/#s min: 1/3.6 #m/#s max: 15/3.6 #m/#s parameter: "Autonomous Bike Pick-up Speed (m/s):" category:  "Bike";
	float RidingSpeedAutonomousBike <-  PickUpSpeedAutonomousBike min: 1/3.6 #m/#s max: 15/3.6 #m/#s parameter: "Autonomous Bike Riding Speed (m/s):" category:  "Bike";
	float minSafeBatteryAutonomousBike <- 0.25*maxBatteryLifeAutonomousBike #m; //Amount of battery at which we seek battery and that is always reserved when charging another bike
	float nightSafeBatteryAutonomousBike <- 0.9*maxBatteryLifeAutonomousBike #m; 
	float autonomousBikeCO2Emissions <- 0.035 #kg/#km parameter: "Autonomous Bike CO2 Emissions: " category: "Initial";
	
	//----------------------numChargingStationsion Parameters------------------------
	//----------------------------------Before---------------------------------------
	/*int numChargingStations <- 75 	min: 1 max: 100 parameter: "Num Charging Stations:" category: "Initial";
	//float V2IChargingRate <- maxBatteryLife/(4.5*60*60) #m/#s; //4.5 h of charge
	float V2IChargingRate <- maxBatteryLifeAutonomousBike/(111) #m/#s;  // 111 s battery swapping -> average of the two reported by Fei-Hui Huang 2019 Understanding user acceptancd of battery swapping service of sustainable transport
	int chargingStationCapacity <- 16; //Average number of docks in bluebikes stations in April 2022*/
	
	//------------------------------------After--------------------------------------
	int numChargingStations <- 75 	min: 1 max: 100 parameter: "Num Charging Stations:" category: "Initial";
	//float V2IChargingRate <- maxBatteryLife/(4.5*60*60) #m/#s; //4.5 h of charge
	float V2IChargingRate <- maxBatteryLifeAutonomousBike/(4.5*60*60) #m/#s;  // 111 s battery swapping -> average of the two reported by Fei-Hui Huang 2019 Understanding user acceptancd of battery swapping service of sustainable transport
	
	
	//----------------------Traditional Scenario-------------------------
	//-----------------------Movement of People--------------------------
	
	//--------------------Dockless Bike Parameters-----------------------
	int numDocklessBikes <- 75 	min: 0 max: 500 parameter: "Num Dockless Bikes:" category: "Dockless Bike";
	// Data extracted from: Characterizing the speed and paths of shared bicycle use in Lyon || Simulation study on the fleet performance of shared autonomous bicycles
	float RidingSpeedDocklessBike <-  10.2/3.6 #m/#s min: 1/3.6 #m/#s max: 15/3.6 #m/#s parameter: "Riding Speed Dockless Bike (m/s):" category:  "Dockless Bike";
	// Data extracted from: Good to Go - Assessing the Environmental Performance of New Mobility || Can Autonomy Make Bicycle-Sharing Systems More Sustainable - Environmental Impact Analysis of an Emerging Mobility Technology
	// float docklessBikeCO2Emissions <- 0.010 #kg/#km parameter: "Dockless Bike CO2 Emissions: " category: "Initial";
	
	//----------------------Movement of Packages--------------------------
	//------------------------Car Parameters------------------------------
	// Data extracted from: https://www.thecoldwire.com/how-many-miles-does-a-full-tank-of-gas-last/
	float maxFuelCar <- 500000.0 #m	min: 320000.0#m max: 645000.0#m parameter: "Car Battery Capacity (m):" category: "Car";
	// Data extracted from: https://movotiv.com/statistics
	float RidingSpeedCar<-  30/3.6 #m/#s min: 1/3.6 #m/#s max: 50/3.6 #m/#s parameter: "Car Riding Speed (m/s):" category:  "Car";
	// Data extracted from: https://www.autoinsuresavings.org/far-drive-vehicle-empty/
	float minSafeFuelCar <- 1*maxFuelCar/16 #m; 
	float nightSafeFuelCar <- 0.9*maxFuelCar #m; 
	// Data extracted from: Good to Go - Assessing the Environmental Performance of New Mobility || Can Autonomy Make Bicycle-Sharing Systems More Sustainable - Environmental Impact Analysis of an Emerging Mobility Technology
	// float carCO2Emissions <- 0.162 #kg/#km parameter: "Car CO2 Emissions: " category: "Initial";
	float refillingRate <- maxFuelCar/(180) #m/#s;  // average time to fill a tank is 2 minutes: https://www.api.org/oil-and-natural-gas/consumer-information/consumer-resources/staying-safe-pump#:~:text=It%20may%20be%20a%20temptation,be%20discharged%20at%20the%20nozzle.
	
	
	//-----------------------Scooter Parameters----------------------------
	// Data extracted from: Mi Electric Scooter Pro: https://www.mi.com/global/mi-electric-scooter-pro/specs/
	float maxBatteryLifeScooter <- 30000.0 #m	min: 25000.0#m max: 45000.0#m parameter: "Scooter Battery Capacity (m):" category: "Scooter"; 
	float RidingSpeedScooter <-  20/3.6 #m/#s min: 1/3.6 #m/#s max: 25/3.6 #m/#s parameter: "Scooter Riding Speed (m/s):" category:  "Scooter";
	float minSafeBatteryScooter <- 0.25*maxBatteryLifeScooter #m; 
	// Data extracted from: Good to Go - Assessing the Environmental Performance of New Mobility || Can Autonomy Make Bicycle-Sharing Systems More Sustainable - Environmental Impact Analysis of an Emerging Mobility Technology
	// float scooterCO2Emissions <- 0.035 #kg/#km parameter: "Scooter CO2 Emissions: " category: "Initial";
	
	//-------------------------EBike Parameters-----------------------------
	// Data extracted from: Juiced Bikes eBikes riding range: https://www.juicedbikes.com/pages/real-world-range-test
	float maxBatteryLifeEBike <- 30000.0 #m	min: 10000.0#m max: 300000.0#m parameter: "EBike Battery Capacity (m):" category: "EBike"; 
	// Data extracted from: City Bike eBikes: https://citibikenyc.com/how-it-works/electric
	float RidingSpeedEBike <-  17/3.6 #m/#s min: 1/3.6 #m/#s max: 30/3.6 #m/#s parameter: "EBike Riding Speed (m/s):" category:  "EBike";
	float minSafeBatteryEBike <- 0.25*maxBatteryLifeEBike #m; 
	// Data extracted from: Good to Go - Assessing the Environmental Performance of New Mobility || Can Autonomy Make Bicycle-Sharing Systems More Sustainable - Environmental Impact Analysis of an Emerging Mobility Technology
	// float eBikeCO2Emissions <- 0.024 #kg/#km parameter: "EBike CO2 Emissions: " category: "Initial";
	
	//---------------------Conventional Bike Parameters-----------------------
	// Data extracted from: Characterizing the speed and paths of shared bicycle use in Lyon || Simulation study on the fleet performance of shared autonomous bicycles
	float RidingSpeedConventionalBikes <-  10.2/3.6 #m/#s min: 1/3.6 #m/#s max: 15/3.6 #m/#s parameter: "Conventional Bike Riding Speed (m/s):" category:  "Conventional Bike";
	// Data extracted from: Good to Go - Assessing the Environmental Performance of New Mobility || Can Autonomy Make Bicycle-Sharing Systems More Sustainable - Environmental Impact Analysis of an Emerging Mobility Technology
	// float conventionalBikeCO2Emissions <- 0.010 #kg/#km parameter: "Scooter CO2 Emissions: " category: "Initial";
		
		
	//--------------------------People Parameters----------------------------
	//int numPeople <- 250 				min: 0 max: 1000 parameter: "Num People:" category: "Initial";
	float maxWaitTimePeople <- 60 #mn		min: 3#mn max: 60#mn parameter: "Max Wait Time People:" category: "People";
	float maxWalkTimePeople <- 10 #mn  min: 1 #mn  max: 15 #mn parameter: "Max Walking Time People:" category: "People";
	float maxDistancePeople_AutonomousBike <- maxWaitTimePeople*PickUpSpeedAutonomousBike #m; //The maxWaitTime is translated into a max radius taking into account the speed of the bikes
    float peopleSpeed <- 5/3.6 #m/#s	min: 1/3.6 #m/#s max: 10/3.6 #m/#s parameter: "People Speed (m/s):" category: "People";
   	float maxDistancePeople_DocklessBike <- maxWalkTimePeople*peopleSpeed #m; 
    
    //--------------------------Package Parameters----------------------------
    float maxWaitTimePackage <- 1440 #mn		min: 3#mn max: 1440#mn parameter: "Max Wait Time Package:" category: "Package";
	float maxDistancePackage_AutonomousBike <- maxWaitTimePackage*PickUpSpeedAutonomousBike #m;
	float maxDistancePackage_Scooter <- maxWaitTimePackage*RidingSpeedScooter#m;
	float maxDistancePackage_EBike <- maxWaitTimePackage*RidingSpeedEBike#m;
	float maxDistancePackage_ConventionalBike <- maxWaitTimePackage*RidingSpeedConventionalBikes #m;
	float maxDistancePackage_Car <- maxWaitTimePackage*RidingSpeedCar#m;
     
    //--------------------------Demand Parameters-----------------------------
    string cityDemandFolder <- "./../includes/Demand";
    csv_file demand_csv <- csv_file (cityDemandFolder+ "/user_trips_empty.csv",true); // Change to user_trips_new when wanting to mix people and packages
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
	bool show_people <- true;
	bool show_restaurant <- true;
	bool show_gasStation <- true;
	bool show_chargingStation <- true;
	bool show_package <- true;
	bool show_car <- true;
	bool show_autonomousBike <- true;
	bool show_conventionalBike <- true;
	bool show_eBike <- true;
	bool show_scooter <- true;
	bool show_docklessBike <- true;
			
}	