function [  ] = DendV5()
%DENDV Render a dendrite's electrical properties
%   DendV visualizes the various current flow within a dendrite compartment
%   Including: Axonal, NMDA, K+, Na+, Leak, Transmembrane

%   DendV was built using MATLAB
%   For any issues or questions, please contact Andrew Schreiber at
%   aschreib@usc.edu
%   USC Lab for Neural Computation

%{
TO DO:
-Place Box chart at the top
-Vertical lines showing alignment (perhaps boolean value to enable/disable)
-Contextual voltage chart; set a certain zoom (x seconds, minimum of maxcompart ms).


Later:
-Make colormap based on absolute values instead of relative
-Make max of line graph the max of the voltage
-Set loading screen as intro



%}


%Initializing
pause on;
close all;
scrsz = get(0,'ScreenSize');
startbarsize=45;
Filename='BardiaSimulation.mat';
Title=strcat('DendV5 -  {',Filename,'}');

%Loads matrix data file
Datafile= load(Filename);

%Main Figure Window
figure('Position', [0 startbarsize scrsz(3) scrsz(4)*.92],...
    'Toolbar', 'none',...
    'Name',Title,...
    'NumberTitle','off');
set(gcf,'Units','normal')
set(gca,'Position',[0 0 1 1])
set(0,'defaultTextFontUnits', 'normalized',...
      'defaultTextFontSize', .020)
%Load Frame
text(.3,.5,'Loading...', 'FontSize', .2);



%initializing
global sodium;
global potass;
global nmda;
global ampa;
global axial;
global volt;
global distance;
global pauser;
global diam;
global cap;
global pas;

sodium = Datafile.ina;
potass = Datafile.ik;
nmda = Datafile.inmda;
ampa = Datafile.iampa;
axial = Datafile.iaxial;
volt = Datafile.v;
distance = Datafile.d; %distance from soma in microns
diam = Datafile.diam; %microns
cap= Datafile.icap;
pas= Datafile.ipas;

%Absolute values of data points. Non-zero.
AbsNa = -1*(sodium-eps);
AbsK = potass+eps;
AbsAMPA = -1*(ampa -eps);
AbsNMDA = -1*(nmda -eps);
AbsV = abs(volt+eps);
AbsAxial = abs(axial+eps);
AbsCap= abs(cap +eps);
AbsPas=abs(pas+eps);


%General Settings
set(0,'CurrentFigure',figure(1) );
[~,maxtime]=size(ampa);
[maxcompart,~]=size(potass);
continued=true;
steps=1;                     %Temporal jump per loop
Time=1000;                      %Start time
pauser=0;                      %Set to 1 to disable bar chart, 0 to enable
LegendSpace=.10;
LegendStart=1-LegendSpace;
SpaceConstant=1/maxcompart *(LegendStart);  %Width of one compartment
Cushion=.015;                               %Vertical space between graphs 
recordmovie=false;                          %Records a video into current directory


%Bar chart settings
BaseLineX1=.1*SpaceConstant;            %Adjust space between midlines
BaseLineX2=BaseLineX1+SpaceConstant*.8; %Adjust .1 or .8 to adjust space from left and right, respectively
BarWidth=SpaceConstant*.8/6;            %6 bars currently **replace with a GetBars
BarZoom=2.5;                            %Manual scalar for barsize
LineY1=.835;                            %Midline location
MaxBar=.165 - Cushion;                  %Maximum allowed size for bar
BarMaxLine= LineY1 + .165 - Cushion;
BarMinLine= LineY1 - .165 + Cushion;
SodiumColor=   [1 0 0];    %[R G B]
PotassiumColor=[1 .9 0];
AMPAColor=     [0 1 1];
NMDAColor=     [0 0 1];
CapColor=      [.8 .5 .5];
PasColor=      [0 1 0];


%Box chart settings
DifftoZero=min(ceil(volt(:)));                     %Takes smallest value in volt
VoltRange= abs( max(ceil(volt(:))) - DifftoZero);  %Range of Volt; works {++,+-,-+,--}
boxcolormap=colormap(jet(VoltRange));              %Sets range-based Jet colormap
AxialScaler=(.9*SpaceConstant)/max(abs(axial(:))); %Multiplies with axial current to fit in compartment
LineY2=.505;                                       %Midpoint of Box chart
BoxScaler=1/max(diam) * (.15 - 2*Cushion);         %*(.33) for scale to 1/3 of figure
BoxMaxLine=LineY2+ .075 - Cushion;
BoxMinLine=LineY2- .075 + Cushion;


