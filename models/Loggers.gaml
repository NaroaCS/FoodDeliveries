model Loggers
import "./main.gaml"

global {
	map<string, string> filenames <- []; //Maps log types to filenames
	
	action registerLogFile(string filename) {
		if traditionalScenario = true {
			filenames[filename] <- './../data/Cambridge/TraditionalScenario/' + string(logDate, 'yyyy-MM-dd hh.mm.ss','en') + '/' + filename + '.csv';
		} else {
			filenames[filename] <- './../data/Cambridge/AutonomousScenario/' + string(logDate, 'yyyy-MM-dd hh.mm.ss','en') + '/' + filename + '.csv';
		}
	}
	
	action log(string filename, list data, list<string> columns) {
		if not(filename in filenames.keys) {
			do registerLogFile(filename);
			save ["Cycle", "Time", "Traditional Scenario", "Num Autonomous Bikes", "Num Dockless Bikes", "Num Scooters", "Num eBikes", "Num Conventional Bikes", "Num Cars",  "Agent"] + columns to: filenames[filename] type: "csv" rewrite: false header: false;
			// Parámetro a variar (que luego se quiera ver en los batch)
		}
		
		//if level <= loggingLevel {
		if loggingEnabled {
			save [cycle, string(current_date, "HH:mm:ss"), traditionalScenario, numAutonomousBikes, numDocklessBikes, numScooters, numEBikes, numConventionalBikes, numCars] + data to: filenames[filename] type: "csv" rewrite: false header: false;
		}
		if  printsEnabled {
			write [cycle, string(current_date,"HH:mm:ss"), traditionalScenario] + data;
		} 
	}
	
	action logForSetUp (list<string> parameters) {
		loop param over: parameters {
			if traditionalScenario = true {
				save (param) to: './../data/Cambridge/TraditionalScenario/' + string(logDate, 'yyyy-MM-dd hh.mm.ss','en') + '/' + 'setUp' + '.txt' type: "text" rewrite: false header: false;
			} else {
				save (param) to: './../data/Cambridge/AutonomousScenario/' + string(logDate, 'yyyy-MM-dd hh.mm.ss','en') + '/' + 'setUp' + '.txt' type: "text" rewrite: false header: false;
			}
		}
	}
	
	//Los parámetros que no se varían pero se quieren guardar para acordarse de su inicialización
	action logSetUp { 
		list<string> parameters <- [
		"NAutonomousBikes: "+string(numAutonomousBikes),
		"NDocklessBikes: "+string(numDocklessBikes),
		// Data extracted from: Contribution to the Sustainability Challenges of the Food-Delivery Sector: Finding from the Deliveroo Italy Case Study
		"NScooters: "+string(numScooters),
		"NEBikes: "+string(numEBikes),
		"NConventionalBikes: "+string(numConventionalBikes),
		"NCars: "+string(numCars),
		"MaxWaitPeople: "+string(maxWaitTimePeople/60),
		"MaxWaitPackage: "+string(maxWaitTimePackage/60),

		"------------------------------SIMULATION PARAMETERS------------------------------",
		"Step: "+string(step),
		"Starting Date: "+string(starting_date),
		"Number of Days of Simulation: "+string(numberOfDays),
		"Number ot Hours of Simulation (if less than one day): "+string(numberOfHours),

		"------------------------------BIKE PARAMETERS------------------------------",
		"Number of Bikes: "+string(numAutonomousBikes),
		"Max Battery Life of Bikes [km]: "+string(maxBatteryLifeAutonomousBike/1000 with_precision 2),
		"Pick-up speed [km/h]: "+string(PickUpSpeedAutonomousBike*3.6),
		"Minimum Battery [%]: "+string(minSafeBatteryAutonomousBike/maxBatteryLifeAutonomousBike*100),
		
		"--------------------------DOCKLESS BIKE PARAMETERS------------------------------",
		"Number of Dockless Bikes: "+string(numDocklessBikes),
		"Riding speed Dockless Bikes [km/h]: " + string(RidingSpeedDocklessBike*3.6),
		
		"------------------------------SCOOTER PARAMETERS------------------------------",
		"Number of Scooters: "+string(numScooters),
		"Max Battery Life of Scooters [km]: "+string(maxBatteryLifeScooter/1000 with_precision 2),
		"Pick-up speed Scooters [km/h]: "+string(PickUpSpeedScooter*3.6),
		"Minimum Battery Scooters [%]: "+string(minSafeBatteryScooter/maxBatteryLifeScooter*100),
		
		"------------------------------EBike PARAMETERS------------------------------",
		"Number of EBikes: "+string(numEBikes),
		"Max Battery Life of EBike [km]: "+string(maxBatteryLifeEBike/1000 with_precision 2),
		"Pick-up speed EBike [km/h]: "+string(PickUpSpeedEBike*3.6),
		"Minimum Battery EBike [%]: "+string(minSafeBatteryEBike/maxBatteryLifeEBike*100),
		
		"------------------------------CONVENTIONAL BIKE PARAMETERS------------------------------",
		"Number of Conventional Bikes: "+string(numConventionalBikes),
		"Pick-up speed Conventional Bikes [km/h]: "+string(PickUpSpeedConventionalBikes*3.6),
		"Riding speed Conventional Bikes [km/h]: " + string(RidingSpeedConventionalBikes*3.6),
		
		"------------------------------CAR PARAMETERS------------------------------",
		"Number of Cars: "+string(numCars),
		"Max Battery Life of Cars [km]: "+string(maxBatteryLifeCar/1000 with_precision 2),
		"Pick-up speed Cars [km/h]: "+string(PickUpSpeedCar*3.6),
		"Minimum Battery Cars [%]: "+string(minSafeBatteryCar/maxBatteryLifeCar*100),
		
		"------------------------------PEOPLE PARAMETERS------------------------------",
		"Maximum Wait Time People [min]: "+string(maxWaitTimePeople/60),
		"Walking Speed [km/h]: "+string(peopleSpeed*3.6),
		"Riding Speed Autonomous Bike [km/h]: "+string(RidingSpeedAutonomousBike*3.6),
		"Riding Speed Dockless Bike [km/h]: "+string(RidingSpeedDocklessBike*3.6),
		
		"------------------------------PACKAGE PARAMETERS------------------------------",
		"Maximum Wait Time Package [min]: "+string(maxWaitTimePackage/60),
		
		"------------------------------STATION PARAMETERS------------------------------",
		"Number of Charging Stations: "+string(numChargingStations),
		"V2I Charging Rate: "+string(V2IChargingRate  with_precision 2),
		"Charging Station Capacity: "+string(chargingStationCapacity),

		"------------------------------MAP PARAMETERS------------------------------",
		"City Map Name: "+string(cityScopeCity),
		"Redisence: "+string(residence),
		"Office: "+string(office),
		"Usage: "+string(usage),
		"Color Map: "+string(color_map),
		
		"------------------------------LOGGING PARAMETERS------------------------------",
		"Print Enabled: "+string(printsEnabled),
		"Autonomous Bike Event/Trip Log: " +string(autonomousBikeEventLog),
		"Dockless Bike Event/Trip Log: " +string(docklessBikeEventLog),
		"Scooter Event/Trip Log: " + string(scooterEventLog),
		"EBike Event/Trip Log: " + string(eBikeEventLog),
		"Conventional Bike Event/Trip Log: " + string(conventionalBikesEventLog),
		"Car Event/Trip Log: " + string(carEventLog),
		"People Trip Log: " + string(peopleTripLog),
		"Package Trip Log: "+ string(packageTripLog),
		"People Event Log: " + string(peopleEventLog),
		"Package Event Log:" + string(packageEventLog),
		"Station Charge Log: "+ string(stationChargeLogs),
		"Roads Traveled Log: " + string(roadsTraveledLog)
		];
		do logForSetUp(parameters);
		}
}

