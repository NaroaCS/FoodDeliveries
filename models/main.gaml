model main

import "./Agents.gaml"
import "./Loggers.gaml"
import "./Parameters.gaml"


global {
	//---------------------------------------------------------Performance Measures-----------------------------------------------------------------------------
	//-------------------------------------------------------------------Necessary Variables--------------------------------------------------------------------------------------------------

	// GIS FILES
	geometry shape <- envelope(bound_shapefile);
	graph roadNetwork;
	list<int> chargingStationLocation;
	
    // ---------------------------------------Agent Creation----------------------------------------------
	init{
    	// ---------------------------------------Buildings-----------------------------i----------------
		do logSetUp;
	    create building from: buildings_shapefile with: [type:string(read (usage))] {
		 	if(type!=office and type!=residence and type!=park and type!=education){ type <- "Other"; }
		}
	    
		// ---------------------------------------The Road Network----------------------------------------------
		create road from: roads_shapefile;
		
		roadNetwork <- as_edge_graph(road) ;
		
		/*loop vertex over: roadNetwork.edges {
			create intersection {
				//id <- roadNetwork.edges index_of vertex using topology(roadNetwork);
				location <- point(vertex);
			}
		}
		
		loop vertex over: roadNetwork.vertices {
			create intersection {
				//id <- roadNetwork.edges index_of vertex using topology(roadNetwork);
				location <- point(vertex);
			}
		}*/
				
		create restaurant from: restaurants_csv with:
			[lat::float(get("latitude")),
			lon::float(get("longitude"))
			]
			{location <- to_GAMA_CRS({lon,lat},"EPSG:4326").location;}
			
		create gasstation from: gasstations_csv with:
			[lat::float(get("lat")),
			lon::float(get("lon"))
			]
			{	
				location <- to_GAMA_CRS({lon,lat},"EPSG:4326").location;
				// DATA: https://faqautotips.com/how-many-fuel-pumps-does-a-typical-gas-station-have
				gasStationCapacity <- rnd(8,16);
			}
					   		
		create chargingStation from: chargingStations_csv with:
			[lat::float(get("Latitude")),
			lon::float(get("Longitude")),
			capacity::int(get("Total docks"))
			]
			{
				location <- to_GAMA_CRS({lon,lat},"EPSG:4326").location;
			}
					
		/*if traditionalScenario{
			numCars <- round(1*numVehiclesPackageTraditional);
			// drop-down menu
			if carType = "Combustion"{
				maxFuelCar <- 500000.0 #m;
				refillingRate <- maxFuelCar/3*60 #m/#s;
			} else{
				maxFuelCar <- 342000.0 #m;
				refillingRate <- maxFuelCar/30*60 #m/#s;
			}
		} else if !traditionalScenario {
			//numCars <- 0;
			if maxBatteryLifeAutonomousBike = 35000.0{
				coefficient <- 21;
			} else if maxBatteryLifeAutonomousBike = 50000.0{
				coefficient <- 30;
			} else if maxBatteryLifeAutonomousBike = 65000.0{
				coefficient <- 39;
			}
		}*/
		
		/*create autonomousBike number:numAutonomousBikes{					
			location <- point(one_of(roadNetwork.vertices));
			batteryLife <- rnd(minSafeBatteryAutonomousBike,maxBatteryLifeAutonomousBike);
		}*/
		
		/*if rechargeRate = "111s"{
			V2IChargingRate <- maxBatteryLifeAutonomousBike/(111);
			nightRechargeCond <- false;
			rechargeCond <- false;
			
		} else{
			V2IChargingRate <- maxBatteryLifeAutonomousBike/(4.5*60*60);
		}*/

	    /*create car number:numCars{		    
			location <- point(one_of(road));
			fuel <- rnd(minSafeFuelCar,maxFuelCar); 	//Battery life random bewteen max and min
		}*/
		
		// true false switch
//		if isCombustionCar{
//			maxFuelCar <- 500000.0 #m;
//			refillingRate <- maxFuelCar/3*60 #m/#s;
//			write(string(maxFuelCar));
//		} else if !isCombustionCar{
//			maxFuelCar <- 342000.0 #m;
//			refillingRate <- maxFuelCar/30*60 #m/#s;
//			write(string(maxFuelCar));
//		}
		    
		create package from: pdemand_csv with:
		[start_hour::date(get("start_time")),
				start_lat::float(get("start_latitude")),
				start_lon::float(get("start_longitude")),
				target_lat::float(get("end_latitude")),
				target_lon::float(get("end_longitude"))	
		]{
			
			start_point  <- to_GAMA_CRS({start_lon,start_lat},"EPSG:4326").location;
			target_point  <- to_GAMA_CRS({target_lon,target_lat},"EPSG:4326").location;
			location <- start_point;
			initial_closestPoint <- (road closest_to start_point using topology(road));
			final_closestPoint <- (road closest_to target_point using topology(road));
			
			string start_h_str <- string(start_hour,'kk');
			start_h <-  int(start_h_str);
			if start_h = 24 {
				start_h <- 0;
			}
			string start_min_str <- string(start_hour,'mm');
			start_min <- int(start_min_str);
		}
		write "FINISH INITIALIZATION";
		initial_hour <- current_date.hour;
		initial_minute <- current_date.minute;
    }
    
	/*reflex stop_simulation when: cycle >= numberOfDays * numberOfHours * 3600 / step {
		do pause ;
	}*/
	
	/* corresponds with fleetsize state, new vehicles are created when the number of vehicles is increased. adds the amount needed to fulfill total amount of vehicles */
	reflex create_autonomousBikes when: !traditionalScenario and fleetsizeCount+wanderCount+lowBattCount+getChargeCount+nightRelCount+pickUpCount+inUseCount < numAutonomousBikes{ 
		create autonomousBike number: (numAutonomousBikes - (wanderCount+lowBattCount+getChargeCount+nightRelCount+pickUpCount+inUseCount)){
			location <- point(one_of(roadNetwork.vertices));
			batteryLife <- rnd(minSafeBatteryAutonomousBike,maxBatteryLifeAutonomousBike);
			fleetsizeCount <- fleetsizeCount +1;
		}
	}
	/* corresponds with fleetsize state, new vehicles are created when the number of vehicles is increased. adds the amount needed to fulfill total amount of vehicles */
	reflex create_cars when: traditionalScenario and fleetsizeCountCar+wanderCountCar+lowFuelCount+getFuelCount+pickUpCountCar+inUseCountCar < numCars{ 
		create car number: (numCars - (wanderCountCar+lowFuelCount+getFuelCount+pickUpCountCar+inUseCountCar)){
			location <- point(one_of(road));
			fuel <- rnd(minSafeFuelCar,maxFuelCar); 
			fleetsizeCountCar <- fleetsizeCountCar +1;
		}
	}
	
	// Reset the number of unserved trips
	reflex reset_unserved_counter when: ((initial_ab_number != numAutonomousBikes) or (initial_ab_battery != maxBatteryLifeAutonomousBike) or (initial_ab_speed != PickUpSpeedAutonomousBike) or (initial_ab_recharge_rate != rechargeRate) or (initial_c_number != numCars) or (initial_c_battery != maxFuelCar) or (initial_c_type != carType) or (initial_scenario != traditionalScenario)) { 
		initial_ab_number <- numAutonomousBikes;
		initial_ab_battery <- maxBatteryLifeAutonomousBike;
		initial_ab_speed <- PickUpSpeedAutonomousBike;
		initial_ab_recharge_rate <- rechargeRate;
		initial_c_number <- numCars;
		initial_c_battery <- maxFuelCar;
		initial_c_type <- carType;
		initial_scenario <- traditionalScenario;
		unservedCount <- 0;
	}
}