%Line chart settings
VoltScaler=(1/max(abs(volt(:)))) * (.165 - Cushion);    %Set * (.165) so maxline is within boundaries and cushion
LineChartMidY= .165;
LineMaxLine=LineChartMidY +.165 - Cushion;
LineMinLine=LineChartMidY -.165 + Cushion;

clf;

%Spacing for arrows
LineX1 =BaseLineX1;
LineX2 =BaseLineX2;
BarX=BaseLineX1;
SodiumX=1:1:maxcompart;
PotassiumX=1:1:maxcompart;
AMPAX=1:1:maxcompart;
NMDAX=1:1:maxcompart;
CapX=1:1:maxcompart;
PasX=1:1:maxcompart;



%Time/Step-size
%str3 =['STEP: ', num2str(steps/10), 'ms'];
%StepDisplay=annotation('textbox', [.8 .97 .07 .03],...
%                       'String', str3,...
%                       'LineStyle', 'none'); %position [fromleft frombottom width height]
str2=['TIME: ', num2str(Time/10),'ms'];
TimeDisplay=annotation('textbox', [.7 .97 .1 .03],...
                       'String', str2,...
                       'LineStyle', 'none');



%Legend display
LegCush=.0025;
annotation('line', [(LegendStart+LegCush) (LegendStart+LegCush)], [BarMaxLine BarMinLine],...
            'LineWidth', 5);
annotation('line', [(LegendStart+LegCush) (LegendStart+LegCush)], [BoxMaxLine BoxMinLine],...
            'LineWidth', 5);
annotation('line', [(LegendStart+LegCush) (LegendStart+LegCush)], [LineMaxLine LineMinLine],...
            'LineWidth', 5);



