model Agents

import "./main.gaml"

global {
	
	float distanceInGraph (point origin, point destination) {
		return (origin distance_to destination using topology(road));	
	}
	
	int numCars;
	int coefficient;
	
	bool autonomousBikesInUse;
	bool carsInUse;
	
	int numGasStations;
	int gasStationCapacity;

	list<autonomousBike> availableAutonomousBikes(package delivery) {
		if traditionalScenario{
			autonomousBikesInUse <- false;
		} else {
			autonomousBikesInUse <- true;
		}
		return autonomousBike where (each.availableForRideAB());
	}
	
	list<car> availableCars(package delivery) {
		if traditionalScenario{
			carsInUse <- true;
		} else {
			carsInUse <- false;
		}
		return car where (each.availableForRideC());
	}
		
	float autonomousBike_distance <- 0.0;
	
	float car_distance <- 0.0;
		
	int requestDeliveryMode(package delivery) {
    	
    	float dab_0; 
    	float dab_1; 
    	float dab_difference;
    	float bab_0; 
    	float bab_1;
    	float bab_difference;
    	float ratio_0 <- 1.0;
    	float ratio;
		float dc;
		float mindistance;
		int choice <- 0;
		int lengthlist <- 0;
		float tripDistance;
    	
		list<autonomousBike> availableAB <- availableAutonomousBikes(delivery);		
		list<car> availableC <- availableCars (delivery);
	
		if !traditionalScenario {
			if empty(availableAB) {
				choice <- 0;
			} else if !empty(availableAB) and delivery != nil{		
				
				// With battery life in decision
				list<autonomousBike> closestAB <- availableAB closest_to(delivery.initial_closestPoint,5) using topology(road);
				autonomousBike ab <- closestAB[0];
				lengthlist <- length(closestAB);
				
				dab_0 <- closestAB[0] distance_to delivery.initial_closestPoint using topology(road);
				bab_0 <- closestAB[0].batteryLife;
				
				if lengthlist >= 2{
					loop i from: 1 to: (length(closestAB)-1) {
						if ((closestAB[i].batteryLife > ab.batteryLife)){
							dab_1 <- (closestAB[i] distance_to delivery.initial_closestPoint using topology(road));
							dab_difference <- dab_1 - dab_0;
							bab_1 <- closestAB[i].batteryLife;
							bab_difference <- bab_1 - bab_0;
							if dab_difference != 0{
								ratio <- bab_difference/dab_difference;
								if ((bab_difference > coefficient*dab_difference) and (dab_difference<1000) and (ratio>ratio_0)){
									ab <- closestAB[i];
									ratio_0 <- ratio;
								}
							} else {
								bab_0 <- closestAB[i].batteryLife;
								ab <- closestAB[i];
							}
						}
					}
				}
				
				tripDistance <- distanceInGraph(ab.location,delivery.initial_closestPoint) + distanceInGraph(delivery.initial_closestPoint,delivery.final_closestPoint);
				if tripDistance < ab.batteryLife {
					ab.delivery <- delivery;
					ask ab {			
						do pickUp(delivery);
					}
					ask delivery {
						do deliver_ab(ab);
					}
					choice <- 1;
				} else {
					choice <- 0;
				}
				
				
				// Without battery life in decision
				/*autonomousBike b <- availableAB closest_to(delivery.initial_closestPoint) using topology(road);
				tripDistance <- distanceInGraph(b.location,delivery.initial_closestPoint) + distanceInGraph(delivery.initial_closestPoint,delivery.final_closestPoint);
				
				if tripDistance < b.batteryLife {
					b.delivery <- delivery;
					ask b {			
						do pickUp(delivery);
					}
					ask delivery {
						do deliver_ab(b);
					}
					choice <- 1;
				} else {
					choice <- 0;
				}*/
				
			} else {
				choice <- 0;
			}
		} else if traditionalScenario {
			if empty(availableC) {
				choice <- 0;
			} else if !empty(availableC) and delivery != nil{
				
				car c <- availableC closest_to(delivery.initial_closestPoint) using topology(road);
				tripDistance <- distanceInGraph(c.location,delivery.initial_closestPoint) + distanceInGraph(delivery.initial_closestPoint,delivery.final_closestPoint);
				if tripDistance < c.fuel{
					c.delivery <- delivery;
					ask c {			
						do pickUpPackage(delivery);
					}
					ask delivery {
						do deliver_c(c);
					}
					choice <- 2;
				} else {
					choice <- 0;
				}
			} else {
				choice <- 0;
			}
		}
		return choice;	
    }
}
	