// Genérico
species Logger {
	
	action logPredicate virtual: true type: bool;
	string filename;
	list<string> columns;
	
	agent loggingAgent;
	
	action log(list data) {
		if logPredicate() {
			ask host {
				//llamar a función para guardar
				do log(myself.filename, [string(myself.loggingAgent.name)] + data, myself.columns);
			} 
		}
	}
}

species peopleLogger_trip parent: Logger mirrors: people {
	string filename <- string("people_trips_"+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second));
	list<string> columns <- [
		"Trip Served",
		"Mode",
		"Wait Time (min)",
		"Departure Time",
		"Arrival Time",
		"Duration (min)",
		"Home [lat]",
		"Home [lon]",
		"Work [lat]",
		"Work [lon]",
		"Distance (m)"
	];

	bool logPredicate { return peopleTripLog; }
	people persontarget;
	
	init {
		persontarget <- people(target);
		persontarget.tripLogger <- self;
		loggingAgent <- persontarget;
	}
	
	action logTrip( bool served, int mode, float waitTime, date departure, date arrival, float tripduration, point origin, point destination, float distance) {
		point origin_WGS84 <- CRS_transform(origin, "EPSG:4326").location; 
		point destination_WGS84 <- CRS_transform(destination, "EPSG:4326").location; 
		string dep;
		string des;
		
		if departure= nil {dep <- nil;}else{dep <- string(departure,"HH:mm:ss");}
		
		if arrival = nil {des <- nil;} else {des <- string(arrival,"HH:mm:ss");}
		
		do log([served, mode, waitTime,dep ,des, tripduration, origin_WGS84.x, origin_WGS84.y, destination_WGS84.x, destination_WGS84.y, distance]);
	} 
}

