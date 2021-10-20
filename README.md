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

The app's interface:
<p align="center">
<img src="images/app_interface.png" width="400">
  </p>
<figcaption align = "center"> 
  <b>Fig.2 Example of the solvent- and water-borne drawdowns</b>
</figcaption>

## Code

To upload the image, one has to click on the image UI component. Three empty arrays, which are going to be used later on, are initilized. It is not critical to initialize them at this stage, but I wanted to make sure that I would not forget to do it later. When the image is uploaded, it appears in the same UI image icon that you clicked on.

```Matlab
% Image clicked function: Image
        function ImageClicked(app, event)
            global img;
            global defect_area_perc_list;
            global defect_area_pix_list;
            global numerated_defects_list;

            defect_area_perc_list = [];
            defect_area_pix_list = [];
            numerated_defects_list = [];

            [a,b] = uigetfile({'*.*'});
            if isequal(a, 0);
                disp("No image selected");
            else
                img = imread([b,a]);
                app.Image.ImageSource = img;
            end
        end

```
To switch between different algorithms (and parameters) for SB and WB drawdowns, I added a app.ButtonGroup. It reads up a type of used formulation (solvent-borne or water-borne) and stores it under the variable "buttonText". 

```Matlab
% Selection changed function: FormulationButtonGroup
        function FormulationButtonGroupSelectionChanged(app, event)
            global buttonText;
            selectedButton = app.FormulationButtonGroup.SelectedObject;
            buttonText = selectedButton.Text
        end
```

Select region
```Matlab
% Button pushed function: SelectregionButton
        function SelectregionButtonPushed(app, event)
            global img;
            global img_croped;
            global low_area_limit;

            figure, imshow(img);
            % Clears the content of the table
            app.UITable.Data = [];
            roi = drawrectangle('Color','b'); % draw the rectangle
                if isvalid(roi);
                    pos = roi.Position;
                    img_croped = imcrop(img, pos);
                    imshow(img_croped, "parent", app.UIAxes_ROI);  
                    close % close the image after selection
                else
                    disp("Cancelled");
                end

             if isequal(low_area_limit, true);
                 disp("PUESHED")

             else
                 disp('NOT pushed')
                 low_area_limit = 1;
             end
```
Create black-and-white image
```Matlab
% Value changing function: BWfilterSlider
        function BWfilterSliderValueChanging(app, event)
            global changingValue;
            global img_croped;
            global img_cr_bw;
            
          % Reads up the value from the slider
            changingValue = event.Value;
            img_gray = rgb2gray(img_croped);
            img_adhist = adapthisteq(img_gray,'ClipLimit',0.005, 'Range', 'full');
            claheI = adapthisteq(img_gray,'ClipLimit',0.01);
            claheI = imadjust(claheI);

            img_cr_bw = claheI > changingValue; % change this number to change the sensitivity
            se = strel('disk', 4); % change to change the sensitivity
            img_cr_bw = imopen(img_cr_bw, se);
            % Noise removal
            img_cr_bw = bwareaopen(img_cr_bw, 60);  
            imshow(img_cr_bw, "parent", app.UIAxes_ROI);
        end
```
