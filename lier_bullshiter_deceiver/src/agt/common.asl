{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$jacamoJar/templates/org-obedient.asl") }

/* Rules */
complement(Atom1,Atom2):- not .list(Atom1) & .term2string(Atom1,String) & .substring("~",String) & .delete("~",String,Temp) & .term2string(Atom2,Temp). 
complement(Atom1,Atom2):- not .list(Atom1) & .term2string(Atom1,String) & not .substring("~",String) & .concat("~",Atom1,Y) & .term2string(Atom2,Y).  

/* Inferences -- Theory of Mind */
believes(Ag,Prop):- Prop[source(Ag)].
// The other agent is ignorant about Prop
ignorant(Ag,Prop):- ~believes(Ag,Prop) & complement(Prop,NProp) & ~believes(Ag,NProp).
// Ignorant about Prop
ignorant(Prop):- not(Prop) & complement(Prop,NProp) & not(NProp).
//Ignorant about others' mental state
ignorant(believes(Ag,Prop)):- not(believes(Ag,Prop)) & not(~believes(Ag,Prop)).
ignorant(desires(Ag,Prop)):- not(desires(Ag,Prop)) & not(~desires(Ag,Prop)).

/* Meta-Reasoning */
member(Content,Content).
member(Content,[Content|T]).
member(Content,[H|T]) :- member(Content,T).

believes_list(Ag,[H]):-   believes(Ag,H).
believes_list(Ag,[H|T]):- believes(Ag,H) & believes_list(Ag,T).

infers(believes(Ag,Prop),believes(Ag,Need)):- believes(Ag,inference(Prop,Need)).
infers(believes(Ag,Prop),believes(Ag,Need)):- believes(Ag,inference(Prop,S)) & member(Need,S). // 2 premisses for the inference


/* Domain-Dependent Plans */

+!open(Aid) <- openSalesRoom[artifact_id(Aid)].
+!enter(Aid) <- enter[artifact_id(Aid)].
+!leave(Aid) <- .wait(3000); leave[artifact_id(Aid)].

+!tell(Agent,Prop) <- .wait(500); .send(Agent,tell,Prop).
+!ask(Agent,Prop) <- .wait(1000); .send(Agent,ask,Prop).

+!believes(Ag,Prop) <- .suspend(believes(Ag,Prop)). //simulating the car dealer desires
+!check_deceive(Ag): .desire(believes(Ag,T)) & desires(Ag,T) & (believes(Ag,inference(T,S)) & believes_list(Ag,S)) <- .print("I did deceive the ", Ag, " about ", T).
+!check_deceive(Ag) <-  .print("I did NOT deceive the ", Ag, "!").

/* Domain Perception */
+client(Name): .my_name(car_dealer) & .print(Name, " entered in the Saleroom!") <- +desires(Name,buy(_)).
-client(Name): .my_name(car_dealer) & .print(Name, " leaved in the Saleroom!") <- !!check_deceive(Name).

/* Performatives + Decision Making */
/* TELL */
+!kqml_received(Sender, tell, NS::Content, MsgId)
		<- +believes(Sender,Content).

/* ASK */
/* Receiver believes on that */		
+!kqml_received(Sender, ask, NS::Content, MsgId): 
		infers(De,believes(Sender,Content)) & .desire(De) &
		ignorant(believes(Sender,Content)) & Content
	<- 	
		.print("Agent ", Sender, " asked ", Content ," :: Telling the truth -- ", Content);
		.send(Sender,response,Content);
		+believes(Sender,Content).
		
/* Receiver believes the opposite */		
+!kqml_received(Sender, ask, NS::Content, MsgId): 
		infers(De,believes(Sender,Content)) & .desire(De) &
		ignorant(believes(Sender,Content)) & complement(Content,NContent) & NContent
	<- 	
		.print("Agent ", Sender, " asked ", Content ," :: Telling a lie -- ", Content, ", the truth is -- ", NContent);
		.send(Sender,response,Content);
		+believes(Sender,Content).

/* Receiver is ignorant */
+!kqml_received(Sender, ask, NS::Content, MsgId): 
		infers(De,believes(Sender,Content)) & .desire(De) &
		ignorant(believes(Sender,Content)) & ignorant(Content)
	<- 	
		.print("Agent ", Sender, " asked ", Content ," ::  Telling a Bullshit -- ", Content, ", the truth is -- ", ignorant(Content));
		.send(Sender,response,Content);
		+believes(Sender,Content).
		
/* RESPONSE  */
+!kqml_received(Sender, response, NS::Content, MsgId)
	<- 	.add_nested_source(Content,Sender,AContent);
		-+AContent.

		