species packageLogger_trip parent: Logger mirrors: package {
	string filename <- string("package_trips_"+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second));
	list<string> columns <- [
		"Trip Served",
		"Mode",
		"Wait Time (min)",
		"Departure Time",
		"Arrival Time",
		"Duration (min)",
		"Home [lat]",
		"Home [lon]",
		"Work [lat]",
		"Work [lon]",
		"Distance (m)"
	];

	bool logPredicate { return packageTripLog; }
	package packagetarget;
	
	init {
		packagetarget <- package(target);
		packagetarget.tripLogger <- self;
		loggingAgent <- packagetarget;
	}
	
	action logTrip( bool served, int mode, float waitTime, date departure, date arrival, float tripduration, point origin, point destination, float distance) {
		point origin_WGS84 <- CRS_transform(origin, "EPSG:4326").location; 
		point destination_WGS84 <- CRS_transform(destination, "EPSG:4326").location; 
		string dep;
		string des;
		
		if departure= nil {dep <- nil;}else{dep <- string(departure,"HH:mm:ss");}
		
		if arrival = nil {des <- nil;} else {des <- string(arrival,"HH:mm:ss");}
		
		do log([served, mode, waitTime,dep ,des, tripduration, origin_WGS84.x, origin_WGS84.y, destination_WGS84.x, destination_WGS84.y, distance]);
	} 
}

// Identificar cosas raras que puedan pasar. Por ejmplo, que una bici nunca llegue al destinatario etc.
// Cargar solo cuando se quiere saber por qué ocurren ciertos problemas