experiment traditionalScenario {
	parameter var: numVehiclesPackageTraditional init: numVehiclesPackageTraditional;
//	float minimum_cycle_duration<- 1 #sec;
	output {
		display Traditional_Scenario type:opengl background: #black axes: false{	
			species building aspect: type visible:show_building position:{0,0,-0.001};
			species road aspect: base visible:show_road;
			species restaurant aspect:base visible:show_restaurant position:{0,0,-0.001};
			species gasstation aspect:base visible:show_gasStation;
			species chargingStation aspect: base visible:show_chargingStation ;
			species car aspect: realistic visible:show_car trace:15 fading: true; 
			species autonomousBike aspect: realistic visible:show_autonomousBike trace:30 fading: true;
			species package aspect:base visible:show_package;
			
		event["b"] {show_building<-!show_building;}
		event["r"] {show_road<-!show_road;}
		event["s"] {show_gasStation<-!show_gasStation;}
		event["f"] {show_restaurant<-!show_restaurant;}
		event["d"] {show_package<-!show_package;}
		event["c"] {show_car<-!show_car;}
		}
		
		/* series graph for car variables */
		display vehicleTasks antialias: true{
    		chart "Vehicle Tasks" type: series background: #black color: #white axes: #white tick_line_color:#white x_label: "Time (sec)" y_label: "Number of Vehicles"{
    			data "wandering" value: wanderCountCar color: #blue marker: false style: line;
    			data "low battery/fuel" value: lowFuelCount color: #orange marker: false style: line;
    			data "getting charge/fuel" value: getFuelCount color: #red marker: false style: line;
//    			data "pick up" value: pickUpCount color: #yellow marker: false style: line;
    			data "in use" value: inUseCountCar+pickUpCountCar color: #green marker: false style: line;
    			//data "night relocating" value: nightRelCount color: #purple marker: false style: line;
   			}
    	}
    	
    	/* series graph for last 10 (moving) average wait time */
  		display avgWaitTime antialias: true{
			chart "Average Wait Time" type: series background: #black color: #white axes: #white tick_line_color:#white x_label: "Time (sec)" y_label: "Average Last 10 Wait Times (min)"{
				data "Wait Time" value: avgWait color: #pink marker: false style: line;
			}
		}
	}
}

