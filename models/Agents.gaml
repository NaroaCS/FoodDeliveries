model Agents

import "./main.gaml"

global {

	float distanceInGraph (point origin, point destination) {
		
		return origin distance_to destination;	
	}
	
	list<bike> availableBikes(people person , package delivery) {
		return bike where (each.availableForRide());
	}
	
	list<scooter> availableScooters(package delivery) {
		return scooter where (each.availableForRideS());
	}
	
	list<conventionalBike> availableConventionalBikes(package delivery) {
		return conventionalBike where (each.availableForRideCB());
	}
	
	float scooter_distance_PUP <- 0.0;
	int scooter_trips_count_PUP <- 0;
	float scooter_distance_D <- 0.0;
	float scooter_distance_C <- 0.0;
	int scooter_trips_count_C <- 0;
	float scooter_total_emissions <-0.0;
	
	float conventionalBike_distance_PUP <- 0.0;
	int conventionalBike_trips_count_PUP <- 0;
	float conventionalBike_distance_D <- 0.0;
	float conventionalBike_total_emissions <- 0.0;
	
	
	bool requestBike(people person, package delivery, point destination) { //returns true if there is any bike available

		list<bike> available <- availableBikes(person, delivery);
		if empty(available) {
			return false;
		}
		if person != nil{
			bike b <- available closest_to(person);
		
			if !bikeClose(person,b){
				return false;
			}
			ask b {
				do pickUp(person);
			}
			ask person {
				do ride(b);
			}
		} else if delivery != nil{		
			
			bike b <- available closest_to(delivery);
			
			if !bikeCloseP(delivery,b){
				return false;
			}
		
			b.delivery <- delivery;
	
			ask delivery {
				do deliver_b(b);
			}
		} else {
			return false;
		}
		return true;
	}

	bool requestScooter(package delivery, point destination) { //returns true if there is any bike available

		list<scooter> available <- availableScooters(delivery);
		if empty(available) {
			return false;
		}
		if delivery != nil{
			scooter s <- available closest_to(delivery);
			
			if !scooterClose(delivery,s){
				return false;
			} else {
				s.delivery <- delivery;
			
				ask delivery {
					do deliver_s(s);
				}
			}		
		} else {
			return false;
		}
		return true;
	}
	
	bool requestConventionalBike(package delivery, point destination) {
		
		list<conventionalBike> available <- availableConventionalBikes(delivery);

		if empty(available) {
			return false;
		}
		if delivery != nil{
			
			conventionalBike cb <- available closest_to(delivery);
			
			if !conventionalBikeClose(delivery,cb){
				return false;
			} else {
				cb.delivery <- delivery;
			
				ask delivery {
					do deliver_cb(cb);
				}
			}		
		} else {
			return false;
		}
		return true;
	}
	
	bool bikeClose(people person, bike b){
		float d <- distanceInGraph(b.location,person.location);
		if d<maxDistance { 
			return true;
		}else{
			return false ;
		}
	}
	
	bool bikeCloseP(package delivery, bike b){
		float d <- distanceInGraph(b.location,delivery.location);
		if d<maxDistance { 
			return true;
		}else{
			return false ;
		}
	}
	
	bool scooterClose(package delivery, scooter s){
		float d <- distanceInGraph(s.location,delivery.location);
		if d<maxDistance { 
			return true;
		}else{
			return false ;
		}
	}
	
	bool conventionalBikeClose(package delivery, conventionalBike cb){
		float d <- distanceInGraph(cb.location,delivery.location);
		if d<maxDistance { 
			return true;
		}else{
			return false ;
		}
	}
}

species road {
	aspect base {
		draw shape color: rgb(125, 125, 125);
	}
}

species building {
    aspect type {
		draw shape color: color_map[type];
	}
	string type; 
}

species chargingStation {
	list<bike> bikesToCharge;
	list<scooter> scootersToCharge;
	float lat;
	float lon;
	
	point point_station;
	aspect base {
		draw circle(10) color:#blue;		
	}
	
	reflex chargeBikes {
		ask chargingStationCapacity first bikesToCharge {
			batteryLife <- batteryLife + step*V2IChargingRate;
		}
	}
	reflex chargeScooters {
		ask chargingStationCapacity first scootersToCharge {
			batteryLife <- batteryLife + step*V2IChargingRate;
		}
	}
}

