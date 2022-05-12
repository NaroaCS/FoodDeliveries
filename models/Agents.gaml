model Agents

import "./main.gaml"

global {
	
	float distanceInGraph (point origin, point destination) {
		return origin distance_to destination;	
	}
	
	bool autonomousBikesInUse;
	bool scootersInUse;
	bool conventionalBikesInUse;
	
	list<autonomousBike> availableAutonomousBikes(people person , package delivery) {
		if traditionalScenario{
			autonomousBikesInUse <- false;
		} else {
			autonomousBikesInUse <- true;
		}
		return autonomousBike where (each.availableForRideAB());
	}
	
	list<scooter> availableScooters(package delivery) {
		if traditionalScenario{
			scootersInUse <- true;
		} else {
			scootersInUse <- false;
		}
		return scooter where (each.availableForRideS());
	}
	
	list<conventionalBike> availableConventionalBikes(package delivery) {
		if traditionalScenario{
			conventionalBikesInUse <- true;
		} else {
			conventionalBikesInUse <- false;
		}
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
	
	bool requestAutonomousBike(people person, package delivery, point destination) { 

		list<autonomousBike> available <- availableAutonomousBikes(person, delivery);
		if empty(available) {
			return false;
		}
		if person != nil{
			autonomousBike b <- available closest_to(person);
		
			if !autonomousBikeClose(person,nil,b){
				return false;
			}
			ask b {
				do pickUp(person, nil);
			}
			ask person {
				do ride(b);
			}
		} else if delivery != nil{		
			
			autonomousBike b <- available closest_to(delivery);
			
			if !autonomousBikeClose(nil,delivery,b){
				return false;
			}
		
			b.delivery <- delivery;
	
			ask delivery {
				do deliver_ab(b);
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
	
	bool autonomousBikeClose(people person, package delivery, autonomousBike b){
		if person !=nil {
			float d <- distanceInGraph(b.location,person.location);
			if d<maxDistance { 
				return true;
			}else{
				return false ;
			}
		} else if delivery !=nil {
			float d <- distanceInGraph(b.location,delivery.location);
			if d<maxDistance { 
				return true;
			}else{
				return false ;
			}
		} else {
			return false;
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
	list<autonomousBike> bikesToCharge;
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
		"requesting_autonomousBike_Package":: #white,
		"requesting_scooter":: #lightblue,
		"requesting_conventionalBike":: #brown,
		"awaiting_autonomousBike_Package":: #white,
		"awaiting_scooter":: #lightblue,
		"awaiting_conventionalBike":: #brown,
		"delivering_autonomousBike":: #yellow,
		"delivering_scooter"::#turquoise,
		"delivering_conventionalBike"::#gray,
		"end":: #magenta
	];
	
	packageLogger logger;
    packageLogger_trip tripLogger;
    
	date start_hour;
	
	point start_point;
	point target_point;
	int start_h;
	int start_min;
	
	autonomousBike autonomousBikeToDeliver;
	scooter scooterToDeliver;
	conventionalBike conventionalBikeToDeliver;
	
	point final_destination; 
    point target; 
    point closestIntersection;
    float waitTime;
    bool r_s <- false;
    bool r_cb <- false;
	
	aspect base {
    	color <- color_map[state];
    	draw square(20) color: color border: #black;
    }
    
	action deliver_ab(autonomousBike ab){
		autonomousBikeToDeliver <- ab;
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
    		if packageEventLog or packageTripLog {ask logger { do logEnterState; }} 
    		target <- nil;
    	}
    	transition to: requesting_autonomousBike_Package when: timeToTravel() {
    		final_destination <- target_point;
    	}
    	exit {
			if packageEventLog {ask logger { do logExitState; }}
		}
    }
	state requesting_autonomousBike_Package{
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState; }}
			closestIntersection <- (intersection closest_to(self)).location; 
		}
		transition to: firstmile when: host.requestAutonomousBike(nil, self, final_destination) {
			target <- closestIntersection;
		}
		transition to: requesting_scooter {
			if packageEventLog {ask logger { do logEvent( "Used another mode, wait too long" ); }}
			r_s <- true;
		}
		exit {
			if packageEventLog {ask logger{do logExitState("Requested Bike "+myself.autonomousBikeToDeliver);}}
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
		transition to: awaiting_autonomousBike_Package when: !r_s and !r_cb and location=target{}
		transition to: awaiting_scooter when: r_s and !r_cb and location=target{}
		transition to: awaiting_conventionalBike when: r_s and r_cb and location=target{}
		exit {
			if packageEventLog {ask logger{do logExitState;}}
		}
		do goto target: target on: roadNetwork;
	}
	
	state awaiting_autonomousBike_Package {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "awaiting " + string(myself.autonomousBikeToDeliver) ); }}
			target <- nil;
		}
		transition to: delivering_autonomousBike when: autonomousBikeToDeliver.state = "in_use_packages" {}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
		}
	}
	
	state awaiting_scooter {
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
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "awaiting " + string(myself.conventionalBikeToDeliver) ); }}
			target <- nil;
		}
		transition to: delivering_conventionalBike when: conventionalBikeToDeliver.state = "in_use_packages" {}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
		}
	}
	
	state delivering_autonomousBike {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "delivering " + string(myself.autonomousBikeToDeliver) ); }}
		}
		transition to: end when: autonomousBikeToDeliver.state != "in_use_packages" {
			target <- final_destination;
		}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
			autonomousBikeToDeliver<- nil;
		}

		location <- autonomousBikeToDeliver.location; 
	}
	
	state delivering_scooter {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "delivering " + string(myself.scooterToDeliver) ); }}
		}
		transition to: end when: scooterToDeliver.state != "in_use_packages" {
			target <- final_destination;
		}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
			scooterToDeliver<- nil;
		}
		location <- scooterToDeliver.location;
	}
	
	state delivering_conventionalBike {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "delivering " + string(myself.conventionalBikeToDeliver) ); }}
		}
		transition to: end when: conventionalBikeToDeliver.state != "in_use_packages" {
			target <- final_destination;
		}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
			conventionalBikeToDeliver<- nil;
		}
		location <- conventionalBikeToDeliver.location;
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
		"requesting_autonomousBike":: #springgreen,
		"awaiting_autonomousBike":: #springgreen,
		"riding_autonomousBike":: #gamagreen,
		"walking":: #magenta
	];
	
	//loggers
    peopleLogger logger;
    peopleLogger_trip tripLogger;
    
    package delivery;

	//raw
	date start_hour; 
	float start_lat; 
	float start_lon;
	float target_lat;
	float target_lon;
	 
	//adapted
	point start_point;
	point target_point;
	int start_h; 
	int start_min; 
    
    autonomousBike autonomousBikeToRide;
    
    point final_destination;
    point target;
    point closestIntersection;
    float waitTime;
    
    aspect base {
    	color <- color_map[state];
    	draw circle(10) color: color border: #black;
    }
    
    //----------------PUBLIC FUNCTIONS-----------------
	
    action ride(autonomousBike ab) {
    	autonomousBikeToRide <- ab;
    }	

    bool timeToTravel { return (current_date.hour = start_h and current_date.minute >= start_min) and !(self overlaps target_point); }
    
    state wandering initial: true {
    	enter {
    		if peopleEventLog or peopleTripLog {ask logger { do logEnterState; }}
    		target <- nil;
    	}
    	transition to: requesting_autonomousBike when: timeToTravel() {
       		final_destination <- target_point;
    	}
    	exit {
			if peopleEventLog {ask logger { do logExitState; }}
		}
    }
	state requesting_autonomousBike {
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState; }}
			closestIntersection <- (intersection closest_to(self)).location; 
		}
		transition to: walking when: host.requestAutonomousBike(self, nil, final_destination) {
			target <- closestIntersection;
		}
		transition to: wandering {
			if peopleEventLog {ask logger { do logEvent( "Used another mode, wait too long" ); }}
			location <- final_destination;
		}
		exit {
			if peopleEventLog {ask logger { do logExitState("Requested Bike " + myself.autonomousBikeToRide); }}
		}
	}
	state awaiting_autonomousBike {
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState( "awaiting " + string(myself.autonomousBikeToRide) ); }}
			target <- nil;
		}
		transition to: riding_autonomousBike when: autonomousBikeToRide.state = "in_use_people" {}
		exit {
			if peopleEventLog {ask logger { do logExitState; }}
		}
	}
	state riding_autonomousBike {
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState( "riding " + string(myself.autonomousBikeToRide) ); }}
		}
		transition to: walking when: autonomousBikeToRide.state != "in_use_people" {
			target <- final_destination;
		}
		exit {
			if peopleEventLog {ask logger { do logExitState; }}
			autonomousBikeToRide <- nil;
		}

		location <- autonomousBikeToRide.location; //Always be at the same place as the bike
	}
	state walking {
		//go to your destination or nearest intersection, then wait
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState; }}
		}
		transition to: wandering when: location = final_destination {}
		transition to: awaiting_autonomousBike when: location = target {}
		exit {
			if peopleEventLog {ask logger { do logExitState; }}
		}
		do goto target: target on: roadNetwork;
	}
}

