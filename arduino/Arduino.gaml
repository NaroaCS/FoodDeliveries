model Arduino_Listener

global {	


	init {
		create NetworkingAgent number: 1 {
		   do connect protocol: "arduino";
		}		
	}
}

species NetworkingAgent skills:[network] {

	reflex fetch when:has_more_message() {	
		loop while:has_more_message()
		{
			message s <- fetch_message();
			write "fetch messages" + s.contents;
		}
	}
}



experiment test_Arduino type: gui {
	output {
		display d {
			species NetworkingAgent;	
		}
	}
}

