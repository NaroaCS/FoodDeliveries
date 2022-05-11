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
		 	if(type!=office and type!=residence){ type <- "Other"; }
		}
	        
	    list<building> residentialBuildings <- building where (each.type=residence);
	    list<building> officeBuildings <- building where (each.type=office);
	    
		// ---------------------------------------The Road Network----------------------------------------------
		create road from: roads_shapefile;
		
		roadNetwork <- as_edge_graph(road) ;
		
		create supermarket from: supermarket_csv with:
			[lat::float(get("lat")),
			lon::float(get("lon"))
			]
			{
				sup <- to_GAMA_CRS({lon,lat},"EPSG:4326").location; 
				location <- sup;
			}
			   
		// -------------------------------------Location of the charging stations----------------------------------------   
		
	    list<int> tmpDist;
	    		
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
		}
		
		
		// -------------------------------------------The Bikes -----------------------------------------
		create bike number:numBikes{
									
			location <- point(one_of(roadNetwork.vertices));
			batteryLife <- rnd(minSafeBattery,maxBatteryLife); 	//Battery life random bewteen max and min
		}
	    
	    //------------------------------------------The Scooters------------------------
	    create scooter number:numScooters{
									
			location <- point(one_of(roadNetwork.vertices));
			batteryLife <- rnd(minSafeBatteryS,maxBatteryLifeS); 	//Battery life random bewteen max and min
		}
	    
		// -------------------------------------------The People -----------------------------------------
	    
	   create package number:numpackage {
	   		list<building> deliv <- building where (each.type=residence or each.type=office);
			building dest <- one_of(deliv);
			target_point <- dest.location;
			supermarket sup <- one_of(supermarket);
			start_point <- sup.location;
			location <- start_point;
			
			int decision <- rnd(0,1);
			if decision = 0 {
				start_h <- lunchmin + rnd(lunchmax-1-lunchmin);
				start_min <- rnd(0,59);
			} else if decision = 1 {
				start_h <- dinnermin + rnd(dinnermax-1-dinnermin);
				start_min <- rnd(0,59);
			}
		}
		
		/*create package from: pdemand_csv with:
		[start_hour::date(get("starttime"))			
		]{
			building dest <- one_of(building);
			target_point <- dest.location;
			supermarket sup <- one_of(supermarket);
			start_point <- sup.location;
			location <- start_point;
			
			string start_h_str <- string(start_hour,'kk');
			start_h <-  int(start_h_str);
			string start_min_str <- string(start_hour,'mm');
			start_min <- int(start_min_str);
		}*/
	   
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

experiment batch_experiment type: batch repeat: 5 until: (cycle >= numberOfDays * numberOfHours * 3600 / step) {
	parameter var: numBikes among: [25, 50, 75, 100, 125];
}


experiment main_with_gui type: gui {
	parameter var: numBikes init: numBikes;
    output {
		display city_display type:opengl background: #black draw_env: false{	 
			species building aspect: type ;
			species road aspect: base ;
			species people aspect: base ;
			species chargingStation aspect: base ;
			species supermarket aspect:base;
			species package aspect:base;
			species bike aspect: realistic trace: 10 ;
			species scooter aspect: realistic trace:10; 
			graphics "text" {
				draw "day" + string(current_date.day) + " - " + string(current_date.hour) + "h" color: #white font: font("Helvetica", 25, #italic) at:
				{world.shape.width * 0.8, world.shape.height * 0.975};
				draw imageRaster size: 40 #px at: {world.shape.width * 0.98, world.shape.height * 0.95};
			}
		}
		/*display histogram_display{
			chart name: 'Size distribution' type: histogram background: rgb('lightGray') {
				data name: "18h" value: float scooteremissions (each.current_date.hour < 19);
				data name: "19h" value: float scooteremissions ((each.current_date.hour < 20) and (each.current_date.hour < 20));
		}*/
    }
}

/*experiment main_headless {
	parameter var: numBikes init: numBikes;
}*/