species peopleLogger parent: Logger mirrors: people {
	string filename <- "people_event"+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
		"Mode",
		"Message",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Distance (m)"
	];
	
	bool logPredicate { return peopleEventLog; }
	people persontarget;
	
	init {
		persontarget <- people(target);
		persontarget.logger <- self;
		loggingAgent <- persontarget;
	}
	
	float tripdistance <- 0.0;
	
	date departureTime;
	int departureCycle;
    int cycleAutonomousBikeRequested;
    int cycleDocklessBikeRequested;
    float waitTime;
    int cycleStartActivity;
    date timeStartActivity;
    point locationStartActivity;
    string currentState;
    bool served;
    int mode;
    
    string timeStartstr;
    string currentstr;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		locationStartActivity <- persontarget.location;
		currentState <- persontarget.state;
		if peopleEventLog {do log(['START: ' + currentState] + [logmessage]);}
		
		if peopleTripLog{ //because trips are logged by the eventLogger
			switch currentState {
				match "requesting_autonomousBike" {
					//trip starts
					cycleAutonomousBikeRequested <- cycle;
					served <- false;
				}
				match "requesting_docklessBike" {
					//trip starts
					cycleDocklessBikeRequested <- cycle;
					served <- false;
				}
				match "riding_autonomousBike" {
					//trip is served
					waitTime <- (cycle*step- cycleAutonomousBikeRequested*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- true;
				}
				match "riding_docklessBike" {
					//trip is served
					waitTime <- (cycle*step- cycleDocklessBikeRequested*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- true;
				}
				match "wandering" {
					//trip has ended
					if tripdistance = 0 {
						tripdistance <- persontarget.start_point distance_to persontarget.target_point;
					}
				
					if cycle != 0 {
						ask persontarget.tripLogger {
							do logTrip(
								myself.served,
								myself.mode,
								myself.waitTime,
								myself.departureTime,
								current_date,
								(cycle*step - myself.departureCycle*step)/60,
								persontarget.start_point.location,
								persontarget.target_point.location,
								myself.tripdistance
							);
						}
					}
				}
			}
		}
	}

	action logExitState(string logmessage) {
		
		if timeStartActivity= nil {timeStartstr <- nil;}else{timeStartstr <- string(timeStartActivity,"HH:mm:ss");}
		if current_date = nil {currentstr <- nil;} else {currentstr <- string(current_date,"HH:mm:ss");}
		
		do log(['END: ' + currentState, mode, logmessage, timeStartstr, currentstr, (cycle*step - cycleStartActivity*step)/60, locationStartActivity distance_to persontarget.location]);
	}
	action logEvent(string event) {
		do log([event]);
	}
}

