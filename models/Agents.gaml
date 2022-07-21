model Agents

import "./main.gaml"

global {
	
	float distanceInGraph (point origin, point destination) {
		return origin distance_to destination;	
	}
	
	// Data extracted from: Contribution to the Sustainability Challenges of the Food-Delivery Sector: Finding from the Deliveroo Italy Case Study
	int numScooters;
	int numEBikes;
	int numConventionalBikes;
	int numCars;
	
	bool autonomousBikesInUse;
	bool docklessBikesInUse;
	bool scootersInUse;
	bool eBikesInUse;
	bool conventionalBikesInUse;
	bool carsInUse;
	
	list<autonomousBike> availableAutonomousBikes(people person , package delivery) {
		if traditionalScenario{
			autonomousBikesInUse <- false;
		} else {
			autonomousBikesInUse <- true;
		}
		return autonomousBike where (each.availableForRideAB());
	}
	
	list<docklessBike> availableDocklessBikes(people person) {
		if traditionalScenario{
			docklessBikesInUse <- true;
		} else {
			docklessBikesInUse <- false;
		}
		return docklessBike where (each.availableForRideDB());
	}
	
	list<scooter> availableScooters(package delivery) {
		if traditionalScenario{
			scootersInUse <- true;
		} else {
			scootersInUse <- false;
		}
		return scooter where (each.availableForRideS());
	}
	
	list<eBike> availableEBikes (package delivery) {
		if traditionalScenario{
			eBikesInUse <- true;
		} else {
			scootersInUse <- false;
		}
		return eBike where (each.availableForRideEB());
	}
	
	list<conventionalBike> availableConventionalBikes(package delivery) {
		if traditionalScenario{
			conventionalBikesInUse <- true;
		} else {
			conventionalBikesInUse <- false;
		}
		return conventionalBike where (each.availableForRideCB());
	}
	
	list<car> availableCars(package delivery) {
		if traditionalScenario{
			carsInUse <- true;
		} else {
			carsInUse <- false;
		}
		return car where (each.availableForRideC());
	}
		
	int autonomousBike_trips_count_total <- 0;
	int autonomousBike_trips_count_people <- 0;
	int autonomousBike_trips_count_package <- 0;
	float autonomousBike_distance_PUP_people <- 0.0;
	float autonomousBike_distance_PUP_package <- 0.0;
	float autonomousBike_distance_D_people <- 0.0;
	float autonomousBike_distance_D_package <- 0.0;
	float autonomousBike_distance_C <- 0.0;
	float autonomousBike_total_emissions_people <- 0.0;
	float autonomousBike_total_emissions_package <- 0.0;
	float autonomousBike_total_emissions_C <- 0.0;
	float autonomousBike_total_emissions <- 0.0;
	
	float docklessBike_distance_DP <- 0.0;
	int docklessBike_trips_count_DP <- 0;
	float docklessBike_total_emissions <- 0.0;
	
	float scooter_distance_PUP <- 0.0;
	int scooter_trips_count_PUP <- 0;
	float scooter_distance_D <- 0.0;
	float scooter_total_emissions <-0.0;
	
	float eBike_distance_PUP <- 0.0;
	int eBike_trips_count_PUP <- 0;
	float eBike_distance_D <- 0.0;
	float eBike_total_emissions <-0.0;
	
	float conventionalBike_distance_PUP <- 0.0;
	int conventionalBike_trips_count_PUP <- 0;
	float conventionalBike_distance_D <- 0.0;
	float conventionalBike_total_emissions <- 0.0;
	
	float car_distance_PUP <- 0.0;
	int car_trips_count_PUP <- 0;
	float car_distance_D <- 0.0;
	float car_total_emissions <- 0.0;
		
	int chooseDeliveryMode(package delivery) {
    	
    	float dab; 
		float ds;
		float deb;
		float dcb;
		float dc;
		float mindistance;
		int choice <- 0;
    	
		list<autonomousBike> availableAB <- availableAutonomousBikes(nil, delivery);
		list<scooter> availableS <- availableScooters(delivery);
		if !empty(availableS){
			scooter s <- availableS closest_to(delivery);
			ds <- distanceInGraph(s.location,delivery.location);
			if ds <= maxDistancePackage_Scooter {
				ds <- ds;
			} else {
				ds <- 1000000.0;
			}
		} else {
			ds <- 10000000.0;
		}
		list<eBike> availableEB <- availableEBikes(delivery);
		if !empty(availableEB){
			eBike eb <- availableEB closest_to(delivery);
			deb <- distanceInGraph(eb.location,delivery.location);
			if deb <= maxDistancePackage_EBike {
				deb <- deb;
			} else {
				deb <- 1000000.0;
			}
		} else {
			deb <- 1000000.0;
		}		
		list<conventionalBike> availableCB <- availableConventionalBikes (delivery);
		if !empty(availableCB){
			conventionalBike cb <- availableCB closest_to(delivery);
			dcb <- distanceInGraph(cb.location,delivery.location);
			if dcb <= maxDistancePackage_ConventionalBike {
				dcb <- dcb;
			} else {
				dcb <- 1000000.0;
			}
		} else {
			dcb <- 1000000.0;
		}
		list<car> availableC <- availableCars (delivery);
		if !empty(availableC){
			car c <- availableC closest_to(delivery);
			dc <- distanceInGraph(c.location,delivery.location);
			if dc <= maxDistancePackage_Car {
				dc <- dc;
			} else {
				dc <- 1000000.0;
			}
		} else {
			dc <- 1000000.0;
		}
		
		if !traditionalScenario {
			if empty(availableAB) {
				dab <- 0.0;
				choice <- 0;
			} else {
				autonomousBike ab <- availableAB closest_to(delivery);
				dab <- distanceInGraph(ab.location,delivery.location);
				if dab < maxDistancePackage_AutonomousBike{
					mindistance <- dab;
					choice <- 1;
				} else {
					choice <- 0;
				}
			}
		} else if traditionalScenario {
			if empty(availableS) and empty(availableEB) and empty(availableCB) and empty(availableC) {
				choice <- 0;
			} else {
				if ds<dc and ds<=deb and ds<=dcb {
					mindistance <- ds;
					choice <- 2;
				} else if deb<dc and deb<ds and deb<=dcb {
					mindistance <- deb;
					choice <- 3;
				} else if dcb<dc and dcb<ds and dcb<deb {
					mindistance <- dcb;
					choice <- 4;
				} else if dc<=ds and dc<=deb and dc<=dcb {
					mindistance <- dc;
					choice <- 5;
				} 
				else {
					choice <- 0;
				}
			}
		}
		return choice;	
    }
		
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
				do ride(b,nil);
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
	
	bool requestDocklessBike(people person, point destination) {
				
		list<docklessBike> available <- availableDocklessBikes(person);

		if empty(available) {
			return false;
		}
		if person != nil{
			
			docklessBike db <- available closest_to(person);
			
			if !docklessBikeClose(person,db){
				return false;
			} else if docklessBikeClose(person,db){
				ask db {
					do pickUpRider(person);
				}
				ask person {
					do ride(nil,db);
				}
			}		
		} else {
			return false;
		}
		return true;
	}

	bool requestScooter(package delivery, point destination) { 

		list<scooter> available <- availableScooters(delivery);
		
		scooter s <- available closest_to(delivery);
		s.delivery <- delivery;
		ask delivery {
			do deliver_s(s);
		}
		return true;		
	}	
	
	bool requestEBike(package delivery, point destination) { 

		list<eBike> available <- availableEBikes(delivery);
		
		eBike eb <- available closest_to(delivery);
		eb.delivery <- delivery;
		ask delivery {
			do deliver_eb(eb);
		}
		return true;		
	}	
	
	bool requestConventionalBike(package delivery, point destination) {
		
		list<conventionalBike> available <- availableConventionalBikes(delivery);	
		conventionalBike cb <- available closest_to(delivery);
		cb.delivery <- delivery;
		ask delivery {
			do deliver_cb(cb);
		}
		return true;
	}
	
	bool requestCar(package delivery, point destination) {
		
		list<car> available <- availableCars(delivery);	
		car c <- available closest_to(delivery);
		c.delivery <- delivery;
		ask delivery {
			do deliver_c(c);
		}
		return true;
	}
		
	bool autonomousBikeClose(people person, package delivery, autonomousBike ab){
		if person !=nil {
			float d <- distanceInGraph(ab.location,person.location);
			if d<maxDistancePeople_AutonomousBike { 
				return true;
			}else{
				return false ;
			}
		} else if delivery !=nil {
			float d <- distanceInGraph(ab.location,delivery.location);
			if d<maxDistancePackage_AutonomousBike { 
				return true;
			}else{
				return false ;
			}
		} else {
			return false;
		}
	}
	
	bool docklessBikeClose(people person, docklessBike db){
		float d <- distanceInGraph(db.location,person.location);
		if d<maxDistancePeople_DocklessBike { 
			return true;
		}else{
			return false ;
		}
	}
	
	bool scooterClose(package delivery, scooter s){
		float d <- distanceInGraph(s.location,delivery.location);
		if d<maxDistancePackage_Scooter { 
			return true;
		}else{
			return false ;
		}
	}
	
	bool eBikeClose(package delivery, eBike eb){
		float d <- distanceInGraph(eb.location,delivery.location);
		if d<maxDistancePackage_EBike { 
			return true;
		}else{
			return false ;
		}
	}
	
	bool conventionalBikeClose(package delivery, conventionalBike cb){
		float d <- distanceInGraph(cb.location,delivery.location);
		if d<maxDistancePackage_ConventionalBike { 
			return true;
		}else{
			return false ;
		}
	}
	bool carClose(package delivery, car c){
		float d <- distanceInGraph(c.location,delivery.location);
		if d<maxDistancePackage_Car { 
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
	list<autonomousBike> autonomousBikesToCharge;
	float lat;
	float lon;
	
	point point_station;
	aspect base {
		draw circle(25) color:#gamaorange border:#black;		
	}
	
	reflex chargeBikes {
		ask chargingStationCapacity first autonomousBikesToCharge {
			batteryLife <- batteryLife + step*V2IChargingRate;
		}
	}
}

species restaurant{
	
	rgb color <- #red;
	
	float lat;
	float lon;
	point rest;
	
	aspect base{
		draw circle(20) color:color border:#black;
	}
}

species intersection {
	int id;	
}

species package control: fsm skills: [moving] {

	rgb color;
	
    map<string, rgb> color_map <- [
    	
    	"firstmile":: #blue,
		"requesting_autonomousBike_Package":: #yellow,
		"requesting_scooter":: #turquoise,
		"requesting_eBike":: #green,
		"requesting_conventionalBike":: #brown,
		"requesting_car":: #gray,
		"awaiting_autonomousBike_Package":: #yellow,
		"awaiting_scooter":: #turquoise,
		"awaiting_eBike":: #green,
		"awaiting_conventionalBike":: #brown,
		"awaiting_car":: #gray,
		"delivering_autonomousBike":: #yellow,
		"delivering_scooter"::#turquoise,
		"delivering_eBike"::#green,
		"delivering_conventionalBike"::#brown,
		"delivering_car"::#gray,
		"lastmile"::#blue,
		"end":: #magenta
	];
	
	packageLogger logger;
    packageLogger_trip tripLogger;
    
	date start_hour;
	float start_lat; 
	float start_lon;
	float target_lat; 
	float target_lon;
	
	point start_point;
	point target_point;
	int start_h;
	int start_min;
	int mode; // 1 <- Autonomous Bike || 2 <- Scooter || 3 <- eBike || 4 <- Conventional Bike
	
	autonomousBike autonomousBikeToDeliver;
	scooter scooterToDeliver;
	eBike eBikeToDeliver;
	conventionalBike conventionalBikeToDeliver;
	car carToDeliver;
	
	point final_destination; 
    point target; 
    point closestIntersection;
    float waitTime;
    int choice;
        
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
	
	action deliver_eb(eBike eb){
		eBikeToDeliver <- eb;
	}
	
	action deliver_cb(conventionalBike cb){
		conventionalBikeToDeliver <- cb;
	}
	
	action deliver_c(car c){
		carToDeliver <- c;
	}
	
	/*action updatePollutionMap (autonomousBike ab, scooter s, eBike eb, conventionalBike cb, car c){
		ask gridHeatmaps overlapping(current_path.shape) {
			if ab!=nil{
				pollution_level <- pollution_level + 32;
			} else if s !=nil {
				pollution_level <- pollution_level + 22;
			} else if eb !=nil {
				pollution_level <- pollution_level + 15;
			} else if cb !=nil {
				pollution_level <- pollution_level + 6;
			} else if c !=nil {
				pollution_level <- pollution_level + 100;
			}
		}
	}*/
		
	bool timeToTravel { return (current_date.hour = start_h and current_date.minute >= start_min) and !(self overlaps target_point); }
	
	state end initial: true {
    	
    	enter {
    		
    		if packageEventLog or packageTripLog {ask logger { do logEnterState;}} 
    		target <- nil;
    	}
    	transition to: choosingDeliveryMode when: timeToTravel() {
    		final_destination <- target_point;
    	}
    	exit {
			if packageEventLog {ask logger { do logExitState; }}
		}
    }
    
    state choosingDeliveryMode {
    	
    	enter {
    		if packageEventLog or packageTripLog {ask logger { do logEnterState; }} 
    		choice <- host.chooseDeliveryMode(self);
    	}
    	transition to: requesting_autonomousBike_Package when: choice=1 {
    		final_destination <- target_point;
    		mode <- 1;
    		//do updatePollutionMap(autonomousBikeToDeliver,nil,nil,nil,nil);
    	}
    	transition to: requesting_scooter when: choice=2 {
    		final_destination <- target_point;
    		mode <- 2;
    		//do updatePollutionMap(nil,scooterToDeliver,nil,nil,nil);
    	}
    	transition to: requesting_eBike when: choice=3 {
    		final_destination <- target_point;
    		mode <- 3;
    		//do updatePollutionMap(nil,nil,eBikeToDeliver,nil,nil);
    	}
    	transition to: requesting_conventionalBike when: choice=4 {
    		final_destination <- target_point;
    		mode <- 4;
    		//do updatePollutionMap(nil,nil,nil,conventionalBikeToDeliver,nil);
    	}
    	transition to: requesting_car when: choice=5 {
    		final_destination <- target_point;
    		mode <- 5;
    		//do updatePollutionMap(nil,nil,nil,nil,carToDeliver);
    	}
    	transition to: end when: choice=0 {
    		target <- final_destination;
    	}
    	exit {
			if packageEventLog {ask logger { do logExitState; }}
		}
    }
    
	state requesting_autonomousBike_Package{
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState; }} 
		}
		transition to: firstmile when: host.requestAutonomousBike(nil, self, final_destination) {
			target <- (road closest_to(self)).location;
		}
		exit {
			if packageEventLog {ask logger{do logExitState("Requested Bike "+myself.autonomousBikeToDeliver);}}
		}
	}
	
	state requesting_scooter{
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState; }}
		}
		transition to: firstmile when: host.requestScooter(self, final_destination) {
			target <- (road closest_to(self)).location;
		}
		exit {
			if packageEventLog {ask logger{do logExitState("Requested Scooter "+myself.scooterToDeliver);}}
		}
	}
	
	state requesting_eBike{
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState; }}
		}
		transition to: firstmile when: host.requestEBike(self, final_destination) {
			target <- (road closest_to(self)).location;
		}
		exit {
			if packageEventLog {ask logger{do logExitState("Requested EBike "+myself.eBikeToDeliver);}}
		}
	}
	
	state requesting_conventionalBike {
		enter {
			if packageEventLog {ask logger { do logEnterState; }}
		}
		transition to: firstmile when: host.requestConventionalBike (self, final_destination) {
			target <- (road closest_to(self)).location;
		}
		exit {
			if packageEventLog {ask logger{do logExitState("Requested Conventional Bike "+myself.conventionalBikeToDeliver);}}
		}
	}
	
	state requesting_car {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState; }} 
		}
		transition to: firstmile when: host.requestCar(self, final_destination) {
			target <- (road closest_to(self)).location;
		}
		exit {
			if packageEventLog {ask logger{do logExitState("Requested Car "+myself.carToDeliver);}}
		}
	}
	
	state firstmile {
		enter{
			if packageEventLog or packageTripLog {ask logger{ do logEnterState;}}
		}
		transition to: awaiting_autonomousBike_Package when: choice=1 and location=target{}
		transition to: awaiting_scooter when: choice=2 and location=target{}
		transition to: awaiting_eBike when: choice=3 and location=target{}
		transition to: awaiting_conventionalBike when: choice=4 and location=target{}
		transition to: awaiting_car when: choice=5 and location=target{}
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
	
	state awaiting_eBike {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "awaiting " + string(myself.eBikeToDeliver) ); }}
			target <- nil;
		}
		transition to: delivering_eBike when: eBikeToDeliver.state = "in_use_packages" {}
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
	
	state awaiting_car {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "awaiting " + string(myself.carToDeliver) ); }}
			target <- nil;
		}
		transition to: delivering_car when: carToDeliver.state = "in_use_packages" {}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
		}
	}
	
	state delivering_autonomousBike {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "delivering " + string(myself.autonomousBikeToDeliver) ); }}
		}
		transition to: lastmile when: autonomousBikeToDeliver.state != "in_use_packages" {
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
		transition to: lastmile when: scooterToDeliver.state != "in_use_packages" {
			target <- final_destination;
		}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
			scooterToDeliver<- nil;
		}
		location <- scooterToDeliver.location;
	}
	
	state delivering_eBike {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "delivering " + string(myself.eBikeToDeliver) ); }}
		}
		transition to: lastmile when: eBikeToDeliver.state != "in_use_packages" {
			target <- final_destination;
		}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
			eBikeToDeliver<- nil;
		}
		location <- eBikeToDeliver.location;
	}
	
	state delivering_conventionalBike {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "delivering " + string(myself.conventionalBikeToDeliver) ); }}
		}
		transition to: lastmile when: conventionalBikeToDeliver.state != "in_use_packages" {
			target <- final_destination;
		}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
			conventionalBikeToDeliver<- nil;
		}
		location <- conventionalBikeToDeliver.location;
	}
	
	state delivering_car {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "delivering " + string(myself.carToDeliver) ); }}
		}
		transition to: lastmile when: carToDeliver.state != "in_use_packages" {
			target <- final_destination;
		}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
			carToDeliver<- nil;
		}
		location <- carToDeliver.location;
	}
	
	state lastmile {
		enter{
			if packageEventLog or packageTripLog {ask logger{ do logEnterState;}}
		}
		transition to:end when: location=target{}
		exit {
			if packageEventLog {ask logger{do logExitState;}}
		}
		do goto target: target on: roadNetwork;
	}
}

