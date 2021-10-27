classdef drawdown_analyzer_script < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        byVLLabel                     matlab.ui.control.Label
        AdddefectsSBButton            matlab.ui.control.Button
        RemovenoiseButton             matlab.ui.control.Button
        ExportButton                  matlab.ui.control.Button
        NumberofdefectsLabel          matlab.ui.control.Label
        Label2                        matlab.ui.control.Label
        LowerarealimitEditField       matlab.ui.control.NumericEditField
        LowerarealimitEditFieldLabel  matlab.ui.control.Label
        FormulationButtonGroup        matlab.ui.container.ButtonGroup
        waterborneButton              matlab.ui.control.RadioButton
        solventborneButton_2          matlab.ui.control.RadioButton
        LabelArea                     matlab.ui.control.Label
        AreaLabel                     matlab.ui.control.Label
        RemoveButton                  matlab.ui.control.Button
        UITable                       matlab.ui.control.Table
        CalculateboundariesButton     matlab.ui.control.Button
        SelectregionButton            matlab.ui.control.Button
        BWfilterSlider                matlab.ui.control.Slider
        BWfilterSliderLabel           matlab.ui.control.Label
        Image                         matlab.ui.control.Image
        UIAxes2                       matlab.ui.control.UIAxes
        UIAxes_ROI                    matlab.ui.control.UIAxes
    end

    % Callbacks that handle component events
    methods (Access = private)

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

        % Button pushed function: SelectregionButton
        function SelectregionButtonPushed(app, event)
            global img;
            global img_croped;
            global low_area_limit;
            global img_gray;

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
                 disp("PUSHED")
             else
                 disp('NOT pushed')
                 low_area_limit = 1;
             end
             img_gray = rgb2gray(img_croped);
        end

        % Value changing function: BWfilterSlider
        function BWfilterSliderValueChanging(app, event)
            global changingValue;
            global img_croped;
            global img_cr_bw;
            global img_gray;
            
            % Reads up the value from the slider
            changingValue = event.Value;
            % Gray-scale image contrast enhancement
            contrast_enhanced = adapthisteq(img_gray,'ClipLimit',0.01);
            contrast_enhanced = imadjust(contrast_enhanced);
            % Setting up the threshold value for the BW image generation
            img_cr_bw = contrast_enhanced > changingValue;
            % Smoothing the edges
            sens = strel('disk', 4); 
            img_cr_bw = imopen(img_cr_bw, sens);
            % Noise removal
            img_cr_bw = bwareaopen(img_cr_bw, 60);  
            imshow(img_cr_bw, "parent", app.UIAxes_ROI); 
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            % Proper closing of the application with variables deleted
            selection = uiconfirm(app.UIFigure, 'Close the app?',...
                'Exit','Cancel','Cancel');
            switch selection
                case 'OK'
                    clear global;
                    delete(app);
                case 'Cancel'
                    return
            end
        end

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
            sens = strel("disk", 50);
            bw_4area = imclose(img_cr_bw, sens);
            figure, imshow(bw_4area);
            drawdown_area = bwarea(bw_4area);

            % Boundaries calculation
            disp(buttonText)
            % Algorithm selection based on the type of the drawdown
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

        % Button pushed function: RemoveButton
        function RemoveButtonPushed(app, event)
            global selectedRow;
            global numerated_defects_list;
            global defect_area_perc_list;
            global img_temp;
            global new_B_list;
            
            numerated_defects_list(selectedRow) = [];
            defect_area_perc_list(selectedRow) = [];
            new_B_list(selectedRow) = [];
            % Row removal. Indices is one, it means a single row is 
            % selected and we can remove it.
            if isequal(height(selectedRow), 1) 
                if selectedRow > height(app.UITable.Data) % When the last row is clicked and removed, subsequent 
                   selectedRow = height(app.UITable.Data);  % removing will throw an error, remove last row instead
                end
                app.UITable.Data(selectedRow, :) = [];
            end

            defected_area_perc_excluded = sum(defect_area_perc_list);
            % Display a calculated area
            app.LabelArea.Text = string(round(defected_area_perc_excluded,2));

            imshow(img_temp);
            hold on
            for i = 1:length(new_B_list);
                boundary = new_B_list{i};
                x = boundary(:, 2);     
                y = boundary(:, 1);
                plot(x, y, 'w', 'LineWidth', 3)
                text(x(1), y(1), string(numerated_defects_list(i)), 'Color','r','FontSize',20);
                i = i + 1;
            end

            % Update the number of defects label
            app.Label2.Text = string(length(numerated_defects_list));
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            global selectedRow;
            selectedRow = event.Indices(1);
        end

        % Selection changed function: FormulationButtonGroup
        function FormulationButtonGroupSelectionChanged(app, event)
            global buttonText;
            selectedButton = app.FormulationButtonGroup.SelectedObject;
            buttonText = selectedButton.Text
        end

        % Value changed function: LowerarealimitEditField
        function LowerarealimitEditFieldValueChanged(app, event)
            global low_area_limit;
            low_area_limit = app.LowerarealimitEditField.Value;
            % Clears the content of the table
            app.UITable.Data = [];
            app.CalculateboundariesButtonPushed
        end

        % Button pushed function: ExportButton
        function ExportButtonPushed(app, event)
            global img_cr_bw;
            global numerated_defects_list;
            headers = {'Number','Area (pixels)','Area (%)'}
            [filename,pathname]= uiputfile('*.xls','Save as');
         
            tableData = app.UITable.Data;
            eXcelTable = [headers; num2cell(tableData)];
            place_to_save = string(pathname) + string(filename)
    
            newTable = table({'a', 'b' , 10})
            writecell(eXcelTable, place_to_save);
        end

        % Button pushed function: RemovenoiseButton
        function RemovenoiseButtonPushed(app, event)

            global img_croped;
            global img_cr_bw;
            global changingValue;
            global img_gray;
 
            app.UITable.Data = [];

            % Display the selected region and selec the region to mask
            imshow(img_cr_bw);
            message = sprintf('Left click and hold to begin drawing.\nSimply lift the mouse button to finish');
            uiwait(msgbox(message));
            
            hFH = drawrectangle();
            % Create a binary image ("mask") from the ROI object.
            binaryImage = hFH.createMask();
            
            % This part puts the black drawn square on the cropped BW image
            % Convert from RGB to gray.
            rgbImage = rgb2gray(img_croped);
      
            redChannel = rgbImage(:, :, 1);
            greenChannel = rgbImage(:, :, 1);
            blueChannel = rgbImage(:, :, 1);
            desiredColor = [0, 0, 0];
            redChannel(binaryImage) = desiredColor(1);
            greenChannel(binaryImage) = desiredColor(2);
            blueChannel(binaryImage) = desiredColor(3);
            rgbImage = cat(3, redChannel, greenChannel, blueChannel);
            img_gray = rgb2gray(rgbImage);
            img_cr_bw = im2bw(img_gray);
            imshow(img_cr_bw, "parent", app.UIAxes_ROI);
       
            answer = questdlg('Remove more?', ...
	        'Remover', ...
	        'Yes','No','No');
            
            % Handle response
            switch answer
                case 'Yes'
                    while true;
                        message = sprintf('Left click and hold to begin drawing.\nSimply lift the mouse button to finish');
                        uiwait(msgbox(message));
                        hFH = drawrectangle(); % imfreehand
                        % Create a binary image ("mask") from the ROI object.
                        binaryImage = hFH.createMask();

                        redChannel = rgbImage(:, :, 1);
                        greenChannel = rgbImage(:, :, 1);
                        blueChannel = rgbImage(:, :, 1);
                        desiredColor = [0, 0, 0];
                        redChannel(binaryImage) = desiredColor(1);
                        greenChannel(binaryImage) = desiredColor(2);
                        blueChannel(binaryImage) = desiredColor(3);
                        rgbImage = cat(3, redChannel, greenChannel, blueChannel);
                        img_gray = rgb2gray(rgbImage);
             
                        figure, imshow(img_gray); 
                   
                        close(1);
                        answer = questdlg('Remove more?', ...
	                    'Remover', ...
	                    'Yes','No','No');
                        switch answer
                            case "No"
                                imshow(img_gray, "parent", app.UIAxes_ROI);
                                break
                            case "Yes"
                        end
                    end
                case 'No'
                    imshow(img_gray, "parent", app.UIAxes_ROI);    
            end
        end

        % Button pushed function: AdddefectsSBButton
        function AdddefectsSBButtonPushed(app, event)

            global img_croped;
            global img;
            global img_cr_bw;
            global indiv_area;
            global values_B;
            
            defect_area_perc_list = [];
            defect_area_pix_list = [];
            numerated_defects_list = [];
            defected_are_percentage = [];
            app.UITable.Data = [];
            added_crators_area = 0;
   
            figure, imshow(img_croped);
            answer = questdlg('Select the drawdown area', ...
	        'Add defect', ...
	        'Ok','Done','Done');
            hFH = drawpolygon('Color','g');
            drawdown_pos = hFH.Position;
            hold on
            x = drawdown_pos(:, 1);
            y = drawdown_pos(:, 2);
            plot(x, y, 'w', 'LineWidth', 2);
            drawdown_area_manual_pix = polyarea(x,y);
            
            % Handle response
            switch answer
                case 'Ok'
                    k = 1;
                    while true;
                        message = sprintf('Select the defects.');
                        uiwait(msgbox(message));
                        hFH = drawpolygon('Color','b');
                        defect_pos = hFH.Position;
                        hold on
                        x = defect_pos(:, 1);
                        y = defect_pos(:, 2);
                        plot(x, y, 'w', 'LineWidth', 2);
                        defect_area_manual_pix = polyarea(x,y);

                        defect_area_pix_list(end+1) = defect_area_manual_pix;
                        defect_area_manual_perc = defect_area_manual_pix / drawdown_area_manual_pix * 100;
                        defect_area_perc_list(end+1) = defect_area_manual_perc
                        numerated_defects_list(end+1) = k
                        k = k + 1

                        answer = questdlg('Add more defects?', ...
	                    'Add defects', ...
	                    'Yes','No','No');

                        switch answer
                            case "No"
                                app.LabelArea.Text = string(sum(defect_area_perc_list));
                                app.Label2.Text = string(length(numerated_defects_list));
                                imshow(img_croped, "parent", app.UIAxes2);
                                app.UITable.ColumnName = {'Number', 'Area, PIX','Area, %'}
                                app.UITable.ColumnWidth = {'auto'};
                                app.UITable.FontSize = 10;
                                for k = 1:length(numerated_defects_list);
                                    app.UITable.Data = [app.UITable.Data; numerated_defects_list(k), defect_area_pix_list(k), defect_area_perc_list(k)];
                                end
                                break
                            case "Yes"
                        end
                    end
                case 'No'
                    imshow(img_croped, "parent", app.UIAxes2);
            end 
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 714 552];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create UIAxes_ROI
            app.UIAxes_ROI = uiaxes(app.UIFigure);
            title(app.UIAxes_ROI, 'Selected region')
            app.UIAxes_ROI.XTick = [];
            app.UIAxes_ROI.YTick = [];
            app.UIAxes_ROI.FontSize = 10;
            app.UIAxes_ROI.Position = [433 275 204 259];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'Results')
            app.UIAxes2.XTick = [];
            app.UIAxes2.YTick = [];
            app.UIAxes2.FontSize = 10;
            app.UIAxes2.Position = [13 24 220 284];

            % Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.ImageClickedFcn = createCallbackFcn(app, @ImageClicked, true);
            app.Image.Position = [13 334 178 200];

            % Create BWfilterSliderLabel
            app.BWfilterSliderLabel = uilabel(app.UIFigure);
            app.BWfilterSliderLabel.HorizontalAlignment = 'right';
            app.BWfilterSliderLabel.Position = [371 508 51 22];
            app.BWfilterSliderLabel.Text = 'BW filter';

            % Create BWfilterSlider
            app.BWfilterSlider = uislider(app.UIFigure);
            app.BWfilterSlider.Limits = [60 200];
            app.BWfilterSlider.Orientation = 'vertical';
            app.BWfilterSlider.ValueChangingFcn = createCallbackFcn(app, @BWfilterSliderValueChanging, true);
            app.BWfilterSlider.Position = [379 295 3 198];
            app.BWfilterSlider.Value = 100;

            % Create SelectregionButton
            app.SelectregionButton = uibutton(app.UIFigure, 'push');
            app.SelectregionButton.ButtonPushedFcn = createCallbackFcn(app, @SelectregionButtonPushed, true);
            app.SelectregionButton.Position = [212 417 100 22];
            app.SelectregionButton.Text = 'Select region';

            % Create CalculateboundariesButton
            app.CalculateboundariesButton = uibutton(app.UIFigure, 'push');
            app.CalculateboundariesButton.ButtonPushedFcn = createCallbackFcn(app, @CalculateboundariesButtonPushed, true);
            app.CalculateboundariesButton.Position = [212 345 128 22];
            app.CalculateboundariesButton.Text = 'Calculate boundaries';

            % Create UITable
            app.UITable = uitable(app.UIFigure);
            app.UITable.ColumnName = {'#'; 'Area, pix'; 'Area, %'; ''};
            app.UITable.RowName = {};
            app.UITable.CellSelectionCallback = createCallbackFcn(app, @UITableCellSelection, true);
            app.UITable.FontSize = 10;
            app.UITable.Position = [257 59 279 185];

            % Create RemoveButton
            app.RemoveButton = uibutton(app.UIFigure, 'push');
            app.RemoveButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveButtonPushed, true);
            app.RemoveButton.Position = [258 25 100 22];
            app.RemoveButton.Text = 'Remove';

            % Create AreaLabel
            app.AreaLabel = uilabel(app.UIFigure);
            app.AreaLabel.HorizontalAlignment = 'right';
            app.AreaLabel.Position = [605 157 48 22];
            app.AreaLabel.Text = 'Area, %';

            % Create LabelArea
            app.LabelArea = uilabel(app.UIFigure);
            app.LabelArea.Position = [658 157 49 22];

            % Create FormulationButtonGroup
            app.FormulationButtonGroup = uibuttongroup(app.UIFigure);
            app.FormulationButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @FormulationButtonGroupSelectionChanged, true);
            app.FormulationButtonGroup.Title = 'Formulation';
            app.FormulationButtonGroup.Position = [211 453 109 73];

            % Create solventborneButton_2
            app.solventborneButton_2 = uiradiobutton(app.FormulationButtonGroup);
            app.solventborneButton_2.Text = 'solvent-borne';
            app.solventborneButton_2.Position = [11 27 95 22];
            app.solventborneButton_2.Value = true;

            % Create waterborneButton
            app.waterborneButton = uiradiobutton(app.FormulationButtonGroup);
            app.waterborneButton.Text = 'water-borne';
            app.waterborneButton.Position = [11 5 86 22];

            % Create LowerarealimitEditFieldLabel
            app.LowerarealimitEditFieldLabel = uilabel(app.UIFigure);
            app.LowerarealimitEditFieldLabel.HorizontalAlignment = 'right';
            app.LowerarealimitEditFieldLabel.Position = [374 25 90 22];
            app.LowerarealimitEditFieldLabel.Text = 'Lower area limit';

            % Create LowerarealimitEditField
            app.LowerarealimitEditField = uieditfield(app.UIFigure, 'numeric');
            app.LowerarealimitEditField.ValueChangedFcn = createCallbackFcn(app, @LowerarealimitEditFieldValueChanged, true);
            app.LowerarealimitEditField.Position = [479 25 57 22];
            app.LowerarealimitEditField.Value = 1;

            % Create Label2
            app.Label2 = uilabel(app.UIFigure);
            app.Label2.Position = [658 126 42 22];
            app.Label2.Text = 'Label2';

            % Create NumberofdefectsLabel
            app.NumberofdefectsLabel = uilabel(app.UIFigure);
            app.NumberofdefectsLabel.HorizontalAlignment = 'right';
            app.NumberofdefectsLabel.Position = [546 126 107 22];
            app.NumberofdefectsLabel.Text = 'Number of defects:';

            % Create ExportButton
            app.ExportButton = uibutton(app.UIFigure, 'push');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportButton.Position = [600 25 100 22];
            app.ExportButton.Text = 'Export';

            % Create RemovenoiseButton
            app.RemovenoiseButton = uibutton(app.UIFigure, 'push');
            app.RemovenoiseButton.ButtonPushedFcn = createCallbackFcn(app, @RemovenoiseButtonPushed, true);
            app.RemovenoiseButton.Position = [212 381 100 22];
            app.RemovenoiseButton.Text = 'Remove noise';

            % Create AdddefectsSBButton
            app.AdddefectsSBButton = uibutton(app.UIFigure, 'push');
            app.AdddefectsSBButton.ButtonPushedFcn = createCallbackFcn(app, @AdddefectsSBButtonPushed, true);
            app.AdddefectsSBButton.Position = [212 309 106 22];
            app.AdddefectsSBButton.Text = 'Add defects - SB';

            % Create byVLLabel
            app.byVLLabel = uilabel(app.UIFigure);
            app.byVLLabel.FontSize = 9;
            app.byVLLabel.Position = [13 4 28 22];
            app.byVLLabel.Text = 'by VL';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = drawdown_analyzer_script

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end