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
	
	// Initial Scenario
	bool initial_scenario <- traditionalScenario;
		
	//autonomous bike count variables, used to create series graph in autonomous scenarios
	int wanderCount <- 0;
	int lowBattCount <- 0; //lowbattery 
	int getChargeCount <- 0; //getcharge 
	int pickUpCount <- 0;
	int inUseCount <- 0;
	int nightRelCount <- 0;
	int fleetsizeCount <- 0;
	int unservedCount <- 0;
	
	// Initial values storage of the simulation
	int initial_ab_number <- numAutonomousBikes;
	float initial_ab_battery <- maxBatteryLifeAutonomousBike;
	float initial_ab_speed <- PickUpSpeedAutonomousBike;
	string initial_ab_recharge_rate <- rechargeRate;
	
	//car count variables, used to create series graph in traditional scenarios
	int wanderCountCar <- 0;
	int lowFuelCount <- 0; //lowbattery, lowfuel for electric, combustion
	int getFuelCount <- 0; //getcharge, getfuel for electric, combustion
	int pickUpCountCar <- 0;
	int inUseCountCar <- 0;
	int fleetsizeCountCar <- 0;
	
	// Initial car values storaged of the simulation
	int initial_c_number <- numCars;
	float initial_c_battery <- maxFuelCar;
	string initial_c_type <- carType;
	
	// wait time variables, used to create series graph in seeing package wait time progression
	//int lessThanWait <- 0;
	int moreThanWait <- nil;
	float timeWaiting <- 0.0;
	float avgWait <- nil;
	list<float> timeList <- []; //list of wait times
	
	//env factor vars
	float gramsCO2;
	float gramsCO2_1;
	float gramsCO2_2;
	float reductionICE;
	float reductionICE_1;
	float reductionICE_2;
	float reductionBEV;
	float reductionBEV_1;
	float reductionBEV_2;
	
	int initial_hour;
	int initial_minute;
	

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
				if rechargeCond{
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
				} else if !rechargeCond{
				// Without battery life in decision
				autonomousBike b <- availableAB closest_to(delivery.initial_closestPoint) using topology(road);
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
				}
				
			} else {
				choice <- 0;
			}
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
		draw shape color: #black;
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
		"awaiting_car":: #cyan,
		
		"delivering_autonomousBike":: #yellow,
		"delivering_car"::#cyan,
		
		"lastmile"::#lightsteelblue,
		
		"retry":: #red,
		
		"delivered":: #transparent,
		
		"unserved":: #transparent
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
	int start_h_considered;
	int start_min_considered;
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
	
		
	bool timeToTravel { return ((current_date.hour = self.start_h and current_date.minute >= self.start_min) or (current_date.hour > self.start_h)) and !(self overlaps target_point); }
	
	int register <- 1;
	
	state generated initial: true {
    	
    	enter {    		
    		if register = 1 and (packageEventLog or packageTripLog) {ask logger { do logEnterState;}}
    		target <- nil;
    		if start_h < initial_hour {
				start_h_considered <- initial_hour;
				start_min_considered <- initial_minute;
			} else if (start_h = initial_hour) and (start_min < initial_minute){
				start_h_considered <- initial_hour;
				start_min_considered <- initial_minute;
			} else {
				start_h_considered <- start_h;
				start_min_considered <- start_min;			
			}
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
    	transition to: retry when: choice = 0  and ((current_date.hour*60 + current_date.minute) - (start_h_considered*60 + start_min_considered)) <= (maxWaitTimePackage/60) {target <- nil;}
    	//transition to: retry when: choice = 0 {target <- nil;}
    	transition to: unserved when:((current_date.hour*60 + current_date.minute) - (start_h_considered*60 + start_min_considered)) > (maxWaitTimePackage/60) {target <- nil;}
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
			
			/* conditions to keep track of wait time for packages */
			if start_h < initial_hour {
				timeWaiting <- float(current_date.hour*60 + current_date.minute) - (initial_hour*60 + initial_minute);
			} else if (start_h = initial_hour) and (start_min < initial_minute){
				timeWaiting <- float(current_date.hour*60 + current_date.minute) - (initial_hour*60 + initial_minute);
			} else {
				timeWaiting <- float(current_date.hour*60 + current_date.minute) - (start_h*60 + start_min);
			}
			
			/* loop(s) to find moving average of last 10 wait times */
			if length(timeList) = 20{
				remove from:timeList index:0;
			} timeList <- timeList + timeWaiting;
			loop while: length(timeList) = 20{
				moreThanWait <- 0;
				avgWait <- 0.0;
				/* the loop below is to count the number of packages delivered under/over 40 minutes, represented in a pie chart (inactive) */
				loop i over: timeList{
					if i > 40{
						moreThanWait <- moreThanWait+1;
					} 
					avgWait <- avgWait + i;
				} avgWait <- avgWait/20; //average
				return moreThanWait;
			}
		}
	}
	
	state unserved {
		enter {
			unservedCount <- unservedCount + 1;
			write (unservedCount);
		}
	}
}