species packageLogger parent: Logger mirrors: package {
	string filename <- "package_event"+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
		"Mode",
		"Message",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Distance (m)"
	];
	
	bool logPredicate { return packageEventLog; }
	package packagetarget;
	
	init {
		packagetarget <- package(target);
		packagetarget.logger <- self;
		loggingAgent <- packagetarget;
	}
	
	float tripdistance <- 0.0;
	
	date departureTime;
	int departureCycle;
    int cycleAutonomousBikeRequested;
    int cycleScooterRequested;
    int cycleEBikeRequested;
    int cycleConventionalBikeRequested;
    int cycleCarRequested;
    float waitTime;
    int cycleStartActivity;
    date timeStartActivity;
    point locationStartActivity;
    string currentState;
    bool served;
    int mode;
    
    string timeStartstr;
    string currentstr;
	
	//faction logEnterState { do logEnterState(""); }
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		locationStartActivity <- packagetarget.location;
		currentState <- packagetarget.state;
		if packageEventLog {do log(['START: ' + currentState] + [logmessage]);}
		
		if packageTripLog{ //because trips are logged by the eventLogger
			switch currentState {
				match "requesting_autonomousBike_Package" {
					//trip starts
					cycleAutonomousBikeRequested <- cycle;
					served <- false;
				}
				match "requesting_scooter" {
					//trip starts
					cycleScooterRequested <- cycle;
					served <- false;
				}
				match "requesting_eBike" {
					//trip starts
					cycleEBikeRequested <- cycle;
					served <- false;
				}
				match "requesting_conventionalBike" {
					//trip starts
					cycleConventionalBikeRequested <- cycle;
					served <- false;
				}
				match "requesting_car" {
					//trip starts
					cycleCarRequested <- cycle;
					served <- false;
				}
				match "delivering_autonomousBike" {
					//trip is served
					waitTime <- (cycle*step- cycleAutonomousBikeRequested*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- true;
					mode <- 1;
				}
				match "delivering_scooter" {
					//trip is served
					waitTime <- (cycle*step- cycleScooterRequested*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- true;
					mode <- 2;
				}
				match "delivering_eBike" {
					//trip is served
					waitTime <- (cycle*step- cycleEBikeRequested*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- true;
					mode <- 3;
				}
				match "delivering_conventionalBike" {
					//trip is served
					waitTime <- (cycle*step- cycleConventionalBikeRequested*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- true;
					mode <- 4;
				}
				match "delivering_car" {
					//trip is served
					waitTime <- (cycle*step- cycleCarRequested*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- true;
					mode <- 5;
				}
				match "end"{
					if tripdistance = 0 {
						tripdistance <- packagetarget.start_point distance_to packagetarget.target_point;
					}
				
					if cycle != 0 {
						ask packagetarget.tripLogger {
							do logTrip(
								myself.served,
								myself.mode,
								myself.waitTime,
								myself.departureTime,
								current_date,
								(cycle*step - myself.departureCycle*step)/60,
								packagetarget.start_point.location,
								packagetarget.target_point.location,
								myself.tripdistance
							);
						}
					}
				}
			}
		}
	}
	
	action logExitState(string logmessage) {
		
		if timeStartActivity= nil {timeStartstr <- nil;}else{timeStartstr <- string(timeStartActivity,"HH:mm:ss");}
		if current_date = nil {currentstr <- nil;} else {currentstr <- string(current_date,"HH:mm:ss");}
		
		do log(['END: ' + currentState, mode, logmessage, timeStartstr, currentstr, (cycle*step - cycleStartActivity*step)/60, locationStartActivity distance_to packagetarget.location]);
	}
	action logEvent(string event) {
		do log([event]);
	}
}

species autonomousBikeLogger_chargeEvents parent: Logger mirrors: autonomousBike { //Station Charging
	string filename <- 'AutonomousBike_station_charge'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Station",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Start Battery %",
		"End Battery %",
		"Battery Gain %"
	];
	bool logPredicate { return stationChargeLogs; }
	autonomousBike autonomousBiketarget;
	string startstr;
	string endstr;
	
	init {
		autonomousBiketarget <- autonomousBike(target);
		autonomousBiketarget.chargeLogger <- self;
		loggingAgent <- autonomousBiketarget;
	}
	
	action logCharge(chargingStation station, date startTime, date endTime, float chargeDuration, float startBattery, float endBattery, float batteryGain) {
				
		if startTime= nil {startstr <- nil;}else{startstr <- string(startTime,"HH:mm:ss");}
		if endTime = nil {endstr <- nil;} else {endstr <- string(endTime,"HH:mm:ss");}
		
		do log([station, startstr, endstr, chargeDuration, startBattery, endBattery, batteryGain]);
	}
}

species autonomousBikeLogger_roadsTraveled parent: Logger mirrors: autonomousBike {
	
	string filename <- 'AutonomousBike_roadstraveled'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Distance Traveled",
		"Num Intersections"
	];
	bool logPredicate { return roadsTraveledLog; }
	autonomousBike autonomousBiketarget;
	
	float totalDistance <- 0.0;
	
	init {
		autonomousBiketarget <- autonomousBike(target);
		autonomousBiketarget.travelLogger <- self;
		loggingAgent <- autonomousBiketarget;
	}
	
	action logRoads(float distanceTraveled) {
		
		totalDistance <- distanceTraveled;
		
		do log( [distanceTraveled]);
	}
}

species docklessBikeLogger_roadsTraveled parent: Logger mirrors: docklessBike {
	
	string filename <- 'docklessBike_roadstraveled'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Distance Traveled",
		"Num Intersections"
	];
	bool logPredicate { return roadsTraveledLog; }
	docklessBike docklessBiketarget;
	
	float totalDistance <- 0.0;
	
	init {
		docklessBiketarget <- docklessBike(target);
		docklessBiketarget.travelLogger <- self;
		loggingAgent <- docklessBiketarget;
	}
	
	action logRoads(float distanceTraveled) {
		totalDistance <- distanceTraveled;
		do log( [distanceTraveled]);
	}
}

species scooterLogger_roadsTraveled parent: Logger mirrors: scooter {
	
	string filename <- 'scooter_roadstraveled'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Distance Traveled",
		"Num Intersections"
	];
	bool logPredicate { return roadsTraveledLog; }
	scooter scootertarget;
	
	float totalDistance <- 0.0;
	
	init {
		scootertarget <- scooter(target);
		scootertarget.travelLogger <- self;
		loggingAgent <- scootertarget;
	}
	
	action logRoads(float distanceTraveled) {
		totalDistance <-  distanceTraveled;
		do log( [distanceTraveled]);
	}
}

