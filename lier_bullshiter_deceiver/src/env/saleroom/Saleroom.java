package saleroom;

import cartago.*;
import jason.asSyntax.Atom;

public class Saleroom extends Artifact {
	
	    @OPERATION public void init()  {
	        defineObsProperty("status",     "CLOSE");
	    }

	    @OPERATION public void openSalesRoom()  {
	        getObsProperty("status").updateValue("OPEN");
	    }

	    @OPERATION public void closeSalesRoom()  {
	    	getObsProperty("status").updateValue("CLOSE");
	    }

	    @OPERATION public void enter() {
	        defineObsProperty("client", new Atom(getCurrentOpAgentId().getAgentName()));
	    }
	    
	    @OPERATION public void leave() {
	        removeObsPropertyByTemplate("client", new Atom(getCurrentOpAgentId().getAgentName()));
	    }
	}


