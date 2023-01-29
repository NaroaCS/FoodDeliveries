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
					
		if traditionalScenario{
			numCars <- round(1*numVehiclesPackageTraditional);
		} else if !traditionalScenario {
			numCars <- 0;
			if maxBatteryLifeAutonomousBike = 35000.0{
				coefficient <- 21;
			} else if maxBatteryLifeAutonomousBike = 50000.0{
				coefficient <- 30;
			} else if maxBatteryLifeAutonomousBike = 65000.0{
				coefficient <- 39;
			}
		}
			
		create autonomousBike number:numAutonomousBikes{					
			location <- point(one_of(roadNetwork.vertices));
			batteryLife <- rnd(minSafeBatteryAutonomousBike,maxBatteryLifeAutonomousBike);
		}

	    create car number:numCars{					
			location <- point(one_of(road));
			fuel <- rnd(minSafeFuelCar,maxFuelCar); 	//Battery life random bewteen max and min
		}
	    	    
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
    }
	reflex stop_simulation when: cycle >= numberOfDays * numberOfHours * 3600 / step {
		do pause ;
	}
}

experiment traditionalScenario {
	parameter var: numVehiclesPackageTraditional init: numVehiclesPackageTraditional;
	output {
		display Traditional_Scenario type:opengl background: #black draw_env: false{	 
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
	}
}

experiment autonomousScenario type: gui {
	parameter var: numAutonomousBikes init: numAutonomousBikes;
	float minimum_cycle_duration<-0.01;
    output {
		display autonomousScenario type:opengl background: #black draw_env: false{	 
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
    }
}

experiment car_batch_experiment type: batch repeat: 5 until: (cycle >= numberOfDays * numberOfHours * 3600 / step) {
	parameter var: numVehiclesPackageTraditional among: [40];
}

experiment autonomousbike_batch_experiment type: batch repeat: 1 until: (cycle >= numberOfDays * numberOfHours * 3600 / step) {
	//parameter var: numAutonomousBikes among: [180];
	parameter var: numAutonomousBikes among: [50,350];
	//parameter var: PickUpSpeedAutonomousBike among: [11/3.6];
	parameter var: PickUpSpeedAutonomousBike among: [11/3.6];
	//parameter var: maxBatteryLifeAutonomousBike among: [65000.0];
	parameter var: maxBatteryLifeAutonomousBike among: [35000.0,65000.0];
}