species eBikeLogger_roadsTraveled parent: Logger mirrors: eBike {
	
	string filename <- 'eBike_roadstraveled'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Distance Traveled",
		"Num Intersections"
	];
	bool logPredicate { return roadsTraveledLog; }
	eBike eBiketarget;
	
	float totalDistance <- 0.0;
	
	init {
		eBiketarget <- eBike(target);
		eBiketarget.travelLogger <- self;
		loggingAgent <- eBiketarget;
	}
	
	action logRoads(float distanceTraveled) {
		totalDistance <- distanceTraveled;		
		do log( [distanceTraveled]);
	}
}

species conventionalBikesLogger_roadsTraveled parent: Logger mirrors: conventionalBike {
	
	string filename <- 'ConventionalBike_roadstraveled'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Distance Traveled",
		"Num Intersections"
	];
	bool logPredicate { return roadsTraveledLog; }
	conventionalBike conventionalbiketarget;
	
	float totalDistance <- 0.0;
	
	init {
		conventionalbiketarget <- conventionalBike(target);
		conventionalbiketarget.travelLogger <- self;
		loggingAgent <- conventionalbiketarget;
	}
	
	action logRoads(float distanceTraveled) {
		totalDistance <- distanceTraveled;
		do log( [distanceTraveled]);
	}
}

species carLogger_roadsTraveled parent: Logger mirrors: car {
	
	string filename <- 'car_roadstraveled'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Distance Traveled",
		"Num Intersections"
	];
	bool logPredicate { return roadsTraveledLog; }
	car cartarget;
	
	float totalDistance <- 0.0;
	
	init {
		cartarget <- car(target);
		cartarget.travelLogger <- self;
		loggingAgent <- cartarget;
	}
	
	action logRoads(float distanceTraveled) {
		totalDistance <- distanceTraveled;
		do log( [distanceTraveled]);
	}
}

species autonomousBikeLogger_event parent: Logger mirrors: autonomousBike {
	
	bool logPredicate { return autonomousBikeEventLog; }
	string filename <- 'autonomousBike_trip_event'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
		"Activity",
		"Message",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Distance Traveled",
		"Start Battery %",
		"End Battery %",
		"Battery Gain %"
	];
	
	autonomousBike autonomousBiketarget;
	init {
		autonomousBiketarget <- autonomousBike(target);
		autonomousBiketarget.eventLogger <- self;
		loggingAgent <- autonomousBiketarget;
	}
	
	chargingStation stationCharging; //Station where being charged [id]
	float chargingStartTime; //Charge start time [s]
	float batteryLifeBeginningCharge; //Battery when beginning charge [%]
	
	int cycleStartActivity;
	date timeStartActivity;
	point locationStartActivity;
	float batteryStartActivity;
	string currentState;
	int activity;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		batteryStartActivity <- autonomousBiketarget.batteryLife;
		locationStartActivity <- autonomousBiketarget.location;
		
		currentState <- autonomousBiketarget.state;
		
		activity <- autonomousBiketarget.activity;
		do log( ['START: ' + autonomousBiketarget.state] + [activity] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- autonomousBiketarget.travelLogger.totalDistance;
		string timeStartstr;
		string currentstr;
		
		if timeStartActivity= nil {timeStartstr <- nil;}else{timeStartstr <- string(timeStartActivity,"HH:mm:ss");}
		if current_date = nil {currentstr <- nil;} else {currentstr <- string(current_date,"HH:mm:ss");}
			
		do log( [
			'END: ' + currentState,
			activity,
			logmessage,
			timeStartstr,
			currentstr,
			(cycle*step - cycleStartActivity*step)/(60),
			d,
			batteryStartActivity/maxBatteryLifeAutonomousBike*100,
			autonomousBiketarget.batteryLife/maxBatteryLifeAutonomousBike*100,
			(autonomousBiketarget.batteryLife-batteryStartActivity)/maxBatteryLifeAutonomousBike*100
		]);
				
		if currentState = "getting_charge" {
			//just finished a charge
			ask autonomousBiketarget.chargeLogger {
				do logCharge(
					chargingStation closest_to autonomousBiketarget,
					myself.timeStartActivity,
					current_date,
					(cycle*step - myself.cycleStartActivity*step)/(60),
					myself.batteryStartActivity/maxBatteryLifeAutonomousBike*100,
					autonomousBiketarget.batteryLife/maxBatteryLifeAutonomousBike*100,
					(autonomousBiketarget.batteryLife-myself.batteryStartActivity)/maxBatteryLifeAutonomousBike*100
				);
			}
		}
	}
}