species autonomousBike control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#transparent,
		
		"low_battery":: #red,
		"night_recharging":: #red,
		"getting_charge":: #red,
		"getting_night_charge":: #red,
		"night_relocating":: #springgreen,
		
		"picking_up_packages"::#gold,
		"in_use_packages"::#gold
	];
	
	aspect realistic {
		color <- color_map[state];
		draw triangle(50) color:color border:color rotate: heading + 90 ;
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
		/* 
	 new state created called fleetsize so we are able to adjust the number of vehicles. if the adjusted number of vehicles (by the user) 
	 is less than the number of vehicles that are active on the map, we kill those excess agents. on the other hand, new agnets are created 
	 if we need more (called in main.gaml)
	 	*/
	state fleetsize initial: true {
		enter {
			if fleetsizeCount+wanderCount+lowBattCount+getChargeCount+nightRelCount+pickUpCount+inUseCount > numAutonomousBikes{
				fleetsizeCount <- fleetsizeCount - 1;
				do die;
			}
			if traditionalScenario {
				fleetsizeCount <- fleetsizeCount - 1;
				do die;
			}
		}
		transition to: wandering {fleetsizeCount <- fleetsizeCount - 1; wanderCount <- wanderCount + 1;} //transition to wandering state, keeping track of the count
	}
	
	state wandering {
		enter {
			if autonomousBikeEventLog {
				ask eventLogger { do logEnterState; }
				ask travelLogger { do logRoads(0.0);}
			}
			
			target <- nil;
		}
		
		/* adjust max battery life */
		if maxBatteryLifeAutonomousBike = 35000.0{
			coefficient <- 21;
			} else if maxBatteryLifeAutonomousBike = 50000.0{
			coefficient <- 30;
			} else if maxBatteryLifeAutonomousBike = 65000.0{
			coefficient <- 39;
		}
		
		// CO2, reduction variables for chart, pie graph
		if maxBatteryLifeAutonomousBike = 35000{
			if rechargeRate = "4.5hours"{
				gramsCO2_1 <- 0.0853*numAutonomousBikes+19.673; //y=0.0853x+19.673	
				reductionICE_1 <- (-0.052033)*numAutonomousBikes+97.8317; //y=−0.052033x+97.8317
				reductionBEV_1 <- (-0.0871)*numAutonomousBikes+96.365; //y=-0​.0871x+96.​365
				gramsCO2_2 <- 0.08773*numAutonomousBikes+18.313; //y=0.08773x+18.313	
				reductionICE_2 <- (-0.0503)*numAutonomousBikes+97.397; //y=−0.0503x+97.397
				reductionBEV_2 <- (-0.0843)*numAutonomousBikes+95.655; //y=-0.​0843x+9​5.655
			} else if rechargeRate = "111s"{
				gramsCO2_1 <- 0.1097*numAutonomousBikes+14.2167; //y=0.1097x+14.2167
				reductionICE_1 <- (-0.0507)*numAutonomousBikes+96.585; //y=−​0.0507x+96.​585
				reductionBEV_1 <- (-0.0793)*numAutonomousBikes+92.325; //y=-0.0​793x+92.3​25
				gramsCO2_2 <- 0.11493*numAutonomousBikes+12.373; //y=0.1​1493x+12.373
				reductionICE_2 <- (-0.0843)*numAutonomousBikes+95.655; //y=-0.​0843x+9​5.655
				reductionBEV_2 <- (-0.071367)*numAutonomousBikes+89.32833; //y=-0.071367x+89.32833
			}
			gramsCO2 <- ((gramsCO2_2-gramsCO2_1)/15.0*PickUpSpeedAutonomousBike*3.6)+(gramsCO2_1-((gramsCO2_2-gramsCO2_1)*5.0/15.0));
			reductionICE <- ((reductionICE_2-reductionICE_1)/15.0*PickUpSpeedAutonomousBike*3.6)+(reductionICE_1-((reductionICE_2-reductionICE_1)*5.0/15.0));
			reductionBEV <- ((reductionBEV_2-reductionBEV_1)/15.0*PickUpSpeedAutonomousBike*3.6)+(reductionBEV_1-((reductionBEV_2-reductionBEV_1)*5.0/15.0));
			
		}
		if maxBatteryLifeAutonomousBike = 65000{
			if rechargeRate = "4.5hours"{
				gramsCO2_1 <- 0.10213*numAutonomousBikes+16.493; //y=0.10213x+16.493
				reductionICE_1 <- (-0.05087)*numAutonomousBikes+96.703; //y=−0.05​087x+96.703​
				reductionBEV_1 <- (-0.085167)*numAutonomousBikes+94.4883; //y=-0.085167x+94.4​883
				gramsCO2_2 <- 0.1029*numAutonomousBikes+16.225; //y=0.1029x+16.225
				reductionICE_2 <- (-0.05073)*numAutonomousBikes+96.6067; //y=−0.​05073x+96.6067
				reductionBEV_2 <- (-0.084933)*numAutonomousBikes+94.31667; //y=-0.084933x+94.31667
			} else if rechargeRate = "111s"{
				gramsCO2_1 <- 0.1218*numAutonomousBikes+14.3; //y=0.1218x+14.3
				reductionICE_1 <- (-0.05193)*numAutonomousBikes+95.3867; //y=−0.05193​x+95.3867
				reductionBEV_1 <- (-0.086967)*numAutonomousBikes+92.27833; //y=-0.08696​7x+92.27​833
				gramsCO2_2 <- 0.12793*numAutonomousBikes+12.153; //y=0.12793x+12.153
				reductionICE_2 <- (-0.0464)*numAutonomousBikes+93.45; //y=-0.04​64x+93.​45
				reductionBEV_2 <- (-0.078433)*numAutonomousBikes+89.07167; //y=-0.078​433x+89.071​67
			}
			gramsCO2 <- ((gramsCO2_2-gramsCO2_1)/15.0*PickUpSpeedAutonomousBike*3.6)+(gramsCO2_1-((gramsCO2_2-gramsCO2_1)*5.0/15.0));
			reductionICE <- ((reductionICE_2-reductionICE_1)/15.0*PickUpSpeedAutonomousBike*3.6)+(reductionICE_1-((reductionICE_2-reductionICE_1)*5.0/15.0));
			reductionBEV <- ((reductionBEV_2-reductionBEV_1)/15.0*PickUpSpeedAutonomousBike*3.6)+(reductionBEV_1-((reductionBEV_2-reductionBEV_1)*5.0/15.0));
		}
		
		/* not using this battery level
		if maxBatteryLifeAutonomousBike = 50000{
			if PickUpSpeedAutonomousBike = 8/3.6{
				if rechargeRate = "4.5hours"{
					gramsCO2 <- 0.090467*numAutonomousBikes+18.94667; //y=0.090​467x+18.94​667
					reductionICE <- (-0.05203)*numAutonomousBikes+97.582; //y=-0.0520​3x+97.582
					reductionBEV <- (-0.087067)*numAutonomousBikes+95.94333; //y=-0.087​067x+95.94333
				} else if rechargeRate = "111s"{
					gramsCO2 <- 0.1158*numAutonomousBikes+14.23; //y=0​.1158x+14.​23
					reductionICE <- (-0.04953)*numAutonomousBikes+95.3767; //y=-0.04953x+95.3767
					reductionBEV <- (-0.0829)*numAutonomousBikes+92.255; //y=-0.​0829x+92​.255
					}
			} else if PickUpSpeedAutonomousBike = 11/3.6{
				if rechargeRate = "4.5hours"{
					gramsCO2 <- 0.09663*numAutonomousBikes+17.3383; //y=0.09663x+17.338​3
					reductionICE <- (-0.0507)*numAutonomousBikes+97.095; //y=-0​.0507x+97.​095
					reductionBEV <- (-0.08487)*numAutonomousBikes+95.1333; //y=-0.084​87x+95.1333
				} else if rechargeRate = "111s"{
					gramsCO2 <- 0.11953*numAutonomousBikes+12.9233; //y=0.11953x+12.923​3
					reductionICE <- (-0.0463)*numAutonomousBikes+94.255; //y=-0.​0463x+94.2​55
					reductionBEV <- (-0.07753)*numAutonomousBikes+90.3967; //y=-0.07753x+90.396​7
				}
			} else if PickUpSpeedAutonomousBike = 14/3.6{
				if rechargeRate = "4.5hours"{
					gramsCO2 <- 0.0999*numAutonomousBikes+16.195; //y=0.09​99x+16.1​95
					reductionICE <- (-0.0497)*numAutonomousBikes+96.635; //y=-0.0​497x+96.6​35
					reductionBEV <- (-0.0832)*numAutonomousBikes+94.37; //y=-0.0​832x+94.​37
				} else if rechargeRate = "111s"{
					gramsCO2 <- 0.121767*numAutonomousBikes+12.141667; //y=0.12176​7x+12.141667
					reductionICE <- (-0.044)*numAutonomousBikes+93.39; //y=-0.0​44x+93.​39
					reductionBEV <- (-0.07363)*numAutonomousBikes+88.93167; //y=-0.07363x+88.​93167
		}}} */
		
		
		/*transitions to different states, keeping track of the count*/
		transition to: picking_up_packages when: delivery != nil{wanderCount <- wanderCount - 1; pickUpCount <- pickUpCount + 1;}
		transition to: low_battery when: setLowBattery() {wanderCount <- wanderCount - 1; lowBattCount <- lowBattCount + 1;}
		transition to: night_recharging when: nightRechargeCond = true and setNightChargingTime() {nightorigin <- self.location; wanderCount <- wanderCount - 1; lowBattCount <- lowBattCount + 1;} // set condition for night charging
		
		if traditionalScenario and delivery = nil{
			wanderCount <- wanderCount - 1;
			do die;
		}
		
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
		/*transitions to different state, keeping track of the count*/
		transition to: getting_charge when: self.location = target {lowBattCount <- lowBattCount - 1; getChargeCount <- getChargeCount + 1;}
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
		/* adjust charging rate */
		if rechargeRate = "111s"{
			V2IChargingRate <- maxBatteryLifeAutonomousBike/(111);
			nightRechargeCond <- false;
			rechargeCond <- false;
		} else if rechargeRate = "4.5hours"{
			V2IChargingRate <- maxBatteryLifeAutonomousBike/(4.5*60*60);

		}
		if traditionalScenario{
			getChargeCount <- getChargeCount - 1;
			do die;
		}
		/*transitions to fleetsize state because the vehicle is done with its trip, keeping track of the count*/
		transition to: fleetsize when: batteryLife >= maxBatteryLifeAutonomousBike {getChargeCount <- getChargeCount - 1; fleetsizeCount <- fleetsizeCount + 1;}
		exit {
			if stationChargeLogs{ask eventLogger { do logExitState("Charged at " + (chargingStation closest_to myself)); }}
			ask chargingStation closest_to(self) {
				autonomousBikesToCharge <- autonomousBikesToCharge - myself;
			}
		}
	}
	
	//Night recharge condition state, line 522 set to activate when true 
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
		/*transitions to different state, keeping track of the count*/
		transition to: getting_night_charge when: self.location = target {lowBattCount <- lowBattCount - 1; getChargeCount <- getChargeCount + 1;}
		exit {
			if autonomousBikeEventLog {ask eventLogger { do logExitState; }}
		}
	}
	
	//Night recharge condition state
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
		/* adjust charging rate */
		if rechargeRate = "111s"{
			V2IChargingRate <- maxBatteryLifeAutonomousBike/(111);
			nightRechargeCond <- false;
			rechargeCond <- false;
		} else if rechargeRate = "4.5hours"{
			V2IChargingRate <- maxBatteryLifeAutonomousBike/(4.5*60*60);

		}
		if traditionalScenario{
			getChargeCount <- getChargeCount - 1;
			do die;
		}
		/*transitions to different state, keeping track of the count*/
		transition to: night_relocating when: batteryLife >= maxBatteryLifeAutonomousBike {getChargeCount <- getChargeCount - 1; nightRelCount <- nightRelCount + 1;}
		exit {
			if stationChargeLogs{ask eventLogger { do logExitState("Charged at " + (chargingStation closest_to myself)); }}
			ask chargingStation closest_to(self) {
				autonomousBikesToCharge <- autonomousBikesToCharge - myself;
			}
		}
	}
	
	//Night recharge condition state
	state night_relocating {
		enter{
			target <- nightorigin;
			origin_closestPoint <- (road closest_to(self.location) using topology(road)).location;
			autonomousBike_distance <- host.distanceInGraph(target,origin_closestPoint);
			if autonomousBikeEventLog {
				ask eventLogger { do logEnterState(myself.state); }
				ask travelLogger { do logRoads(autonomousBike_distance);}
			}
		}
		/*transitions to fleetsize state because the vehicle is done with its trip, keeping track of the count*/
		transition to: fleetsize when: self.location = target {nightRelCount <- nightRelCount - 1; fleetsizeCount <- fleetsizeCount + 1;}
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
			/*transitions to different state, keeping track of the count*/
			transition to: in_use_packages when: (location = target and delivery.location = target) {pickUpCount <- pickUpCount - 1; inUseCount <- inUseCount + 1;}
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
		/*transitions to fleetsize state because the vehicle is done with its trip, keeping track of the count*/
		transition to: fleetsize when: location=target {delivery <- nil; inUseCount <- inUseCount - 1; fleetsizeCount <- fleetsizeCount + 1;}
		exit {
			
			if autonomousBikeEventLog {ask eventLogger { do logExitState("Used" + myself.delivery); }}
		}
	}
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