species road {
	aspect base {
		draw shape color: rgb(125, 125, 125);
	}
}

species building {
    aspect type {
		draw shape color: color_map_2[type]-75 ;
	}
	string type; 
}

species chargingStation{
	
	list<autonomousBike> autonomousBikesToCharge;
	
	rgb color <- #deeppink;
	
	float lat;
	float lon;
	int capacity;
	
	aspect base{
		draw hexagon(25,25) color:color border:#black;
	}
	
	reflex chargeBikes {
		ask capacity first autonomousBikesToCharge {
			batteryLife <- batteryLife + step*V2IChargingRate;
		}
	}
}

species restaurant{
	
	rgb color <- #sandybrown;
	
	float lat;
	float lon;
	point rest;
	
	aspect base{
		draw circle(10) color:color;
	}
}

species gasstation{
	
	rgb color <- #hotpink;
	
	list<car> carsToRefill;
	float lat;
	float lon;
	int capacity;
	
	aspect base{
		draw circle(30) color:color border:#black;
	}
	reflex refillCars {
		ask gasStationCapacity first carsToRefill {
			fuel <- fuel + step*refillingRate;
		}
	}	
}

/*species intersection{
	int id;
	aspect base{
		draw circle(10) color:#purple border:#black;
	}
}*/

species package control: fsm skills: [moving] {

	rgb color;
	
    map<string, rgb> color_map <- [
    	
    	"generated":: #transparent,
    	
    	"firstmile":: #lightsteelblue,
    	
    	"requestingDeliveryMode"::#red,
    	
		"awaiting_autonomousBike":: #yellow,
		"awaiting_car":: #palevioletred,
		
		"delivering_autonomousBike":: #yellow,
		"delivering_car"::#cyan,
		
		"lastmile"::#lightsteelblue,
		
		"retry":: #red,
		
		"delivered":: #transparent
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
	int mode; // 1 <- Autonomous Bike || 2 <- Car || 0 <- None
	
	autonomousBike autonomousBikeToDeliver;
	car carToDeliver;
	
	point final_destination; 
    point target; 
    point initial_closestPoint;
    point final_closestPoint;
    point closestPoint;
    float waitTime;
    float tripdistance;
    int choice;
        
	aspect base {
    	color <- color_map[state];
    	draw square(15) color: color border: #black;
    }
    
	action deliver_ab(autonomousBike ab){
		autonomousBikeToDeliver <- ab;
	}
	
	action deliver_c(car c){
		carToDeliver <- c;
	}
		
	bool timeToTravel { return ((current_date.hour = start_h and current_date.minute >= start_min) or (current_date.hour > start_h)) and !(self overlaps target_point); }
	
	int register <- 1;
	
	state generated initial: true {
    	
    	enter {    		
    		if register = 1 and (packageEventLog or packageTripLog) {ask logger { do logEnterState;}}
    		target <- nil;
    	}
    	transition to: requestingDeliveryMode when: timeToTravel() {
    		final_destination <- target_point;
    	}
    	exit {
			if register = 1 and (packageEventLog) {ask logger { do logExitState; }}
		}
    }
    
    state requestingDeliveryMode {
    	
    	enter {
    		target <- self.initial_closestPoint;
    		if register = 1 and (packageEventLog or packageTripLog) {ask logger { do logEnterState; }}    		
    		choice <- host.requestDeliveryMode(self);
    		if choice = 0 {
    			register <- 0;
    		} else {
    			register <- 1;
    		}
    	}
    	transition to: firstmile when: (choice != 0){}
    	transition to: retry when: choice = 0 {target <- nil;}
    	exit {
    		if register = 1 and packageEventLog {ask logger { do logExitState; }}
		}
    }
    
    state retry {
    	transition to: requestingDeliveryMode when: timeToTravel() {target <- nil;}
    }
	
	state firstmile {
		enter{
			if packageEventLog or packageTripLog {ask logger{ do logEnterState;}}
		}
		transition to: awaiting_autonomousBike when: choice = 1 and location = target{mode <- 1;}
		transition to: awaiting_car when: choice = 2 and location = target{mode <- 2;}
		exit {
			if packageEventLog {ask logger{do logExitState;}}
		}
		do goto target: target on: roadNetwork;
	}
	
	state awaiting_autonomousBike{
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "awaiting " + string(myself.autonomousBikeToDeliver) ); }}
		}
		transition to: delivering_autonomousBike when: autonomousBikeToDeliver.state = "in_use_packages" {target <- nil;}
		exit {
			if packageEventLog {ask logger { do logExitState; }}
		}
	}
	
	state awaiting_car {
		enter {
			if packageEventLog or packageTripLog {ask logger { do logEnterState( "awaiting " + string(myself.carToDeliver) ); }}
		}
		transition to: delivering_car when: carToDeliver.state = "in_use_packages" {target <- nil;}
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
		transition to: delivered when: location = target{}
		exit {
			if packageEventLog {ask logger{do logExitState;}}
		}
		do goto target: target on: roadNetwork;
	}
	
	state delivered {
		enter{
			tripdistance <- (self.start_point distance_to self.initial_closestPoint) + host.distanceInGraph(self.initial_closestPoint,self.final_closestPoint) + (self.final_closestPoint distance_to target_point);
			if packageEventLog or packageTripLog {ask logger{ do logEnterState;}}
		}
	}
}