species intersection {
	int id;	
}

species supermarket{
	
	rgb color <- #red;
	
	float lat;
	float lon;
	point sup;
	
	aspect base{
		draw circle(20) color:color border:#black;
	}
}

species package control: fsm skills: [moving] {

	rgb color;
	
    map<string, rgb> color_map <- [
    	
    	"firstmile":: #blue,
		"requesting_bike_p":: #white,
		"requesting_scooter":: #lightblue,
		"requesting_conventionalBike":: #brown,
		"awaiting_bike_p":: #white,
		"awaiting_scooter":: #lightblue,
		"awaiting_conventionalBike":: #brown,
		"delivering":: #yellow,
		"delivering_scooter"::#turquoise,
		"delivering_conventional_bike"::#gray,
		"end":: #magenta
	];
	
	packageLogger logger;
    packageLogger_trip tripLogger;
    
	date start_hour;
	
	point start_point;
	point target_point;
	int start_h;
	int start_min;
	
	bike bikeToDeliver;
	scooter scooterToDeliver;
	conventionalBike conventionalBikeToDeliver;
	
	point final_destination; //Final destination for the trip
    point target; //Interim destination; the point we are currently moving toward
    point closestIntersection;
    float waitTime;
    bool r_s <- false;
    bool r_cb <- false;
	
	aspect base {
    	color <- color_map[state];
    	draw square(20) color: color border: #black;
    }
    
	action deliver_b(bike b){
		bikeToDeliver <- b;
	}
	
	action deliver_s(scooter s){
		scooterToDeliver <- s;
	}
	
	action deliver_cb(conventionalBike cb){
		conventionalBikeToDeliver <- cb;
	}
	
	bool timeToTravel { return (current_date.hour = start_h and current_date.minute >= start_min) and !(self overlaps target_point); }
	
	state end initial: true {
    	
    	enter {
    		if packageEventLog or packageTripLog {ask logger { do logEnterState; }} // trips are logged by the eventlogger
    		target <- nil;
    	}
    	transition to: requesting_bike_p when: timeToTravel() {
    		final_destination <- target_point;
    	}
    	exit {
			if packageEventLog {ask logger { do logExitState; }}
		}
    }
	state requesting_bike_p{
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState; }}
			closestIntersection <- (intersection closest_to(self)).location; 
		}
		transition to: firstmile when: host.requestBike(nil, self, final_destination) {
			target <- closestIntersection;
		}
		transition to: requesting_scooter {
			if packageEventLog {ask logger { do logEvent( "Used another mode, wait too long" ); }}
			r_s <- true;
		}
		exit {
			if packageEventLog {ask logger{do logExitState("Requested Bike "+myself.bikeToDeliver);}}
		}
	}
	
	state requesting_scooter{
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState; }}
			closestIntersection <- (intersection closest_to(self)).location; 
		}
		transition to: firstmile when: host.requestScooter(self, final_destination) {
			target <- closestIntersection;
			r_cb <- false;
		}
		transition to: requesting_conventionalBike{
			if packageEventLog {ask logger { do logEvent( "Used another mode, wait too long" ); }}
			r_cb <- true;
		}
		exit {
			if packageEventLog {ask logger{do logExitState("Requested Scooter "+myself.scooterToDeliver);}}
		}
	}
	
	state requesting_conventionalBike {
		enter {
			if packageEventLog {ask logger { do logEnterState; }}
			closestIntersection <- (intersection closest_to(self)).location;
			//float e<-distanceInGraph(closestIntersection.location, self.location);
		}
		transition to: firstmile when: host.requestConventionalBike (self, final_destination) {
			target <- closestIntersection;
		}
		exit {
			if packageEventLog {ask logger{do logExitState("Requested Conventional Bike "+myself.conventionalBikeToDeliver);}}
		}
	}
	
	state firstmile {
		enter{
			if packageEventLog or packageTripLog {ask logger{ do logEnterState;}}
		}
		transition to: awaiting_scooter when: r_s and !r_cb and location=target{}
		transition to: awaiting_conventionalBike when: r_s and r_cb and location=target{}
		transition to: awaiting_bike_p when: !r_s and !r_cb and location=target{}
		exit {
			if packageEventLog {ask logger{do logExitState;}}
		}
		do goto target: target on: roadNetwork;
	}
	
	state awaiting_bike_p {
		//Sit at the intersection and wait for your bike
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "awaiting " + string(myself.bikeToDeliver) ); }}
			target <- nil;
		}
		transition to: delivering when: bikeToDeliver.state = "in_use_packages" {}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
		}
	}
	
	state awaiting_scooter {
		//Sit at the intersection and wait for your bike
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "awaiting " + string(myself.scooterToDeliver) ); }}
			target <- nil;
		}
		transition to: delivering_scooter when: scooterToDeliver.state = "in_use_packages" {}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
		}
	}
	
	state awaiting_conventionalBike {
		//Sit at the intersection and wait for your bike
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "awaiting " + string(myself.conventionalBikeToDeliver) ); }}
			target <- nil;
		}
		transition to: delivering_conventional_bike when: conventionalBikeToDeliver.state = "in_use_packages" {}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
		}
	}
	
	state delivering {
		//Follow the bike around (i.e., ride it) until it drops you off 
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "riding " + string(myself.bikeToDeliver) ); }}
		}
		transition to: end when: bikeToDeliver.state != "in_use_packages" {
			target <- final_destination;
		}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
			bikeToDeliver<- nil;
		}

		location <- bikeToDeliver.location; //Always be at the same place as the bike
	}
	
	state delivering_scooter {
		//Follow the bike around (i.e., ride it) until it drops you off 
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "riding " + string(myself.scooterToDeliver) ); }}
		}
		transition to: end when: scooterToDeliver.state != "in_use_packages" {
			target <- final_destination;
		}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
			scooterToDeliver<- nil;
		}

		location <- scooterToDeliver.location; //Always be at the same place as the bike
	}
	
	state delivering_conventional_bike {
		//Follow the bike around (i.e., ride it) until it drops you off 
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "riding " + string(myself.conventionalBikeToDeliver) ); }}
		}
		transition to: end when: conventionalBikeToDeliver.state != "in_use_packages" {
			target <- final_destination;
		}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
			conventionalBikeToDeliver<- nil;
		}

		location <- conventionalBikeToDeliver.location; //Always be at the same place as the bike
	}
	/*state lastmile {
		enter{
			if packageEventLog or packageTripLog {ask logger{ do logEnterState;}}
		}
		transition to:end when: location=target{}
		exit {
			if packageEventLog {ask logger{do logExitState;}}
		}
		do goto target: target on: roadNetwork;
	}*/
}