BarMaxStr=[num2str(((BarMaxLine-BarMinLine)/2)/BarZoom), ' mV'];
annotation('textbox',[LegendStart, BarMaxLine-.5*Cushion, .1, .05],... %-.5*Cushion for ideal alignment
           'String', BarMaxStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom');
           

BarMinStr=[num2str(((BarMaxLine-BarMinLine)/2)/BarZoom*-1), ' mV']; 
annotation('textbox',[LegendStart, BarMinLine-.5*Cushion, .1, .05],...
           'String', BarMinStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 

       
BoxMaxStr=[num2str(max(diam)), ' µm3']; 
annotation('textbox',[LegendStart, BoxMaxLine-.5*Cushion, .1, .05],...
           'String', BoxMaxStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 

BoxMinStr=['0', ' µm3']; 
annotation('textbox',[LegendStart, BoxMinLine-.5*Cushion+.01, .1, .05],...
           'String', BoxMinStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 


LineMaxStr=[num2str(max(abs(volt(:)))), ' mV'];

annotation('textbox',[LegendStart, LineMaxLine-.5*Cushion, .1, .05],...
           'String', LineMaxStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 

LineMinStr=[num2str(max(abs(volt(:)))*-1), ' mV']; 
annotation('textbox',[LegendStart, LineMinLine-.5*Cushion, .1, .05],...
           'String', LineMinStr,...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 
       
annotation('line', [0 LegendStart], [LineChartMidY LineChartMidY],...
           'LineStyle', '--'); 
       

annotation('textbox',[LegendStart, LineChartMidY-.5*Cushion, .1, .05],...
           'String', '0 mV',...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 

 %Sodium Legend
annotation('rectangle', ... #x, y, width, height
           [LegendStart+.03 LineY1+.08 BarWidth .02],...
           'FaceColor',SodiumColor,... %R G B
           'LineWidth', .0005);
annotation('textbox',[LegendStart+.032, LineY1+.08, .1, .02],...
           'String', '  Sodium',...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 
       
       
%Potassium Legend       
annotation('rectangle', ... #x, y, width, height
           [LegendStart+.03 LineY1+.05 BarWidth .02],...
           'FaceColor',PotassiumColor,... %R G B
           'LineWidth', .0005);
       annotation('textbox',[LegendStart+.032, LineY1+.05, .1, .02],...
           'String', '  Potassium',...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 
       
%AMPA Legend
annotation('rectangle', ... #x, y, width, height
           [LegendStart+.03 LineY1+.020 BarWidth .02],...
           'FaceColor',AMPAColor,... %R G B
           'LineWidth', .0005);
annotation('textbox',[LegendStart+.032, LineY1+.02, .1, .02],...
           'String', '  AMPA',...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 
       
%NMDA Legend       
annotation('rectangle', ... #x, y, width, height
           [LegendStart+.03 LineY1-.01 BarWidth .02],...
           'FaceColor',NMDAColor,... %R G B
           'LineWidth', .0005);
annotation('textbox',[LegendStart+.032, LineY1-.01, .1, .02],...
           'String', '  NMDA',...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 
       
%Capacitive Legend
annotation('rectangle', ... #x, y, width, height
           [LegendStart+.03 LineY1-.04 BarWidth .02],...
           'FaceColor',CapColor,... %R G B
           'LineWidth', .0005);
annotation('textbox',[LegendStart+.032, LineY1-.04, .1, .02],...
           'String', '  Capacitive',...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom'); 
       
%Passive Legend       
annotation('rectangle', ... #x, y, width, height
           [LegendStart+.03 LineY1-.07 BarWidth .02],...
           'FaceColor',PasColor,... %R G B
           'LineWidth', .0005);
annotation('textbox',[LegendStart+.032, LineY1-.07, .1, .02],...
           'String', '  Passive',...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom');     
       
       
%more legend       
annotation('textarrow', [LegendStart+.02 LegendStart+.02], [LineY1+.04 LineY1+.08],...
           'String' , 'Out')       
       
annotation('textarrow', [LegendStart+.02 LegendStart+.02], [LineY1-.04 LineY1-.08],...
           'String' , 'In')       
    
       
annotation('textbox',[0 BoxMinLine-.03 .1 .03],...
           'String', strcat(num2str(min(distance)), ' µm (from soma)'),...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom');
annotation('textbox',[LegendStart-.05 BoxMinLine-.03 .06 .06],...
           'String', strcat(num2str(max(distance)), ' µm (from soma)'),...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom');
       
  %Proximal <-> Distal     
annotation('doublearrow', [.4 .6], [BoxMinLine-.02 BoxMinLine-.02])  
annotation('textbox',[.34 BoxMinLine-.03 .04 .04],...
           'String', 'Proximal',...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom');
annotation('textbox',[.61 BoxMinLine-.03 .04 .04],...
           'String', 'Distal',...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom');             

 %axial legend   
annotation('line', [LegendStart+.03 LegendStart+.03],[LineY2+.035 LineY2-.045])
annotation('rectangle',...
        [LegendStart+.03 .49 .9*SpaceConstant .012],...    
        'LineWidth', .0001, ...
        'FaceColor', [.2 .1 .1]);

annotation('textbox',[LegendStart+.015+.9*SpaceConstant LineY2-.05 .04 .04],...
           'String', strcat(num2str(max(abs(axial(:)))), ' mV Axial'),...
           'LineStyle', 'none',...
           'VerticalAlignment', 'bottom');
%Line Chart - Voltage string
annotation('textarrow', [LegendStart+.05 LegendStart+.05], [.12 .22],...
           'String', 'Voltage');
       
       
%Setting up display
for arrowloop=1:maxcompart
BoxX(arrowloop)=SpaceConstant*arrowloop-SpaceConstant;
end




for arrowloop=1:maxcompart
    if continued==false
        break;
    end
    
    
    %Midlines
    annotation('line', [LineX1 LineX2], [LineY1 LineY1]);
    
    
    %Sodium
    SodiumBarSize=min(MaxBar, BarZoom*AbsNa(arrowloop, Time));
    SodiumBar(arrowloop)=annotation('rectangle', ... #x, y, width, height ; preallocating makes no speed difference
        [BarX LineY1-SodiumBarSize BarWidth SodiumBarSize],...
        'FaceColor',SodiumColor,... %R G B
        'LineWidth', .0005);
    SodiumX(arrowloop)= BarX;
    BarX=BarX+BarWidth;    %Set next bar
    
    
    
    %Potassium current
    PotassiumBarSize=min(MaxBar, BarZoom*AbsK(arrowloop, Time));
    PotassiumBar(arrowloop)=annotation('rectangle',...
        [BarX LineY1-.0005 BarWidth PotassiumBarSize],...
        'FaceColor',PotassiumColor,...    
        'LineWidth', .0005);
    PotassiumX(arrowloop)= BarX;
    BarX=BarX+BarWidth;
    
    
    %AMPA current
    
    AMPABarSize=min(MaxBar, BarZoom*AbsAMPA(arrowloop, Time));
    AMPABar(arrowloop)=annotation('rectangle',...
        [BarX LineY1-AMPABarSize BarWidth  AMPABarSize],...
        'FaceColor',AMPAColor,...
        'LineWidth', .0005);
    
    AMPAX(arrowloop)= BarX;
    BarX=BarX+BarWidth;
    
    %NMDA current
    
    
    NMDABarSize=min(MaxBar, BarZoom*AbsNMDA(arrowloop, Time));
    NMDABar(arrowloop)=annotation('rectangle',...
        [BarX LineY1-NMDABarSize BarWidth NMDABarSize],...
        'FaceColor',NMDAColor,...
        'LineWidth', .0005);
    
    NMDAX(arrowloop)= BarX;
    BarX= BarX + BarWidth;
    
    
    %Capacitive current
    CapBarSize=min(MaxBar, BarZoom*AbsCap(arrowloop, Time));
    if cap(arrowloop, Time)>0
        
        CapBar(arrowloop)=annotation('rectangle',...
            [BarX LineY1-.0005 BarWidth CapBarSize],...
            'FaceColor',CapColor,...
            'LineWidth', .0005);
        
    else
        CapBar(arrowloop)=annotation('rectangle',...
            [BarX LineY1-CapBarSize BarWidth CapBarSize],...
            'FaceColor',CapColor,...
            'LineWidth', .0005);
    end
    CapX(arrowloop)= BarX;
    BarX= BarX + BarWidth;
    
    %Passive current here
    PasBarSize=min(MaxBar, BarZoom*AbsPas(arrowloop, Time));
    PasBar(arrowloop)=annotation('rectangle',...
        [BarX LineY1-.0005 BarWidth PasBarSize],...
        'FaceColor',PasColor,...
        'LineWidth', .0005);
    PasX(arrowloop)=BarX;
    
    
    %Move to next compartment
    LineX1 =LineX1 + SpaceConstant;
    LineX2 =LineX2 + SpaceConstant;
    BarX=LineX1;
    
    
 %Box Chart
    BoxSize=BoxScaler*diam(arrowloop);          %Scales current value to range of rendering
    BoxFromBot=LineY2-.5*BoxSize;               %Determines lowest point of box; subtracts half box size from midline
    
    ColorNumber=ceil(volt(arrowloop,Time))+abs(DifftoZero);
    BarColor=[boxcolormap(ColorNumber,1) boxcolormap(ColorNumber,2) boxcolormap(ColorNumber,3)];
    
    DiamBar(arrowloop)=annotation('rectangle',[BoxX(arrowloop) BoxFromBot SpaceConstant BoxSize],...
        'FaceColor', BarColor,...
        'EdgeColor', 'none'); %fromleft frombottom width height
    
    
    %Axial current
    ScaledArrowX= AxialScaler*axial(arrowloop,Time); %Sets range to -1 to 1
    ArrowX2=max(.001,min(1, -1*ScaledArrowX)); % *-1 to correct axial directions
    
    AxialBox(arrowloop)=annotation('rectangle',...
        [BoxX(arrowloop) .49 ArrowX2 .012],...    %Draws
        'EdgeColor', 'none', ...
        'FaceColor', [.2 .1 .1]);

    
 %Line Chart
    VoltLine(arrowloop)=annotation('line', [BoxX(arrowloop) (BoxX(arrowloop)+SpaceConstant)], [.2 .2],...
                'Color', [.5 .2 1],...
                'LineWidth', 2);
        

end


if recordmovie==true
  writerObj= VideoWriter(strcat(Filename, '_movie.avi'));
  writerObj.FrameRate=10;
   open(writerObj);
end


%-------------Main Display Loop-----------------%
while Time<maxtime && continued==true    
    tic %to smooth
 %   set(0,'CurrentFigure',figure(1) );
    
 %   str3=['STEP: ',num2str(steps/10),'ms'];
%    set(StepDisplay, 'String', str3);
    str3=['TIME: ',num2str(Time/10),'ms'];
    set(TimeDisplay, 'String', str3) %(closing window causes program to end here)
    
    
    for arrowloop=1:maxcompart
        
        SodiumBarSize=min(MaxBar, BarZoom*AbsNa(arrowloop, Time));
        SodiumBarPos=[SodiumX(arrowloop) LineY1-SodiumBarSize BarWidth SodiumBarSize];
        set(SodiumBar(arrowloop),'Position', SodiumBarPos);
        
        PotassiumBarSize=min(MaxBar, BarZoom*AbsK(arrowloop, Time));
        PotassiumBarPos=[PotassiumX(arrowloop) LineY1-.0005 BarWidth PotassiumBarSize];
        set(PotassiumBar(arrowloop),'Position', PotassiumBarPos);
        
        AMPABarSize=min(MaxBar, BarZoom*AbsAMPA(arrowloop, Time));
        AMPABarPos=[AMPAX(arrowloop) LineY1-AMPABarSize BarWidth AMPABarSize];
        set(AMPABar(arrowloop),'Position', AMPABarPos);
        
        
        NMDABarSize=min(MaxBar, BarZoom*AbsNMDA(arrowloop, Time));
        NMDABarPos=[NMDAX(arrowloop) LineY1-NMDABarSize BarWidth NMDABarSize];
        set(NMDABar(arrowloop),'Position', NMDABarPos);
        
        
        if cap(arrowloop, Time)>0
            
            CapBarSize=min(MaxBar, BarZoom*AbsCap(arrowloop, Time));
            CapBarPos=[CapX(arrowloop) LineY1-.0005 BarWidth CapBarSize];
            set(CapBar(arrowloop),'Position', CapBarPos);
            
        else
            
            CapBarSize=min(MaxBar, BarZoom*AbsCap(arrowloop, Time));
            CapBarPos=[CapX(arrowloop) LineY1-CapBarSize BarWidth CapBarSize];
            set(CapBar(arrowloop),'Position', CapBarPos);
        end
        
        PasBarSize=min(MaxBar, BarZoom*AbsPas(arrowloop, Time));
        PasBarPos=[PasX(arrowloop) LineY1-.0005 BarWidth PasBarSize];
        set(PasBar(arrowloop),'Position', PasBarPos);
        
        
        %Bar Chart
        ColorNumber=ceil(volt(arrowloop,Time))+abs(DifftoZero);
        BarColor=[boxcolormap(ColorNumber,1) boxcolormap(ColorNumber,2) boxcolormap(ColorNumber,3)];
        set(DiamBar(arrowloop),'FaceColor',BarColor);

        ScaledArrowX= AxialScaler*axial(arrowloop,Time);  %Sets range to -1 to 1
        ArrowX2=abs(min(1, -1*ScaledArrowX)); % *-1 to correct axial directions
        
        if(axial(arrowloop,Time)<0)
            AxialBoxPosition=[BoxX(arrowloop) LineY2-.01 ArrowX2 .012];
        else
            AxialBoxPosition=[BoxX(arrowloop)-ArrowX2 LineY2-.01 ArrowX2 .012];
        end
        
        set(AxialBox(arrowloop),'Position', AxialBoxPosition);
 

        
        
        %Voltage Line
        VLY1=VoltScaler*volt(arrowloop,Time);
        VLY2=VoltScaler*volt(arrowloop+1,Time);
        VoltLineY= [(VLY1+LineChartMidY) (VLY2+LineChartMidY)];
        
        set(VoltLine(arrowloop),'Y', VoltLineY);
        
        
        
    end
    
    
    
   % set(0,'CurrentFigure',figure(1) );
    
    %MovieFrames(Time)=getframe;
    
    drawnow;
    if recordmovie==true
     currentframe=getframe(gcf);
     writeVideo(writerObj, currentframe);
    end
    
    loopspeed=toc;
    if (loopspeed<.3 && recordmovie==false)
    pause(.3-loopspeed); %Pause between switching frames
    end
    
    Time = Time + steps; %Update time loop
    
end %End main loop
if recordmovie==true

   close(writerObj);
end
close all;
end %End Function



















