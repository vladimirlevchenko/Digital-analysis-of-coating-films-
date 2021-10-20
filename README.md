# Digital analysis of coating films 
This repository is created to introduce the digital solution to the drawdown analysis in paint industry.

## Introduction

When new paint or formulation is developed, it's properties have to be thoroughly investigated before the product ends up on the shop's shelf or customer's wall. One of the methods to assess the properties of the paint is called drawdown analysis. Now, depending on type of solvent that paint includes, one can find two types of paints - solvent-borne and water-borne. 

<p align="center">
<img src="images/solvent_borne_example.jpeg" width="400">
<img src="images/water_borne_example.jpeg" width="400">
  </p>
<figcaption align = "center"><b>Fig.1 Example of the solvent- and water-borne drawdowns</b>
</figcaption>


The water- and solvent-borne (WB and SB for simplicity) drawdowns are prepared on different substrates - paper charts or glass plates for WB and metallic plates for SB. Such differences also affect the film appearance. For WB drawdowns, it is fairly straighforward to see crators, flow and levelling defects and other surface defects. For the SB drawdowns, one has to carefully analyze the film's surface... 

Flow, wetting, crators 

## Algorithm

The algorith for the analysis is based on image processing techniques. Because the defects on SB and WB plates are presented differently (WB - readily visible crators; SB - marked regions), we should take into account when setting up the algorithm. 

WB - two colored charts
SB - circle the defects using a marker.

(figure of the marked SB drawdown)

## App
<p align="center">
<img src="app_interface.png" width="400">
  </p>
<figcaption align = "center"><b>Fig.1 Example of the solvent- and water-borne drawdowns</b>
</figcaption>