species people control: fsm skills: [moving] {

	rgb color;
	
    map<string, rgb> color_map <- [
		"idle"::#lavender,
		"requesting_bike":: #springgreen,
		"awaiting_bike":: #springgreen,
		"riding":: #gamagreen,
		"walking":: #magenta
	];
	
	//loggers
    peopleLogger logger;
    peopleLogger_trip tripLogger;
    
    package delivery;

	//raw
	date start_hour; //datetime
	float start_lat; 
	float start_lon;
	float target_lat;
	float target_lon;
	 
	//adapted
	point start_point;
	point target_point;
	int start_h; //just hour
	int start_min; //just minute
    
    bike bikeToRide;
    
    point final_destination; //Final destination for the trip
    point target; //Interim destination; the point we are currently moving toward
    point closestIntersection;
    float waitTime;
    
    aspect base {
    	color <- color_map[state];
    	draw circle(10) color: color border: #black;
    }
    
    //----------------PUBLIC FUNCTIONS-----------------
	// these are how other agents interact with this one. Not used by self
	
    action ride(bike b) {
    	bikeToRide <- b;
    }	

    bool timeToTravel { return (current_date.hour = start_h and current_date.minute >= start_min) and !(self overlaps target_point); }
    	//Should we leave for work/home? Only if it is time, and we are not already there
    
    state wandering initial: true {
    	//Watch netflix at home (and/or work)
    	enter {
    		if peopleEventLog or peopleTripLog {ask logger { do logEnterState; }} // trips are logged by the eventlogger
    		target <- nil;
    	}
    	transition to: requesting_bike when: timeToTravel() {
    		//write "cycle: " + cycle + ", current time "+ current_date.hour +':' + current_date.minute + 'agent' +string(self) + " time " + self.start_h + ":"+self.start_min;
    		final_destination <- target_point;
    	}
    	exit {
			if peopleEventLog {ask logger { do logExitState; }}
		}
    }
	state requesting_bike {
		//Ask the system for a bike, teleport (use another transportation mode) if wait is too long
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState; }}
			closestIntersection <- (intersection closest_to(self)).location; 
		}
		transition to: walking when: host.requestBike(self, nil, final_destination) {
			target <- closestIntersection;
		}
		transition to: wandering {
			if peopleEventLog {ask logger { do logEvent( "Used another mode, wait too long" ); }}
			location <- final_destination;
		}
		exit {
			if peopleEventLog {ask logger { do logExitState("Requested Bike " + myself.bikeToRide); }}
		}
	}
	state awaiting_bike {
		//Sit at the intersection and wait for your bike
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState( "awaiting " + string(myself.bikeToRide) ); }}
			target <- nil;
		}
		transition to: riding when: bikeToRide.state = "in_use" {}
		exit {
			if peopleEventLog {ask logger { do logExitState; }}
		}
	}
	state riding {
		//Follow the bike around (i.e., ride it) until it drops you off 
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState( "riding " + string(myself.bikeToRide) ); }}
		}
		transition to: walking when: bikeToRide.state != "in_use" {
			target <- final_destination;
		}
		exit {
			if peopleEventLog {ask logger { do logExitState; }}
			bikeToRide <- nil;
		}

		location <- bikeToRide.location; //Always be at the same place as the bike
	}
	state walking {
		//go to your destination or nearest intersection, then wait
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState; }}
		}
		transition to: wandering when: location = final_destination {}
		transition to: awaiting_bike when: location = target {}
		exit {
			if peopleEventLog {ask logger { do logExitState; }}
		}
		do goto target: target on: roadNetwork;
	}
}

