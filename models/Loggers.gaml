model Loggers
import "./main.gaml"



global {
	map<string, string> filenames <- []; //Maps log types to filenames
	
	action registerLogFile(string filename) {
		filenames[filename] <- './../data/' + string(logDate, 'yyyy-MM-dd hh.mm.ss','en') + '/' + filename + '.csv';
		
	}
	
	action log(string filename, list data, list<string> columns) {
		if not(filename in filenames.keys) {
			do registerLogFile(filename);
			save ["Cycle", "Time", "Traditional Scenario", "Num Autonomous Bikes", "Num Scooters", "Num EBikes", "Num Conventional Bikes", "Num Dockless Bikes", "Agent"] + columns to: filenames[filename] type: "csv" rewrite: false header: false;
			// Parámetro a variar (que luego se quiera ver en los batch)
		}
		
		//if level <= loggingLevel {
		if loggingEnabled {
			save [cycle, string(current_date, "HH:mm:ss"), traditionalScenario, numAutonomousBikes, numScooters, numEBikes, numConventionalBikes, numDocklessBikes] + data to: filenames[filename] type: "csv" rewrite: false header: false;
		}
		if  printsEnabled {
			write [cycle, string(current_date,"HH:mm:ss"), traditionalScenario] + data;
		} 
	}
	
	action logForSetUp (list<string> parameters) {
		loop param over: parameters {
			save (param) to: './../data/' + string(logDate, 'yyyy-MM-dd hh.mm.ss','en') + '/' + 'setUp' + '.txt' type: "text" rewrite: false header: false;}
	}
	
	//Los parámetros que no se varían pero se quieren guardar para acordarse de su inicialización
	action logSetUp { 
		list<string> parameters <- [
		"NAutonomousBikes: "+string(numAutonomousBikes),
		"NDocklessBikes: "+string(numDocklessBikes),
		"NScooters: "+string(numScooters),
		"NEBikes: "+string(numEBikes),
		"NConventionalBikes: "+string(numConventionalBikes),
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
				match "delivering_autonomousBike" {
					//trip is served
					waitTime <- (cycle*step- cycleAutonomousBikeRequested*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- true;
				}
				match "delivering_scooter" {
					//trip is served
					waitTime <- (cycle*step- cycleScooterRequested*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- true;
				}
				match "delivering_eBike" {
					//trip is served
					waitTime <- (cycle*step- cycleEBikeRequested*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- true;
				}
				match "delivering_conventionalBike" {
					//trip is served
					waitTime <- (cycle*step- cycleConventionalBikeRequested*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- true;
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
	int totalIntersections <- 0;
	
	init {
		autonomousBiketarget <- autonomousBike(target);
		autonomousBiketarget.travelLogger <- self;
		loggingAgent <- autonomousBiketarget;
	}
	
	action logRoads(float distanceTraveled, int numIntersections) {
		
		totalDistance <- totalDistance + distanceTraveled;
		totalIntersections <- totalIntersections + numIntersections;
		
		do log( [distanceTraveled, numIntersections]);
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
	int totalIntersections <- 0;
	
	init {
		docklessBiketarget <- docklessBike(target);
		docklessBiketarget.travelLogger <- self;
		loggingAgent <- docklessBiketarget;
	}
	
	action logRoads(float distanceTraveled, int numIntersections) {
		totalDistance <- totalDistance + distanceTraveled;
		totalIntersections <- totalIntersections + numIntersections;
		
		do log( [distanceTraveled, numIntersections]);
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
	int totalIntersections <- 0;
	
	init {
		scootertarget <- scooter(target);
		scootertarget.travelLogger <- self;
		loggingAgent <- scootertarget;
	}
	
	action logRoads(float distanceTraveled, int numIntersections) {
		totalDistance <- totalDistance + distanceTraveled;
		totalIntersections <- totalIntersections + numIntersections;
		
		do log( [distanceTraveled, numIntersections]);
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
	int totalIntersections <- 0;
	
	init {
		eBiketarget <- eBike(target);
		eBiketarget.travelLogger <- self;
		loggingAgent <- eBiketarget;
	}
	
	action logRoads(float distanceTraveled, int numIntersections) {
		totalDistance <- totalDistance + distanceTraveled;
		totalIntersections <- totalIntersections + numIntersections;
		
		do log( [distanceTraveled, numIntersections]);
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
	int totalIntersections <- 0;
	
	init {
		conventionalbiketarget <- conventionalBike(target);
		conventionalbiketarget.travelLogger <- self;
		loggingAgent <- conventionalbiketarget;
	}
	
	action logRoads(float distanceTraveled, int numIntersections) {
		totalDistance <- totalDistance + distanceTraveled;
		totalIntersections <- totalIntersections + numIntersections;
		
		do log( [distanceTraveled, numIntersections]);
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
	float distanceStartActivity;
	float batteryStartActivity;
	string currentState;
	int activity;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		batteryStartActivity <- autonomousBiketarget.batteryLife;
		locationStartActivity <- autonomousBiketarget.location;
		
		distanceStartActivity <- autonomousBiketarget.travelLogger.totalDistance;
		
		currentState <- autonomousBiketarget.state;
		
		activity <- autonomousBiketarget.activity;
		do log( ['START: ' + autonomousBiketarget.state] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- autonomousBiketarget.travelLogger.totalDistance - distanceStartActivity;
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
	float distanceStartActivity;
	string currentState;
	int activity <- 1;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		locationStartActivity <- docklessBiketarget.location;
		
		distanceStartActivity <- docklessBiketarget.travelLogger.totalDistance;
		
		currentState <- docklessBiketarget.state;
		do log( ['START: ' + docklessBiketarget.state] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- docklessBiketarget.travelLogger.totalDistance - distanceStartActivity;
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
	float distanceStartActivity;
	string currentState;
	int activity <- 0;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		locationStartActivity <- scootertarget.location;
		
		distanceStartActivity <- scootertarget.travelLogger.totalDistance;
		
		currentState <- scootertarget.state;
		do log( ['START: ' + scootertarget.state] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- scootertarget.travelLogger.totalDistance - distanceStartActivity;
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
	
	bool logPredicate { return scooterEventLog; }
	eBike eBiketarget;
	init {
		eBiketarget <- eBike(target);
		eBiketarget.eventLogger <- self;
		loggingAgent <- eBiketarget;
	}
		
	int cycleStartActivity;
	date timeStartActivity;
	point locationStartActivity;
	float distanceStartActivity;
	string currentState;
	int activity <- 0;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		locationStartActivity <- eBiketarget.location;
		
		distanceStartActivity <- eBiketarget.travelLogger.totalDistance;
		
		currentState <- eBiketarget.state;
		do log( ['START: ' + eBiketarget.state] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- eBiketarget.travelLogger.totalDistance - distanceStartActivity;
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
	float distanceStartActivity;
	string currentState;
	int activity <- 0;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		locationStartActivity <- conventionalbiketarget.location;
		
		distanceStartActivity <- conventionalbiketarget.travelLogger.totalDistance;
		
		currentState <- conventionalbiketarget.state;
		do log( ['START: ' + conventionalbiketarget.state] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- conventionalbiketarget.travelLogger.totalDistance - distanceStartActivity;
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