species docklessBikeLogger_event parent: Logger mirrors: docklessBike {
	
	string filename <- 'docklessBike_trip_event'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
		"Activity",
		"Message",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Distance Traveled",
		"Start Battery %",
		"End Battery %",
		"Battery Gain %"
	];
	
	bool logPredicate { return docklessBikeEventLog; }
	docklessBike docklessBiketarget;
	init {
		docklessBiketarget <- docklessBike(target);
		docklessBiketarget.eventLogger <- self;
		loggingAgent <- docklessBiketarget;
	}
	
	int cycleStartActivity;
	date timeStartActivity;
	point locationStartActivity;
	string currentState;
	int activity <- 1;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		locationStartActivity <- docklessBiketarget.location;
		
		currentState <- docklessBiketarget.state;
		do log( ['START: ' + docklessBiketarget.state] + [activity] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- docklessBiketarget.travelLogger.totalDistance;
		string timeStartstr;
		string currentstr;
		
		if timeStartActivity= nil {timeStartstr <- nil;}else{timeStartstr <- string(timeStartActivity,"HH:mm:ss");}
		if current_date = nil {currentstr <- nil;} else {currentstr <- string(current_date,"HH:mm:ss");}
				
		do log( [
			'END: ' + currentState,
			activity,
			logmessage,
			timeStartstr,
			currentstr,
			(cycle*step - cycleStartActivity*step)/(60),
			d,
			nil,
			nil,
			nil
		]);
	}
}

species scooterLogger_event parent: Logger mirrors: scooter {
	
	string filename <- 'scooter_trip_event'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
		"Activity",
		"Message",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Distance Traveled",
		"Start Battery %",
		"End Battery %",
		"Battery Gain %"
	];
	
	bool logPredicate { return scooterEventLog; }
	scooter scootertarget;
	init {
		scootertarget <- scooter(target);
		scootertarget.eventLogger <- self;
		loggingAgent <- scootertarget;
	}
		
	int cycleStartActivity;
	date timeStartActivity;
	point locationStartActivity;
	float batteryStartActivity;
	float distanceStartActivity;
	string currentState;
	int activity <- 0; // Activity: 0 -> Packages || Activity: 1 -> People
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		batteryStartActivity <- scootertarget.batteryLife;
		locationStartActivity <- scootertarget.location;
		
		currentState <- scootertarget.state;
		do log( ['START: ' + scootertarget.state] + [activity] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- scootertarget.travelLogger.totalDistance;
		string timeStartstr;
		string currentstr;
		
		if timeStartActivity= nil {timeStartstr <- nil;}else{timeStartstr <- string(timeStartActivity,"HH:mm:ss");}
		if current_date = nil {currentstr <- nil;} else {currentstr <- string(current_date,"HH:mm:ss");}
				
		do log( [
			'END: ' + currentState,
			activity,
			logmessage,
			timeStartstr,
			currentstr,
			(cycle*step - cycleStartActivity*step)/(60),
			d,
			batteryStartActivity/maxBatteryLifeScooter*100,
			scootertarget.batteryLife/maxBatteryLifeScooter*100,
			nil
		]);
	}
}