species bike control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#purple,
		
		"low_battery":: #red,
		"getting_charge":: #pink,
		
		"picking_up"::#springgreen,
		"picking_up_packages"::#white,
		"in_use"::#gamagreen,
		"in_use_packages"::#orange
	];
	
	aspect realistic {
		color <- color_map[state];
		draw triangle(25) color:color border:color rotate: heading + 90 ;
	} 

	//loggers
	bikeLogger_roadsTraveled travelLogger;
	bikeLogger_chargeEvents chargeLogger;
	bikeLogger_event eventLogger; // TODO: review if delete
	    
	/* ========================================== PUBLIC FUNCTIONS ========================================= */
	// these are how other agents interact with this one. Not used by self

	people rider;
	package delivery;
	
	list<string> rideStates <- ["wandering"]; //This defines in which state the bikes have to be to be available for a ride
	bool lowPass <- false;

	bool availableForRide {
		return (state in rideStates) and !setLowBattery() and rider = nil  and delivery=nil and bikesInUse=true;
	}
	
	action pickUp(people person) { 
		//transition from wander to picking_up. Called by the global scheduler
		rider <- person;
	}
	action pickUpPackage(package pack){
		delivery <- pack;
	}
	/* ========================================== PRIVATE FUNCTIONS ========================================= */
	// no other species should touch these
	
	//----------------BATTERY-----------------
	
	bool setLowBattery { //Determines when to move into the low_battery state
		
		if batteryLife < minSafeBattery { return true; } 
		else {
			return false;
		}
	}
	float energyCost(float distance) {
		//if state = "in_use" { return 0; } //This means use phase does not consmue battery
		return distance;
	}
	action reduceBattery(float distance) {
		batteryLife <- batteryLife - energyCost(distance); 
	}
	//----------------MOVEMENT-----------------
	point target;
	
	float batteryLife min: 0.0 max: maxBatteryLife; //Number of meters we can travel on current battery
	float distancePerCycle;
	
	path travelledPath; //preallocation. Only used within the moveTowardTarget reflex
	
	bool canMove {
		return ((target != nil and target != location)) and batteryLife > 0;
	}
		
	path moveTowardTarget {
		if (state="in_use" or state="in_use_packages"){return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeed);}
		return goto(on:roadNetwork, target:target, return_path: true, speed:PickUpSpeed);
	}
	
	reflex move when: canMove() {
		
		travelledPath <- moveTowardTarget();
		//do goto or, in the case of wandering, follow the predicted path for the full step (see path wander)
		
		float distanceTraveled <- host.distanceInGraph(travelledPath.source,travelledPath.target);
		
		do reduceBattery(distanceTraveled);
	}
				
	/* ========================================== STATE MACHINE ========================================= */
	state wandering initial: true {
		//wander the map, follow pheromones. Same as the old searching reflex
		enter {
			ask eventLogger { do logEnterState; }
			target <- nil;
		}
		transition to: picking_up when: rider != nil {}
		transition to: picking_up_packages when: delivery != nil{}
		transition to: low_battery when: setLowBattery() {}
		exit {
			ask eventLogger { do logExitState; }
		}
	}
	
	state low_battery {
		//seek either a charging station or another vehicle
		enter{
			ask eventLogger { do logEnterState(myself.state); }
			target <- (chargingStation closest_to(self)).location; //
		}
		transition to: getting_charge when: self.location = target {}
		exit {
			ask eventLogger { do logExitState; }
		}
	}
	
	state getting_charge {
		//sit at a charging station until charged
		enter {
			target <- nil;
			if stationChargeLogs{ask eventLogger { do logEnterState("Charging at " + (chargingStation closest_to myself)); }}		
			
			ask chargingStation closest_to(self) {
				bikesToCharge <- bikesToCharge + myself;
			}
		}
		transition to: wandering when: batteryLife >= maxBatteryLife {}
		exit {
			if stationChargeLogs{ask eventLogger { do logExitState("Charged at " + (chargingStation closest_to myself)); }}
			ask chargingStation closest_to(self) {
				bikesToCharge <- bikesToCharge - myself;
			}
		}
	}
			
	//BIKE - PEOPLE
	state picking_up {
		//go to rider's location, pick them up
			enter {
				if bikeEventLog {ask eventLogger { do logEnterState("Picking up " + myself.rider); }}
				target <- rider.closestIntersection; //Go to the rider's closest intersection
			}
			transition to: in_use when: location=target and rider.location=target{}
			exit{
				ask eventLogger { do logExitState("Picked up " + myself.rider); }
			}
	}	
	
	state picking_up_packages {
		//go to package's location, pick them up
			enter {
				if bikeEventLog {ask eventLogger { do logEnterState("Picking up " + myself.delivery); }}
				target <- delivery.location; //Go to the rider's closest intersection
			}
			transition to: in_use_packages when: location=target {}
			exit{
				ask eventLogger { do logExitState("Picked up " + myself.delivery); }
			}
	}
	
	state in_use {
		//go to rider's destination, In Use will use it
		enter {
			if bikeEventLog {ask eventLogger { do logEnterState("In Use " + myself.rider); }}
			target <- (intersection closest_to rider.final_destination).location;
		}
		transition to: wandering when: location=target {
			rider <- nil;
		}
		exit {
			if bikeEventLog {ask eventLogger { do logExitState("Used" + myself.rider); }}
		}
	}
	
	state in_use_packages {
		//go to rider's destination, In Use will use it
		enter {
			if bikeEventLog {ask eventLogger { do logEnterState("In Use " + myself.delivery); }}
			target <- delivery.final_destination.location;  
		}
		transition to: wandering when: location=target {
			delivery <- nil;
		}
		exit {
			if bikeEventLog {
				ask eventLogger { do logExitState("Used" + myself.delivery); }
			}
		}
	}
}

