model Loggers
import "./main.gaml"



global {
	map<string, string> filenames <- []; //Maps log types to filenames
	
	action registerLogFile(string filename) {
		filenames[filename] <- './../data/' + string(logDate, 'yyyy-MM-dd hh.mm.ss','en') + '/' + filename + '.csv';
		
	}
	
	//action log(string filename, int level, list data, list<string> columns) {
	action log(string filename, list data, list<string> columns) {
		if not(filename in filenames.keys) {
			do registerLogFile(filename);
			save ["Cycle", "Time","Num Bikes","Agent"] + columns to: filenames[filename] type: "csv" rewrite: false header: false;
			save ["Cycle", "Time","Num Scooters","Agent"] + columns to: filenames[filename] type: "csv" rewrite: false header: false;
		}
		
		//if level <= loggingLevel {
		if loggingEnabled {
			save [cycle, string(current_date, "HH:mm:ss"),numBikes] + data to: filenames[filename] type: "csv" rewrite: false header: false;
			save [cycle, string(current_date, "HH:mm:ss"),numScooters] + data to: filenames[filename] type: "csv" rewrite: false header: false;
		}
		if  printsEnabled {
			write [cycle, string(current_date,"HH:mm:ss")] + data;
		} 
	}
	
	action logForSetUp (list<string> parameters) {
		loop param over: parameters {
			save (param) to: './../data/' + string(logDate, 'yyyy-MM-dd hh.mm.ss','en') + '/' + 'setUp' + '.txt' type: "text" rewrite: false header: false;}
	}
	
	action logSetUp { 
		list<string> parameters <- [
		"Nbikes: "+string(numBikes),
		"Nscooters: "+string(numScooters),
		"MaxWait: "+string(maxWaitTime/60),

		"------------------------------SIMULATION PARAMETERS------------------------------",
		"Step: "+string(step),
		"Starting Date: "+string(starting_date),
		"Number of Days of Simulation: "+string(numberOfDays),
		"Number ot Hours of Simulation (if less than one day): "+string(numberOfHours),

		"------------------------------BIKE PARAMETERS------------------------------",
		"Number of Bikes: "+string(numBikes),
		"Max Battery Life of Bikes [km]: "+string(maxBatteryLife/1000 with_precision 2),
		"Pick-up speed [km/h]: "+string(PickUpSpeed*3.6),
		"Minimum Battery [%]: "+string(minSafeBattery/maxBatteryLife*100),
		
		"------------------------------SCOOTER PARAMETERS------------------------------",
		"Number of Scooters: "+string(numScooters),
		"Max Battery Life of Scooters [km]: "+string(maxBatteryLifeS/1000 with_precision 2),
		"Pick-up speed Scooters [km/h]: "+string(PickUpSpeedS*3.6),
		"Minimum Battery Scooters [%]: "+string(minSafeBatteryS/maxBatteryLifeS*100),
		
		"------------------------------PEOPLE PARAMETERS------------------------------",
		"Maximum Wait Time [min]: "+string(maxWaitTime/60),
		"Walking Speed [km/h]: "+string(peopleSpeed*3.6),
		"Riding speed [km/h]: "+string(RidingSpeed*3.6),

		
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
		"Bike Event/Trip Log: " +string(bikeEventLog),
		"Scooter Event/Trip Log: " + string(scooterEventLog),
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

species Logger {
	
	action logPredicate virtual: true type: bool;
	string filename;
	list<string> columns;
	
	agent loggingAgent;
	
	//action log(int level, list data) {
	action log(list data) {
		if logPredicate() {
			ask host {
				do log(myself.filename, [string(myself.loggingAgent.name)] + data, myself.columns);
			} 
		}
	}
}

species peopleLogger_trip parent: Logger mirrors: people {
	string filename <- string("people_trips_"+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second));
	list<string> columns <- [
		"Trip Served",
		//"Trip Type",
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
	
	action logTrip( bool served, float waitTime, date departure, date arrival, float tripduration, point origin, point destination, float distance) {
		//numBikes, WanderingSpeed, maxWaitTime, evaporation, exploitationRate, chargingPheromoneThreshold, pLowPheromoneCharge, readUpdateRate
		point origin_WGS84 <- CRS_transform(origin, "EPSG:4326").location; //project the point to WGS84 CRS
		point destination_WGS84 <- CRS_transform(destination, "EPSG:4326").location; //project the point to WGS84 CRS
		string dep;
		string des;
		
		if departure= nil {dep <- nil;}else{dep <- string(departure,"HH:mm:ss");}
		
		if arrival = nil {des <- nil;} else {des <- string(arrival,"HH:mm:ss");}
		
		do log([served, waitTime,dep ,des, tripduration, origin_WGS84.x, origin_WGS84.y, destination_WGS84.x, destination_WGS84.y, distance]);
	} 
}

species packageLogger_trip parent: Logger mirrors: package {
	string filename <- string("package_trips_"+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second));
	list<string> columns <- [
		"Trip Served",
		//"Trip Type",
		"Wait Time (min)",
		"Departure Time",
		"Arrival Time",
		"Duration (min)",
		"Distance (m)"
	];

	bool logPredicate { return packageTripLog; }
	package packagetarget;
	
	init {
		packagetarget <- package(target);
		loggingAgent <- packagetarget;
	}
	
	action logTrip( bool served, float waitTime, date departure, date arrival, float tripduration, point origin, point destination, float distance) {
		//numBikes, WanderingSpeed, maxWaitTime, evaporation, exploitationRate, chargingPheromoneThreshold, pLowPheromoneCharge, readUpdateRate
		point origin_WGS84 <- CRS_transform(origin, "EPSG:4326").location; //project the point to WGS84 CRS
		point destination_WGS84 <- CRS_transform(destination, "EPSG:4326").location; //project the point to WGS84 CRS
		string dep;
		string des;
		
		if departure= nil {dep <- nil;}else{dep <- string(departure,"HH:mm:ss");}
		
		if arrival = nil {des <- nil;} else {des <- string(arrival,"HH:mm:ss");}
		
		do log([served, waitTime,dep ,des, tripduration, origin_WGS84.x, origin_WGS84.y, destination_WGS84.x, destination_WGS84.y, distance]);
	} 
}

species peopleLogger parent: Logger mirrors: people {
	string filename <- "people_event"+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
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
    int cycleBikeRequested;
    float waitTime;
    int cycleStartActivity;
    date timeStartActivity;
    point locationStartActivity;
    string currentState;
    bool served;
    
    string timeStartstr;
    string currentstr;
	
	//faction logEnterState { do logEnterState(""); }
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		locationStartActivity <- persontarget.location;
		currentState <- persontarget.state;
		if peopleEventLog {do log(['START: ' + currentState] + [logmessage]);}
		
		if peopleTripLog{ //because trips are logged by the eventLogger
		switch currentState {
			match "requesting_bike" {
				//trip starts
				cycleBikeRequested <- cycle;
				served <- false;
			}
			match "riding" {
				//trip is served
				waitTime <- (cycle*step- cycleBikeRequested*step)/60;
				departureTime <- current_date;
				departureCycle <- cycle;
				served <- true;
			}
			match "wandering" {
				//trip has ended
				if tripdistance = 0 {
					//tripdistance <- topology(roadNetwork) distance_between [persontarget.start_point, persontarget.target_point];
					tripdistance <- persontarget.start_point distance_to persontarget.target_point;
				}
				
				if cycle != 0 {
					ask persontarget.tripLogger {
						do logTrip(
							myself.served,
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
		}}
		
	}

	action logExitState(string logmessage) {
		
		if timeStartActivity= nil {timeStartstr <- nil;}else{timeStartstr <- string(timeStartActivity,"HH:mm:ss");}
		if current_date = nil {currentstr <- nil;} else {currentstr <- string(current_date,"HH:mm:ss");}
		
		do log(['END: ' + currentState, logmessage, timeStartstr, currentstr, (cycle*step - cycleStartActivity*step)/60, locationStartActivity distance_to persontarget.location]);
	}
	action logEvent(string event) {
		do log([event]);
	}
}

species packageLogger parent: Logger mirrors: package {
	string filename <- "package_event"+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
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
    int cycleBikeRequested;
    float waitTime;
    int cycleStartActivity;
    date timeStartActivity;
    point locationStartActivity;
    string currentState;
    bool served;
    
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
				match "requesting_bike_p" {
					//trip starts
					cycleBikeRequested <- cycle;
					served <- false;
				}
				match "delivering" {
					//trip is served
					waitTime <- (cycle*step- cycleBikeRequested*step)/60;
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
		
		do log(['END: ' + currentState, logmessage, timeStartstr, currentstr, (cycle*step - cycleStartActivity*step)/60, locationStartActivity distance_to packagetarget.location]);
	}
	action logEvent(string event) {
		do log([event]);
	}
}

species bikeLogger_chargeEvents parent: Logger mirrors: bike { //Station Charging
	string filename <- 'bike_station_charge'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
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
	bike biketarget;
	string startstr;
	string endstr;
	
	init {
		biketarget <- bike(target);
		biketarget.chargeLogger <- self;
		loggingAgent <- biketarget;
	}
	
	action logCharge(chargingStation station, date startTime, date endTime, float chargeDuration, float startBattery, float endBattery, float batteryGain) {
				
		if startTime= nil {startstr <- nil;}else{startstr <- string(startTime,"HH:mm:ss");}
		if endTime = nil {endstr <- nil;} else {endstr <- string(endTime,"HH:mm:ss");}
		
		do log([station, startstr, endstr, chargeDuration, startBattery, endBattery, batteryGain]);
	}
}

species scooterLogger_chargeEvents parent: Logger mirrors: scooter { //Station Charging
	string filename <- 'scooter_station_charge'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
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
	scooter scootertarget;
	string startstr;
	string endstr;
	
	init {
		scootertarget <- scooter(target);
		scootertarget.chargeLogger <- self;
		loggingAgent <- scootertarget;
	}
	
	action logCharge(chargingStation station, date startTime, date endTime, float chargeDuration, float startBattery, float endBattery, float batteryGain) {
				
		if startTime= nil {startstr <- nil;}else{startstr <- string(startTime,"HH:mm:ss");}
		if endTime = nil {endstr <- nil;} else {endstr <- string(endTime,"HH:mm:ss");}
		
		do log([station, startstr, endstr, chargeDuration, startBattery, endBattery, batteryGain]);
	}
}

species bikeLogger_roadsTraveled parent: Logger mirrors: bike {
	
	string filename <- 'bike_roadstraveled'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Distance Traveled",
		"Num Intersections"
	];
	bool logPredicate { return roadsTraveledLog; }
	bike biketarget;
	
	float totalDistance <- 0.0;
	int totalIntersections <- 0;
	
	init {
		biketarget <- bike(target);
		biketarget.travelLogger <- self;
		loggingAgent <- biketarget;
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

species bikeLogger_event parent: Logger mirrors: bike {
	
	string filename <- 'bike_trip_event'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
		"Message",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Distance Traveled",
		"Start Battery %",
		"End Battery %",
		"Battery Gain %"
	];
	
	bool logPredicate { return bikeEventLog; }
	bike biketarget;
	init {
		biketarget <- bike(target);
		biketarget.eventLogger <- self;
		loggingAgent <- biketarget;
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
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		batteryStartActivity <- biketarget.batteryLife;
		locationStartActivity <- biketarget.location;
		
		distanceStartActivity <- biketarget.travelLogger.totalDistance;
		
		currentState <- biketarget.state;
		do log( ['START: ' + biketarget.state] + [logmessage]);
	}
	//action logExitState { do logExitState(""); }
	action logExitState(string logmessage) {
		float d <- biketarget.travelLogger.totalDistance - distanceStartActivity;
		string timeStartstr;
		string currentstr;
		
		if timeStartActivity= nil {timeStartstr <- nil;}else{timeStartstr <- string(timeStartActivity,"HH:mm:ss");}
		if current_date = nil {currentstr <- nil;} else {currentstr <- string(current_date,"HH:mm:ss");}
				
		do log( [
			'END: ' + currentState,
			logmessage,
			timeStartstr,
			currentstr,
			(cycle*step - cycleStartActivity*step)/(60),
			d,
			batteryStartActivity/maxBatteryLife*100,
			biketarget.batteryLife/maxBatteryLife*100,
			(biketarget.batteryLife-batteryStartActivity)/maxBatteryLife*100
		]);
				
		if currentState = "getting_charge" {
			//just finished a charge
			ask biketarget.chargeLogger {
				do logCharge(
					chargingStation closest_to biketarget,
					myself.timeStartActivity,
					current_date,
					(cycle*step - myself.cycleStartActivity*step)/(60),
					myself.batteryStartActivity/maxBatteryLife*100,
					biketarget.batteryLife/maxBatteryLife*100,
					(biketarget.batteryLife-myself.batteryStartActivity)/maxBatteryLife*100
				);
			}
		}
	}
}

species scooterLogger_event parent: Logger mirrors: scooter {
	
	string filename <- 'scooter_trip_event'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
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
	
	chargingStation stationCharging; //Station where being charged [id]
	float chargingStartTime; //Charge start time [s]
	float batteryLifeBeginningCharge; //Battery when beginning charge [%]
	
	int cycleStartActivity;
	date timeStartActivity;
	point locationStartActivity;
	float distanceStartActivity;
	float batteryStartActivity;
	string currentState;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		batteryStartActivity <- scootertarget.batteryLife;
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
			logmessage,
			timeStartstr,
			currentstr,
			(cycle*step - cycleStartActivity*step)/(60),
			d,
			batteryStartActivity/maxBatteryLife*100,
			scootertarget.batteryLife/maxBatteryLife*100,
			(scootertarget.batteryLife-batteryStartActivity)/maxBatteryLife*100
		]);
				
		if currentState = "getting_charge" {
			//just finished a charge
			ask scootertarget.chargeLogger {
				do logCharge(
					chargingStation closest_to scootertarget,
					myself.timeStartActivity,
					current_date,
					(cycle*step - myself.cycleStartActivity*step)/(60),
					myself.batteryStartActivity/maxBatteryLife*100,
					scootertarget.batteryLife/maxBatteryLife*100,
					(scootertarget.batteryLife-myself.batteryStartActivity)/maxBatteryLife*100
				);
			}
		}
	}
}