species car control: fsm skills: [moving] {
	
	//----------------Display-----------------
	rgb color;
	
	map<string, rgb> color_map <- [
		"wandering"::#transparent,
		
		"low_fuel"::#red,
		"night_refilling"::#red,
		"getting_fuel"::#red,
		"getting_night_fuel"::#red,
		"night_relocating"::#orangered,
		
		"picking_up_packages"::#cyan,
		"in_use_packages"::#cyan
	];
	
	aspect realistic {
		color <- color_map[state];
		draw triangle(50) color:color border:color rotate: heading + 90 ;
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
			/* 
	 new state created called fleetsize so we are able to adjust the number of vehicles. if the adjusted number of vehicles (by the user) 
	 is less than the number of vehicles that are active on the map, we kill those excess agents. on the other hand, new agnets are created 
	 if we need more (called in main.gaml)
	 	*/
	state fleetsize initial: true {
		enter {
			if fleetsizeCountCar+wanderCountCar+lowFuelCount+getFuelCount+pickUpCountCar+inUseCountCar > numCars{
				fleetsizeCountCar <- fleetsizeCountCar - 1;
				do die;
			}
			if !traditionalScenario {
				fleetsizeCountCar <- fleetsizeCountCar - 1;
				do die;
			}
		}
		transition to: wandering {fleetsizeCountCar <- fleetsizeCountCar - 1; wanderCountCar <- wanderCountCar + 1;} //transition to wandering state, keeping track of the count
	}

	state wandering {
		enter {
			if carEventLog {
				ask eventLogger { do logEnterState; }
				ask travelLogger { do logRoads(0.0);}
			}
			target <- nil;
		}
		
		if carType = "Electric"{
			maxFuelCar <- 342000.0 #m;
		} else{
			maxFuelCar <- 500000.0 #m;
		}
		
		/*transitions to different states, keeping track of the count*/
		transition to: picking_up_packages when: delivery != nil{wanderCountCar <- wanderCountCar - 1; pickUpCountCar <- pickUpCountCar + 1;}
		transition to: low_fuel when: setLowFuel() {wanderCountCar <- wanderCountCar - 1; lowFuelCount <- lowFuelCount + 1;}
		/*transition to: night_refilling when: setNightRefillingTime() {nightorigin <- self.location;}*/
		
		if !traditionalScenario and delivery = nil{
			wanderCountCar <- wanderCountCar - 1;
			do die;
		}
			
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
		/*transitions to different state, keeping track of the count*/
		transition to: getting_fuel when: self.location = target {lowFuelCount <- lowFuelCount - 1; getFuelCount <- getFuelCount + 1;}
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
		if carType = "Electric"{
			refillingRate <- maxFuelCar/(30*60) #m/#s;
		} else{
			refillingRate <- maxFuelCar/(3*60) #m/#s;
		}
		if !traditionalScenario {
			getFuelCount <- getFuelCount - 1;
			do die;
		}
		/*transitions to fleetsize state because the vehicle is done with its trip, keeping track of the count*/
		transition to: fleetsize when: fuel >= maxFuelCar {getFuelCount <- getFuelCount - 1; fleetsizeCountCar <- fleetsizeCountCar + 1;}
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
		/*transitions to different state, keeping track of the count*/
		transition to: in_use_packages when: (location = target and delivery.location = target) {pickUpCountCar <- pickUpCountCar - 1; inUseCountCar <- inUseCountCar + 1;}
		
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
		/*transitions to fleetsize state because the vehicle is done with its trip, keeping track of the count*/
		transition to: fleetsize when: location=target {
			delivery <- nil;
			inUseCountCar <- inUseCountCar - 1; fleetsizeCountCar <- fleetsizeCountCar + 1;
		}	
		exit {
			if carEventLog {ask eventLogger { do logExitState("Used " + myself.delivery); }}
		}
	}
}