experiment autonomousScenario type: gui {
	parameter var: numAutonomousBikes init: numAutonomousBikes;
	float minimum_cycle_duration<- 1 #sec;
    output {
		display autonomousScenario type:opengl background: #black axes: false{	 
			species building aspect: type visible:show_building position:{0,0,-0.001};
			species road aspect: base visible:show_road ;
			species gasstation aspect:base visible:show_gasStation;
			species chargingStation aspect: base visible:show_chargingStation ;
			species restaurant aspect:base visible:show_restaurant position:{0,0,-0.001};
			species autonomousBike aspect: realistic visible:show_autonomousBike trace:30 fading: true;
			species car aspect: realistic visible:show_car trace:15 fading: true; 
			species package aspect:base visible:show_package;
			//species intersection aspect:base;
		event["b"] {show_building<-!show_building;}
		event["r"] {show_road<-!show_road;}
		event["s"] {show_chargingStation<-!show_chargingStation;}
		event["f"] {show_restaurant<-!show_restaurant;}
		event["d"] {show_package<-!show_package;}
		event["a"] {show_autonomousBike<-!show_autonomousBike;}
		}
		/* series graph for bike variables */
		display vehicleTasks antialias: true{
    		chart "Vehicle Tasks" type: series background: #black color: #white axes: #white tick_line_color:#white x_label: "Time (sec)" y_label: "Number of Vehicles"{
    			data "wandering" value: wanderCount color: #blue marker: false style: line;
    			data "low battery" value: lowBattCount color: #orange marker: false style: line;
    			data "getting charge" value: getChargeCount color: #red marker: false style: line;
//    			data "pick up" value: pickUpCount color: #yellow marker: false style: line;
    			data "in use" value: inUseCount+pickUpCount color: #green marker: false style: line;
    			data "night relocating" value: nightRelCount color: #purple marker: false style: line;
   			}
    	}
    	
    	//inactive pie chart
    	/* 
		display percentServed {
			chart "Delivery Speed" type: pie{
			loop while: length(timeList) < 10{
				datalist["Served in less than 40min", "Served in more than 40min"] value: [] color: [];
			}
			datalist["Served in less than 40min", "Served in more than 40min"] value: [10-moreThanWait, moreThanWait] color: [#blue, #red];
			}
		} */

    	/* series graph for last 10 (moving) average wait time */
		display avgWaitTime antialias: true{
			chart "Average Wait Time" type: series background: #black color: #white axes: #white tick_line_color:#white x_label: "Time (sec)" y_label: "Average Last 10 Wait Times (min)"{
				data "Wait Time" value: avgWait color: #pink marker: false style: line; 
			}
		}
    }
		
}