species scooter control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#purple,
		
		"low_battery":: #red,
		"getting_charge":: #pink,
		
		"picking_up"::#springgreen,
		"picking_up_packages"::#lightblue,
		"in_use_packages"::#turquoise
	];
	
	aspect realistic {
		color <- color_map[state];
		draw rectangle(25,10) color:color border:color rotate: heading + 90 ;
	} 

	//loggers
	scooterLogger_roadsTraveled travelLogger;
	scooterLogger_chargeEvents chargeLogger;
	scooterLogger_event eventLogger;
	    
	/* ========================================== PUBLIC FUNCTIONS ========================================= */
	// these are how other agents interact with this one. Not used by self

	package delivery;
	
	list<string> rideStates <- ["wandering"]; //This defines in which state the bikes have to be to be available for a ride
	bool lowPass <- false;

	bool availableForRideS {
		return (state in rideStates) and !setLowBattery() and delivery=nil and scootersInUse=true;
	}
	
	action pickUpPackage(package pack){
		delivery <- pack;
	}
	/* ========================================== PRIVATE FUNCTIONS ========================================= */
	// no other species should touch these
	
	//----------------BATTERY-----------------
	
	bool setLowBattery { //Determines when to move into the low_battery state
		
		if batteryLife < minSafeBatteryS { return true; } 
		else {
			return false;
		}
	}
	float energyCost(float distance) {
		return distance;
	}
	action reduceBattery(float distance) {
		batteryLife <- batteryLife - energyCost(distance); 
	}
	//----------------MOVEMENT-----------------
	point target;
	
	float batteryLife min: 0.0 max: maxBatteryLifeS; //Number of meters we can travel on current battery
	float distancePerCycle;
	
	path travelledPath; //preallocation. Only used within the moveTowardTarget reflex
	
	bool canMove {
		return ((target != nil and target != location)) and batteryLife > 0;
	}
		
	path moveTowardTarget {
		if (state="in_use_packages"){return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeedS);}
		return goto(on:roadNetwork, target:target, return_path: true, speed:PickUpSpeedS);
	}
	
	reflex move when: canMove() {
		
		travelledPath <- moveTowardTarget();
		
		float distanceTraveled <- host.distanceInGraph(travelledPath.source,travelledPath.target);
		
		//scooterEmissions <- scooterEmissions + distanceTraveled*scooterCO2Emissions;
				
		do reduceBattery(distanceTraveled);
	}
				
	/* ========================================== STATE MACHINE ========================================= */
	state wandering initial: true {
		//wander the map, follow pheromones. Same as the old searching reflex
		enter {
			ask eventLogger { do logEnterState; }
			target <- nil;
		}
		transition to: picking_up_packages when: delivery != nil{}
		transition to: low_battery when: setLowBattery() {}
		exit {
			ask eventLogger { do logExitState; }
		}
	}
	
	state low_battery {
		//seek either a charging station or another vehicle
		enter{
			ask eventLogger { do logEnterState(myself.state); }
			target <- (chargingStation closest_to(self)).location; 
			scooter_trips_count_C <- scooter_trips_count_C + 1;
			scooter_distance_C <- target distance_to location;
			scooter_total_emissions <- scooter_total_emissions + scooter_distance_C*scooterCO2Emissions;
		}
		transition to: getting_charge when: self.location = target {}
		exit {
			ask eventLogger { do logExitState; }
		}
	}
	
	state getting_charge {
		//sit at a charging station until charged
		enter {
			target <- nil;
			if stationChargeLogs{ask eventLogger { do logEnterState("Charging at " + (chargingStation closest_to myself)); }}		
			
			ask chargingStation closest_to(self) {
				scootersToCharge <- scootersToCharge + myself;
			}
		}
		transition to: wandering when: batteryLife >= maxBatteryLifeS {}
		exit {
			if stationChargeLogs{ask eventLogger { do logExitState("Charged at " + (chargingStation closest_to myself)); }}
			ask chargingStation closest_to(self) {
				scootersToCharge <- scootersToCharge - myself;
			}
		}
	}
	state picking_up_packages {
		//go to package's location, pick them up
		enter {
			if scooterEventLog {ask eventLogger { do logEnterState("Picking up " + myself.delivery); }}
			target <- delivery.location; //Go to the rider's closest intersection
			//scootersUsed <- scootersUsed +1;			
			scooter_trips_count_PUP <- scooter_trips_count_PUP + 1;
			scooter_distance_PUP <- delivery.location distance_to location;
			scooter_total_emissions <- scooter_total_emissions + scooter_distance_PUP*scooterCO2Emissions;
		}
		transition to: in_use_packages when: location=target {}
		exit{
			ask eventLogger { do logExitState("Picked up " + myself.delivery); }
		}
	}
	
	state in_use_packages {
		//go to rider's destination, In Use will use it
		enter {
			if scooterEventLog {ask eventLogger { do logEnterState("In Use " + myself.delivery); }}
			target <- delivery.final_destination.location;  
			scooter_distance_D <- delivery.final_destination.location distance_to location;
			scooter_total_emissions <- scooter_total_emissions + scooter_distance_D*scooterCO2Emissions;
		}
		transition to: wandering when: location=target {
			delivery <- nil;
		}
		exit {
			if scooterEventLog {
				ask eventLogger { do logExitState("Used" + myself.delivery); }
			}
		}
	}
}

