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
		 	if(type!=office and type!=residence and type!=park and type!=health and type!=education){ type <- "Other"; }
		}
	    
		// ---------------------------------------The Road Network----------------------------------------------
		create road from: roads_shapefile;
		
		roadNetwork <- as_edge_graph(road) ;
				
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
					   
		// -------------------------------------Location of the charging stations----------------------------------------   
		//-----------------------------------------------Before----------------------------------------------------------
		
		/*list<int> tmpDist;
	    		
		loop vertex over: roadNetwork.vertices {
			create intersection {
				id <- roadNetwork.vertices index_of vertex;
				location <- point(vertex);
			}
		}

		//K-Means		
		//Create a list of x,y coordinate for each intersection
		list<list> instances <- intersection collect ([each.location.x, each.location.y]);

		//from the vertices list, create k groups  with the Kmeans algorithm (https://en.wikipedia.org/wiki/K-means_clustering)
		list<list<int>> kmeansClusters <- list<list<int>>(kmeans(instances, numChargingStations));

		//from clustered vertices to centroids locations
		int groupIndex <- 0;
		list<point> coordinatesCentroids <- [];
		loop cluster over: kmeansClusters {
			groupIndex <- groupIndex + 1;
			list<point> coordinatesVertices <- [];
			loop i over: cluster {
				add point (roadNetwork.vertices[i]) to: coordinatesVertices; 
			}
			add mean(coordinatesVertices) to: coordinatesCentroids;
		}    
	    
		loop centroid from:0 to:length(coordinatesCentroids)-1 {
			tmpDist <- [];
			loop vertices from:0 to:length(roadNetwork.vertices)-1{
				add (point(roadNetwork.vertices[vertices]) distance_to coordinatesCentroids[centroid]) to: tmpDist;
			}	
			loop vertices from:0 to: length(tmpDist)-1{
				if(min(tmpDist)=tmpDist[vertices]){
					add vertices to: chargingStationLocation;
					break;
				}
			}	
		}
	    
	    loop i from: 0 to: length(chargingStationLocation) - 1 {
			create chargingStation{
				location <- point(roadNetwork.vertices[chargingStationLocation[i]]);
			}
		}*/
		
		//--------------------------------------After--------------------------------------------------
		
		create chargingStation from: chargingStations_csv with:
			[lat::float(get("Latitude")),
			lon::float(get("Longitude")),
			capacity::int(get("Total docks"))
			]
			{
				location <- to_GAMA_CRS({lon,lat},"EPSG:4326").location;
				
			 	chargingStationCapacity <- capacity;
			}
		
		//-----------------------Scenarios-------------------------------------------------------------
			
		if traditionalScenario{
			numAutonomousBikes <- 0;			
			numScooters <- round(0.0*numVehiclesPackageTraditional);
			numEBikes <- round(0.0*numVehiclesPackageTraditional);
			numConventionalBikes <- round(0.0*numVehiclesPackageTraditional);
			numCars <- round(1*numVehiclesPackageTraditional);
			
		} else if !traditionalScenario {
			numDocklessBikes <- 0;			
			numScooters <- 0;
			numEBikes <- 0;
			numConventionalBikes <- 0;
			numCars <- 0;
		}
			
		// -------------------------------------------The Bikes -----------------------------------------
		create autonomousBike number:numAutonomousBikes{					
			location <- point(one_of(roadNetwork.vertices));
			batteryLife <- rnd(minSafeBatteryAutonomousBike,maxBatteryLifeAutonomousBike); 	//Battery life random bewteen max and min
		}
		
		// -------------------------------------------The Dockless Bikes -----------------------------------------
		create docklessBike number:numDocklessBikes{					
			location <- point(one_of(road));
		}
	    
	    //------------------------------------------The Scooters------------------------
	    // Data extracted from: Contribution to the Sustainability Challenges of the Food-Delivery Sector: Finding from the Deliveroo Italy Case Study
	    create scooter number:numScooters{					
			location <- point(one_of(road));
			batteryLife <- rnd(minSafeBatteryScooter,maxBatteryLifeScooter); 	//Battery life random bewteen max and min
		}
	
		//------------------------------------------The EBikes------------------------
		// Data extracted from: Contribution to the Sustainability Challenges of the Food-Delivery Sector: Finding from the Deliveroo Italy Case Study
	    create eBike number:numEBikes{						
			location <- point(one_of(road));
			batteryLife <- rnd(minSafeBatteryEBike,maxBatteryLifeEBike); 	//Battery life random bewteen max and min
		}
		
		//------------------------------------------The Conventional Bikes------------------------
		// Data extracted from: Contribution to the Sustainability Challenges of the Food-Delivery Sector: Finding from the Deliveroo Italy Case Study
	    create conventionalBike number:numConventionalBikes{					
			location <- point(one_of(road));
		}
		
		//------------------------------------------The Cars------------------------
	    // Data extracted from: Contribution to the Sustainability Challenges of the Food-Delivery Sector: Finding from the Deliveroo Italy Case Study
	    create car number:numCars{					
			location <- point(one_of(road));
			fuel <- rnd(minSafeFuelCar,maxFuelCar); 	//Battery life random bewteen max and min
		}
	    	    
		// -------------------------------------------The Packages -----------------------------------------
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
			
			string start_h_str <- string(start_hour,'kk');
			start_h <-  int(start_h_str);
			string start_min_str <- string(start_hour,'mm');
			start_min <- int(start_min_str);
		}
		
		// -------------------------------------------The People -----------------------------------------
	    create people from: demand_csv with:
		[start_hour::date(get("starttime")), //'yyyy-MM-dd hh:mm:s'
				start_lat::float(get("start_lat")),
				start_lon::float(get("start_lon")),
				target_lat::float(get("target_lat")),
				target_lon::float(get("target_lon"))
			]{

	        speed <- peopleSpeed;
	        start_point  <- to_GAMA_CRS({start_lon,start_lat},"EPSG:4326").location; // (lon, lat) var0 equals a geometry corresponding to the agent geometry transformed into the GAMA CRS
			target_point <- to_GAMA_CRS({target_lon,target_lat},"EPSG:4326").location;
			location <- start_point;
			
			string start_h_str <- string(start_hour,'kk');
			start_h <- int(start_h_str);
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
			species building aspect: type ;
			species road aspect: base ;
			species people aspect: base ;
			species restaurant aspect:base;
			species gasstation aspect:base;
			species package aspect:base;
			species docklessBike aspect: realistic trace: 10 ;
			species scooter aspect: realistic trace:10; 
			species eBike aspect: realistic trace:10; 
			species conventionalBike aspect: realistic trace:10;
			species car aspect: realistic trace:10;  
			//species gridHeatmaps aspect:pollution;
			graphics "text" {
				draw "day" + string(current_date.day) + " - " + string(current_date.hour) + "h" color: #white font: font("Helvetica", 25, #italic) at:
				{world.shape.width * 0.8, world.shape.height * 0.975};
				draw imageRaster size: 40 #px at: {world.shape.width * 0.98, world.shape.height * 0.95};
			}
		}
		/*display Dashboard type:opengl  background: #black refresh: every(2 #cycles) {
	        chart "CO2 Emissions" type: series style: spline size:{0.5,0.5} position: {world.shape.width*0,world.shape.height*0}{
		        data "Dockless Bike Emissions" value: docklessBike_total_emissions color: #purple marker: false;
		        data "Scooter Emissions" value: scooter_total_emissions color: #green marker: false;
		        data "E Bike Emissions" value: eBike_total_emissions color: #yellow marker: false;
		        data "Conventional Bike Emissions" value: conventionalBike_total_emissions color: #red marker: false;
		        data "Car Emissions" value: car_total_emissions color: #black marker: false;
        	}
        	chart "Package Delivery per MoCho" type: pie size: {0.5,0.5} position: {world.shape.width*0.5,world.shape.height*0}{
		        data "Scooter" value: scooter_trips_count_PUP color: #green;
		        data "E Bike" value: eBike_trips_count_PUP color: #yellow;
		        data "Conventional Bike" value: conventionalBike_trips_count_PUP color: #red;
		        data "Car" value: car_trips_count_PUP color: #black;
        	}	
        }*/    
	}
}

