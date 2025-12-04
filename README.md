# gtt_qb_vehicle_damage
## A simple QB-Core based vehicle damage script for FiveM.

Note: This script was made mostly with chatgpt. I do not take full credit as I did use that for a lot of it but I did do some of it myself and I am publishing it for free for people to enjoy or use.
If you do not condone the usage of chatgpt or AI tools then just don't use the script. The intentions were for my personal use but I figured people who are new(and experienced) might want to try it out and use it.
I have tested it in a local FiveM server and it seems to work pretty good so far, however I have not tested it in a FiveM server with other people so it's a little more experimental at the moment.
I have not tested the performance/optimization either, so if there are any memory leaks or issues I am not responsible. I will however, take constructive criticism and/or feedback to make changes to improve the script.

### **Features:**  
-Works for QB-Core  
-Little to no conflicts  
-Works as advertised  
-Uses client and server sided talking to make a synced up damage script  
-Stores information in a JSON file within the script  
-Highly configurable, you can change the body and engine damage levels to where the vehicle starts smoking and will become disabled etc.  
-Has a debugger mode to show the vehicles health so you can tweak the values and see the changes etc.  
-*should* keep track of vehicles and their damage after reset (untested).  
-Allows the player to type a command "/repairgt" (by default) and it plays an animation and after 10 seconds (also configurable) it will heal the vehicle enough to allow it to drive again.  
-Sets a limit on how many times the command can be used before disabling it and starting a cooldown period (all configurable)  
-Has QB built-in notifications based on the vehicles health etc.  
-Has smoke effects when the car gets to a certain level of damage.

Enjoy!  
-Gtt
