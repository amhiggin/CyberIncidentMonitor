# CyberIncidentMonitor

Computer Engineering Masters research project, Trinity College Dublin.

Concerned with: 
* The role of honeypot technologies in protecting critical infrastructures through their application in cyber-incident monitoring, accounting for cost and legacy systems;
* The tracking and evaluation of current IoT botnets based on attraction to characteristics of honeypots.

7th March 2018: Can SSH and Telnet into the router container as cisco, admin, root users successfully.
The current issue is that when attempting to SSH into the honeypot containers on the DMZ network, it seems that it does a reflected SSH login back into the router.
NMAP results are consistent with a re-attempted login into the router.