experiment autonomousScenario type: gui {
	parameter var: numAutonomousBikes init: numAutonomousBikes;
    output {
		display autonomousScenario type:opengl background: #black draw_env: false{	 
			species building aspect: type ;
			species road aspect: base ;
			species people aspect: base ;
			species chargingStation aspect: base ;
			species restaurant aspect:base;
			species package aspect:base;
			species autonomousBike aspect: realistic trace: 10 ;
			graphics "text" {
				draw "day" + string(current_date.day) + " - " + string(current_date.hour) + "h" color: #white font: font("Helvetica", 25, #italic) at:
				{world.shape.width * 0.8, world.shape.height * 0.975};
				draw imageRaster size: 40 #px at: {world.shape.width * 0.98, world.shape.height * 0.95};
			}
		}
		/*display Dashboard type:opengl  background: #black refresh: every(2 #cycles) {
	        chart "CO2 Emissions" type: series style: spline size:{0.5,0.5} position: {world.shape.width*0,world.shape.height*0}{
		        data "Autonomous Bike Emissions in People Delivery" value: autonomousBike_total_emissions_people color: #purple marker: false;
		        data "Autonomous Bike Emissions in Package Delivery" value: autonomousBike_total_emissions_package color: #green marker: false;
		        data "Autonomous Bike Emissions Going to Charge" value: autonomousBike_total_emissions_C color: #red marker: false;
        	}
        	chart "Autonomous Bike Usage per MoCho" type: pie size: {0.5,0.5} position: {world.shape.width*0.5,world.shape.height*0}{
		        data "People" value: autonomousBike_trips_count_people color: #green;
		        data "package" value: autonomousBike_trips_count_package color: #red;
        	}
        	chart "CO2 Emissions Total" type: series style: spline size:{0.5,0.5} position: {world.shape.width*0,world.shape.height*0.5}{
		        data "Autonomous Bike Emissions Total" value: autonomousBike_total_emissions color: #black marker: false;
        	}
        }*/
    }
}

