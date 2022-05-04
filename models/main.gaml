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
		   
		// TODO: This was some pre-computing but it's not being used now
		//Next move to the shortest path between each point in the graph
		//matrix allPairs <- all_pairs_shortest_path (roadNetwork);    
		
	    
		// -------------------------------------Location of the charging stations----------------------------------------   
		
		//***NOTE:*** This section just creates the number of stations defined by the user by clustering road intersections
		// TODO: I tried to put the stations in current Bluebikes stations' location but I was doing someting wrong - Will review
		
				/*create chargingStation from: chargingStations_csv with:[
						lat::float(get("y")),
						lon::float(get("x"))
				]{
					point_station  <- to_GAMA_CRS({lon,lat},"EPSG:4326").location;
					location <- (intersection closest_to point_station).location;
				}*/
				 
	    //from charging locations to closest intersection
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
			
			//write "cycle: " + cycle + ", " + string(self) + " created with batteryLife " + self.batteryLife;
		}
	    
		// -------------------------------------------The People -----------------------------------------
	    
	    create people from: demand_csv with:
		[start_hour::date(get("starttime")), //'yyyy-MM-dd hh:mm:s'
				start_lat::float(get("start_lat")),
				start_lon::float(get("start_lon")),
				target_lat::float(get("target_lat")),
				target_lon::float(get("target_lon"))
				/*start_lat::float(42.369732),
				start_lon::float(-71.090101),
				target_lat::float(42.368263),
				target_lon::float(-71.080622)*/
				
			]{

				
	        speed <- peopleSpeed;
	        start_point  <- to_GAMA_CRS({start_lon,start_lat},"EPSG:4326").location; // (lon, lat) var0 equals a geometry corresponding to the agent geometry transformed into the GAMA CRS
			target_point <- to_GAMA_CRS({target_lon,target_lat},"EPSG:4326").location;
			location <- start_point;
			
			string start_h_str <- string(start_hour,'kk');
			start_h <- int(start_h_str);
			string start_min_str <- string(start_hour,'mm');
			start_min <- int(start_min_str);
			
			//write "cycle: " + cycle + ", time "+ self.start_h + ":" + self.start_min + ", "+ string(self) + " will travel from " + self.start_point + " to "+ self.target_point;
			
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
			species bike aspect: realistic trace: 10 ; 
			graphics "text" {
				draw "day" + string(current_date.day) + " - " + string(current_date.hour) + "h" color: #white font: font("Helvetica", 25, #italic) at:
				{world.shape.width * 0.8, world.shape.height * 0.975};
				draw imageRaster size: 40 #px at: {world.shape.width * 0.98, world.shape.height * 0.95};
			}
		}
	
    }
}

experiment main_headless {
	parameter var: numBikes init: numBikes;
}




