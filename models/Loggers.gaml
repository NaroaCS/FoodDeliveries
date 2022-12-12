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
			save ["Cycle", "Time", "Traditional Scenario", "Num Autonomous Bikes","Autonomous Bikes Battery Life","AB PickUp Speed","Num Cars","Agent"] + columns to: filenames[filename] type: "csv" rewrite: false header: false;
		}		
		if loggingEnabled {
			save [cycle, string(current_date, "HH:mm:ss"), traditionalScenario, numAutonomousBikes, maxBatteryLifeAutonomousBike, PickUpSpeedAutonomousBike, numCars] + data to: filenames[filename] type: "csv" rewrite: false header: false;
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
	
	action logSetUp { 
		list<string> parameters <- [
		"NAutonomousBikes: "+string(numAutonomousBikes),
		"NCars: "+string(numCars),
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
		
		"------------------------------CAR PARAMETERS------------------------------",
		"Number of Cars: "+string(numCars),
		"Max Battery Life of Cars [km]: "+string(maxFuelCar/1000 with_precision 2),
		"Minimum Battery Cars [%]: "+string(minSafeFuelCar/maxFuelCar*100),
		"Riding speed Cars [km/h]: " + string(RidingSpeedCar*3.6),
		
		"------------------------------PACKAGE PARAMETERS------------------------------",
		"Maximum Wait Time Package [min]: "+string(maxWaitTimePackage/60),
		
		"------------------------------STATION PARAMETERS------------------------------",
		"Number of Charging Stations: "+string(numChargingStations),
		"V2I Charging Rate: "+string(V2IChargingRate  with_precision 2),
		
		"---------------------------GAS STATION PARAMETERS------------------------------",
		"Number of Gas Stations: "+string(numGasStations),
		"Refilling Rate: "+string(refillingRate  with_precision 2),
		"Gas Station Capacity: "+string(gasStationCapacity),

		"------------------------------MAP PARAMETERS------------------------------",
		"City Map Name: "+string(cityScopeCity),
		"Redisence: "+string(residence),
		"Office: "+string(office),
		"Usage: "+string(usage),
		"Color Map: "+string(color_map),
		
		"------------------------------LOGGING PARAMETERS------------------------------",
		"Print Enabled: "+string(printsEnabled),
		"Autonomous Bike Event/Trip Log: " +string(autonomousBikeEventLog),
		"Car Event/Trip Log: " + string(carEventLog),
		"Package Trip Log: "+ string(packageTripLog),
		"Package Event Log:" + string(packageEventLog),
		"Station Charge Log: "+ string(stationChargeLogs),
		"Gas Station Charge Log: "+ string(gasstationFuelLogs),
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
	
	action log(list data) {
		if logPredicate() {
			ask host {
				do log(myself.filename, [string(myself.loggingAgent.name)] + data, myself.columns);
			} 
		}
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
		"Origin [lat]",
		"Origin [lon]",
		"Destination [lat]",
		"Destination [lon]",
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
	int cycleRequestingDeliveryMode;
    float waitTime;
    int cycleStartActivity;
    date timeStartActivity;
    point locationStartActivity;
    string currentState;
    bool served <- false;
    int mode;
    
    string timeStartstr;
    string currentstr;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		locationStartActivity <- packagetarget.location;
		currentState <- packagetarget.state;
		if packageEventLog {do log(['START: ' + currentState] + [logmessage]);}
		
		if packageTripLog{ //because trips are logged by the eventLogger
			switch currentState {
				match "requestingDeliveryMode" {
					cycleRequestingDeliveryMode <- cycle;
					served <- false;
				}
				match "delivering_autonomousBike" {
					waitTime <- (cycle*step- cycleRequestingDeliveryMode*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- false;
					mode <- 1;
				}
				match "delivering_car" {
					//trip is served
					waitTime <- (cycle*step- cycleRequestingDeliveryMode*step)/60;
					departureTime <- current_date;
					departureCycle <- cycle;
					served <- false;
					mode <- 2;
				}
				match "delivered"{
				
					if cycle != 0 {
						served <- true;
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
								packagetarget.tripdistance
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
		"Distance Traveled"
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

species carLogger_fuelEvents parent: Logger mirrors: car { //Fuel refilling
	string filename <- 'Car_fuel_refilling'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Gas Station",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Start Fuel %",
		"End Fuel %",
		"Fuel Gain %"
	];
	bool logPredicate { return gasstationFuelLogs; }
	car cartarget;
	string startstr;
	string endstr;
	
	init {
		cartarget <- car(target);
		cartarget.fuelLogger <- self;
		loggingAgent <- cartarget;
	}
	
	action logRefill(gasstation station, date startTime, date endTime, float refillDuration, float startFuel, float endFuel, float fuelGain) {
				
		if startTime= nil {startstr <- nil;}else{startstr <- string(startTime,"HH:mm:ss");}
		if endTime = nil {endstr <- nil;} else {endstr <- string(endTime,"HH:mm:ss");}
		
		do log([station, startstr, endstr, refillDuration, startFuel, endFuel, fuelGain]);
	}
}

species carLogger_roadsTraveled parent: Logger mirrors: car {
	
	string filename <- 'car_roadstraveled'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Distance Traveled"
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
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		batteryStartActivity <- autonomousBiketarget.batteryLife;
		locationStartActivity <- autonomousBiketarget.location;
		
		currentState <- autonomousBiketarget.state;
		
		do log( ['START: ' + autonomousBiketarget.state] + [logmessage]);
	}
	action logExitState(string logmessage) {
		float d <- autonomousBiketarget.travelLogger.totalDistance;
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
			batteryStartActivity/maxBatteryLifeAutonomousBike*100,
			autonomousBiketarget.batteryLife/maxBatteryLifeAutonomousBike*100,
			(autonomousBiketarget.batteryLife-batteryStartActivity)/maxBatteryLifeAutonomousBike*100
		]);
				
		if currentState = "getting_charge" {
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

species carLogger_event parent: Logger mirrors: car {
	
	bool logPredicate { return carEventLog; }
	string filename <- 'car_trip_event'+string(nowDate.hour)+"_"+string(nowDate.minute)+"_"+string(nowDate.second);
	list<string> columns <- [
		"Event",
		"Message",
		"Start Time",
		"End Time",
		"Duration (min)",
		"Distance Traveled",
		"Start Fuel %",
		"End Fuel %",
		"Fuel Gain %"
	];
	
	car cartarget;
	init {
		cartarget <- car(target);
		cartarget.eventLogger <- self;
		loggingAgent <- cartarget;
	}
	
	gasstation gasstationRefilling; //Station where being refield [id]
	float refillingStartTime; //Refill start time [s]
	float fuelBeginningCharge; //Fuel when beginning charge [%]
		
	int cycleStartActivity;
	date timeStartActivity;
	point locationStartActivity;
	float fuelStartActivity;
	string currentState;
	
	action logEnterState(string logmessage) {
		cycleStartActivity <- cycle;
		timeStartActivity <- current_date;
		fuelStartActivity <- cartarget.fuel;
		locationStartActivity <- cartarget.location;
		
		currentState <- cartarget.state;
		do log( ['START: ' + cartarget.state] + [logmessage]);
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
			logmessage,
			timeStartstr,
			currentstr,
			(cycle*step - cycleStartActivity*step)/(60),
			d,
			fuelStartActivity/maxFuelCar*100,
			cartarget.fuel/maxFuelCar*100,
			(cartarget.fuel-fuelStartActivity)/maxFuelCar*100
		]);
		
		if currentState = "getting_fuel" {
			//just finished a charge
			ask cartarget.fuelLogger {
				do logRefill(
					gasstation closest_to cartarget,
					myself.timeStartActivity,
					current_date,
					(cycle*step - myself.cycleStartActivity*step)/(60),
					myself.fuelStartActivity/maxFuelCar*100,
					cartarget.fuel/maxFuelCar*100,
					(cartarget.fuel-myself.fuelStartActivity)/maxFuelCar*100
				);
			}
		}
	}
}