species conventionalBike control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#purple,
		"picking_up_packages"::#brown,
		"in_use_packages"::#gray
	];
	
	aspect realistic {
		color <- color_map[state];
		draw triangle(25) color:color border:color rotate: heading + 90 ;
	} 

	conventionalBikesLogger_roadsTraveled travelLogger;
	conventionalBikesLogger_event eventLogger; // TODO: review if delete
	    
	/* ========================================== PUBLIC FUNCTIONS ========================================= */

	package delivery;
	
	list<string> rideStates <- ["wandering"]; //This defines in which state the bikes have to be to be available for a ride
	bool lowPass <- false;

	bool availableForRideCB {
		return (state in rideStates) and delivery=nil and conventionalBikesInUse=true;
	}
	
	action pickUpPackage(package pack){
		delivery <- pack;
	}
	/* ========================================== PRIVATE FUNCTIONS ========================================= */

	point target;
	
	path travelledPath;
	
	bool canMove {
		return ((target != nil and target != location));
	}
		
	path moveTowardTarget {
		if (state="in_use_packages"){return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeedConventionalBikes);}
		return goto(on:roadNetwork, target:target, return_path: true, speed:PickUpSpeedConventionalBikes);
	}
	
	reflex move when: canMove() {
		
		travelledPath <- moveTowardTarget();
		
		float distanceTraveled <- host.distanceInGraph(travelledPath.source,travelledPath.target);
		
		//scooterEmissions <- scooterEmissions + distanceTraveled*scooterCO2Emissions;
	}
				
	state wandering initial: true {
		enter {
			ask eventLogger { do logEnterState; }
			target <- nil;
		}
		transition to: picking_up_packages when: delivery != nil{}
		exit {
			ask eventLogger { do logExitState; }
		}
	}
	
	state picking_up_packages {
		enter {
			if conventionalBikesEventLog {ask eventLogger { do logEnterState("Picking up " + myself.delivery); }}
			target <- delivery.location; 
			conventionalBike_trips_count_PUP <- conventionalBike_trips_count_PUP + 1;
			conventionalBike_distance_PUP <- target distance_to location;
			conventionalBike_total_emissions <- conventionalBike_total_emissions + conventionalBike_distance_PUP*conventionalBikeCO2Emissions;				
		}
		transition to: in_use_packages when: location=target {}
		exit{
			ask eventLogger { do logExitState("Picked up " + myself.delivery); }
		}
	}
	
	state in_use_packages {
		enter {
			if conventionalBikesEventLog {ask eventLogger { do logEnterState("In Use " + myself.delivery); }}
			target <- delivery.final_destination.location;  
			conventionalBike_distance_D <- target distance_to location;
			conventionalBike_total_emissions <- conventionalBike_total_emissions + conventionalBike_distance_D*conventionalBikeCO2Emissions;
		}
		transition to: wandering when: location=target {
			delivery <- nil;
		}
		exit {
			if conventionalBikesEventLog {
				ask eventLogger { do logExitState("Used" + myself.delivery); }
			}
		}
	}
}