species people control: fsm skills: [moving] {

	rgb color;
	
    map<string, rgb> color_map <- [
		"requesting_autonomousBike":: #springgreen,
		"requesting_docklessBike"::#gamablue,
		"awaiting_autonomousBike":: #springgreen,
		"walking_docklessBike":: #magenta,
		"riding_autonomousBike":: #gamagreen,
		"riding_docklessBike"::#gamablue,
		"firstmile":: #magenta,
		"lastmile":: #magenta
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
	int mode; // 0 <- Autonomous Bike || 1 <- Dockless Bike
    
    autonomousBike autonomousBikeToRide;
    docklessBike docklessBikeToRide;
    
    point final_destination;
    point target;
    point closestDocklessBikeToRide;
    float waitTime;
    
    aspect base {
    	color <- color_map[state];
    	draw circle(10) color: color border: #black;
    }
    
    //----------------PUBLIC FUNCTIONS-----------------
	
    action ride(autonomousBike ab, docklessBike db) {
    	if ab!=nil{
    		autonomousBikeToRide <- ab;
    		mode <- 0;
    	} else if db!=nil{
    		docklessBikeToRide <- db;
    		mode <- 1;
    	}
    }	
    
    /*action updatePollutionMap (autonomousBike ab, docklessBike db) {
    	if ab !=nil{
    		ask gridHeatmaps overlapping(current_path.shape) {
			pollution_level <- pollution_level + 32;
			}
    	} else if db != nil {
    		ask gridHeatmaps overlapping(current_path.shape) {
			pollution_level <- pollution_level + 6;
			}
    	}
		
	}*/

    bool timeToTravel { return (current_date.hour = start_h and current_date.minute >= start_min) and !(self overlaps target_point); }
    
    state wandering initial: true {
    	enter {
    		if peopleEventLog or peopleTripLog {ask logger { do logEnterState; }}
    		target <- nil;
    		if traditionalScenario{
    			numAutonomousBikes <- 0;
    		} else if !traditionalScenario {
    			numDocklessBikes <- 0;
    		}
    	}
    	transition to: requesting_autonomousBike when: timeToTravel() and !traditionalScenario {
       		final_destination <- target_point;
       		//do updatePollutionMap(autonomousBikeToRide, nil);
    	}
    	transition to: requesting_docklessBike when: timeToTravel() and traditionalScenario {
       		final_destination <- target_point;
       		//do updatePollutionMap(nil, docklessBikeToRide);
    	}
    	exit {
			if peopleEventLog {ask logger { do logExitState; }}
		}
    }
    
	state requesting_autonomousBike {
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState; }} 
		}
		transition to: firstmile when: host.requestAutonomousBike(self, nil, final_destination) {
			target <- (road closest_to(self)).location;
		}
		transition to: wandering {
			if peopleEventLog {ask logger { do logEvent( "Used another mode, wait too long" ); }}
			location <- final_destination;
		}
		exit {
			if peopleEventLog {ask logger { do logExitState("Requested Bike " + myself.autonomousBikeToRide); }}
		}
	}
	state requesting_docklessBike {
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState; }}
		}
		transition to: walking_docklessBike when: host.requestDocklessBike(self, final_destination) {
			target <- docklessBikeToRide.location;
		}
		transition to: wandering {
			if peopleEventLog {ask logger { do logEvent( "Used another mode, wait too long" ); }}
			location <- final_destination;
		}
		exit {
			if peopleEventLog {ask logger { do logExitState("Requested Bike " + myself.docklessBikeToRide); }}
		}
	}
	state firstmile {
		enter{
			if peopleEventLog or peopleTripLog {ask logger{ do logEnterState;}}
		}
		transition to: awaiting_autonomousBike when: location=target{}
		exit {
			if peopleEventLog {ask logger{do logExitState;}}
		}
		do goto target: target on: roadNetwork;
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
	state walking_docklessBike {
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState; }}
		}
		transition to: riding_docklessBike when: traditionalScenario and location = target and docklessBikeToRide.state = "in_use_people" {}
		exit {
			if peopleEventLog {ask logger { do logExitState; }}
		}
		do goto target: target on: roadNetwork;
	}
	state riding_autonomousBike {
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState( "riding " + string(myself.autonomousBikeToRide) ); }}
			mode <- 0;
		}
		transition to: lastmile when: autonomousBikeToRide.state != "in_use_people" {
			target <- final_destination;
		}
		exit {
			if peopleEventLog {ask logger { do logExitState; }}
			autonomousBikeToRide <- nil;
		}

		location <- autonomousBikeToRide.location; //Always be at the same place as the bike
	}
	state riding_docklessBike {
		enter {
			if peopleEventLog or peopleTripLog {ask logger { do logEnterState( "riding " + string(myself.docklessBikeToRide) ); }}
			mode <- 1;
		}
		transition to: lastmile when: docklessBikeToRide.state != "in_use_people" {
			target <- final_destination;
		}
		exit {
			if peopleEventLog {ask logger { do logExitState; }}
			docklessBikeToRide <- nil;
		}
		location <- docklessBikeToRide.location; //Always be at the same place as the bike
	}
	state lastmile {
		enter{
			if peopleEventLog or peopleTripLog {ask logger{ do logEnterState;}}
		}
		transition to:wandering when: location=target{}
		exit {
			if peopleEventLog {ask logger{do logExitState;}}
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
	int activity; //0=Package 1=Person
	
	list<string> rideStates <- ["wandering"]; 
	bool lowPass <- false;

	bool availableForRideAB {
		return (state in rideStates) and self.state="wandering" and !setLowBattery() and rider = nil  and delivery=nil and autonomousBikesInUse=true;
	}
	
	action pickUp(people person, package pack) { 
		if person != nil{
			rider <- person;
			activity <- 1;
		} else if pack !=nil {
			delivery <- pack;
			activity <- 0;
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
	path Path;
	
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
			if autonomousBikeEventLog {
				ask eventLogger { do logEnterState; }
				ask travelLogger { do logRoads(0.0);}
			}
			target <- nil;
		}
		transition to: picking_up_people when: rider != nil {}
		transition to: picking_up_packages when: delivery != nil{}
		transition to: low_battery when: setLowBattery() {}
		exit {
			if autonomousBikeEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state low_battery {
		enter{
			target <- (chargingStation closest_to(self)).location; 
			autonomousBike_distance_C <- target distance_to location;
			autonomousBike_total_emissions_C <- autonomousBike_total_emissions_C+autonomousBike_distance_C*autonomousBikeCO2Emissions;
			autonomousBike_total_emissions <- autonomousBike_total_emissions + autonomousBike_total_emissions_C;
			if autonomousBikeEventLog {
				ask eventLogger { do logEnterState(myself.state); }
				ask travelLogger { do logRoads(autonomousBike_distance_C);}
			}
		}
		transition to: getting_charge when: self.location = target {}
		exit {
			if autonomousBikeEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state getting_charge {
		enter {
			if stationChargeLogs{
				ask eventLogger { do logEnterState("Charging at " + (chargingStation closest_to myself)); }
				ask travelLogger { do logRoads(0.0);}
			}		
			target <- nil;
			ask chargingStation closest_to(self) {
				autonomousBikesToCharge <- autonomousBikesToCharge + myself;
			}
		}
		transition to: wandering when: batteryLife >= maxBatteryLifeAutonomousBike {}
		exit {
			if stationChargeLogs{ask eventLogger { do logExitState("Charged at " + (chargingStation closest_to myself)); }}
			ask chargingStation closest_to(self) {
				autonomousBikesToCharge <- autonomousBikesToCharge - myself;
			}
		}
	}
			
	state picking_up_people {
			enter {
				target <- rider.location;
				autonomousBike_trips_count_people <- autonomousBike_trips_count_people + 1;
				autonomousBike_trips_count_total <- autonomousBike_trips_count_total + 1;
				autonomousBike_distance_PUP_people <- target distance_to location;
				autonomousBike_total_emissions_people <- autonomousBike_total_emissions_people + autonomousBike_distance_PUP_people*autonomousBikeCO2Emissions;
				autonomousBike_total_emissions <- autonomousBike_total_emissions + autonomousBike_total_emissions_people;
				if autonomousBikeEventLog {
					ask eventLogger { do logEnterState("Picking up " + myself.rider); }
					ask travelLogger { do logRoads(autonomousBike_distance_PUP_people);}
				}
			}
			transition to: in_use_people when: location=target {}
			exit{
				if autonomousBikeEventLog {ask eventLogger { do logExitState("Picked up " + myself.rider); }}
			}
	}	
	
	state picking_up_packages {
			enter {
				target <- delivery.location; 
				autonomousBike_trips_count_package <- autonomousBike_trips_count_people + 1;
				autonomousBike_trips_count_total <- autonomousBike_trips_count_total + 1;
				autonomousBike_distance_PUP_package <- target distance_to location;
				autonomousBike_total_emissions_package <- autonomousBike_total_emissions_package + autonomousBike_distance_PUP_package*autonomousBikeCO2Emissions;
				autonomousBike_total_emissions <- autonomousBike_total_emissions + autonomousBike_total_emissions_package;
				if autonomousBikeEventLog {
					ask eventLogger { do logEnterState("Picking up " + myself.delivery); }
					ask travelLogger { do logRoads(autonomousBike_distance_PUP_package);}
				}
			}
			transition to: in_use_packages when: location=target {}
			exit{
				if autonomousBikeEventLog {ask eventLogger { do logExitState("Picked up " + myself.delivery); }}
			}
	}
	
	state in_use_people {
		enter {
			target <- (road closest_to rider.final_destination).location;
			autonomousBike_distance_D_people <- target distance_to location;
			autonomousBike_total_emissions_people <- autonomousBike_total_emissions_people + autonomousBike_distance_D_people*autonomousBikeCO2Emissions;
			autonomousBike_total_emissions <- autonomousBike_total_emissions + autonomousBike_total_emissions_people;
			if autonomousBikeEventLog {
				ask eventLogger { do logEnterState("In Use " + myself.rider); }
				ask travelLogger { do logRoads(autonomousBike_distance_D_people);}
			}
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
			target <- (road closest_to delivery.final_destination).location;  
			autonomousBike_distance_D_package <- target distance_to location;
			autonomousBike_total_emissions_package <- autonomousBike_total_emissions_package + autonomousBike_distance_D_package*autonomousBikeCO2Emissions;
			autonomousBike_total_emissions <- autonomousBike_total_emissions + autonomousBike_total_emissions_package;
			if autonomousBikeEventLog {
				ask eventLogger { do logEnterState("In Use " + myself.delivery); }
				ask travelLogger { do logRoads(autonomousBike_distance_D_package);}
			}
		}
		transition to: wandering when: location=target {
			delivery <- nil;
		}
		exit {
			if autonomousBikeEventLog {ask eventLogger { do logExitState("Used" + myself.delivery); }}
		}
	}
}

species docklessBike control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#gamablue,
		"blocked"::#gamablue,
		"in_use_people"::#gamablue
	];
	
	aspect realistic {
		color <- color_map[state];
		draw triangle(25) color:color border:color rotate: heading + 90 ;
	} 

	docklessBikeLogger_roadsTraveled travelLogger;
	docklessBikeLogger_event eventLogger;
	    
	/* ========================================== PUBLIC FUNCTIONS ========================================= */

	people rider;
	
	list<string> rideStates <- ["wandering"]; //This defines in which state the bikes have to be to be available for a ride
	bool lowPass <- false;

	bool availableForRideDB {
		return (state in rideStates) and self.state="wandering" and rider=nil and docklessBikesInUse=true;
	}
	
	action pickUpRider(people person){
		rider <- person;
	}
	/* ========================================== PRIVATE FUNCTIONS ========================================= */

	point target;
	
	path travelledPath;
	
	bool canMove {
		return ((target != nil and target != location));
	}
		
	path moveTowardTarget {
		if (state="in_use_people"){return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeedDocklessBike);}
		return goto(on:roadNetwork, target:self.location, return_path: true, speed:0.0);
	}
	
	reflex move when: canMove() {
		
		travelledPath <- moveTowardTarget();
		
		float distanceTraveled <- host.distanceInGraph(travelledPath.source,travelledPath.target);
	}
				
	state wandering initial: true {
		enter {
			if docklessBikeEventLog {
				ask eventLogger { do logEnterState; }
				ask travelLogger { do logRoads(0.0);}
			}
			target <- nil;
		}
		transition to: blocked when: rider != nil{}
		exit {
			if docklessBikeEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state blocked {
		enter {
			if docklessBikeEventLog {
				ask eventLogger { do logEnterState("Blocked for " + myself.rider); }
				ask travelLogger { do logRoads(0.0);}
			}
		}
		transition to: in_use_people when: location=rider.location {}
		exit{
			if docklessBikeEventLog {ask eventLogger { do logExitState("Blocked for " + myself.rider); }}
		}
	}
	
	state in_use_people {
		enter {
			target <- road closest_to rider.final_destination.location;
			docklessBike_trips_count_DP <- docklessBike_trips_count_DP + 1;
			docklessBike_distance_DP <- target distance_to location;
			docklessBike_total_emissions <- docklessBike_total_emissions + docklessBike_distance_DP*docklessBikeCO2Emissions;
			if docklessBikeEventLog {
				ask eventLogger { do logEnterState("In Use " + myself.rider); }
				ask travelLogger { do logRoads(docklessBike_distance_DP);}
			}	
		}
		transition to: wandering when: location=target {
			rider <- nil;
		}
		exit {
			if docklessBikeEventLog {ask eventLogger { do logExitState("Used" + myself.rider); }}
		}
	}
}

species scooter control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#turquoise,
		"low_battery"::#red,
		"picking_up_packages"::#turquoise,
		"in_use_packages"::#turquoise
	];
	
	aspect realistic {
		color <- color_map[state];
		draw rectangle(25,10) color:color border:color rotate: heading + 90 ;
	} 

	//loggers
	scooterLogger_roadsTraveled travelLogger;
	scooterLogger_event eventLogger;
	    
	/* ========================================== PUBLIC FUNCTIONS ========================================= */
	// these are how other agents interact with this one. Not used by self

	package delivery;
	
	list<string> rideStates <- ["wandering"]; //This defines in which state the bikes have to be to be available for a ride
	bool lowPass <- false;

	bool availableForRideS {
		return (state in rideStates) and self.state="wandering" and !setLowBattery() and delivery=nil and scootersInUse=true;
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
						
		do reduceBattery(distanceTraveled);
	}
				
	/* ========================================== STATE MACHINE ========================================= */
	state wandering initial: true {
		enter {
			if scooterEventLog {
				ask eventLogger { do logEnterState; }
				ask travelLogger { do logRoads(0.0);}
			}
			target <- nil;		
		}
		transition to: picking_up_packages when: delivery != nil{}
		transition to: low_battery when: setLowBattery() {}
		exit {
			if scooterEventLog {ask eventLogger { do logExitState("Ended wandering "); }}
		}
	}
	
	state low_battery {
		//seek either a charging station or another vehicle
		enter{
			if scooterEventLog {
				ask eventLogger { do logEnterState(myself.state); }
				ask travelLogger { do logRoads(0.0);}
			}		
		}
		exit {
			if scooterEventLog {ask eventLogger { do logExitState("Low battery set"); }}
		}
	}
	
	state picking_up_packages {
		enter {
			scooter_trips_count_PUP <- scooter_trips_count_PUP + 1;
			scooter_distance_PUP <- delivery.location distance_to location;
			scooter_total_emissions <- scooter_total_emissions + scooter_distance_PUP*scooterCO2Emissions;
			if scooterEventLog {
				ask eventLogger { do logEnterState("Picking up " + myself.delivery);}
				ask travelLogger { do logRoads(scooter_distance_PUP);}
			}
			target <- delivery.location; 	
		}
		transition to: in_use_packages when: location=target {}
		exit{
			if scooterEventLog {ask eventLogger { do logExitState("Picked up " + myself.delivery); }}
		}
	}
	
	state in_use_packages {
		enter {
			target <- road closest_to delivery.final_destination.location;  
			scooter_distance_D <- delivery.final_destination.location distance_to location;
			scooter_total_emissions <- scooter_total_emissions + scooter_distance_D*scooterCO2Emissions;
			if scooterEventLog {
				ask eventLogger { do logEnterState("In use " + myself.delivery); }
				ask travelLogger { do logRoads(scooter_distance_D);}
			}
		}
		transition to: wandering when: location=target {
			delivery <- nil;
		}
		exit {
			if scooterEventLog {ask eventLogger { do logExitState("Used " + myself.delivery); }}
		}
	}
}

species eBike control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#green,
		"low_battery"::#red,
		"picking_up_packages"::#green,
		"in_use_packages"::#green
	];
	
	aspect realistic {
		color <- color_map[state];
		draw triangle(25,10) color:color border:color rotate: heading + 90 ;
	} 

	//loggers
	eBikeLogger_roadsTraveled travelLogger;
	eBikeLogger_event eventLogger;
	    
	/* ========================================== PUBLIC FUNCTIONS ========================================= */
	// these are how other agents interact with this one. Not used by self

	package delivery;
	
	list<string> rideStates <- ["wandering"]; //This defines in which state the bikes have to be to be available for a ride
	bool lowPass <- false;

	bool availableForRideEB {
		return (state in rideStates) and self.state="wandering" and !setLowBattery() and delivery=nil and eBikesInUse=true;
	}
	
	action pickUpPackage(package pack){
		delivery <- pack;
	}
	
	/* ========================================== PRIVATE FUNCTIONS ========================================= */
	// no other species should touch these
	
	//----------------BATTERY-----------------
	
	bool setLowBattery { //Determines when to move into the low_battery state
		
		if batteryLife < minSafeBatteryEBike { return true; } 
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
	
	float batteryLife min: 0.0 max: maxBatteryLifeEBike; //Number of meters we can travel on current battery
	float distancePerCycle;
	
	path travelledPath; //preallocation. Only used within the moveTowardTarget reflex
	
	bool canMove {
		return ((target != nil and target != location)) and batteryLife > 0;
	}
		
	path moveTowardTarget {
		if (state="in_use_packages"){return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeedEBike);}
		return goto(on:roadNetwork, target:target, return_path: true, speed:PickUpSpeedEBike);
	}
	
	reflex move when: canMove() {
		
		travelledPath <- moveTowardTarget();
		
		float distanceTraveled <- host.distanceInGraph(travelledPath.source,travelledPath.target);
						
		do reduceBattery(distanceTraveled);
	}
				
	/* ========================================== STATE MACHINE ========================================= */
	state wandering initial: true {
		enter {
			if eBikeEventLog {
				ask eventLogger { do logEnterState; }
				ask travelLogger { do logRoads(0.0);}
			}			
			target <- nil;
		}
		transition to: picking_up_packages when: delivery != nil{}
		transition to: low_battery when: setLowBattery() {}
		exit {
			if eBikeEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state low_battery {
		//seek either a charging station or another vehicle
		enter{
			if eBikeEventLog {
				ask eventLogger { do logEnterState(myself.state); }
				ask travelLogger { do logRoads(0.0);}
			}
		}
		exit {
			if eBikeEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state picking_up_packages {
		enter {
			eBike_trips_count_PUP <- eBike_trips_count_PUP + 1;
			eBike_distance_PUP <- delivery.location distance_to location;
			eBike_total_emissions <- eBike_total_emissions + eBike_distance_PUP*eBikeCO2Emissions;
			if eBikeEventLog {
				ask eventLogger { do logEnterState("Picking up " + myself.delivery); }
				ask travelLogger { do logRoads(eBike_distance_PUP);}
			}
			target <- delivery.location;
		}
		transition to: in_use_packages when: location=target {}
		exit{
			if eBikeEventLog {ask eventLogger { do logExitState("Picked up " + myself.delivery); }}
		}
	}
	
	state in_use_packages {
		enter {
			target <- road closest_to delivery.final_destination.location;  
			eBike_distance_D <- delivery.final_destination.location distance_to location;
			eBike_total_emissions <- eBike_total_emissions + eBike_distance_D*eBikeCO2Emissions;
			if eBikeEventLog {
				ask eventLogger { do logEnterState("In Use " + myself.delivery); }
				ask travelLogger { do logRoads(eBike_distance_D);}
			}
		}
		transition to: wandering when: location=target {
			delivery <- nil;
		}
		exit {
			if eBikeEventLog {ask eventLogger { do logExitState("Used" + myself.delivery); }}
		}
	}
}

species conventionalBike control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#brown,
		"picking_up_packages"::#brown,
		"in_use_packages"::#brown
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
		return (state in rideStates) and self.state="wandering" and delivery=nil and conventionalBikesInUse=true;
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
	}
				
	state wandering initial: true {
		enter {
			if conventionalBikesEventLog {
				ask eventLogger { do logEnterState; }
				ask travelLogger { do logRoads(0.0);}
			}
			target <- nil;
		}
		transition to: picking_up_packages when: delivery != nil{}
		exit {
			if conventionalBikesEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state picking_up_packages {
		enter {
			target <- delivery.location; 
			conventionalBike_trips_count_PUP <- conventionalBike_trips_count_PUP + 1;
			conventionalBike_distance_PUP <- target distance_to location;
			conventionalBike_total_emissions <- conventionalBike_total_emissions + conventionalBike_distance_PUP*conventionalBikeCO2Emissions;		
			if conventionalBikesEventLog {
				ask eventLogger { do logEnterState("Picking up " + myself.delivery); }
				ask travelLogger { do logRoads(conventionalBike_distance_PUP);}
			}
		}
		transition to: in_use_packages when: location=target {}
		exit{
			if conventionalBikesEventLog {ask eventLogger { do logExitState("Picked up " + myself.delivery); }}
		}
	}
	
	state in_use_packages {
		enter {
			target <- road closest_to delivery.final_destination.location;  
			conventionalBike_distance_D <- target distance_to location;
			conventionalBike_total_emissions <- conventionalBike_total_emissions + conventionalBike_distance_D*conventionalBikeCO2Emissions;
			if conventionalBikesEventLog {
				ask eventLogger { do logEnterState("In Use " + myself.delivery); }
				ask travelLogger { do logRoads(conventionalBike_distance_D);}
			}
		}
		transition to: wandering when: location=target {
			delivery <- nil;
		}
		exit {
			if conventionalBikesEventLog {ask eventLogger { do logExitState("Used" + myself.delivery); }}
		}
	}
}

species car control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#gray,
		"low_battery"::#red,
		"picking_up_packages"::#gray,
		"in_use_packages"::#gray
	];
	
	aspect realistic {
		color <- color_map[state];
		draw rectangle(25,10) color:color border:color rotate: heading + 90 ;
	} 

	//loggers
	carLogger_roadsTraveled travelLogger;
	carLogger_event eventLogger;
	    
	/* ========================================== PUBLIC FUNCTIONS ========================================= */
	// these are how other agents interact with this one. Not used by self

	package delivery;
	
	list<string> rideStates <- ["wandering"]; //This defines in which state the bikes have to be to be available for a ride
	bool lowPass <- false;

	bool availableForRideC {
		return (state in rideStates) and self.state="wandering" and !setLowBattery() and delivery=nil and carsInUse=true;
	}
	
	action pickUpPackage(package pack){
		delivery <- pack;
	}
	
	/* ========================================== PRIVATE FUNCTIONS ========================================= */
	// no other species should touch these
	
	//----------------BATTERY-----------------
	
	bool setLowBattery { //Determines when to move into the low_battery state
		
		if batteryLife < minSafeBatteryCar { return true; } 
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
	
	float batteryLife min: 0.0 max: maxBatteryLifeCar; //Number of meters we can travel on current battery
	float distancePerCycle;
	
	path travelledPath; //preallocation. Only used within the moveTowardTarget reflex
	
	bool canMove {
		return ((target != nil and target != location)) and batteryLife > 0;
	}
		
	path moveTowardTarget {
		if (state="in_use_packages"){return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeedCar);}
		return goto(on:roadNetwork, target:target, return_path: true, speed:PickUpSpeedCar);
	}
	
	reflex move when: canMove() {
		
		travelledPath <- moveTowardTarget();
		
		float distanceTraveled <- host.distanceInGraph(travelledPath.source,travelledPath.target);
						
		do reduceBattery(distanceTraveled);
	}
				
	/* ========================================== STATE MACHINE ========================================= */
	state wandering initial: true {
		enter {
			if carEventLog {
				ask eventLogger { do logEnterState; }
				ask travelLogger { do logRoads(0.0);}
			}
			target <- nil;
		}
		transition to: picking_up_packages when: delivery != nil{}
		transition to: low_battery when: setLowBattery() {}
		exit {
			if carEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state low_battery {
		//seek either a charging station or another vehicle
		enter{
			if carEventLog {
				ask eventLogger { do logEnterState(myself.state); }
				ask travelLogger { do logRoads(0.0);}
			}
		}
		exit {
			if carEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state picking_up_packages {
		enter {
			car_trips_count_PUP <- car_trips_count_PUP + 1;
			car_distance_PUP <- delivery.location distance_to location;
			car_total_emissions <- car_total_emissions + car_distance_PUP*carCO2Emissions;
			if carEventLog {
				ask eventLogger { do logEnterState("Picking up " + myself.delivery); }
				ask travelLogger { do logRoads(car_distance_PUP);}
			}
			target <- delivery.location; 	
		}
		transition to: in_use_packages when: location=target {}
		exit{
			if carEventLog {ask eventLogger { do logExitState("Picked up " + myself.delivery); }}
		}
	}
	
	state in_use_packages {
		enter {
			car_distance_D <- delivery.final_destination.location distance_to location;
			car_total_emissions <- car_total_emissions + car_distance_D*carCO2Emissions;
			if carEventLog {
				ask eventLogger { do logEnterState("In Use " + myself.delivery); }
				ask travelLogger { do logRoads(car_distance_D);}
			}
			target <- road closest_to delivery.final_destination.location;  
		}
		transition to: wandering when: location=target {
			delivery <- nil;
		}
		exit {
			if carEventLog {ask eventLogger { do logExitState("Used" + myself.delivery); }}
		}
	}
}

/*grid gridHeatmaps height: 50 width: 50 {
	int pollution_level <- 0 ;
	int density<-0;
	rgb pollution_color <- rgb(pollution_level*10,0,0) update:rgb(pollution_level*10,0,0);
	
	aspect pollution{
		draw shape color:pollution_color;
	}
}*/