species autonomousBike control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#purple,
		
		"low_battery":: #red,
		"getting_charge":: #pink,
		
		"picking_up_people"::#springgreen,
		"picking_up_packages"::#white,
		"in_use_people"::#gamagreen,
		"in_use_packages"::#orange
	];
	
	aspect realistic {
		color <- color_map[state];
		draw triangle(25) color:color border:color rotate: heading + 90 ;
	} 

	//loggers
	autonomousBikeLogger_roadsTraveled travelLogger;
	autonomousBikeLogger_chargeEvents chargeLogger;
	autonomousBikeLogger_event eventLogger;
	    
	/* ========================================== PUBLIC FUNCTIONS ========================================= */
	
	people rider;
	package delivery;
	
	list<string> rideStates <- ["wandering"]; 
	bool lowPass <- false;

	bool availableForRideAB {
		return (state in rideStates) and !setLowBattery() and rider = nil  and delivery=nil and autonomousBikesInUse=true;
	}
	
	action pickUp(people person, package pack) { 
		if person != nil{
			rider <- person;
		} else if pack !=nil {
			delivery <- pack;
		}
	}
	
	/* ========================================== PRIVATE FUNCTIONS ========================================= */
	//---------------BATTERY-----------------
	
	bool setLowBattery { 
		if batteryLife < minSafeBatteryAutonomousBike { return true; } 
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
	
	float batteryLife min: 0.0 max: maxBatteryLifeAutonomousBike; 
	float distancePerCycle;
	
	path travelledPath; 
	
	bool canMove {
		return ((target != nil and target != location)) and batteryLife > 0;
	}
		
	path moveTowardTarget {
		if (state="in_use_people" or state="in_use_packages"){return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeedAutonomousBike);}
		return goto(on:roadNetwork, target:target, return_path: true, speed:PickUpSpeedAutonomousBike);
	}
	
	reflex move when: canMove() {
		
		travelledPath <- moveTowardTarget();
		
		float distanceTraveled <- host.distanceInGraph(travelledPath.source,travelledPath.target);
		
		do reduceBattery(distanceTraveled);
	}
				
	/* ========================================== STATE MACHINE ========================================= */
	state wandering initial: true {
		enter {
			ask eventLogger { do logEnterState; }
			target <- nil;
		}
		transition to: picking_up_people when: rider != nil {}
		transition to: picking_up_packages when: delivery != nil{}
		transition to: low_battery when: setLowBattery() {}
		exit {
			ask eventLogger { do logExitState; }
		}
	}
	
	state low_battery {
		enter{
			ask eventLogger { do logEnterState(myself.state); }
			target <- (chargingStation closest_to(self)).location; 
		}
		transition to: getting_charge when: self.location = target {}
		exit {
			ask eventLogger { do logExitState; }
		}
	}
	
	state getting_charge {
		enter {
			target <- nil;
			if stationChargeLogs{ask eventLogger { do logEnterState("Charging at " + (chargingStation closest_to myself)); }}		
			
			ask chargingStation closest_to(self) {
				bikesToCharge <- bikesToCharge + myself;
			}
		}
		transition to: wandering when: batteryLife >= maxBatteryLifeAutonomousBike {}
		exit {
			if stationChargeLogs{ask eventLogger { do logExitState("Charged at " + (chargingStation closest_to myself)); }}
			ask chargingStation closest_to(self) {
				bikesToCharge <- bikesToCharge - myself;
			}
		}
	}
			
	state picking_up_people {
			enter {
				if autonomousBikeEventLog {ask eventLogger { do logEnterState("Picking up " + myself.rider); }}
				target <- rider.closestIntersection; //Go to the rider's closest intersection
			}
			transition to: in_use_people when: location=target and rider.location=target{}
			exit{
				ask eventLogger { do logExitState("Picked up " + myself.rider); }
			}
	}	
	
	state picking_up_packages {
			enter {
				if autonomousBikeEventLog {ask eventLogger { do logEnterState("Picking up " + myself.delivery); }}
				target <- delivery.location; 
			}
			transition to: in_use_packages when: location=target {}
			exit{
				ask eventLogger { do logExitState("Picked up " + myself.delivery); }
			}
	}
	
	state in_use_people {
		enter {
			if autonomousBikeEventLog {ask eventLogger { do logEnterState("In Use " + myself.rider); }}
			target <- (intersection closest_to rider.final_destination).location;
		}
		transition to: wandering when: location=target {
			rider <- nil;
		}
		exit {
			if autonomousBikeEventLog {ask eventLogger { do logExitState("Used" + myself.rider); }}
		}
	}
	
	state in_use_packages {
		enter {
			if autonomousBikeEventLog {ask eventLogger { do logEnterState("In Use " + myself.delivery); }}
			target <- delivery.final_destination.location;  
		}
		transition to: wandering when: location=target {
			delivery <- nil;
		}
		exit {
			if autonomousBikeEventLog {
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
		
		if batteryLife < minSafeBatteryScooter { return true; } 
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
	
	float batteryLife min: 0.0 max: maxBatteryLifeScooter; //Number of meters we can travel on current battery
	float distancePerCycle;
	
	path travelledPath; //preallocation. Only used within the moveTowardTarget reflex
	
	bool canMove {
		return ((target != nil and target != location)) and batteryLife > 0;
	}
		
	path moveTowardTarget {
		if (state="in_use_packages"){return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeedScooter);}
		return goto(on:roadNetwork, target:target, return_path: true, speed:PickUpSpeedScooter);
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
		transition to: wandering when: batteryLife >= maxBatteryLifeScooter {}
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
