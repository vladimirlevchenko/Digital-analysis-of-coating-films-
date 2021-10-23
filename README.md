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

<p align="center">
<img src="images/algorithm.png" width="400">
  </p>
<figcaption align = "center"><b>Fig.1 Example of the solvent- and water-borne drawdowns</b>
</figcaption>

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

It is seldomly the whole uploaded picture that is going to be analyzed. In most cases, it is only a specific region that is of interest. The "Select region"-button was introduced so that user could select the region of interest (ROI) him/herself. ROI was selected using a *drawrectangle* function. After the rectangle has been placed, it's position was readed and the uploaded image was then croped with the constrains that the ROI implied.  

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

To further analyze the croped region form the previous step, it has to be converted to the black-and-white (BW) image. Here I though to take down two flies on one smack - convert ot BW, smooth the edges of the defects and filter off the noisy pixels. Since the selected region is still a RGB image, it must be converted to the gray-scale image using an *rgb2gray* function. The contrast of the gray-scale image was enhanced by means of *adapthisteq* and *imadjust* functions. 
The convertation to the BW image is fairly simple and was achieved by threshholding the intensity of the gray image using *changingValue*-variable. This variable was being read from the sliding bar. So by manually changing the sliding bar value, the "depth" of BW image can be scanned, revealing more or less defects depending on the needs.  

<p align="center">
<img src="images/GIF_BWslider.gif" width="400">
  </p>
<figcaption align = "center"> 
  <b>Fig.2 Example of the solvent- and water-borne drawdowns</b>
</figcaption>

Function *bwareaopen* smoothes the edges around the defects so they do not look sharp. The rest of the code plots the BW figure into the UIAxis. 

```Matlab
% Value changing function: BWfilterSlider
        function BWfilterSliderValueChanging(app, event)
            global changingValue;
            global img_croped;
            global img_cr_bw;
            
          % Reads up the value from the slider
            changingValue = event.Value;
            img_gray = rgb2gray(img_croped);
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
Example
<p align="center">
<img src="images/BW_example.png" width="400">
  </p>
<figcaption align = "center"> 
  <b>Fig.2 Example of the solvent- and water-borne drawdowns</b>
</figcaption>

example 2

Boundaries calculations
When the defects are represented as BW image, we can draw the borders on the interface between white and black pixels. That would give us coordinates of each boundary associated with defects, which then could be converted to the area. The calculated area of each defect would then be divided on the area of the whole drawdown (or the selected region of interest), stored in the list as pixel and percentage area. The sum of area of each individual defect would give us then a total defectiveness of the drawdown, in percentage.

Single defect, % = defect's area (pix^2) / total area * 100

So the first thing that has to be done is to calculate the area of the whole drawdown or the selected region. This is done using the *bwarea* function that calculates the area in the binary image (the "white" part in the BW image). But before we apply this function, we have to make sure that the defects are filled (in the BW image the defects are "black") and became "white". That would ensure that the defects are gone and the total area would be calculated as the "undefected" one.

defects_removal_2

Example
<p align="center">

  <img src="images/defects_removal_2.png" width="300">
  </p>
<figcaption align = "center"> 
  <b>Fig.2 Example of the solvent- and water-borne drawdowns</b>
</figcaption>

```Matlab
% Button pushed function: CalculateboundariesButton
        function CalculateboundariesButtonPushed(app, event)
            global img_cr_bw;
            global k_numbers_list;  
            global numerated_defects_list;
            global defect_area_perc_list;
            global buttonText;
            global img_temp;
            global new_B_list;
            global low_area_limit;
            global defect_area_pix_list;
        
            defect_area_perc_list = [];
            defect_area_pix_list = [];
            numerated_defects_list = [];

            app.UITable.Data = [];
            disp(low_area_limit)
            % Calculate the area of the whole drawdown. The defects are
            % filled.
            se = strel("disk", 50);
            bw_4area = imclose(img_cr_bw, se);
            figure, imshow(bw_4area);
            drawdown_area = bwarea(bw_4area);
     %       figure, imshow(img_cr_bw);

            % Boundaries calculation
            disp(buttonText)
            if isequal(buttonText, 'water-borne');
                formulation = 'holes'
            else
                formulation = 'noholes'
            end
            disp(formulation)

            [B,L] = bwboundaries(img_cr_bw, formulation);
            img_temp = label2rgb(L, @jet, [.0 .0 .0]);
            imshow(img_temp);
            hold on
            k_numbers_list = {}; % create an empty list of numbers of boundaries to be used in BoxList. 
      
            all_defects_area_pix = 0;
        
            m = 0;
            new_B_list = [];

            for i = 1:length(B);
                defect = B{i};
                x = defect(:,2);
                y = defect(:,1);
                defect_area_pix = polyarea(x,y);
                if defect_area_pix > low_area_limit;
                    m = m + 1;
                    defect_area_pix_list(end+1) = defect_area_pix;
                    defect_area_perc = defect_area_pix / drawdown_area * 100;
                    defect_area_perc_list(end+1) = defect_area_perc;
                    all_defects_area_pix = all_defects_area_pix + defect_area_pix;
                    numerated_defects_list(end+1) = string(m);
                    %defect = B{m};
                    new_B_list{end+1} = defect;
                end
            end

            for k = 1:length(new_B_list);
                boundary = new_B_list{k};
                x = boundary(:, 2);     
                y = boundary(:, 1);
                plot(x, y, 'w', 'LineWidth', 3)
                text(x(1), y(1), string(k), 'Color','r','FontSize',20);
                k_numbers_list{end+1} = k;
                disp(new_B_list{k})
                disp(k_numbers_list{k})
            end
            disp(k_numbers_list)
            imshow(img_temp, "parent", app.UIAxes2);

            app.UITable.ColumnName = {'Number', 'Area, PIX','Area, %'}
            app.UITable.ColumnWidth = {'auto'};
            app.UITable.FontSize = 10;
            for k = 1:length(numerated_defects_list);
                app.UITable.Data = [app.UITable.Data; numerated_defects_list(k), defect_area_pix_list(k), defect_area_perc_list(k)];
            end

            defected_area_perc = sum(defect_area_perc_list);
            % Display the calculated area
            app.LabelArea.Text = string(round(defected_area_perc, 4));

            % Update the number of defects label
            app.Label2.Text = string(length(numerated_defects_list));
        end
```
