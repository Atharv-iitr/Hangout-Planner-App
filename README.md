# Hangout-Planner-App
#  STEPS TO SETUP FLUTTER AND ANDROID STUDIO TO RUN AND COMPILE THE CODE
  steps to install flutter:-
  1) Go to https://git-scm.com/ click on download for windows and then install it
  2) Go to vs code and install flutter and dart extensions
  3) Then go to flutter.dev -> get started->windows->android->use vscode to install->follow the steps and don't clone flutter in onedrive
  4) Once you click on add SDK to path, you are done just type ctrl + shift +p -> application -> and store this new project in the same folder as of flutter
  5) Now flutter is installed if you can see the demo code, type flutter doctor in terminal and you must see only 2 errors 
  Steps to install android studio
  1) go to https://developer.android.com/studio and install it (total of 5-6 gb) 
  2) once you setup android studio open it click on More Actions->SDK Manager->select NDK Side-by-Side and install it
  3) After this go to vs code and type   flutter doctor --android-licenses, type y for every licenses
  4) Now again type flutter doctor and you must see only one error If yes then you are done
# STEPS TO RUN AND TEST THE CODE
  1) In your phone go to developer options and enable USB DEBUGGING
  2) Connect your phone and laptop with a data cable
  3) In your phone allow your laptop to connect with your phone
  4) Open VS Code, on bottom right corner you will see 'No devices' or 'Windows' click on it and select your connected phone and after that type 'flutter pub get
  5) Now go to 'Run and Debug' section and run the code, after a minute the app will run on your phone.
# Project Description
  A social hangout planning app designed to organize meetups with friends across 1st and 2nd-degree connections. The app facilitates secure and permission-based           invitations, ensuring privacy and user control. Integrated with friend graph visualization, it simplifies event creation and participation.
# Key features
  1) Friend Graph Visualization:-
     Circular interactive layout showing 1st and 2nd-degree friends.
     Animated transitions with pagination (Next Friends/Previous Friends) and page indicators.
     To organize all friends we have implemented the graph in such way that you will only see first 8 friends and then you can click on Next Friends/Previous Friends to      access next/previous 8 friends.
  2) Plan Creation & Participation
     Users can create plans with a title and description.
     Direct invites to 1st-degree friends; 2nd-degree invites require permission (only for first time after getting permission the @nd-degree becomes a pseudo-primary        friend).
  3) Search and connect
     We have implemented dynamic search bar to search username and send friend requests.
     Also in notification tab we can reject/accept friend requests of others.
  4) Plans page
     We can see both created and joined plans with plan title, plan description and all active members of the plan.
     Here we can delete or get out of a plan as well
  5) User-friendly interface
     Simple and clean UI built in flutter having cyberpunk theme
     Smooth navigations between pages and graphs.
 # Additional features
  The most difficult job was to fit all friends in graph as we cant do it in one window we thought about an idea of pagination of graph. In pagination we divided all      friends into group of 8 friends and viewed a group per window and to shift between groups we implemented Next/Previous Friends buttons. In this way we were able to      show any number of friends of an user.
  We have also created the apk of the app so that the app could be also run on your phone. For apk please go to the releases section.
  
       
