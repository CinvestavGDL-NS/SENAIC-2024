/**
* Name: part3
* Move cars 
* Author: Lili
* Tags: 
*/


model part3
global
{
	// Maps and images declaration
	file 		shp_roads 		<- file("../includes/maps/cd_creativa_1.shp");
	file 		shp_nodes 		<- file("../includes/maps/cd_creativa_nodes_1.shp");
	file 		shp_building 	<- file("../includes/maps/cd_creativa_build_2.shp");
	
	file 		shp_mibici 		<- file("../includes/maps/mibici_spots.shp");
	image_file 	logo_mibici 	<- image_file("../includes/img/mibici_logo.png");
	
	
	geometry 	shape 			<- envelope(shp_roads);
	graph 		road_network;
	
	map<string,int> building_type 		<- ["Lugar trabajo"::1,"Negocio tradicional"::2, "Nuevo negocio"::3, "Centro cultural"::4];


	//int number_of_work_places 		<- 10;
	int number_of_traditional		<- 100;
	int number_of_new_places		<- 80;
	int number_of_cultural			<- 8;
	
	
	int number_of_low_profile		<- 500;
	int number_of_mid_profile		<- 500;
	int number_of_high_profile		<- 500;
	
	
	list<building> traditional;
	list<building> new_places;
	list<building> cultural; 
	
	
	
	init
	{
		step <- 10 #s;
		create intersection from: shp_nodes;
		create road 		from:shp_roads where (each != nil);
		
		road_network 		<- as_driving_graph(road, intersection);

		
		create mibici 	from: shp_mibici;
		
		create building from:shp_building 
		{
			type <- "Lugar trabajo";
		}
		
		
		loop element over:building
		{
			if number_of_cultural > 0
			{
				element.type <- "Centro cultural";
				add element to: cultural;
				number_of_cultural		<- number_of_cultural-1;
			}
			
			else if number_of_new_places > 0
			{
				element.type <- "Nuevo negocio";
				add element to: new_places;
				number_of_new_places	<- number_of_new_places-1;
			}
			else if number_of_traditional > 0
			{
				element.type <- "Negocio tradicional";
				add element to: traditional;
				number_of_traditional	<- number_of_traditional-1;
			}
			else
			{
				break;
			}
		}
		
		
		create car number:200;
		
		create person number: number_of_low_profile 
		{ 
			profile 			<-"Bajo";
			location 			<- any_location_in(one_of(building));
		}
		
		create person number: number_of_mid_profile 
		{ 
			profile 			<- "Medio";
			location 			<- any_location_in(one_of(building));
		}
		
		create person number: number_of_high_profile 
		{ 
			profile 			<- "Alto";
			location 			<- any_location_in(one_of(building));
		}
		
		

	}
}


species building
{
	string type;
	int FID;
	
	map<string,rgb> colors <- ["Lugar trabajo"::#darkgrey,"Negocio tradicional"::#deepskyblue, "Nuevo negocio"::#darkmagenta, "Centro cultural"::#royalblue];

	
	aspect default
	{
		draw shape color: darker(colors[type]).darker depth: rnd(10) + 2;
	}
}

species road skills: [road_skill]
{
	aspect default
	{
		draw (shape + 5#m) color: #white;
	}
}

species intersection skills: [intersection_skill] ;


species mibici 
{
	aspect default
	{
		pair<float,point> r0 	<-  -90::{1,0,0};	
		draw cube(10) at:location;
		draw logo_mibici size:20 at:location+{0,0,20} rotate: r0;
	}
}

species person skills: [moving]
{
	string 	profile;
	bool	relocate_active; // 
	map<string,float>	bussiness_preference;
	map<string,float>	transport_preference;
	
	//Target point of the agent
	string			transport;
	point 			target;
	map<int,point> 	route ;
	
	
	//Probability of leaving the building
	float 	leaving_proba <- 0.2;
	//Speed of the agent
	float 	speed <- rnd(10) #km / #h + 1;
	// Random state
	string 	state <- "in_place"; // on_route, in_place, on_route_inter
	int	 	r_step;
	
	
	aspect default 
	{
		draw sphere(5) color: #mediumturquoise;
	} 
}



species car skills: [driving] 
{
	init 
	{
		location <- one_of(intersection).location;
		vehicle_length <- 1.9 #m;
		max_speed <- rnd(50,100) #km / #h;
		max_acceleration <- 3.5;
		
	}
	
	reflex relocate when: next_road = nil and distance_to_current_target = 0.0 {
		do unregister;
		location <- one_of(intersection).location;
	}

	reflex select_next_path when: current_path = nil {
		intersection goal <- one_of(intersection);
		
		loop while: goal.location = location 
		{
			goal <- one_of(intersection);
		}
		
		do compute_path graph: road_network target: goal;
	}
	
	
	reflex commute when: current_path != nil {
		do drive;
	}
		
	

	aspect default 
	{
		draw rectangle(4,10) rotated_by (heading+90) color:( #dodgerblue) depth: 3;
		draw rectangle(4, 6) rotated_by (heading+90) color:( #dodgerblue) depth: 4;
	} 
}

experiment main type:gui
{
	output synchronized: true
	{
		layout #split;
		
		display traffic type: 3d axes: false background: rgb(50,50,50) toolbar: false {
			light #ambient intensity: 128;
			camera 'default' location: {1254.041,2938.6921,1792.4286} target: {1258.8966,1547.6862,0.0};
			
			species road 	 refresh: false;
			species building refresh: false;
			species mibici 	 refresh: false;
			species person 	 refresh: true;
			species car		 refresh: true;
		}
		
	}
	
	
}






