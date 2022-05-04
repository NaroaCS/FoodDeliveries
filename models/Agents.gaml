model Agents

import "./main.gaml"


global {

	float distanceInGraph (point origin, point destination) {
		//using topology(roadNetwork) {
			//return origin distance_to destination;
		//}
		return origin distance_to destination;	
	}
	list<bike> availableBikes(people person) {
		return bike where (each.availableForRide());
	}


	bool requestBike(people person, point destination) { //returns true if there is any bike available

		list<bike> available <- availableBikes(person);
		if empty(available) {
			return false;
		}
		/*list<bike> candidates <- available where (each::bikeClose(person, each));
		if empty(candidates) {
			return false;
		}*/
		
		bike b <- available closest_to(person);
		
		if !bikeClose(person,b){
			return false;
		}
		//list<bike> candidates <- available closest_to(person,5);
		
		/*map<bike, float> costs <- map( candidates collect(each::bikeCost(person, each)));
		float minCost <- min(costs.values);
		bike b <- costs.keys[ costs.values index_of minCost ];*/
		
		//Ask for pickup
		ask b {
			do pickUp(person);
		}
		ask person {
			do ride(b);
		}
		
		return true;
	}

	
	bool bikeClose(people person, bike b){
		float d <- distanceInGraph(b.location,person.location);
		//float d <- person distance_to b;
		//write "Time "+ current_date +"bike "+ b.name+ " distance to "+ person.name + ": "+d+ " < "+ maxDistance;
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
}


species intersection {
	int id;	
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
		
		transition to: walking when: host.requestBike(self, final_destination) {
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
		"in_use"::#gamagreen
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
	
	list<string> rideStates <- ["wandering"]; //This defines in which state the bikes have to be to be available for a ride
	bool lowPass <- false;

	bool availableForRide {
		return (state in rideStates) and !setLowBattery() and rider = nil;
	}

	
	action pickUp(people person) { 
		//transition from wander to picking_up. Called by the global scheduler
		rider <- person;
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
		batteryLife <- batteryLife - energyCost(distance); // TODO: Review this, it wasn't active
   
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
		if (state="in_use"){return goto(on:roadNetwork, target:target, return_path: true, speed:RidingSpeed);}
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
		transition to: low_battery when: setLowBattery() {}
		exit {
			ask eventLogger { do logExitState; }
		}
		//Wandering is handled by the move reflex
	}
	
	state low_battery {
		//seek either a charging station or another vehicle
		enter{
			ask eventLogger { do logEnterState(myself.state); }
			target <- (chargingStation closest_to(self)).location; //
			//lastTag.nearestChargingStation.location; //// TODO: Review if it works
		}
		transition to: getting_charge when: self.location = target {}
		exit {
			ask eventLogger { do logExitState; }
		}
		
		//Movement is handled by the move reflex
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
		
		//charging station will reflexively add power to this bike
	}
			
	//BIKE - PEOPLE
	state picking_up {
		//go to rider's location, pick them up
		enter {
			if bikeEventLog {ask eventLogger { do logEnterState("Picking up " + myself.rider); }}
			target <- rider.closestIntersection; //Go to the rider's closest intersection
		}
		
		transition to: in_use when: location=target and rider.location=target {}
		exit{
			ask eventLogger { do logExitState("Picked up " + myself.rider); }
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
}