/*experiment main_headless {
	parameter var: numAutonomousBikes init: numAutonomousBikes;
}*/

/*experiment batch_experiment type: batch repeat: 5 until: (cycle >= numberOfDays * numberOfHours * 3600 / step) {
	parameter var: numAutonomousBikes among: [25, 50, 75, 100, 125];
}*/

/*experiment main_with_gui type: gui {
	parameter var: numAutonomousBikes init: numAutonomousBikes;
    output {
		display city_display type:opengl background: #black draw_env: false{	 
			species building aspect: type ;
			species road aspect: base ;
			species people aspect: base ;
			species chargingStation aspect: base ;
			species supermarket aspect:base;
			species package aspect:base;
			species autonomousBike aspect: realistic trace: 10 ;
			species docklessBike aspect: realistic trace: 10 ;
			species scooter aspect: realistic trace:10; 
			species conventionalBike aspect: realistic trace:10; 
			graphics "text" {
				draw "day" + string(current_date.day) + " - " + string(current_date.hour) + "h" color: #white font: font("Helvetica", 25, #italic) at:
				{world.shape.width * 0.8, world.shape.height * 0.975};
				draw imageRaster size: 40 #px at: {world.shape.width * 0.98, world.shape.height * 0.95};
			}
		}
		display Dashboard type:opengl  background: #black refresh: every(2 #cycles) {
	        chart "CO2 Emissions" type: series style: spline size:{0.5,0.5} position: {world.shape.width*0,world.shape.height*0}{
		        data "Dockless Bike Emissions" value: docklessBike_total_emissions color: #purple marker: false;
		        data "Scooter Emissions" value: scooter_total_emissions color: #green marker: false;
		        data "Conventional Bike Emissions" value: conventionalBike_total_emissions color: #red marker: false;
        	}
        	chart "Package Delivery per MoCho" type: pie size: {0.5,0.5} position: {world.shape.width*0.5,world.shape.height*0}{
		        data "Scooter" value: scooter_trips_count_PUP color: #green;
		        data "Conventional Bike" value: conventionalBike_trips_count_PUP color: #red;
        	}
        }
    }
}*/
experiment car_batch_experiment type: batch repeat: 1 until: (cycle >= numberOfDays * numberOfHours * 3600 / step) {
	parameter var: numVehiclesPackageTraditional among: [20,40,60,80,100/*,120,140,160,180,200*/];
}

experiment autonomousbike_batch_experiment type: batch repeat: 1 until: (cycle >= numberOfDays * numberOfHours * 3600 / step) {
	parameter var: numAutonomousBikes among: [20,40,60,80,100];
	//parameter var: maxBatteryLifeAutonomousBike among: [10000.0,15000.0,20000.0,25000.0,30000.0];
}