species eBikeLogger_event parent: Logger mirrors: eBike {
	
	string filename <- 'eBike_trip_event'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
		"Activity",
		"Message",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Distance Traveled",
		"Start Battery %",
		"End Battery %",
		"Battery Gain %"
	];
	
	bool logPredicate { return eBikeEventLog; }
	eBike eBiketarget;
	init {
		eBiketarget <- eBike(target);
		eBiketarget.eventLogger <- self;
		loggingAgent <- eBiketarget;
	}
		
	int cycleStartActivity;
	date timeStartActivity;
	point locationStartActivity;
	float batteryStartActivity;
	string currentState;
	int activity <- 0;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		batteryStartActivity <- eBiketarget.batteryLife;
		locationStartActivity <- eBiketarget.location;
			
		currentState <- eBiketarget.state;
		do log( ['START: ' + eBiketarget.state] + [activity] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- eBiketarget.travelLogger.totalDistance;
		string timeStartstr;
		string currentstr;
		
		if timeStartActivity= nil {timeStartstr <- nil;}else{timeStartstr <- string(timeStartActivity,"HH:mm:ss");}
		if current_date = nil {currentstr <- nil;} else {currentstr <- string(current_date,"HH:mm:ss");}
				
		do log( [
			'END: ' + currentState,
			activity,
			logmessage,
			timeStartstr,
			currentstr,
			(cycle*step - cycleStartActivity*step)/(60),
			d,
			batteryStartActivity/maxBatteryLifeEBike*100,
			eBiketarget.batteryLife/maxBatteryLifeEBike*100,
			nil
		]);
	}
}

species conventionalBikesLogger_event parent: Logger mirrors: conventionalBike {
	
	string filename <- 'conventionalBike_trip_event'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
		"Activity",
		"Message",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Distance Traveled",
		"Start Battery %",
		"End Battery %",
		"Battery Gain %"
	];
	
	bool logPredicate { return conventionalBikesEventLog; }
	conventionalBike conventionalbiketarget;
	init {
		conventionalbiketarget <- conventionalBike(target);
		conventionalbiketarget.eventLogger <- self;
		loggingAgent <- conventionalbiketarget;
	}
	
	int cycleStartActivity;
	date timeStartActivity;
	point locationStartActivity;
	string currentState;
	int activity <- 0;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		locationStartActivity <- conventionalbiketarget.location;
		
		currentState <- conventionalbiketarget.state;
		do log( ['START: ' + conventionalbiketarget.state] + [activity] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- conventionalbiketarget.travelLogger.totalDistance;
		string timeStartstr;
		string currentstr;
		
		if timeStartActivity= nil {timeStartstr <- nil;}else{timeStartstr <- string(timeStartActivity,"HH:mm:ss");}
		if current_date = nil {currentstr <- nil;} else {currentstr <- string(current_date,"HH:mm:ss");}
				
		do log( [
			'END: ' + currentState,
			activity,
			logmessage,
			timeStartstr,
			currentstr,
			(cycle*step - cycleStartActivity*step)/(60),
			d,
			nil,
			nil,
			nil
		]);
	}
}

species carLogger_event parent: Logger mirrors: car {
	
	string filename <- 'car_trip_event'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
		"Activity",
		"Message",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Distance Traveled",
		"Start Battery %",
		"End Battery %",
		"Battery Gain %"
	];
	
	bool logPredicate { return carEventLog; }
	car cartarget;
	init {
		cartarget <- car(target);
		cartarget.eventLogger <- self;
		loggingAgent <- cartarget;
	}
		
	int cycleStartActivity;
	date timeStartActivity;
	point locationStartActivity;
	float batteryStartActivity;
	string currentState;
	int activity <- 0;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		batteryStartActivity <- cartarget.batteryLife;
		locationStartActivity <- cartarget.location;
		
		currentState <- cartarget.state;
		do log( ['START: ' + cartarget.state] + [activity] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- cartarget.travelLogger.totalDistance;
		string timeStartstr;
		string currentstr;
		
		if timeStartActivity= nil {timeStartstr <- nil;}else{timeStartstr <- string(timeStartActivity,"HH:mm:ss");}
		if current_date = nil {currentstr <- nil;} else {currentstr <- string(current_date,"HH:mm:ss");}
				
		do log( [
			'END: ' + currentState,
			activity,
			logmessage,
			timeStartstr,
			currentstr,
			(cycle*step - cycleStartActivity*step)/(60),
			d,
			batteryStartActivity/maxBatteryLifeCar*100,
			cartarget.batteryLife/maxBatteryLifeCar*100,
			nil
		]);
	}
}