experiment generalScenario type: gui {
    output {
    layout #split  parameters: true navigator: false editors: false consoles: false toolbars: false tray: false tabs: false;
		display autonomousScenario type:java2D background: #black axes: false {	 
			species building aspect: type visible:show_building ;
			species road aspect: base visible:show_road ;
			species gasstation aspect:base visible:show_gasStation;
			species chargingStation aspect: base visible:show_chargingStation ;
			species restaurant aspect:base visible:show_restaurant;
			species autonomousBike aspect: realistic visible:show_autonomousBike trace:30 fading: true;
			species car aspect: realistic visible:show_car trace:15 fading: true; 
			species package aspect:base visible:show_package;
			//species intersection aspect:base;
		event["b"] {show_building<-!show_building;}
		event["r"] {show_road<-!show_road;}
		event["s"] {show_chargingStation<-!show_chargingStation;}
		event["f"] {show_restaurant<-!show_restaurant;}
		event["d"] {show_package<-!show_package;}
		event["a"] {show_autonomousBike<-!show_autonomousBike;}
		event["c"] {show_car<-!show_car;}
		}
		
		/* series graph for bike and car variables */
		display vehicleTasks antialias: false axes: false{
			
    		chart "Vehicle Tasks" type: series background: #black color: #white title_font: font("Helvetica", 20, #bold) axes: #white tick_line_color:#transparent x_label: "Time of the Day" y_label: "Number of Vehicles" x_serie_labels: (string(current_date.hour))  x_tick_unit: 362 {
    			
    			data "wandering cars" value: wanderCountCar color: #blue marker: false style: line;
				//data "cars low battery/fuel" value: lowFuelCount color: #orange marker: false style: line;
				data "car getting charge/fuel" value: getFuelCount color: #red marker: false style: line;
				data "cars in use" value: inUseCountCar+pickUpCountCar color: #yellow marker: false style: line;
				
				data "wandering bikes" value: wanderCount color: #lightblue marker: false style: line;	
				//data "bikes with low battery" value: lowBattCount color: #coral marker: false style: line;
				data "bikes getting charge" value: getChargeCount color: #red marker: false style: line;
				data "bikes in use" value: inUseCount+pickUpCount color: #lightgreen marker: false style: line;
				//data "bikes night relocating" value: nightRelCount color: #plum marker: false style: line;
   			}
    	}
		
    	/* series graph for last 10 (moving) average wait time */
		
		display avgWaitTime antialias: false axes: false{
			chart "Average Wait Time" type: series background: #black title_font: font("Helvetica", 20, #bold) color: #white axes: #white tick_line_color:#transparent x_label: "Time of the Day" y_label: "Average Last 10 Wait Times (min)" x_serie_labels: (string(current_date.hour))  x_tick_unit: 362 {
				data "Wait Time" value: avgWait color: #pink marker: false style: line;
				data "40min" value: 40 color: #red marker: false style: line;
			}
		}
		
		display CO2 antialias: false axes: false {
			chart "CO2" type:histogram background: #black color: #white axes: #transparent title_font: font("Helvetica", 20, #bold) tick_line_color:#transparent y_range: [0.0, 60.0] x_serie_labels: "gCO2/km:" x_label: string(round(gramsCO2*100)/100)
			series_label_position: xaxis
			{
				data " "
					style: bar
					value: round(gramsCO2*100)/100
					color: #red;
			}
		}
		display "Strings" type: opengl  axes: false {
			graphics Strings {
				if traditionalScenario{
					draw "Traditional Scenario" at: {0, 600} color: #white font: font("Helvetica", 60, #bold);
					draw "Number of Cars: " + numCars at: {0, 2000} color: #white font: font("Helvetica", 40, #plain);
					draw "Car Type: " + carType at: {0, 3000} color: #white font: font("Helvetica", 40, #plain);
					draw "Speed: " + round(RidingSpeedCar*100*3.6)/100 + " km/h" at: {0, 4000} color: #white font: font("Helvetica", 40, #plain);
				} else{
					draw "Autonomous Scenario" at: {0, 600} color: #white font: font("Helvetica", 60, #bold);
					draw "Number of Bikes: " + numAutonomousBikes at: {0, 2000} color: #white font: font("Helvetica", 40, #plain);
					draw "Full Recharge: " + rechargeRate at: {0, 3000} color: #white font: font("Helvetica", 40, #plain);
					draw "Speed: " + round(PickUpSpeedAutonomousBike*100*3.6)/100 + " km/h" at: {0, 4000} color: #white font: font("Helvetica", 40, #plain);
					draw "Battery Capacity: " + maxBatteryLifeAutonomousBike/1000 + "km" at: {0, 5000} color: #white font: font("Helvetica", 40, #plain);
					draw "Number of Charging Stations: " + numChargingStations at: {0, 6000} color: #white font: font("Helvetica", 40, #plain);
				}
				draw "UnservedTrips: " + unservedCount at: {0, 7000} color: #white font: font("Helvetica", 40, #plain);
				}
			}
			
		display reductionICE antialias: false type: java2D{ 
			chart "% Reduction vs. ICE" type: pie style: ring background: #black color: #white title_font: font("Helvetica", 20, #bold) series_label_position: none{
				data "reduction %" value: round(reductionICE*100)/100 color: #lightgreen;
				data " " value: 100-round(reductionICE*100)/100 color: #darkgray;
				}
			graphics Strings{
				draw " " + round(reductionICE*100)/100 + "%" at: {2000, 3200} color: #white font: font("Helvetica", 40, #bold);
				}
			}
			
		display reductionBEV  antialias: false type: java2D{
			chart "% Reduction vs. BEV" type: pie style: ring background: #black color: #white title_font: font("Helvetica", 20, #bold) series_label_position: none{ 
				data "reduction %" value: round(reductionBEV*100)/100 color: #darkgreen;
				data " " value: 100-round(reductionBEV*100)/100 color: #darkgray;
				}
			graphics Strings{
				draw " " + round(reductionBEV*100)/100 + "%" at: {2000, 3200} color: #white font: font("Helvetica", 40, #bold);
				}
			}
		
		
//		display unservedTrips antialias: true draw_env: false{
//    		chart "Unserved Trips" type: histogram background: #black color: #white axes: #white tick_line_color:#transparent y_label: "Number of Unserved Trips [-]"{
//				data "Unserved Trips" value: unservedCount;
//			}
//    	}
    	
    }
		
}

experiment car_batch_experiment type: batch repeat: 1 until: (cycle >= numberOfDays * numberOfHours * 3600 / step) {
	parameter var: numVehiclesPackageTraditional among: [5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80];
}

experiment autonomousbike_batch_experiment type: batch repeat: 1 until: (cycle >= numberOfDays * numberOfHours * 3600 / step) {
	//parameter var: numAutonomousBikes among: [200];
	parameter var: numAutonomousBikes among: [140,150,160,170,180,190,200,210,220,230,240,250,260,270,280,290,300];
	//parameter var: PickUpSpeedAutonomousBike among: [11/3.6];
	parameter var: PickUpSpeedAutonomousBike among: [8/3.6,11/3.6,14/3.6];
	//parameter var: maxBatteryLifeAutonomousBike among: [50000.0];
	parameter var: maxBatteryLifeAutonomousBike among: [35000.0,50000.0,65000.0];
}