species autonomousBike control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#transparent,
		
		"low_battery":: #red,
		"night_recharging":: #orangered,
		"getting_charge":: #red,
		"getting_night_charge":: #orangered,
		"night_relocating":: #springgreen,
		
		"picking_up_packages"::#mediumorchid,
		"in_use_packages"::#gold
	];
	
	aspect realistic {
		color <- color_map[state];
		draw triangle(35) color:color border:color rotate: heading + 90 ;
	} 

	autonomousBikeLogger_roadsTraveled travelLogger;
	autonomousBikeLogger_chargeEvents chargeLogger;
	autonomousBikeLogger_event eventLogger;
	    
	/* ========================================== PUBLIC FUNCTIONS ========================================= */
	
	package delivery;
	
	list<string> rideStates <- ["wandering"]; 
	bool lowPass <- false;

	bool availableForRideAB {
		return (state in rideStates) and self.state="wandering" and !setLowBattery() and delivery = nil and autonomousBikesInUse=true;
	}
	
	action pickUp(package pack) { 
		if pack !=nil {
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
	bool setNightChargingTime { 
		if (batteryLife < nightSafeBatteryAutonomousBike) and (current_date.hour>=2) and (current_date.hour<5){ return true; } 
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
	point nightorigin;
	point origin_closestPoint;
		
	float batteryLife min: 0.0 max: maxBatteryLifeAutonomousBike; 
	float distancePerCycle;
	
	path travelledPath; 
	path Path;
	
	
	bool canMove {
		return ((target != nil and target != location)) and batteryLife > 0;
	}
		
	path moveTowardTarget {
		if (state="in_use_packages"){return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeedAutonomousBike);}
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
		transition to: picking_up_packages when: delivery != nil{}
		transition to: low_battery when: setLowBattery() {}
		transition to: night_recharging when: setNightChargingTime() {nightorigin <- self.location;}
		exit {
			if autonomousBikeEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state low_battery {
		enter{
			target <- (chargingStation closest_to(self) using topology(road)).location; 
			point target_closestPoint <- (road closest_to(target) using topology(road)).location;
			autonomousBike_distance <- host.distanceInGraph(target_closestPoint,self.location);
			if autonomousBikeEventLog {
				ask eventLogger { do logEnterState(myself.state); }
				ask travelLogger { do logRoads(autonomousBike_distance);}
			}
		}
		transition to: getting_charge when: self.location = target {}
		exit {
			if autonomousBikeEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state night_recharging {
		enter{
			target <- (chargingStation closest_to(self) using topology(road)).location; 
			point target_closestPoint <- (road closest_to(target) using topology(road)).location;
			autonomousBike_distance <- host.distanceInGraph(target_closestPoint,self.location);
			if autonomousBikeEventLog {
				ask eventLogger { do logEnterState(myself.state); }
				ask travelLogger { do logRoads(autonomousBike_distance);}
			}
		}
		transition to: getting_night_charge when: self.location = target {}
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
	
	state getting_night_charge {
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
		transition to: night_relocating when: batteryLife >= maxBatteryLifeAutonomousBike {}
		exit {
			if stationChargeLogs{ask eventLogger { do logExitState("Charged at " + (chargingStation closest_to myself)); }}
			ask chargingStation closest_to(self) {
				autonomousBikesToCharge <- autonomousBikesToCharge - myself;
			}
		}
	}
	
	state night_relocating {
		enter {
			target <- nightorigin;
			origin_closestPoint <- (road closest_to(self.location) using topology(road)).location;
			autonomousBike_distance <- host.distanceInGraph(target,origin_closestPoint);
			if autonomousBikeEventLog {
				ask eventLogger { do logEnterState(myself.state); }
				ask travelLogger { do logRoads(autonomousBike_distance);}
			}
		}
		transition to: wandering when: self.location = target {}
		exit {
			if autonomousBikeEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state picking_up_packages {
			enter {
				target <- delivery.initial_closestPoint;
				autonomousBike_distance <- host.distanceInGraph(target,self.location);
				if autonomousBikeEventLog {
					ask eventLogger { do logEnterState("Picking up " + myself.delivery); }
					ask travelLogger { do logRoads(autonomousBike_distance);}
				}
			}
			transition to: in_use_packages when: (location = target and delivery.location = target) {}
			exit{
				if autonomousBikeEventLog {ask eventLogger { do logExitState("Picked up " + myself.delivery); }}
			}
	}
	
	state in_use_packages {
		enter {
			target <- delivery.final_closestPoint;  
			autonomousBike_distance <- host.distanceInGraph(target,self.location);
			if autonomousBikeEventLog {
				ask eventLogger { do logEnterState("In Use " + myself.delivery); }
				ask travelLogger { do logRoads(autonomousBike_distance);}
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

species car control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#transparent,
		
		"low_fuel"::#red,
		"night_refilling"::#orangered,
		"getting_fuel"::#pink,
		"getting_night_fuel"::#orangered,
		"night_relocating"::#orangered,
		
		"picking_up_packages"::#indianred,
		"in_use_packages"::#cyan
	];
	
	aspect realistic {
		color <- color_map[state];
		draw triangle(35) color:color border:color rotate: heading + 90 ;
	} 

	carLogger_roadsTraveled travelLogger;
	carLogger_fuelEvents fuelLogger;
	carLogger_event eventLogger;
	    
	/* ========================================== PUBLIC FUNCTIONS ========================================= */
	// these are how other agents interact with this one. Not used by self

	package delivery;
	
	list<string> rideStates <- ["wandering"]; //This defines in which state the cars have to be to be available for a ride
	bool lowPass <- false;

	bool availableForRideC {
		return (state in rideStates) and self.state="wandering" and !setLowFuel() and delivery=nil and carsInUse=true;
	}
	
	action pickUpPackage(package pack){
		delivery <- pack;
	}
	
	/* ========================================== PRIVATE FUNCTIONS ========================================= */	
	//----------------BATTERY-----------------
	
	bool setLowFuel { //Determines when to move into the low_fuel state
		if fuel < minSafeFuelCar { return true; } 
		else {
			return false;
		}
	}
	bool setNightRefillingTime { 
		if (fuel < nightSafeFuelCar) and (current_date.hour >= 2) and (current_date.hour < 5){ return true; } 
		else {
			return false;
		}
	}
	float energyCost(float distance) {
		return distance;
	}
	action reduceFuel(float distance) {
		fuel <- fuel - energyCost(distance); 
	}
	//----------------MOVEMENT-----------------
	point target;
	point nightorigin;
	
	float fuel min: 0.0 max: maxFuelCar; //Number of meters we can travel on current fuel
	float distancePerCycle;
	
	path travelledPath; //preallocation. Only used within the moveTowardTarget reflex
	
	bool canMove {
		return ((target != nil and target != location)) and fuel > 0;
	}
		
	path moveTowardTarget {
		if (state="in_use_packages"){return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeedCar);}
		return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeedCar);
	}
	
	reflex move when: canMove() {
		
		travelledPath <- moveTowardTarget();
		
		float distanceTraveled <- host.distanceInGraph(travelledPath.source,travelledPath.target);
						
		do reduceFuel(distanceTraveled);
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
		transition to: low_fuel when: setLowFuel() {}
		/*transition to: night_refilling when: setNightRefillingTime() {nightorigin <- self.location;}*/
		exit {
			if carEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	state low_fuel {
		enter{
			target <- (gasstation closest_to(self) using topology(road)).location;
			point target_closestPoint <- (road closest_to(target) using topology(road)).location;
			car_distance <- host.distanceInGraph(target_closestPoint,self.location);
			if carEventLog {
				ask eventLogger { do logEnterState(myself.state); }
				ask travelLogger { do logRoads(car_distance);}
			}
		}
		transition to: getting_fuel when: self.location = target {}
		exit {
			if carEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	/*state night_refilling {
		enter{
			target <- (gasstation closest_to(self) using topology(road)).location;
			point target_closestPoint <- (road closest_to(target) using topology(road)).location;
			car_distance <- host.distanceInGraph(target_closestPoint,self.location);			
			if carEventLog {
				ask eventLogger { do logEnterState(myself.state); }
				ask travelLogger { do logRoads(car_distance);}
			}
		}
		transition to: getting_night_fuel when: self.location = target {}
		exit {
			if carEventLog {ask eventLogger { do logExitState; }}
		}
	}*/
	
	state getting_fuel {
		enter {
			if gasstationFuelLogs{
				ask eventLogger { do logEnterState("Refilling at " + (gasstation closest_to myself)); }
				ask travelLogger { do logRoads(0.0);}
			}		
			target <- nil;
			ask gasstation closest_to(self) {
				carsToRefill <- carsToRefill + myself;
			}
		}
		transition to: wandering when: fuel >= maxFuelCar {}
		exit {
			if gasstationFuelLogs{ask eventLogger { do logExitState("Refilled at " + (gasstation closest_to myself)); }}
			ask gasstation closest_to(self) {
				carsToRefill <- carsToRefill - myself;
			}
		}
	}
	
	/*state getting_night_fuel {
		enter {
			if gasstationFuelLogs{
				ask eventLogger { do logEnterState("Refilling at " + (gasstation closest_to myself)); }
				ask travelLogger { do logRoads(0.0);}
			}		
			target <- nil;
			ask gasstation closest_to(self) {
				carsToRefill <- carsToRefill + myself;
			}
		}
		transition to: night_relocating when: fuel >= maxFuelCar {}
		exit {
			if gasstationFuelLogs{ask eventLogger { do logExitState("Refilled at " + (gasstation closest_to myself)); }}
			ask gasstation closest_to(self) {
				carsToRefill <- carsToRefill - myself;
			}
		}
	}
	
	state night_relocating {
		enter{
			target <- nightorigin;
			point origin_closestPoint <- (road closest_to(self.location) using topology(road)).location
			car_distance <- host.distanceInGraph(target,origin_closestPoint);
			if carEventLog {
				ask eventLogger { do logEnterState(myself.state); }
				ask travelLogger { do logRoads(car_distance);}
			}
		}
		transition to: wandering when: self.location = target {}
		exit {
			if carEventLog {ask eventLogger { do logExitState; }}
		}
	}*/
	
	state picking_up_packages {
		enter {
			target <- delivery.initial_closestPoint; 
			car_distance <- host.distanceInGraph(target,self.location);
			if carEventLog {
				ask eventLogger { do logEnterState("Picking up " + myself.delivery); }
				ask travelLogger { do logRoads(car_distance);}
			}
		}
		transition to: in_use_packages when: (location = target and delivery.location = target) {}
		exit{
			if carEventLog {ask eventLogger { do logExitState("Picked up " + myself.delivery); }}
		}
	}
	
	state in_use_packages {
		enter {
			target <- delivery.final_closestPoint; 
			car_distance <- host.distanceInGraph(target,self.location);
			
			if carEventLog {
				ask eventLogger { do logEnterState("In Use " + myself.delivery); }
				ask travelLogger { do logRoads(car_distance);}
			}
		}
		transition to: wandering when: location=target {
			delivery <- nil;
		}
		exit {
			if carEventLog {ask eventLogger { do logExitState("Used " + myself.delivery); }}
		}
	}
}